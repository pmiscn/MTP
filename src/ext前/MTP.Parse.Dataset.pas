unit MTP.Parse.Dataset;

/// 数据集的接口，就是糊弄下，只支持dataset标记，for each 等同于dataset，都是循环一次。if是字段。
///
interface

uses sysutils, System.Classes, Generics.Collections,
  Data.DB, FireDAC.Comp.Client, FireDAC.Comp.Dataset, FireDAC.Moni.RemoteClient, FireDAC.Phys.MSSQL,

  qstring, MTP.Utils, MTP.Types, MTP.Parse, MTP.Expression;

type
  TMDataParser_Dataset = class(TMInterface, IMDataParser) // TObjectInterfaced
  public
    constructor Create();
    destructor Destroy; override;

    function DataByPath(const aData: Pointer; const aPath: String): Pointer;
    function TryDataByPath(const aData: Pointer; const aPath: String; var outdata: Pointer): Boolean;
    function TryGetData(const aData: Pointer; const AName: String; const aAllowOwn: Boolean; var r: string): Boolean;
    function DataCount(const aData: Pointer): Integer;

    function HasPath(const aData: Pointer; const aPath: String): Boolean;
    function Items(const aData: Pointer; const idx: Integer): Pointer;

  end;

var
  pubDataParser_Dataset: TMDataParser_Dataset;

implementation

uses Mu.MSSQL.Exec, qjson, Mu.Pool.qjson;
{ TMDataParse_JSON }

constructor TMDataParser_Dataset.Create;
begin

end;

function TMDataParser_Dataset.DataByPath(const aData: Pointer; const aPath: String): Pointer;
begin
  result := TFDRdbmsDataSet(aData); // .ItemByPath(aPath);
end;

function TMDataParser_Dataset.DataCount(const aData: Pointer): Integer;
begin
  result := Tdataset(aData).RecordCount;
end;

destructor TMDataParser_Dataset.Destroy;
begin
  inherited;
end;

function TMDataParser_Dataset.HasPath(const aData: Pointer; const aPath: String): Boolean;
begin
  // 这个是命名

  result := true; // TQJson(aData).ItemByPath(aPath) <> nil;
end;

function TMDataParser_Dataset.Items(const aData: Pointer; const idx: Integer): Pointer;
begin
  TFDRdbmsDataSet(aData).RecNo := idx;
  result := TFDRdbmsDataSet(aData); // TQJson(aData).Items[idx];
end;

function TMDataParser_Dataset.TryDataByPath(const aData: Pointer; const aPath: String; var outdata: Pointer): Boolean;
begin
  result := true; // TFDRdbmsDataSet(aData ;
end;

function TMDataParser_Dataset.TryGetData(const aData: Pointer; const AName: String; const aAllowOwn: Boolean;
  var r: string): Boolean;
var
  fd: TField;
  nama: String;
  fdst: TFDRdbmsDataSet;
  function fdvalue(fdst: TFDRdbmsDataSet): String;
  var
    js: Tqjson;
  begin
    js := qjsonpool.get;
    try
      TMuMSSQLExecBase.datasetToJson(fdst, js);
      result := js.ToString;
    finally
      qjsonpool.return(js);
    end;
  end;

begin
  r := '';
  fdst := TFDRdbmsDataSet(aData);
  nama := AName;
  if (nama = EXPrefix) and (aAllowOwn) then
  begin
    r := fdvalue(fdst); result := true; exit;
  end;

  if nama[1] = EXPrefix then
  begin
    System.delete(nama, 1, 1);
    fd := fdst.FieldByName(nama);
    if fd <> nil then
    begin
      r := fd.AsString;
      result := true;
    end
  end else if aAllowOwn then
  begin
    r := nama;
    result := true;
  end
end;

initialization

pubDataParser_Dataset := TMDataParser_Dataset.Create;

finalization

freeandnil(pubDataParser_Dataset);

end.
