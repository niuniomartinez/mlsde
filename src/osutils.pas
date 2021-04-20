unit osUtils;
(*<Implements operating system specific stuff. *)
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

(* Returns file version number. *)
  function GetFileVersion: String;

implementation

  uses
    fileinfo, sysutils,
{$IFDEF WINDOWS}
    winpeimagereader,
    shlobj            { For special directories. }
{$ELSE}
 {$IF DEFINED(MACOS) OR DEFINED(DARWIN)}
    machoreader
 {$ELSE}
    elfreader
 {$ENDIF}
{$ENDIF}
  ;



(* Returns file version number. *)
  function GetFileVersion: String;
  var
    lFileVersionInfo: TFileVersionInfo;
  begin
    lFileVersionInfo := TFileVersionInfo.Create (Nil);
    try
      lFileVersionInfo.ReadFileInfo;
      Result := lFileVersionInfo.VersionStrings.Values['FileVersion']
    finally
      lFileVersionInfo.Free
    end
  end;

end.

