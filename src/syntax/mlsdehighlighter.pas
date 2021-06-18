unit MLSDEHighlighter;
(*<Implements the base highlighter classes used by MLSDE. *)
(*
  Copyright (c) 2018-2021 Guillermo Martínez J.

  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
 *)

interface

  uses
    SynEditHighlighter,
    Classes, Graphics;

  const
  (* Attributes for data types. *)
    MLSDE_ATTR_TYPE = 10;
  (* Attributes for operators. *)
    MLSDE_ATTR_OPERATOR = 11;
  (* Attributes for labels. *)
    MLSDE_ATTR_LABEL = 12;
  (* Attributes for errors. *)
    MLSDE_ATTR_ERROR = 13;



  type
  (* To identify tokens.  For internal use.
     @seealso(TMLSDEHighlighter.TokenType) *)
    TToken = (
    (* Comment. *)
      tkComment    = SYN_ATTR_COMMENT,
    (* Identifiers.  For example, library functions. *)
      tkIdentifier = SYN_ATTR_IDENTIFIER,
    (* Keyword. *)
      tkKeyword    = SYN_ATTR_KEYWORD,
    (* Textstring. *)
      tkString     = SYN_ATTR_STRING,
    (* Unknown token.  General identifiers *)
      tkUnknown    = SYN_ATTR_WHITESPACE,
    (* Symbol, as separator (comma, dot...), bracket... *)
      tkSymbol     = SYN_ATTR_SYMBOL,
    (* Numbers. *)
      tkNumber     = SYN_ATTR_NUMBER,
    (* Directive (i.e. preprocessor, compiler option, etc. ) *)
      tkDirective  = SYN_ATTR_DIRECTIVE,
    (* Embeded Assembler code. *)
      tkAssembler  = SYN_ATTR_ASM,
    (* Variables.  Not RTL. *)
      tkVariable   = SYN_ATTR_VARIABLE,
    (* Data types. *)
      tkType       = MLSDE_ATTR_TYPE,
    (* Operators. *)
      tkOperator   = MLSDE_ATTR_OPERATOR,
    (* Labels. *)
      tkLabel      = MLSDE_ATTR_LABEL,
    (* Errors. *)
      tkError      = MLSDE_ATTR_ERROR
    );



  (* Stores the style for the code highlight. *)
    TMLSDEHighlightStyle = class (TObject)
    private
      fBgColor, fFgColor: TColor;
      fAttributes: array [TToken] of TSynHighlighterAttributes;

      function GetAttributes (aToken: TToken): TSynHighlighterAttributes;
         inline;
      function GetCustomFileName: String;
    public
    (* Constructor. *)
      constructor Create;
    (* Destructor. *)
      destructor Destroy; override;
    (* Sets default to the attributes.  This may load user style. *)
      procedure Clear;
    (* Loads style from given file. *)
      procedure LoadFromFile (const aFileName: String);
    (* Saves style to the given file. *)
      procedure SaveToFile (const aFileName: String);
    (* Saves as user style. *)
      procedure SaveUserStyle;
    (* Copies the style from the given one. *)
      procedure Assign (aStyle: TMLSDEHighlightStyle);

    (* Default text color. *)
      property Foreground: TColor read fFgColor write fFgColor;
    (* Default background color. *)
      property Background: TColor read fBgColor write fBgColor;
    (* Access to attributes. *)
      property Attributes[aToken: TToken]: TSynHighlighterAttributes
        read GetAttributes;
    end;



  (* Identifies range. @seealso(TMLSDEHighlighter.Range) *)
    TCodeRange = (
    (* Outside any range. *)
      crgNone,
    (* Inside comments. *)
      crgComment,
    (* Inside text constant (i.e. heredoc, etc.). *)
      crgTextConst,
    (* Inside a code block. *)
      crgBlock
    );



  (* Base class for all MLSDE syntax highlihgters.

     Defines default behavior and introduces attributes and API to be used by
     MLSDE, as well as useful methods and properties.

     None of the token lists are assigned by default.

     This class is likely not used as it is.  It should be extended in a class
     that actually does the parsing. *)
    TMLSDEHighlighter = class (TSynCustomHighlighter)
    private
      fStyle: TMLSDEHighlightStyle;
      fLanguageName: String;
      fExtensions: String;
      fKeywords, fTypes, fLibrary, fOperators: TStrings;
      fIdentifierChars: String;
      fRange: TCodeRange;
      fTokenType: TToken;
      fLine: PChar;
      fLineNumber: Integer;
    protected
    (* Position of the current token in the current line.  Zero based.
       @seealso(SetLine) @seealso(GetTokenEx)
       @seealso(Line) @seealso(TokenLength) *)
      TokenStart,
    (* Length of current token.
       @seealso(SetLine) @seealso(GetTokenEx)
       @seealso(Line) @seealso(TokenStart) *)
      TokenLength: Integer;

    (* Current line number. @seealso(SetLine) *)
      property LineNumber: Integer read fLineNumber;
    (* Pointer to the current line.
       @seealso(SetLine) @seealso(GetTokenEx)
       @seealso(TokenStart) @seealso(TokenLength) *)
      property Line: PChar read fLine;
    (* Code range.

       Check to know current range and assign when it changes.
       @seealso(ResetRange) @seealso(GetRange) @seealso(SetRange) *)
      property Range: TCodeRange read fRange write fRange;
    (* Last token. *)
      property TokenType: TToken read fTokenType write fTokenType;
    protected
    (* Gets until the end of the line.

       You may use this to parse single line comments. *)
      procedure JumpToEOL;
    (* Parses spaces.  Call this if you find a space. *)
      procedure ParseSpaces;
    (* Parses a number.

       This parses standard floating-point constant.  Raises an exeption if
       there's a problem with parsing (i.e. it isn't a number or is bad
       formatted). *)
      procedure ParseNumber;
    (* Parses an integer.

       This is a simple number.  Raises an exeption if there's a problem with
       parsing (i.e. it isn't a number or is bad formatted). *)
      procedure ParseInteger;
    (* Parses an hex number.

       Raises an exeption if there's a problem with parsing (i.e. it isn't a
       number or is bad formatted).*)
      procedure ParseHex;
    (* Parses a simple string.

       Raises an exeption if there's a problem with parsing (i.e. can't  find
       the closing delimiter.
       @param(aChar The string delimiter.) *)
      procedure ParseStringConstant (const aChar: Char);
    (* Parses identifiers. @seealso(IdentifierChars) *)
      procedure ParseIdentifier;
    (* Returns current token as string. *)
      function GetCurrentToken: String;
    (* Returns a reference to the style. *)
      function GetDefaultAttribute (aIndex: LongInt): TSynHighlighterAttributes;
        override;
    public
    (* Constructor. *)
      constructor Create (aOwner: TComponent); override;
    (* Destructor. *)
      destructor Destroy; override;

    (* Checks if given word is a keyword. @seealso(Keywords) *)
      function IsKeyword (const aIdent: String): Boolean; override;
    (* Checks if given word is a data type. @seealso(DataTypes) *)
      function IsType (const aIdent: String): Boolean; virtual;
    (* Checks if given word is a library object (routine, variable...).
       @seealso(LibraryObjects) *)
      function IsLibraryObject (const aIdent: String): Boolean; virtual;
    (* Checks if given word is an operator. @seealso(Operators) *)
      function IsOperator (const aIdent: String): Boolean; virtual;

    (* Sets the line to parse.

       This assigns @link(Line) and @link(LineNumber), and sets
       @link(TokenStart) to zero. *)
      procedure SetLine (const aLineText: String; aLineNumber: Integer);
        override;
    (* Checks if in end of line. *)
      function GetEol: Boolean; override;

    (* Resets range before parsing. @seealso(Range) *)
      procedure ResetRange; override;
    (* Assigns range before parsing current line. @seealso(Range) *)
      procedure SetRange (aValue: Pointer); override;
    (* Returns range after parsing line. @seealso(Range) *)
      function GetRange: Pointer; override;
    (* @exclude
       Next methods are used to manage brackets and quotes (string constants).
       They're not mandatory but must return apropriate values.  Maybe a future
       version will implement something. *)
      function GetToken: String; override;
    (* @exclude *)
      function getTokenPos: Integer; override;
    (* @exclude *)
      function GetTokenKind: Integer; override;

    (* Returns token information.
       @param(aTokenStart Pointer to the start of token.)
       @param(aTokenLength Token length in bytes.)
     *)
      procedure GetTokenEx (out aTokenStart: PChar; out aTokenLength: Integer);
        override;
    (* Returns last token attribute. *)
      function GetTokenAttribute: TSynHighlighterAttributes; override;

    (* Reference to the style to apply to the highlighter. *)
      property Style: TMLSDEHighlightStyle read fStyle write fStyle;
    (* Language name.

       @bold(Note:) Use this instead of @code(LanguageName). *)
      property Language: String read fLanguageName write fLanguageName;
    (* Extensions separated by ";". *)
      property Extensions: String read fExtensions write fExtensions;
    (* Keyword list. @seealso(IsKeyword) *)
      property Keywords: TStrings read fKeywords;
    (* Operators. @seealso(IsOperator) *)
      property Operators: TStrings read fOperators;
    (* Data types. @seealso(IsType) *)
      property DataTypes: TStrings read fTypes;
    (* Library objects (variables, constants, routines...).
       @seealso(IsLibraryObject)*)
      property LibraryObjects: TStrings read fLibrary;
    (* Characters that can be used to define identifiers.

       Default is alphanumerical characters.
       @seealso(ParseIdentifier) *)
      property IdentifierChars: String
        read fIdentifierChars write fIdentifierChars;

    (* Attributes for types. *)
      property TypeAttribute: TSynHighlighterAttributes
        index MLSDE_ATTR_TYPE read GetDefaultAttribute;
    (* Attributes for operators. *)
      property OperatorAttribute: TSynHighlighterAttributes
        index MLSDE_ATTR_OPERATOR read GetDefaultAttribute;
    (* Attributes for labels. *)
      property LabelAttribute: TSynHighlighterAttributes
        index MLSDE_ATTR_LABEL read GetDefaultAttribute;
    (* Attributes for errors. *)
      property ErrorAttribute: TSynHighlighterAttributes
        index MLSDE_ATTR_ERROR read GetDefaultAttribute;
    end;

  (* Class reference to highlighters. *)
    TMLSDEHighlighterClass = class of TMLSDEHighlighter;



  (* Stores delimiters for blocks. *)
    TBlock = record
      Starting, Ending: String
    end;



  (* Customizable hightlighter.

     This class allows to easily define new languages, to save the description
     in a disk file and to load such files. *)
    TMLSDECustomHighlighter = class (TMLSDEHighlighter)
    private
      fSampleSource: TStringList;
      fCaseSensitive: Boolean;
      fComments, fDirectives: array of TBlock;
      fSimpleStringDelimiter: String;
      fHexPrefix, fSymbolChars: String;

      procedure Clear;
    protected
    (* Returns a code snippet that can be used as code example. *)
      function GetSampleSource: String; override;
    (* Assigns the sample source snippet. *)
      procedure SetSampleSource (aValue: String); override;

    (* Stores a code snippet that can be used as code example. *)
      property SampleSource: TStringList read fSampleSource;
    public
    (* Constructor. *)
      constructor Create (aOwner: TComponent); override;
    (* Destructor. *)
      destructor Destroy; override;
    (* Loads language description from the given disk file.

       @bold(On error) raises an exception. *)
      procedure LoadFromFile (const aFileName: String);
    (* Saves language description in to the given disk file.

       @bold(On error) raises an exception. *)
      procedure SaveToFile (const aFileName: String);

    (* Tells if language is case sensitive. *)
      property CaseSensitive: Boolean read fCaseSensitive write fCaseSensitive;
    end;

implementation

  uses
    Main, Utils,
    IniFiles, StrUtils, sysutils, Types;

  const
  { Identifiers for default color attributes in color description files. }
    SectionDefault = 'default';
    ForegroundVar = 'Foreground';
    BackgroundVar = 'Background';
  { Default identifier characters. }
    DefaultIdentifierChars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  resourcestring
    errUnknownToken = 'Unknown token "%s".';
    errDuplicatedName = 'Duplicated language name.';
    errDuplicatedExtensions = 'Duplicated extensions.';
    errDuplicatedString = 'Duplicated string definition.';
    errDuplicatedHex = 'Duplicated hexagesimal definition.';
    errDuplicatedSymbols = 'Duplicated symbol definition.';
    errDuplicatedIdentifier = 'Duplicated identifier characters definition.';
    errUnknownParameter = 'Unknown parameter "%s".';
    errStringExpected = 'String expected.';
    errUndefinedString = 'Undefined string.';
    errExpecting = 'Expecting "%s"';
    errUnknownStringType = 'Unknown string type "%s".';
    errTokenNotFound = '"%s" not found.';

(*
 * TMLSDEHighlightStyle
 ***************************************************************************)

  function TMLSDEHighlightStyle.GetAttributes (aToken: TToken)
    : TSynHighlighterAttributes;
  begin
    Result := fAttributes[aToken]
  end;



(* User style file. *)
  function TMLSDEHighlightStyle.GetCustomFileName: String;
  begin
    Result := Concat (
      MLSDEApplication.Configuration.ConfigurationDir,
      'custom.csd'
    )
  end;



(* Constructor. *)
  constructor TMLSDEHighlightStyle.Create;
  begin
    inherited Create;
  { Create and initialize atributes. }
    fAttributes[tkComment]   := TSynHighlighterAttributes.Create ('comments');
    fAttributes[tkIdentifier]:=TSynHighlighterAttributes.Create ('identifiers');
    fAttributes[tkKeyword]   := TSynHighlighterAttributes.Create ('keywords');
    fAttributes[tkString]    := TSynHighlighterAttributes.Create ('strings');
    fAttributes[tkUnknown]   := Nil;
    fAttributes[tkSymbol]    := TSynHighlighterAttributes.Create ('symbols');
    fAttributes[tkNumber]    := TSynHighlighterAttributes.Create ('numbers');
    fAttributes[tkDirective] := TSynHighlighterAttributes.Create ('directives');
    fAttributes[tkAssembler] := TSynHighlighterAttributes.Create ('assembler');
    fAttributes[tkVariable]  := TSynHighlighterAttributes.Create ('variables');
    fAttributes[tkType]      := TSynHighlighterAttributes.Create ('types');
    fAttributes[tkOperator]  := TSynHighlighterAttributes.Create ('operators');
    fAttributes[tkLabel]     := TSynHighlighterAttributes.Create ('labels');
    fAttributes[tkError]     := TSynHighlighterAttributes.Create ('errors')
  end;



(* Destructor. *)
  destructor TMLSDEHighlightStyle.Destroy;
  var
    lAttributes: TSynHighlighterAttributes;
  begin
    for lAttributes in fAttributes do lAttributes.Free;
    inherited Destroy
  end;



(* Set defaults. *)
  procedure TMLSDEHighlightStyle.Clear;

    procedure SetAttributes (
      aId: TToken;
      aBgColor, aFgColor: TColor;
      aFontStyle: TFontStyles
    ); inline;
    begin
      fAttributes[aId].Background := aBgColor;
      fAttributes[aId].Foreground := aFgColor;
      fAttributes[aId].Style := aFontStyle
    end;

  var
    lFileName: TFileName;
  begin
  { Set defaults. }
    fFgColor := clBlack;
    fBgColor := clWhite;
    SetAttributes (tkComment,    clNone, clGreen, [fsItalic]);
    SetAttributes (tkIdentifier, clNone, clNone,  []);
    SetAttributes (tkKeyword,    clNone, clNavy,  [fsBold]);
    SetAttributes (tkString,     clNone, clBlue,  []);
    // SetAttributes (tkUnknown,    clNone, clNone, []);
    SetAttributes (tkSymbol,     clNone, clNavy,  [fsBold]);
    SetAttributes (tkNumber,     clNone, clBlue,  []);
    SetAttributes (tkDirective,  clNone, clTeal,  [fsItalic, fsBold]);
    SetAttributes (tkAssembler,  clNone, clBlack, []);
    SetAttributes (tkVariable,   clNone, clNone,  [fsBold]);
    SetAttributes (tkType,       clNone, clNavy,  [fsBold]);
    SetAttributes (tkOperator,   clNone, clNavy,  [fsBold]);
    SetAttributes (tkLabel,      clNone, clNone,  [fsbold]);
    SetAttributes (tkError,      clRed,  clWhite, [fsUnderline]);
  { If there are a user style defined, load it. }
    lFileName := Self.GetCustomFileName;
    if FileExists (lFileName) then Self.LoadFromFile (lFileName)
  end;



(* Loads from file. *)
  procedure TMLSDEHighlightStyle.LoadFromFile (const aFileName: String);
  var
    lFile: TIniFile;
    lAttributes: TSynHighlighterAttributes;
  begin
    lFile := TIniFile.Create (aFileName);
    try
      fBgColor := lFile.ReadInteger (SectionDefault, BackgroundVar, fBgColor);
      fFgColor := lFile.ReadInteger (SectionDefault, ForegroundVar, fFgColor);
      for lAttributes in fAttributes do
        if Assigned (lAttributes) then
          lAttributes.LoadFromFile (lFile)
    finally
      lFile.Free
    end
  end;



(* Saves to file. *)
  procedure TMLSDEHighlightStyle.SaveToFile (const aFileName: String);
  var
    lFile: TIniFile;
    lAttributes: TSynHighlighterAttributes;
  begin
    lFile := TIniFile.Create (aFileName);
    try
      lFile.WriteInteger (SectionDefault, BackgroundVar, fBgColor);
      lFile.WriteInteger (SectionDefault, ForegroundVar, fFgColor);
      for lAttributes in fAttributes do
        if Assigned (lAttributes) then
          lAttributes.SaveToFile (lFile)
    finally
      lFile.Free
    end
  end;



(* Saves user style. *)
  procedure TMLSDEHighlightStyle.SaveUserStyle;
  begin
    Self.SaveToFile (Self.GetCustomFileName)
  end;



(* Copies style. *)
  procedure TMLSDEHighlightStyle.Assign (aStyle: TMLSDEHighlightStyle);
  var
    Ndx: TToken;
  begin
    fBgColor := aStyle.fBgColor;
    fFgColor := aStyle.fFgColor;
    for Ndx := Low (fAttributes) to High (fAttributes) do
      if Assigned (fAttributes[Ndx]) then
        fAttributes[Ndx].Assign (aStyle.fAttributes[Ndx])
  end;



(*
 * TMLSDEHighlighter
 ***************************************************************************)

(* Parse to the end of the line. *)
  procedure TMLSDEHighlighter.JumpToEOL;
  begin
    while not (Line[Self.TokenStart + Self.TokenLength] in [#0, #10, #13]) do
      Inc (Self.TokenLength)
  end;



(* Parse spaces. *)
  procedure TMLSDEHighlighter.ParseSpaces;
  begin
    while (#0 < fLine[Self.TokenStart + Self.TokenLength])
      and (fLine[Self.TokenStart + Self.TokenLength] <= ' ')
    do
      Inc (Self.TokenLength)
  end;



(* Parses numbers. *)
  procedure TMLSDEHighlighter.ParseNumber;
  const
    lCharNums = ['0'..'9', '.'];
  var
    lFractPart: Integer;
  begin
    lFractPart := 0;
    while fLine[Self.TokenStart + Self.TokenLength] in lCharNums do
    begin
      if fLine[Self.TokenStart + Self.TokenLength] = '.' then Inc (lFractPart);
      Inc (Self.TokenLength)
    end;
    if lFractPart > 1 then
      raise EConvertError.Create ('Error parsing number.')
  end;



(* Parses numbers. *)
  procedure TMLSDEHighlighter.ParseInteger;
  const
    lCharNums = ['0'..'9', '.'];
  var
    lFractPart: Integer;
  begin
    lFractPart := 0;
    while fLine[Self.TokenStart + Self.TokenLength] in lCharNums do
    begin
      if fLine[Self.TokenStart + Self.TokenLength] = '.' then Inc (lFractPart);
      Inc (Self.TokenLength)
    end;
    if lFractPart > 0 then
      raise EConvertError.Create ('Error parsing number.')
  end;



(* Parses numbers. *)
  procedure TMLSDEHighlighter.ParseHex;
  const
    lCharNums = ['0'..'9', 'A'..'F', 'a'..'f'];
  begin
    while fLine[Self.TokenStart + Self.TokenLength] in lCharNums do
      Inc (Self.TokenLength)
  end;



(* Parses string. *)
  procedure TMLSDEHighlighter.ParseStringConstant (const aChar: Char);
  begin
    repeat
      Inc (Self.TokenLength)
    until fLine[Self.TokenStart + Self.TokenLength] in [#0, aChar];
    if fLine[Self.TokenStart + Self.TokenLength] = aChar then
      Inc (Self.TokenLength)
    else
      raise Exception.Create ('Error parsing string constant.')
  end;



(* Parses an identifier. *)
  procedure TMLSDEHighlighter.ParseIdentifier;
  begin
  { First character is alwais identifier. }
    repeat
      Inc (Self.TokenLength)
    until Pos (fLine[Self.TokenStart + Self.TokenLength], fIdentifierChars) = 0
  end;



(* Returns current token. *)
  function TMLSDEHighlighter.GetCurrentToken: String;
  var
    Cnt: Integer;
  begin
    Result := ''; Cnt := 0;
    while Cnt < Self.TokenLength do
    begin
      Result := Concat (Result, Self.Line[Cnt]);
      Inc (Cnt)
    end
  end;



(* Get style. *)
  function TMLSDEHighlighter.GetDefaultAttribute (aIndex: LongInt)
    : TSynHighlighterAttributes;
  begin
    if (SYN_ATTR_COMMENT <= aIndex) and (aIndex <= MLSDE_ATTR_ERROR) then
      Result := fStyle.Attributes[TToken (aIndex)]
    else
      Result := Nil
  end;



(* Constructor. *)
  constructor TMLSDEHighlighter.Create (aOwner: TComponent);
  begin
    inherited Create(aOwner);
    fKeywords := TStringList.Create;
    TStringList (fKeywords).Sorted := True;
    fTypes := TStringList.Create;
    TStringList (fTypes).Sorted := True;
    fLibrary := TStringList.Create;
    TStringList (fLibrary).Sorted := True;
    fOperators := TStringList.Create;
    TStringList (fOperators).Sorted := True;
    fIdentifierChars := DefaultIdentifierChars
  end;



(* Destructor. *)
  destructor TMLSDEHighlighter.Destroy;
  begin
    fKeywords.Free;
    fTypes.Free;
    fLibrary.Free;
    fOperators.Free;
    inherited Destroy
  end;



(* Checks if it is a keyword. *)
  function TMLSDEHighlighter.IsKeyword (const aIdent: String): Boolean;
  var
    lNdx: Integer;
  begin
  { Implementation note:  Find uses binary search so it is quite fast. }
    Result := TStringList (fKeywords).Find (aIdent, lNdx)
  end;



  (* Checks if it is a data type. *)
  function TMLSDEHighlighter.IsType (const aIdent: String): Boolean;
  var
    lNdx: Integer;
  begin
    Result := TStringList (fTypes).Find (aIdent, lNdx)
  end;



(* Checks if it is a library object. *)
  function TMLSDEHighlighter.IsLibraryObject (const aIdent: String): Boolean;
  var
    lNdx: Integer;
  begin
    Result := TStringList (fLibrary).Find (aIdent, lNdx)
  end;



(* Checks if it is an operator. *)
  function TMLSDEHighlighter.IsOperator (const aIdent: String): Boolean;
  var
    lNdx: Integer;
  begin
    Result := TStringList (fOperators).Find (aIdent, lNdx)
  end;



(* Sets the line to parse. *)
  procedure TMLSDEHighlighter.SetLine (
    const aLineText: String;
    aLineNumber: Integer
  );
  begin
    inherited SetLine (aLineText, aLineNumber);
    fLine := PChar (aLineText); fLineNumber := aLineNumber;
    Self.TokenStart := 0
  end;



(* Checks end of line. *)
  function TMLSDEHighlighter.GetEol: Boolean;
  begin
    Result := fLine[Self.TokenStart] = #0
  end;



(* Resets range. *)
  procedure TMLSDEHighlighter.ResetRange;
  begin
    fRange := crgNone
  end;



(* Assigns range. *)
  procedure TMLSDEHighlighter.SetRange (aValue: Pointer);
  begin
    fRange := TCodeRange (PtrUInt (aValue))
  end;



(* Returns range. *)
  function TMLSDEHighlighter.GetRange: Pointer;
  begin
    Result := Pointer (PtrInt (Ord (fRange)))
  end;



(* Needed stuff but unimplemented (maybe someday). *)
  function TMLSDEHighlighter.GetToken: String;
  begin
    Result := ''
  end;

  function TMLSDEHighlighter.getTokenPos: Integer;
  begin
    Result := Self.TokenStart - 1
  end;

  function TMLSDEHighlighter.GetTokenKind: Integer;
  begin
    Result := 0
  end;



(* Returns token information. *)
  procedure TMLSDEHighlighter.GetTokenEx (
    out aTokenStart: PChar;
    out aTokenLength: Integer
  );
  begin
    aTokenStart := fLine + Self.TokenStart;
    aTokenLength := Self.TokenLength
  end;



(* Returns token attribute. *)
  function TMLSDEHighlighter.GetTokenAttribute: TSynHighlighterAttributes;
  begin
    Result := fStyle.Attributes[fTokenType]
  end;



(*
 * TMLSDECustomHighlighter
 ***************************************************************************)

  procedure TMLSDECustomHighlighter.Clear;
  begin
    fLanguageName := '';
    fExtensions := '';
    SetLength (fComments, 0);
    SetLength (fDirectives, 0);
    fSimpleStringDelimiter := '';
    fHexPrefix := '';
    fSymbolChars := '';
    Self.IdentifierChars := DefaultIdentifierChars;
    fKeywords.Clear;
    fTypes.Clear;
    fLibrary.Clear;
    fOperators.Clear;
    fIdentifierChars := '';
    fCaseSensitive := False
  end;



(* Returns sample code. *)
  function TMLSDECustomHighlighter.GetSampleSource: String;
  begin
    Result := fSampleSource.Text
  end;



(* Assigns sample code. *)
  procedure TMLSDECustomHighlighter.SetSampleSource (aValue: String);
  begin
    fSampleSource.Text := aValue
  end;



(* Constructor. *)
  constructor TMLSDECustomHighlighter.Create (aOwner: TComponent);
  begin
    inherited Create(aOwner);
    Self.IdentifierChars := DefaultIdentifierChars;
    fSampleSource := TStringList.Create
  end;



(* Destructor. *)
  destructor TMLSDECustomHighlighter.Destroy;
  begin
    fSampleSource.Free;
    inherited Destroy
  end;



(* Loads language description. *)
  procedure TMLSDECustomHighlighter.LoadFromFile (const aFileName: String);
  const
    errTxtTmpl = '%s [%d, %d] ';
  var
    lDefinitionFile: TStringList;
    Ndx, lPos: Integer;

    procedure RaiseException (const aMessage: String); inline;
    begin
      raise Exception.CreateFmt (
        Concat (errTxtTmpl, aMessage),
        [ExtractFileName (aFileName), lPos, Ndx + 1]
      )
    end;

    procedure SkipSpaces;
    begin
      while (lPos <= Length (lDefinitionFile[Ndx]))
        and (lDefinitionFile[Ndx][lPos] <= #32)
      do
        Inc (lPos)
    end;

    function GetToken: String;
    begin
      SkipSpaces;
      Result := '';
      while (lPos <= Length (lDefinitionFile[Ndx]))
        and (lDefinitionFile[Ndx][lPos] > #32)
      do begin
        Result := Concat (Result, lDefinitionFile[Ndx][lPos]);
        Inc (lPos)
      end
    end;

    function GetString: String;
    var
      lDelimiter: Char;
    begin
      SkipSpaces;
      if lPos >= Length (lDefinitionFile[Ndx]) then
        RaiseException (errStringExpected);
      lDelimiter := lDefinitionFile[Ndx][lPos];
      if not (lDelimiter in ['''', '"']) then
        RaiseException (errStringExpected);
      Inc (lPos); { Skips string delimiter. }
      Result := '';
      while (lPos <= Length (lDefinitionFile[Ndx]))
        and (lDefinitionFile[Ndx][lPos] > #32)
        and (lDefinitionFile[Ndx][lPos] <> lDelimiter)
      do begin
        Result := Concat (Result, lDefinitionFile[Ndx][lPos]);
        Inc (lPos)
      end;
      if (lPos > Length (lDefinitionFile[Ndx]))
      or (lDefinitionFile[Ndx][lPos] <> lDelimiter)
      then
        RaiseException (errUndefinedString);
      Inc (lPos) { Skips string delimiter. }
    end;

    procedure SetLanguageName; inline;
    begin
      if fLanguageName = EmptyStr then
        fLanguageName := GetToken
      else
        RaiseException (errDuplicatedName)
    end;

    procedure SetExtensions;
    var
      lExtensions: TStringDynArray;
    begin
      if fExtensions = EmptyStr then
      begin
        lExtensions  := SplitString (
          LowerCase (Trim (
            RightStr (
              lDefinitionFile[Ndx],
              Length (lDefinitionFile[Ndx]) - lPos
            )
          )),
          ' '
        );
        fExtensions := JoinStrings (lExtensions, ';')
      end
      else
        RaiseException (errDuplicatedExtensions)
    end;

    procedure SetCaseSense; inline;
    var
      lSense: String;
    begin
      lSense := LowerCase (GetToken);
      if lSense = 'sensitive' then
        fCaseSensitive := true
      else if lSense = 'insensitive' then
        fCaseSensitive := false
      else
        RaiseException (Format (errUnknownParameter, [lSense]))
    end;

    procedure AddCommentDelimiters;
    var
      lStarts, lEnds: String;
      lNdx: Integer;
    begin
    { Get comment delimiters. }
      if LowerCase (GetToken) = 'starts' then
      begin
        lStarts := GetString;
        if not Self.CaseSensitive then lStarts := LowerCase (lStarts);
        lEnds := LowerCase (GetToken);
        if lEnds <> EmptyStr then
        begin
          if lEnds = 'ends' then
          begin
            lEnds := GetString;
            if not Self.CaseSensitive then lEnds := LowerCase (lEnds)
          end
          else
            RaiseException (Format (errUnknownParameter, [lEnds]))
        end
      end
      else
        RaiseException (Format (errExpecting, ['starts']));
    { If code ends here, then it is ok. }
      lNdx := Length (fComments);
      SetLength (fComments, lNdx + 1);
      fComments[lNdx].Starting := lStarts;
      fComments[lNdx].Ending := lEnds
    end;

    procedure AddDirectiveDelimiters;
    var
      lStarts, lEnds: String;
      lNdx: Integer;
    begin
    { Get comment delimiters. }
      if LowerCase (GetToken) = 'starts' then
      begin
        lStarts := GetString;
        if not Self.CaseSensitive then lStarts := LowerCase (lStarts);
        lEnds := LowerCase (GetToken);
        if lEnds <> EmptyStr then
        begin
          if lEnds = 'ends' then
          begin
            lEnds := GetString;
            if not Self.CaseSensitive then lEnds := LowerCase (lEnds)
          end
          else
            RaiseException (Format (errUnknownParameter, [lEnds]))
        end
      end
      else
        RaiseException (Format (errExpecting, ['starts']));
    { If code ends here, then it is ok. }
      lNdx := Length (fDirectives);
      SetLength (fDirectives, lNdx + 1);
      fDirectives[lNdx].Starting := lStarts;
      fDirectives[lNdx].Ending := lEnds
    end;

    procedure AddStringDelimiters;
    var
      lToken: String;
    begin
      lToken := LowerCase (GetToken);
      if lToken <> 'simple' then
        RaiseException (Format (errUnknownStringType, [lToken]));
      lToken := GetString;
      if Length (lToken) <> 1 then
        RaiseException (Format (errUnknownToken, [lToken]));
      if Pos (lToken, fSimpleStringDelimiter) > 0 then
        RaiseException (errDuplicatedString);
      fSimpleStringDelimiter := Concat (fSimpleStringDelimiter, lToken)
    end;

    procedure ParseHexPrefix;
    begin
      if fHexPrefix <> EmptyStr then RaiseException (errDuplicatedHex);
      if LowerCase (GetToken) <> 'prefix' then
        RaiseException (Format (errExpecting, ['hex prefix']));
      fHexPrefix := GetString;
      if not Self.CaseSensitive then fHexPrefix := LowerCase (fHexPrefix)
    end;

    procedure SetSymbolChars;
    begin
      if fSymbolChars <> EmptyStr then
        RaiseException (errDuplicatedSymbols);
      fSymbolChars := GetString
    end;

    procedure SetIdentifierChars;
    begin
    { That should work but for some reason the first time this code runs
      IdentifierChars is empty.  I'm lazy now to fix it, but shouldn't be too
      hard.
      if fIdentifierChars <> DefaultIdentifierChars then
        RaiseException (errDuplicatedIdentifier);
    }
      if LowerCase (GetToken) <> 'chars' then
        RaiseException (Format (errExpecting, ['chars']));
      Self.IdentifierChars := GetString
    end;

    procedure ParseKeywordsSection;
    begin
      repeat
        Inc (Ndx)
      until (Ndx > lDefinitionFile.Count)
      or (LowerCase (Trim (lDefinitionFile[Ndx])) = 'end keywords');
      if Ndx > lDefinitionFile.Count then
        RaiseException (Format (errTokenNotFound, ['end keywords']))
    end;

    procedure ParseTypesSection;
    begin
      repeat
        Inc (Ndx)
      until (Ndx > lDefinitionFile.Count)
      or (LowerCase (Trim (lDefinitionFile[Ndx])) = 'end types');
      if Ndx > lDefinitionFile.Count then
      RaiseException (Format (errTokenNotFound, ['end types']))
    end;

    procedure ParseOperatorsSection;
    begin
      repeat
        Inc (Ndx)
      until (Ndx > lDefinitionFile.Count)
      or (LowerCase (Trim (lDefinitionFile[Ndx])) = 'end operators');
      if Ndx > lDefinitionFile.Count then
      RaiseException (Format (errTokenNotFound, ['end operators']))
    end;

    procedure ParseIdentifierSection;
    begin
      repeat
        Inc (Ndx)
      until (Ndx > lDefinitionFile.Count)
      or (LowerCase (Trim (lDefinitionFile[Ndx])) = 'end identifiers');
      if Ndx > lDefinitionFile.Count then
      RaiseException (Format (errTokenNotFound, ['end identifiers']))
    end;

  var
    lToken: String;
  begin
    Self.Clear;
    lDefinitionFile := TStringList.Create;
    try
      lDefinitionFile.LoadFromFile (aFileName);
      Ndx := 0;
      repeat
        lPos := 1;
        lToken := LowerCase (GetToken);
      { Ignore empty lines and comments. }
        if (lToken <> EmptyStr) and (lToken[1] <> '#') then
        begin
          if lToken = 'language' then
            SetLanguageName
          else if lToken = 'extensions' then
            SetExtensions
          else if lToken = 'case' then
            SetCaseSense
          else if lToken = 'comment' then
            AddCommentDelimiters
          else if lToken = 'directive' then
            AddDirectiveDelimiters
          else if lToken = 'string' then
            AddStringDelimiters
          else if lToken = 'hex' then
            ParseHexPrefix
          else if lToken = 'symbols' then
            SetSymbolChars
          else if lToken = 'identifier' then
            SetIdentifierChars
          else if lToken = 'keywords' then
            ParseKeywordsSection
          else if lToken = 'types' then
            ParseTypesSection
          else if lToken = 'operators' then
            ParseOperatorsSection
          else if lToken = 'identifiers' then
            ParseIdentifierSection
          else
            RaiseException (Format (errUnknownToken, [lToken]))
        end;
        Inc (Ndx)
      until ndx >= lDefinitionFile.Count
    finally
      lDefinitionFile.Free
    end;
  end;



(* Saves language description. *)
  procedure TMLSDECustomHighlighter.SaveToFile (const aFileName: String);
  begin
    raise Exception.Create ('TMLSDECustomHighlighter.SaveToFile no implementado')
  end;

end.

