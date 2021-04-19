unit ConfigurationFrameEnvironment;
(*<Defines the frame used for Environment Configuration. *)
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
    ConfigurationDialogFrame, DividerBevel, StdCtrls, ComboEx;

  type
  (* Contains and manages the controls that allows to configure the
     environment. *)
    TEnvironmentConfigurationFrame = class (TConfigurationFrame)
      TitleLanguage: TDividerBevel;
        Listlanguages: TComboBoxEx;
    public
    (* Initializes the frame.

       It sets component values. *)
      procedure Initialize; override;
    (* User accepted configuration. *)
      procedure AcceptConfiguration; override;
    end;

implementation

  uses
    Main;

{$R *.lfm}

  const
  (* List of language names.

     This list must be in sync with the ListLanguages component list.  If you
     change one you MUST change the other. *)
    Languages: array [0..2] of String = (
      '', 'en', 'es'
    );

(* Get the language name (ISO) and returns the list index. *)
  function GetLanguageIndex (aName: String): Integer;
  var
    Ndx: Integer;
  begin
    aName := LowerCase (aName);
    for Ndx := Low (Languages) to High (Languages) do
      if aName = Languages[Ndx] then Exit (Ndx);
  { No language found (or not ISO). }
    Result := 0 { Default. }
  end;



(* Get the language list index and returns the name (ISO). *)
  function GetLanguageName (const Index: Integer): String;
  begin
    if (1 > Index) or (Index > High (Languages)) then Exit (''); { Default. }
    Result := Languages[Index]
  end;



(*
 * TEnvironmentConfigurationFrame
 **************************************************************************)

(* Initialize. *)
  procedure TEnvironmentConfigurationFrame.Initialize;
  var
    lEnvironmentConfiguration: TEnvironmentConfiguration;
  begin
    lEnvironmentConfiguration := TEnvironmentConfiguration (
      MLSDEApplication.Configuration.FindConfig (idEnvironmentConfig)
    );
  { Languaje. }
    Listlanguages.ItemIndex :=
      GetLanguageIndex (lEnvironmentConfiguration.Language)
  end;



(* User accepted configuration. *)
  procedure TEnvironmentConfigurationFrame.AcceptConfiguration;
  var
    lEnvironmentConfiguration: TEnvironmentConfiguration;
    lLanguageId: String;
  begin
    lEnvironmentConfiguration := TEnvironmentConfiguration (
      MLSDEApplication.Configuration.FindConfig (idEnvironmentConfig)
    );
  { Language. }
    lLanguageId := GetLanguageName (Listlanguages.ItemIndex);
    if lLanguageId <> lEnvironmentConfiguration.Language then
    begin
      lEnvironmentConfiguration.Language := lLanguageId;
      Self.NeedsToReinitialize
    end
  end;

end.

