unit Utils;
(*< Implements several utility functions. *)
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
    Classes, Types;

  const
  (* Max number of observers. *)
    MaxObservers = 4;

  type
  (* A simple observer pattern implementation. *)
    TSubject = class (TObject)
    private
      fOwner: TObject;
      fObserverList: array [1..MaxObservers] of TNotifyEvent;
    public
    (* Constructor.
       @param(aOwner The actual subject.  Will be passed as @code(Sender) to
        the callback methods.) *)
      constructor Create (aOwner: TObject); virtual;
    (* Adds an observer. *)
      procedure AddObserver (aObserverCallback: TNotifyEvent);
    (* Removes observer. *)
      procedure RemoveObserver (aObserverCallback: TNotifyEvent);
    (* Notifies all observers. *)
      procedure Notify;
    end;


(* Encodes a name (i.e. file path) so all characters are valid for identifiers.
 *)
  function NormalizeIdentifier (const aName: String): String;
(* Orders the characters of the given string. *)
  procedure OrderString (var aString: String);
(* Tells if character is in the string.  String should be ordered. *)
  function CharInStr (const aChar: Char; const aString: String): Boolean;
(* Finds the string in the list or returns -1 if not found. *)
  function FindString (const aNeedle: String; aHaystack: TStringDynArray)
    : Integer;
(* Joins the string array in a single string. *)
  function JoinStrings (aStrings: TStringDynArray; const Delimiter: String):
    String;
(* Extracts file extension @bold(without dot and @italic(lowercased)). *)
  function GetFileExtension (const aFileName: String): String;

implementation

  uses
    sysutils;

(* Encodes name. *)
  function NormalizeIdentifier (const aName: String): String;
  const
    lValidChars = [ 'A'..'Z', '0'..'9', 'a'..'z', '_'];
  var
    Cnt: Integer;
  begin
    Result := '';
    for Cnt := 1 to Length (aName) do
      if aName[Cnt] in lValidChars then
        Result := Concat (Result + aName[Cnt])
      else
        Result := Result + '__'
  end;



(* Orders string. *)
  procedure OrderString (var aString: String);
  var
    lNdx: Integer;
    lOrdered: Boolean;
    lTmp: Char;
  begin
    repeat
      lOrdered := True;
      for lNdx := 1 to Length (aString) - 1 do
        if aString[lNdx] > aString[lNdx + 1] then
        begin
          lOrdered := False;
          lTmp := aString[lNdx];
          aString[lNdx] := aString[lNdx + 1];
          aString[lNdx + 1] := lTmp
        end;
    until lOrdered
  end;



(* Search for char. *)
  function CharInStr (const aChar: Char; const aString: String): Boolean;
  var
    lLeft, lRight, lMiddle: Integer;
  begin
    lLeft := 1;
    lRight := Length (aString);
    while lLeft <= lRight do
    begin
      lMiddle := (lLeft + lRight) div 2;
      if aString[lMiddle] > aChar then
        lRight := lMiddle - 1
      else if aString[lMiddle] < aChar then
        lLeft := lMiddle + 1
      else
        Exit (True)
    end;
    Result := False
  end;



(* Find string. *)
  function FindString(const aNeedle: String; aHaystack: TStringDynArray)
    : Integer;
  var
    Ndx: Integer;
  begin
    for Ndx := Low (aHaystack) to High (aHaystack) do
      if aNeedle = aHaystack[Ndx] then Exit (Ndx);
    Result := -1
  end;



(* Join string. *)
  function JoinStrings(aStrings: TStringDynArray; const Delimiter: String
    ): String;
  var
    lNdx: Integer;
  begin
    Result := aStrings[0];
    if Length (aStrings) > 1 then
      for lNdx := 1 to Length (aStrings) - 1 do
        Result := Concat (Result, Delimiter, aStrings[lNdx])
  end;



(* Extracts file extension without dot. *)
  function GetFileExtension (const aFileName: String): String;
  begin
    Result := LowerCase (ExtractFileExt (aFileName));
    if Result = '.' then
      Result := ''
    else if Result <> '' then
      Result := RightStr (Result, Length (Result) -1)
  end;


(*
 * TSubject
 ***************************************************************************)

(* Constructor. *)
  constructor TSubject.Create (aOwner: TObject);
  var
    Ndx: Integer;
  begin
    inherited Create;
    fOwner := aOwner;
    for Ndx := Low (fObserverList) to High (fObserverList) do
      fObserverList[Ndx] := Nil
  end;



(* Adds observer. *)
  procedure TSubject.AddObserver(aObserverCallback: TNotifyEvent);
  var
    Ndx: Integer;
  begin
    for Ndx := Low (fObserverList) to High (fObserverList) do
      if not Assigned (fObserverList[Ndx]) then
      begin
        fObserverList[Ndx] := aObserverCallback;
        Exit
      end;
    raise Exception.Create ('No space for more observers!')
  end;



(* Removes observer. *)
  procedure TSubject.RemoveObserver(aObserverCallback: TNotifyEvent);
  var
    Ndx: Integer;
  begin
    for Ndx := Low (fObserverList) to High (fObserverList) do
      if fObserverList[Ndx] = aObserverCallback then
        fObserverList[Ndx] := Nil
  end;



(* Does notification. *)
  procedure TSubject.Notify;
  var
    Ndx: Integer;
  begin
    for Ndx := Low (fObserverList) to High (fObserverList) do
      if Assigned (fObserverList[Ndx]) then
      begin
        fObserverList[Ndx] (fOwner);
        Exit
      end
  end;

end.

