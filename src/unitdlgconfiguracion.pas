UNIT unitDlgConfiguracion;

{$mode objfpc}{$H+}

INTERFACE

USES
  Classes, Sysutils, Fileutil, DividerBevel, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, ComCtrls, ButtonPanel, StdCtrls, Spin;

TYPE

  { TDlgConfiguracion }

  TDlgConfiguracion = CLASS (Tform )
    ChkSoloArchivosFuente: Tcheckbox;
    ChkMostrarBarraEstrado: Tcheckbox;
    ChkMostrarBarraHerramientas: Tcheckbox;
    ChkMostrarMenuPpal: Tcheckbox;
    ChkEditGuardaAlPerderFoco: Tcheckbox;
    ChkCopiaSeguridad: Tcheckbox;
    ChkDirsOcultos: Tcheckbox;
    ChkArchOcultos: Tcheckbox;
    TituloGuardadoAutomatico: Tdividerbevel;
    EditExtCopiaSeguridad: TComboBox;
    EditNivelDirs: Tspinedit;
    LblEditExtCopiaSeguridad: Tlabel;
    LblEditNivelDirs: Tlabel;
    TituloArchivosDir: Tdividerbevel;
    PagProyecto: Tpage;
    PagEntorno: Tpage;
    PanelBotones: Tbuttonpanel;
    PantallasConfig: Tnotebook;
    OpcionesConfiguracion: TTreeView;
    Splitter: TSplitter;
    TituloCopiasSeguridad: Tdividerbevel;
    TituloAspecto: Tdividerbevel;
    PROCEDURE FormCreate (Sender: TObject);
    PROCEDURE OkButtonClick (Sender: TObject);
    PROCEDURE OpcionesConfiguracionClick (Sender: TObject);
  PRIVATE
    { private declarations }
  PUBLIC
    { public declarations }
  END;

VAR
  DlgConfiguracion: TDlgConfiguracion;

IMPLEMENTATION

  USES
    Configuracion;

{$R *.lfm}

{ TDlgConfiguracion }

  CONST
  (* Mnemónicos para las páginas.  Se corresponden con el índice del elemento
     del árbol y con el Tag de la página del TNotebook. *)
    PAG_Proyecto = 0;
    PAG_Entorno  = 1;

  PROCEDURE TDlgConfiguracion.FormCreate (Sender: TObject);
  BEGIN
  { Paginación. }
    OpcionesConfiguracion.Items[PAG_Proyecto].Data := POINTER (PAG_Proyecto);
    OpcionesConfiguracion.Items[PAG_Entorno].Data  := POINTER (PAG_Entorno);
  { Opciones. }
    ChkDirsOcultos.Checked := Config.InluyeDirsOcultos;
    EditNivelDirs.Value := Config.NivelProfundidadDirs;

    ChkArchOcultos.Checked := Config.InluyeArchivosOcultos;
    ChkSoloArchivosFuente.Checked := Config.InluyeSoloArchivosFuente;

    ChkEditGuardaAlPerderFoco.Checked := Config.GuardarAlPerderFoco;
    ChkCopiaSeguridad.Checked := Config.CopiaSeguridad;
    EditExtCopiaSeguridad.Text := Config.ExtensionCopiaSeguridad;

    ChkMostrarMenuPpal.Checked := Config.MostrarMenuPpal;
    ChkMostrarBarraHerramientas.Checked := Config.MostrarBarraHerramientas;
    ChkMostrarBarraEstrado.Checked := Config.MostrarBarraEstado;

    Config.AntesDialogo;
  END;



  PROCEDURE TDlgConfiguracion.OkButtonClick (Sender: TObject);
  BEGIN
    Config.DespuesDialogo;

    Config.InluyeDirsOcultos := ChkDirsOcultos.Checked;
    Config.NivelProfundidadDirs := EditNivelDirs.Value;

    Config.InluyeArchivosOcultos := ChkArchOcultos.Checked;
    Config.InluyeSoloArchivosFuente := ChkSoloArchivosFuente.Checked;

    Config.GuardarAlPerderFoco := ChkEditGuardaAlPerderFoco.Checked;
    Config.CopiaSeguridad := ChkCopiaSeguridad.Checked;
    Config.ExtensionCopiaSeguridad := EditExtCopiaSeguridad.Text;

    Config.MostrarMenuPpal := ChkMostrarMenuPpal.Checked;
    Config.MostrarBarraHerramientas := ChkMostrarBarraHerramientas.Checked;
    Config.MostrarBarraEstado := ChkMostrarBarraEstrado.Checked;

    Config.Guardar;
  END;



  PROCEDURE TDlgConfiguracion.OpcionesConfiguracionClick (Sender: TObject);
  BEGIN
    IF Sender IS TTreeView THEN
      PantallasConfig.PageIndex := TTreeView (Sender).Selected.Index
    ELSE
      RAISE Exception.Create ('[TDlgConfiguracion.OpcionesConfiguracionClick] ¡Se llamó al evento equivocado!')
  END;

END.

