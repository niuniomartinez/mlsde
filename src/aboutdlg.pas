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
    Forms, StdCtrls, ButtonPanel, ComCtrls, Classes;

  type
  (* Shows legal and contact information about the application.

     It is used by @link(TMainWindow), wich creates and destroys it.
   *)
    TAboutDialog = class (TForm)
      PageControl: TPageControl;
       TabSheetGeneral: TTabSheet;
        LblTitle: TLabel;
        LblDescription: Tlabel;
        LblWebsite: Tlabel;
        LblCopyright: Tlabel;
       TabSheetLicense: TTabSheet;
         MemoLicense: TMemo;
      ButtonPannel: TButtonPanel;
    (* Executed when dialog is activated. *)
      procedure FormActivate (Sender: TObject);
    (* User clicked on web URL. *)
      procedure LblWebsiteClick (Sender: TObject);
    end;

implementation

(* Implementation note:
     See that the license text is stored as a resource.  That makes the license
     easily modificable.  Maybe a better way is to set the license as a constant
     text and assign in runtime, though it is still quite easy to modify
     (specially the name).

     This also apply to the version number and web-site URI.
 *)

  uses
   { Not used while alpha/beta:
     osUtils,
   }
    fileinfo, LCLIntf;

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
    LblWebsite.Caption := 'https://github.com/niuniomartinez/mlsde';
  { Get version from executable properties. }
    lFileVersionInfo := TFileVersionInfo.Create (Self);
    try
      lFileVersionInfo.ReadFileInfo;
      LblTitle.Caption := 'MLSDE '
                        + '1.α.0'
{ Use next line in production (non alpha nor beta).
                        + GetFileVersion
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

