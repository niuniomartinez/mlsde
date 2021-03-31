UNIT UnitDatos;

{$mode objfpc}{$H+}

INTERFACE

USES
  Classes, Fileutil, SynHighlighterPas, Controls, Dialogs,
  SynEditHighlighterFoldBase, SynHighlighterCpp, SynHighlighterJava,
  SynHighlighterHTML, SynHighlighterXML, SynHighlighterCss, SynHighlighterPHP,
  synhighlighterunixshellscript, SynHighlighterVB, SynHighlighterIni,
  SynHighlighterBat,
  SynEditHighlighter, SynHighlighterSQL, SynHighlighterJScript;

  TYPE

    { TModuloDatos }

    TModuloDatos = CLASS (Tdatamodule )
      ImagenesOperaciones: Timagelist;
      DlgSeleccionarDirectorio: Tselectdirectorydialog;
      SynBatSyn: TSynBatSyn;
      SynCppSyn: TSynCppSyn;
      SynCssSyn: TSynCssSyn;
      SynHTMLSyn: TSynHTMLSyn;
      SynIniSyn: TSynIniSyn;
      SynJavaSyn: TSynJavaSyn;
      SynJScriptSyn: Tsynjscriptsyn;
      SynPasSyn: TSynPasSyn;
      SynPHPSyn: TSynPHPSyn;
      SynSQLSyn: Tsynsqlsyn;
      SynUNIXShellScriptSyn: TSynUNIXShellScriptSyn;
      SynXMLSyn: TSynXMLSyn;
      PROCEDURE DataModuleCreate (Sender: Tobject );
    PUBLIC
    (* Dada una extensión, devuelve el analizador sintáctico adecuado. *)
      FUNCTION SintaxisDeExt (aExt: STRING): TSynCustomHighlighter;
    END;

  (* Almacena la información de una sintáxis. *)
    TSintaxix = RECORD
      Nombre,
    { Separadas por punto y coma, y en minúsculas. }
      Extensiones: STRING;
      Resaltado: TSynCustomHighlighter;
    END;

  CONST
  (* Abrir proyecto. *)
    GRF_ABRE_DIR = 0;
  (* Nuevo directorio. *)
    GRF_NUEVO_DIR = 3;
  (* Nuevo archivo. *)
    GRF_NUEVO_ARCHIVO = 4;
  (* Renombrar. *)
    GRF_RENOMBRAR = 5;
  (* Eliminar archivo o directorio. *)
    GRF_ELIMINAR_ARCHIVO = 6;
  (* Salir. *)
    GRF_SALIR = 7;
  (* Configurar la aplicación. *)
    GRF_CONFIGURAR = 8;
  (* Guardar. *)
    GRF_GUARDAR = 9;
  (* Recargar, restaurar, ... *)
    GRF_RECARGAR = 10;
  (* Marca de información. *)
    GRF_INFORMACION = 11;


VAR
  ModuloDatos: TModuloDatos;
(* Lista de sintáxis y tal o dos. *)
  ListaSintaxis: ARRAY OF TSintaxix;

IMPLEMENTATION

  USES
    sysutils;

{$R *.lfm}

(* Pone un valor de sintáxis. *)
  PROCEDURE PonSintaxis (CONST Ndx: INTEGER; Nombre, Extensiones: STRING;
    Resaltado: TSynCustomHighlighter);
  BEGIN
    ListaSintaxis[Ndx].Nombre := Trim (Nombre);
    ListaSintaxis[Ndx].Extensiones := LowerCase (Trim (Extensiones));
    ListaSintaxis[Ndx].Resaltado := Resaltado;
  END;



  { TModuloDatos }

  PROCEDURE TModuloDatos.DataModuleCreate (Sender: Tobject );
  BEGIN
  { Sintáxis y extensiones por defecto. }
    SetLength (ListaSintaxis, 13);
    PonSintaxis ( 0, 'texto',      ';txt', NIL);
  { Si no estuviera el primero, habría un conflicto entre ".pp" y ".cpp". }
    PonSintaxis ( 1, 'Pascal',  'pas;pp;dpr;lpr', SynPasSyn);
    PonSintaxis ( 2, 'bat',        'bat',         SynBatSyn);
    PonSintaxis ( 3, 'C/C++',      'c;cpp;h;hpp', SynCppSyn);
    PonSintaxis ( 4, 'CSS',        'css',         SynCssSyn);
    PonSintaxis ( 5, 'HTML',       'htm;html',    SynHTMLSyn);
    PonSintaxis ( 6, 'INI',        'ini',         SynIniSyn);
    PonSintaxis ( 7, 'Java',       'jav',         SynJavaSyn);
    PonSintaxis ( 8, 'JavaScript', 'js',          SynJScriptSyn);
    PonSintaxis ( 9, 'PHP',        'php',         SynPHPSyn);
    PonSintaxis (10, 'UNIX shell', 'sh',          SynUNIXShellScriptSyn);
    PonSintaxis (11, 'SQL',        'sql',         SynSQLSyn);
    PonSintaxis (12, 'XML',        'xml;rss',     SynXMLSyn);
  END;



(* Dada una extensión, devuelve el analizador sintáctico adecuado. *)
  FUNCTION TModuloDatos.SintaxisDeExt (aExt: STRING): TSynCustomHighlighter;
  VAR
    Ndx: INTEGER;
  BEGIN
    aExt := LowerCase (Trim (aExt));
    IF Length (aExt) > 0 THEN
    BEGIN
      IF aExt[1] = '.' THEN aExt := RightStr (aExt, Length (aExt) - 1);
      FOR Ndx := LOW (ListaSintaxis) TO HIGH (ListaSintaxis) DO
        IF Pos (aExt, ListaSintaxis[Ndx].Extensiones) > 0 THEN
          EXIT (ListaSintaxis[Ndx].Resaltado);
    END;
  { Es texto plano o no lo reconoce. }
    RESULT := NIL;
  END;

END.

