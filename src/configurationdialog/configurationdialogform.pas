unit ConfigurationDialogForm;
(*<Implements the configuration dialog. *)
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
    ConfigurationDialogFrame,
    Forms, ComCtrls, ButtonPanel, ExtCtrls, Classes;

  type
  (* The configuration dialog.

     See that @italic(tabs) are empty.  The content is created and assigned at
     @link(Initialize). *)
    TConfigurationDlg = class (TForm)
      ButtonPanel: TButtonPanel;
      NoteBook: TNotebook;
      ResizeBar: TSplitter;
      TabList: TTreeView;

    (* Accepts configuration values. *)
      procedure Accept (Sender: TObject);
    (* Initializes the dialog.  Called everytime the dialog is used. *)
      procedure Initialize (Sender: TObject);
    (* User clicked in the tab list. *)
      procedure TabListClick (aSender: TObject);
    private
    { Implementation Note:

      This is one reason I don't add the frames at design time.

      Other (and the main one) is that adding them mess-up .lfm and .po
      files.  Some definitions are duplicated and changes in the frames aren't
      shown/actualized in the form.

      A third one is because this way it is more easy to add custom
      configuration frames for extension configuration.
    }
      fConfigurationFrameList: array of TConfigurationFrame;

    (* Adds a new page to the configuration and returns the associated tree
       node. *)
      function AddTab (
        aTab: TConfigurationFrame;
        aName: String;
        aParentNode: TTreeNode=Nil
      ): TTreeNode;
    (* Adds a new page to the configuration. *)
      procedure AppendTab (
        aTab: TConfigurationFrame;
        aName: String;
        aParentNode: TTreeNode=Nil
      );
    end;


implementation

  uses
    ColorSchemaFrame,
    ConfigurationFrameEditor, ConfigurationFrameEnvironment,
    ConfigurationFrameProject,
    GUIUtils, Main, Controls,
    sysutils;

{$R *.lfm}

  resourcestring
    captionConfiguration = 'Configuration';
    messageNeedsReinitialize = 'Some configuration changes won''t be applied'#10+
                         'until you reinitialize the application.';
    messageCantSaveConfigFile = 'Couldn''t save changes to configuration file.';

    captionEnvironment = 'Environment';
    captionProject = 'Project';
    captionEditor = 'Editor';
    captionColorSchema = 'Color shcema';



(*
 * TConfigurationDlg
 **************************************************************************)

(* Accepts configuration values. *)
  procedure TConfigurationDlg.Accept (Sender: TObject);
  var
    lTab: TConfigurationFrame;
    lNeedsReinitialize: Boolean;
  begin
    lNeedsReinitialize := False;
    try
      for lTab in fConfigurationFrameList do
      begin
	lTab.AcceptConfiguration;
	if lTab.NeedInitialize then lNeedsReinitialize := True
      end
    except
      ShowError (messageCantSaveConfigFile)
    end;
    MLSDEApplication.Configuration.Apply;
    if lNeedsReinitialize then
      ShowInformation (captionConfiguration, messageNeedsReinitialize)
  end;



(* Initializes the dialog. *)
  procedure TConfigurationDlg.Initialize (Sender: TObject);
  var
    lTab: TConfigurationFrame;
    lNode: TTreeNode;
  begin
  { Create the frames and set them in tabs. }
    Self.AppendTab (
      TEnvironmentConfigurationFrame.Create (Self),
      captionEnvironment
    );
    Self.AppendTab (
      TProjectConfigurationFrame.Create (Self),
      captionProject
    );
    lNode := Self.AddTab (
      TEditorConfigurationFrame.Create (Self),
      captionEditor
    );
    Self.AppendTab (
      TColorShcemaEditor.Create (Self),
      captionColorSchema,
      lNode
    );
  { Initialize tabs. }
    for lTab in fConfigurationFrameList do lTab.Initialize;
  { Show first frame. }
    Self.NoteBook.PageIndex := 0
  end;



(* User clicked option list. *)
  procedure TConfigurationDlg.TabListClick (aSender: TObject);
  var
    lOptionList: TTreeView absolute aSender;
  begin
    if Assigned (lOptionList.Selected) then
      Self.NoteBook.PageIndex := TPage (lOptionList.Selected.Data).PageIndex
  end;



(* Adds a new page to the configuration. *)
  function TConfigurationDlg.AddTab (
    aTab: TConfigurationFrame;
    aName: String;
    aParentNode: TTreeNode
  ): TTreeNode;
  var
    lTabIndex: Integer;
    lPage: TPage;
  begin
  { Get space for the new tab. }
    lTabIndex := Length (fConfigurationFrameList);
    SetLength (fConfigurationFrameList, lTabIndex + 1);
  { Adds the tab. }
    Self.NoteBook.Pages.Add (aName);
    lPage := TPage (Self.NoteBook.Pages.Objects[Self.NoteBook.Pages.Count - 1]);

    if lPage = Nil then
      RAISE Exception.Create ('Error al crear página de configuración');

    fConfigurationFrameList[lTabIndex] := aTab;
    fConfigurationFrameList[lTabIndex].Parent := lPage;
    fConfigurationFrameList[lTabIndex].Align := alClient;
    fConfigurationFrameList[lTabIndex].Tag := TabList.Items.Count;

    if Assigned (aParentNode) then
      Result := Self.TabList.Items.AddChild (aParentNode, aName)
    else if Self.TabList.Items.Count = 0 then
      Result := Self.TabList.Items.AddFirst (Nil, aName)
    else
      Result := Self.TabList.Items.Add (
        Self.TabList.Items[TabList.Items.Count - 1], aName
      );
    if Result = Nil then
      RAISE Exception.Create ('Can''t add page to configuration dialog.');
  { Binds tab with tree node. }
    Result.Data := lPage
  end;



(* Adds a new page to the configuration. *)
  procedure TConfigurationDlg.AppendTab (
    aTab: TConfigurationFrame;
    aName: String;
    aParentNode: TTreeNode
  );
  var
    lIgnore: TTreeNode;
  begin
    lIgnore := Self.AddTab (aTab, aName, aParentNode)
  end;

end.
