unit ConfigurationFrameEditor;
(*<Defines the frame used for Editor Configuration. *)
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
    Graphics, StdCtrls, Spin, ExtCtrls, Dialogs, DividerBevel, Classes;

  type
  (* Contains and manages the controls that allows to configure the
     source editor. *)
    TEditorConfigurationFrame = class (TConfigurationFrame)
      TitleGutter: TDividerBevel;
       chkShowGutter: TCheckBox;
       lblNthLineNumber: TLabel;
       editNthLineNumber: TSpinEdit;
       chkShowChangeMarks: TCheckBox;
      TitleTextFont: TDividerBevel;
       editFont: TLabeledEdit;
       btnSelectFont: TButton;
       FontDialog: TFontDialog;
       lblFontSize: TLabel;
       editFontSize: TSpinEdit;

    (* Activate or deactivate the gutter. *)
      procedure chkShowGutterChange (Sender: TObject);
    (* User wants to select the text font from dialog. *)
      procedure btnSelectFontClick (Sender: TObject);
    (* Font size changed. *)
      procedure editFontSizeChange (Sender: TObject);
    private
      fFont: TFont;
    public
    (* Constructor. *)
      constructor Create (aOwner: TComponent); override;
    (* Destructor. *)
      destructor Destroy; override;
    (* Initializes the frame. *)
      procedure Initialize; override;
    (* User accepted the configuration changes. *)
      procedure AcceptConfiguration; override;
    end;

implementation

  uses
    EditorFrame, Main;

{$R *.lfm}

(*
 * TEditorConfigurationFrame
 **************************************************************************)

(* Activates or deactivates the gutter. *)
  procedure TEditorConfigurationFrame.chkShowGutterChange (Sender: TObject);
  begin
    Self.editNthLineNumber.Enabled := Self.chkShowGutter.Checked;
    Self.chkShowChangeMarks.Enabled := Self.chkShowGutter.Checked
  end;



(* Selects font. *)
  procedure TEditorConfigurationFrame.btnSelectFontClick (Sender: TObject);
  begin
    Self.FontDialog.Font.Assign (fFont);
    if Self.FontDialog.Execute then
    begin
      fFont.Assign (Self.FontDialog.Font);
      Self.editFont.Text := fFont.Name;
      Self.editFontSize.OnChange := Nil;
      Self.editFontSize.Value := fFont.Size;
      Self.editFontSize.OnChange := @Self.editFontSizeChange
    end
  end;



(* Font size changes. *)
  procedure TEditorConfigurationFrame.editFontSizeChange (Sender: TObject);
  begin
    fFont.Size := TSpinEdit (Sender).Value
  end;



(* Create. *)
  constructor TEditorConfigurationFrame.Create (aOwner: TComponent);
  begin
    inherited Create  (aOwner);
    fFont := TFont.Create
  end;



(* Destructor. *)
  destructor TEditorConfigurationFrame.Destroy;
  begin
    fFont.Destroy;
    inherited Destroy
  end;



(* Initializes the frame. *)
  procedure TEditorConfigurationFrame.Initialize;
  var
    lEditorConfiguration: TEditorConfiguration;
  begin
    lEditorConfiguration := TEditorConfiguration (
      MLSDEApplication.Configuration.FindConfig (idEditorConfig)
    );
    Self.chkShowGutter.Checked := lEditorConfiguration.ShowGutter;
    Self.editNthLineNumber.Value := lEditorConfiguration.ShowLinesMultiplesOf;
    Self.chkShowChangeMarks.Checked := lEditorConfiguration.ShowChangeMarks;
    fFont.Assign (lEditorConfiguration.GetFont);
    Self.editFont.Text := fFont.Name;
    Self.editFontSize.Value := fFont.Size
  end;



(* Accepts changes. *)
  procedure TEditorConfigurationFrame.AcceptConfiguration;
  var
    lEditorConfiguration: TEditorConfiguration;
  begin
    lEditorConfiguration := TEditorConfiguration (
      MLSDEApplication.Configuration.FindConfig (idEditorConfig)
    );
    lEditorConfiguration.ShowGutter := Self.chkShowGutter.Checked;
    lEditorConfiguration.ShowLinesMultiplesOf := Self.editNthLineNumber.Value;
    lEditorConfiguration.ShowChangeMarks := Self.chkShowChangeMarks.Checked;
    lEditorConfiguration.CopyFont (fFont)
  end;

end.

