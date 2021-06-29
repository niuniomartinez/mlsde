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
    (* Inside directives. *)
      crgDirective,
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
      procedure SetIdentifierChars(aValue: String);
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
    (* Returns current character. *)
      function CurrentChar: Char; inline;
    (* Advance to the end of the line. *)
      procedure JumpToEOL;
    (* Parses spaces.  Call this if you find a space. *)
      procedure ParseSpaces;
    (* Advances until find the character or hte end of the line. *)
      procedure FindChar (const aChar: Char);
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
        read fIdentifierChars write SetIdentifierChars;

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

implementation

  uses
    Main, Utils,
    IniFiles, SysUtils;

  const
  { Identifiers for default color attributes in color description files. }
    SectionDefault = 'default';
    ForegroundVar = 'Foreground';
    BackgroundVar = 'Background';
  { Default identifier characters. }
    DefaultIdentifierChars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

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
    SetAttributes (tkComment,    clNone, clGreen, []);
    SetAttributes (tkIdentifier, clNone, clNone,  []);
    SetAttributes (tkKeyword,    clNone, clNavy,  [fsBold]);
    SetAttributes (tkString,     clNone, clBlue,  []);
    // SetAttributes (tkUnknown,    clNone, clNone, []);
    SetAttributes (tkSymbol,     clNone, clNavy,  [fsBold]);
    SetAttributes (tkNumber,     clNone, clBlue,  []);
    SetAttributes (tkDirective,  clNone, clTeal,  []);
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

  procedure TMLSDEHighlighter.SetIdentifierChars (aValue: String);
  begin
    if fIdentifierChars = aValue then Exit;
    fIdentifierChars := SortStringChars (aValue)
  end;



 (* Returns char. *)
  function TMLSDEHighlighter.CurrentChar: Char;
  begin
    Result := Self.fLine[Self.TokenStart + Self.TokenLength]
  end;



(* Parse to the end of the line. *)
  procedure TMLSDEHighlighter.JumpToEOL;
  begin
    while not (Self.CurrentChar in [#0, #10, #13]) do
      Inc (Self.TokenLength)
  end;



(* Parse spaces. *)
  procedure TMLSDEHighlighter.ParseSpaces;
  begin
    while (Self.CurrentChar > #0) and (Self.CurrentChar <= ' ') do
      Inc (Self.TokenLength)
  end;



(* Advances to char. *)
  procedure TMLSDEHighlighter.FindChar(const aChar: Char);
  begin
    while (Self.CurrentChar > #0) and (Self.CurrentChar <> aChar) do
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
    while Self.CurrentChar in lCharNums do
    begin
      if Self.CurrentChar = '.' then
      begin
      { Avoid parsing double dot. }
        if fLine[Self.TokenStart + Self.TokenLength + 1] = '.' then Break;
        Inc (lFractPart)
      end;
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
    while Self.CurrentChar in lCharNums do
    begin
      if Self.CurrentChar = '.' then
      begin
      { Avoid parsing double dot. }
        if fLine[Self.TokenStart + Self.TokenLength + 1] = '.' then Break;
        Inc (lFractPart)
      end;
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
    while Self.CurrentChar in lCharNums do Inc (Self.TokenLength)
  end;



(* Parses string. *)
  procedure TMLSDEHighlighter.ParseStringConstant (const aChar: Char);
  begin
    Inc (Self.TokenLength);
    Self.FindChar (aChar);
    if Self.CurrentChar = aChar then
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
    until not CharInStr (Self.CurrentChar, fIdentifierChars)
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
    TStringList (fKeywords).Duplicates := dupIgnore;
    TStringList (fKeywords).Sorted := True;
    fTypes := TStringList.Create;
    TStringList (fTypes).Duplicates := dupIgnore;
    TStringList (fTypes).Sorted := True;
    fLibrary := TStringList.Create;
    TStringList (fLibrary).Duplicates := dupIgnore;
    TStringList (fLibrary).Sorted := True;
    fOperators := TStringList.Create;
    TStringList (fOperators).Duplicates := dupIgnore;
    TStringList (fOperators).Sorted := True;
    Self.SetIdentifierChars (DefaultIdentifierChars)
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

end.

