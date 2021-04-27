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
    function GetModifyTableSQL(const aTableDef: TTableDef): TStringList; override;
  end;

implementation

uses
  Apollo_Helpers,
  FireDAC.Phys.Intf,
  System.SysUtils;

{ TSQLiteEngine }

function TSQLiteEngine.GetModifyTableSQL(const aTableDef: TTableDef): TStringList;
var
  FieldDef: TFieldDef;
  FieldNames: TArray<string>;
  FKeyDef: TFKeyDef;
  NeedToModify: Boolean;
  NewTableDef: TTableDef;
  OldFieldNames: TArray<string>;
  SQLList: TStringList;
begin
  Result := TStringList.Create;
  NeedToModify := False;

  for FieldDef in aTableDef.FieldDefs do
  begin
    if DifferMetadata(aTableDef.OldTableName, FieldDef) <> mdEqual then
      NeedToModify := True;
  end;

  ForEachMetadata(aTableDef.OldTableName, mkTableFields, procedure(aDMetaInfoQuery: TFDMetaInfoQuery)
    var
      FieldDef2: TFieldDef;
      FieldExists: Boolean;
    begin
      if NeedToModify then
        Exit;

      FieldExists := False;
      for FieldDef2 in aTableDef.FieldDefs do
      begin
        if aDMetaInfoQuery.FieldByName('COLUMN_NAME').AsString = FieldDef2.OldFieldName then
          FieldExists := True;
      end;
      if not FieldExists then
        NeedToModify := True;
    end
  );

  for FKeyDef in aTableDef.FKeyDefs do
  begin
    if DifferMetadata(aTableDef.OldTableName, FKeyDef) <> mdEqual then
      NeedToModify := True;
  end;

  if NeedToModify then
  begin
    Result.Add('PRAGMA FOREIGN_KEYS = OFF;');

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
        FieldNames := FieldNames + [FieldDef.FieldName];
        OldFieldNames := OldFieldNames + [FieldDef.OldFieldName];
      end;

    if FieldNames.Count > 0 then
      Result.Add(Format('INSERT INTO %s (%s) SELECT %s FROM %s;', [
        NewTableDef.TableName,
        FieldNames.CommaText,
        OldFieldNames.CommaText,
        NewTableDef.OldTableName
      ]));

    Result.Add(Format('DROP TABLE %s;', [NewTableDef.OldTableName]));

    Result.Add(GetRenameTableSQL(NewTableDef.TableName, aTableDef.TableName));

    Result.Add('PRAGMA FOREIGN_KEYS = ON;');
  end;

  if not NeedToModify and (aTableDef.TableName <> aTableDef.OldTableName) then
    Result.Add(GetRenameTableSQL(aTableDef.OldTableName, aTableDef.TableName));
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
