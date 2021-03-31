UNIT UnitDlgAbout;
(*<Implements an "About..." dialog. *)
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

{$mode objfpc}{$H+}

INTERFACE

  USES
    Forms, StdCtrls, ExtCtrls, Classes;

  TYPE
  (* Shows legal and contact information about the application.

     It is used by @link(TVntPrincipal.AcercaDe), wich creates and destroys it.
   *)

    { TDlgAbout }

    TDlgAbout = CLASS (TForm)
      BtnClose: TButton;
      LblTitle: TLabel;
      BottomPanel: TPanel;
      MemoExplain: TLabel;
    (* Executed when dialog is activated. *)
      PROCEDURE FormActivate(Sender: TObject);
    (* User press close button. *)
      PROCEDURE BtnCloseClick(Sender: TObject);
    END;

  VAR
  (* Global reference to the dialog. *)
    DlgAbout: TDlgAbout;

IMPLEMENTATION

  USES
    fileinfo,
    winpeimagereader, elfreader, machoreader; { <- May be use DEFS to include only one. }

{$R *.lfm}

(*
 * TDlgAbout
 *****************************************************************************)

(* Activates dialog. *)
  PROCEDURE TDlgAbout.FormActivate (Sender: TObject);
  VAR
    FileVersionInfo: TFileVersionInfo;
  BEGIN
    FileVersionInfo := TFileVersionInfo.Create (SELF);
    TRY
      FileVersionInfo.ReadFileInfo;
      LblTitle.Caption := 'MLSDE '
                        + FileVersionInfo.VersionStrings.Values['FileVersion']
    FINALLY
      FileVersionInfo.Free
    END
  END;



(* Closes dialog. *)
  PROCEDURE TDlgAbout.BtnCloseClick (Sender: TObject);
  BEGIN
    SELF.Close
  END;

END.

