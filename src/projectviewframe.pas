unit ProjectViewFrame;
(*<Implements the project view used by @link(MainForm).
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
    Project,
    Forms, ComCtrls, Controls;

  const
  (* Index of the directory icon. *)
    ICON_DIRECTORY = 0;
  (* Index of the open directory icon. *)
    ICON_OPEN_DIRECTORY = 1;
  (* Index of the file icon. *)
    ICON_FILE = 2;

  type
  (* A panel that shows the project content.  It also allows some interaction
     as open files or rename items. *)
    TProjectView = class (TFrame)
      FileIconList: TImageList;
      ProjectTree: TTreeView;
    private
      fProject: TProject;
      fCancelOperation: Boolean;

    (* Utility for tree sorting. *)
      function OrderNodes (aNode1, aNode2: TTreeNode): Integer;
    (* Allows to cancel the sorting. *)
      procedure CancelSorting (aSender: TObject);
    public
    (* Updates project view. *)
      procedure UpdateView;

    (* Reference to the project. *)
      property Project: TProject read fProject write fProject;
    end;

implementation

  uses
    ProgressDialogForm,
    sysutils;

{$R *.lfm}

  resourcestring
    SORTING = 'Sorting files...';

(*
 * TProjectView
 ***************************************************************************)

(* Tree sorting. *)
  function TProjectView.OrderNodes (aNode1, aNode2: TTreeNode): Integer;

    function IsFile (const aNode: TTreeNode): Boolean; inline;
    begin
      Result := aNode.Data = Nil
    end;

    function IsDirectory (const aNode: TTreeNode): Boolean; inline;
    begin
      Result := aNode.Data <> Nil
    end;

  begin
    if Random (100) = 50 then Application.ProcessMessages;
  { Directories before files. }
    if IsDirectory (aNode1) and IsFile (aNode2) then Exit (-1);
    if IsFile (aNode1) and IsDirectory (aNode2) then Exit ( 1);
  { Same kind in alphabetical order. }
    Result := AnsiStrIComp (PChar (aNode1.Text), PChar (aNode2.Text))
  end;



(* Allows to cancel the sorting. *)
  procedure TProjectView.CancelSorting (aSender: TObject);
  begin
    fCancelOperation := True
  end;



(* Updates project view. *)
  procedure TProjectView.UpdateView;

  (* Adds directories recursivelly. *)
    procedure AddSubdirectory (aNode: TTreeNode; aDir: TDirectory);
    var
      lNdx: Integer;
      lNode: TTreeNode;
    begin
      if fCancelOperation then Exit;
      if Random (100) = 50 then Application.ProcessMessages;
      aNode.Expanded := False;
      aNode.ImageIndex := ICON_DIRECTORY;
      aNode.SelectedIndex := ICON_OPEN_DIRECTORY;
    { Add directories if available. }
      if aDir.NumDirs > 0 then
        for lNdx := 0 to aDir.NumDirs - 1 do
        begin
          lNode := Self.ProjectTree.Items.AddChild (
            aNode,
            aDir.SubDir[lNdx].Name
          );
          lNode.Data := aDir.SubDir[lNdx];
          AddSubdirectory (lNode, aDir.SubDir[lNdx])
        end;
    { Add files if available. }
      if not fCancelOperation and (aDir.NumFiles > 0) then
        for lNdx := 0 to aDir.NumFiles - 1 do
        begin
          lNode := Self.ProjectTree.Items.AddChild (
            aNode,
            aDir.Files[lNdx].Name
          );
          lNode.Data := aDir.GetFileInfoPointer (lNdx);
          lNode.ImageIndex := ICON_FILE;
          lNode.SelectedIndex := ICON_FILE;
        end
    end;

  var
    lRoot: TTreeNode;
  begin
  { Set up the progress dialog, if available. }
    fCancelOperation := False;
    if ProgressDlg <> Nil then
    begin
      ProgressDlg.LabelText.Caption := SORTING;
      ProgressDlg.ProgressBar.Style := pbstMarquee;
      ProgressDlg.OnCancelAction := @Self.CancelSorting
    end;
    if Self.ProjectTree.Items.Count <> 0 then Self.ProjectTree.Items.Clear;
    if fProject.Root <> Nil then
    begin
    { Add root directory. }
      lRoot := Self.ProjectTree.Items.AddFirst (
        Nil, fProject.Root.Name
      );
      lRoot.Data := fProject.Root;
      AddSubdirectory (lRoot, fProject.Root);
      lRoot.Expanded := True;
    { Actual sorting can't be cancelled. }
      if ProgressDlg <> Nil then ProgressDlg.OnCancelAction := Nil;
      Self.ProjectTree.CustomSort (@Self.OrderNodes)
    end;
  { Reset the progress dialog, if available (it won't if Root is Nil). }
    if ProgressDlg <> Nil then ProgressDlg.OnCancelAction := Nil;
  { If operation was cancelled, remove data. }
    if fCancelOperation then
    begin
      fProject.Clear;
      Self.ProjectTree.Items.Clear
    end
  end;

end.

