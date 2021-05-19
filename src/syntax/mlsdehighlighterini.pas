unit MLSDEHighlighterINI;
(*<Built-in highlighter for INI files. *)
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
    MLSDEHighlighter,
    Classes;

  const
  (* Sample code. *)
    SampleCodeINI = '# INI file example'#10 +
                  'Variable=Value'#10 +
                  '[section]'#10+
                  '  Other=123';

  type
  (* The INI highlighter.

     Read @link(TMLSDEHighlighter) for details. *)
    TMLSDEINISyn = class (TMLSDEHighlighter)
    private
      fTokenIndex: Integer; { In the current line. }
      fIsSectionLine, fInErrorState: Boolean;
    public
    (* Constructor. *)
      constructor Create (aOwner: TComponent); override;
    (* Sets the line to parse. *)
      procedure SetLine (const aLineText: String; aLineNumber: Integer);
        override;
    (* Gets next token. *)
      procedure Next; override;
    end;

implementation

(*
 * TMLSDEINISyn
 ***************************************************************************)

(* Constructor. *)
  constructor TMLSDEINISyn.Create (aOwner: TComponent);
  const
    ReservedWords: array [0..1] of String = ('true', 'false');
  var
    lToken: String;
  begin
    inherited Create (aOwner);
    Self.SampleSource := SampleCodeINI;
    Self.IdentifierChars := Concat (Self.IdentifierChars, '-_');
    for lToken in ReservedWords do Self.LibraryObjects.Append (lToken);
    Self.Operators.Append ('=')
  end;



(* Initializes parse. *)
  procedure TMLSDEINISyn.SetLine (
    const aLineText:
    String; aLineNumber: Integer
  );
  begin
    inherited SetLine(aLineText, aLineNumber);
  { No tokens parsed in current line. }
    fTokenIndex := 0;
  { Assume it is not a section line. }
    fIsSectionLine := False;
  { Not error yet. }
    fInErrorState := False
  end;



(* Parses. *)
  procedure TMLSDEINISyn.Next;

    procedure ParseAssignation; inline;
    begin
      Inc (Self.TokenLength);
      Inc (fTokenIndex);
      if fTokenIndex = 2 then
        Self.TokenType := tkOperator
      else
        fInErrorState := True
    end;

    procedure ParseComment; inline;
    begin
      Self.TokenType := tkComment;
      Self.JumpToEOL
    end;

    procedure ParseIdentifier; inline;
    var
      lIdentifier: String;
      lNdx: Integer;
    begin
      lIdentifier := LowerCase (Self.ParseIdentifier);
      Inc (fTokenIndex);
      case fTokenIndex of
        1:
          Self.TokenType := tkVariable;
        2:
          fInErrorState := True;
        otherwise
          if TStringList (Self.LibraryObjects).Find (lIdentifier, lNdx) then
            Self.TokenType := tkIdentifier
          else
            Self.TokenType := tkString;
      end;
      if fIsSectionLine then fInErrorState := True
    end;

    procedure ParseSection; inline;
    const
      EndToken = [#0, #10, #13, ']'];
    begin
      while not (Self.Line[Self.TokenStart + Self.TokenLength] in EndToken) do
        Inc (Self.TokenLength);
      if Self.Line[Self.TokenStart + Self.TokenLength] = ']' then
      begin
        Inc (Self.TokenLength);
      { Section label should be the only one in the line. }
        if fIsSectionLine or (fTokenIndex > 0) then
          fInErrorState := True
        else begin
          Self.TokenType := tkLabel;
          fIsSectionLine := True;
          fTokenIndex := 1
        end
      end
      else
      { Forgot closing bracket. }
        fInErrorState := True
    end;

    procedure ParseString; inline;
    begin
      try
        Self.ParseStringConstant (Self.Line[Self.TokenStart]);
        Inc (fTokenIndex);
        if fTokenIndex > 2 then
          Self.TokenType := tkString
        else
          fInErrorState := True
      except
        fInErrorState := True
      end;
    end;

    procedure ParseValue; inline;
    var
      lIgnoref: Real;
    begin
      try
        lIgnoref := Self.ParseNumber;
        Self.TokenType := tkNumber
      except
        fInErrorState := True
      end
    end;

  begin
    Self.TokenType := tkUnknown;
  { Check end of line. }
    if Self.Line[Self.TokenStart] <> #0 then
    begin
    { Get token start. }
      Inc (Self.TokenStart, Self.TokenLength);
      Self.TokenLength := 0;
    { Identify token. }
      case Self.Line[Self.TokenStart] of
      '#':
        ParseComment;
      '[':
        ParseSection;
      '=':
        ParseAssignation;
      '"', '''':
        ParseString;
      '0'..'9':
        ParseValue;
      otherwise
        if Self.Line[Self.TokenStart] <= ' ' then
          Self.ParseSpaces
        else
          ParseIdentifier;
      end;
    { If in error state, then token is an error. }
      if fInErrorState then Self.TokenType := tkError
    end
  end;

end.

