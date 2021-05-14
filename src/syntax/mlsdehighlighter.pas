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
    public
    (* Constructor. *)
      constructor Create;
    (* Destructor. *)
      destructor Destroy; override;
    (* Sets default to the attributes. *)
      procedure Clear;
    (* Loads style from given file. *)
      procedure LoadFromFile (const aFileName: String);
    (* Saves style to the given file. *)
      procedure SaveToFile (const aFileName: String);

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
      crgTextConst
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
      fKeywords, fTypes, fLibrary, fOperators: TStrings;
      fSymbols: String;
      fRange: TCodeRange;
      fTokenType: TToken;
    protected
    (* Code range.

       Check to know current range and assign when it changes.
       @seealso(ResetRange) @seealso(GetRange) @seealso(SetRange) *)
      property Range: TCodeRange read fRange write fRange;
    (* Last token. *)
      property TokenType: TToken read fTokenType write fTokenType;

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
    (* Checks if character is a symbol. @seealso(Symbols) *)
      function IsSymbol (const aChar: Char): Boolean; virtual;

    (* Resets range before parsing. @seealso(Range) *)
      procedure ResetRange; override;
    (* Assigns range before parsing current line. @seealso(Range) *)
      procedure SetRange (aValue: Pointer); override;
    (* Returns range after parsing line. @seealso(Range) *)
      function GetRange: Pointer; override;

    (* Returns last token attribute. *)
      function GetTokenAttribute: TSynHighlighterAttributes; override;

    (* Reference to the style to apply to the highlighter. *)
      property Style: TMLSDEHighlightStyle read fStyle write fStyle;
    (* Keyword list. @seealso(IsKeyword) *)
      property Keywords: TStrings read fKeywords;
    (* Data types. @seealso(IsType) *)
      property DataTypes: TStrings read fTypes;
    (* Library objects (variables, constants, routines...).
       @seealso(IsLibraryObject)*)
      property LibraryObjects: TStrings read fLibrary;
    (* Symbol characters. @seealso(IsSymbol) *)
      property Symbols: String read fSymbols write fSymbols;

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



  (* Customizable hightlighter.

     This class allows to easily define new languages, to save the description
     in a disk file and to load such files. *)
    TMLSDECustomHighlighter = class (TMLSDEHighlighter)
    private
      fLanguageName, fSampleSource: String;
    protected
    (* Returns a code snippet that can be used as code example. *)
      function GetSampleSource: String; override;
    (* Assigns the sample source snippet. *)
      procedure SetSampleSource (aValue: String); override;
    public
    (* Loads language description from the given disk file. *)
      procedure LoadFromFile (const aFileName: String);
    (* Saves language description in to the given disk file. *)
      procedure SaveToFile (const aFileName: String);

    (* Returns the language name. *)
      property LanguageName: String read fLanguageName write fLanguageName;
    end;

implementation

  uses
    IniFiles, sysutils;

(*
 * TMLSDEHighlightStyle
 ***************************************************************************)

  function TMLSDEHighlightStyle.GetAttributes (aToken: TToken)
    : TSynHighlighterAttributes;
  begin
    Result := fAttributes[aToken]
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
    fAttributes[tkUnknown]   := TSynHighlighterAttributes.Create ('default');
    fAttributes[tkSymbol]    := TSynHighlighterAttributes.Create ('symbols');
    fAttributes[tkNumber]    := TSynHighlighterAttributes.Create ('numbers');
    fAttributes[tkDirective] := TSynHighlighterAttributes.Create ('directives');
    fAttributes[tkAssembler] := TSynHighlighterAttributes.Create ('assembler');
    fAttributes[tkVariable]  := TSynHighlighterAttributes.Create ('variables');
    fAttributes[tkType]      := TSynHighlighterAttributes.Create ('types');
    fAttributes[tkOperator]  := TSynHighlighterAttributes.Create ('operators');
    fAttributes[tkLabel]     := TSynHighlighterAttributes.Create ('labels');
    fAttributes[tkError]     := TSynHighlighterAttributes.Create ('errors');
    Self.Clear
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

  begin
    fFgColor := clBlack;
    fBgColor := clWhite;
    SetAttributes (tkComment,    clDefault, clGreen,   [fsItalic]);
    SetAttributes (tkIdentifier, clDefault, clDefault, []);
    SetAttributes (tkKeyword,    clDefault, clNavy,    [fsBold]);
    SetAttributes (tkString,     clDefault, clBlue,    []);
    SetAttributes (tkUnknown,    clGray,    clDefault, []);
    SetAttributes (tkSymbol,     clDefault, clNavy,    [fsBold]);
    SetAttributes (tkNumber,     clDefault, clBlue,    []);
    SetAttributes (tkDirective,  clDefault, clTeal,    []);
    SetAttributes (tkAssembler,  clDefault, clBlack,   []);
    SetAttributes (tkVariable,   clDefault, clDefault, []);
    SetAttributes (tkType,       clDefault, clNavy,    [fsBold]);
    SetAttributes (tkOperator,   clDefault, clNavy,    [fsBold]);
    SetAttributes (tkLabel,      clDefault, clDefault, [fsbold]);
    SetAttributes (tkError,      clRed,     clWhite,   [])
  end;



(* Loads from file. *)
  procedure TMLSDEHighlightStyle.LoadFromFile (const aFileName: String);
  var
    lFile: TIniFile;
    lAttributes: TSynHighlighterAttributes;
  begin
    lFile := TIniFile.Create (aFileName);
    try
      lFile.ReadInteger ('', 'Foreground', fFgColor);
      lFile.ReadInteger ('', 'background', fBgColor);
      for lAttributes in fAttributes do lAttributes.LoadFromFile (lFile)
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
      lFile.WriteInteger ('', 'Foreground', fFgColor);
      lFile.WriteInteger ('', 'background', fBgColor);
      for lAttributes in fAttributes do lAttributes.SaveToFile (lFile)
    finally
      lFile.Free
    end
  end;



(*
 * TMLSDEHighlighter
 ***************************************************************************)

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
    TStringList (fOperators).Sorted := True
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



(* Checks if it is a symbol. *)
  function TMLSDEHighlighter.IsSymbol (const aChar: Char): Boolean;
  begin
    Result := Pos (aChar, fSymbols) > 0
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



(* Returns token attribute. *)
  function TMLSDEHighlighter.GetTokenAttribute: TSynHighlighterAttributes;
  begin
    Result := fStyle.Attributes[fTokenType]
  end;



(*
 * TMLSDECustomHighlighter
 ***************************************************************************)

(* Returns sample code. *)
  function TMLSDECustomHighlighter.GetSampleSource: String;
  begin
    Result := fSampleSource
  end;



(* Assigns sample code. *)
  procedure TMLSDECustomHighlighter.SetSampleSource (aValue: String);
  begin
    fSampleSource := aValue
  end;



(* Loads language description. *)
  procedure TMLSDECustomHighlighter.LoadFromFile (const aFileName: String);
  begin
    raise Exception.Create ('TMLSDECustomHighlighter.LoadToFile no implementado')
  end;



(* Saves language description. *)
  procedure TMLSDECustomHighlighter.SaveToFile (const aFileName: String);
  begin
    raise Exception.Create ('TMLSDECustomHighlighter.SaveToFile no implementado')
  end;

end.

