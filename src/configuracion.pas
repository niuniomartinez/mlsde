UNIT Configuracion;
(*<Contiene y gestiona la configuración. *)

INTERFACE

  TYPE
  (* Encapsula la configuración. *)
    TConfiguracion = CLASS (TObject)
    PRIVATE
    (* Para ser usado por AntesDialogo y DespuesDialogo. *)
      fCfgAutoGuardar: BOOLEAN;
      fNiveldialogo: INTEGER;

      FUNCTION TomaMostrarMenuPpal: BOOLEAN; INLINE;
      PROCEDURE PonMostrarMenuPpal (CONST Valor: BOOLEAN); INLINE;
      FUNCTION TomaMostrarBarraHerramientas: BOOLEAN; INLINE;
      PROCEDURE PonMostrarBarraHerramientas (CONST Valor: BOOLEAN); INLINE;
      FUNCTION TomaMostrarBarraEstado: BOOLEAN; INLINE;
      PROCEDURE PonMostrarBarraEstado (CONST Valor: BOOLEAN); INLINE;

      FUNCTION TomaIncluyeDirsOcultos: BOOLEAN; INLINE;
      PROCEDURE PonIncluyeDirsOcultos (CONST Valor: BOOLEAN); INLINE;
      FUNCTION TomaNivelProfundidadDirs: INTEGER; INLINE;
      PROCEDURE PonNivelProfundidadDirs (CONST Valor: INTEGER); INLINE;
      FUNCTION TomaIncluyeArchivosOcultos: BOOLEAN; INLINE;
      PROCEDURE PonIncluyeArchivosOcultos (CONST Valor: BOOLEAN); INLINE;
      FUNCTION TomaIncluyeSoloArchivosFuente: BOOLEAN; INLINE;
      PROCEDURE PonIncluyeSoloArchivosFuente (CONST Valor: BOOLEAN); INLINE;

      FUNCTION TomaGuardarAlPerderFoco: BOOLEAN; INLINE;
      PROCEDURE PonGuardarAlPerderFoco (CONST Valor: BOOLEAN); INLINE;
      FUNCTION TomaCopiaSeguridad: BOOLEAN; INLINE;
      PROCEDURE PonCopiaSeguridad (CONST Valor: BOOLEAN); INLINE;
      FUNCTION TomaExtCopiaSeguridad: STRING; INLINE;
      PROCEDURE PonExtCopiaSeguridad (CONST Valor: STRING); INLINE;

      FUNCTION TomaNumSintaxis: INTEGER; INLINE;
      FUNCTION TomaNombreSintaxis (CONST Ndx: INTEGER): STRING; INLINE;
      FUNCTION TomaExtSintaxis (CONST Ndx: INTEGER): STRING; INLINE;
      PROCEDURE PonExtSintaxis (CONST Ndx: INTEGER; aExtensiones: STRING); INLINE;
    PUBLIC
    (* Carga la configuración. *)
      CONSTRUCTOR Create;
    (* Destructor. *)
      DESTRUCTOR Destroy; OVERRIDE;
    (* Guarda la configuración en disco. *)
      PROCEDURE Guardar;

    (* Si se abre un diálogo, la ventana principal pierde foco y puede
       desencadenar que el archivo se guarde cuando esto no es lo apropiado,
       por ejemplo si se está preguntando si realmente quiere cerrarse el
       archivo sin gardar las modificacions.

       Este método evita que suceda esto, pero debe llamarse a
       @link(DespuesDialogo) al terminar para restaurar el estado. *)
      PROCEDURE AntesDialogo;
    (* Procedimiento opuesto a @link(AntesDialogo). *)
      PROCEDURE DespuesDialogo;

    (* ¿Mostrar el menú principal. *)
      PROPERTY MostrarMenuPpal: BOOLEAN
        READ TomaMostrarMenuPpal WRITE PonMostrarMenuPpal;
    (* ¿Mostrar el menú principal. *)
      PROPERTY MostrarBarraHerramientas: BOOLEAN
        READ TomaMostrarBarraHerramientas WRITE PonMostrarBarraHerramientas;
    (* ¿Mostrar el menú principal. *)
      PROPERTY MostrarBarraEstado: BOOLEAN
        READ TomaMostrarBarraEstado WRITE PonMostrarBarraEstado;

    (* ¿Incluir directorios ocultos en el proyecto? *)
      PROPERTY InluyeDirsOcultos: BOOLEAN
        READ TomaIncluyeDirsOcultos WRITE PonIncluyeDirsOcultos;
    (* Nivel de profundidad de directorios a analizar. *)
      PROPERTY NivelProfundidadDirs: INTEGER
        READ TomaNivelProfundidadDirs WRITE PonNivelProfundidadDirs;
    (* ¿Incluir archivos ocultos en el proyecto? *)
      PROPERTY InluyeArchivosOcultos: BOOLEAN
        READ TomaIncluyeArchivosOcultos WRITE PonIncluyeArchivosOcultos;
    (* ¿Incluir únicamente archivos identificados como texto o archivo fuente
       en el proyecto? *)
      PROPERTY InluyeSoloArchivosFuente: BOOLEAN
        READ TomaIncluyeSoloArchivosFuente
        WRITE PonIncluyeSoloArchivosFuente;

    (* Indica si guardar los archivos automáticamente cuando el programa pierda
      el foco. *)
      PROPERTY GuardarAlPerderFoco: BOOLEAN
        READ TomaGuardarAlPerderFoco WRITE PonGuardarAlPerderFoco;
    (* Indica si hacer una copia de seguridad cada vez que se guarde. *)
      PROPERTY CopiaSeguridad: BOOLEAN
        READ TomaCopiaSeguridad WRITE PonCopiaSeguridad;
    (* Indica la extensión de la copia de seguridad. *)
      PROPERTY ExtensionCopiaSeguridad: STRING
        READ TomaExtCopiaSeguridad WRITE PonExtCopiaSeguridad;
    (* Número de sintáxis reconocidas, incluyendo "texto plano". *)
      PROPERTY NumSintaxis: INTEGER
        READ TomaNumSintaxis; { Por ahora no se puede modificar. }
    (* Devuelve el nombre de la sintaxis a partir de su nombre. *)
      PROPERTY NombreSintaxis[Ndx: INTEGER]: STRING
        READ TomaNombreSintaxis; { Por ahora, no se puede modificar. }
    (* Devuelve las extensiones de la sintaxis. *)
      PROPERTY ExtensionesSintaxis[Ndx: INTEGER]: STRING
        READ TomaExtSintaxis WRITE PonExtSintaxis;
    END;

  VAR
  (* La configuración propiamente dicha.  Se crea y se destruye en las
    secciones INITIALIZATION y FINALIZATION respectivamente. *)
    Config: TConfiguracion;

IMPLEMENTATION

  USES
    UnitDatos,
    IniFiles, sysutils;

  VAR
    fArchivoIni: TIniFile;

(*
 * TConfiguracion
 ****************************************************************************)

  FUNCTION TConfiguracion.TomaMostrarMenuPpal: BOOLEAN;
  BEGIN
    RESULT := fArchivoIni.ReadBool ('gui', 'show_main_menu', TRUE);
  END;



  PROCEDURE TConfiguracion.PonMostrarMenuPpal (CONST Valor: BOOLEAN);
  BEGIN
    fArchivoIni.WriteBool ('gui', 'show_main_menu', Valor);
  END;



  FUNCTION TConfiguracion.TomaMostrarBarraHerramientas: BOOLEAN;
  BEGIN
    RESULT := fArchivoIni.ReadBool ('gui', 'show_tool_bar', TRUE);
  END;



  PROCEDURE TConfiguracion.PonMostrarBarraHerramientas (CONST Valor: BOOLEAN);
  BEGIN
    fArchivoIni.WriteBool ('gui', 'show_tool_bar', Valor);
  END;



  FUNCTION TConfiguracion.TomaMostrarBarraEstado: BOOLEAN;
  BEGIN
    RESULT := fArchivoIni.ReadBool ('gui', 'show_status_bar', TRUE);
  END;



  PROCEDURE TConfiguracion.PonMostrarBarraEstado (CONST Valor: BOOLEAN);
  BEGIN
    fArchivoIni.WriteBool ('gui', 'show_status_bar', Valor);
  END;



  FUNCTION TConfiguracion.TomaIncluyeDirsOcultos: BOOLEAN;
  BEGIN
    RESULT := fArchivoIni.ReadBool ('project', 'hidden_dirs', FALSE);
  END;



  PROCEDURE TConfiguracion.PonIncluyeDirsOcultos (CONST Valor: BOOLEAN);
  BEGIN
    fArchivoIni.WriteBool ('project', 'hidden_dirs', Valor);
  END;



  FUNCTION TConfiguracion.TomaNivelProfundidadDirs: INTEGER;
  BEGIN
    RESULT := fArchivoIni.ReadInteger ('project', 'dir_levels', 5);
  END;



  PROCEDURE TConfiguracion.PonNivelProfundidadDirs (CONST Valor: INTEGER);
  BEGIN
    IF (1 > Valor) OR (Valor > 32) THEN
      RAISE Exception.Create ('La profundidad de directorio debe estar entre 1 y 32.');
    fArchivoIni.WriteInteger ('project', 'dir_levels', Valor);
  END;



  FUNCTION TConfiguracion.TomaIncluyeArchivosOcultos: BOOLEAN;
  BEGIN
    RESULT := fArchivoIni.ReadBool ('project', 'hidden_files', FALSE);
  END;



  PROCEDURE TConfiguracion.PonIncluyeArchivosOcultos (CONST Valor: BOOLEAN);
  BEGIN
    fArchivoIni.WriteBool ('project', 'hidden_files', Valor);
  END;



  FUNCTION TConfiguracion.TomaIncluyeSoloArchivosFuente: BOOLEAN;
  BEGIN
    RESULT := fArchivoIni.ReadBool ('project', 'only_source_files', TRUE);
  END;



  PROCEDURE TConfiguracion.PonIncluyeSoloArchivosFuente (CONST Valor: BOOLEAN);
  BEGIN
    fArchivoIni.WriteBool ('project', 'only_source_files', Valor);
  END;



  FUNCTION TConfiguracion.TomaGuardarAlPerderFoco: BOOLEAN;
  BEGIN
    RESULT := fArchivoIni.ReadBool ('editor', 'save_focus_off', FALSE);
  END;



  PROCEDURE TConfiguracion.PonGuardarAlPerderFoco (CONST Valor: BOOLEAN);
  BEGIN
    fArchivoIni.WriteBool ('editor', 'save_focus_off', Valor);
  END;


  FUNCTION TConfiguracion.TomaCopiaSeguridad: BOOLEAN;
  BEGIN
    RESULT := fArchivoIni.ReadBool ('editor', 'backup', FALSE);
  END;



  PROCEDURE TConfiguracion.PonCopiaSeguridad (CONST Valor: BOOLEAN);
  BEGIN
    fArchivoIni.WriteBool ('editor', 'backup', Valor);
  END;



  FUNCTION TConfiguracion.TomaExtCopiaSeguridad: STRING; INLINE;
  BEGIN
    RESULT := fArchivoIni.ReadString ('editor', 'backup_ext', 'orig');
  END;



  PROCEDURE TConfiguracion.PonExtCopiaSeguridad (CONST Valor: STRING); INLINE;
  BEGIN
    IF Length (Trim (Valor)) < 1 THEN
      RAISE Exception.Create ('Debe indicarse una extensión al archivo');
    fArchivoIni.WriteString ('editor', 'backup_ext', Valor);
  END;



  FUNCTION TConfiguracion.TomaNumSintaxis: INTEGER;
  BEGIN
    RESULT := Length (UnitDatos.ListaSintaxis);
  END;



  FUNCTION TConfiguracion.TomaNombreSintaxis (CONST Ndx: INTEGER): STRING;
  BEGIN
    RESULT := UnitDatos.ListaSintaxis[Ndx].Nombre;
  END;



  FUNCTION TConfiguracion.TomaExtSintaxis (CONST Ndx: INTEGER): STRING;
  BEGIN
    RESULT := UnitDatos.ListaSintaxis[Ndx].Extensiones;
  END;



  PROCEDURE TConfiguracion.PonExtSintaxis (CONST Ndx: INTEGER; aExtensiones: STRING);
  BEGIN
    UnitDatos.ListaSintaxis[Ndx].Extensiones := aExtensiones;
  END;



(* Carga la configuración. *)
  CONSTRUCTOR TConfiguracion.Create;
  BEGIN
    INHERITED Create;
    fArchivoIni := TIniFile.Create (GetAppConfigFile (FALSE, TRUE));
    fArchivoIni.CacheUpdates := TRUE;
    fNiveldialogo := 0
  END;



(* Destructor. *)
  DESTRUCTOR TConfiguracion.Destroy;
  BEGIN
    fArchivoIni.Free;
    INHERITED Destroy
  END;



(* Guarda la configuración en disco. *)
  PROCEDURE TConfiguracion.Guardar;
  VAR
    RutaDir: STRING;
  BEGIN
    RutaDir := GetAppConfigDir (FALSE);
    IF NOT DirectoryExists (RutaDir) THEN
    BEGIN
      {$I+}
      MkDir (RutaDir);
      {$I-}
      IF IOResult <> 0 THEN
        RAISE Exception.CreateFmt ('No pudo crearse el directorio "%s".', [RutaDir]);
    END;
    fArchivoIni.UpdateFile;
  END;



(* Usar antes de abrir un diálogo. *)
  PROCEDURE TConfiguracion.AntesDialogo;
  BEGIN
    INC (fNiveldialogo);
    IF fNiveldialogo = 1 THEN
    BEGIN
      fCfgAutoGuardar := SELF.TomaGuardarAlPerderFoco;
      SELF.PonGuardarAlPerderFoco (FALSE)
    END
  END;



(* Usar tras cerrar un diálogo. *)
  PROCEDURE TConfiguracion.DespuesDialogo;
  BEGIN
    DEC (fNiveldialogo);
    IF fNiveldialogo = 0 THEN
      SELF.PonGuardarAlPerderFoco (fCfgAutoGuardar)
  END;



INITIALIZATION
  Config := TConfiguracion.Create;
FINALIZATION
  FreeAndNil (Config);
END.

