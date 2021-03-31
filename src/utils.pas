UNIT Utils;
(*<Some util stuff not big enough to have their own unit. *)
(*
  Copyright (c) 2014-2015, 2019 Guillermo Martínez J.

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

{$MODESWITCH ADVANCEDRECORDS}

INTERFACE

  USES
    Classes;

  TYPE
  (* Helper to manage notifications.

     This allows to activate or deactivate notifications, for example to avoid
     repetitive calls in a loop process. *)
    TMlsdeNotification = RECORD
    PRIVATE
      fOwner: TObject;
      fCallback: TNotifyEvent;
      fActive: BOOLEAN;
      fActivationCount: INTEGER;

      PROCEDURE SetCallback (CONST aCallback: TNotifyEvent); INLINE;
    PUBLIC
    (* Activates event. *)
      PROCEDURE Activate; INLINE;
    (* Deactivates event. *)
      PROCEDURE Deactivate; INLINE;
    (* Does notification. *)
      PROCEDURE NotifyEvent; INLINE;

    (* Event owner.  Shouldn't be @nil. *)
      PROPERTY Owner: TObject READ fOwner WRITE fOwner;
    (* The callback method. *)
      PROPERTY Callback: TNotifyEvent READ fCallback WRITE SetCallback;
    (* Notifycation state. *)
      PROPERTY Active: BOOLEAN READ fActive;
    END;

(* Encodes a name (i.e. file path) so all characters are valid identifiers. *)
  FUNCTION EncodeName (CONST aName: STRING): STRING;

(* Checks if given word is in the given word list. *)
  FUNCTION IsWordInList (CONST aWord: STRING; CONST aList: ARRAY OF STRING)
  : BOOLEAN;

(* Shows an error message. *)
  PROCEDURE ShowErrorMessage (CONST aErrorMessage: STRING);


IMPLEMENTATION

  USES
    Dialogs, sysutils;

(* Encodes name. *)
  FUNCTION EncodeName (CONST aName: STRING): STRING;
  CONST
    ValidChars = [ 'A'..'Z', '0'..'9', 'a'..'z', '_'];
  VAR
    Cnt: INTEGER;
  BEGIN
    RESULT := '';
    FOR Cnt := 1 TO Length (aName) DO
      IF aName[Cnt] IN ValidChars THEN
        RESULT := RESULT + aName[Cnt]
      ELSE
        RESULT := RESULT + '__'
  END;



(* Checks if word is in the list. *)
  FUNCTION IsWordInList (CONST aWord: STRING; CONST aList: ARRAY OF STRING)
  : BOOLEAN;
  VAR
    Ndx: INTEGER;
  BEGIN
    FOR Ndx := LOW (aList) TO HIGH (aList) DO
      IF aWord = aList[Ndx] THEN EXIT (TRUE);
    RESULT := FALSE
  END;


(* Muestra el error. *)
  PROCEDURE ShowErrorMessage (CONST aErrorMessage: STRING);
  BEGIN
    MessageDlg ('Error', aErrorMessage, mtError, [mbClose], 0)
  END;



(*
 * TMlsdeNotification
 ***************************************************************************)

(* Sets callback. *)
  PROCEDURE TMlsdeNotification.SetCallback (CONST aCallback: TNotifyEvent);
  BEGIN
    fCallback := aCallback;
    fActive := TRUE;
    fActivationCount := 0
  END;



(* Activates event. *)
  PROCEDURE TMlsdeNotification.Activate;
  BEGIN
    INC (fActivationCount);
    IF fActivationCount >= 0 THEN fActive := TRUE
  END;



(* Deactivates event. *)
  PROCEDURE TMlsdeNotification.Deactivate;
  BEGIN
    DEC (fActivationCount);
    fActive := FALSE
  END;



(* Notifies event. *)
  PROCEDURE TMlsdeNotification.NotifyEvent;
  BEGIN
    IF fActive AND (fCallback <> NIL) THEN fCallback (fOwner)
  END;

END.
