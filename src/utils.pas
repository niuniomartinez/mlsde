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

(* Encodes a name (i.e. file path) so all characters are valid for identifiers.
 *)
  function EncodeName (const aName: String): String;

implementation

(* Encodes name. *)
  function EncodeName (CONST aName: String): String;
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

end.

