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
    Autocompletion, Configuration, Project, SyntaxHighlighting,
    Classes, SysUtils;

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
      fTitle: String;

      function GetLanguage: String;
      procedure SetLanguage (const aValue: String);
      function GetWindowTitleProjectFirst: Boolean;
      procedure SetWindowTitleProjectFirst (const aValue: Boolean);
      function GetWindowTitleProjectShowDir: Boolean;
      procedure SetWindowTitleProjectShowDir (const aValue: Boolean);
      function GetShowMenu: Boolean;
      procedure SetShowMenu (const aValue: Boolean);
      function GetShowToolBar: Boolean;
      procedure SetShowToolBar (const aValue: Boolean);
      function GetShowStatusBar: Boolean;
      procedure SetShowStatusBar (const aValue: Boolean);

      procedure BuildTitleTemplate;
    public
    (* Returns help of the supported command line options. *)
      procedure GetCommandLineHelp (aStringList: TStrings); override;
    (* Parses conmmand line options. *)
      procedure ParseCommandLineOptions; override;

    (* Application language. *)
      property Language: String read GetLanguage write SetLanguage;
    (* Tells if main window title should show the project first.
       @seealso(WindowTitleProjectShowDir) @seealso(TitleTemplate) *)
      property WindowTitleProjectFirst: Boolean
        read GetWindowTitleProjectFirst write SetWindowTitleProjectFirst;
    (* Tells if main window title should show the project directory.
       @seealso(WindowTitleProjectFirst) @seealso(TitleTemplate) *)
      property WindowTitleProjectShowDir: Boolean
        read GetWindowTitleProjectShowDir write SetWindowTitleProjectShowDir;
    (* Main window title template.
       @seealso(WindowTitleProjectFirst) @seealso(WindowTitleProjectShowDir) *)
      property TitleTemplate: String read fTitle;
    (* Tells if show the menu. *)
      property ShowMenu: Boolean read GetShowMenu write SetShowMenu;
    (* Tells if show the tool bar. *)
      property ShowToolBar: Boolean read GetShowToolBar write SetShowToolBar;
    (* Tells if show the status bar. *)
      property ShowStatusBar: Boolean
        read GetShowStatusBar write SetShowStatusBar;
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
      fSynManager: TSynManager;
      fFileList: TStrings;
      fAutocompletionWordList: TAutocompletionWordList;

    (* Sets up the language translation. *)
      procedure SetUpLanguage;
    (* Returns application directory. *)
      function GetApplicationDir (const aDir: TFileName): TFileName; inline;
    (* Returns executable directory. *)
      function GetExecutableDir (const aDir: TFileName): TFileName; inline;
    (* Returns user directory. *)
      function GetUserDir (const aDir: TFileName): TFileName; inline;
    public
    (* Constructor. *)
      constructor Create;
    (* Destructor. *)
      destructor Destroy; override;
    (* Initializes the object. *)
      procedure Initialize;
    (* Looks for the file in the application and user directories.

       It looks first in the user directory, then in the directory where the
       exectuable is and finally in the application directory.
       @param(aFile The file to look for.  Should include directory.)
       @return(If file is found, the full path.  If not found, @code(aFile)
               content as it is.)
       @seealso(FindDirectory)
     *)
      function FindFile (const aFile: String): String;
    (* Looks for the directory inside in the application and user directories.

       It looks first in the user directory, then in the directory where the
       exectuable is and finally in the application directory.
       @param(aDir The directory to look for.)
       @return(If directory is found, the full path.  If not found, @code(aDir)
               content as it is.)
       @seealso(FindFile)
     *)
      function FindDirectory (const aDir: String): String;
    (* Looks for files that match the name (possibly with wildcards) in both
       application and user directories.  It then fills the name list with all
       found files with full path.
       @param(aFileName The file name (with or without wildcards) to look for.)
       @param(aFileList The list where the found files will be stored.) *)
      procedure FindFileList (const aFileName: TFileName; aFileList: TStrings);

    (* Application configuration. *)
      property Configuration: TConfiguration read fConfiguration;
    (* List of files passed via command line options. *)
      property FileList: TStrings read fFileList;
    (* The currently loaded project. *)
      property Project: TProject read fProject;
    (* Reference to the syntax highlighters manager. *)
      property SynManager: TSynManager read fSynManager;
    (* Reference to the autocompletion word list. *)
      property AutocompletionWordList: TAutocompletionWordList
        read fAutocompletionWordList;
    end;

  var
  (* Global reference to the MLSDE application object. *)
    MLSDEApplication: TMLSDEApplication;

implementation

  uses
    GUIUtils, EditorFrame,
    LCLTranslator, { No need to put this in any other place. }
    Forms;

  const
  (* Directory where .po/.mo files are. *)
    LangDir = 'languages';
  (* To build the window title.  See TEnvironmentConfiguration. *)
    WindowTitleProjectFmt = 'MLSDE - %s';
    WindowTitleProjectDirFmt = 'MLSDE - %s (%s)';
    WindowTitleProjectFirstFmt = '%s - MLSDE';
    WindowTitleProjectDirFirstFmt = '%s (%s) - MLSDE';

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
    if aValue <> Self.GetLanguage then
      Self.SetValue (EnvironmentSection, 'language', aValue)
  end;

  function TEnvironmentConfiguration.GetWindowTitleProjectFirst: Boolean;
  begin
    Result := Self.GetBoolValue (EnvironmentSection, 'title_project_first', False)
  end;

  procedure TEnvironmentConfiguration.SetWindowTitleProjectFirst
    (const aValue: Boolean);
  begin
    if aValue <> Self.GetWindowTitleProjectFirst then
    begin
      Self.SetBooleanValue (EnvironmentSection, 'title_project_first', aValue);
      Self.BuildTitleTemplate
    end;
  end;

  function TEnvironmentConfiguration.GetWindowTitleProjectShowDir: Boolean;
  begin
    Result := Self.GetBoolValue (EnvironmentSection, 'title_project_dir', True)
  end;

  procedure TEnvironmentConfiguration.SetWindowTitleProjectShowDir
    (const aValue: Boolean);
  begin
    if aValue <> Self.GetWindowTitleProjectShowDir then
    begin
      Self.SetBooleanValue (EnvironmentSection, 'title_project_dir', aValue);
      Self.BuildTitleTemplate
    end
  end;

  function TEnvironmentConfiguration.GetShowMenu: Boolean;
  begin
    Result := Self.GetBoolValue (EnvironmentSection, 'show_menu', True)
  end;

  procedure TEnvironmentConfiguration.SetShowMenu(const aValue: Boolean);
  begin
    if aValue <> Self.GetShowMenu then
      Self.SetBooleanValue (EnvironmentSection, 'show_menu', aValue)
  end;

  function TEnvironmentConfiguration.GetShowToolBar: Boolean;
  begin
    Result := Self.GetBoolValue (EnvironmentSection, 'show_toolbar', True)
  end;

  procedure TEnvironmentConfiguration.SetShowToolBar (const aValue: Boolean);
  begin
    if aValue <> Self.GetShowToolBar then
      Self.SetBooleanValue (EnvironmentSection, 'show_toolbar', aValue)
  end;

  function TEnvironmentConfiguration.GetShowStatusBar: Boolean;
  begin
    Result := Self.GetBoolValue (EnvironmentSection, 'show_statuslbar', True)
  end;

  procedure TEnvironmentConfiguration.SetShowStatusBar(const aValue: Boolean);
  begin
   if aValue <> Self.GetShowStatusBar then
      Self.SetBooleanValue (EnvironmentSection, 'show_statuslbar', aValue)
  end;



  procedure TEnvironmentConfiguration.BuildTitleTemplate;
  begin
    if Self.GetWindowTitleProjectFirst then
    begin
      if Self.GetWindowTitleProjectShowDir then
        fTitle := WindowTitleProjectDirFirstFmt
      else
        fTitle := WindowTitleProjectFirstFmt
    end
    else begin
      if Self.GetWindowTitleProjectShowDir then
        fTitle := WindowTitleProjectDirFmt
      else
        fTitle := WindowTitleProjectFmt
    end
  end;



(* Prints command line help. *)
  procedure TEnvironmentConfiguration.GetCommandLineHelp (aStringList: TStrings);
  begin
    aStringList.Append (
      Concat ('  --lang=[en|es]:  ', messageSelectAppLanguage)
    )
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
  { Sets the title template. }
    Self.BuildTitleTemplate
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
      Self.FindDirectory (LangDir)
    )
  end;



(* Returns application directory. *)
  function TMLSDEApplication.GetApplicationDir (const aDir: TFileName)
    : TFileName;
  begin
    Result :=
{$IFDEF WINDOWS}
      '' { Windows doesn't has this directory. }
{$ELSE}
      Concat ('/usr/share/mlsde/', aDir)
{$ENDIF}
  end;



(* Returns executable directory. *)
  function TMLSDEApplication.GetExecutableDir (const aDir: TFileName)
    : TFileName;
  begin
    Result := Concat (
      IncludeTrailingPathDelimiter (ExtractFileDir (ParamStr (0))),
      aDir
    )
  end;



(* Returns user directory. *)
  function TMLSDEApplication.GetUserDir (const aDir: TFileName): TFileName;
  begin
    Result := Concat (
      IncludeTrailingPathDelimiter (GetAppConfigDir (False)),
      aDir
    )
  end;



(* Constructor. *)
  constructor TMLSDEApplication.Create;
  begin
    inherited Create;
    fConfiguration := TConfiguration.Create;
    fProject := TProject.Create;
    fSynManager := TSynManager.Create;
    fAutocompletionWordList := TAutocompletionWordList.Create;
    fFileList := TStringList.Create
  end;



(* Destructor. *)
  destructor TMLSDEApplication.Destroy;
  begin
    fProject.Free;
    fAutocompletionWordList.Free;
    fSynManager.Free;
    fFileList.Free;
    fConfiguration.Free;
    inherited Destroy
  end;



(* Initializes the object. *)
  procedure TMLSDEApplication.Initialize;
  var
    lNdx: Integer;
  begin
  { Add configuration objects. }
    fConfiguration.AddSection (TAutocompletionConfiguration.Create, idAutocompletionConfig);
    fConfiguration.AddSection (TEnvironmentConfiguration.Create, EnvironmentSection);
    fConfiguration.AddSection (TProjectConfiguration.Create, idProjectConfig);
    fConfiguration.AddSection (TEditorConfiguration.Create, idEditorConfig);
  { Load configuration file and parse command line options. }
    lNdx := 0; fFileList.Clear;
    while lNdx < ParamCount do
    begin
      Inc (lNdx);
      if ParamStr (lNdx)[1] <> '-' then fFileList.Append (ParamStr (lNdx))
    end;
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
      fConfiguration.Apply;
    { Loads and initializes the syntax highlighters. }
      fSynManager.Initialize;
    { Initializes the autocompletion subsystem. }
      fAutocompletionWordList.Initialize
    end
  end;



(* Looks for file. *)
  function TMLSDEApplication.FindFile (const aFile: String): String;
  begin
    Result := Self.GetUserDir (aFile);
    if not FileExists (Result) then
    begin
      Result := Self.GetExecutableDir (aFile);
      if not FileExists (Result) then
      begin
        Result := Self.GetApplicationDir (aFile);
        if not FileExists (Result) then
        begin
        { Not found, so... }
          Result := aFile
        end
      end
    end
  end;



  function TMLSDEApplication.FindDirectory (const aDir: String): String;
  begin
    Result := Self.GetUserDir (aDir);
    if not DirectoryExists (Result) then
    begin
      Result := Self.GetExecutableDir (aDir);
      if not DirectoryExists (Result) then
      begin
        Result := Self.GetApplicationDir (aDir);
        if not DirectoryExists (Result) then
        begin
        { Not found, so... }
          Result := aDir;
        end
      end
    end;
    Result := IncludeTrailingPathDelimiter (Result)
  end;



(* Looks for files. *)
  procedure TMLSDEApplication.FindFileList (
    const aFileName: TFileName;
    aFileList: TStrings
  );

    procedure FillList (const aPath: TFileName);
    var
      lDir: TFileName;
      lFileInfo: TSearchRec;
    begin
      if FindFirst (aPath, 0, lFileInfo) = 0 then
      begin
        lDir := IncludeTrailingBackslash (ExtractFileDir (aPath));
        repeat
          aFileList.Append (Concat (lDir, lFileInfo.Name))
        until FindNext (lFileInfo) <> 0;
        FindClose (lFileInfo)
      end
    end;

  begin
  { Search in user directory. }
    FillList (Self.GetUserDir (aFileName));
  { Search in executable directory. }
    FillList (Self.GetExecutableDir (aFileName));
  { Search in application directory. }
    FillList (Self.GetApplicationDir (aFileName))
  end;

end.

