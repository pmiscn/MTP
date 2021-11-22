unit MTP.Data;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.NetEncoding,
  System.Classes, MTP.Logs, MTP.Types, Mu.HttpGet,

  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys.MSSQL, FireDAC.Moni.RemoteClient,
  FireDAC.Phys, FireDAC.Stan.Intf,
  FireDAC.Stan.ExprFuncs, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.Client, Data.DB, FireDAC.Comp.DataSet,

  qjson, qstring, Mu.Pool.qjson, MTP.msdb;

type

  PMPostData = ^TMPostData;

  TMPostData = record
    Data1: Pointer;
    Data2: Pointer;
    Data3: Pointer;
    Data4: Pointer;
    Data5: Pointer;
  end;

  TMDataBase = class(TMLog)
    protected
      FDataConfig: TQjson;
      FTimeout   : integer;
      FDateOrigin: TMDataOrigin;
      FDataType  : TMDataType;
      FParams    : TQjson; // 查询参数
      FInThread  : boolean;
      FStatus    : integer; // 加载的状态，0 等待 -1 正在加载，1 成功 -2 失败 ，如果返回-1 一般就是异常引起的。
      FDataProp  : TMDataProp;

      procedure setvalue(vjs: TQjson);
    public
      constructor create(aDataProp: TMDataProp); overload; virtual;
      function execute(): boolean; virtual; abstract;
      destructor Destroy; override;
      class procedure SetValueFromParam(vjs: TQjson; aParam: TQjson); static;

      property TTimeout: integer read FTimeout write FTimeout;
      property DateOrigin: TMDataOrigin read FDateOrigin write FDateOrigin;
      property DataType: TMDataType read FDataType write FDataType;
      property InThread: boolean read FInThread write FInThread;
      property Status: integer read FStatus;
      property Params: TQjson read FParams write FParams;
  end;

  TMDataBaseClass = class of TMDataBase;

  TMJsonDataBase = class(TMDataBase)
    protected
      FResultData: TQjson;
    protected
      function DoGetInst(aInst: TMJsonDataBase): TQjson; virtual; abstract;
      function DoGet(): TQjson; virtual; abstract;
    public

      constructor create(aDataProp: TMDataProp); override;
      destructor Destroy; override;
      function Get(): TQjson; overload; virtual;
      function Get(aParams: TQjson): TQjson; overload; virtual;
      property ResultData: TQjson read FResultData;
  end;

  TMJsonDataBaseClass = class of TMJsonDataBase;

  TMJsonData_JSON = class(TMJsonDataBase)
    private

    protected
      function DoGetInst(aInst: TMJsonDataBase): TQjson; override;
      function DoGet(): TQjson; override;
    public

  end;

  TMJsonData_File = class(TMJsonDataBase)
    private
      FFileName: String;
    protected
      function DoGetInst(aInst: TMJsonDataBase): TQjson; override;
      function DoGet(): TQjson; override;
    public

      property FileName: String read FFileName;
  end;

  TMJsonData_Http = class(TMJsonDataBase)
    private
      function getdata(hp: TMuHttpget; aValue: TQjson): TQjson;
    protected
      function DoGetInst(aInst: TMJsonDataBase): TQjson; override;
      function DoGet(): TQjson; override;
    public
      class function ParamsToUrlParams(aParam: TQjson): String;
  end;

  TMJsonData_MDB = class(TMJsonDataBase)
    private
      function getdata(): TQjson;
    protected
      function DoGetInst(aInst: TMJsonDataBase): TQjson; override;
      function DoGet(): TQjson; override;
    public
      destructor Destroy; override;
  end;

  TMJsonData_Plugin    = class(TMJsonDataBase);
  TMJsonData_QPligin   = class(TMJsonDataBase);
  TMJsonData_mdoUnknow = class(TMJsonDataBase);

  TMJsonData_Custom = class(TMJsonDataBase)
    function getdata(aValue: TQjson): TQjson;
    protected
      function DoGetInst(aInst: TMJsonDataBase): TQjson; override;
      function DoGet(): TQjson; override;
  end;

  TMJsonData = TMJsonDataBase;

  TMJSONDataOriginAndClass = record
    Origin: TMDataOrigin;
    cls: TMJsonDataBaseClass;
  end;

  TMJsonDataM = class
    private
      class var FMJsonDataBaseClass: TMJsonDataBaseClass;

    public
      // class constructor create;
      // class destructor Destroy;
      class procedure RegisterMuHttpGetBaseClass(const aMJsonDataBaseClass: TMJsonDataBaseClass);
    protected
    public
      // class function create: TMJsonData; overload; static;
      // class function create(const aMJsonDataBaseClass: TMJsonDataBaseClass; const aConfig: String): TMJsonData; static;
      class function create(const aMJsonDataBaseClass: TMJsonDataBaseClass; const aDataProp: TMDataProp): TMJsonData;
        overload; static;
      class function create(const aDataProp: TMDataProp): TMJsonData; overload; static;

  end;

  TMDataBaseUnkown = class(TMDataBase)
  end;

  TMDatasetDataBase = class(TMDataBase)
  end;

  TMDatasetDataGetEnd = reference to procedure(ADataset: Pointer); // TFDRdbmsDataSet

  TMDatasetData = class(TMDatasetDataBase)
    private
    public
      function GetDataset(aParams: TQjson): TFDRdbmsDataSet;
      procedure ReturnDataset(ads: TFDRdbmsDataSet);
      // 直接用static 省事
      class procedure getdata(aConfig: TQjson; aParams: TQjson; OnEnd: TMDatasetDataGetEnd);
  end;

  TMData = class
    public
      class function GetJsonData(const aProperty: TMDataProp; aParams: TQjson; aData: TQjson): boolean;
      class function GetDatasetData(const aProperty: TMDataProp; aParams: TQjson; var aData: TFDRdbmsDataSet): boolean;

      class function getdata(const aProperty: TMDataProp; aParams: TQjson; var aData: Pointer): boolean;
  end;

const
  // (mdoUnknow, mdoJson, mdoHttp, mdoMuDB, mdoFile, mdoPlugin, mdoQPlugin, mdoCustom);
  JSONDataOriginAndClass: array [mdoUnknow .. mdoCustom] of TMJsonDataBaseClass = (TMJsonData_mdoUnknow,
    TMJsonData_JSON, TMJsonData_Http, TMJsonData_MDB, TMJsonData_File, TMJsonData_Plugin, TMJsonData_QPligin,
    TMJsonData_Custom);

const
  DataTypeAndClass: array [mdtUnknow .. mdtDataset] of TMDataBaseClass = (TMDataBaseUnkown, TMJsonDataBase,
    TMDatasetDataBase);

implementation

uses MTP.Utils, Mu.Pool.st, qworker;

constructor TMDataBase.create(aDataProp: TMDataProp);
begin
  FDataConfig := TQjson.create;

  if (aDataProp.Path <> '') and (aDataProp.Origin <> mdoHttp) then
  begin
    FDataConfig.LoadFromFile(aDataProp.Path)
  end else if aDataProp.Content.Trim <> '' then
    if not FDataConfig.TryParse(aDataProp.Content) then
    begin
      raise Exception.create('Error data node content,must ba json');
    end;

  FTimeout    := aDataProp.Timeout;
  FDateOrigin := aDataProp.Origin;

  FDataType := aDataProp.DataType;
  FInThread := false;
  FDataProp := aDataProp;

  FStatus := 0;
end;

destructor TMDataBase.Destroy;
begin
  FDataConfig.Free;
  inherited;
end;

procedure TMDataBase.setvalue(vjs: TQjson);

begin

  TMDataBase.SetValueFromParam(vjs, FParams);

end;

class procedure TMDataBase.SetValueFromParam(vjs, aParam: TQjson);
var
  js          : TQjson;
  s           : String;
  GetAllParams: boolean;
  function paramValue(n: String): String;
  begin
    result := aParam.ValueByName(n, '');
  end;

  procedure setpv(js: TQjson);
  var
    j: TQjson;
  begin

    if js.DataType = jdtstring then
    begin
      s := js.Value;
      if s = '' then
      begin
        js.AsString := paramValue(js.Name);
        exit;
      end else if s = '$$' then
      begin
        GetAllParams := true;
        // js.DataType := jdtobject;
        // js.Assign(aParam);
        js.AsString := aParam.ToString;
      end else if s[1] = '$' then
      begin
        if s = '$' then
          js.AsString := paramValue(js.Name)
        else
          js.AsString := aParam.ValueByPath(s.Substring(1), '');
      end;
    end else if js.DataType = jdtobject then
    begin
      for j in js do
      begin
        setpv(j);
      end;
    end;
  end;

begin
  GetAllParams := false;
  // 这个以后扩展 cookie session jwt
  if not assigned(aParam) then
    exit;

  for js in vjs do
  begin
    setpv(js);
  end;
  if not GetAllParams then
    vjs.Merge(aParam, jmmIgnore);
end;

{ TMJsonDataBase }

constructor TMJsonDataBase.create(aDataProp: TMDataProp);
begin
  inherited create(aDataProp);
  FResultData := TQjson.create;
end;

destructor TMJsonDataBase.Destroy;
begin
  FResultData.Free;
  inherited;
end;

function TMJsonDataBase.Get(aParams: TQjson): TQjson;
begin
  self.FParams := aParams;
  result       := DoGetInst(self);
end;

function TMJsonDataBase.Get: TQjson;
begin
  self.FParams := nil;
  result       := DoGetInst(self);
end;

{ TMJsonData_JSON }

function TMJsonData_JSON.DoGetInst(aInst: TMJsonDataBase): TQjson;
begin
  result := TMJsonData_JSON(aInst).DoGet();
end;

function TMJsonData_JSON.DoGet: TQjson;
begin

  self.ResultData.Assign(self.FDataConfig);
  FStatus := 1;
end;

{ TMJsonData_File }

function TMJsonData_File.DoGetInst(aInst: TMJsonDataBase): TQjson;
begin
  result := TMJsonData_File(aInst).DoGet();
end;

function TMJsonData_File.DoGet: TQjson;
var
  stm: TMemoryStream;
begin
  FStatus := -1;

  if FDataProp.Path <> '' then
    self.FFileName := FDataProp.Path
  else
    self.FFileName := self.FDataConfig.ValueByName('FileName', '');

  if (FFileName <> '') and fileExists(FFileName) then
  begin
    stm := getstm();
    try
      stm.LoadFromFile(FFileName);
      stm.Position := 0;
      FResultData.LoadFromStream(stm);
      FStatus := 1;
    finally
      returnstm(stm);
    end;
  end
  else;
end;

{ TMJsonData_Http }

function TMJsonData_Http.DoGetInst(aInst: TMJsonDataBase): TQjson;
begin
  result := TMJsonData_Http(aInst).DoGet();
end;

function TMJsonData_Http.DoGet: TQjson;
var
  hp     : TMuHttpget;
  jobh   : THandle;
  pd     : PMPostData;
  vjs, js: TQjson;
begin
  self.FResultData.Clear;
  FStatus := 0;
  if not assigned(MuHttpPool) then
    MuHttpPool := TMuHttpPool.create(10);

  hp  := MuHttpPool.Get;
  vjs := qjsonpool.Get;
  if FDataConfig.HasChild('Values', js) then
  begin
    vjs.Assign(js);
  end;

  writeln(vjs.ToString);

  try
    if self.FInThread then
    begin
      new(pd);
      try
        pd.Data1 := hp;
        pd.Data2 := self.Params;
        jobh     := workers.Post(
          procedure(ajob: PQJob)
          var
            hp: TMuHttpget;
            pd: PMPostData;
          begin
            pd := ajob.Data;
            hp := pd.Data1;
            getdata(hp, TQjson(pd.Data2));
          end, pd, false);
        workers.WaitJob(jobh, round(self.TTimeout * 1.3), false);
      finally
        dispose(PMPostData(pd));
      end;
    end else begin
      getdata(hp, vjs);
    end;
  finally
    result := FResultData;
    qjsonpool.return(vjs);
    MuHttpPool.return(hp);
  end;
end;

function TMJsonData_Http.getdata(hp: TMuHttpget; aValue: TQjson): TQjson;
var
  respstr      : String;
  url, ParamStr: String;
begin
  ParamStr := '';
  FStatus  := -1;
  if self.FDataProp.Path <> '' then
    url := FDataProp.Path
  else
    url := FDataConfig.ValueByName('URL', '');
  if (aValue <> nil) then
    ParamStr := ParamsToUrlParams(aValue);
  FResultData.Clear;

  if ParamStr <> '' then
  begin
    if pos('?', url) > 5 then
      url := url + '&' + ParamStr
    else
      url := url + '?' + ParamStr;
  end;
  try
    respstr := hp.Get(url);
    if hp.StatusCode div 200 = 1 then
      FStatus := 1;
    if FStatus = 1 then
    begin
      FResultData.TryParse(respstr);
      result := FResultData;
    end;
  except

  end;

end;

class function TMJsonData_Http.ParamsToUrlParams(aParam: TQjson): String;
var
  js: TQjson;
begin
  result := '';
  if assigned(aParam) then
    for js in aParam do
    begin
      if result = '' then
        result := format('%s=%s', [js.Name, TnetEncoding.url.EncodeQuery(js.Value)])
      else
        result := result + '&' + format('%s=%s', [js.Name, TnetEncoding.url.EncodeQuery(js.Value)]);
    end;
end;

{ TMJsonData_MDB }

destructor TMJsonData_MDB.Destroy;
begin

  inherited;
end;

function TMJsonData_MDB.DoGetInst(aInst: TMJsonDataBase): TQjson;
begin
  result := TMJsonData_MDB(aInst).DoGet();
end;

function TMJsonData_MDB.getdata(): TQjson;
var
  bjs, ajs, cjs, js: TQjson;
  isMutiData       : boolean;
  procedure getjsdata(aConfig: TQjson; rjs: TQjson);
  var
    dbtype               : string;
    aValue, ajs, svconfig: TQjson;
  begin
    dbtype := aConfig.ValueByName('Type', 'mssql');

    if dbtype = 'mssql' then
    begin
      aValue := qjson.AcquireJson;
      try

        if aConfig.HasChild('Config', svconfig) then
        begin
          svconfig.Merge(DBServerConfig, jmmIgnore);
        end else begin
          rjs.Parse('{}');
          exit;
        end;
        if aConfig.HasChild('Value', ajs) then
        begin
          aValue.Assign(ajs);
        end else if aConfig.HasChild('Values', ajs) then
        begin
          aValue.Assign(ajs);
        end else begin

        end;
        setvalue(aValue);

        rjs.Clear;
        TMSDB.ExecJson(svconfig, aValue, rjs);

      finally

        qjson.ReleaseJson(aValue);
      end;
    end;
  end;

begin
  FResultData.Clear;
  if FDataConfig.DataType = jdtarray then
  begin
    FResultData.DataType := jdtarray;
    for cjs in FDataConfig do
      getjsdata(cjs, FResultData.Add());
  end else begin
    FDataConfig.DataType := jdtobject;

    if FDataConfig.HasChild('mutiData', bjs) then
    begin
      isMutiData := bjs.AsBoolean;
      if isMutiData then
      begin
        for cjs in FDataConfig do
        begin
          if cjs = bjs then
            continue;
          js := FResultData.Add(cjs.Name);
          getjsdata(cjs, js);
        end;
      end
      else
        getjsdata(FDataConfig, FResultData);
    end
    else
      getjsdata(FDataConfig, FResultData);
  end;
  result := FResultData;
end;

function TMJsonData_MDB.DoGet: TQjson;
var
  jobh   : THandle;
  js, vjs: TQjson;
  pd     : PMPostData;
begin
  self.FResultData.Clear;
  FStatus := 0;
  try

    if self.FInThread then
    begin
      jobh := workers.Post(
        procedure(ajob: PQJob)
        begin
          getdata();
        end, nil, false);

      workers.WaitJob(jobh, round(self.TTimeout * 1.3), false);
      // database的IO，套了一层又一层的。如果这里超时了，会造成一堆的孤魂野鬼。

    end else begin
      getdata();
    end;
  finally
    result := FResultData;
  end;
end;
{ TMJsonData_Custom }

function TMJsonData_Custom.DoGet: TQjson;
var
  jobh   : THandle;
  js, vjs: TQjson;
begin
  self.FResultData.Clear;
  FStatus := 0;
  vjs     := qjsonpool.Get;
  try
    if FDataConfig.HasChild('Values', js) then
    begin
      vjs.Assign(js);
    end;

    if self.FInThread then
    begin
      jobh := workers.Post(
        procedure(ajob: PQJob)
        var
          js: TQjson;
        begin
          js := ajob.Data;
          getdata(js);
        end, vjs, false);
      workers.WaitJob(jobh, round(self.TTimeout * 1.3), false);
    end else begin
      getdata(vjs);
    end;
  finally
    result := FResultData;
    qjsonpool.return(vjs);
  end;
end;

function TMJsonData_Custom.DoGetInst(aInst: TMJsonDataBase): TQjson;
begin
  result := TMJsonData_Custom(aInst).DoGet();
end;

function TMJsonData_Custom.getdata(aValue: TQjson): TQjson;
begin
  TMDataOrigin.ExecCustom(self.FDataProp, FResultData);
  result := FResultData;
end;

class function TMJsonDataM.create(const aMJsonDataBaseClass: TMJsonDataBaseClass; const aDataProp: TMDataProp)
  : TMJsonData;
begin
  result := TMJsonData(aMJsonDataBaseClass.create(aDataProp));
end;

class function TMJsonDataM.create(const aDataProp: TMDataProp): TMJsonData;
begin
  result := TMJsonData(JSONDataOriginAndClass[aDataProp.Origin].create(aDataProp));
end;

class procedure TMJsonDataM.RegisterMuHttpGetBaseClass(const aMJsonDataBaseClass: TMJsonDataBaseClass);
begin
  FMJsonDataBaseClass := aMJsonDataBaseClass;
end;

{ TMData }

class function TMData.getdata(const aProperty: TMDataProp; aParams: TQjson; var aData: Pointer): boolean;
var
  aDatads: TFDRdbmsDataSet;
begin
  result := false;
  case aProperty.DataType of
    mdtJson:
      result := GetJsonData(aProperty, aParams, aData);
    mdtDataset:
      begin
        result := GetDatasetData(aProperty, aParams, aDatads);
        aData  := aDatads;
      end;
    // result := GetJsonData(aProperty, aParams, aData);
  end;
end;

class function TMData.GetDatasetData(const aProperty: TMDataProp; aParams: TQjson; var aData: TFDRdbmsDataSet): boolean;
var
  aDatasetData: TMDatasetData;
begin
  // 默认数据库，其他的暂时不管了
  if aProperty.Origin <> TMDataOrigin.mdoMuDB then
    exit(false);
  // 直接数据库去读了
  aDatasetData := TMDatasetData.create(aProperty);
  try
    aData  := aDatasetData.GetDataset(aParams);
    result := aData <> nil;

  finally
    aDatasetData.Free;
  end;
end;

class function TMData.GetJsonData(const aProperty: TMDataProp; aParams: TQjson; aData: TQjson): boolean;
var
  JsonData: TMJsonData;
begin
  result := true;
  if aProperty.Origin = TMDataOrigin.mdoUnknow then
    exit(false);
  JsonData := TMJsonDataM.create(aProperty);
  try

    // JsonData.Params := aParams;
    JsonData.Get(aParams);
    aData.Assign(JsonData.ResultData);
    if JsonData.Status = 1 then
    begin
      aData.Assign(JsonData.ResultData);
    end;
  finally
    JsonData.Free;
  end;
end;

{ TMDatasetData }

class procedure TMDatasetData.getdata(aConfig, aParams: TQjson; OnEnd: TMDatasetDataGetEnd);
var
  vjs, js, svconfig: TQjson;
  ds               : TFDRdbmsDataSet;
begin

  vjs := qjsonpool.Get;
  try
    if aConfig.HasChild('Values', js) then
    begin
      vjs.Assign(js);
    end else if aConfig.HasChild('Value', js) then
    begin
      vjs.Assign(js);
    end;

    TMDatasetData.SetValueFromParam(vjs, aParams);
    if aConfig.HasChild('Config', svconfig) then
    begin
      ds := TMSDB.GetDataset(svconfig, vjs);
      if ds <> nil then
      begin
        try
          OnEnd(ds);
        finally
          TMSDB.ReturnDataset(svconfig, ds);
        end;
      end;
    end else begin
      exit;
    end;

  finally
    qjsonpool.return(vjs);
  end;
end;

function TMDatasetData.GetDataset(aParams: TQjson): TFDRdbmsDataSet;
var
  vjs, js, svconfig: TQjson;
begin
  result       := nil;
  self.FParams := aParams;
  vjs          := qjsonpool.Get;
  try
    if FDataConfig.HasChild('Values', js) then
    begin
      vjs.Assign(js);
    end;

    self.setvalue(vjs);
    if FDataConfig.HasChild('Config', svconfig) then
    begin
      result := TMSDB.GetDataset(svconfig, vjs);
    end else begin
      exit;
    end;

  finally
    qjsonpool.return(vjs);
  end;
end;

procedure TMDatasetData.ReturnDataset(ads: TFDRdbmsDataSet);
begin
  TMSDB.ReturnDataset(FDataConfig, ads);
end;

initialization

finalization

end.
