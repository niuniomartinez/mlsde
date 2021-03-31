UNIT mlsdeScripting;
(*<Defines scripting interface with BAScript. *)
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
INTERFACE

  USES
    BAScript,
    Classes, LCLType;

  CONST
  (* Stack size, in bytes. *)
    STACK_SIZE = 256;
  (* Allows to identify virtual key codes of the "shift" keys. *)
    VK_SHIFT_KEYS = [
      VK_SHIFT, VK_LSHIFT, VK_RSHIFT,
      VK_CONTROL, VK_LCONTROL, VK_RCONTROL,
      VK_MENU, VK_LMENU, VK_RMENU
    { NOTE: Should include kana and kanji keys? }
    ];

  TYPE
  (* Contains and manages all interpretors and contexts.

     Note that interpretors are shared by groups.  For example, all sources
     editors shared the same interpretor. *)
    TScriptingSystem = CLASS (TComponent)
    PUBLIC
    (* Constructor. *)
      CONSTRUCTOR Create (aOwner: TComponent); OVERRIDE;
    (* Destructor. *)
      DESTRUCTOR Destroy; OVERRIDE;
    (* Initializes the scripting system.

       This method will register the libraries and load the default scripts
       where available.

       You can use it to reinitialize as it clears al the scripts.  Actually,
       the scripts will become invalid so anything that is hooked to a script
       should re-hook it! *)
      PROCEDURE Initialize;
    (* Clears the scripting system.

       This will remove all memory variables and clear the stacks.  Then it
       will try to execute the @code(:init) routine each script. *)
      PROCEDURE Clear;
    END;

(* Returns the name of the given VK_* constant.
   @seealso(GetShiftKeysId) @seealso(BuildKeyId)*)
  FUNCTION GetVKName (CONST aVK: INTEGER): STRING;
(* Returns a string that identifies the shift keys combination pressed.
   @seealso(GetVKName) @seealso(BuildKeyId) *)
  FUNCTION GetShiftKeysId (CONST Shifts: TShiftState): STRING;
(* Returns a identifier of the key combination.  This is used as trigger name
   in scripts.

   The identifier string is build as @code('Key<shifts><keyname>') where
   @italic(<shifts>) may be a combination of @code('shift'), @code('alt') and
   @code('ctrl'), and @italic(<keyname>) is the key name or the chars
   @code('VK') followed by the hexagesimal virtual-key number.
   @seealso(GetVKName) @seealso(GetShiftKeysId) *)
  FUNCTION BuildKeyId (CONST Shifts: TShiftState; CONST VK: INTEGER): STRING;



  VAR
  (* Global reference to the script conteiner. *)
    Scripts: TScriptingSystem;

IMPLEMENTATION

  USES
    Forms,
    sysutils;

  RESOURCESTRING
    NO_FILE_NAME = 'File name is empty!';
    NO_ABSOLUTE_PATH = 'Searching should not be used with absolute path.';
    WORKING_DIR = 'Looking at working directory';
    APP_DIR = 'Looking at application directory';
    DIDNT_FOUND_FILE = 'Didn''t found file "%s".';

  VAR
  (* Names of the VK_* constants.

   Note most are empty strings, only useful ones have content (i.e. those
   that can be used to trigger events). *)
    VK_NAMES: ARRAY [VK_UNKNOWN..VK_HIGHESTVALUE] OF STRING;

(* Returns the name of the VK_* constant in a way it can be used as an
   identifier. *)
  FUNCTION GetVKName (CONST aVK: INTEGER): STRING;
  BEGIN
    RESULT := VK_NAMES[aVK];
    IF RESULT = '' THEN RESULT := 'VK' + Format ('%.4X', [aVK])
  END;



(* Returns a string that identifies the shift keys combination pressed. *)
  FUNCTION GetShiftKeysID (CONST Shifts: TShiftState): STRING;
  BEGIN
    RESULT := '';
    IF ssShift IN Shifts THEN RESULT := 'shift';
    IF ssAlt   IN Shifts THEN RESULT := RESULT + 'alt';
    IF ssCtrl  IN Shifts THEN RESULT := RESULT + 'ctrl';
  END;



(* Returns a identifier of the key combination. *)
  FUNCTION BuildKeyId (CONST Shifts: TShiftState; CONST VK: INTEGER): STRING;
  BEGIN
    RESULT := 'Key' + GetShiftKeysID (Shifts) + GetVKName (VK)
  END;



(*
 * TScriptingSystem
 ***************************************************************************)

(* Constructor. *)
  CONSTRUCTOR TScriptingSystem.Create (aOwner: TComponent);
  BEGIN
    INHERITED Create (aOwner);
  END;



(* Destructor. *)
  DESTRUCTOR TScriptingSystem.Destroy;
  BEGIN
    INHERITED Destroy
  END;



(* Initializes the scripting system. *)
  PROCEDURE TScriptingSystem.Initialize;
  BEGIN
  END;



(* Clears the scripting system. *)
  PROCEDURE TScriptingSystem.Clear;
  BEGIN
  END;

VAR
  KeyV: INTEGER;

INITIALIZATION
{ May be not the best way to assign.

  The order is almost the same than in LCLType, but some are in different
  order to group by functionality. }
  VK_NAMES[VK_UNKNOWN] := 'unknown';

  VK_NAMES[VK_BACK]    := 'backspace';
  VK_NAMES[VK_TAB]     := 'tab';
  VK_NAMES[VK_RETURN]  := 'return';    { ...or 'intro'? }

  VK_NAMES[VK_SHIFT]   := 'shift';     { Do not distinguish left and right. }
  VK_NAMES[VK_CONTROL] := 'control';   { Do not distinguish left and right. }
  VK_NAMES[VK_LMENU]   := 'alt';
  VK_NAMES[VK_RMENU]   := 'altgr';     { This may confuse Apple users. }
  VK_NAMES[VK_PAUSE]   := 'pause';     { Comment says it's also "break" key. }

  VK_NAMES[VK_CAPITAL] := 'capslock';
  VK_NAMES[VK_NUMLOCK] := 'numlock';
  VK_NAMES[VK_SCROLL]  := 'scrolllock';

{ UNICODE isn't supported yet, but better to define as soon as possible. }
  VK_NAMES[VK_KANA]    := 'kana';
  VK_NAMES[VK_KANJI]   := 'kanji';

  VK_NAMES[VK_ESCAPE]  := 'escape';
  VK_NAMES[VK_SPACE]   := 'space'; { ...or 'spacebar'? }

  VK_NAMES[VK_PRIOR]   := 'pageup';
  VK_NAMES[VK_NEXT]    := 'pagedown';
  VK_NAMES[VK_END]     := 'end';
  VK_NAMES[VK_HOME]    := 'home';
  VK_NAMES[VK_UP]      := 'up';
  VK_NAMES[VK_DOWN]    := 'down';
  VK_NAMES[VK_LEFT]    := 'left';
  VK_NAMES[VK_RIGHT]   := 'right';
  VK_NAMES[VK_SELECT]  := 'select';
  VK_NAMES[VK_INSERT]  := 'insert';
  VK_NAMES[VK_DELETE]  := 'delete';

  VK_NAMES[VK_PRINT]   := 'printscreen';
  VK_NAMES[VK_HELP]    := 'help';   { Not sure wich one is this... }

  FOR KeyV := VK_0 TO VK_9 DO VK_NAMES[KeyV] := CHR (ORD ('0') + KeyV - VK_0);
  FOR KeyV := VK_A TO VK_Z DO VK_NAMES[KeyV] := CHR (ORD ('a') + KeyV - VK_A);

  FOR KeyV := VK_NUMPAD0 TO VK_NUMPAD9 DO
    VK_NAMES[KeyV] := 'numpad'+CHR (ORD ('0') + KeyV - VK_NUMPAD0);
  VK_NAMES[VK_MULTIPLY] := 'multiply';
  VK_NAMES[VK_ADD]      := 'add';
  VK_NAMES[VK_SUBTRACT] := 'substract';
  VK_NAMES[VK_DIVIDE]   := 'divide';
  VK_NAMES[VK_DECIMAL]  := 'decimal';;

  FOR KeyV := VK_F1 TO VK_F24 DO
    VK_NAMES[KeyV] := Format ('f%d', [KeyV + 1 - VK_F1]);
{ Next virtual keycodes are a bit "system dependant" and so they may refer to
  different keys in different keyboard configuration.  As for the comments in
  LCLType source they seem to be coherent with USA keyboard. }
  VK_NAMES[VK_LCL_EQUAL]      := 'equal';
  VK_NAMES[VK_LCL_MINUS]      := 'minus';
  VK_NAMES[VK_LCL_COMMA]      := 'comma';
  VK_NAMES[VK_LCL_POINT]      := 'period';
  VK_NAMES[VK_LCL_SLASH]      := 'slash';
  VK_NAMES[VK_LCL_BACKSLASH]  := 'backslash';
  VK_NAMES[VK_LCL_SEMI_COMMA] := 'colons'; { Not sure this is the best name. }
  VK_NAMES[VK_LCL_OPEN_BRAKET]  := 'openbraket';
  VK_NAMES[VK_LCL_CLOSE_BRAKET] := 'closebraket';
  VK_NAMES[VK_LCL_QUOTE]      := 'quotes'; { Not sure this is the best name. }
FINALIZATION
  { Not needed but Delphi forces this. } ;
END.
