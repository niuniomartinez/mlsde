unit ProgressDialogForm;
(*<Implements a dialog that shows a progress bar. *)
(*
  Copyright (c) 2020 Guillermo Martínez J.

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
    Forms, StdCtrls, ComCtrls, ButtonPanel, Classes;

  type
  (* A dialog that shows a progress bar.

     The way to use it is to create the object, set the label and bar
     properties and show it (not modal!).  Then update the bar (and the label
     too), calling @code(Application.ProcessMessages) to be sure it updates and
     the application and GUI don't freeze.  Updating the label and/or the
     progress bar would implicitly call @code(ProcessMessages) in some systems
     but @bold(it may not).

     When shown, it disables the main window, re-enabling when closed.

     Note that pressing the @code(Cancel) button will not close the dialog:
     that should be done by the cancelation code.

     An example of use is how it's used by @link(TProject) and
     @link(TProjectView) to cancel directory scanning.

     @seealso(ProgressDlg) *)
    TProgressDlg = class (TForm)
      ButtonPanel: TButtonPanel;
      LabelText: TLabel;
      ProgressBar: TProgressBar;

    (* Prepares the dialog. *)
      procedure FormCreate (Sender: TObject);
    (* Shows the dialog. *)
      procedure FormShow (Sender: TObject);
    (* User pressed the cancel button. *)
      procedure CancelButtonClick (Sender: TObject);
    (* Avoids dialog closing. *)
      procedure FormClose (Sender: TObject; var CloseAction: TCloseAction);
    (* Destroys the dialog. *)
      procedure FormDestroy (Sender: TObject);
    private
      fOnCancelAction: TNotifyEvent;

      procedure SetOnCancelAction (const aValue: TNotifyEvent); inline;
    public
    (* If set, this will be called if the @code(Cancel) button is pressed.

       Assigning this property will change the @code(Cancel) button
       @code(Enable) property state. *)
      property OnCancelAction: TNotifyEvent
	read fOnCancelAction write SetOnCancelAction;
    end;

  var
  (* Global reference for the dialog. *)
    ProgressDlg: TProgressDlg;

implementation

  uses
    MainForm;

{$R *.lfm}

{$PUSH}
  {$WARN 5024 OFF : Parameter "$1" not used}

(* Prepares the dialog. *)
  procedure TProgressDlg.FormCreate (Sender: TObject);
  begin
    Self.ProgressBar.Style := pbstMarquee
  end;



(* Shows the dialog. *)
  procedure TProgressDlg.FormShow (Sender: TObject);
  begin
    MainWindow.Enabled := False
  end;



(* User pressed the cancel button. *)
  procedure TProgressDlg.CancelButtonClick (Sender: TObject);
  begin
    if Assigned (fOnCancelAction) then fOnCancelAction (Self)
  end;



(* Avoids dialog closing. *)
  procedure TProgressDlg.FormClose (
    Sender: TObject;
    var CloseAction: TCloseAction
  );
  begin
    CloseAction := caNone
  end;



(* Response to user pressing the close button. *)
  procedure TProgressDlg.FormDestroy (Sender: TObject);
  begin
    MainWindow.Enabled := True
  end;

{$POP}



(* Sets the OnCancelAction property and updates Cancel button state. *)
  procedure TProgressDlg.SetOnCancelAction (const aValue: TNotifyEvent);
  begin
    if fOnCancelAction <> aValue then
    begin
      fOnCancelAction := aValue;
      Self.ButtonPanel.CancelButton.Enabled := aValue <> Nil
    end
  end;

end.

