program Apollo_DB_SQLite_Test;

{$STRONGLINKTYPES ON}
uses
  Vcl.Forms,
  System.SysUtils,
  DUnitX.Loggers.GUI.VCL,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  tstApollo_DB_SQLite in 'tstApollo_DB_SQLite.pas',
  Apollo_DB_SQLite in 'Apollo_DB_SQLite.pas';

begin
  Application.Initialize;
  Application.Title := 'DUnitX';
  AApplication.CreateForm(TGUIVCLTestRunner, GUIVCLTestRunner);
  pplication.Run;
end.
