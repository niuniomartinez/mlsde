unit Autocompletion;
(*<Defines the autocompletion subsystem. *)
(*
  Copyright (c) 2018-2021 Guillermo Martínez J.
  See file AUTHORS for a full list of authors.

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
    Configuration,
    Classes;

  const
  (* Identifies autocompletion configuration. *)
    idAutocompletionConfig = 'autocompletion';

  type
  (* Manages autocompletion configuration. *)
    TAutocompletionConfiguration = class (TCustomConfiguration)
    private
      function GetMinChars: Byte;
      procedure SetMinChars(const aValue: Byte);
    public
    (* Minimun number of characters per word by default. *)
      property MinChars: Byte read GetMinChars write SetMinChars;
    end;



  (* Contains and manages the words used by the autocompletion. *)
    TAutocompletionWordList = class (TObject)
    private
      fMinWordLength: Byte;
      fWordList: TStringList;

      procedure AutocompletionConfigurationChanged (aSender: TObject);
      procedure ProjectClosed (aSender: TObject);
    public
    (* Constructor. *)
      constructor Create;
    (* Destructor. *)
      destructor Destroy; override;
    (* Initializes wordlist. *)
      procedure Initialize;
    (* Removes all words from list. *)
      procedure Clear;
    (* Adds a word or a line to the list.

       This method separates words. *)
      procedure Add (aText: String);
    (* Adds alist of words or a file to the list. *)
      procedure AddText (aText: TStrings);
    (* Returns a list of words that fits the given text.
       @param(aText The text suggestion.)
       @param(aList Where to store the word list.) *)
      procedure GetWordSuggestions (aText: String; aList: TStrings);
    end;

(* Checks if given character is a separator.

   Note that it assumes ASCII only! *)
  function IsSeparator (const aChar: Char): Boolean;

implementation

  uses
    Main,
    sysutils;

  const
  (* Minimun number of characters per word by default. *)
    MinCharsWord = 3;
  (* Valid characters for identifiers.  ASCII only at the moment.  Also, it
     seems it depends on the synth used. *)
    VALID_CHARS = ['0'..'9', 'a'..'z', 'A'..'Z', '_'];
  (* Valid characters to initiate identifiers. *)
    VALID_INIT_CHARS = ['a'..'z', 'A'..'Z', '_'];

(* Checks for separators. *)
  function IsSeparator (const aChar: Char): Boolean;
  begin
    Result := not (aChar in VALID_CHARS)
  end;



(*
 * TAutocompletionConfiguration
 ************************************************************************)

  function TAutocompletionConfiguration.GetMinChars: Byte;
  begin
    Result :=
      Self.GetIntValue (idAutocompletionConfig, 'min_length', MinCharsWord)
  end;

  procedure TAutocompletionConfiguration.SetMinChars(const aValue: Byte);
  begin
    Self.SetIntValue (idAutocompletionConfig, 'min_length', aValue)
  end;



(*
 * TAutocompletionConfiguration
 ************************************************************************)

  procedure TAutocompletionWordList.AutocompletionConfigurationChanged
    (aSender: TObject);
  var
    lConfiguration: TAutocompletionConfiguration absolute aSender;
  begin
    fMinWordLength := lConfiguration.MinChars
  { TODO: Rescan? }
  end;

  procedure TAutocompletionWordList.ProjectClosed (aSender: TObject);
  begin
    Self.Clear
  end;



(* Constructor. *)
  constructor TAutocompletionWordList.Create;
  begin
    inherited Create;
    fWordList := TStringList.Create;
    fWordList.Duplicates := dupIgnore;
    fWordList.CaseSensitive := False;
    fWordList.Sorted := True
  end;



(* Destructor. *)
  destructor TAutocompletionWordList.Destroy;
  begin
    fWordList.Free;
    inherited Destroy
  end;



(* Initializes. *)
  procedure TAutocompletionWordList.Initialize;
  var
    lConfiguration: TAutocompletionConfiguration;
  begin
    lConfiguration := TAutocompletionConfiguration (
      MLSDEApplication.Configuration.FindConfig (idAutocompletionConfig)
    );
    lConfiguration.Subject.AddObserver (
      @Self.AutocompletionConfigurationChanged
    );
    MLSDEApplication.Project.onClose := @Self.ProjectClosed;
    fMinWordLength := lConfiguration.MinChars
  end;



(* Clears list. *)
  procedure TAutocompletionWordList.Clear;
  begin
    fWordList.Clear
  end;



(* Adds word or line to the list. *)
  procedure TAutocompletionWordList.Add (aText: String);
  var
    lPosC: Integer;
    lWord: String;
  begin
  { Be sure line isn't empty. }
    aText := Trim (aText); if aText = EmptyStr then Exit;
    lPosC := 1;
    repeat;
    { Removes non alphanumeric characters. }
      while (lPosC <= Length (aText)) and not (aText[lPosC] in VALID_INIT_CHARS)
      do
        Inc (lPosC);
      if lPosC > Length (aText) then Exit;
    { Extract word. }
      lWord := EmptyStr;
      repeat
        lWord := Concat (lWord, aText[lPosC]);
        Inc (lPosC)
      until (lPosC > Length (aText)) or not (aText[lPosC] in VALID_CHARS);
    { Add word to list. }
      if Length (lWord) >= fMinWordLength then
        fWordList.Add (lWord)
    until lPosC > Length (aText)
  end;



(* Adds a text. *)
  procedure TAutocompletionWordList.AddText (aText: TStrings);
  var
    lLine: String;
  begin
    for lLine in aText do
      if Trim (lLine) <> EmptyStr then Self.Add (lLine)
  end;



(* Gets suggestion. *)
  procedure TAutocompletionWordList.GetWordSuggestions (
    aText: String;
    aList: TStrings
  );
  var
    lNdx: Integer;
  begin;
    aText := Trim (aText);
    aList.Clear;
  { Sometimes, CurrentString includes separators (seems to depend on the
    syntax) so let's do some cleaning trying to emulate Vim. }
    while (aText <> EmptyStr) and not (aText[1] in VALID_CHARS) do
      aText := RightStr (aText, Length (aText) - 1);
  { If there's no input, add all words. }
    if Length (aText) < 1 then
      aList.AddStrings (fWordList)
    else
  { Otherwise looks for words that start with the given text. }
      for lNdx := 0 to fWordList.Count - 1 do
        if Pos (
          LowerCase (aText), LowerCase (fWordList[lNdx])
        ) = 1 then
          aList.Add (fWordList[lNdx])
  { TODO: Include words that include aText, not starting with. }
  end;

end.

