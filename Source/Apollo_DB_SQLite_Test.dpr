program Apollo_DB_SQLite_Test;

{$STRONGLINKTYPES ON}
uses
  Vcl.Forms,
  System.SysUtils,
  DUnitX.Loggers.GUI.VCL,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  tstApollo_DB_SQLite in 'tstApollo_DB_SQLite.pas',
  Apollo_DB_SQLite in 'Apollo_DB_SQLite.pas',
  Apollo_Helpers in '..\Vendors\Apollo_Helpers\Apollo_Helpers.pas',
  Apollo_DB_Core in '..\Vendors\Apollo_DB_Core\Apollo_DB_Core.pas';

begin
  Application.Initialize;
  Application.Title := 'DUnitX';
  Application.CreateForm(TGUIVCLTestRunner, GUIVCLTestRunner);
  Application.Run;
end.
