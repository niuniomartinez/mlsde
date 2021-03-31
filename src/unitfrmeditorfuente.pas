UNIT unitFrmEditorFuente;
(*<Define el editor de texto. *)
(*
  Copyright (c) 2018 Guillermo Martínez J.
  See file AUTHORS for a full list of authors.

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

{$mode objfpc}{$H+}

INTERFACE

USES
  AutocompletionUtils,
  Classes, Sysutils, Fileutil, SynEdit, SynCompletion, Forms, Controls,
  ActnList, ComCtrls, Menus, LCLType;

  TYPE

  (* Describe el editor de texto.

     @bold(Importante:)  Ojo, que hay dos elementos con nombres muy parecidos
     pero usos diferentes: @link(Autocompletar) y @link(Autocompletador).
   *)
  TFrmEditorFuente = CLASS (TFrame )
    AccionesEdicion: TActionList;
    ActEditGuardar: TAction;
    ActEditRecarga: TAction;
    ActCerrarLengueta: TAction;
    BarraEstado: TStatusBar;
    BarraHerramientas: TToolBar;
    EditorTexto: TSynEdit;
    MenuEdicion: TPopupMenu;
    BtnGuardar: TToolButton;
    BtnRecarga: TToolButton;
    MenuCerrarLengueta: TMenuItem;
    MnuEditRecargar: TMenuItem;
    MnuEditGuardar: TMenuItem;
    AutoCompletar: TSynCompletion;
    PROCEDURE ActEditExecute (Sender: TObject);
    PROCEDURE AutocompletarExecute (Sender: TObject);
    PROCEDURE AutocompletarSearchPosition (VAR aPosition: INTEGER);
    PROCEDURE EditorTextoChange (Sender: TObject);
  PRIVATE
    fRutaArchivo, fNombreArchivo: STRING;
    fAutocompletador: TAutocompletionWordList;

    FUNCTION TomaRutaCompleta: STRING; INLINE;
    FUNCTION TomaModificado: BOOLEAN; INLINE;
  (* Activa o desactiva opciones dependiendo del estado del archivo. *)
    PROCEDURE ActualizaEstados;
  (* Filtra las palabras del autocompletador dependiendo de lo que haya escrito
     el usuario. *)
    PROCEDURE FiltraPalabrasAutocompletado;
  PUBLIC
   (* Constructor. *)
    CONSTRUCTOR Create (TheOwner: TComponent); OVERRIDE;
   (* Destructor. *)
     DESTRUCTOR Destroy; OVERRIDE;
  (* Carga el archivo indicado.  También busca y activa el resaltador
    sintáctico adecuado, si lo encuentra, y rellena el autocompletador con las
    palabras que haya en el archivo. *)
    PROCEDURE CargaArchivo (CONST NombreArchivo: STRING);
  (* Guarda el archivo. *)
    PROCEDURE GuardaArchivo;
  (* Actualiza los controles según la configuración. *)
    PROCEDURE ActualzaConfiguracion;
  (* Recarga el archivo que está siendo editado. *)
    PROCEDURE RecargaArchivo;
  (* Cierra la lengüeta.

     Antes de hacerlo, comprueba si el archivo ha sido modificado y da la
     oportunidad de guardarlo si es así. *)
    PROCEDURE CierraLengueta;

  (* Nombre completo del archivo. *)
    PROPERTY RutaCompleta: STRING READ TomaRutaCompleta;
  (* Devuelve el estado del archivo. *)
    PROPERTY Modificado: BOOLEAN READ TomaModificado;
  (* Referencia del autocompletador a usar.  No es propietario del objeto. *)
    PROPERTY Autocompletador: TAutocompletionWordList
      READ fAutocompletador WRITE fAutocompletador;
  END;

IMPLEMENTATION

  USES
    Configuracion, UnitDatos, Utils,
    SynEditLines, { Ver "GuardaArchivo" }
    Dialogs;

{$R *.lfm}

  PROCEDURE TFrmEditorFuente.ActEditExecute (Sender: TObject);
  CONST
    Guardar = 1; Recargar = 2;
    Cerrarlengueta = 3;
  BEGIN
    CASE TComponent (Sender).Tag OF
    Guardar:
      SELF.GuardaArchivo;
    Recargar:
      SELF.RecargaArchivo;
    Cerrarlengueta:
      BEGIN
    { TODO: Esto está desactivado porque lanza una excepción tras el cierre al
      intentar acceder al SynEdit después de haberlo destruido.  Sólo sucede si
      el cierre se solicita desde el menú contextual, así que es posible que se
      trate de alguna limpieza realizada tras el evento.

      La excepción se lanza en SynEditPointClasses.pas:2145
    }
        EXIT;
      { Símplemente debería llamar al siguiente método. }
        SELF.CierraLengueta;
      END;
    END
  END;



  PROCEDURE TFrmEditorFuente.AutocompletarExecute (Sender: TObject);
  BEGIN
    SELF.FiltraPalabrasAutocompletado
  END;



  PROCEDURE TFrmEditorFuente.AutocompletarSearchPosition (VAR aPosition: INTEGER);
  BEGIN
    SELF.FiltraPalabrasAutocompletado;
    IF AutoCompletar.ItemList.Count > 0 THEN
      aPosition := 0
    ELSE
      aPosition := -1;
  END;



  PROCEDURE TFrmEditorFuente.EditorTextoChange (Sender: TObject);
  VAR
    cX, cY: INTEGER;
  BEGIN
    ActualizaEstados;
  { Si se ha introducido una tecla imprimible que no sea alfanumérica, analiza
    la línea actual para ver si introduce o no una palabra nueva al
    autocomplete. }
    cX := EditorTexto.CaretX - 1; cY := EditorTexto.CaretY - 1;
    IF (cX >= 0) AND (cY >= 0) AND (Length (EditorTexto.Lines[cY]) > 1)
    AND IsSeparator (EditorTexto.Lines[cY][cX])
    THEN
      fAutocompletador.Add (EditorTexto.Lines[cY])
  END;



  FUNCTION TFrmEditorFuente.TomaRutaCompleta: STRING;
  BEGIN
    RESULT := fRutaArchivo + fNombreArchivo;
  END;



  FUNCTION TFrmEditorFuente.TomaModificado: BOOLEAN;
  BEGIN
    RESULT := SELF.EditorTexto.Modified;
  END;



(* Activa o desactiva opciones dependiendo del estado del archivo. *)
  PROCEDURE TFrmEditorFuente.ActualizaEstados;
  BEGIN
    IF SELF.EditorTexto.Modified THEN
    BEGIN
      SELF.Parent.Caption := '*'+fNombreArchivo;
      SELF.BarraEstado.SimpleText := 'Modificado';

      ActEditGuardar.Enabled := TRUE;
    END
    ELSE BEGIN
      SELF.Parent.Caption := fNombreArchivo;
      SELF.BarraEstado.SimpleText := '';

      ActEditGuardar.Enabled := FALSE
    END;
  END;



(* Filtra las palabras del autocompletador. *)
  PROCEDURE TFrmEditorFuente.FiltraPalabrasAutocompletado;
  BEGIN
    AutoCompletar.ItemList.Clear;
    fAutocompletador.GetWordList (
      AutoCompletar.CurrentString, AutoCompletar.ItemList
    )
  END;



(* Constructor. *)
  CONSTRUCTOR TFrmEditorFuente.Create (TheOwner: TComponent);
  BEGIN
    INHERITED Create (TheOwner);
    ActualzaConfiguracion;
  { Quita el nombre para evitar el error "Nombre de componente duplicado". }
    SELF.Name := ''
  END;



(* Destructor. *)
  DESTRUCTOR TFrmEditorFuente.Destroy;
  BEGIN
    INHERITED Destroy
  END;



(* Carga el archivo indicado. *)
  PROCEDURE TFrmEditorFuente.CargaArchivo (CONST NombreArchivo: STRING);
  BEGIN
  { Busca el resaltador de sintáxis apropiado y lo asigna. }
    Self.EditorTexto.Highlighter := ModuloDatos.SintaxisDeExt (
      ExtractFileExt (NombreArchivo)
    );
    SELF.EditorTexto.Lines.LoadFromFile (NombreArchivo);
  { Analiza el archivo para rellenar el autocompletador. }
    IF SELF.EditorTexto.Lines.Count > 0 THEN
      fAutocompletador.Add (SELF.EditorTexto.Lines);
  { Pon propiedades. }
    fRutaArchivo := IncludeTrailingPathDelimiter(ExtractFileDir(NombreArchivo));
    fNombreArchivo := ExtractFileName (NombreArchivo);
    SELF.Parent.Name := EncodeName (TomaRutaCompleta);
    ActualizaEstados
  END;



(* Guarda el archivo. *)
  PROCEDURE TFrmEditorFuente.GuardaArchivo;
  VAR
    NombreArchivo, ArchivoDestino: STRING;
  BEGIN
    IF SELF.EditorTexto.Modified THEN
    BEGIN
      ArchivoDestino := TomaRutaCompleta;
    { Comprueba si debe hacer copia de seguridad. }
      IF Config.CopiaSeguridad THEN
      BEGIN
        NombreArchivo := TomaRutaCompleta + '.' + Config.ExtensionCopiaSeguridad;
        IF NOT FileExists (NombreArchivo) THEN
          CopyFile (ArchivoDestino, NombreArchivo, TRUE);
      END;
      NombreArchivo := ArchivoDestino + '~';
      IF FileExists (NombreArchivo) THEN DeleteFile (NombreArchivo);
      CopyFile (ArchivoDestino, NombreArchivo, TRUE);
    { Ahora sí, guarda el archivo. }
{
  La hipótesis es que, con la siguiente línea, cambie el estilo de fin de línea
  a UNIX, pero la verdad es que no tiene efecto alguno.

  SELF.EditorTexto.Lines.TextLineBreakStyle := tlbsLF;

  El problema está en que Lines es un TSynEditLines que sobreescribe SaveToFile.
  Usa su propia propiedad para saber qué separador de línea usar, pero está
  mal planteado (en mi opinión) ya que debería o bien usar esta propiedad, o
  bien añadir una propiedad nueva al TSynEdit para tal eventualidad.

  Así pues, nos obligan a usar el siguiente y feo código:
}
TSynEditLines (SELF.EditorTexto.Lines).FileWriteLineEndType := sfleLoaded;
SELF.EditorTexto.Lines.SaveToFile (TomaRutaCompleta);
{
  El código siguiente es una alternativa bastante elegante, pero el problema
  es que las líneas que deben marcarse en el "Gutter" no son las de la
  propiedad Lines.

Buffer := TStringList.Create;
Buffer.Text := SELF.EditorTexto.Lines.Text;
Buffer.TextLineBreakStyle := tlbsLF;
Buffer.SaveToFile (TomaRutaCompleta);
// Por desgracia, el Lines no es la propiedad TSynEditStringList...
TSynEditStringList (SELF.EditorTexto.Lines).MarkSaved;
SELF.EditorTexto.InvalidateGutter;
}
      SELF.EditorTexto.Modified := FALSE;
      ActualizaEstados;
    END;
  END;



(* Actualiza los controles según la configuración. *)
  PROCEDURE TFrmEditorFuente.ActualzaConfiguracion;
  BEGIN
    IF Config.MostrarBarraHerramientas THEN
      BarraHerramientas.Show
    ELSE
      BarraHerramientas.Hide;
    IF Config.MostrarBarraEstado THEN
      BarraEstado.Show
    ELSE
      BarraEstado.Hide;
  END;



(* Recarga el archivo que está siendo editado. *)
  PROCEDURE TFrmEditorFuente.RecargaArchivo;
  VAR
    Columna, Fila: INTEGER;
  BEGIN
    Columna := SELF.EditorTexto.CaretX;
    Fila := SELF.EditorTexto.CaretY;
    SELF.EditorTexto.Lines.LoadFromFile (TomaRutaCompleta);
    SELF.EditorTexto.Modified := FALSE;
    SELF.EditorTexto.CaretX := Columna;
    SELF.EditorTexto.CaretY := Fila;
    ActualizaEstados
  END;



(* Cierra la lengüeta. *)
  PROCEDURE TFrmEditorFuente.CierraLengueta;
  VAR
    Resultado: INTEGER;
  BEGIN
    IF SELF.Modificado THEN
    BEGIN
      Config.AntesDialogo;
      TRY
	Resultado := QuestionDlg (
	  'Cerrando pestaña',
	  'El archivo ha sido modificado y no se ha guardado.'#10'¿Realmente quiere cerrar la pestaña?',
	  mtConfirmation, [mrYes, mrNo], 0
	);
      FINALLY
	Config.DespuesDialogo
      END;
      IF Resultado = mrNo THEN EXIT
    END;
    TTabSheet (SELF.Parent).Free
  END;

END.

