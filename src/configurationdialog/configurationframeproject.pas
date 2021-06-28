unit ConfigurationFrameProject;
(*<Defines the frame used for Project Configuration. *)
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
    ConfigurationDialogFrame, DividerBevel, StdCtrls, Spin, ComboEx;

  type
    TProjectConfigurationFrame = class (TConfigurationFrame)
      TitleFilesNDirs: TDividerBevel;
        lblDirectoryDepth: TLabel;
        EditDirectoryDepth: TSpinEdit;
        selectDirOrder: TComboBoxEx;
        lblDirectoryOrder: TLabel;
        chkKnownFiles: TCheckBox;
        chkHiddenFiles: TCheckBox;
        chkHiddenDirectories: TCheckBox;
    public
    (* Initializes the frame.

       It sets component values. *)
      procedure Initialize; override;
    (* User accepted configuration. *)
      procedure AcceptConfiguration; override;
    end;

implementation

  uses
    Main, Project;

{$R *.lfm}

(*
 * TProjectConfigurationFrame
 **************************************************************************)

  procedure TProjectConfigurationFrame.Initialize;
  var
    lProjectConfiguration: TProjectConfiguration;
  begin
    lProjectConfiguration := TProjectConfiguration (
      MLSDEApplication.Configuration.FindConfig (idProjectConfig)
    );
  { Files and directories. }
    chkKnownFiles.Checked := lProjectConfiguration.OnlyKnownFiles;
    chkHiddenFiles.Checked := lProjectConfiguration.ShowHiddenFiles;
    chkHiddenDirectories.Checked := lProjectConfiguration.ShowHiddenDirs;
    EditDirectoryDepth.Value := lProjectConfiguration.DirDepth;
    selectDirOrder.ItemIndex := Ord (lProjectConfiguration.DirOrder);
  end;



  procedure TProjectConfigurationFrame.AcceptConfiguration;
  var
    lProjectConfiguration: TProjectConfiguration;
  begin
    lProjectConfiguration := TProjectConfiguration (
      MLSDEApplication.Configuration.FindConfig (idProjectConfig)
    );
  { Files and directories. }
    lProjectConfiguration.OnlyKnownFiles := chkKnownFiles.Checked ;
    lProjectConfiguration.ShowHiddenFiles := chkHiddenFiles.Checked;
    lProjectConfiguration.ShowHiddenDirs := chkHiddenDirectories.Checked;
    lProjectConfiguration.DirDepth := EditDirectoryDepth.Value;
    lProjectConfiguration.DirOrder := TDirectoryOrder (selectDirOrder.ItemIndex)
  end;

end.

