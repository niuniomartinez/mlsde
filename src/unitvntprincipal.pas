UNIT unitVntPrincipal;
(*<Define la ventana principal del programa. *)

INTERFACE

USES
  AutocompletionUtils,
  UnitDatos, Project, Classes, Sysutils, Fileutil, Forms, unitFrmEditorFuente,
  Controls, Graphics, Dialogs, ComCtrls, ExtCtrls, Menus, ActnList;

TYPE
(* Ventana principal del programa.

  Muestra el árbol de directorios del proyecto y los archivos.
  Abre archivos en lengüetas.
 *)

  { TVntPrincipal }

  TVntPrincipal = CLASS (TForm)
    AccionesProyecto: TActionList;
    AcPryAbrir: TAction;
    AcPryNuevoDir: TAction;
    AcPryRenombrar: TAction;
    AcPryNuevoArchivo: TAction;
    AcPryEliminar: TAction;
    AccionesPrograma: Tactionlist;
    AcPrgConfigurar: TAction;
    AcPrgSalir: TAction;
    AcPryActualiza: TAction;
    AcPrgGuardarArchivo: TAction;
    AcPrgCierraArchivo: Taction;
    ActPryCerrarTodosArchivos: Taction;
    ImagenesProyecto: TImageList;
    MnuPrpPryCerrarTodo: Tmenuitem;
    MnuPrpArchCerrar: Tmenuitem;
    MnuPrpArchGuardar: TMenuItem;
    MenuPrpArchivo: TMenuItem;
    MnuPrpPryAbrir: TMenuItem;
    MnuPrpProyecto: TMenuItem;
    MnuPryActualiza: TMenuItem;
    MnuPrgAcercaDe: TMenuItem;
    MenuPrincipal: TMainMenu;
    MnuPrgPrograma: TMenuItem;
    MnuPrgConfigurar: TMenuItem;
    Mnuprgseparador1: TMenuItem;
    Mnuprgsalir: TMenuItem;
    MenuProyecto: TPopupMenu;
    MnuPryAbrir: TMenuItem;
    MnuPrySeparador1: TMenuItem;
    MnuPryNuevoDir: TMenuItem;
    MnuPryNuevoArchivo: TMenuItem;
    MnuPrySeparador2: TMenuItem;
    MnuPryCambiarNombre: TMenuItem;
    MnuPryEliminar: TMenuItem;
    VistaProyecto: TTreeView;
    Separador: TSplitter;
    Editores: TPageControl;
    PROCEDURE AcProgramaExecute (Sender: TObject);
    PROCEDURE AcProyectoExecute (Sender: TObject);
    PROCEDURE AcercaDe (Sender: TObject);
    PROCEDURE EditoresCloseTabClicked (Sender: TObject);
    PROCEDURE FormActivate (Sender: TObject);
    PROCEDURE FormClose (Sender: TObject; VAR Closeaction: TCloseAction);
    PROCEDURE FormCreate (Sender: TObject);
    PROCEDURE FormDeactivate (Sender: TObject);
    PROCEDURE FormDestroy (Sender: TObject);
    PROCEDURE FormKeydown (Sender: TObject; VAR Key: Word; Shift: TShiftState);
    PROCEDURE VistaProyectoClick (Sender: TObject);
  PRIVATE
  (* Algunas acciones de la inicialización pueden resultar en errores internos
     si se realizan en FormCreate.  Por eso se realizan en FormActivate usando
     este indicador para saber si se trata de la inicialización o no. *)
    fInicializando: BOOLEAN;
  (* El proyecto completo. *)
    fProyecto: TProject;
  (* Base de datos del autocompletador. *)
    fAutocompletador: TAutocompletionWordList;

  (* Crea una nueva lengüeta de edición. *)
    FUNCTION CreaLenguetaEdicion: TTabSheet;
  (* Muestra las excepciones del sistema.  Es el último recurso. *)
    PROCEDURE onException (Sender: TObject; E: Exception);
  (* Dado el archivo indicado, lo carga si no lo está y pone su lengüeta en
     primer plano. *)
    PROCEDURE AbreArchivo (CONST NombreArchivo: STRING);
  (* Función para determinar el orden de los nodos de la vista del proyecto. *)
    FUNCTION OrdenNodosArbol (Nodo1, Nodo2: TTreeNode): INTEGER;
  (* Comprueba si puede cerrar, preguntando incluso al usuario. *)
    FUNCTION PuedeCerrar: BOOLEAN;
  (* Actualiza elementos cuando el proyecto cambia. *)
    PROCEDURE onProyectoCambia (Sender: TObject);
  (* Acciones a realizar cuando cambia la configuración. *)
    PROCEDURE ActualizaConfiguracion; INLINE;
  (* Devuelve el "editor" de la lengüeta indicada. *)
    FUNCTION TomaEditor (CONST Lengueta: TTabSheet): TFrmEditorFuente;
  (* Cierra todas las lengüetas.  No hace preguntas. *)
    PROCEDURE CierraTodasLasLenguetas;
  PUBLIC
  (* Constructor. *)
    CONSTRUCTOR Create (TheOwner: TComponent); OVERRIDE;
  (* Destructor. *)
    DESTRUCTOR Destroy; OVERRIDE;
  END;

VAR
  VntPrincipal: TVntPrincipal;

IMPLEMENTATION

  USES
    mlsdeScripting,
    Configuracion, UnitDlgAbout, unitDlgConfiguracion, Utils,
    LCLType;

{$R *.lfm}

  RESOURCESTRING
  (* Para construir el título de la ventana. *)
    TITULO_VENTANA = '%s (%s) - edit';
  CONST
  (* Índice al icono "carpeta". *)
    ICN_CARPETA = 0;
  (* Índice al icono "carpeta abierta". *)
    ICN_CARPETA_ABIERTA = 0;
  (* Índice al icono "archivo de texto". *)
    ICN_ARCHIVO_TXT = 1;

{ TVntPrincipal }
  PROCEDURE TVntPrincipal.AcProgramaExecute (Sender: TObject);
  CONST
    OP_CONFIG = 1;
    OP_CERRAR = 2;
    OP_GUARDA_ARCHIVO = 3;
    OP_GUARDA_TODOS_ARCHIVOS = 4;
    OP_CIERRA_ARCHIVO = 5;
  BEGIN
    CASE TComponent (Sender).Tag OF
    OP_CERRAR:
      SELF.Close;
    OP_CONFIG:
      BEGIN
        DlgConfiguracion := TDlgConfiguracion.Create (SELF);
        TRY
          IF DlgConfiguracion.ShowModal = mrOK THEN ActualizaConfiguracion
        FINALLY
          FreeAndNil (DlgConfiguracion)
        END
      END;
    OP_GUARDA_ARCHIVO:
      IF Editores.PageCount > 0 THEN
        SELF.TomaEditor (Editores.ActivePage).GuardaArchivo;
    OP_CIERRA_ARCHIVO:
      IF Editores.PageCount > 0 THEN
        SELF.TomaEditor (Editores.ActivePage).CierraLengueta;
    END;
  END;



  PROCEDURE TVntPrincipal.AcProyectoExecute (Sender: TObject);
  CONST
    OPC_ABRIR = 1;
    OPC_ACTUALIZA = 6;
    OPC_NUEVO_DIR = 2;
    OPC_NUEVO_ARC = 3;
    OPC_RENOMBRAR = 4;
    OPC_ELIMINAR = 5;
    OPC_CIERRA_TODOS_ARCHIVOS = 7;
  VAR
    Directorio: TDirectorio;
    Nombre: STRING;
    Aceptado: BOOLEAN;
    Archivo: FILE;
    InformacionArchivo: TArchivo; InformacionDirectorio: TDirectorio;

    PROCEDURE ObtieneDirectorioSeleccionado;
    BEGIN
      IF (VistaProyecto.Selected <> NIL)
      AND (VistaProyecto.Selected.Data <> NIL)
      AND (TObject (VistaProyecto.Selected.Data) IS TDirectorio) THEN
        Directorio := TDirectorio (VistaProyecto.Selected.Data)
      ELSE
        RAISE Exception.Create ('Debe seleccionar un directorio.')
    END;

    PROCEDURE AbrirProyecto;
    VAR
      Resultado: INTEGER;
    BEGIN
    { Comprueba si se pueden cerrar las lengüetas abiertas. }
      IF NOT SELF.PuedeCerrar THEN
      BEGIN
        Config.AntesDialogo;
        TRY
          Resultado := QuestionDlg (
            'Abriendo proyecto',
            'Hay archivos modificados sin guardar.'#10'¿Realmente quiere continuar?',
            mtConfirmation, [mrYes, mrNo], 0
          );
          IF Resultado = mrNo THEN EXIT
        FINALLY
          Config.DespuesDialogo
        END
      END;
      SELF.CierraTodasLasLenguetas;
      fAutocompletador.Clear;
    { Ahora, abre el proyecto solicitado. }
      IF ModuloDatos.DlgSeleccionarDirectorio.Execute THEN
        fProyecto.Escanea (ModuloDatos.DlgSeleccionarDirectorio.FileName)
    END;

    PROCEDURE NuevoDirectorio;
    BEGIN
      ObtieneDirectorioSeleccionado;
      Aceptado := InputQuery (
	'Nombre del nuevo directorio',
	'Introduzca el nombre del nuevo directorio',
	Nombre
      );
      IF Aceptado THEN
      BEGIN
	Nombre := Directorio.Ruta + Nombre;
{$I-}
	MkDir (Nombre);
{$I+}
	IF IOResult <> 0 THEN
	  RAISE Exception.CreateFmt ('No pudo crearse el directorio "%s".',
	    [Nombre]);
	fProyecto.Escanea
      END
    END;

    PROCEDURE NuevoArchivo;
    BEGIN
      ObtieneDirectorioSeleccionado;
      Aceptado := InputQuery (
        'Nombre del nuevo archivo',
        'Introduzca el nombre del nuevo archivo',
        Nombre
      );
      IF Aceptado THEN
      BEGIN
        Nombre := Directorio.Ruta + Nombre;
{$I-}
        system.Assign (Archivo, Nombre);
        system.Rewrite (Archivo);
        system.Close (Archivo);
{$I-}
        IF IOResult <> 0 THEN
          RAISE Exception.CreateFmt ('No pudo crearse el Archivo "%s".',
            [ExtractFileName (Nombre)]);
        fProyecto.Escanea;
        SELF.AbreArchivo (Nombre)
      END
    END;

    PROCEDURE Renombrar;
    BEGIN
      IF (VistaProyecto.Selected <> NIL)
      AND (VistaProyecto.Selected.Data <> NIL) THEN
      BEGIN
	IF TObject (VistaProyecto.Selected.Data) IS TArchivo THEN
	BEGIN
	  InformacionArchivo := TArchivo (VistaProyecto.Selected.Data);
	  IF InformacionArchivo <> NIL THEN
	  BEGIN
	    Nombre := InformacionArchivo.Nombre;
	    Aceptado := InputQuery (
		'Nuevo nombre del archivo',
		'Introduzca el nuevo nombre del archivo',
	        Nombre
	    );
	    IF Aceptado AND (Nombre <> InformacionArchivo.Nombre) THEN
	    BEGIN
              IF NOT RenameFile (
		InformacionArchivo.Ruta + InformacionArchivo.Nombre,
		InformacionArchivo.Ruta + Nombre)
	      THEN
		ShowErrorMessage ('No pudo cambarse el nombre del archivo.')
	      ELSE
		fProyecto.Escanea
	    END
	  END
	END
	ELSE
	  ShowErrorMessage ('Por ahora no puede cambiarse el nombre de los directorios.')
      END
    END;

    PROCEDURE Eliminar;
    BEGIN
      IF (VistaProyecto.Selected <> NIL)
      AND (VistaProyecto.Selected.Data <> NIL) THEN
      BEGIN
	IF TObject (VistaProyecto.Selected.Data) IS TArchivo THEN
	BEGIN
	  InformacionArchivo := TArchivo (VistaProyecto.Selected.Data);
	  IF InformacionArchivo <> NIL THEN
	  BEGIN
	    Aceptado  := QuestionDlg (
		'Borrar archivo',
		'¿Realmente quiere eliminar el archivo?',
	        mtConfirmation, [mrYes, mrNo], 0
	    ) = mrYes;
	    IF Aceptado THEN
	    BEGIN
	      IF NOT DeleteFile (
		InformacionArchivo.Ruta + InformacionArchivo.Nombre)
	      THEN
		ShowErrorMessage ('No pudo eliminarse el archivo.')
	      ELSE
		fProyecto.Escanea
	    END
	  END
	END
	ELSE BEGIN
	  InformacionDirectorio := TDirectorio (VistaProyecto.Selected.Data);
	  IF InformacionDirectorio <> NIL THEN
	  BEGIN
	    Nombre := InformacionDirectorio.Nombre;
	    Aceptado  := QuestionDlg (
	      'Borrar archivo',
	      '¿Realmente quiere eliminar el directorio?  Tenga en cuenta que también se eliminarán TODOS los archivos y subdirectorios que contenga.',
	      mtConfirmation, [mrYes, mrNo], 0
	    ) = mrYes;
	    IF Aceptado THEN
	    BEGIN
	      IF NOT DeleteDirectory (
		InformacionDirectorio.Ruta + InformacionDirectorio.Nombre,
		FALSE)
	      THEN
		ShowErrorMessage ('No pudo eliminarse el directorio.');
	    { Reanaliza por si hubo un borrado parcial. }
	      fProyecto.Escanea
	    END
	  END
	END
      END
    END;

    PROCEDURE CierraLenguetas;
    VAR
      Resultado: INTEGER;
    BEGIN
    { Comprueba si se pueden cerrar las lengüetas abiertas. }
      IF NOT SELF.PuedeCerrar THEN
      BEGIN
        Config.AntesDialogo;
        TRY
          Resultado := QuestionDlg (
            'Abriendo proyecto',
            'Hay archivos modificados sin guardar.'#10'¿Realmente quiere continuar?',
            mtConfirmation, [mrYes, mrNo], 0
          );
          IF Resultado = mrNo THEN EXIT
        FINALLY
          Config.DespuesDialogo
        END
      END;
      SELF.CierraTodasLasLenguetas
    END;

  BEGIN
    Nombre := ''; { Evitar un aviso. }
    Config.AntesDialogo;
    TRY
      CASE TComponent (Sender).Tag OF
        OPC_ABRIR:     AbrirProyecto;
        OPC_NUEVO_DIR: NuevoDirectorio;
        OPC_NUEVO_ARC: NuevoArchivo;
        OPC_RENOMBRAR: Renombrar;
        OPC_ELIMINAR:  Eliminar;
        OPC_ACTUALIZA: fProyecto.Escanea;
        OPC_CIERRA_TODOS_ARCHIVOS: CierraLenguetas;
      END
    FINALLY
      Config.DespuesDialogo
    END
  END;



  PROCEDURE TVntPrincipal.AcercaDe (Sender: Tobject );
  BEGIN
    TRY
      Config.AntesDialogo;
      DlgAbout := TDlgAbout.Create (SELF);
      DlgAbout.ShowModal
    FINALLY
      FreeAndNil (DlgAbout);
      Config.DespuesDialogo
    END
  END;



  PROCEDURE TVntPrincipal.EditoresCloseTabClicked (Sender: TObject);
  BEGIN
    IF Sender IS TTabSheet THEN
      SELF.TomaEditor (TTabSheet (Sender)).CierraLengueta
  END;



  PROCEDURE TVntPrincipal.FormActivate (Sender: TObject);
  VAR
    Cnt: INTEGER;
  BEGIN
    IF fInicializando THEN
    BEGIN
    { Primeros ajustes. }
      ActualizaConfiguracion;
      SELF.onProyectoCambia (fProyecto);
      fInicializando := FALSE;
    { Comprueba si se indicó la carga de algún archivo o directorio. }
      IF Paramcount > 0 THEN
      BEGIN
        IF Paramcount = 1 THEN
        BEGIN
        { El orden es imporante, ya que en Linux  (¿o tal vez en POSIX?) los
          directorios son considerados un tipo de archivo especial. }
          IF DirectoryExists (ParamStr (1)) THEN
            fProyecto.Escanea (ParamStr (1))
          ELSE IF FileExists (ParamStr (1)) THEN
          BEGIN
            fProyecto.Escanea (ExtractFilePath (ParamStr (1)));
            SELF.AbreArchivo (ParamStr (1))
          END
          ELSE
            ShowErrorMessage ('No pudo abrirse el archivo o directorio solicitado.')
        END
        ELSE FOR Cnt := 1 TO Paramcount DO
          IF FileExists (ParamStr (Cnt))
          AND NOT DirectoryExists (ParamStr (Cnt))
          THEN BEGIN
            SELF.AbreArchivo (ParamStr (Cnt))
          END
      END
    END
  END;



  PROCEDURE TVntPrincipal.FormClose (Sender: TObject; VAR Closeaction: TCloseAction);
  VAR
    Resultado: INTEGER;
  BEGIN
    IF NOT PuedeCerrar THEN
    BEGIN TRY
      Config.AntesDialogo;
      Resultado := QuestionDlg (
        'Cerrando la aplicación',
        'Hay archivos modificados sin guardar.'#10'¿Realmente quiere salir?',
        mtConfirmation, [mrYes, mrNo], 0
      );
      IF Resultado = mrNo THEN Closeaction := caNone
    FINALLY
      Config.DespuesDialogo
    END END
  END;



  PROCEDURE TVntPrincipal.FormCreate (Sender: TObject);
  BEGIN
    Application.OnException := @SELF.onException;
    fInicializando := TRUE;
    fProyecto := TProject.Create;
    fProyecto.onChange := @SELF.onProyectoCambia;
    SELF.KeyPreview := TRUE;
    Application.OnDeactivate := @FormDeactivate;
  { Scripting system. }
    Scripts.Initialize
  END;



  PROCEDURE TVntPrincipal.FormDeactivate (Sender: TObject);
  VAR
    Ndx: INTEGER;
  BEGIN
    IF Config.GuardarAlPerderFoco THEN
      FOR Ndx := Editores.PageCount - 1 DOWNTO 0 DO
	SELF.TomaEditor (Editores.Pages[Ndx]).GuardaArchivo
  END;



  PROCEDURE TVntPrincipal.FormDestroy (Sender: TObject);
  BEGIN
    FreeAndNil (fProyecto);
  END;



  PROCEDURE TVntPrincipal.FormKeydown (Sender: TObject; VAR Key: Word;
    Shift: TShiftState);
  BEGIN
  { Ignore shift keys. }
    IF Key IN VK_SHIFT_KEYS THEN EXIT;
  { Show what key was pressed.

    This was for testing purposes.  Will be removed once the scripting system
    is up and running.

    ShowMessage ('The key trigger is "'+BuildKeyId (Shift, Key) + '"');
    Exit;
  }
    IF Key = VK_F10 THEN
    BEGIN
      Key := 0;
      IF MenuPrincipal.Parent <> SELF THEN
      BEGIN
        MenuPrincipal.Parent := SELF;
        MenuPrincipal.HandleNeeded
      END
      ELSE
        MenuPrincipal.Parent := NIL
    END
  END;



  PROCEDURE TVntPrincipal.VistaProyectoClick (Sender: TObject);
  VAR
    InformacionArchivo: TArchivo;
    InformacionDirectorio: TDirectorio;
  BEGIN
    IF (VistaProyecto.Selected <> NIL)
    AND (VistaProyecto.Selected.Data <> NIL) THEN
    BEGIN
      IF TObject (VistaProyecto.Selected.Data) IS TArchivo THEN
      BEGIN
	InformacionArchivo := TArchivo (VistaProyecto.Selected.Data);
	SELF.AbreArchivo (InformacionArchivo.Ruta + InformacionArchivo.Nombre)
      END
      ELSE BEGIN
	InformacionDirectorio := TDirectorio (VistaProyecto.Selected.Data);
	fProyecto.Escanea (InformacionDirectorio.Ruta)
      END
    END
  END;



(* Crea una nueva lengüeta de edición. *)
  FUNCTION TVntPrincipal.CreaLenguetaEdicion: TTabSheet;
  VAR
    Editor: TFrmEditorFuente;
  BEGIN
    RESULT := Editores.AddTabSheet;
    Editor := TFrmEditorFuente.Create (RESULT);
    Editor.Autocompletador := SELF.fAutocompletador;
    Editor.Align := alClient;
    Editor.Parent := RESULT;
    Editores.ActivePage := RESULT
  END;



(* Muestra las excepciones del sistema.  Es el último recurso. *)
  PROCEDURE TVntPrincipal.onException (Sender: TObject; E: Exception);
  BEGIN
    Config.AntesDialogo;
    ShowErrorMessage (E.Message);
    Config.DespuesDialogo
  END;



(* Dado el archivo indicado, lo carga si no lo está y pone su lengüeta en
   primer plano. *)
  PROCEDURE TVntPrincipal.AbreArchivo (CONST NombreArchivo: STRING);
  VAR
    NombreUnico: STRING;
    Ndx: INTEGER;
    Lengueta: TTabSheet = NIL;
  BEGIN
  { Comprueba si ya está abierto. }
    NombreUnico := EncodeName (NombreArchivo);
    IF Editores.PageCount > 0 THEN
      FOR Ndx := 0 TO Editores.PageCount - 1 DO
        IF Editores.Pages[Ndx].Name = NombreUnico THEN
        BEGIN
          Lengueta := Editores.Pages[Ndx];
        { Poner la lengüeta en primer plano. }
          Editores.ActivePageIndex := Ndx
        END;
    IF Lengueta = NIL THEN
    BEGIN
    { No está abierto, así que lo abre. }
      Lengueta := CreaLenguetaEdicion;
      TomaEditor (Lengueta).CargaArchivo (NombreArchivo)
    END;
    TomaEditor (Lengueta).EditorTexto.SetFocus
  END;



(* Función para determinar el orden de los nodos de la vista del proyecto. *)
  FUNCTION TVntPrincipal.OrdenNodosArbol (Nodo1, Nodo2: TTreeNode): INTEGER;

    FUNCTION EsArchivo (CONST Nodo: TTreeNode): BOOLEAN; INLINE;
    BEGIN
      RESULT := TObject (Nodo.Data) IS TArchivo
    END;


    FUNCTION EsDirectorio (CONST Nodo: TTreeNode): BOOLEAN; INLINE;
    BEGIN
      RESULT := TObject (Nodo.Data) IS TDirectorio
    END;

  BEGIN
  { Directorios antes que archivos. }
    IF EsDirectorio (Nodo1) AND EsArchivo (Nodo2) THEN EXIT (-1);
    IF EsArchivo (Nodo1) AND EsDirectorio (Nodo2) THEN EXIT ( 1);
    RESULT := AnsiStrIComp (PChar (Nodo1.Text), PChar (Nodo2.Text))
  END;



(* Comprobar si puede cerrar. *)
  FUNCTION TVntPrincipal.PuedeCerrar: BOOLEAN;
  VAR
    Ndx: INTEGER;
  BEGIN
    FOR Ndx := Editores.PageCount - 1 DOWNTO 0 DO
      IF SELF.TomaEditor (Editores.Pages[Ndx]).Modificado THEN
	EXIT (FALSE);
    RESULT := TRUE
  END;



(* Actualiza elementos cuando el proyecto cambia. *)
  PROCEDURE TVntPrincipal.onProyectoCambia (Sender: TObject);

    PROCEDURE AnnadeSubdirectorios (aNodo: TTreeNode; aDirectorio: TDirectorio);
    VAR
      Ndx: INTEGER;
      Nodo: TTreeNode;
    BEGIN
      aNodo.Expanded := FALSE;
      aNodo.ImageIndex := ICN_CARPETA;
      aNodo.SelectedIndex := ICN_CARPETA_ABIERTA;
      IF aDirectorio.NumSubdirectorios > 0 THEN
        FOR Ndx := 1 TO aDirectorio.NumSubdirectorios DO
        BEGIN
          Nodo := VistaProyecto.Items.AddChild (
            aNodo,
            aDirectorio.Subdirectorios[Ndx].Nombre
          );
          Nodo.Data := aDirectorio.Subdirectorios[Ndx];
          AnnadeSubdirectorios (Nodo, aDirectorio.Subdirectorios[Ndx])
        END;
      IF aDirectorio.NumArchivos > 0 THEN
        FOR Ndx := 1 TO aDirectorio.NumArchivos DO
        BEGIN
          Nodo := VistaProyecto.Items.AddChild (
            aNodo,
            aDirectorio.Archivos[Ndx].Nombre
          );
          Nodo.Data := aDirectorio.Archivos[Ndx];
          Nodo.ImageIndex := ICN_ARCHIVO_TXT;
          Nodo.SelectedIndex := ICN_ARCHIVO_TXT
        END
    END;

  VAR
    NodoRaiz: TTreeNode;
  BEGIN
    IF VistaProyecto.Items.Count <> 0 THEN
      VistaProyecto.Items.Clear;
    IF fProyecto.Raiz <> NIL THEN
    BEGIN
      NodoRaiz:= VistaProyecto.Items.AddFirst (NIL, fProyecto.Raiz.Nombre);
      NodoRaiz.Data := fProyecto.Raiz;
      AnnadeSubdirectorios (NodoRaiz, fProyecto.Raiz);
      NodoRaiz.Expanded := TRUE;
      Caption := Format (TITULO_VENTANA, [
	fProyecto.Raiz.Nombre,
	ExcludeTrailingPathDelimiter (fProyecto.RutaBase)
      ]);
      VistaProyecto.CustomSort (@SELF.OrdenNodosArbol)
    END
  END;



(* Actualiza la configuración. *)
  PROCEDURE TVntPrincipal.ActualizaConfiguracion;
  VAR
    Ndx: INTEGER;
  BEGIN
    IF Config.MostrarMenuPpal THEN
    BEGIN
      IF MenuPrincipal.Parent = NIL THEN
      BEGIN
        MenuPrincipal.Parent := SELF;
        MenuPrincipal.HandleNeeded
      END
    END
    ELSE
      MenuPrincipal.Parent := NIL;

    FOR Ndx := Editores.PageCount - 1 DOWNTO 0 DO
      SELF.TomaEditor (Editores.Pages[Ndx]).ActualzaConfiguracion
  END;



(* Devuelve el "editor" de la lengüeta indicada. *)
  FUNCTION TVntPrincipal.TomaEditor (CONST Lengueta: TTabSheet): TFrmEditorFuente;
  VAR
    Ndx: INTEGER;
  BEGIN
    FOR Ndx := Lengueta.ComponentCount - 1 DOWNTO 0 DO
      IF Lengueta.Components[Ndx] IS TFrmEditorFuente THEN
	EXIT (TFrmEditorFuente (Lengueta.Components[Ndx]));
    RAISE Exception.Create ('No encontró el editor de la lengüeta.')
  END;



{ Cierra las lengüetas. }
  PROCEDURE TVntPrincipal.CierraTodasLasLenguetas;
  VAR
    Ndx: INTEGER;
  BEGIN
    FOR Ndx := Editores.PageCount - 1 DOWNTO 0 DO Editores.Pages[Ndx].Free;
  END;



(* Constructor. *)
  CONSTRUCTOR TVntPrincipal.Create (TheOwner: TComponent);
  BEGIN
    INHERITED Create (TheOwner);
    fAutocompletador := TAutocompletionWordList.Create
  END;



(* Destructor. *)
  DESTRUCTOR TVntPrincipal.Destroy;
  BEGIN
    fAutocompletador.Free;
    INHERITED Destroy
  END;

END.

