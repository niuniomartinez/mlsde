unit GUIUtils;
(*<Defines stuff that simplifies some GUI operations. *)
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
    Forms;

  resourcestring
  (* String "Error", to translate. *)
    ERROR_STR = 'Error';
  (* String "Warning", to translate. *)
    WARNING_STR = 'Warning';

(* Shows a simple information box.
   @param(aCaption The caption of the box.)
   @param(aMessage The message to be shown.) *)
  procedure ShowInformation (const aCaption, aMessage: String); overload;

(* Shows a simple information box.  Works like @code(Format) procedure so read
   RTL documentation to know more.
   @param(aCaption The caption of the box.)
   @param(aMessageFmt The message with format.)
   @param(aParams Parameters to be added to the @code(aMessageFmt).) *)
  procedure ShowInformation
    (const aCaption, aMessageFmt: String; aParams: array of const); overload;

(* Shows a warning message. *)
  procedure ShowWarning (const aMessage: String); overload;

(* Shows a warning message with parameters.  Works like @code(Format) procedure
   so read RTL documentation to know more
   @param(aMessageFmt The message with format.)
   @param(aParams Parameters to be added to the @code(aMessageFmt).)*)
  procedure ShowWarning (const aMessageFmt: String; aParams: array of const);
    overload;

(* Shows a simple error message. *)
  procedure ShowError (const aMessage: String); overload;

(* Shows an error message with parameters.  Works like @code(Format) procedure
   so read RTL documentation to know more
   @param(aMessageFmt The message with format.)
   @param(aParams Parameters to be added to the @code(aMessageFmt).)*)
  procedure ShowError (const aMessageFmt: String; aParams: array of const);
    overload;

(* Request a confirmation.  Shows the message with an "Yes/No" buttons.
   @return(@true or @false depending the  clicked button.) *)
  function ConfirmationDialog (const aCaption, aMessage: String): Boolean;


(* Shows the given form as modal dialog and destroys it when closed.
   @return(The @italic(modal result) of the dialog.) *)
  function RunModalDialog (aDialog: TForm): TModalResult;

implementation

  uses
    LCLType, sysutils;

(* Shows an information box. *)
  procedure ShowInformation (const aCaption, aMessage: String);
  begin
    Application.MessageBox (PCHAR (aMessage), PChar (aCaption))
  end;

  procedure ShowInformation (
    const aCaption, aMessageFmt: String;
    aParams: array of const
  );
  begin
    ShowInformation (aCaption, Format (aMessageFmt, aParams))
  end;



(* Shows a simple warning message. *)
  procedure ShowWarning (const aMessage: String);
  begin
    Application.MessageBox (
      PCHAR (aMessage), PChar (WARNING_STR),
      MB_OK or MB_ICONWARNING
    )
  end;

  procedure ShowWarning (const aMessageFmt: String; aParams: array of const);
  begin
    ShowWarning (Format (aMessageFmt, aParams))
  end;



(* Shows a simple error message. *)
  procedure ShowError (const aMessage: String);
  begin
    Application.MessageBox (
      PCHAR (aMessage), PChar (ERROR_STR),
      MB_OK or MB_ICONERROR
    )
  end;

  procedure ShowError (const aMessageFmt: String; aParams: array of const);
  begin
    ShowError (Format (aMessageFmt, aParams))
  end;



(* Asks confirmation. *)
  function ConfirmationDialog (const aCaption, aMessage: String): Boolean;
  begin
    Result := Application.MessageBox (
      PCHAR (aMessage), PChar (aCaption),
      MB_YESNO or MB_ICONQUESTION
    ) = IDYES
  end;



(* Shows the given form as modal. *)
  function RunModalDialog (aDialog: TForm): TModalResult;
  begin
    try
      Result := aDialog.ShowModal
    finally
      aDialog.Free
    end
  end;

end.

