UNIT AutocompletionUtils;
(*<Defines utils used by editor's autocompletion.
 *)
(*
  Copyright (c) 2018 Guillermo Martínez J.
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

INTERFACE
  USES
    Classes;

  CONST
  (* Default minimun number of characters for strings added to the word list.
     @seealso(TAutocompletionWordList.MinChars)
   *)
    MIN_CHARS = 3;

  TYPE
  (* Contains and manages the words used by the autocompletion. *)
    TAutocompletionWordList = CLASS (TObject)
    PRIVATE
      fMinChars: INTEGER;
      fWordList: TStringList;
    PUBLIC
    (* Constructor. *)
      CONSTRUCTOR Create;
    (* Destructor. *)
      DESTRUCTOR Destroy; OVERRIDE;
    (* Removes all words from list. *)
      PROCEDURE Clear;
    (* Adds a word or a line to the list.

       This method parses the given text and extracts separate words. *)
      PROCEDURE Add (aText: STRING); OVERLOAD;
    (* Adds a list of strings to the list. *)
      PROCEDURE Add (aText: TStrings); OVERLOAD;
    (* Get a list of words that fits the given text.
       @param(aText The text suggestion.)
       @param(aList This object will be filled with words.) *)
      PROCEDURE GetWordList (aText: STRING; aList: TStrings);

    (* Minimun number of characters for strings added to the word list.  Any
       word with less characters will be ignored.

       By default it is @link(MIN_CHARS). *)
      PROPERTY MinChars: INTEGER READ fMinChars WRITE fMinChars;
    END;

(* Checks if given character is a separator.

   Note that it assumes ASCII instead of UNICODE! *)
  FUNCTION IsSeparator (CONST aChar: CHAR): BOOLEAN;

IMPLEMENTATION

  USES
    sysutils;

  CONST
  (* Valid characters for identifiers.  ASCII only at the moment.  Also, it
     seems it depends on the synth used. *)
    VALID_CHARS = ['0'..'9', 'a'..'z', 'A'..'Z', '_'];
  (* Valid characters to initiate identifiers. *)
    VALID_INIT_CHARS = ['a'..'z', 'A'..'Z', '_'];

   (* Separators.
    *
    * It is commented because I'm thinking in ASCII instead of UTF-8 wich is
    * used by SynEdit.
    *)
 //    SEPARATORS = [
     { Second character is a tab. }
 //      ' ', '	',
 //      '!', '?', ',', '.', ';', ':',
 //      '+', '-', '*', '\', '/', '%', '<', '>', '=',
 //      '(', ')', '[', ']', '{', '}', '"', '''',
 //      '|', '#', '@', '^', '`',
 //      '~'
 //    ];



(* Checks if given character is a separator. *)
  FUNCTION IsSeparator (CONST aChar: CHAR): BOOLEAN;
  BEGIN
    RESULT := NOT (aChar IN VALID_CHARS)
  END;



(*
 * TAutocompletionWordList
 *****************************************************************************)

(* Constructor. *)
  CONSTRUCTOR TAutocompletionWordList.Create;
  BEGIN
    INHERITED Create;
  { The word list. }
    fWordList := TStringList.Create;
    fWordList.Duplicates := dupIgnore;
  { Autocompletion configuration. }
    fWordList.CaseSensitive := TRUE; { TODO: Configuration. }
    fWordList.Sorted := TRUE;
    fMinChars := MIN_CHARS
  END;



(* Destructor. *)
  DESTRUCTOR TAutocompletionWordList.Destroy;
  BEGIN
    fWordList.Free;
    INHERITED Destroy
  END;



(* Remove words. *)
  PROCEDURE TAutocompletionWordList.Clear;
  BEGIN
    fWordList.Clear
  END;



(* Adds word or line to list. *)
  PROCEDURE TAutocompletionWordList.Add (aText: STRING);
  VAR
    PosC: INTEGER;
    Word: STRING;
  BEGIN
  { Be sure line isn't empty. }
    aText := Trim (aText); IF aText = '' THEN EXIT;
    PosC := 1;
    REPEAT
    { Removes non alphanumeric characters. }
      WHILE (PosC <= Length (aText)) AND NOT (aText[PosC] IN VALID_INIT_CHARS)
      DO
        INC (PosC);
      IF PosC > Length (aText) THEN EXIT;
    { Extract Word. }
      Word := '';
      REPEAT
        Word := Word + aText[PosC];
        INC (PosC)
      UNTIL (PosC > Length (aText)) OR NOT (aText[PosC] IN VALID_CHARS);
    { Add Word to list. }
      IF Length (Word) >= fMinChars THEN
        fWordList.Add (Word)
    UNTIL PosC > Length (aText)
  END;



(* Adds text content to list. *)
  PROCEDURE TAutocompletionWordList.Add (aText: TStrings);
  VAR
    Ndx: INTEGER;
  BEGIN
    IF aText.Count > 0 THEN
      FOR Ndx := aText.Count - 1 DOWNTO 0 DO SELF.Add (aText[Ndx])
  END;



(* Gets suggested word list. *)
  PROCEDURE TAutocompletionWordList.GetWordList (aText: STRING; aList: TStrings);
  VAR
    Ndx: INTEGER;
    Word: STRING;
  BEGIN
    aText := Trim (aText);
    aList.Clear;
  { Sometimes, CurrentString includes separators (seems to depend to the
    syntax) so let's do some cleaning trying to emulate Vim. }
    WHILE (aText <> '') AND NOT (aText[1] IN VALID_CHARS) DO
      aText := RightStr (Word, Length (aText) - 1);
  { If there's no input, add all words. }
    IF Length (aText) < 1 THEN
      aList.AddStrings (fWordList)
    ELSE
  { In other case, looks for word that starts with the given text. }
      FOR Ndx := 0 TO fWordList.Count - 1 DO
        IF Pos(
          LowerCase (aText), LowerCase (fWordList[Ndx])
        ) = 1 THEN
          aList.Add (fWordList[Ndx])
  END;

END.
