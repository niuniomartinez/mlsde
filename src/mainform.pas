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
    Forms, Menus, ActnList, StdActns, ComCtrls, ExtCtrls;

  type
  (* Main window of the application.

     Note that some stuff is defined in the @link(Initialize) method. *)
    TMainWindow = class (TForm)
    (* Action list.  Only contains application actions.  Other actions are in
       the respective @code(TFrame). *)
      ActionList: TActionList;
       ActionConfigure: TAction;
       ActionAbout: TAction;
       ActionQuit: TFileExit;
       ActionSaveFile: TAction;
       ActionSaveAll: TAction;
      MainMenu: TMainMenu;
       MenuItemMLSDE: TMenuItem;
        MenuItemAbout: TMenuItem;
        MenuItemConfiguration: TMenuItem;
        MenuItemQuit: TMenuItem;
       MenuItemOpenPrj: TMenuItem;
        MenuItemProject: TMenuItem;
      ToolBar: TToolBar;
       tbtnQuit: TToolButton;
       tbtnOpenPrj: TToolButton;
       tbtnSeparator1: TToolButton;
       tbtnSaveFile: TToolButton;
       tbtnSaveAll: TToolButton;
      ProjectViewer: TProjectView;
      ResizeBar: TSplitter;
      EditorList: TPageControl;

    (* Event triggered when an environment action is executed. *)
      procedure ActionEnvironmentExecute (Sender: TObject);
    (* Event trigered when a file action is executed. *)
      procedure ActionSourceFileExecute (Sender: TObject);
    (* Event triggered when form is shown. *)
      procedure FormShow (Sender: TObject);
    (* Initializes the window. *)
      procedure Initialize (Sender: TObject);
    (* User clicks on tree. *)
      procedure ProjectTreeDblClick (Sender: TObject);
    (* There are changes in the editor.

       This event is triggered when a file changed, and also when user selects
       a file. *)
      procedure EditorChanged (Sender: TObject);
    private
    (* Updates the state of the components related with files. *)
      procedure UpdateFileComponentStates;
    (* Returns the "editor" object of the given tab.

       If it doesn't find it then raises an exception. *)
      function FindEditorInTab (const aTab: TTabSheet): TSourceEditorFrame;
    (* Opens the given file.

       If file was open it just sets the tab in first plane. *)
      procedure OpenFile (const aFileName: String);
    (* Project has changed. *)
      procedure ProjectChanged (Sender: TObject);
    end;

  var
  (* Global reference to the main window. *)
    MainWindow: TMainWindow;

implementation

  uses
    AboutDlg, ConfigurationDialogForm, GUIUtils, Main,
    Project, Utils,
    Classes, Controls, Dialogs, sysutils;

{$R *.lfm}

  const
  (* To build the window title. *)
    WindowTitle = '%s (%s) - MLSDE';
  (* Tag values for different actions. *)
    tagConfigure = 1;
    tagAboutDlg = 2;

    tagSaveFile = 1;
    tagSaveAllFiles = 2;



(*
 * TMainWindow
 ***************************************************************************)

(* Executes an environment action. *)
  procedure TMainWindow.ActionEnvironmentExecute (Sender: TObject);
  begin
    case (Sender AS TComponent).Tag of
    tagConfigure:
      GUIUtils.RunModalDialog (TConfigurationDlg.Create (Self));
    tagAboutDlg:
      GUIUtils.RunModalDialog (TAboutDialog.Create (Self));
    else
    { This should never be rendered, so no translation required. }
      ShowError ('Action environment tag: %d', [(Sender AS TComponent).Tag]);
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
    else
    { This should never be rendered, so no translation required. }
      ShowError ('Action source file tag: %d', [(Sender AS TComponent).Tag]);
    end
  end;



(* Shows window. *)
  procedure TMainWindow.FormShow (Sender: TObject);
  begin
    Self.ProjectViewer.UpdateView;
    Self.UpdateFileComponentStates
  end;



(* Initializes. *)
  procedure TMainWindow.Initialize (Sender: TObject);
  begin
  { Create project view. }
    Self.ProjectViewer.Project := MLSDEApplication.Project;
  { Project management. }
    MLSDEApplication.Project.OnChange := @Self.ProjectChanged;
  { Some action events. }
    Self.ProjectViewer.ProjectTree.OnDblClick := @Self.ProjectTreeDblClick;
    Self.MenuItemOpenPrj.Action := Self.ProjectViewer.ActionOpenProject;
    Self.tbtnOpenPrj.Action := Self.ProjectViewer.ActionOpenProject;

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
        Self.OpenFile (lFileInfo.GetPath + lFileInfo.Name);
        Self.UpdateFileComponentStates
      end
    end
  end;



(* There are changes in the editor. *)
  procedure TMainWindow.EditorChanged (Sender: TObject);
  begin
    Self.UpdateFileComponentStates
  end;



(* Updates components. *)
  procedure TMainWindow.UpdateFileComponentStates;
  var
    Ndx: Integer;
    lEditor: TSourceEditorFrame;
  begin
  { Initially, all save options are disabled. }
    Self.ActionSaveFile.Enabled := False;
    Self.ActionSaveAll.Enabled := False;
  { Are there opened files? }
    if Self.EditorList.PageCount > 0 then
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
    end
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
  var
    lProjectName, lProjectPath: String;
  begin
    Self.ProjectViewer.UpdateView;
    if MLSDEApplication.Project.Root <> Nil then
    begin
      lProjectName := MLSDEApplication.Project.Root.Name;
      lProjectPath := ExcludeTrailingPathDelimiter (
        MLSDEApplication.Project.Root.GetPath
      )
    end
    else begin
      lProjectName := '<>';
      lProjectPath := '.'
    end;
    Self.Caption := Format (WindowTitle, [lProjectName, lProjectPath]);
    Self.UpdateFileComponentStates
  end;

end.
