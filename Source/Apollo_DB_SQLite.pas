unit Apollo_DB_SQLite;

interface

uses
  Apollo_DB_Core,
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLite,
  System.Classes;

type
  TSQLiteEngine = class(TDBEngine)
  protected
    procedure SetConnectParams(aConnection: TFDConnection); override;
  protected
    function GetRenameTableSQL(const aOldTableName, aNewTableName: string): string;
  public
    function GetModifyTableSQL(const aOldTableName: string; const aTableDef: TTableDef): TStringList; override;
  end;

implementation

uses
  System.SysUtils;

{ TSQLiteEngine }

function TSQLiteEngine.GetModifyTableSQL(const aOldTableName: string;
  const aTableDef: TTableDef): TStringList;
var
  FieldDef: TFieldDef;
  NeedToModify: Boolean;
  NewTableDef: TTableDef;
begin
  Result := TStringList.Create;
  NeedToModify := False;

  for FieldDef in aTableDef.FieldDefs do
  begin
    if DifferMetadata(aOldTableName, FieldDef) <> mdEqual then
      NeedToModify := True;
  end;

  if NeedToModify then
  begin
    Result.Add('PRAGMA FOREIGN_KEYS = OFF;');

    NewTableDef := aTableDef;
    NewTableDef.TableName := 'NEW_' + NewTableDef.TableName;
    Result.Add(GetCreateTableSQL(NewTableDef));

    Result.Add(Format('DROP TABLE %s;', [aOldTableName]));

    Result.Add(GetRenameTableSQL(NewTableDef.TableName, aTableDef.TableName));

    Result.Add('PRAGMA FOREIGN_KEYS = ON;');
  end;

  if not NeedToModify and (aTableDef.TableName <> aOldTableName) then
    Result.Add(GetRenameTableSQL(aOldTableName, aTableDef.TableName));
end;

function TSQLiteEngine.GetRenameTableSQL(const aOldTableName,
  aNewTableName: string): string;
begin
  Result := Format('ALTER TABLE %s RENAME TO %s;', [aOldTableName, aNewTableName]);
end;

procedure TSQLiteEngine.SetConnectParams(aConnection: TFDConnection);
begin
  inherited;

  aConnection.Params.Values['DriverID'] := 'SQLite';
end;

end.
