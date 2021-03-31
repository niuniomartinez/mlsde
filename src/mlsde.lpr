program mlsde;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  mlsdeScripting,
  Forms, lazcontrols, unitVntPrincipal, UnitDatos, configuracion
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.Createform(Tmodulodatos, Modulodatos);
  Scripts := TScriptingSystem.Create (Application);
  Application.Createform(Tvntprincipal, Vntprincipal);
  Application.Run;
end.

