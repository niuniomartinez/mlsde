unit MLSDEHighlighterMLSDE;
(*<Defines highliters for MLSDE internal files. *)
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

  type
  (* Defines a highlighters to the syntax definition files. *)

    { TMLSDESyntaxDefinitionSyn }

    TMLSDESyntaxDefinitionSyn = class (TMLSDEHighlighter)
    private
      fTokenIndex: Integer; { In the current line. }
    public
    (* Constructor. *)
      constructor Create (aOwner: TComponent); override;
    (* Sets the line to parse. *)
      procedure SetLine (const aLineText: String; aLineNumber: Integer);
        override;
    (* Parses the line. *)
      procedure Next; override;
    end;

implementation

  uses
    Utils;

(*
 * TMLSDESyntaxDefinitionSyn
 ***************************************************************************)

  constructor TMLSDESyntaxDefinitionSyn.Create (aOwner: TComponent);
  const
    ReservedWords: array [0..12] of String = (
      'language', 'case',
      'end',
      'comment', 'directive',
      'string', 'hex', 'symbols', 'identifier',
      'keywords', 'types', 'operators', 'identifiers');
    Identifiers: array [0..4] of String = (
      'starts', 'ends', 'prefix',
      'chars', 'simple'
    );
  var
    lToken: String;
  begin
    inherited Create (aOwner);
    Self.SampleSource := '';
    for lToken in ReservedWords do Self.Keywords.Append (lToken);
    for lToken in Identifiers do Self.LibraryObjects.Append (lToken)
  end;



(* Initializes parse. *)
  procedure TMLSDESyntaxDefinitionSyn.SetLine (
    const aLineText:
    String; aLineNumber: Integer
  );
  begin
    inherited SetLine(aLineText, aLineNumber);
  { No tokens parsed in current line. }
    fTokenIndex := 0
  end;



(* Parse line. *)
  procedure TMLSDESyntaxDefinitionSyn.Next;

    procedure ParseString; inline;
    begin
      try
        Self.ParseStringConstant (Self.Line[Self.TokenStart]);
        Inc (fTokenIndex);
        Self.TokenType := tkString
      except
        Self.TokenType := tkError
      end
    end;

    function ExtractToken: String;
    begin
      Result := '';
      repeat
        Result := Concat (Result, Self.Line[Self.TokenStart+Self.TokenLength]);
        Inc (Self.TokenLength)
      until Self.Line[Self.TokenStart + Self.TokenLength] <= ' '
    end;

  const
    lBlockIdents: array [0..3] of String =
      ('keywords', 'types', 'operators', 'identifiers');
  var
    lToken: String;
  begin
    Self.TokenType := tkUnknown;
  { Check end of line. }
    if Self.Line[Self.TokenStart] <> #0 then
    begin
    { Get token start. }
      Inc (Self.TokenStart, Self.TokenLength);
      Self.TokenLength := 0;
    { identify token. }
      if Self.Line[Self.TokenStart] <= ' ' then
        Self.ParseSpaces
      else if Self.Line[Self.TokenStart] = '"' then
        ParseString
      else begin
        lToken := LowerCase (ExtractToken);
        Inc (fTokenIndex);
        if Self.Range = crgBlock then
        begin
          if fTokenIndex = 1 then
          begin
          { If first token in block line, maybe we reached the end of list. }
            if lToken = 'end' then
            begin
              Self.Range := crgNone;
              Self.TokenType := tkKeyword
            end
            else
              Self.TokenType := tkNumber
          end
          else
            Self.TokenType := tkNumber
        end
        else begin
          if Self.IsKeyword (lToken) then
          begin
            Self.TokenType := tkKeyword;
            if (fTokenIndex = 1)
            and (FindString (lToken, lBlockIdents) >= 0) then
              Self.Range := crgBlock
          end
          else if Self.IsLibraryObject (lToken) then
            Self.TokenType := tkIdentifier
          else
            Self.TokenType := tkUnknown;
        end
      end
    end
  end;


end.

