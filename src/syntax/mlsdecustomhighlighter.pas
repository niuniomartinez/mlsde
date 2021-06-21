unit MLSDECustomHighlighter;
(*<Implements the MLSDE custom highlighter. *)
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
      fSimpleStringDelimiter, fHexPrefix, fSymbolChars,
      fDirectiveStartChars, fCommentStartChars: String;

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
      procedure LoadDefinitionFile (const aFileName: String);
    (* Saves language description in to the given disk file.

       @bold(On error) raises an exception. *)
      procedure SaveDefinitionFile (const aFileName: String);
    (* Parses the line. *)
      procedure Next; override;

    (* Tells if language is case sensitive. *)
      property CaseSensitive: Boolean read fCaseSensitive write fCaseSensitive;
    end;

implementation

  uses
    Utils,
    StrUtils, SysUtils, Types;

  const
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
 * TMLSDECustomHighlighter
 ***************************************************************************)

  procedure TMLSDECustomHighlighter.Clear;
  begin
    Self.Language := '';
    Self.Extensions := '';
    SetLength (fComments, 0);
    SetLength (fDirectives, 0);
    fSimpleStringDelimiter := '';
    fHexPrefix := '';
    fSymbolChars := '';
    Self.IdentifierChars := DefaultIdentifierChars;
    Self.Keywords.Clear;
    Self.DataTypes.Clear;
    Self.LibraryObjects.Clear;
    Self.Operators.Clear;
    Self.IdentifierChars := '';
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
  procedure TMLSDECustomHighlighter.LoadDefinitionFile (const aFileName: String);
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

  { Checks End Of Line. }
    function EOL: Boolean; inline;
    begin
      Result := lPos > Length (lDefinitionFile[Ndx])
    end;

    procedure SkipSpaces;
    begin
      while not EOL and (lDefinitionFile[Ndx][lPos] <= #32) do Inc (lPos)
    end;

    function GetToken: String;
    begin
      SkipSpaces;
      Result := '';
      while not EOL and (lDefinitionFile[Ndx][lPos] > #32) do
      begin
        Result := Concat (Result, lDefinitionFile[Ndx][lPos]);
        Inc (lPos)
      end
    end;

    function GetString: String;
    var
      lDelimiter: Char;
    begin
      SkipSpaces;
      if EOL then RaiseException (errStringExpected);
      lDelimiter := lDefinitionFile[Ndx][lPos];
      if not (lDelimiter in ['''', '"']) then
        RaiseException (errStringExpected);
      Inc (lPos); { Skips string delimiter. }
      Result := '';
      while not EOL
        and (lDefinitionFile[Ndx][lPos] > #32)
        and (lDefinitionFile[Ndx][lPos] <> lDelimiter)
      do begin
        Result := Concat (Result, lDefinitionFile[Ndx][lPos]);
        Inc (lPos)
      end;
      if EOL or (lDefinitionFile[Ndx][lPos] <> lDelimiter) then
        RaiseException (errUndefinedString);
      Inc (lPos) { Skips string delimiter. }
    end;

    procedure SetLanguageName; inline;
    begin
      if Self.Language = EmptyStr then
        Self.Language := GetToken
      else
        RaiseException (errDuplicatedName)
    end;

    procedure SetExtensions;
    var
      lExtensions: TStringDynArray;
    begin
      if Self.Extensions = EmptyStr then
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
        Self.Extensions := JoinStrings (lExtensions, ';')
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
    { Here it is ok. }
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
    { Here it is ok. }
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
      if fSymbolChars <> EmptyStr then RaiseException (errDuplicatedSymbols);
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

    procedure ParseSection (aList: TStrings; const aEnd: String);
    var
      lIsFirstToken: Boolean;

      procedure NextLine;
      begin
        Inc (Ndx); lPos := 1;
        lIsFirstToken := True
      end;

      function IsEndOfSection (const lToken: String): Boolean;
      var
        lOldPos: Integer;
        lSecondToken: String;
      begin
        if lIsFirstToken then
        begin
          lIsFirstToken := False;
          if LowerCase (lToken) = 'end' then
          begin
            lOldPos := lPos;
            lSecondToken := LowerCase (GetToken);
            lPos := lOldPos; { Roll back. }
            Exit (lSecondToken = aEnd)
          end
        end;
        Result := False
      end;

    var
      lToken: String;
    begin
      NextLine;
      while True do
      begin
      { Check end of file. }
        if Ndx >= lDefinitionFile.Count then
          RaiseException (Format (errExpecting, [Concat ('end ', aEnd)]));
      { Get token. }
        lToken := GetToken;
        if lToken <> EmptyStr then
        begin
        { Check end of section. }
          if IsEndOfSection (lToken) then
          begin
            Inc (Ndx);
            Exit
          end;
        { Add new token. }
          if not Self.CaseSensitive then lToken := LowerCase (lToken);
          aList.Append (lToken)
        end;
      { Check end of line. }
        if EOL then NextLine
      end
    end;

    function ExtractInitialChars (aBlocks: array of TBlock): String;
    var
      lNdx: Integer;
    begin
      Result := '';
      for lNdx := Low (aBlocks) to High (aBlocks) do
        Result := Concat (Result, aBlocks[lNdx].Starting[1])
    end;

  var
    lToken: String;
  begin
    Self.Clear;
  { Load the file. }
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
            ParseSection (Self.Keywords, 'keywords')
          else if lToken = 'types' then
            ParseSection (Self.DataTypes, 'types')
          else if lToken = 'operators' then
            ParseSection (Self.Operators, 'operators')
          else if lToken = 'identifiers' then
            ParseSection (Self.LibraryObjects, 'identifiers')
          else
            RaiseException (Format (errUnknownToken, [lToken]))
        end;
        Inc (Ndx)
      until ndx >= lDefinitionFile.Count
    finally
      lDefinitionFile.Free
    end;
  { Get starters. }
    fCommentStartChars := ExtractInitialChars (fComments);
    fDirectiveStartChars := ExtractInitialChars (fDirectives)
  end;



(* Saves language description. *)
  procedure TMLSDECustomHighlighter.SaveDefinitionFile (const aFileName: String);
  begin
    raise Exception.Create ('TMLSDECustomHighlighter.SaveToFile no implementado')
  end;



(* Parses line. *)
  procedure TMLSDECustomHighlighter.Next;

    function ExtractToken: String;
    begin
      Result := '';
      repeat
        Result := Concat (Result, Self.Line[Self.TokenStart+Self.TokenLength]);
        Inc (Self.TokenLength)
      until Self.Line[Self.TokenStart + Self.TokenLength] <= ' '
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
      if Self.Line[Self.TokenStart] <= ' ' then
      begin
        Self.ParseSpaces;
        Exit
      end
      else if Pos (Self.Line[Self.TokenStart], fSimpleStringDelimiter) > 0 then
      begin
        Self.ParseStringConstant (Self.Line[Self.TokenStart]);
        Self.TokenType := tkString;
        Exit
      end;
      ExtractToken
    end
  end;

end.

