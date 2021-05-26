unit LanguageSelectorDialogform;
(*<Implements a dialog to select one of the available languages. *)
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
    Forms, ButtonPanel, StdCtrls, Classes;

  type
  (* The language selector dialog. *)
    TLanguageSelectorDlg = class(TForm)
      ButtonPanel: TButtonPanel;
      LanguageList: TListBox;

    (* Constructor. *)
      procedure FormCreate (aSender: TObject);
    (* User double click. *)
      procedure LanguageListDblClick (Sender: TObject);
    private
      function GetLanguage: String; inline;
    public
    (* Selects the given language. *)
      procedure Select (aLanguage: String);

    (* Returns the selected language. *)
      property Language: String read GetLanguage;
    end;

implementation

  uses
    Main,
    Controls;

{$R *.lfm}

  resourcestring
  (* Name for the "Nil" highlighter. *)
    NilHighlighterString = 'Text';

(* Constructor. *)
  procedure TLanguageSelectorDlg.FormCreate (aSender: TObject);
  var
    Ndx: Integer;
  begin
  { Adds the "nil". }
    Self.LanguageList.AddItem (NilHighlighterString, Nil);
  { Adds languages. }
    for Ndx := 0 to MLSDEApplication.SynManager.Count - 1 do
      Self.LanguageList.AddItem (
        MLSDEApplication.SynManager.Highlighters[Ndx].Name,
        Nil
      )
  end;



(* User double click. *)
  procedure TLanguageSelectorDlg.LanguageListDblClick (Sender: TObject);
  var
    lList: TListBox absolute Sender;
  begin
    if lList.ItemIndex > -1 then Self.ModalResult := mrOK
  end;



  function TLanguageSelectorDlg.GetLanguage: String;
  begin
    Result := Self.LanguageList.Items[Self.LanguageList.ItemIndex]
  end;



(* Selects language. *)
  procedure TLanguageSelectorDlg.Select (aLanguage: String);
  var
    Ndx: Integer;
  begin
    aLanguage := LowerCase (aLanguage);
    for Ndx := 0 to Self.LanguageList.Count - 1 do
      if LowerCase (Self.LanguageList.Items[Ndx]) = aLanguage then
      begin
        Self.LanguageList.ItemIndex := Ndx;
        Exit
      end;
  { Not found. }
    Self.LanguageList.ItemIndex := 0
  end;

end.

