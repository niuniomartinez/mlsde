unit AboutDlg;
(*<Implements an "About..." dialog. *)
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
    Forms, StdCtrls, ButtonPanel, Classes;

  type
  (* Shows legal and contact information about the application.

     It is used by @link(TMainWindow), wich creates and destroys it.
   *)
    TAboutDialog = class (TForm)
      LblWebsite: Tlabel;
      LblCopyright: Tlabel;
      LblDescription: Tlabel;
      LblTitle: TLabel;
      ButtonPannel: TButtonPanel;
    (* Executed when dialog is activated. *)
      procedure FormActivate (Sender: TObject);
    (* User clicked on web URL. *)
      procedure LblWebsiteClick (Sender: TObject);
    end;

implementation

  uses
    fileinfo, LCLIntf,
  { TODO: Use $IFDEF to include only the appropriate one.
  }
    winpeimagereader, elfreader, machoreader;

{$R *.lfm}

(*
 * TAboutDialog
 *****************************************************************************)

(* Activates dialog. *)
  procedure TAboutDialog.FormActivate (Sender: TObject);
  var
    lFileVersionInfo: TFileVersionInfo;
  begin
  { Try to avoid change the URL using translations.

    Note that it is still possible to change the URI... }
    LblWebsite.Caption := 'https://www.sf.net/p/mlsde';
  { Get version from executable properties. }
    lFileVersionInfo := TFileVersionInfo.Create (Self);
    try
      lFileVersionInfo.ReadFileInfo;
      LblTitle.Caption := 'MLSDE '
                        + '1.α.0'
{ Use next line in production (non alpha nor beta).
                        + lFileVersionInfo.VersionStrings.Values['FileVersion']
}
    finally
      lFileVersionInfo.Free
    end
  end;



(* User clicked on web URL. *)
  procedure TAboutDialog.LblWebsiteClick (Sender: TObject);
  begin
    OpenURL ((Sender AS TLabel).Caption)
  end;

end.

