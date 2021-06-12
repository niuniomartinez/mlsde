unit MainForm;
(*<Defines the main window of the application.
 *)
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
    EditorFrame, ProjectViewFrame,
    ActnList, Classes, ComCtrls, Controls, ExtCtrls, Forms, Menus, StdActns;

  const
  (* Index of the information status panel. *)
    InformationStatusPanel = 0;
  (* Index of the cursor information status panel. *)
    CursorPosStatusPanel = 1;
  (* Index of the language information status panel. *)
    LanguageStatusPanel = 2;

  type
  (* Main window of the application.

     Note that some stuff is defined in the @link(Initialize) method.  That's
     why some buttons and menu options look empty. *)
    TMainWindow = class (TForm)
    (* Action list.  Only contains application actions.  Other actions are in
       the respective @code(TFrame). *)
      ActionList: TActionList;
       ActionConfigure: TAction;
       ActionAbout: TAction;
       ActionQuit: TFileExit;
       ActionCloseAllTabs: TAction;
       ActionCloseCurrentTab: TAction;
       ActionSaveFile: TAction;
       ActionSaveAll: TAction;
      MainMenu: TMainMenu;
       MenuItemMLSDE: TMenuItem;
        MenuItemAbout: TMenuItem;
        MenuItemConfiguration: TMenuItem;
        MenuItemQuit: TMenuItem;
       MenuItemOpenPrj: TMenuItem;
        MenuItemProject: TMenuItem;
        MenuItemCloseAllTabs: TMenuItem;
       MenuItemFile: TMenuItem;
        mnuItemSeparator1: TMenuItem;
        MenuItemSaveFile: TMenuItem;
        MenuItemSaveAll: TMenuItem;
        mnuItemCloseTab: TMenuItem;
      ToolBar: TToolBar;
       tbtnSeparator1: TToolButton;
       tbtnOpenPrj: TToolButton;
       tbtnSeparator2: TToolButton;
       tbtnSaveFile: TToolButton;
       tbtnSaveAll: TToolButton;
       tbtnCloseCurrentTab: TToolButton;
      ProjectViewer: TProjectView;
      ResizeBar: TSplitter;
      EditorList: TPageControl;
      StatusBar: TStatusBar;

    (* Event triggered when an environment action is executed. *)
      procedure ActionEnvironmentExecute (Sender: TObject);
    (* Event trigered when a file action is executed. *)
      procedure ActionSourceFileExecute (Sender: TObject);
    (* Creates the window. *)
      procedure FormCreate (Sender: TObject);
    (* Activates teh window. *)
      procedure FormActivate(Sender: TObject);
    (* Event triggered when form is shown. *)
      procedure FormShow (Sender: TObject);
    (* User clicks on tree. *)
      procedure ProjectTreeDblClick (Sender: TObject);
    (* There are changes in the editor.

       This event is triggered when a file changed, and also when user selects
       a file. *)
      procedure EditorChanged (Sender: TObject);
    (* Click in the status bar. *)
      procedure StatusBarMouseDown (
        aSender: TObject;
        aButton: TMouseButton;
        aShift: TShiftState;
        aX, aY: Integer
      );
    (* Status bar size changed. *)
      procedure StatusBarResize (Sender: TObject);
    private
    (* Some initialization may result in internal error if done in onCreate
       event, so they're done in onActivate instead using this flag to know if
       it is an initialization. *)
      fInitializing: Boolean;

    (* Configuration changed. *)
      procedure EnvironmentConfigurationChanged (Sender: TObject);
      procedure EditorConfigurationChanged (Sender: TObject);
    (* Updates the state of the components related with files. *)
      procedure UpdateFileComponentStates;
    (* Updates window title. *)
      procedure UpdateWindowTitle;
    (* Returns the "editor" object of the given tab.

       If it doesn't find it then raises an exception. *)
      function FindEditorInTab (const aTab: TTabSheet): TSourceEditorFrame;
    (* Opens the given file.

       If file was open it just sets the tab in first plane. *)
      procedure OpenFile (const aFileName: String);
    (* Project has changed. *)
      procedure ProjectChanged (Sender: TObject);
    (* Closes all tabs. *)
      procedure CloseAllTabs;
    (* Closes current tab. *)
      procedure CloseCurrentTab;
    end;

  var
  (* Global reference to the main window. *)
    MainWindow: TMainWindow;

implementation

  uses
    AboutDlg, ConfigurationDialogForm, GUIUtils, LanguageSelectorDialogform,
    Main, MLSDEHighlighter, Project, Utils,
    Dialogs, sysutils;

{$R *.lfm}

  const
  (* Tag values for different actions. *)
    tagConfigure = 1;
    tagAboutDlg = 2;
    tagCloseAllTabs = 3;
    tabCloseCurrentTab = 4;

    tagSaveFile = 1;
    tagSaveAllFiles = 2;
  (* Sizes of the status panels. *)
    CursorPanelWidth = 50;
    LanguagePanelWidth = 100;



(*
 * TMainWindow
 ***************************************************************************)

(* Executes an environment action. *)
  procedure TMainWindow.ActionEnvironmentExecute (Sender: TObject);
  begin
    case (Sender as TComponent).Tag of
    tagConfigure:
      GUIUtils.RunModalDialog (TConfigurationDlg.Create (Self));
    tagAboutDlg:
      GUIUtils.RunModalDialog (TAboutDialog.Create (Self));
    tagCloseAllTabs:
      Self.CloseAllTabs;
    tabCloseCurrentTab:
      Self.CloseCurrentTab;
    otherwise
    { This should never be rendered, so no translation required. }
      ShowError ('Action environment tag: %d', [(Sender as TComponent).Tag]);
    end
  end;



(* Executes file actions. *)
  procedure TMainWindow.ActionSourceFileExecute (Sender: TObject);
  var
    lEditor: TSourceEditorFrame;
    Ndx: Integer;
  begin
    case (Sender as TComponent).Tag of
    tagSaveFile:
      if Self.EditorList.ActivePage <> Nil then
      begin
        lEditor := Self.FindEditorInTab (Self.EditorList.ActivePage);
        lEditor.Save
      end;
    tagSaveAllFiles:
      if Self.EditorList.PageCount > 0 then
        for Ndx := 0 to Self.EditorList.PageCount - 1 do
        begin
          lEditor := Self.FindEditorInTab (Self.EditorList.Pages[Ndx]);
          if lEditor.Modified then lEditor.Save
        end;
    otherwise
    { This should never be rendered, so no translation required. }
      ShowError ('Action source file tag: %d', [(Sender as TComponent).Tag]);
    end
  end;



(* Initializes. *)
  procedure TMainWindow.FormCreate (Sender: TObject);
  begin
    fInitializing := True;
  { Create project view. }
    Self.ProjectViewer.Project := MLSDEApplication.Project;
  { Project management. }
    MLSDEApplication.Project.OnChange := @Self.ProjectChanged;
  { Some action events. }
    Self.ProjectViewer.ProjectTree.OnDblClick := @Self.ProjectTreeDblClick;
    Self.MenuItemOpenPrj.Action := Self.ProjectViewer.ActionOpenProject;
    Self.tbtnOpenPrj.Action := Self.ProjectViewer.ActionOpenProject;
    MLSDEApplication.Configuration.FindConfig (
      idEnvironmentConfig
    ).Subject.AddObserver (@Self.EnvironmentConfigurationChanged);
    MLSDEApplication.Configuration.FindConfig (
      idEditorConfig
    ).Subject.AddObserver (@Self.EditorConfigurationChanged);
  end;



(* Activates window. *)
  procedure TMainWindow.FormActivate(Sender: TObject);
  begin
    if fInitializing then
    begin
    { Components state. }
      Self.UpdateFileComponentStates;
      Self.EnvironmentConfigurationChanged (Nil);
      fInitializing := false
    end
  end;



(* Shows window. *)
  procedure TMainWindow.FormShow (Sender: TObject);
  begin
    Self.ProjectViewer.UpdateView;
    Self.UpdateWindowTitle;
    Self.UpdateFileComponentStates
  end;



(* Double click on project tree. *)
  procedure TMainWindow.ProjectTreeDblClick (Sender: TObject);
  var
    lProjectTree: TTreeView absolute Sender;
    lFileInfo: TFile;
  begin
    if (lProjectTree.Selected <> Nil)
    and (lProjectTree.Selected.Data <> Nil) then
    begin
      if TObject (lProjectTree.Selected.Data) is TFile then
      begin
        lFileInfo := TFile (lProjectTree.Selected.Data);
        Self.OpenFile (Concat (lFileInfo.GetPath, lFileInfo.Name));
        Self.UpdateFileComponentStates
      end
    end
  end;



(* There are changes in the editor. *)
  procedure TMainWindow.EditorChanged (Sender: TObject);
  begin
    Self.UpdateFileComponentStates;
    Self.FindEditorInTab (Self.EditorList.ActivePage).SetFocus
  end;



(* Click in the status bar. *)
  procedure TMainWindow.StatusBarMouseDown (
    aSender: TObject;
    aButton: TMouseButton;
    aShift: TShiftState;
    aX, aY: Integer);
  var
    lDlgLanguage: TLanguageSelectorDlg;
    lEditor: TSourceEditorFrame;
  begin
  { Only if there are a file open. }
    if Assigned (Self.EditorList.ActivePage) then
    begin
      if (aButton = mbLeft) and (aShift = [ssLeft])
      and (aX > Self.StatusBar.Width - LanguagePanelWidth) then
      try
        lDlgLanguage := TLanguageSelectorDlg.Create (Self);
        lEditor := Self.FindEditorInTab (Self.EditorList.ActivePage);
        if Assigned (lEditor.SynEdit.Highlighter) then
          lDlgLanguage.Select (
            TMLSDEHighlighter (lEditor.SynEdit.Highlighter).Language
          )
        else
          lDlgLanguage.Select ('');
        if lDlgLanguage.ShowModal = mrOK then
          lEditor.SetLanguage (lDlgLanguage.Language)
      finally
        lDlgLanguage.Free
      end
    end
  end;



(* Status bar changed size. *)
  procedure TMainWindow.StatusBarResize (Sender: TObject);
  var
    lStatusBar: TStatusBar absolute Sender;
  begin
    if lStatusBar.Visible then
    begin
      lStatusBar.Panels[InformationStatusPanel].Width :=
        lStatusBar.Width - (CursorPanelWidth + LanguagePanelWidth);
      lStatusBar.Panels[CursorPosStatusPanel].Width := CursorPanelWidth
    end
  end;



(* Configuration changed. *)
  procedure TMainWindow.EnvironmentConfigurationChanged (Sender: TObject);
  var
    lConfiguration: TEnvironmentConfiguration;
  begin
    Self.UpdateWindowTitle;
    lConfiguration := TEnvironmentConfiguration (
      MLSDEApplication.Configuration.FindConfig (idEnvironmentConfig)
    );
    if lConfiguration.ShowMenu then
    begin
      if not Assigned (Self.MainMenu.Parent) then
      begin
        Self.MainMenu.Parent := Self;
        Self.MainMenu.HandleNeeded
      end
    end
    else
      Self.MainMenu.Parent := Nil;
    Self.ToolBar.Visible := lConfiguration.ShowToolbar;
    Self.StatusBar.Visible := lConfiguration.ShowStatusBar
  end;

  procedure TMainWindow.EditorConfigurationChanged (Sender: TObject);
  var
    Ndx: Integer;
    lEditor: TSourceEditorFrame;
  begin
    for Ndx := 0 to Self.EditorList.PageCount - 1 do
    begin
      lEditor := Self.FindEditorInTab (Self.EditorList.Pages[Ndx]);
      lEditor.ApplyEditorConfiguration
    end;
  end;



(* Updates components. *)
  procedure TMainWindow.UpdateFileComponentStates;

    procedure OpenedFiles;
    var
      Ndx: Integer;
      lEditor: TSourceEditorFrame;
    begin
    { Is any of them modified? }
      for Ndx := 0 to Self.EditorList.PageCount - 1 do
      begin
        lEditor := Self.FindEditorInTab (Self.EditorList.Pages[Ndx]);
        if lEditor.Modified then
        begin
          Self.ActionSaveAll.Enabled := True;
        { Is the selected tab modified? }
          lEditor := Self.FindEditorInTab (Self.EditorList.ActivePage);
          Self.ActionSaveFile.Enabled := lEditor.Modified;
        { No need to check more. }
          Exit
        end
      end
    end;

  begin
    Self.ActionCloseAllTabs.Enabled := Self.EditorList.PageCount > 0;
    Self.ActionCloseCurrentTab.Enabled := Self.EditorList.PageCount > 0;
  { Initially, all save options are disabled. }
    Self.ActionSaveFile.Enabled := False;
    Self.ActionSaveAll.Enabled := False;
  { Are there opened files? }
    if Self.EditorList.PageCount > 0 then
    begin
      OpenedFiles;
      Self.FindEditorInTab (Self.EditorList.ActivePage).UpdateStatusBarInfo
    end
    else begin
      Self.StatusBar.Panels[InformationStatusPanel].Text := '';
      Self.StatusBar.Panels[CursorPosStatusPanel].Text := '';
      Self.StatusBar.Panels[LanguageStatusPanel].Text := ''
    end
  end;



(* Updates window title. *)
  procedure TMainWindow.UpdateWindowTitle;
  begin
    if Assigned (MLSDEApplication.Project.Root) then
      Self.Caption := Format (
        TEnvironmentConfiguration (
          MLSDEApplication.Configuration.FindConfig (idEnvironmentConfig)
        ).TitleTemplate,
        [
          MLSDEApplication.Project.Root.Name,
          ExcludeTrailingPathDelimiter (MLSDEApplication.Project.Root.GetPath)
        ]
      )
    else
      Self.Caption := Format (
        TEnvironmentConfiguration (
          MLSDEApplication.Configuration.FindConfig (idEnvironmentConfig)
        ).TitleTemplate,
        ['', '<n/a>']
      )
  end;



(* Returns editor object. *)
  function TMainWindow.FindEditorInTab (const aTab: TTabSheet)
    : TSourceEditorFrame;
  var
    Ndx: Integer;
  begin
    for Ndx := aTab.ComponentCount - 1 downto 0 do
      if aTab.Components[Ndx] is TSourceEditorFrame then
        Exit (TSourceEditorFrame (aTab.Components[Ndx]));
    raise Exception.Create ('Can''t find editor component in tabs!')
  end;



(* Opens source file. *)
  procedure TMainWindow.OpenFile (const aFileName: String);
  var
    lEditor: TSourceEditorFrame;
    lTab: TTabSheet = Nil;
    lTabname: String;
    Ndx: Integer;
  begin
  { Search file in tabs. }
    lTabname := NormalizeIdentifier (aFileName);
    if Self.EditorList.PageCount > 0 then
      for Ndx := 0 to Self.EditorList.PageCount - 1 do
        if Self.EditorList.Pages[Ndx].Name = lTabname then
        begin
          lTab := Self.EditorList.Pages[Ndx];
          lEditor := Self.FindEditorInTab (lTab)
        end;
  { If not found, then load. }
    if lTab = nil then
    begin
      lTab := Self.EditorList.AddTabSheet;
      Self.EditorList.ActivePage := lTab;
      lEditor := TSourceEditorFrame.Create (lTab);
      lEditor.Align := alClient;
      lEditor.Parent := lTab;
      lEditor.Load (aFileName);
      lEditor.OnChange := @Self.EditorChanged
    end;
    Self.EditorList.ActivePage := lTab;
    lEditor.SynEdit.SetFocus
  end;



(* Project has changed. *)
  procedure TMainWindow.ProjectChanged (Sender: TObject);
  begin
    Self.CloseAllTabs; { TODO: Only when loading new project? }
    MLSDEApplication.SynManager.Initialize; { TODO: Only when loading new project? }
    Self.ProjectViewer.UpdateView;
    Self.UpdateWindowTitle;
    Self.UpdateFileComponentStates
  end;



{ Closes all tabs. }
  procedure TMainWindow.CloseAllTabs;
  var
    Ndx: Integer;
  begin;
    for Ndx := Self.EditorList.PageCount - 1 downto 0 do
      Self.EditorList.Pages[Ndx].Free;
    Self.UpdateFileComponentStates
  end;



(* Closes current tab. *)
  procedure TMainWindow.CloseCurrentTab;
  begin
  { Be sure there's a tab open. }
    if Assigned (Self.EditorList.ActivePage) then
    begin
      Self.EditorList.ActivePage.Free;
      Self.UpdateFileComponentStates
    end
  end;

end.
