unit Project;
(*<Defines the project manager. *)
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
{$MODESWITCH ADVANCEDRECORDS+}
interface

  uses
    Configuration,
    Classes, fgl, sysutils;

  const
  (* To identify project configuration object. *)
    idProjectConfig = 'project';

  type
  (* Implementation note:
       See both TDirectory and TFile are CLASSes.  I thinkg to use RECORDs
       would be more efficient (i.e. an array of contiguous objects would be
       better for both cache access and memory fragmentation) but I didn't do
       that due to the tree node identification problem (see
       TMainWindow.ProjectTreeDblClick).  Also use TFPGObjectList helps with
       management.  And CLASSes don't need the pointer access operator (^).

       Anyway, if I find that use ARRAY OF RECORD is better then this system
       should change.

       I've found a way that whould make the identification work with RECORDs:

       TItem = RECORD Id: integer END;
       TFile = RECORD Id: integer; Name: String; fOwner: ... END;
       TDir  = RECORD Id: integer; Name: String; Files: ... END;

       That way if you have a pointer (i.e. Node.Data) you can do:

       CASE TItemPtr (Node.Data)^.Id OF
       ID_FILE:
         File := TFilePtr (Node.Data);
       ID_DIR:
         Dir := TDirPtr (Node.Data);
       END;

   *)
  (* @exclude forward declaration. *)
    TProject = class;
  (* @exclude forward declaration. *)
    TDirectory = class;



  (* Manages project configuration. *)
    TProjectConfiguration = class (TCustomConfiguration)
    private
      function GetDirectoryDepth: Integer;
      procedure SetDirectoryDepth (aValue: Integer);
      function GetShowHiddenFiles: Boolean;
      procedure SetShowHiddenFiles (aValue: Boolean);
      function GetShowHiddenDirectories: Boolean;
      procedure SetShowHiddenDirectories (aValue: Boolean);
    public
    (* Tells depth when scanning directories. *)
      property DirDepth: Integer read GetDirectoryDepth write SetDirectoryDepth;
    (* Tells if should show the hidden files in the project list. *)
      property ShowHiddenFiles: Boolean
         read GetShowHiddenFiles write SetShowHiddenFiles;
    (* Tells if should show the hidden directories in the project list. *)
      property ShowHiddenDirs: Boolean
        read GetShowHiddenDirectories write SetShowHiddenDirectories;
    end;



  (* File information. *)
    TFile = class (TObject)
    private
      fOwner: TDirectory;
      fName: String;
    public
    (* Constructor.
       @param(aName File name.)
       @param(aOwner Directory owner.  Must @bold(not) be @nil.)*)
      constructor Create (const aName: String; aOwner: TDirectory);
    (* Builds and returns the full file path. *)
      function GetPath: String;

    (* Directory. *)
      property Directory: TDirectory read fOwner;
    (* File name. *)
      property Name: String read fName;
    end;



  (* Directory information. *)
    TDirectory = class (TObject)
    private type
    (* Directory container. *)
      TDirectoryList = specialize TFPGObjectList<TDirectory>;
    (* File container. *)
      TFileList = specialize TFPGObjectList<TFile>;
    private
      fProject: TProject;
      fOwner: TDirectory;
      fName: String;
      fDirList: TDirectoryList;
      fFileList: TFileList;

      function GetNumDirs: Integer; inline;
      function GetSubDir (const aNdx: Integer): TDirectory; inline;
      function GetNumFiles: Integer; inline;
      function GetFile (const aNdx: Integer): TFile; inline;

    (* Checks if given directory or file is valid.  Result may depend on the
       project configuration. *)
      function IsValidFile (const aInfo: TSearchRec): Boolean;
    public
    (* Constructor.
       @param(aName Directory name.)
       @param(aOwner Directory owner.  If @nil then asume it is root.) *)
      constructor Create (const aName: String; aOwner: TDirectory = Nil);
    (* Destructor. *)
      destructor Destroy; override;
    (* Clears data from the directory. *)
      procedure Clear;
    (* Builds and returns the full directory path. *)
      function GetPath: String;
    (* Scans the directory and populates with files and subdirectories.
       @param(aLevel How much deep the scan will be.  0 will scan the current
              directory only, 1 will scan subdirectories, etc.) *)
      procedure Scan (aLevel: Integer);

    (* Owner directory. *)
      property Owner: TDirectory read fOwner;
    (* Directory name.  If it is the root directory, then it contains the full
       path. *)
      property Name: String read fName;
    (* How many subdirectories contains. *)
      property NumDirs: Integer read GetNumDirs;
    (* Returns reference to a subdirectory.  It is 0-based. *)
      property SubDir[aNdx: Integer]: TDirectory read GetSubDir;
    (* How many files contains. *)
      property NumFiles: Integer read GetNumFiles;
    (* Returns information about a file.  It is 0-based. *)
      property Files[aNdx: Integer]: TFile read GetFile;
    end;



  (* Stores and manages a project.

     Right now a project is just a list of directories and files.

     If @link(ProgressDlg) exists, then it is used to show progress. *)
    TProject = class (TObject)
    private
      fBasePath: String;
      fRoot: TDirectory;
      fOnChange: TNotifyEvent;

    (* Event to cancel the scanning. *)
      procedure CancelScan (aSender: TObject);
    public
    (* Destructor. *)
      destructor Destroy; override;
    (* Opens a project.

       Right now, a project is just a directory. *)
      procedure Open (aPath: String);
    (* Scans the directory searching for files and directories. *)
      procedure Scan;
    (* Clears the project data. *)
      procedure Clear;

    (* Base path. *)
      property BasePath: String read fBasePath;
    (* Root directory.  It may be @nil. *)
      property Root: TDirectory read fRoot;

    (* Event triggered when project changed.  For example, when opening a new
       one, adding items, etc.

       Note that this doesn't triggers if a file changes (yet). *)
      property OnChange: TNotifyEvent read fOnChange write fOnChange;
    end;

implementation

  uses
    Main, ProgressDialogForm,
    ComCtrls, Forms;

  const
    DefaultDirDepth = 5;

  var
  (* Flag to know if current operation has been canceled. *)
    fCancelOperation: Boolean;

(*
 * TProjectConfiguration
 ***************************************************************************)

  function TProjectConfiguration.GetDirectoryDepth: Integer;
  begin
    Result := Self.GetIntValue (idProjectConfig, 'dir_depth', DefaultDirDepth)
  end;



  procedure TProjectConfiguration.SetDirectoryDepth (aValue: Integer);
  begin
    if 1 > aValue then aValue := DefaultDirDepth;
    Self.SetIntValue (idProjectConfig, 'dir_depth', aValue)
  end;



  function TProjectConfiguration.GetShowHiddenFiles: Boolean;
  begin
    Result := Self.GetBoolValue (idProjectConfig, 'show_hidden_files', False)
  end;



  procedure TProjectConfiguration.SetShowHiddenFiles (aValue: Boolean);
  begin
    Self.SetBooleanValue (idProjectConfig, 'show_hidden_files', aValue)
  end;



  function TProjectConfiguration.GetShowHiddenDirectories: Boolean;
  begin
    Result := Self.GetBoolValue (idProjectConfig, 'show_hidden_dirs', False)
  end;



  procedure TProjectConfiguration.SetShowHiddenDirectories (aValue: Boolean);
  begin
    Self.SetBooleanValue (idProjectConfig, 'show_hidden_dir', aValue)
  end;



(*
 * TFile
 ***************************************************************************)

(* Constructor. *)
  constructor TFile.Create (const aName: String; aOwner: TDirectory);
  begin
    if not Assigned (aOwner) then
      raise Exception.CreateFmt ('File %s without directory?', [aName]);
    inherited Create;
    fOwner := aOwner;
    fName := aName
  end;



(* Builds path. *)
  function TFile.GetPath: String;
  begin
  { All files are in directories. }
    Result := IncludeTrailingPathDelimiter (fOwner.GetPath)
  end;



(*
 * TDirectory
 ***************************************************************************)

  function TDirectory.GetNumDirs: Integer;
  begin
    Result := fDirList.Count
  end;



  function TDirectory.GetSubDir (const aNdx: Integer): TDirectory;
  begin
    Result := fDirList[aNdx]
  end;



  function TDirectory.GetNumFiles: Integer;
  begin
    if Assigned (fFileList) then Result := fFileList.Count else Result := 0
  end;



  function TDirectory.GetFile (const aNdx: Integer): TFile;
  begin
    Result := fFileList[aNdx]
  end;


(* Checks if given directory or file is valid. *)
  function TDirectory.IsValidFile (const aInfo: TSearchRec): Boolean;

    function IsHidden: Boolean; inline;
    begin
      Result := ((aInfo.Attr and faHidden) = faHidden) or (aInfo.Name[1] = '.')
    end;

  var
    lCfgSection: TProjectConfiguration;
  begin
    lCfgSection := TProjectConfiguration (
      MLSDEApplication.Configuration.FindConfig (idProjectConfig)
    );
  { Directories. }
    if (aInfo.Attr and faDirectory) = faDirectory then
    begin
    { Avoid navigation entries. }
      if (aInfo.Name = '.') or (aInfo.Name = '..') then Exit (False);
    { Hidden directories. }
      if (not lCfgSection.ShowHiddenDirs) and IsHidden then
        Exit (False)
    end
  { Files. }
    else begin
    { Hidden files. }
      if (not lCfgSection.ShowHiddenFiles) and IsHidden then
        Exit (False)
    end;
  { If here, then it is valid. }
    Result := True
  end;



(* Constructor. *)
  constructor TDirectory.Create (const aName: String; aOwner: TDirectory);
  begin
    inherited Create;
    fOwner := aOwner;
    fName := ExcludeTrailingPathDelimiter (ExtractFileName (aName));
    fDirList := TDirectoryList.Create;
    fFileList := Nil { This is created only if needed. }
  end;



(* Destructor. *)
  destructor TDirectory.Destroy;
  begin
    fFileList.Free;
    fDirList.Free;
    inherited Destroy
  end;


(* Clears data from the directory. *)
  procedure TDirectory.Clear;
  begin
    FreeAndNil (fFileList);
    fDirList.Clear
  end;



(* Builds path. *)
  function TDirectory.GetPath: String;
  begin
  { If it's root, it doesn't has owner. }
    if fOwner <> Nil then
      Result := IncludeTrailingPathDelimiter (fOwner.GetPath + fName)
    else
      Result := IncludeTrailingPathDelimiter (fProject.fBasePath + fName)
  end;



(* Scans the directory and populates with files and subdirectories. *)
  procedure TDirectory.Scan (aLevel: Integer);

    procedure AddSubdirectory (const aName: String); inline;
    begin
      fDirList.Add (TDirectory.Create (aName, Self))
    end;

    procedure AddFile (const aName: String); inline;
    begin
    { TODO: Filter files by type (i.e. add only known files). }
      if not Assigned (fFileList) then fFileList := TFileList.Create (True);
      fFileList.Add (TFile.Create (aName, Self))
    end;

  var
    lFileInfo: TSearchRec;
    lDirectory: TDirectory;
  begin
    Self.Clear;
  { Get files and directories. }
    if FindFirst (
      Self.GetPath + '*',
      faAnyFile or faDirectory or faHidden,
      lFileInfo
    ) = 0 then
    try
      repeat
        if fCancelOperation then Exit;
        if Random (100) = 50 then
        begin
	  if ProgressDlg <> Nil then
	    ProgressDlg.LabelText.Caption := Self.GetPath + lFileInfo.Name;
          Application.ProcessMessages
        end;
        if Self.IsValidFile (lFileInfo) then
        begin
          if (lFileInfo.Attr and faDirectory) = faDirectory then
            AddSubdirectory (lFileInfo.Name)
          else
            AddFile (lFileInfo.Name)
        end
      until FindNext (lFileInfo) <> 0
    finally
      FindClose (lFileInfo)
    end;
  { Next level. }
    Dec (aLevel);
    if aLevel > 0 then for lDirectory in fDirList do lDirectory.Scan (aLevel)
  end;



(*
 * TProject
 ***************************************************************************)

(* Event to cancel the scanning. *)
  procedure TProject.CancelScan (aSender: TObject);
  begin
    fCancelOperation := True
  end;



(* Destructor. *)
  destructor TProject.Destroy;
  begin
    Self.Clear;
    inherited Destroy
  end;



(* Opens a project. *)
  procedure TProject.Open (aPath: String);
  begin
    Self.Clear;
    aPath := Trim (aPath);
  { If no path, then root. }
    if aPath = '' then
    begin
      aPath := ExcludeTrailingPathDelimiter (GetUserDir);
      fBasePath := ExtractFileDir (aPath);
      fRoot := TDirectory.Create (
        ExtractFileName (ExcludeTrailingPathDelimiter (aPath))
      );
      fRoot.fProject := Self
    end
    else begin
      fBasePath := IncludeTrailingPathDelimiter (ExtractFileDir (aPath));
      fRoot := TDirectory.Create (
        ExtractFileName (ExcludeTrailingPathDelimiter (aPath))
      );
      fRoot.fProject := Self
    end;
  { Populate. }
    Self.Scan;
    if Assigned (fOnChange) then fOnChange (Self)
  end;



(* Scans the project directory. *)
  procedure TProject.Scan;
  begin
  { Set up the progress dialog, if available. }
    fCancelOperation := False;
    if ProgressDlg <> Nil then
    begin
      ProgressDlg.ProgressBar.Style := pbstMarquee;
      ProgressDlg.OnCancelAction := @Self.CancelScan
    end;
  { Do scan. }
    fRoot.Scan (
      TProjectConfiguration (
        MLSDEApplication.Configuration.FindConfig (idProjectConfig)
      ).DirDepth
    );
  { Reset the progress dialog, if available. }
    if ProgressDlg <> Nil then ProgressDlg.OnCancelAction := Nil;
  { If operation was cancelled, remove data. }
    if fCancelOperation then Self.Clear
  end;



(* Clears project. *)
  procedure TProject.Clear;
  begin
    FreeAndNil (fRoot);
    fBasePath := ''
  end;

end.

