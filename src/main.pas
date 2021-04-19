unit Main;
(*<Implements the @link(MLSDEApplication) object. *)
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
    Configuration, Project,
    Classes;

  const
  (* Name for the environment configuration section. *)
    idEnvironmentConfig = 'environment';

  type
  (* Manages the environment configuration.

     This parses next command line options:@unorderedlist(
       @item(@code(--lang=<lang>) Forces the language to be used by the
	     application.  Currently it supports @code(en) @(English@) and
	     @code(es) @(Spanish@) only.)
     ) *)
    TEnvironmentConfiguration = class (TCustomConfiguration)
    private
      function GetLanguage: String;
      procedure SetLanguage (const aValue: String);
    public
    (* Writes help of the supported command line options. *)
      procedure PrintCommandLineHelp; override;
    (* Parses conmmand line options. *)
      procedure ParseCommandLineOptions; override;

    (* Application language. *)
      property Language: String read GetLanguage write SetLanguage;
    end;



  (* Defines the MLSDEApplication object.

     This is an idea borrowed from Lazarus:  Instead of having a bunch of global
     objects scattered around different units, all that is managed by a simple
     object.  Think as @code(MLSDEApplication) is the logic part of the
     application while the @code(Application) object manages the graphical
     interface.
     @seealso(MLSDEApplication) *)
    TMLSDEApplication = class (TObject)
    private
      fConfiguration: TConfiguration;
      fProject: TProject;

    (* Sets up the language translation. *)
      procedure SetUpLanguage;
    public
    (* Constructor. *)
      constructor Create;
    (* Destructor. *)
      destructor Destroy; override;
    (* Initializes the object. *)
      procedure Initialize;

    (* Application configuration. *)
      property Configuration: TConfiguration read fConfiguration;
    (* The currently loaded project. *)
      property Project: TProject read fProject;
    end;

  var
  (* Global reference to the MLSDE application object. *)
    MLSDEApplication: TMLSDEApplication;

implementation

  uses
    GUIUtils,
    LCLTranslator, { No need to put this in any other place. }
    Forms, sysutils;

  const
  (* Directory where .po/.mo files are. *)
    LangDir = 'languages';

  resourcestring
    messageSelectAppLanguage = 'Selects the application language.';

    messageCantCreateConfigDir = 'Cannot create configuration directory.'#10+
                                 'Configuration changes won''t be saved.';

(*
 * TEnvironmentConfiguration
 ***************************************************************************)

  const
  (* Section to store options. *)
    EnvironmentSection = idEnvironmentConfig;

  function TEnvironmentConfiguration.GetLanguage: String;
  begin
    Result := Self.GetValue (EnvironmentSection, 'language', '')
  end;

  procedure TEnvironmentConfiguration.SetLanguage (const aValue: String);
  begin
    Self.SetValue (EnvironmentSection, 'language', aValue)
  end;



(* Prints command line help. *)
  procedure TEnvironmentConfiguration.PrintCommandLineHelp;
  begin
    WriteLn ('  --lang=[en|es]:  ', messageSelectAppLanguage)
  end;



(* Command line options. *)
  procedure TEnvironmentConfiguration.ParseCommandLineOptions;
  var
    lOption: String;
  begin
    lOption := LowerCase (Application.GetOptionValue ('lang'));
    if (lOption = 'en') or (lOption = 'es') then
      Self.SetLanguage (lOption);
  { TODO: Wrong lOption! }
  end;



(*
 * TMLSDEApplication
 ***************************************************************************)

(* Sets language. *)
  procedure TMLSDEApplication.SetUpLanguage;
  begin
    SetDefaultLang (
      TEnvironmentConfiguration (
        fConfiguration.FindConfig (EnvironmentSection)
      ).Language,
      LangDir
    )
  end;



(* Constructor. *)
  constructor TMLSDEApplication.Create;
  begin
    inherited Create;
    fConfiguration := TConfiguration.Create;
    fProject := TProject.Create
  end;



(* Destructor. *)
  destructor TMLSDEApplication.Destroy;
  begin
    fProject.Free;
    fConfiguration.Free;
    inherited Destroy
  end;



(* Initializes the object. *)
  procedure TMLSDEApplication.Initialize;
  begin
  { Add configuration objects. }
    fConfiguration.AddSection (TEnvironmentConfiguration.Create, EnvironmentSection);
    fConfiguration.AddSection (TProjectConfiguration.Create, idProjectConfig);
  { Load configuration file. }
    fConfiguration.Initialize;
  { Parse command line options. }
    Self.SetUpLanguage; { Needed to translate command line help. }
    if Application.HasOption ('h', 'help') then
    begin
      fConfiguration.PrintCommandLineHelp;
      Application.Terminate;
      Exit
    end;
  { Only if running. }
    if not Application.Terminated then
    begin
    { Configuration directory must exist. }
      if not DirectoryExists (fConfiguration.ConfigurationDir) then
        if not CreateDir (fConfiguration.ConfigurationDir) then
          ShowWarning (messageCantCreateConfigDir);
    { Configuration initiated. }
      fConfiguration.Apply
    end
  end;

end.

