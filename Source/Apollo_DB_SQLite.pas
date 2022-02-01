unit Apollo_DB_SQLite;

interface

uses
  Apollo_DB_Core,
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLite,
  System.Classes;

type
  TSQLiteEngine = class(TDBEngine)
  private
    function DoNeedModify(const aTableDef: TTableDef): Boolean;
  protected
    procedure SetConnectParams(aConnection: TFDConnection); override;
  protected
    function GetRenameTableSQL(const aOldTableName, aNewTableName: string): string;
  public
    function GetModifyTableSQL(const aTableDef: TTableDef): TStringList; override;
    procedure DisableForeignKeys; override;
    procedure EnableForeignKeys; override;
  end;

implementation

uses
  Apollo_Helpers,
  FireDAC.Phys.Intf,
{$IF CompilerVersion >= 34.0} //from Delphi 10.4 Sydney
  FireDAC.Phys.SQLiteWrapper.Stat,
{$ENDIF}
  System.SysUtils;

{ TSQLiteEngine }

procedure TSQLiteEngine.DisableForeignKeys;
begin
  inherited;

  ExecSQL('PRAGMA FOREIGN_KEYS = OFF;');
end;

function TSQLiteEngine.DoNeedModify(const aTableDef: TTableDef): Boolean;
var
  FieldDef: TFieldDef;
  FKeyDef: TFKeyDef;
  IndexDef: TIndexDef;
begin
  Result := False;

  for FieldDef in aTableDef.FieldDefs do
  begin
    if DifferMetadata(aTableDef.OldTableName, FieldDef) <> mdEqual then
      Exit(True);
  end;
  if Length(DifferMetadataForDrop(aTableDef.OldTableName, aTableDef.FieldDefs)) > 0 then
    Exit(True);
  for FKeyDef in aTableDef.FKeyDefs do
  begin
    if DifferMetadata(aTableDef.OldTableName, FKeyDef) <> mdEqual then
      Exit(True);
  end;
  if Length(DifferMetadataForDrop(aTableDef.OldTableName, aTableDef.FKeyDefs)) > 0 then
    Exit(True);
  for IndexDef in aTableDef.IndexDefs do
  begin
    if DifferMetadata(aTableDef.OldTableName, IndexDef) <> mdEqual then
      Exit(True);
  end;

  if Length(DifferMetadataForDrop(aTableDef.OldTableName, aTableDef.IndexDefs)) > 0 then
    Exit(True);
end;

procedure TSQLiteEngine.EnableForeignKeys;
begin
  inherited;

  ExecSQL('PRAGMA FOREIGN_KEYS = ON;');
end;

function TSQLiteEngine.GetModifyTableSQL(const aTableDef: TTableDef): TStringList;
var
  FieldDef: TFieldDef;
  FieldNames: TArray<string>;
  NeedToModify: Boolean;
  NewTableDef: TTableDef;
  OldFieldNames: TArray<string>;
  SQLList: TStringList;
begin
  Result := TStringList.Create;
  NeedToModify := DoNeedModify(aTableDef);
  if NeedToModify then
  begin
    SQLList := TStringList.Create;
    try
      ForEachMetadata(aTableDef.OldTableName, mkIndexes, procedure(aDMetaInfoQuery: TFDMetaInfoQuery)
        begin
          SQLList.Add(Format('DROP INDEX %s;', [aDMetaInfoQuery.FieldByName('INDEX_NAME').AsString]));
        end
      );
      Result.AddStrings(SQLList);
    finally
      SQLList.Free;
    end;
    NewTableDef := aTableDef;
    NewTableDef.TableName := 'NEW_' + NewTableDef.TableName;
    SQLList := GetCreateTableSQL(NewTableDef);
    try
      Result.AddStrings(SQLList);
    finally
      SQLList.Free;
    end;
    FieldNames := [];
    OldFieldNames := [];
    for FieldDef in NewTableDef.FieldDefs do
      if not FieldDef.OldFieldName.IsEmpty then
      begin
        FieldNames := FieldNames + [Format('`%s`', [FieldDef.FieldName])];
        OldFieldNames := OldFieldNames + [Format('`%s`', [FieldDef.OldFieldName])];
      end;
    if FieldNames.Count > 0 then
      Result.Add(Format('INSERT INTO `%s` (%s) SELECT %s FROM `%s`;', [
        NewTableDef.TableName,
        FieldNames.CommaText,
        OldFieldNames.CommaText,
        NewTableDef.OldTableName
      ]));
    Result.Add(Format('DROP TABLE `%s`;', [NewTableDef.OldTableName]));
    Result.Add(GetRenameTableSQL(NewTableDef.TableName, aTableDef.TableName));
  end;
  if not NeedToModify and (aTableDef.TableName <> aTableDef.OldTableName) then
    Result.Add(GetRenameTableSQL(aTableDef.OldTableName, aTableDef.TableName));
end;

function TSQLiteEngine.GetRenameTableSQL(const aOldTableName,
  aNewTableName: string): string;
begin
  Result := Format('ALTER TABLE `%s` RENAME TO `%s`;', [aOldTableName, aNewTableName]);
end;

procedure TSQLiteEngine.SetConnectParams(aConnection: TFDConnection);
begin
  inherited;
  aConnection.Params.Values['DriverID'] := 'SQLite';
end;

end.
