unit ColorSchemaFrame;
(*< Implements the color schema editor that allows to define the color schema
    used in syntax highlighting. *)
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
    ConfigurationDialogFrame, DividerBevel, SynEdit, SynHighlighterPas,
    SynHighlighterJava, StdCtrls, Buttons, ExtCtrls, Dialogs, ColorBox, Classes,
    MLSDEHighlighter;

  type
  (* Color schema editor. *)
    TColorShcemaEditor = class (TConfigurationFrame)
      panelColorSchema: TPanel;
       titleSchema: TDividerBevel;
       editSchemaList: TComboBox;
      panelSchemaView: TPanel;
       listTokenTypes: TListBox;
       spliterShowSchema: TSplitter;
       editSourceSample: TSynEdit;
       JavaSyntax: TSynJavaSyn;
      panelAttributeEdition: TPanel;
       titleAttributeEdition: TDividerBevel;
       lblColorTexto: TLabel;
       selectTextColor: TColorBox;
       lblBackgroundColor: TLabel;
       selectBackgroundColor: TColorBox;
       chkBold: TCheckBox;
       chkItalic: TCheckBox;
       chkUnderlined: TCheckBox;

    (* User selected a schreme. *)
      procedure editSchemaListChange (Sender: TObject);
    (* User selected a token to edit. *)
      procedure listTokenTypesClick (Sender: TObject);
    (* Foreground color changed. *)
      procedure selectTextColorColorChanged (Sender: TObject);
    (* Background color changed. *)
      procedure selectBackgroundtColorColorChanged (Sender: TObject);
    (* Checboxes chnged. *)
      procedure CheckboxesChange (Sender: TObject);
    private
      fStyleCopy: TMLSDEHighlightStyle;
      fSchemeList: TStringList;

    (* Returns the token value for the list token item. *)
      function GetItemTokenValue: TToken; inline;
    (* Applies style copy to highlighter. *)
      procedure ApplyStyle;
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
    EditorFrame, Main,
    Graphics, SynEditHighlighter, SysUtils;

{$R *.lfm}

(*
 * TColorShcemaEditor
 ************************************************************************)
   const
   (* Dictionary between token list item and actual token values. *)
     DictItemtoken: array [1..13] of TToken = (
       tkComment, tkDirective, tkKeyword, tkType, tkIdentifier, tkOperator,
       tkSymbol, tkLabel, tkVariable, tkString, tkNumber, tkAssembler,
       tkError
     );

(* Get token. *)
  function TColorShcemaEditor.GetItemTokenValue: TToken;
  begin
    Result := DictItemtoken[Self.listTokenTypes.ItemIndex]
  end;



(* /ser selected scheme. *)
  procedure TColorShcemaEditor.editSchemaListChange (Sender: TObject);
  begin
    if editSchemaList.ItemIndex >= 0 then
    begin
      fStyleCopy.LoadFromFile (fSchemeList[editSchemaList.ItemIndex]);
      Self.listTokenTypesClick (Self.listTokenTypes)
    end
  end;



(* User selected item. *)
  procedure TColorShcemaEditor.listTokenTypesClick (Sender: TObject);
  var
    lToken: TToken;
  begin
  { To change checkboxes values triggers the onChange event; so deactivate to
    prevent it. }
    chkBold.OnChange := Nil;
    chkItalic.OnChange := Nil;
    chkUnderlined.OnChange := Nil;
  { Select the token and show current values. }
    if Self.listTokenTypes.ItemIndex = 0 then
    begin
    { Default attributes are a bit special. }
      selectTextColor.Style := selectTextColor.Style - [cbIncludeNone];
      selectTextColor.Selected := fStyleCopy.Foreground;
      selectBackgroundColor.Style := selectBackgroundColor.Style - [cbIncludeNone];
      selectBackgroundColor.Selected := fStyleCopy.Background;
      chkBold.Enabled := False; chkBold.Checked := False;
      chkItalic.Enabled := False; chkItalic.Checked := False;
      chkUnderlined.Enabled := False; chkUnderlined.Checked := False;
    end
    else begin
      lToken := Self.GetItemTokenValue;
      selectTextColor.Style := selectTextColor.Style + [cbIncludeNone];
      selectTextColor.Selected := fStyleCopy.Attributes[lToken].Foreground;
      selectBackgroundColor.Style := selectBackgroundColor.Style + [cbIncludeNone];
      selectBackgroundColor.Selected := fStyleCopy.Attributes[lToken].Background;
      chkBold.Enabled := True;
      chkBold.Checked := fsBold in fStyleCopy.Attributes[lToken].Style;
      chkItalic.Enabled := True;
      chkItalic.Checked := fsItalic in fStyleCopy.Attributes[lToken].Style;
      chkUnderlined.Enabled := True;
      chkUnderlined.Checked := fsUnderline in fStyleCopy.Attributes[lToken].Style
    end;
  { Restores event. }
    chkBold.OnChange := @Self.CheckboxesChange;
    chkItalic.OnChange := @Self.CheckboxesChange;
    chkUnderlined.OnChange := @Self.CheckboxesChange
  end;



(* Style changed. *)
  procedure TColorShcemaEditor.selectTextColorColorChanged (Sender: TObject);
  begin
    if Self.listTokenTypes.ItemIndex = 0 then
      fStyleCopy.Foreground := Self.selectTextColor.Selected
    else
      fStyleCopy.Attributes[Self.GetItemTokenValue].Foreground :=
        Self.selectTextColor.Selected;
    Self.ApplyStyle
  end;

  procedure TColorShcemaEditor.selectBackgroundtColorColorChanged (Sender: TObject);
  begin
    if Self.listTokenTypes.ItemIndex = 0 then
      fStyleCopy.Background := Self.selectBackgroundColor.Selected
    else
      fStyleCopy.Attributes[Self.GetItemTokenValue].Background :=
        Self.selectBackgroundColor.Selected;
    Self.ApplyStyle
  end;

  procedure TColorShcemaEditor.CheckboxesChange (Sender: TObject);
  var
    lCheckbox: TCheckBox absolute Sender;
    lStyle: TFontStyles;
  begin
    if lCheckbox.Enabled then
    begin
      lStyle := [];
      if chkBold.Checked then lStyle := [fsBold];
      if chkItalic.Checked then lStyle := [fsItalic] + lStyle;
      if chkUnderlined.Checked then lStyle := [fsUnderline] + lStyle;
      fStyleCopy.Attributes[Self.GetItemTokenValue].Style := lStyle;
      Self.ApplyStyle
    end
  end;



(* Applies style. *)
  procedure TColorShcemaEditor.ApplyStyle;

    procedure AssignAttributes (aAttr:TSynHighlighterAttributes; aToken:TToken);
    begin
      if Assigned (fStyleCopy.Attributes[aToken]) then
        aAttr.Assign (fStyleCopy.Attributes[aToken])
      else begin
        aAttr.Background := fStyleCopy.Background;
        aAttr.Foreground := fStyleCopy.Foreground;
        aAttr.Style := []
      end;
    end;

  var
    lEditorConfiguration: TEditorConfiguration;
  begin
    lEditorConfiguration := TEditorConfiguration (
      MLSDEApplication.Configuration.FindConfig (idEditorConfig)
    );
    Self.editSourceSample.Font.Assign (lEditorConfiguration.GetFont);;
    Self.editSourceSample.Color := fStyleCopy.Background;
    AssignAttributes (Self.JavaSyntax.AnnotationAttri, tkDirective);
    AssignAttributes (Self.JavaSyntax.CommentAttri, tkComment);
    AssignAttributes (Self.JavaSyntax.DocumentAttri, tkDirective);
    AssignAttributes (Self.JavaSyntax.IdentifierAttri, tkUnknown);
    AssignAttributes (Self.JavaSyntax.InvalidAttri, tkError);
    AssignAttributes (Self.JavaSyntax.KeyAttri, tkKeyword);
    AssignAttributes (Self.JavaSyntax.NumberAttri, tkNumber);
    AssignAttributes (Self.JavaSyntax.SpaceAttri, tkUnknown);
    AssignAttributes (Self.JavaSyntax.StringAttri, tkString);
    AssignAttributes (Self.JavaSyntax.SymbolAttri, tkSymbol)
  end;



(* Constructor. *)
  constructor TColorShcemaEditor.Create(aOwner: TComponent);
  begin
    inherited Create(aOwner);
    fStyleCopy := TMLSDEHighlightStyle.Create;
    fSchemeList := TStringList.Create
  end;



(* Destructor. *)
  destructor TColorShcemaEditor.Destroy;
  begin
    fSchemeList.Free;
    fStyleCopy.Free;
    inherited Destroy
  end;



(* Initializes frame. *)
  procedure TColorShcemaEditor.Initialize;
  var
    lItem, lFileName: String;
  begin
  { Find schemes. }
    fSchemeList.Clear;
    MLSDEApplication.FindFileList (
      Concat (IncludeTrailingPathDelimiter ('schemes'), '*.csd'),
      fSchemeList
    );
    Self.editSchemaList.Items.Clear;
    for lItem in fSchemeList do
    begin
      lFileName := ExtractFileName (lItem);
      Self.editSchemaList.Items.Append (LeftStr (
        lFileName,
        Length (lFileName) - 4
      ))
    end;
  { Set scheme. }
    fStyleCopy.Assign (MLSDEApplication.SynManager.Style);
    Self.editSourceSample.Lines.Text := Self.JavaSyntax.SampleSource;
    Self.ApplyStyle;
    Self.listTokenTypes.ItemIndex := 0;
    Self.listTokenTypesClick (Self.listTokenTypes)
  end;



(* User accepted the configuration. *)
  procedure TColorShcemaEditor.AcceptConfiguration;
  begin
    MLSDEApplication.SynManager.Style.Assign (fStyleCopy);
    MLSDEApplication.SynManager.Style.SaveUserStyle
  end;

end.

