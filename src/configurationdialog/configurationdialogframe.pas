unit ConfigurationDialogFrame;
(*<Defines the base class for the frames used by
  @link(TConfigurationDlg). *)
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
    Classes, Forms;

  type
  (* Base class for frames used by @link(TConfigurationDlg).

     It is an abstract class. *)
    TConfigurationFrame = class (TFrame)
    private
      fNeedReinitialize: Boolean;
    protected
    (* Call this if the applied configuration needs the application to be
       reinitialized. *)
      procedure NeedsToReinitialize; inline;
    public
    (* Constructor. *)
      constructor Create (aOwner: TComponent); override;
    (* Initializes the frame.

       This is called by the configuration dialog in the beginning.  It should
       set the component values. *)
      procedure Initialize; virtual; abstract;
    (* User accepted the configuration changes. *)
      procedure AcceptConfiguration; virtual; abstract;

    (* Tells if current configuration needs the application to be reinitialized.
     *)
      property NeedInitialize: Boolean read fNeedReinitialize;
    end;

implementation

{$R *.lfm}

(*
 * TConfigurationFrame
 **************************************************************************)

(* Application needs to initialize. *)
  procedure TConfigurationFrame.NeedsToReinitialize;
  begin
    fNeedReinitialize := True
  end;



(* Constructor. *)
  constructor TConfigurationFrame.Create (aOwner: TComponent);
  begin
    inherited Create (aOwner);
    fNeedReinitialize := False
  end;

end.

