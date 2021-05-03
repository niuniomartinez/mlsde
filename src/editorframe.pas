unit EditorFrame;
(*< Implements the source editor.
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
    Configuration,
    Classes, Forms, Graphics, SynEdit;

  const
  (* Name for the editor configuration section. *)
    idEditorConfig = 'editor';

  type
  (* Manages editor configuration. *)
    TEditorConfiguration = class (TCustomConfiguration)
    private
      fFont: TFont;

      function GetShowGutter: Boolean;
      procedure SetShowGutter (const aValue: Boolean);
      function GetShowLinesMultiplesOf: Integer;
      procedure SetShowLinesMultiplesOf (const aValue: Integer);
    public
    (* Constructor. *)
      constructor Create; override;
    (* Destructor. *)
      destructor Destroy; override;
    (* "Parses command line options." but actually loads the configuration. *)
      procedure ParseCommandLineOptions; override;
    (* Returns a reference to the text font. *)
      function GetFont: TFont;
    (* Gets font definition from given text font. *)
      procedure CopyFont (aFont: TFont);

    (* Show or hide gutter (line numbers, change marks). *)
      property ShowGutter: Boolean read GetShowGutter write SetShowGutter;
    (* Show lines multiples of... *)
      property ShowLinesMultiplesOf: Integer
        read GetShowLinesMultiplesOf write SetShowLinesMultiplesOf;
    end;



  (* Source editor frame.  This is created in a tab in the @link(MainWindow). *)
    TSourceEditorFrame = class (TFrame)
      SynEdit: TSynEdit;

    (* User modified the text. *)
      procedure SynEditChange (Sender: TObject);
    private
      fFileName, fPath: String;
      fOnChange: TNotifyEvent;

      function getModified: Boolean; inline;
    public
    (* Constructor. *)
      constructor Create (aOwer: TComponent); override;
    (* Loads the given source file.

       It also searchs and sets-up the syntax highlighter and the autocomplete
       tool. *)
      procedure Load (aSourceFileName: String);
    (* Saves the sources to the file.

       Note it saves in the same file it was loaded. *)
      procedure Save;
    (* Applyes editor configuration. *)
      procedure ApplyEditorConfiguration;

    (* Tells if source was modified. *)
      property Modified: Boolean read getModified;
    (* Event triggered when source file change. *)
      property OnChange: TNotifyEvent read fOnChange write fOnChange;
    end;

implementation

  uses
    Main, Utils,
    SynGutterLineNumber,
    sysutils;

{$R *.lfm}

(*
 * TEditorConfiguration
 ************************************************************************)

  const
    EditorSection = idEditorConfig;
  { Defaults. }
    ShowGutter = True;
    FontName = 'Monospace';
    FontSize = 12;
    ShowLinesNum = 10;

  function TEditorConfiguration.GetShowGutter: Boolean;
  begin
    Result := Self.GetBoolValue (EditorSection, 'show_gutter', True)
  end;

  procedure TEditorConfiguration.SetShowGutter (const aValue: Boolean);
  begin
    Self.SetBooleanValue (EditorSection, 'show_gutter', aValue)
  end;



  function TEditorConfiguration.GetShowLinesMultiplesOf: Integer;
  begin
    Result := Self.GetIntValue (
      EditorSection,
      'show_lines_multiples',
      ShowLinesNum
    )
  end;

  procedure TEditorConfiguration.SetShowLinesMultiplesOf(const aValue: Integer);
  begin
    Self.SetIntValue (EditorSection, 'show_lines_multiples', aValue)
  end;



(* Constructor. *)
  constructor TEditorConfiguration.Create;
  begin
    inherited Create;
    fFont := TFont.Create
  end;



  destructor TEditorConfiguration.Destroy;
  begin
    fFont.Free;
    inherited Destroy
  end;



(* Gets configuration. *)
  procedure TEditorConfiguration.ParseCommandLineOptions;
  begin
    inherited ParseCommandLineOptions;
    fFont.Name := Self.GetValue (EditorSection, 'font', FontName);
    fFont.Size := Self.GetIntValue (EditorSection, 'font_size', FontSize)
  end;



(* Returns font. *)
  function TEditorConfiguration.GetFont: TFont;
  begin
    Result := fFont
  end;



(* Defines font. *)
  procedure TEditorConfiguration.CopyFont(aFont: TFont);
  begin
    fFont.Assign (aFont);
    Self.SetValue (EditorSection, 'font', fFont.Name);
    Self.SetIntValue (EditorSection, 'font_size', fFont.Size)
  end;



(*
 * TSourceEditorFrame
 ************************************************************************)

  function TSourceEditorFrame.getModified: Boolean;
  begin
    Result := Self.SynEdit.Modified
  end;



(* User modified the file. *)
  procedure TSourceEditorFrame.SynEditChange (Sender: TObject);
  begin
    if Self.SynEdit.Modified then
      Self.Parent.Caption := '*' + fFileName
    else
      Self.Parent.Caption := fFileName;
    if Assigned (fOnChange) then fOnChange (Self)
  end;



(* Constructor. *)
  constructor TSourceEditorFrame.Create (aOwer: TComponent);
  begin
    inherited Create (aOwer);
  { Remove name to avoid error "Duplicated component name". }
    Self.Name := '';
    fOnChange := Nil;
  { Load configuration. }
    Self.ApplyEditorConfiguration
  end;



(* Loads source file. *)
  procedure TSourceEditorFrame.Load (aSourceFileName: String);
  begin
    aSourceFileName := ExpandFileName (aSourceFileName);
    Self.SynEdit.Lines.LoadFromFile (aSourceFileName);
    fPath := IncludeTrailingPathDelimiter (ExtractFileDir (aSourceFileName));
    fFileName := ExtractFileName (aSourceFileName);
    Self.Name := 'edit' + NormalizeIdentifier  (aSourceFileName);
    Self.Parent.Name := NormalizeIdentifier (aSourceFileName);
    Self.Parent.Caption := fFileName;
    Self.SynEdit.Highlighter :=
      MLSDEApplication.SynManager.GetHighlighterForExt (
        GetFileExtension (aSourceFileName)
      );
    if Assigned (fOnChange) then fOnChange (Self)
  end;



(* Saves the sources to the file. *)
  procedure TSourceEditorFrame.Save;
  begin
    if Self.SynEdit.Modified then
    begin
      Self.SynEdit.Lines.SaveToFile (fPath + fFileName);
      Self.SynEdit.Modified := False;
      Self.SynEditChange (Self.SynEdit)
    end
  end;



(* Applyes configuration. *)
  procedure TSourceEditorFrame.ApplyEditorConfiguration;
  var
    lConfiguration: TEditorConfiguration;
    lGutterLines: TSynGutterLineNumber;
  begin
    lConfiguration := TEditorConfiguration (
      MLSDEApplication.Configuration.FindConfig (idEditorConfig)
    );
    Self.SynEdit.Font.Assign (lConfiguration.GetFont);
    Self.SynEdit.Gutter.Visible := lConfiguration.ShowGutter;
    lGutterLines := TSynGutterLineNumber (
      Self.SynEdit.Gutter.Parts.ByClass[TSynGutterLineNumber, 0]
    );
    lGutterLines.ShowOnlyLineNumbersMultiplesOf :=
      lConfiguration.ShowLinesMultiplesOf
  end;

end.

