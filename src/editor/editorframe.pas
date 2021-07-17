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
    Classes, Forms, Graphics, SynEdit, SynCompletion;

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
      function GetShowChangeMarks: Boolean;
      procedure SetShowChangeMarks (const aValue: Boolean);
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
    (* Show change marks. *)
      property ShowChangeMarks: Boolean
        read GetShowChangeMarks write SetShowChangeMarks;
    end;



  (* Source editor frame.  This is created in a tab in the @link(MainWindow). *)
    TSourceEditorFrame = class (TFrame)
      SynCompletion: TSynCompletion;
      SynEdit: TSynEdit;

    (* User modified the text. *)
      procedure SynEditChange (Sender: TObject);
    (* User clicked in the editor with mouse. *)
      procedure SynEditClick (Sender: TObject);
    (* User pressed a key. *)
      procedure SynEditKeyUp (
        Sender: TObject;
        var Key: Word;
        Shift: TShiftState
      );
    (* Triggers autocompletion. *)
      procedure AutocompletionExecute (Sender: TObject);
    (* I think it changes the selection position in the autocompletion popup.
       It was long since I used this for the first time (copying from 2019
       branch, and it was written few years before).  Too lazy to do testings
       now. *)
      procedure AutocompleteSearchPosition (var aPosition: integer);
    private
      fFileName, fPath: String;
      fOldCaretX, fOldCaretY: LongInt;
      fOnChange: TNotifyEvent;

      function getModified: Boolean; inline;
    (* Updates cursor position panel in main window status bar.

       It also may update the autocompletion list. *)
      procedure UpdateCursorPositionPanel;
    (* Obtains the autocompletion suggestions. *)
      procedure GetAutocompletionSuggestions;
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
    (* Updates status bar information. *)
      procedure UpdateStatusBarInfo;
    (* Sets focus. *)
      procedure SetFocus; override;
    (* Forces the language. *)
      procedure SetLanguage (aLanguage: String);
    (* Closes tab.

      It checks if there are modifications and allows to cancel if so. *)
      procedure CloseTab;

    (* Tells if source was modified. *)
      property Modified: Boolean read getModified;
    (* Event triggered when source file change. *)
      property OnChange: TNotifyEvent read fOnChange write fOnChange;
    end;

implementation

  uses
    Autocompletion, GUIUtils, Main, MainForm, MLSDEHighlighter, Utils,
    ComCtrls, SynGutterLineNumber, SynGutterChanges,
    sysutils;

{$R *.lfm}

  resourcestring
    TextSyntax = 'Text';
    errFileNotFound = 'File "%s" not found.';

    TextClosing = 'Closing tab';
    TextFileModified = 'The file changes have not been saved.'+
      #10'Do you really want to close the tab?';

(*
 * TEditorConfiguration
 ************************************************************************)

  const
    EditorSection = idEditorConfig;
  { Defaults. }
    ShowGutterDefault = True;
    ShowCHangeMarksDefault = True;
    FontNameDefault = 'Monospace';
    FontSizeDefault = 12;
    ShowLinesNumDefault = 10;

  function TEditorConfiguration.GetShowGutter: Boolean;
  begin
    Result := Self.GetBoolValue (
      EditorSection, 'show_gutter',
      ShowGutterDefault
    )
  end;

  procedure TEditorConfiguration.SetShowGutter (const aValue: Boolean);
  begin
    Self.SetBooleanValue (EditorSection, 'show_gutter', aValue)
  end;



  function TEditorConfiguration.GetShowLinesMultiplesOf: Integer;
  begin
    Result := Self.GetIntValue (
      EditorSection, 'show_lines_multiples',
      ShowLinesNumDefault
    )
  end;

  procedure TEditorConfiguration.SetShowLinesMultiplesOf (const aValue: Integer);
  begin
    Self.SetIntValue (EditorSection, 'show_lines_multiples', aValue)
  end;



  function TEditorConfiguration.GetShowChangeMarks: Boolean;
  begin
    Result := Self.GetBoolValue (
      EditorSection, 'show_change_marks',
      ShowCHangeMarksDefault
    )
  end;

  procedure TEditorConfiguration.SetShowChangeMarks (const aValue: Boolean);
  begin
    Self.SetBooleanValue (EditorSection, 'show_change_marks', aValue)
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
    fFont.Name := Self.GetValue (EditorSection, 'font', FontNameDefault);
    fFont.Size := Self.GetIntValue (EditorSection, 'font_size', FontSizeDefault)
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



(* Updates cursor position panel in main window status bar. *)
  procedure TSourceEditorFrame.UpdateCursorPositionPanel;
  var
    lText: String;
  begin
  { If changes line, adds to autocompletion. }
    if fOldCaretY <> Self.SynEdit.CaretY then
    begin
      lText := Trim (Self.SynEdit.Lines[fOldCaretY - 1]);
      if lText <> EmptyStr then
        MLSDEApplication.AutocompletionWordList.Add (lText)
    end;
  { Update panel. }
    fOldCaretX := Self.SynEdit.CaretX;
    fOldCaretY := Self.SynEdit.CaretY;
    if MainWindow.StatusBar.Visible then
      MainWindow.StatusBar.Panels[CursorPosStatusPanel].Text :=
        Format ('%d, %d', [fOldCaretY, fOldCaretX])
  end;



(* User modified the file. *)
  procedure TSourceEditorFrame.SynEditChange (Sender: TObject);
  var
    cX, cY: Integer;
    lLine: String;
  begin
    if Self.SynEdit.Modified then
    begin
      Self.Parent.Caption := '*' + fFileName;
    { If key is not alphanumeric check current line to see if should add a new
      word to the autocompletion component. }
      cX := Self.SynEdit.CaretX - 1; cY := Self.SynEdit.CaretY - 1;
      lLine := Self.SynEdit.Lines[cY];
      if (cX > 0) and (Length (lLine) >= cX) then
      begin
        if IsSeparator (lLine[cX]) then
          MLSDEApplication.AutocompletionWordList.Add (lLine)
      end
      else
        MLSDEApplication.AutocompletionWordList.Add (lLine);
    end
    else
      Self.Parent.Caption := fFileName;
    if Assigned (fOnChange) then fOnChange (Self)
  end;



(* Mouse click. *)
  procedure TSourceEditorFrame.SynEditClick (Sender: TObject);
  begin
  { Update cursor position in the estatus panel. }
    if (fOldCaretX <> Self.SynEdit.CaretX)
    or (fOldCaretY <> Self.SynEdit.CaretY)
    then
      Self.UpdateCursorPositionPanel
  end;



(* Keyboard. *)
  procedure TSourceEditorFrame.SynEditKeyUp (
    Sender: TObject;
    var Key: Word;
    Shift: TShiftState
  );
  begin
  { Update cursor position in the status panel. }
    if (fOldCaretX <> Self.SynEdit.CaretX)
    or (fOldCaretY <> Self.SynEdit.CaretY)
    then
      Self.UpdateCursorPositionPanel
  end;



(* Triggers autocompletion. *)
  procedure TSourceEditorFrame.AutocompletionExecute (Sender: TObject);
  begin
    Self.GetAutocompletionSuggestions
  end;



(* Changes position of the selection in the autocompletion? *)
  procedure TSourceEditorFrame.AutocompleteSearchPosition
   (var aPosition: integer);
  begin
    Self.GetAutocompletionSuggestions;
    if Self.SynCompletion.ItemList.Count > 0 then
      aPosition := 0
    else
      aPosition := -1
  end;



(* Obtains the autocompletion suggestions. *)
  procedure TSourceEditorFrame.GetAutocompletionSuggestions;
  begin
    Self.SynCompletion.ItemList.Clear;
    MLSDEApplication.AutocompletionWordList.GetWordSuggestions (
      Self.SynCompletion.CurrentString,
      Self.SynCompletion.ItemList
    )
  end;



(* Constructor. *)
  constructor TSourceEditorFrame.Create (aOwer: TComponent);
  begin
    inherited Create (aOwer);
  { Remove name to avoid error "Duplicated component name". }
    Self.Name := '';
    fOnChange := Nil
  end;



(* Loads source file. *)
  procedure TSourceEditorFrame.Load (aSourceFileName: String);
  begin
    aSourceFileName := ExpandFileName (aSourceFileName);
    if not FileExists (aSourceFileName) then
      raise EFileNotFoundException.CreateFmt (
        errFileNotFound,
        [aSourceFileName]
      );
    Self.SynEdit.Lines.LoadFromFile (aSourceFileName);
    fPath := IncludeTrailingPathDelimiter (ExtractFileDir (aSourceFileName));
    fFileName := ExtractFileName (aSourceFileName);
    Self.Name := Concat ('edit', NormalizeIdentifier  (aSourceFileName));
    Self.Parent.Name := NormalizeIdentifier (aSourceFileName);
    Self.Parent.Caption := fFileName;
    Self.SynEdit.Highlighter :=
      MLSDEApplication.SynManager.GetHighlighterForExt (
        GetFileExtension (aSourceFileName)
      );
    if Assigned (fOnChange) then fOnChange (Self);
    MLSDEApplication.AutocompletionWordList.AddText (Self.SynEdit.Lines)
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

    procedure ConfigureEditor; inline;
    begin
      Self.SynEdit.Font.Assign (lConfiguration.GetFont);
      Self.SynEdit.Color := MLSDEApplication.SynManager.Style.Background;
      Self.SynEdit.Font.Color := MLSDEApplication.SynManager.Style.Foreground
    end;

    procedure ConfigureGutter; inline;
    begin
      Self.SynEdit.Gutter.Visible := lConfiguration.ShowGutter;
      TSynGutterLineNumber (
        Self.SynEdit.Gutter.Parts.ByClass[TSynGutterLineNumber, 0]
      ).ShowOnlyLineNumbersMultiplesOf :=
        lConfiguration.ShowLinesMultiplesOf;
      TSynGutterChanges (
        Self.SynEdit.Gutter.Parts.ByClass[TSynGutterChanges, 0]
      ).Visible :=
        lConfiguration.ShowChangeMarks
    end;

  begin
    lConfiguration := TEditorConfiguration (
      MLSDEApplication.Configuration.FindConfig (idEditorConfig)
    );
    ConfigureEditor;
    ConfigureGutter
  end;



(* Updates status bar information. *)
  procedure TSourceEditorFrame.UpdateStatusBarInfo;
  begin
    if MainWindow.StatusBar.Visible then
    begin
      Self.UpdateCursorPositionPanel;
      if Assigned (Self.SynEdit.Highlighter) then
        MainWindow.StatusBar.Panels[LanguageStatusPanel].Text :=
          TMLSDEHighlighter (Self.SynEdit.Highlighter).Language
      else
        MainWindow.StatusBar.Panels[LanguageStatusPanel].Text := TextSyntax
    end
  end;



(* Sets focus. *)
  procedure TSourceEditorFrame.SetFocus;
  begin
    Self.SynEdit.SetFocus
  end;



(* Forces language. *)
  procedure TSourceEditorFrame.SetLanguage(aLanguage: String);
  begin
    Self.SynEdit.Highlighter :=
      MLSDEApplication.SynManager.GetHighlighter (aLanguage);
    Self.UpdateStatusBarInfo
  end;



(* Closes tab. *)
  procedure TSourceEditorFrame.CloseTab;
  begin
  { Check if there are modifications. }
    if Self.SynEdit.Modified then
    { Allows to cancel the action. }
      if not ConfirmationDialog (TextClosing, TextFileModified) then
        Exit;
  { Closes tab. }
    TTabSheet (Self.Parent).Free
  end;

end.

