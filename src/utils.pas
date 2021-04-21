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
    Types;

(* Encodes a name (i.e. file path) so all characters are valid for identifiers.
 *)
  function NormalizeIdentifier (const aName: String): String;
(* Finds the string in the list or returns -1 if not found. *)
  function FindString (const aNeedle: String; aHaystack: TStringDynArray)
    : Integer;
(* Extracts file extension @bold(without dot and @italic(lowercased)). *)
  function GetFileExtension (const aFileName: String): String;

implementation

  uses
    sysutils;

(* Encodes name. *)
  function NormalizeIdentifier (CONST aName: String): String;
  const
    lValidChars = [ 'A'..'Z', '0'..'9', 'a'..'z', '_'];
  var
    Cnt: Integer;
  begin
    Result := '';
    for Cnt := 1 to Length (aName) do
      if aName[Cnt] in lValidChars then
        Result := Result + aName[Cnt]
      else
        Result := Result + '__'
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



(* Extracts file extension without dot. *)
  function GetFileExtension (const aFileName: String): String;
  begin
    Result := LowerCase (ExtractFileExt (aFileName));
    if Result = '.' then
      Result := ''
    else if Result <> '' then
      Result := RightStr (Result, Length (Result) -1)
  end;

end.

