unit MLSDEHighlighter;
(*<Implements the base highlighters used by MLSDE. *)
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
    Graphics;

  const
  (* Attributes for operators. *)
    MLSDE_ATTR_OPERATOR = 10;



  type
  (* To identify tokens.  For internal use. *)
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
    (* Operators. *)
      tkOperator   = MLSDE_ATTR_OPERATOR
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



  (* Base class for all MLSDE syntax highlihgters. *)
    TMLSDEHighlighter = class (TSynCustomHighlighter)
    private
      fStyle: TMLSDEHighlightStyle;
    protected
    (* Returns a reference to the style. *)
      function GetDefaultAttribute (aIndex: LongInt): TSynHighlighterAttributes;
        override;
    public
    (* Reference to the style to apply to the highlighter. *)
      property Style: TMLSDEHighlightStyle read fStyle write fStyle;

    (* Attributes for operators. *)
      property OperatorAttribute: TSynHighlighterAttributes
        index MLSDE_ATTR_OPERATOR read GetDefaultAttribute;
    end;



  (* Customizable hightlighter.

     This class allows to easily define new languages, to save the description
     in a disk file and to load such files. *)
    TMLSDECustomHighlighter = class (TMLSDEHighlighter)
    public
    (* Loads language description from the given disk file. *)
      procedure LoadFromFile (const aFileName: String);
    (* Saves language description in to the given disk file. *)
      procedure SaveToFile (const aFileName: String);
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
    fAttributes[tkOperator]  := TSynHighlighterAttributes.Create ('operators');
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
    SetAttributes (tkComment,    clDefault, clGray,    [fsItalic]);
    SetAttributes (tkIdentifier, clDefault, clDefault, []);
    SetAttributes (tkKeyword,    clDefault, clDefault, [fsBold]);
    SetAttributes (tkString,     clDefault, clRed,     []);
    SetAttributes (tkUnknown,    clGray,    clDefault, []);
    SetAttributes (tkSymbol,     clDefault, clDefault, [fsBold]);
    SetAttributes (tkNumber,     clDefault, clFuchsia, []);
    SetAttributes (tkDirective,  clDefault, clGray,    [fsItalic, fsBold]);
    SetAttributes (tkAssembler,  clDefault, clDefault, [fsItalic]);
    SetAttributes (tkVariable,   clDefault, clDefault, []);
    SetAttributes (tkOperator,   clDefault, clDefault, [fsBold])
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
    if (SYN_ATTR_COMMENT <= aIndex) and (aIndex <= MLSDE_ATTR_OPERATOR) then
      Result := fStyle.Attributes[TToken (aIndex)]
    else
      Result := Nil
  end;



(*
 * TMLSDECustomHighlighter
 ***************************************************************************)

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

