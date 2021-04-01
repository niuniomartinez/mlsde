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
    Classes, Forms, SynEdit;

  type
  (* Source editor frame.  This is created in a tab in the @link(MainWindow). *)
    TSourceEditorFrame = class (TFrame)
      SynEdit: TSynEdit;
    private
      fFileName, fPath: String;
    public
    (* Constructor. *)
      constructor Create (aOwer: TComponent); OVERRIDE;
    (* Loads the given source file.

       It also searchs and sets-up the syntax highlighter and the autocomplete
       tool. *)
      procedure Load (aSourceFileName: String);
    (* Saves the sources to the file.

       Note it saves in the same file it was loaded. *)
    end;

implementation

  uses
    Utils,
    sysutils;

{$R *.lfm}

(*
 * TSourceEditorFrame
 ************************************************************************)

(* Constructor. *)
  constructor TSourceEditorFrame.Create (aOwer: TComponent);
  begin
    inherited Create (aOwer);
  { Remove name to avoid error "Duplicated component name". }
    Self.Name := ''
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
  { TODO: Syntax hightlighter and autocomplete stuff. }
  end;

end.

