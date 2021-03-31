UNIT Project;
(*<Defines a poject manager. *)
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

INTERFACE

  USES
    Utils,
    Classes, Sysutils;

  TYPE
  (* @Exclude:  Forwarded. *)
    TProject = CLASS;
  (* @Exclude:  Forwarded. *)
    TDirectorio = CLASS;



  (* Contiene la descripción de un archivo de proyecto. *)
    TArchivo = CLASS (TObject)
    PRIVATE
      fNombre, fRuta: STRING;
      fDirectorio: TDirectorio;

      PROCEDURE PonNombre (CONST aNombre: STRING);
    PUBLIC
    (* Constructor. *)
      CONSTRUCTOR Create (aDir: TDirectorio);

    (* Nombre del archivo, sin ruta. *)
      PROPERTY Nombre: STRING READ fNombre WRITE PonNombre;
    (* Ruta del directorio contenedor del archivo. *)
      PROPERTY Ruta: STRING READ fRuta WRITE fRuta;
    END;



  (* Contiene la descripción de un directorio del proyecto. *)
    TDirectorio = CLASS (TObject)
    PRIVATE
      fNombre: STRING;
      fProyecto: TProject;
      fRaiz: TDirectorio;
      fSubdirectorios: ARRAY OF TDirectorio;
      fArchivos: ARRAY OF TArchivo;

      FUNCTION TomaNumSubDirectorios: INTEGER; INLINE;
      FUNCTION TomaSubdirectorio (CONST Ndx: INTEGER): TDirectorio; INLINE;
      FUNCTION TomaNumArchivos: INTEGER; INLINE;
      FUNCTION TomaArchivo (CONST Ndx: INTEGER): TArchivo; INLINE;

      PROCEDURE PonNombre (aNombre: STRING);
      FUNCTION TomaRuta: STRING;
      PROCEDURE Vacia;
    PUBLIC
    (* Crea el directorio (vacío). *)
      CONSTRUCTOR Create (aProyecto: TProject; aRaiz: TDirectorio=NIL);
    (* Destructor. *)
      DESTRUCTOR Destroy; OVERRIDE;
    (* Escanea el directorio y genera el árbol.  Funciona de forma
      semi-recursiva, solicitando el escaneo de cada subdirectorio
      encontrado.  No ejecuta el evento de cambio.  *)
      PROCEDURE Escanea (aRuta: STRING; CONST Nivel: INTEGER);

    (* Nombre del directorio. *)
      PROPERTY Nombre: STRING READ fNombre WRITE PonNombre;
    (* Ruta del directorio. *)
      PROPERTY Ruta: STRING READ TomaRuta;
    (* Directorio raíz. *)
      PROPERTY Raiz: TDirectorio READ fRaiz;
    (* Número de subdirectorios.  Empieza a contar en 1. *)
      PROPERTY NumSubdirectorios: INTEGER READ TomaNumSubDirectorios;
    (* Acceso a subdirectorios. *)
      PROPERTY Subdirectorios[CONST Ndx: INTEGER]: TDirectorio READ TomaSubdirectorio;
    (* Número de archivos. *)
      PROPERTY NumArchivos: INTEGER READ TomaNumArchivos;
    (* Acceso a archivos.  Empieza a contar en 1. *)
      PROPERTY Archivos[CONST Ndx: INTEGER]: TArchivo READ TomaArchivo;
    END;



  (* Contains and manages a project.

     @bold(Implementation note:)  Right now there's only one project per
     application.  It is created and owned by @link(TVntPrincipal) (the main
     window). *)
    TProject = CLASS (TObject)
    PRIVATE
      fRutaBase: STRING;
      fRaiz: TDirectorio;

      fOnChange: TMlsdeNotification;

      PROCEDURE PonRutaBase (CONST aRuta: STRING); INLINE;
    (* Limpia el proyecto actual. *)
      PROCEDURE Vacia;

      FUNCTION GetOnCHange: TNotifyEvent; INLINE;
      PROCEDURE SetOnChange (CONST aCallback: TNotifyEvent); INLINE;
    PUBLIC
    (* Creates an empty project. *)
      CONSTRUCTOR Create;
    (* Destructor. *)
      DESTRUCTOR Destroy; OVERRIDE;
    (* Analiza el directorio y genera el proyecto.  El proyecto actual se
      elimina. *)
      PROCEDURE Escanea (aRuta: STRING = '');

    (* Ruta base del proyecto, sin el directorio de la @link(raiz). *)
      PROPERTY RutaBase: STRING READ fRutaBase WRITE PonRutaBase;
    (* Directorio raíz. *)
      PROPERTY Raiz: TDirectorio READ fRaiz;

    (* Event triggered when something in the project changes, as a file name. *)
      PROPERTY onChange: TNotifyEvent READ GetOnChange WRITE SetOnChange;
    END;

IMPLEMENTATION

  USES
    Configuracion, UnitDatos;

  VAR
    ExtensionesValidas: ARRAY OF STRING;

(* Determina si el archivo o directorio es identificado como válido,
   dependiendo de la configuración. *)
  FUNCTION EsValido (CONST Info: TSearchRec): BOOLEAN;
  VAR
    Extension: STRING;
  BEGIN
    IF (Info.Attr AND faDirectory) = faDirectory THEN
    BEGIN
      IF (Info.Name = '.') OR (Info.Name = '..') THEN
	EXIT (FALSE);
      IF (NOT Config.InluyeDirsOcultos)
      AND ((Info.Attr AND faHidden) = faHidden) THEN
        EXIT (FALSE);
    END
    ELSE BEGIN
      IF (NOT Config.InluyeArchivosOcultos)
      AND ((Info.Attr AND faHidden) = faHidden) THEN
        EXIT (FALSE);
      IF Config.InluyeSoloArchivosFuente THEN
      BEGIN
        Extension := LowerCase (Trim (ExtractFileExt (Info.Name)));
        IF Length (Extension) > 0 THEN
        BEGIN
          Extension := RightStr (Extension, Length (Extension) - 1);
          IF NOT IsWordInList (Extension, ExtensionesValidas) THEN
            EXIT (FALSE);
        END;
      END;
    END;
    RESULT := TRUE;
  END;



  (*
   * TArchivo
   **************************************************************************)

  PROCEDURE TArchivo.PonNombre (CONST aNombre: STRING);
  BEGIN
    IF fNombre <> aNombre THEN
    BEGIN
      fNombre := ExtractFileName (aNombre);
      IF fNombre <> aNombre THEN fRuta := ExtractFileDir (aNombre);
      fDirectorio.fProyecto.fOnChange.NotifyEvent
    END;
  END;



(* Constructor. *)
  CONSTRUCTOR TArchivo.Create (aDir: TDirectorio);
  BEGIN
    INHERITED Create;
    fDirectorio := aDir;
  END;



(*
 * TDirectorio
 **************************************************************************)

  FUNCTION TDirectorio.TomaNumSubDirectorios: INTEGER;
  BEGIN
    RESULT := Length (fSubdirectorios);
  END;



  FUNCTION TDirectorio.TomaSubdirectorio (CONST Ndx: INTEGER): TDirectorio;
  BEGIN
    RESULT := fSubdirectorios[Ndx - 1];
  END;



  FUNCTION TDirectorio.TomaNumArchivos: INTEGER;
  BEGIN
    RESULT := Length (fArchivos);
  END;



  FUNCTION TDirectorio.TomaArchivo (CONST Ndx: INTEGER): TArchivo;
  BEGIN
    RESULT := fArchivos[Ndx - 1];
  END;



  PROCEDURE TDirectorio.PonNombre (aNombre: STRING);
  BEGIN
    aNombre := ExtractFileName (ExcludeTrailingPathDelimiter (aNombre));
    IF fNombre <> aNombre THEN
    BEGIN
      fNombre := aNombre;
      fProyecto.fOnChange.NotifyEvent
    END;
  END;



  FUNCTION TDirectorio.TomaRuta: STRING;
  BEGIN
    IF fRaiz <> NIL THEN
      RESULT := IncludeTrailingPathDelimiter (fRaiz.Ruta + fNombre)
    ELSE
      RESULT := IncludeTrailingBackslash (fProyecto.RutaBase + fNombre);
  END;



  PROCEDURE TDirectorio.Vacia;
  VAR
    Ndx: INTEGER;
  BEGIN
    FOR Ndx := LOW (fSubdirectorios) TO HIGH (fSubdirectorios) DO
      FreeAndNil (fSubdirectorios[Ndx]);
    SetLength (fSubdirectorios, 0);
    FOR Ndx := LOW (fArchivos) TO HIGH (fArchivos) DO
      FreeAndNil (fArchivos[Ndx]);
    SetLength (fArchivos, 0);
  END;



(* Crea el directorio (vacío). *)
  CONSTRUCTOR TDirectorio.Create (aProyecto: TProject; aRaiz: TDirectorio);
  BEGIN
    INHERITED Create;
    fProyecto := aProyecto;
    fRaiz := aRaiz;
  END;



(* Destructor. *)
  DESTRUCTOR TDirectorio.Destroy;
  BEGIN
    SELF.Vacia;
    INHERITED Destroy;
  END;



(* Escanea el directorio y genera el árbol.  Funciona de forma
  semi-recursiva, solicitando el escaneo de cada subdirectorio
  encontrado.  No ejecuta el evento de cambio. *)
  PROCEDURE TDirectorio.Escanea (aRuta: STRING; CONST Nivel: INTEGER);

    PROCEDURE AnnadeSubdirectorio (CONST aNombre: STRING); INLINE;
    VAR
      Ndx: INTEGER;
    BEGIN
      Ndx := Length (fSubdirectorios);
      SetLength (fSubdirectorios, Ndx + 1);
      fSubdirectorios[Ndx] := TDirectorio.Create (fProyecto, SELF);
      fSubdirectorios[Ndx].PonNombre (aNombre);
      fSubdirectorios[Ndx].Escanea (aRuta+aNombre, Nivel + 1);
    END;

    PROCEDURE AnnadeArchivo (CONST aNombre: STRING); INLINE;
    VAR
      Ndx: INTEGER;
    BEGIN
      Ndx := Length (fArchivos);
      SetLength (fArchivos, Ndx + 1);
      fArchivos[Ndx] := TArchivo.Create (SELF);
      fArchivos[Ndx].PonNombre (aNombre);
      fArchivos[Ndx].fRuta := aRuta;
    END;

  VAR
    Resultado: INTEGER;
    InfoArchivo: TSearchRec;
  BEGIN
    IF Nivel >= Config.NivelProfundidadDirs + 1 THEN
      EXIT;
  { Inicializa el análisis. }
    PonNombre (aRuta);
    aRuta := IncludeTrailingPathDelimiter (aRuta);
    SELF.Vacia;
    Resultado := FindFirst (aRuta+'*', faAnyFile OR faDirectory OR faHidden, InfoArchivo);
    TRY
    { Realiza la búsqueda. }
      IF Resultado = 0 THEN
      REPEAT
	IF EsValido (InfoArchivo) THEN
	BEGIN
	  IF (InfoArchivo.Attr AND faDirectory) = faDirectory THEN
	    AnnadeSubdirectorio (InfoArchivo.Name)
	  ELSE
	    AnnadeArchivo (InfoArchivo.Name);
	END;
      UNTIL FindNext (InfoArchivo) <> 0;
    FINALLY
      FindClose (InfoArchivo);
    END;
    fProyecto.fOnChange.NotifyEvent
  END;



(*
 * TProject
 ****************************************************************************)

  PROCEDURE TProject.PonRutaBase (CONST aRuta: STRING); INLINE;
  BEGIN
    fRutaBase := IncludeTrailingPathDelimiter (aRuta);
  END;



(* Limpia el proyecto actual. *)
  PROCEDURE TProject.Vacia;
  BEGIN
    FreeAndNil (fRaiz);
  END;



  FUNCTION TProject.GetOnChange: TNotifyEvent;
  BEGIN
    RESULT := fOnChange.Callback
  END;



  PROCEDURE TProject.SetOnChange (CONST aCallback: TNotifyEvent);
  BEGIN
    fOnChange.Callback := aCallback
  END;


(* Creates an empty project. *)
  CONSTRUCTOR TProject.Create;
  VAR
    Tmp: STRING;
  BEGIN
    INHERITED Create;
    fOnChange.Owner := SELF;
    fOnChange.Callback := NIL;
    Tmp := ExcludeTrailingPathDelimiter (GetUserDir);
    PonRutaBase (ExtractFileDir (Tmp));
    fRaiz := TDirectorio.Create (SELF);
    fRaiz.Nombre := Tmp
  END;



(* Destructor. *)
  DESTRUCTOR TProject.Destroy;
  BEGIN
    INHERITED Destroy;
    FreeAndNil (fRaiz);
  END;



(* Analiza el directorio y genera el proyecto.  El proyecto actual se
   elimina. *)
  PROCEDURE TProject.Escanea (aRuta: STRING);
  VAR
    NdxExt, NdxSin, PosChar: INTEGER;
  BEGIN
  { Si no indicó una ruta, re-escanea. }
    IF aRuta = '' THEN
      aRuta := SELF.Raiz.Ruta;
    IF DirectoryExists (aRuta) THEN
    BEGIN
      TRY
      { Crea la lista de extensiones reconocidas.}
        NdxExt := 0;
        FOR NdxSin := LOW (ListaSintaxis) TO HIGH (ListaSintaxis) DO
        BEGIN
          SetLength (ExtensionesValidas, NdxExt + 1);
          ExtensionesValidas[NdxExt] := '';
          FOR PosChar := 1 TO Length (ListaSintaxis[NdxSin].Extensiones) DO
            IF ListaSintaxis[NdxSin].Extensiones[PosChar] = ';' THEN
            BEGIN
              INC (NdxExt);
              SetLength (ExtensionesValidas, NdxExt + 1);
              ExtensionesValidas[NdxExt] := '';
            END
            ELSE
              ExtensionesValidas[NdxExt] :=
                ExtensionesValidas[NdxExt] +
                ListaSintaxis[NdxSin].Extensiones[PosChar];
          INC (NdxExt);
        END;
      { Realiza el análisis. }
	fOnChange.Deactivate;
	Vacia;
	PonRutaBase (ExtractFileDir (ExcludeTrailingPathDelimiter (aRuta)));
	fRaiz := TDirectorio.Create (SELF);
	fRaiz.Escanea (IncludeTrailingPathDelimiter (aRuta), 1);
      FINALLY
	SetLength (ExtensionesValidas, 0);
	fOnChange.Activate
      END;
      fOnChange.NotifyEvent
    END;
  END;

END.
