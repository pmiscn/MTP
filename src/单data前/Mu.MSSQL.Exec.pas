unit Mu.MSSQL.Exec;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.netencoding, System.Classes, Vcl.Graphics,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys.MSSQL, FireDAC.Moni.RemoteClient,
  FireDAC.Phys, FireDAC.Stan.Intf, FireDAC.Stan.ExprFuncs, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.Client, Data.DB, FireDAC.Comp.DataSet, FireDAC.Phys.ODBCWrapper, FireDAC.Phys.ODBCCli,
  Data.DBXDataSets,
  unit_logs, qjson, Mu.DBHelp, qstring, qworker, Mu.Pool.qjson;

type
  TOnEnd     = procedure(Sender: TObject; aDoCount: Int64) of object;
  TOnProcess = procedure(Sender: TObject; aTotalCount, aDoCount: Int64; var continue: boolean) of object;

type
  TODBCStatementBase_ = class helper for TODBCStatementBase
    function MoreResults: boolean;
  end;

type

  TMuMSSQLExecBase = class(TMlog)
    protected
      FProcessPerCount: integer;
      FIsAbort        : boolean;
      FOnEnd          : TOnEnd;
      FOnProcess      : TOnProcess;
    public
      constructor Create();
      destructor Destroy; override;

      function InitProc(Proc: TFDStoredProc; aProcName: String; AParameDemo: TQJson; var aErrStr: String): boolean;

      function GetOneSQLDBHelp(Sv: TQJson): TSQLDBHelp; overload;
      function GetOneSQLDBHelp(aServer, aUser, aPwd, aDbName: String): TSQLDBHelp; overload;
      property OnEnd: TOnEnd read FOnEnd write FOnEnd;
      property ProcessPerCount: integer read FProcessPerCount write FProcessPerCount;
      property OnProcess: TOnProcess read FOnProcess write FOnProcess;

      class function datasetToJson(ds: TFDRdbmsDataSet; aResult: TQJson): integer;

    public

  end;

  TMuMSSQLExec_Json = class(TMuMSSQLExecBase)
    protected

    protected

    public

      /// 保存数据到数据库，下面是Config参数,默认数据库参数都是对的
      /// Server:{Server:"127.0.0.1,1433",Username:"sa",Password:"sa",Database:"master",},
      /// SQL:"DomainDropped.dbo.P_DomainDropped_add",
      /// Type:"proc",
      /// Parames:[
      /// {Name:"@Domain",Type:"varchar",Length: 100,Value:""},
      /// {Name:"@DDate",Type:"date",Length:0,Value:""}
      /// {Name:"@Result",Type:"varchar",Length:1000,Direction:"output" }
      /// ]
      /// 下面是值的
      ///
      ///
      ///
      ///
      ///

      function ExecProc_Dateset(aConfig: TQJson; ParamsFields: TQJson; aDs: TDataset; var aErrStr: String): string;

      function Exec(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String): string; overload;
      function Exec(const aConfig: TQJson; const aValue: String; var aErrStr: String): string; overload;
      function Exec(const aConfig: String; const aValue: String; var aErrStr: String): string; overload;

      // 入口
      function ExecJson(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String; aResult: TQJson)
        : boolean; overload;

      function ExecJson(const aConfig: TQJson; const aValue: String; var aErrStr: String; aResult: TQJson)
        : boolean; overload;

      function ExecJson(const aConfig: String; const aValue: String; var aErrStr: String; aResult: TQJson)
        : boolean; overload;

      function ExecProc(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String): String; overload;
      function ExecProcJson(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String; aResult: TQJson)
        : boolean; overload;
      function ExecProcJson(const aServer, aUser, aPwd, aDbName, aProc: String; const aValue: TQJson;
        var aErrStr: String; aResult: TQJson): boolean; overload;

      function ExecSQL(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String): String;
      function ExecSQLJson(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String; aResult: TQJson)
        : boolean; overload;
      function ExecSQLJson(const aServer, aUser, aPwd, aDbName, aSql: String; const aValue: TQJson; var aErrStr: String;
        aResult: TQJson): boolean; overload;

      function JSONResult_proc(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String): String;
      function JSONResult_procJson(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String;
        aResult: TQJson): boolean;

      function JSONResult_SQL(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String): String;
      function JSONResult_SQLJson(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String;
        aResult: TQJson): boolean;

      function JSONResult(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String): String;
      function JSONResultJson(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String;
        aResult: TQJson): boolean;

      function OpenQuery(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String): TFDQuery;

      procedure stop();

  end;

  TMuMSSQLExec = TMuMSSQLExec_Json;

  TMuMSSQLExec_Ds = class(TMuMSSQLExecBase)
    public
      function GetProc(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String): TFDStoredProc;
      function GetQuery(const aConfig: TQJson; const aValue: TQJson; var aErrStr: String): TFDQuery; overload;
      function GetQuery(const aServer, aUser, aPwd, aDbName, aSql: String; const aValue: TQJson; var aErrStr: String)
        : TFDQuery; overload;

      procedure returnProc(const aConfig: TQJson; Proc: TFDStoredProc);
      procedure returnQuery(const aConfig: TQJson; aQuery: TFDQuery);
      procedure returnDataset(const aConfig: TQJson; aQuery: TFDRdbmsDataSet);

  end;

implementation

constructor TMuMSSQLExecBase.Create;
begin
  FIsAbort         := false;
  FProcessPerCount := 10;
end;

class function TMuMSSQLExecBase.datasetToJson(ds: TFDRdbmsDataSet; aResult: TQJson): integer;
var
  tbjs: TQJson;
  procedure AddFields(js: TQJson);
  var
    i : integer;
    fd: TField;
  begin
    with js.Add('Fields') do
    begin
      datatype := jdtobject;
      for i    := 0 to ds.FieldCount - 1 do
      begin
        fd := ds.Fields[i];
        with Add(fd.FieldName) do
        begin
          datatype                  := jdtobject;
          Add('Size').AsInteger     := fd.Size;
          Add('FullName').AsString  := fd.FullName;
          Add('FieldName').AsString := fd.FieldName;
          Add('FieldNo').AsInteger  := fd.FieldNo;
          Add('Origin').AsString    := fd.Origin;
        end;
      end;
    end;
  end;

  procedure addone();
  var
    i  : integer;
    rjs: TQJson;
    fd : TField;
  begin
    rjs := tbjs.Add;
    AddFields(rjs);
    with rjs.Add('Data') do
    begin
      datatype := jdtarray;
      ds.first;
      while not ds.Eof do
      begin
        with Add() do
        begin
          datatype := jdtarray;
          for i    := 0 to ds.FieldCount - 1 do
          begin
            fd := ds.Fields[i];
            case fd.datatype of
              ftWideMemo, ftWideString, ftString, ftMemo, ftFixedChar, ftFixedWideChar:
                begin
                  Add().AsString := fd.AsString;
                end;
              ftSmallint, ftInteger, ftWord, ftLongWord, ftShortint, ftByte:
                Add().AsInteger := fd.AsInteger;
              ftBoolean:
                Add().AsBoolean := fd.AsBoolean;
              ftFloat, ftSingle, ftCurrency, ftExtended:
                Add().AsFloat := fd.AsFloat;
              ftDate, ftTime, ftDateTime, ftTimeStamp, ftOraTimeStamp:
                Add().AsDateTime := fd.AsDateTime;
              ftBCD:
                Add().AsBcd := fd.AsBcd;
              ftBlob, ftGraphic, ftOraBlob:
                Add().AsBase64Bytes := fd.AsBytes; // TNetEncoding.Base64.Encode(fd.AsBytes);
              ftArray:
                Add().AsString := StringOf(fd.AsBytes);
            else
              addvariant('', fd.AsVariant);
            end;

            { ftUnknown, , ftSmallint, // 0..4
              , ,  , , , // 5..11
              ftBytes, ftVarBytes, ftAutoInc, ,  , , ftFmtMemo, // 12..18
              ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, , // 19..24
              ftLargeint, ftADT, , ftReference, ftDataSet, , ftOraClob, // 25..31
              ftVariant, ftInterface, ftIDispatch, ftGuid, , ftFMTBcd, // 32..37
              , , , ftOraInterval, // 38..41
              , ftConnection, ftParams, ftStream, //42..48
              ftTimeStampOffset, ftObject, }
          end;

        end;
        ds.Next;
      end;
    end;
  end;

begin
  aResult.Clear;
  tbjs := aResult.AddArray('Tables');

  while ds.Active do
  begin
    addone();
    ds.NextRecordSet;
  end;
end;

destructor TMuMSSQLExecBase.Destroy;
var
  i: integer;
begin
  FIsAbort := true;
  inherited;

end;

function TMuMSSQLExecBase.GetOneSQLDBHelp(aServer, aUser, aPwd, aDbName: String): TSQLDBHelp;
begin
  result := SQLDBHelps.get(aServer, aUser, aPwd, aDbName);
end;

function TMuMSSQLExecBase.InitProc(Proc: TFDStoredProc; aProcName: String; AParameDemo: TQJson;
  var aErrStr: String): boolean;
var
  i: integer;
  function checkparams(): boolean;
  var
    i: integer;
  begin
    result := true;

    if Proc.Params.Count < AParameDemo.Count then
    begin
      // exit(false);
    end;
    for i := 0 to Proc.Params.Count - 1 do
    begin
      if not(Proc.Params[i].ParamType in [ptResult, ptOutput, ptInputOutput]) then
      begin
        if (not AParameDemo.Exists(Proc.Params[i].Name)) and
          (not AParameDemo.Exists(Proc.Params[i].Name.Replace('@', ''))) then
        begin
          log('check params %s,Param not exists:%s', [aProcName, Proc.Params[i].Name], 0);

          result := false;
          exit(false);
        end;
      end;
    end;
  end;

begin
  result := false;
  try
    if not Proc.Connection.Connected then
    begin
      log('开始打开链接', 9);
      // log(llmessage, Proc.Connection.ConnectionString);
      Proc.Connection.Connected := true;
    end;
  except
    on e: exception do
    begin
      aErrStr := format('proc.StoredProcName Connection.Connected 1 %s ', [e.message]);
      exit;
    end;
  end;

  if Proc.Tag > 2000 then
  begin
    exit(true);
  end;

  i := 0;

  Proc.Prepared := false;
  while (i < 5) and (not Proc.Prepared) do
  begin
    try
      log('proc.Prepare repeat:%d', [i + 1], 9);

      Proc.StoredProcName := aProcName;
      Proc.Prepare;

      if (checkparams) then
        break;
      inc(i);
      sleep(100);
    except
      on e: exception do
      begin
        aErrStr := format('proc.StoredProcName Prepare repeat 2 %s ', [e.message]);
        exit;
      end;
    end;
  end;
  log('ProcName:%s,StoredProcName:%s,Params:%d', [Proc.Name, Proc.StoredProcName, Proc.Params.Count]);

  if not Proc.Prepared then
  begin
    log('Procedure %s is not prepared', [Proc.Name], 7);

  end;

  for i := 0 to Proc.Params.Count - 1 do
  begin
    if Proc.Params[i].ParamType in [ptOutput, ptInputOutput] then
      if Proc.Params[i].datatype in [ftWideMemo, ftFmtMemo, ftMemo] then
      begin
        Proc.Tag := 2001;
        break;
      end;
  end;

  log('InitProc end');
  result := true;
end;

function TMuMSSQLExecBase.GetOneSQLDBHelp(Sv: TQJson): TSQLDBHelp;
begin
  result := SQLDBHelps.get(Sv);
end;

{ TMuMSSQLExec }

function TMuMSSQLExec_Json.Exec(const aConfig, aValue: TQJson; var aErrStr: String): string;
var
  rjs: TQJson;
begin
  rjs := qjsonPool.get;
  try
    if ExecJson(aConfig, aValue, aErrStr, rjs) then
      result := rjs.ToString;
  finally
    qjsonPool.return(rjs);
  end;
end;

function TMuMSSQLExec_Json.Exec(const aConfig: TQJson; const aValue: String; var aErrStr: String): string;
var
  rjs: TQJson;
begin
  rjs := qjsonPool.get;
  try
    rjs.Parse(aValue);
    if ExecJson(aConfig, aValue, aErrStr, rjs) then
      result := rjs.ToString;
  finally
    qjsonPool.return(rjs);
  end;
end;

function TMuMSSQLExec_Json.Exec(const aConfig, aValue: String; var aErrStr: String): string;
var
  rjs: TQJson;
begin
  rjs := qjsonPool.get;
  try
    if ExecJson(aConfig, aValue, aErrStr, rjs) then
      result := rjs.ToString;
  finally
    qjsonPool.return(rjs);
  end;
end;

function TMuMSSQLExec_Json.ExecJson(const aConfig, aValue: TQJson; var aErrStr: String; aResult: TQJson): boolean;
var
  tp         : String;
  js         : TQJson;
  FRetryTimes: integer;
begin
  aErrStr := '';

  tp               := aConfig.ValueByName('Type', 'SQL');
  FProcessPerCount := aConfig.IntByName('ProcessPerCount', FProcessPerCount);
  if tp.ToLower.IndexOf('json') > -1 then
  begin
    result := JSONResultJson(aConfig, aValue, aErrStr, aResult);
  end else if (tp.ToLower() = 'proc') or (tp.ToLower() = 'procedure') then
  begin
    FRetryTimes := 0;
    log('ExecProc');
    try
      result := ExecProcJson(aConfig, aValue, aErrStr, aResult);
    except
      on e: exception do
      begin
        aErrStr := format('TMuMSSQLExec_Json.ExecJson ExecProc exception 1:%s', [e.message]);
        log(aErrStr, 0);
        if aConfig.HasChild('Exception', js) then
        begin
          if js.IntByName('Retry', 0) > FRetryTimes then
          begin
            inc(FRetryTimes);
            sleep(js.IntByName('Sleep', 3) * 1000);
            result := self.ExecProcJson(aConfig, aValue, aErrStr, aResult);
            exit;
          end;
        end;
      end;
    end;
  end else begin
    try
      result := self.ExecSQLJson(aConfig, aValue, aErrStr, aResult);
    except
      on e: exception do
      begin
        aErrStr := format('TMuMSSQLExec_Json.ExecJson ExecSQL exception 2:%s', [e.message]);
        log(aErrStr, 0);
        if aConfig.HasChild('Exception', js) then
        begin
          if js.IntByName('Retry', 0) > FRetryTimes then
          begin
            inc(FRetryTimes);
            sleep(js.IntByName('Sleep', 3) * 1000);
            result := self.ExecSQLJson(aConfig, aValue, aErrStr, aResult);
            exit;
          end;
        end;
      end;
    end;
  end;
end;

function TMuMSSQLExec_Json.ExecJson(const aConfig: TQJson; const aValue: String; var aErrStr: String;
  aResult: TQJson): boolean;
var
  vjs: TQJson;
begin
  vjs := qjsonPool.get;
  try
    vjs.Parse(aValue);
    result := ExecJson(aConfig, vjs, aErrStr, aResult);
  finally
    qjsonPool.return(vjs);
  end;
end;

function TMuMSSQLExec_Json.ExecJson(const aConfig, aValue: String; var aErrStr: String; aResult: TQJson): boolean;
var
  vjs, cjs: TQJson;
begin
  vjs := qjsonPool.get;
  cjs := qjsonPool.get;
  try
    vjs.Parse(aValue);
    cjs.Parse(aConfig);
    result := ExecJson(cjs, vjs, aErrStr, aResult);
  finally
    qjsonPool.return(vjs);
    qjsonPool.return(cjs);
  end;
end;

function TMuMSSQLExec_Json.ExecSQL(const aConfig, aValue: TQJson; var aErrStr: String): String;
var
  rjs: TQJson;
begin
  aErrStr := '';
  result  := '';
  rjs     := qjsonPool.get;
  try
    ExecSQLJson(aConfig, aValue, aErrStr, rjs);
  finally
    result := rjs.ToString();
    qjsonPool.return(rjs);
  end;
end;

function TMuMSSQLExec_Json.ExecSQLJson(const aServer, aUser, aPwd, aDbName, aSql: String; const aValue: TQJson;
  var aErrStr: String; aResult: TQJson): boolean;
var
  FQ           : TFDQuery;
  pjs          : TQJson;
  i, c, succ, l: integer;

  es: String;

  aSQLDBHelp: TSQLDBHelp;
  aContinue : boolean;
  function doOne(aValue: TQJson; R: TQJson): boolean;
  var
    i    : integer;
    pname: String;
  begin
    result := false;
    if (FQ.SQL.Text <> aSql) then
    begin
      FQ.SQL.Text := aSql;
      // FQ.Prepare;
    end else if FQ.Params.Count <> aValue.Count then
    begin
      FQ.Prepare;
    end;
    if FQ.Params.Count <> pjs.Count then
    begin
      aErrStr := 'SQL的参数和配置文件的参数数目不一样.';
      exit;
    end;
    for i := 0 to aValue.Count - 1 do
    begin
      pname := aValue[i].Name;
      with FQ.Params.ParamByName(pname) do
        case datatype of
          ftString, ftFixedChar, ftWideString, ftFixedWideChar:
            begin
              l  := Size;
              es := aValue[i].AsString;
              if l < es.Length then
              begin
                log('%s 长度截断了 %d/%d', [pname, l, es.Length], 6);
                es := copy(es, 1, l);
              end;
              AsString := es;
            end;
          // AsString := aValue[i].AsString;
          // ftWideString:
          // AsWideString := aValue[i].AsString;
          ftWideMemo:
            begin
              asWideMemo := aValue[i].AsString;
            end;
          ftFmtMemo, ftMemo:
            asMemo := aValue[i].AsString;

          ftInteger:
            AsInteger := aValue[i].AsInteger;
          ftSmallint:
            AsSmallInt := aValue[i].AsInteger;
          ftShortint:
            AsShortInt := aValue[i].AsInteger;
          ftWord:
            AsWord := aValue[i].AsInteger;
          ftLargeint:
            AsLargeInt := aValue[i].AsInt64;
          ftLongWord:
            AsLongword := aValue[i].AsInt64;

          ftDate:
            asDate := aValue[i].AsDateTime;
          ftTime:
            astime := aValue[i].AsDateTime;
          ftDateTime:
            AsDateTime := aValue[i].AsDateTime;
          // ftTimeStamp:
          // AsSQLTimeStamp := aValue[i].asDatetime;

          ftBoolean:
            AsBoolean := aValue[i].AsBoolean;

          ftFloat:
            AsFloat := aValue[i].AsFloat;
          ftCurrency:
            asCurrency := aValue[i].AsFloat;
          ftExtended:
            asExtended := aValue[i].AsFloat;
          ftSingle:
            asSingle := aValue[i].AsFloat;

        else
          value := aValue[i].AsVariant;
        end;

      // FQ.Params.ParamByName(pname).Value := aValue[i].AsVariant;
    end;
    try
      FQ.ExecSQL;
      result := true;
      with (R.Add()) do
      begin
        for i := 0 to FQ.Params.Count - 1 do
        begin
          addvariant(FQ.Params[i].Name, FQ.Params[i].value);
        end;
      end;

    except
      on e: exception do
      begin
        // if aErrStr <> '' then
        // aErrStr := aErrStr + #13#10;
        aErrStr  := aValue.Encode(false) + ' TMuMSSQLExec_Json.ExecSQLJson do one ExecSQL ' + e.message;
        FIsAbort := true;
      end;
    end;
  end;

begin
  aErrStr := '';
  result  := false;
  succ    := 0;
  try
    try

      aSQLDBHelp := GetOneSQLDBHelp(aServer, aUser, aPwd, aDbName);
      FQ         := aSQLDBHelp.getCusQuery(aSql);

    except
      on e: exception do
      begin
        aErrStr := e.message;
      end;
    end;
    // 此时获取到的，默认是服务器没有更改参数。如果更改了，就自动获取。

    // 数据格式，默认都是对的  bin image text暂时不支持，可以到parames字段的类型读取
    FIsAbort         := false;
    aResult.datatype := jdtarray;

    if aValue.datatype = jdtarray then
    begin
      c     := aValue.Count;
      for i := 0 to c - 1 do
      begin
        if FIsAbort then
          break;
        if doOne(aValue[i], aResult) then
          inc(succ);

        if (i mod FProcessPerCount = 0) or (i = c - 1) then
          if assigned(FOnProcess) then
          begin
            FOnProcess(self, c, i + 1, aContinue);
            if not aContinue then
              break;
          end;
      end;
      if assigned(FOnProcess) then
      begin
        FOnProcess(self, c, c, aContinue);
        if not aContinue then
          exit;
      end;
    end else begin
      c := 1;
      if doOne(aValue, aResult) then
        inc(succ);

      if assigned(FOnProcess) then
      begin
        FOnProcess(self, c, i + 1, aContinue);
        if not aContinue then
          exit;
      end;
    end;

    if assigned(FOnEnd) then
      FOnEnd(self, c);

    result := succ > 0;
  finally

    aSQLDBHelp.returnCusQuery(aSql, FQ);

  end;

end;

function TMuMSSQLExec_Json.ExecSQLJson(const aConfig, aValue: TQJson; var aErrStr: String; aResult: TQJson): boolean;
var
  Sv  : TQJson;
  aSql: String;
begin
  // logs.Post(lldebug, 'execproc save value %s ', [aValue.ToString]);
  try
    Sv     := aConfig.ItemByName('Server');
    aSql   := aConfig.ItemByName('SQL').AsString;
    result := ExecSQLJson(Sv.ItemByName('Server').AsString, Sv.ItemByName('Username').AsString,
      Sv.ItemByName('Password').AsString, Sv.ItemByName('Database').AsString, aSql, aValue, aErrStr, aResult);
  finally

  end;
end;

function TMuMSSQLExec_Json.ExecProc(const aConfig, aValue: TQJson; var aErrStr: String): String;
var
  rjs: TQJson;
begin
  aErrStr := '';
  result  := '{}';
  rjs     := qjsonPool.get;
  try
    if ExecProcJson(aConfig, aValue, aErrStr, rjs) then
    begin
    end;
  finally
    result := rjs.ToString();
    qjsonPool.return(rjs);
  end;
end;

function TMuMSSQLExec_Json.ExecProcJson(const aServer, aUser, aPwd, aDbName, aProc: String; const aValue: TQJson;
  var aErrStr: String; aResult: TQJson): boolean;
var
  Proc            : TFDStoredProc;
  pjs             : TQJson;
  i, j, c, succ, l: integer;
  // rjs: TQJson;
  tmpjs: TQJson;
  es   : String;

  pname      : string;
  aSQLDBHelp : TSQLDBHelp;
  aContinue  : boolean;
  needSeconds: boolean;
  needPrepare: boolean;

  function doOne(aValue: TQJson; R: TQJson): boolean;
  var
    i   : integer;
    tmps: String;
  begin
    result := false;

    for i := 0 to Proc.Params.Count - 1 do
    begin
      if not(Proc.Params[i].ParamType in [ptResult, ptOutput, ptInputOutput]) then
      begin
        pname := Proc.Params[i].Name;

        if not(aValue.Exists(pname) or (aValue.Exists(pname.Replace('@', '')))) then
        begin

          aErrStr := format('%s 参数 (%d)"%s"没有值！%s', [Proc.Name, i, pname, aValue.ToString]);

          exit;
        end;
      end else if Proc.Params[i].ParamType in [ptOutput, ptInputOutput] then
        case Proc.Params[i].datatype of
          ftWideMemo, ftFmtMemo, ftMemo:
            begin // 必须设置为null，不然会造成参数冲突。
              Proc.Params[i].value := null;
            end;
          ftString, ftFixedChar, ftWideString, ftFixedWideChar:
            Proc.Params[i].value := '';
        end;
    end;
    try
      // messagebox(0, pchar(aValue.ToString), pchar(''), 0);
      for i := 0 to aValue.Count - 1 do
      begin
        pname := aValue[i].Name;

        if copy(pname, 1, 1) <> '@' then
          pname := '@' + pname;
        { ftUnknown, ftString, ftSmallint, ftInteger, ftWord, // 0..4
          ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime, // 5..11
          ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo, // 12..18
          ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftWideString, // 19..24
          ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob, // 25..31
          ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd, // 32..37
          ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval, // 38..41
          ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream, //42..48
          ftTimeStampOffset, ftObject, ftSingle }

        with Proc.Params.ParamByName(pname) do
          case datatype of
            // ftString, ftWideString:
            ftString, ftFixedChar, ftWideString, ftFixedWideChar:
              begin
                l  := Size;
                es := aValue[i].AsString;
                if l < es.Length then
                begin
                  log('%s 长度截断了 %d/%d', [pname, l, es.Length], 8);
                  es := copy(es, 1, l);
                end;
                AsString := es;
              end;

            // ftWideString:
            // AsWideString := aValue[i].AsString;
            ftWideMemo:
              asWideMemo := aValue[i].AsString;
            ftFmtMemo, ftMemo:
              asMemo := aValue[i].AsString;
            ftInteger:
              AsInteger := aValue[i].AsInteger;
            ftSmallint:
              AsSmallInt := aValue[i].AsInteger;
            ftShortint:
              AsShortInt := aValue[i].AsInteger;
            ftWord:
              AsWord := aValue[i].AsInteger;
            ftLargeint:
              AsLargeInt := aValue[i].AsInt64;
            ftLongWord:
              AsLongword := aValue[i].AsInt64;

            ftDate:
              asDate := aValue[i].AsDateTime;
            ftTime:
              astime := aValue[i].AsDateTime;
            ftDateTime:
              AsDateTime := aValue[i].AsDateTime;
            // ftTimeStamp:
            // AsSQLTimeStamp := aValue[i].asDatetime;

            ftBoolean:
              AsBoolean := aValue[i].AsBoolean;

            ftFloat:
              AsFloat := aValue[i].AsFloat;
            ftCurrency:
              begin
                asCurrency := aValue[i].AsFloat;
              end;
            ftExtended:
              asExtended := aValue[i].AsFloat;
            ftSingle:
              asSingle := aValue[i].AsFloat;
          else
            value := aValue[i].AsVariant;
          end;


        // Proc.Params.ParamByName(pname).Value := aValue[i].AsVariant;

      end;
    except
      on e: exception do
      begin
        aErrStr := format('TMuMSSQLExec_Json.ExecProcJson doone2, Proc Params set value 3,%s %s',
          [aValue.Encode(false), e.message]);
        log('%s', [aErrStr], 0);
      end;
    end;
    try
      // logs.Post(lldebug, 'Proc.ExecProc %s', [aValue.encode(false)]);
      // if needRepared then
      // Proc.Prepare;

      Proc.ExecProc;

      // logs.Post(lldebug, 'Proc.ExecProc End');
      result := true;
      with (R.Add()) do
      begin
        for i := 0 to Proc.Params.Count - 1 do
        begin
          if Proc.Params[i].ParamType in [ptResult, ptOutput, ptInputOutput] then
          begin

            case Proc.Params[i].datatype of
              ftString, ftFixedChar, ftWideString, ftFixedWideChar:
                begin
                  // tmps := Proc.Params[i].Name;
                  tmps := (Proc.Params[i].AsString);
                  // logs.Post(llmessage, '%s:%s', [Proc.Params[i].Name, tmps]);
                  addvariant(Proc.Params[i].Name, tmps);
                end;
              ftWideMemo:
                begin
                  tmps := Proc.Params[i].asWideMemo;
                  // logs.Post(llmessage, 'ftWideMemo:%s', [tmps]);
                  addvariant(Proc.Params[i].Name, tmps);
                end;
              ftMemo:
                begin
                  tmps := Proc.Params[i].asMemo;
                  // logs.Post(llmessage, 'asMemo:%s', [tmps]);
                  addvariant(Proc.Params[i].Name, tmps);
                end
            else
              addvariant(Proc.Params[i].Name, (Proc.Params[i].value));
            end;
          end;
        end;
      end;
      // logs.Post(lldebug, 'Proc.ExecProc End 2');
    except
      on e: exception do
      begin
        // if aErrStr <> '' then
        // aErrStr := aErrStr + #13#10;
        // messagebox(0,pchar( e.message),'',0);
        aErrStr := aValue.Encode(false) + 'TMuMSSQLExec_Json.ExecProcJson doone2, ExecProc ' + e.message;
        log('%s', [aErrStr], 0);
        // self.FIsAbort := true;
      end;
    end;
  end;

begin
  aErrStr := '';
  result  := false; // '{}';

  aResult.Clear;
  succ        := 0;
  needSeconds := false;
  needPrepare := true;

  // logs.Post(lldebug, 'execproc save value %s ', [aValue.ToString]);

  try
    try

      // logs.Post(llhint, '需要执行的语句是:%s', [aSql]);

      aSQLDBHelp := GetOneSQLDBHelp(aServer, aUser, aPwd, aDbName);
      log('get SQLDBHelp %s %d', [aSQLDBHelp.server, aSQLDBHelp.ID], 9);

      if aSQLDBHelp = nil then
      begin
        aErrStr := format('无法获取服务器信息:%s', [aServer]);

        log(aErrStr, 8);
        exit;
      end;

    except
      on e: exception do
      begin
        aErrStr := e.message;
        log('TMuMSSQLExec_Json.ExecProcJson GetOneSQLDBHelp %s', [aErrStr], 0);
        exit;
      end;
    end;

    try
      Proc := aSQLDBHelp.getCusProc(aProc);
    except
      on e: exception do
      begin
        aErrStr := e.message;
        log('TMuMSSQLExec_Json.ExecProcJson getCusProc %s', [aErrStr], 0);
        exit;
      end;

    end;

    try
      tmpjs := aValue;
      if aValue.datatype = jdtarray then
        if aValue.Count > 0 then
          tmpjs := aValue[0];

      if not self.InitProc(Proc, aProc, tmpjs, aErrStr) then
      begin
        log('InitProc Error 1 %s', [aErrStr], 0);
        exit;
      end;
    except
      on e: exception do
      begin
        aErrStr := e.message;
        log('InitProc %s', [aErrStr], 0);
      end;
    end;
    aResult.datatype := jdtarray;
    aResult.Clear;
    if aValue.datatype = jdtarray then
    begin
      c := aValue.Count;
      log('aValue.Count:=%d', [c], 0);
      aContinue := true;
      for i     := 0 to c - 1 do
      begin
        if FIsAbort then
          break;
        if (aErrStr = '') then
        begin
          if doOne(aValue[i], aResult) then
          begin
            inc(succ);
            if Proc.Tag = 2001 then
            begin
              Proc.Tag := 2002;
              aResult.Clear;
              doOne(aValue[i], aResult);
            end;
          end;
          if ((i + 1) mod FProcessPerCount = 0) or (i = c - 1) then
            if assigned(FOnProcess) then
            begin
              FOnProcess(self, c, i + 1, aContinue);
              // log(lldebug, 'FOnProcess End');
              if not aContinue then
              begin
                log('not aContinue exit', 0);
                exit;
              end;
              if aErrStr <> '' then
                log('aErrStr:%s', [aErrStr], 0);
            end;
        end;
      end;
      if assigned(FOnProcess) then
      begin
        FOnProcess(self, c, c, aContinue);
        if not aContinue then
      end;

    end else begin
      c := 1;

      if doOne(aValue, aResult) then
      begin
        inc(succ);
        if Proc.Tag = 2001 then
        begin
          Proc.Tag := 2002;
          aResult.Clear;
          doOne(aValue, aResult);
        end;
      end;
    end;
    if assigned(FOnEnd) then
      FOnEnd(self, c);
    log('执行成功：%d', [succ], 0);
    result := succ > 0;
  finally
    // result := rjs.ToString();

    try
      aSQLDBHelp.returnCusProc(aProc, Proc);

    except
      on e: exception do
      begin
        log('TMuMSSQLExec_Json.ExecProcJson returnCusProc(aSql, Proc):%s', [e.message], 0);
      end;
    end;
  end;

end;

function TMuMSSQLExec_Json.ExecProcJson(const aConfig, aValue: TQJson; var aErrStr: String; aResult: TQJson): boolean;
var
  Sv  : TQJson;
  aSql: String;
begin
  // logs.Post(lldebug, 'execproc save value %s ', [aValue.ToString]);
  try
    Sv     := aConfig.ItemByName('Server');
    aSql   := aConfig.ItemByName('SQL').AsString;
    result := ExecProcJson(Sv.ItemByName('Server').AsString, Sv.ItemByName('Username').AsString,
      Sv.ItemByName('Password').AsString, Sv.ItemByName('Database').AsString, aSql, aValue, aErrStr, aResult);
  finally
  end;
end;

function TMuMSSQLExec_Json.ExecProc_Dateset(aConfig: TQJson; ParamsFields: TQJson; aDs: TDataset;
  var aErrStr: String): string;
var
  Proc                : TFDStoredProc;
  pjs                 : TQJson;
  i, j, c, succ, l    : integer;
  rjs                 : TQJson;
  es                  : String;
  server, aSql, fdName: String;
  pname               : string;
  aSQLDBHelp          : TSQLDBHelp;
  aContinue           : boolean;
  aFDParam            : TFDParam;
  afd                 : TField;
begin

  aErrStr := '';
  result  := '';
  rjs     := qjsonPool.get;
  rjs.Clear;

  succ := 0;

  try
    try
      aSql := aConfig.ItemByName('SQL').AsString;
      // log(llhint, '需要执行的语句是:%s', [aSql]);

      aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
      log('get SQLDBHelp %s %d', [aSQLDBHelp.server, aSQLDBHelp.ID], 7);

      if aSQLDBHelp = nil then
      begin
        aErrStr := format('无法获取服务器信息:%s', [aConfig.ItemByName('Server')]);

        log(aErrStr, 7);
        exit;
      end;

    except
      on e: exception do
      begin
        aErrStr := e.message;
        log('TMuMSSQLExec_Json.ExecProc_Dateset GetOneSQLDBHelp %s', [aErrStr], 0);
        exit;
      end;
    end;

    try
      Proc := aSQLDBHelp.getCusProc(aSql);
    except
      on e: exception do
      begin
        aErrStr := e.message;
        log('getCusProc %s', [aErrStr], 0);
        exit;
      end;
    end;

    if not InitProc(Proc, aSql, ParamsFields, aErrStr) then
    begin
      log('InitProc Error 2 %s', [aSql], 0);
      exit;
    end;
    c := aDs.RecordCount;

    log('Start saving recordcount %d', [c], 0);
    j    := 0;
    succ := 0;
    aDs.first;
    rjs.datatype := jdtarray;
    aContinue    := true;
    while (not aDs.Eof) and (not self.FIsAbort) do
    begin
      inc(j);
      try
        for i := 0 to ParamsFields.Count - 1 do
        begin
          fdName := ParamsFields[i].AsString;
          if aDs.FindField(fdName) = nil then
            continue;
          afd   := aDs.FieldByName(fdName);
          pname := ParamsFields[i].Name;
          if copy(pname, 1, 1) <> '@' then
            pname  := '@' + pname;
          aFDParam := Proc.Params.ParamByName(pname);
          with aFDParam do
            case datatype of
              ftString, ftFixedChar, ftWideString, ftFixedWideChar:
                begin
                  l  := Size;
                  es := afd.AsString;
                  if l < es.Length then
                  begin
                    log('%s 长度截断了 %d/%d', [pname, l, es.Length], 0);
                    es := copy(es, 1, l);
                  end;
                  AsString := es;
                end;
              // ftWideString:
              // AsWideString := afd.AsString;
              ftInteger:
                AsInteger := afd.AsInteger;
              ftSmallint:
                AsSmallInt := afd.AsInteger;
              ftShortint:
                AsShortInt := afd.AsInteger;
              ftWord:
                AsWord := afd.AsInteger;
              ftLargeint:
                AsLargeInt := afd.AsLargeInt;
              ftLongWord:
                AsLongword := afd.AsLongword;
              ftDate:
                asDate := afd.AsDateTime;
              ftTime:
                astime := afd.AsDateTime;
              ftDateTime:
                AsDateTime := afd.AsDateTime;
              // ftTimeStamp:
              // AsSQLTimeStamp := aValue[i].asDatetime;
              ftBoolean:
                AsBoolean := afd.AsBoolean;
              ftFloat:
                AsFloat := afd.AsFloat;
              ftCurrency:
                asCurrency := afd.AsFloat;
              ftExtended:
                asExtended := afd.AsFloat;
              ftSingle:
                asSingle := afd.AsFloat;

            else
              value := afd.AsVariant;
            end;
          // Proc.Params.ParamByName(pname).Value := aValue[i].AsVariant;
        end;
        {
          Proc.Params.ParamByName(pname).Value :=
          aDs.FieldByName(ParamsFilds[i].AsString).AsVariant;
        }

      except
        on e: exception do
        begin
          aErrStr := e.message;
          log(aErrStr, 0);
        end;
      end;
      try
        Proc.ExecProc;
        inc(succ);
        // log(llmessage, '  saving  end %d', [j]);
        with (rjs.Add()) do
        begin
          for i := 0 to Proc.Params.Count - 1 do
          begin
            if Proc.Params[i].ParamType in [ptResult, ptOutput, ptInputOutput] then
            begin
              addvariant(Proc.Params[i].Name, Proc.Params[i].value);

              // log(llmessage, '%s', [Proc.Params[i].Value]);
            end;
          end;
        end;
        if ((j) mod FProcessPerCount = 0) or (j = c - 1) then
          if assigned(FOnProcess) then
          begin
            FOnProcess(self, c, j, aContinue);
            if not aContinue then
              exit;
          end;
      except
        on e: exception do
        begin
          // if aErrStr <> '' then
          // aErrStr := aErrStr + #13#10;
          aErrStr := e.message;
          log(aErrStr, 0);
          // self.FIsAbort := true;
        end;
      end;
      aDs.Next();
    end;

    log('执行成功：%d', [succ], 5);
    try
      if assigned(FOnProcess) then
      begin
        FOnProcess(self, c, c, aContinue);
        if not aContinue then
          exit;
      end;

      if assigned(FOnEnd) then
        FOnEnd(self, c);
    except
      on e: exception do
      begin
        log('TMuMSSQLExec_Json.ExecProc_Dateset ExecProc_Dateset :%s', [e.message], 0);
      end;
    end;
  finally
    result := rjs.ToString();
    rjs.Clear;
    if (assigned(Proc)) then
      aSQLDBHelp.returnCusProc(aSql, Proc);
    qjsonPool.return(rjs);
  end;
end;

function TMuMSSQLExec_Json.JSONResult(const aConfig, aValue: TQJson; var aErrStr: String): String;
var
  tp: String;
  js: TQJson;
begin
  js := qjsonPool.get;
  try
    if JSONResultJson(aConfig, aValue, aErrStr, js) then
      result := js.ToString;
  finally
    qjsonPool.Free;
  end;
end;

function TMuMSSQLExec_Json.JSONResultJson(const aConfig, aValue: TQJson; var aErrStr: String; aResult: TQJson): boolean;
var
  tp         : String;
  js         : TQJson;
  FRetryTimes: integer;
begin
  aErrStr := '';
  tp      := aConfig.ValueByName('Type', 'SQL');
  // log(llhint, '需要执行的类型是：%s', [tp]);
  if (tp.ToLower() = 'jsonproc') or (tp.ToLower() = 'procjson') or (tp.ToLower() = 'jsonprocedure') then
  begin

    FRetryTimes := 0;
    log('ExecProc for json');
    try
      result := JSONResult_procJson(aConfig, aValue, aErrStr, aResult);
    except
      on e: exception do
      begin
        aErrStr := format('TMuMSSQLExec_Json.JSONResultJson ExecProc exception:%s', [e.message]);
        log(aErrStr, 0);
        if aConfig.HasChild('Exception', js) then
        begin
          if js.IntByName('Retry', 0) > FRetryTimes then
          begin
            inc(FRetryTimes);
            sleep(js.IntByName('Sleep', 3) * 1000);
            result := self.JSONResult_procJson(aConfig, aValue, aErrStr, aResult);
            exit;
          end;
        end;
      end;
    end;
  end else begin
    try
      result := self.JSONResult_SQLJson(aConfig, aValue, aErrStr, aResult);
    except
      on e: exception do
      begin
        aErrStr := format('TMuMSSQLExec_Json.JSONResultJson ExecSQL exception:%s', [e.message]);
        log(aErrStr, 0);
        if aConfig.HasChild('Exception', js) then
        begin
          if js.IntByName('Retry', 0) > FRetryTimes then
          begin
            inc(FRetryTimes);
            sleep(js.IntByName('Sleep', 3) * 1000);
            result := self.JSONResult_SQLJson(aConfig, aValue, aErrStr, aResult);
            exit;
          end;
        end;
      end;
    end;
  end;
end;

function TMuMSSQLExec_Json.JSONResult_proc(const aConfig, aValue: TQJson; var aErrStr: String): String;
var
  Proc            : TFDStoredProc;
  pjs             : TQJson;
  i, j, c, succ, l: integer;
  rjs             : TQJson;
  es              : String;
  server, aSql    : String;
  pname           : string;
  aSQLDBHelp      : TSQLDBHelp;
  aContinue       : boolean;
var
  tmpjs: TQJson;
  function doOne(aValue: TQJson; rjs: TQJson): boolean;
  var
    i: integer;
  begin
    result := false;
    for i  := 0 to Proc.Params.Count - 1 do
    begin
      if not(Proc.Params[i].ParamType in [ptResult, ptOutput, ptInputOutput]) then
      begin
        pname := Proc.Params[i].Name;
        if (aValue.ItemByName(pname) = nil) and (aValue.ItemByName(pname.Replace('@', '')) = nil) then
        begin
          aErrStr := format('%s参数 (%d)"%s"没有值！%s', [Proc.Name, i, Proc.Params[i].Name, aValue.ToString]);
          exit;
        end;
      end;
    end;

    try

      for i := 0 to aValue.Count - 1 do
      begin
        pname := aValue[i].Name;
        if copy(pname, 1, 1) <> '@' then
          pname := '@' + pname;
        with Proc.Params.ParamByName(pname) do
          case datatype of
            ftString, ftFixedChar, ftWideString, ftFixedWideChar:
              begin
                l  := Size;
                es := aValue[i].AsString;
                if l < es.Length then
                begin
                  log('%s 长度截断了 %d/%d', [pname, l, es.Length], 7);
                  es := copy(es, 1, l);
                end;
                AsString := es;
              end;
            // AsString := aValue[i].AsString;
            // ftWideString:
            // AsWideString := aValue[i].AsString;
            ftWideMemo:
              begin
                asWideMemo := aValue[i].AsString;
              end;
            ftFmtMemo, ftMemo:
              asMemo := aValue[i].AsString;
            ftInteger:
              AsInteger := aValue[i].AsInteger;
            ftSmallint:
              AsSmallInt := aValue[i].AsInteger;
            ftShortint:
              AsShortInt := aValue[i].AsInteger;
            ftWord:
              AsWord := aValue[i].AsInteger;
            ftLargeint:
              AsLargeInt := aValue[i].AsInt64;
            ftLongWord:
              AsLongword := aValue[i].AsInt64;

            ftDate:
              asDate := aValue[i].AsDateTime;
            ftTime:
              astime := aValue[i].AsDateTime;
            ftDateTime:
              AsDateTime := aValue[i].AsDateTime;
            // ftTimeStamp:
            // AsSQLTimeStamp := aValue[i].asDatetime;

            ftBoolean:
              AsBoolean := aValue[i].AsBoolean;

            ftFloat:
              AsFloat := aValue[i].AsFloat;
            ftCurrency:
              asCurrency := aValue[i].AsFloat;
            ftExtended:
              asExtended := aValue[i].AsFloat;
            ftSingle:
              asSingle := aValue[i].AsFloat;

          else
            value := aValue[i].AsVariant;
          end;
        // Proc.Params.ParamByName(pname).Value := aValue[i].AsVariant;

      end;
    except
      on e: exception do
      begin
        aErrStr := format('Proc Params set value 1 ,%s %s', [aValue.Encode(false), e.message]);
        log('%s', [aErrStr], 0);
      end;
    end;
    try
      log('Proc.ExecProc %s', [aValue.Encode(false)]);
      Proc.Active := true;
      // log('Proc.ExecProc end %s', [aValue.encode(false)]);

      log('Proc.ExecProc FieldCount:%d,RecordCount:%d ', [Proc.FieldCount, Proc.RecordCount]);
      if Proc.RecordCount = 0 then
      begin
        exit;
      end;
      if Proc.FieldCount = 0 then
      begin
        exit;
      end;
      if Proc.RecordCount = 1 then
      begin
        rjs.datatype := jdtobject;
        Proc.first;
        while not Proc.Eof do
        begin
          // log(Proc.Fields[0].AsString);
          rjs.Parse(Proc.Fields[0].AsString);
          Proc.Next;
        end;
      end else begin
        Proc.first;
        while not Eof do
        begin
          // log(llmessage,Proc.Fields[0].AsString);
          rjs.Add.Parse(Proc.Fields[0].AsString);
          Proc.Next;
        end;
        rjs.datatype := jdtarray;
      end;
      // log('Proc.ExecProc End');
      result := true;
      // log('Proc.ExecProc End 2');
    except
      on e: exception do
      begin
        // if aErrStr <> '' then
        // aErrStr := aErrStr + #13#10;
        aErrStr := aValue.Encode(false) + 'TMuMSSQLExec_Json.JSONResult_proc JSONResult_proc:' + e.message;
        log('%s', [aErrStr], 0);
        // self.FIsAbort := true;
      end;
    end;
  end;

begin
  aErrStr := '';
  result  := '{}';
  rjs     := qjsonPool.get;
  rjs.Clear;
  succ := 0;
  try
    try
      aSql := aConfig.ItemByName('SQL').AsString;
      // log(llhint, '需要执行的语句是:%s', [aSql]);

      aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
      log('get SQLDBHelp %s %d', [aSQLDBHelp.server, aSQLDBHelp.ID]);

      if aSQLDBHelp = nil then
      begin
        aErrStr := format('无法获取服务器信息:%s', [aConfig.ItemByName('Server')]);

        log(aErrStr, 2);
        exit;
      end;

    except
      on e: exception do
      begin
        aErrStr := e.message;
        log('GetOneSQLDBHelp %s', [aErrStr], 0);
        exit;
      end;
    end;
    try
      try
        Proc := aSQLDBHelp.getCusProc(aSql);

        // log(llerror, 'getCusProc %s', [proc.]);
      except
        on e: exception do
        begin
          aErrStr := e.message;
          log('TMuMSSQLExec_Json.JSONResult_proc getCusProc %s', [aErrStr], 0);
          exit;
        end;

      end;
      try
        tmpjs := aValue;
        if aValue.datatype = jdtarray then
          if aValue.Count > 0 then
            tmpjs := aValue[0];

        if not self.InitProc(Proc, aSql, tmpjs, aErrStr) then
        begin
          log('InitProc Error 3 %s', [aErrStr], 0);
          exit;
        end;
      except
        on e: exception do
        begin
          aErrStr := e.message;
          log('InitProc %s', [aErrStr], 0);
        end;
      end;
      try
        if doOne(aValue, rjs) then
          inc(succ);
      finally
        Proc.Active := false;
      end;
      if assigned(FOnEnd) then
        FOnEnd(self, c);
      log('执行成功：%d', [succ]);
    finally
      aSQLDBHelp.returnCusProc(aSql, Proc);
    end;
  finally
    result := rjs.ToString();
    rjs.Clear;
    qjsonPool.return(rjs);
  end;
end;

function TMuMSSQLExec_Json.JSONResult_procJson(const aConfig, aValue: TQJson; var aErrStr: String;
  aResult: TQJson): boolean;
var
  Proc            : TFDStoredProc;
  pjs             : TQJson;
  i, j, c, succ, l: integer;

  es          : String;
  server, aSql: String;
  pname       : string;
  aSQLDBHelp  : TSQLDBHelp;
  aContinue   : boolean;
var
  tmpjs: TQJson;
  function doOne(aValue: TQJson; R: TQJson): boolean;
  var
    i: integer;
  begin
    result := false;
    try
      for i := 0 to Proc.Params.Count - 1 do
      begin
        if not(Proc.Params[i].ParamType in [ptResult, ptOutput, ptInputOutput]) then
        begin
          pname := Proc.Params[i].Name;
          if (aValue.ItemByName(pname) = nil) and (aValue.ItemByName(pname.Replace('@', '')) = nil) then
          begin
            aErrStr := format('%s参数 (%d)"%s"没有值！%s', [Proc.Name, i, Proc.Params[i].Name, aValue.ToString]);
            exit;
          end;
        end;
      end;
    except
      on e: exception do
      begin
        aErrStr := format('TMuMSSQLExec_Json.JSONResult_procJson doone setparams,%s %s', [Proc.Name, e.message]);
        log('%s', [aErrStr], 0);
      end;
    end;

    try

      for i := 0 to aValue.Count - 1 do
      begin
        pname := aValue[i].Name;
        if copy(pname, 1, 1) <> '@' then
          pname := '@' + pname;
        with Proc.Params.ParamByName(pname) do
          case datatype of
            ftString, ftFixedChar, ftWideString, ftFixedWideChar:
              begin
                l  := Size;
                es := aValue[i].AsString;
                if l < es.Length then
                begin
                  log('%s 长度截断了 %d/%d', [pname, l, es.Length], 7);
                  es := copy(es, 1, l);
                end;
                AsString := es;
              end;
            // AsString := aValue[i].AsString;
            // ftWideString:
            // AsWideString := aValue[i].AsString;

            ftWideMemo:
              begin
                asWideMemo := aValue[i].AsString;
              end;
            ftFmtMemo, ftMemo:
              asMemo := aValue[i].AsString;

            ftInteger:
              AsInteger := aValue[i].AsInteger;
            ftSmallint:
              AsSmallInt := aValue[i].AsInteger;
            ftShortint:
              AsShortInt := aValue[i].AsInteger;
            ftWord:
              AsWord := aValue[i].AsInteger;
            ftLargeint:
              AsLargeInt := aValue[i].AsInt64;
            ftLongWord:
              AsLongword := aValue[i].AsInt64;

            ftDate:
              asDate := aValue[i].AsDateTime;
            ftTime:
              astime := aValue[i].AsDateTime;
            ftDateTime:
              AsDateTime := aValue[i].AsDateTime;
            // ftTimeStamp:
            // AsSQLTimeStamp := aValue[i].asDatetime;

            ftBoolean:
              AsBoolean := aValue[i].AsBoolean;

            ftFloat:
              AsFloat := aValue[i].AsFloat;
            ftCurrency:
              asCurrency := aValue[i].AsFloat;
            ftExtended:
              asExtended := aValue[i].AsFloat;
            ftSingle:
              asSingle := aValue[i].AsFloat;

          else
            value := aValue[i].AsVariant;
          end;
        // Proc.Params.ParamByName(pname).Value := aValue[i].AsVariant;

      end;
    except
      on e: exception do
      begin
        aErrStr := format('Proc Params set value 2 ,%s %s', [aValue.Encode(false), e.message]);
        log('%s', [aErrStr], 0);
      end;
    end;
    try
      log('Proc.ExecProc %s', [aValue.Encode(false)]);
      Proc.Active := true;
      // log('Proc.ExecProc end %s', [aValue.encode(false)]);

      log('Proc.ExecProc FieldCount:%d,RecordCount:%d ', [Proc.FieldCount, Proc.RecordCount]);
      if Proc.RecordCount = 0 then
      begin

        exit;
      end;
      if Proc.FieldCount = 0 then
      begin

        exit;
      end;
      if Proc.RecordCount = 1 then
      begin
        aResult.datatype := jdtobject;
        Proc.first;
        while not Proc.Eof do
        begin
          // log(Proc.Fields[0].AsString);
          if Proc.FieldCount > 0 then
          begin
            aResult.Parse(Proc.Fields[0].AsString);
            Proc.Next;
          end else begin
            log('%s field count=0 ', [Proc.Name], 0);
          end;
        end;
      end else begin
        Proc.first;
        while not Eof do
        begin
          // log(llmessage,Proc.Fields[0].AsString);
          aResult.Add.Parse(Proc.Fields[0].AsString);
          Proc.Next;
        end;
        aResult.datatype := jdtarray;

      end;
      // log('Proc.ExecProc End');
      result := true;

      // log('Proc.ExecProc End 2');
    except
      on e: exception do
      begin
        // if aErrStr <> '' then
        // aErrStr := aErrStr + #13#10;
        aErrStr := aValue.Encode(false) + 'TMuMSSQLExec_Json.JSONResult_proc JSONResult_proc' + e.message;
        log('%s', [aErrStr], 0);
        // self.FIsAbort := true;
      end;
    end;
  end;

begin
  aErrStr := '';
  result  := false;
  aResult.Clear;
  succ := 0;
  try

    try
      aSql := aConfig.ItemByName('SQL').AsString;
      // log(llhint, '需要执行的语句是:%s', [aSql]);

      aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
      log('get SQLDBHelp %s %d', [aSQLDBHelp.server, aSQLDBHelp.ID]);

      if aSQLDBHelp = nil then
      begin
        aErrStr := format('无法获取服务器信息:%s', [aConfig.ItemByName('Server')]);

        log(aErrStr, 2);
        exit;
      end;

    except
      on e: exception do
      begin
        aErrStr := e.message;
        log('TMuMSSQLExec_Json.JSONResult_proc GetOneSQLDBHelp %s', [aErrStr], 0);
        exit;
      end;
    end;
    try
      try
        Proc := aSQLDBHelp.getCusProc(aSql);

        // log(llerror, 'getCusProc %s', [proc.]);
      except
        on e: exception do
        begin
          aErrStr := e.message;
          log('TMuMSSQLExec_Json.JSONResult_proc getCusProc %s', [aErrStr], 0);
          exit;
        end;

      end;
      try
        tmpjs := aValue;
        if aValue.datatype = jdtarray then
          if aValue.Count > 0 then
            tmpjs := aValue[0];

        if not self.InitProc(Proc, aSql, tmpjs, aErrStr) then
        begin
          log('InitProc Error 3 %s', [aErrStr], 0);
          exit;
        end;
      except
        on e: exception do
        begin
          aErrStr := e.message;
          log('TMuMSSQLExec_Json.JSONResult_procJson InitProc %s', [aErrStr], 0);
        end;
      end;
      try
        try
          if doOne(aValue, aResult) then
            inc(succ);
        except
          on e: exception do
          begin
            aErrStr := e.message;
            log('TMuMSSQLExec_Json.JSONResult_procJson after doOne %s', [aErrStr], 0);
          end;
        end;
      finally
        Proc.Active := false;
      end;
      if assigned(FOnEnd) then
        FOnEnd(self, c);
      log('执行成功：%d', [succ]);
    finally

      aSQLDBHelp.returnCusProc(aSql, Proc);

    end;

  finally
    result := succ > 0;

  end;

end;

function TMuMSSQLExec_Json.JSONResult_SQL(const aConfig, aValue: TQJson; var aErrStr: String): String;
var
  FQ        : TFDQuery;
  pjs       : TQJson;
  i, c, l   : integer;
  rjs, tmpjs: TQJson;
begin
  aErrStr := '';
  result  := '';
  rjs     := qjsonPool.get;
  try
    JSONResult_SQLJson(aConfig, aValue, aErrStr, rjs);
    result := rjs.ToString;
  finally
    qjsonPool.return(rjs);
  end;

end;

function TMuMSSQLExec_Json.JSONResult_SQLJson(const aConfig, aValue: TQJson; var aErrStr: String;
  aResult: TQJson): boolean;
var
  FQ           : TFDQuery;
  pjs          : TQJson;
  i, c, l, succ: integer;
  tmpjs        : TQJson;
  es           : String;
  aSql         : String;
  aSQLDBHelp   : TSQLDBHelp;
  aContinue    : boolean;
  function doOne(aValue: TQJson; R: TQJson): boolean;
  var
    i    : integer;
    pname: String;
  begin
    result := false;
    if (FQ.SQL.Text <> aSql) then
    begin
      FQ.SQL.Text := aSql;
      // FQ.Prepare;
    end else if FQ.Params.Count <> aValue.Count then
    begin
      FQ.Prepare;
    end;
    if FQ.Params.Count <> aValue.Count then
    begin
      aErrStr := format('SQL的参数%d和配置文件的参数%d数目不一样.', [FQ.Params.Count, aValue.Count]);
      exit;
    end;

    for i := 0 to aValue.Count - 1 do
    begin
      pname := aValue[i].Name;
      // sql 里面一般不是显示声明的类型
      with FQ.Params.ParamByName(pname) do
      begin
        case datatype of
          ftString, ftFixedChar, ftWideString, ftFixedWideChar:
            begin
              l  := Size;
              es := aValue[i].AsString;
              // if l < es.Length then
              // begin
              // log(llWarning, '%s 长度截断了 %d/%d', [pname, l, es.Length]);
              // es := copy(es, 1, l);
              // end;
              AsString := es;

            end;
          // AsString := aValue[i].AsString;
          // ftWideString:
          // AsWideString := aValue[i].AsString;
          ftWideMemo:
            begin
              asWideMemo := aValue[i].AsString;
            end;
          ftFmtMemo, ftMemo:
            asMemo := aValue[i].AsString;
          ftInteger:
            AsInteger := aValue[i].AsInteger;
          ftSmallint:
            AsSmallInt := aValue[i].AsInteger;
          ftShortint:
            AsShortInt := aValue[i].AsInteger;
          ftWord:
            AsWord := aValue[i].AsInteger;
          ftLargeint:
            AsLargeInt := aValue[i].AsInt64;
          ftLongWord:
            AsLongword := aValue[i].AsInt64;

          ftDate:
            asDate := aValue[i].AsDateTime;
          ftTime:
            astime := aValue[i].AsDateTime;
          ftDateTime:
            AsDateTime := aValue[i].AsDateTime;
          // ftTimeStamp:
          // AsSQLTimeStamp := aValue[i].asDatetime;

          ftBoolean:
            AsBoolean := aValue[i].AsBoolean;

          ftFloat:
            AsFloat := aValue[i].AsFloat;
          ftCurrency:
            asCurrency := aValue[i].AsFloat;
          ftExtended:
            asExtended := aValue[i].AsFloat;
          ftSingle:
            asSingle := aValue[i].AsFloat;

        else
          value := aValue[i].AsVariant;
        end;
      end;
      // FQ.Params.ParamByName(pname).Value := aValue[i].AsVariant;
    end;
    try
      FQ.Active := true;
      result    := true;
      if FQ.RecordCount = 0 then
      begin
        exit;
      end;
      if FQ.FieldCount = 0 then
      begin
        exit;
      end;
      if FQ.RecordCount = 1 then
      begin
        aResult.datatype := jdtobject;
        FQ.first;
        result := true;
        while not FQ.Eof do
        begin
          aResult.Parse(FQ.Fields[0].AsString);
          FQ.Next;
        end;
      end else begin
        FQ.first;
        while not FQ.Eof do
        begin
          aResult.Add.Parse(FQ.Fields[0].AsString);
          FQ.Next;
        end;
        aResult.datatype := jdtarray;

      end;

    except
      on e: exception do
      begin
        // if aErrStr <> '' then
        // aErrStr := aErrStr + #13#10;
        aErrStr  := aValue.Encode(false) + 'TMuMSSQLExec_Json.JSONResult_SQLJson JSONResult_SQL:' + e.message;
        FIsAbort := true;
      end;
    end;
  end;

begin
  aErrStr := '';
  result  := false;
  succ    := 0;
  try
    try
      aSql       := aConfig.ItemByName('SQL').AsString;
      aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
      FQ         := aSQLDBHelp.getCusQuery(aSql);

    except
      on e: exception do
      begin
        aErrStr := e.message;
      end;
    end;
    // 此时获取到的，默认是服务器没有更改参数。如果更改了，就自动获取。

    // 数据格式，默认都是对的  bin image text暂时不支持，可以到parames字段的类型读取
    FIsAbort         := false;
    aResult.datatype := jdtarray;

    c := 1;
    try

      if doOne(aValue, aResult) then
        inc(succ);
    finally
      FQ.Active := false;
    end;
    if assigned(FOnProcess) then
    begin
      FOnProcess(self, c, i + 1, aContinue);
      if not aContinue then
        exit;
    end;

    if assigned(FOnEnd) then
      FOnEnd(self, c);
    result := succ > 0;
  finally

    aSQLDBHelp.returnCusQuery(aSql, FQ);

  end;

end;

function TMuMSSQLExec_Json.OpenQuery(const aConfig, aValue: TQJson; var aErrStr: String): TFDQuery;
begin

end;

procedure TMuMSSQLExec_Json.stop;
begin
  self.FIsAbort := true;
end;

{ TODBCStatementBase_ }

function TODBCStatementBase_.MoreResults: boolean;
var
  iRes: SQLReturn;
begin
  result := false;
  if NoMoreResults then
    exit;
  iRes := Lib.SQLMoreResults(Handle);
  case iRes of

    SQL_PARAM_DATA_AVAILABLE:
      begin
        result := true;
      end
  else
    inherited;
  end;
end;

{ TMuMSSQLExec_Ds }

function TMuMSSQLExec_Ds.GetProc(const aConfig, aValue: TQJson; var aErrStr: String): TFDStoredProc;
var
  Proc: TFDStoredProc;
  i, l: integer;

  server, aSql, fdName: String;
  pname, es           : string;
  aSQLDBHelp          : TSQLDBHelp;

  aFDParam: TFDParam;
  afd     : TField;
begin

  aErrStr := '';
  result  := nil;

  try
    try
      aSql := aConfig.ItemByName('SQL').AsString;
      // log(llhint, '需要执行的语句是:%s', [aSql]);

      aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
      log('get SQLDBHelp %s %d', [aSQLDBHelp.server, aSQLDBHelp.ID], 7);

      if aSQLDBHelp = nil then
      begin
        aErrStr := format('无法获取服务器信息:%s', [aConfig.ItemByName('Server')]);

        log(aErrStr, 7);
        exit;
      end;

    except
      on e: exception do
      begin
        aErrStr := e.message;
        log('TMuMSSQLExec_Ds.GetProc GetOneSQLDBHelp %s', [aErrStr], 0);
        exit;
      end;
    end;

    try
      Proc := aSQLDBHelp.getCusProc(aSql);
    except
      on e: exception do
      begin
        aErrStr := e.message;
        log('TMuMSSQLExec_Ds.GetProc getCusProc %s', [aErrStr], 0);
        exit;
      end;
    end;

    if not InitProc(Proc, aSql, aValue, aErrStr) then
    begin
      log('InitProc Error 2 %s', [aSql], 0);
      exit;
    end;

    try
      for i := 0 to aValue.Count - 1 do
      begin
        fdName := aValue[i].AsString;
        if Proc.FindField(fdName) = nil then
          continue;
        afd   := Proc.FieldByName(fdName);
        pname := aValue[i].Name;
        if copy(pname, 1, 1) <> '@' then
          pname  := '@' + pname;
        aFDParam := Proc.Params.ParamByName(pname);
        with aFDParam do
          case datatype of
            ftString, ftFixedChar, ftWideString, ftFixedWideChar:
              begin
                l  := Size;
                es := afd.AsString;
                if l < es.Length then
                begin
                  log('%s 长度截断了 %d/%d', [pname, l, es.Length], 0);
                  es := copy(es, 1, l);
                end;
                AsString := es;
              end;
            // ftWideString:
            // AsWideString := afd.AsString;
            ftInteger:
              AsInteger := afd.AsInteger;
            ftSmallint:
              AsSmallInt := afd.AsInteger;
            ftShortint:
              AsShortInt := afd.AsInteger;
            ftWord:
              AsWord := afd.AsInteger;
            ftLargeint:
              AsLargeInt := afd.AsLargeInt;
            ftLongWord:
              AsLongword := afd.AsLongword;
            ftDate:
              asDate := afd.AsDateTime;
            ftTime:
              astime := afd.AsDateTime;
            ftDateTime:
              AsDateTime := afd.AsDateTime;
            // ftTimeStamp:
            // AsSQLTimeStamp := aValue[i].asDatetime;
            ftBoolean:
              AsBoolean := afd.AsBoolean;
            ftFloat:
              AsFloat := afd.AsFloat;
            ftCurrency:
              asCurrency := afd.AsFloat;
            ftExtended:
              asExtended := afd.AsFloat;
            ftSingle:
              asSingle := afd.AsFloat;

          else
            value := afd.AsVariant;
          end;
        // Proc.Params.ParamByName(pname).Value := aValue[i].AsVariant;
      end;

    except
      on e: exception do
      begin
        aErrStr := e.message;
        log('TMuMSSQLExec_Ds.GetProc:' + aErrStr, 0);
      end;
    end;

    try
      Proc.Active := true;

      result := Proc;

    except
      on e: exception do
      begin
        if (assigned(Proc)) then
          aSQLDBHelp.returnCusProc(aSql, Proc);

        aErrStr := e.message;
        log('TMuMSSQLExec_Ds.GetProc:' + aErrStr, 0);
        // self.FIsAbort := true;
      end;
    end;
  finally
    // if (assigned(Proc)) then
    // aSQLDBHelp.returnCusProc(aSql, Proc);
  end;

end;

function TMuMSSQLExec_Ds.GetQuery(const aConfig, aValue: TQJson; var aErrStr: String): TFDQuery;
var
  Sv  : TQJson;
  aSql: String;
begin
  // logs.Post(lldebug, 'execproc save value %s ', [aValue.ToString]);
  try
    Sv     := aConfig.ItemByName('Server');
    aSql   := aConfig.ItemByName('SQL').AsString;
    result := GetQuery(Sv.ItemByName('Server').AsString, Sv.ItemByName('Username').AsString,
      Sv.ItemByName('Password').AsString, Sv.ItemByName('Database').AsString, aSql, aValue, aErrStr);
  finally

  end;
end;

function TMuMSSQLExec_Ds.GetQuery(const aServer, aUser, aPwd, aDbName, aSql: String; const aValue: TQJson;
  var aErrStr: String): TFDQuery;
var
  FQ           : TFDQuery;
  pjs          : TQJson;
  i, c, succ, l: integer;

  es: String;

  aSQLDBHelp: TSQLDBHelp;
  aContinue : boolean;

  function doOne(aValue: TQJson): boolean;
  var
    i    : integer;
    pname: String;
  begin
    result := false;
    if (FQ.SQL.Text <> aSql) then
    begin
      FQ.SQL.Text := aSql;
      // FQ.Prepare;
    end else if FQ.Params.Count <> aValue.Count then
    begin
      FQ.Prepare;
    end;
    if FQ.Params.Count <> aValue.Count then
    begin
      aErrStr := 'SQL的参数和配置文件的参数数目不一样.';
      exit;
    end;
    for i := 0 to aValue.Count - 1 do
    begin
      pname := aValue[i].Name;
      with FQ.Params.ParamByName(pname) do
        case datatype of
          ftString, ftFixedChar, ftWideString, ftFixedWideChar:
            begin
              l  := Size;
              es := aValue[i].AsString;
              if l < es.Length then
              begin
                log('%s 长度截断了 %d/%d', [pname, l, es.Length], 6);
                es := copy(es, 1, l);
              end;
              AsString := es;
            end;
          // AsString := aValue[i].AsString;
          // ftWideString:
          // AsWideString := aValue[i].AsString;
          ftWideMemo:
            begin
              asWideMemo := aValue[i].AsString;
            end;

          ftFmtMemo, ftMemo:
            asMemo := aValue[i].AsString;

          ftInteger:
            AsInteger := aValue[i].AsInteger;
          ftSmallint:
            AsSmallInt := aValue[i].AsInteger;
          ftShortint:
            AsShortInt := aValue[i].AsInteger;
          ftWord:
            AsWord := aValue[i].AsInteger;
          ftLargeint:
            AsLargeInt := aValue[i].AsInt64;
          ftLongWord:
            AsLongword := aValue[i].AsInt64;

          ftDate:
            asDate := aValue[i].AsDateTime;
          ftTime:
            astime := aValue[i].AsDateTime;
          ftDateTime:
            AsDateTime := aValue[i].AsDateTime;
          // ftTimeStamp:
          // AsSQLTimeStamp := aValue[i].asDatetime;

          ftBoolean:
            AsBoolean := aValue[i].AsBoolean;

          ftFloat:
            AsFloat := aValue[i].AsFloat;
          ftCurrency:
            asCurrency := aValue[i].AsFloat;
          ftExtended:
            asExtended := aValue[i].AsFloat;
          ftSingle:
            asSingle := aValue[i].AsFloat;

        else
          value := aValue[i].AsVariant;
        end;

      // FQ.Params.ParamByName(pname).Value := aValue[i].AsVariant;
    end;
    try
      FQ.Active := true;
      result    := true;

    except
      on e: exception do
      begin
        // if aErrStr <> '' then
        // aErrStr := aErrStr + #13#10;
        aErrStr  := aValue.Encode(false) + 'TMuMSSQLExec_Ds.GetQuery fdquery open: ' + e.message;
        FIsAbort := true;
      end;
    end;
  end;

begin
  aErrStr := '';
  result  := nil;

  try
    try

      aSQLDBHelp := GetOneSQLDBHelp(aServer, aUser, aPwd, aDbName);
      FQ         := aSQLDBHelp.getCusQuery(aSql);

    except
      on e: exception do
      begin
        aErrStr := e.message;
      end;
    end;
    // 此时获取到的，默认是服务器没有更改参数。如果更改了，就自动获取。

    // 数据格式，默认都是对的  bin image text暂时不支持，可以到parames字段的类型读取
    FIsAbort := false;

    if doOne(aValue) then
    begin
      result := FQ;
    end
    else
      aSQLDBHelp.returnCusQuery(aSql, FQ);

  finally

    // aSQLDBHelp.returnCusQuery(aSql, FQ);

  end;

end;

procedure TMuMSSQLExec_Ds.returnDataset(const aConfig: TQJson; aQuery: TFDRdbmsDataSet);
var
  aType, aSql: String;
  aSQLDBHelp : TSQLDBHelp;
begin
  aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
  log('get SQLDBHelp %s %d', [aSQLDBHelp.server, aSQLDBHelp.ID], 7);
  aSql  := aConfig.ItemByName('SQL').AsString;
  aType := aConfig.ItemByName('Type').AsString.ToLower();
  if pos('proc', aType) > 0 then
  begin
    aSQLDBHelp.returnCusProc(aSql, aQuery as TFDStoredProc);
  end
  else
    aSQLDBHelp.returnCusQuery(aSql, aQuery as TFDQuery);
end;

procedure TMuMSSQLExec_Ds.returnProc(const aConfig: TQJson; Proc: TFDStoredProc);
var
  aSQLDBHelp: TSQLDBHelp;
  aSql      : String;
begin
  aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
  log('get SQLDBHelp %s %d', [aSQLDBHelp.server, aSQLDBHelp.ID], 7);
  aSql := aConfig.ItemByName('SQL').AsString;
  if aSQLDBHelp = nil then
  begin
    log(format('无法获取服务器信息:%s', [aConfig.ItemByName('Server')]), 7);
    exit;
  end;
  // if (assigned(Proc)) then
  aSQLDBHelp.returnCusProc(aSql, Proc);
end;

procedure TMuMSSQLExec_Ds.returnQuery(const aConfig: TQJson; aQuery: TFDQuery);
var
  aSQLDBHelp: TSQLDBHelp;
  aSql      : String;
begin
  aSQLDBHelp := GetOneSQLDBHelp(aConfig.ItemByName('Server'));
  log('get SQLDBHelp %s %d', [aSQLDBHelp.server, aSQLDBHelp.ID], 7);
  aSql := aConfig.ItemByName('SQL').AsString;
  if aSQLDBHelp = nil then
  begin
    log(format('无法获取服务器信息:%s', [aConfig.ItemByName('Server')]), 7);
    exit;
  end;
  // if (assigned(aQuery)) then
  aSQLDBHelp.returnCusQuery(aSql, aQuery);

end;

initialization

// SDBHelp := TSDBHelp.Create(getexepath + 'db\ac.sdb');

finalization

// SDBHelp.Free;

end.
