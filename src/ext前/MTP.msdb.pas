unit MTP.msdb;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys.MSSQL, FireDAC.Moni.RemoteClient,
  FireDAC.Phys, FireDAC.Stan.Intf,
  FireDAC.Stan.ExprFuncs, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.Client, Data.DB, FireDAC.Comp.DataSet,

  qmacros, qjson, qstring, Mu.Pool.qjson, Mu.MSSQL.Exec;

var
  DBServerConfig: TQjson;
  FMuMSSQLExec: TMuMSSQLExec_Json;
  FMuMSSQLExec_ds: TMuMSSQLExec_ds;

  // FSQLDBHelp: TSQLDBHelp;

type
  TCmdReturn = record
    ReturnCode: integer;
    Result: String;
    Error: String;
  public
    class function create(rc: integer; rs, err: String): TCmdReturn; static;
  end;

  TMSDB = class
  public

    class function getErrorInfoFromResponseStr(ResStr: String): string; static;
    class function getErrorInfoFromResponseJson(respjs: TQjson): string; static;
    class function getResultFromResponseStr(ResStr: String): TCmdReturn; static;

    class function getResponseJson(ResponseStr: String; aResJson: TQjson): boolean; overload; static;
    class function getResponseJson(ResponseStr: String; aResJson: TQjson; var Errstr: String): boolean;
      overload; static;
    class procedure initRequestJson(ajs: TQjson); static;
    class procedure SetRequestJsonValue(cmdjs, Vjs: TQjson); static;
    class procedure ResponseJsonToStrings(aReq: TQjson; Fields: String; rs: TStrings);
    class procedure RequestToStrings(aReq: TQjson; Fields: String; rs: TStrings);

    class function getconn: TFDConnection;
    class procedure retrunconn(aConn: TFDConnection);
    class function Exec(aReqParams: TQjson): String; overload;
    class function Exec(aType, aSql: String; aValue: TQjson): String; overload;
    class function Exec(aType, aSql, aValue: String): String; overload;

    class function Exec(aConfig: TQjson; aType, aSql: String; aValue: TQjson): String; overload;
    class function Exec(aConfig: TQjson; aValue: TQjson): String; overload;

    class function ExecJson(aReqParams: TQjson; aResult: TQjson): boolean; overload;
    class function ExecJson(aType, aSql: String; aValue: TQjson; aResult: TQjson): boolean; overload;
    class function ExecJson(aType, aSql, aValue: String; aResult: TQjson): boolean; overload;

    class function ExecJson(aConfig: TQjson; aType, aSql: String; aValue: TQjson; aResult: TQjson): boolean; overload;
    class function ExecJson(aConfig: TQjson; aValue: TQjson; aResult: TQjson): boolean; overload;

    /// dataset
    class function GetDataset(const aConfig: TQjson; const aValue: TQjson): TFDRdbmsDataSet;
    class function GetProc(const aConfig: TQjson; const aValue: TQjson): TFDStoredProc;
    class function GetQuery(const aConfig: TQjson; const aValue: TQjson): TFDQuery; overload;

    class procedure returnProc(const aConfig: TQjson; Proc: TFDStoredProc);
    class procedure returnQuery(const aConfig: TQjson; aQuery: TFDQuery);
    class procedure returnDataset(const aConfig: TQjson; aQuery: TFDRdbmsDataSet);

  end;

  TMSDBClass = class of TMSDB;

implementation

uses MTP.Utils;

function loadconfig(): boolean;
var
  fn: String;
begin
  DBServerConfig := TQjson.create;
  fn := getexepath + 'config\msdb.json';
  if fileexists(fn) then
    DBServerConfig.LoadFromFile(fn);
end;

class function TMSDB.getErrorInfoFromResponseJson(respjs: TQjson): string;
var
  ejs: TQjson;
  es, s: String;
  i: integer;

  function isErrResult(rs: String; var es: String): boolean;
  var
    js, ejs: TQjson;
  begin
    Result := false;
    rs := trim(rs);
    es := '';

    if rs.Length > 0 then
    begin
      if rs[1] in ['{', '['] then
      begin

        js := TQjson.create;
        try
          if js.TryParse(rs) then
          begin
            if js.HasChild('Error', ejs) then
            begin
              es := ejs.AsString;
              exit(true);
            end;
            if js.HasChild('ERROR', ejs) then
            begin
              es := ejs.AsString;
              exit(true);
            end;
          end
          else
            messagebox(0, pchar(rs), 'Error', 0);
        finally
          js.Free;
        end;
      end;
    end;
    if copy(rs, 1, 5).ToUpper() = 'ERROR' then
    begin
      es := rs;
      exit(true);
    end;
  end;

begin

  if respjs.HasChild('Error', ejs) then
  begin
    exit(ejs.ToString);
  end else begin
    if respjs.HasChild('Error', ejs) then
    begin
      exit(ejs.ToString);
    end else if respjs.HasChild('@Result', ejs) then
    begin
      s := ejs.ToString;

      if Length(s) > 5 then
      begin
        if isErrResult(s, es) then
          exit(es);
      end;
    end;
    if respjs.Count > 0 then
    begin
      if respjs[0].HasChild('Error', ejs) then
      begin
        exit(ejs.ToString);
      end else if respjs[0].HasChild('@Result', ejs) then
      begin
        s := ejs.ToString;
        if Length(s) > 5 then
        begin
          if isErrResult(s, es) then
            exit(es);

        end;
      end;
    end;
  end;
end;

class function TMSDB.getErrorInfoFromResponseStr(ResStr: String): string;
var
  respjs, rpjs, ejs: TQjson;
  s: String;
  i: integer;
begin
  Result := '';
  if ResStr = '' then
    exit;
  respjs := qjsonpool.get;
  try
    respjs.parse(ResStr);
    Result := TMSDB.getErrorInfoFromResponseJson(respjs);
  finally
    // respjs.Free;
    qjsonpool.return(respjs);
  end;
end;

class function TMSDB.GetDataset(const aConfig, aValue: TQjson): TFDRdbmsDataSet;
var
  js: TQjson;
  aErr: String;
  aType, aV: String;
begin
  try
    Result := nil;


    if aConfig.HasChild('Server', js) then
    begin
      js.Merge(DBServerConfig.ItemByName('Server'), jmmIgnore);
    end
    else
      aConfig.Add('Server').Assign(DBServerConfig.ItemByName('Server'));

    for js in aValue do
    begin
      aV := js.AsString.ToUpper();
      if (aV = uppercase('$$LoginUserID')) or (aV = uppercase('$$UserID')) or (aV = uppercase('$LoginUserID')) or
        (aV = uppercase('$UserID')) then
      begin
        // js.AsString := userinfo.UserNO;
      end;
    end;

    aType := aConfig.ValueByName('Type', '');

    if pos('porc', aType.ToLower()) > 0 then
      Result := FMuMSSQLExec_ds.GetProc(aConfig, aValue, aErr)
    else
      Result := FMuMSSQLExec_ds.GetQuery(aConfig, aValue, aErr);

    if aErr <> '' then
    begin

    end;
  finally

  end;

end;

class function TMSDB.GetProc(const aConfig, aValue: TQjson): TFDStoredProc;
var
  js: TQjson;
  aErr: String;
  aV: String;
begin
  try
    Result := nil;
    if aConfig.HasChild('Server', js) then
    begin
      js.Merge(DBServerConfig.ItemByName('Server'), jmmIgnore);
    end
    else
      aConfig.Add('Server').Assign(DBServerConfig.ItemByName('Server'));

    for js in aValue do
    begin
      aV := js.AsString.ToUpper();
      if (aV = uppercase('$$LoginUserID')) or (aV = uppercase('$$UserID')) or (aV = uppercase('$LoginUserID')) or
        (aV = uppercase('$UserID')) then
      begin
        // js.AsString := userinfo.UserNO;
      end;
    end;

    Result := FMuMSSQLExec_ds.GetProc(aConfig, aValue, aErr);

    if aErr <> '' then
    begin

    end;
  finally

  end;

end;

class function TMSDB.GetQuery(const aConfig, aValue: TQjson): TFDQuery;
var
  js: TQjson;
  aErr: String;
  aV: String;
begin
  try
    Result := nil;
    if aConfig.HasChild('Server', js) then
    begin
      js.Merge(DBServerConfig.ItemByName('Server'), jmmIgnore);
    end
    else
      aConfig.Add('Server').Assign(DBServerConfig.ItemByName('Server'));

    for js in aValue do
    begin
      aV := js.AsString.ToUpper();
      if (aV = uppercase('$$LoginUserID')) or (aV = uppercase('$$UserID')) or (aV = uppercase('$LoginUserID')) or
        (aV = uppercase('$UserID')) then
      begin
        // js.AsString := userinfo.UserNO;
      end;
    end;

    Result := FMuMSSQLExec_ds.GetQuery(aConfig, aValue, aErr);

    if aErr <> '' then
    begin

    end;
  finally

  end;

end;

class function TMSDB.getResponseJson(ResponseStr: String; aResJson: TQjson; var Errstr: String): boolean;
var
  resjs, ajs: TQjson;
begin
  Result := true;
  resjs := qjsonpool.get; // TQjson.create;
  Errstr := '';
  try
    resjs.parse(ResponseStr);
    Errstr := TMSDB.getErrorInfoFromResponseJson(resjs);
    if Errstr <> '' then
    begin
      Result := false;
    end;

    if resjs.HasChild('Response', ajs) then
      aResJson.Assign(ajs)
    else
      aResJson.Assign(resjs);
  finally
    qjsonpool.return(resjs);
    // resjs.Free;
  end;
end;

class function TMSDB.getResultFromResponseStr(ResStr: string): TCmdReturn;
var
  respjs, rpjs, rjs, ejs: TQjson;
  s: String;
  i: integer;
  function getFromResJson(rpjs: TQjson): TCmdReturn;
  begin

  end;

begin
  Result.ReturnCode := 0;
  Result.Result := '';
  Result.Error := '';
  if ResStr = '' then
    exit;
  rpjs := nil;

  respjs := qjsonpool.get; // TQjson.create; ;
  try
    respjs.parse(ResStr);
    if respjs.HasChild('Error', ejs) then
    begin
      Result.Error := (ejs.ToString);
    end else if not respjs.HasChild('Response', rpjs) then

      rpjs := respjs;

    if rpjs.DataType = jdtarray then
      if rpjs.Count > 0 then
      begin
        rpjs := rpjs[0];
      end;

    if rpjs.HasChild('Error', ejs) then
    begin
      Result.Error := (ejs.ToString);
    end else begin
      if rpjs.HasChild('@Result', ejs) then
      begin
        s := ejs.ToString;
        Result.Result := s;

        if Length(s) > 5 then
        begin
          if copy(s.ToUpper, 1, 5) = 'ERROR' then
          begin
            Result.Error := s;
          end;
        end;
      end;
      if rpjs.HasChild('@RETURN_VALUE', ejs) then
      begin
        Result.ReturnCode := ejs.AsInteger;
      end;
    end;

  finally
    // respjs.Free;
    qjsonpool.return(respjs);
  end;
end;

class function TMSDB.getResponseJson(ResponseStr: String; aResJson: TQjson): boolean;
var
  resjs, ajs: TQjson;
  rs: String;
begin
  Result := true;
  resjs := qjsonpool.get; // TQjson.create;
  try
    rs := getErrorInfoFromResponseStr(ResponseStr);
    if rs <> '' then
    begin
      Result := false;
      // raise exception.CreateFmt('数据库请求时发生错误%s', [rs]);
    end;
    resjs.parse(ResponseStr);
    if resjs.HasChild('Response', ajs) then
      aResJson.Assign(ajs)
    else
      aResJson.Assign(resjs);

  finally
    qjsonpool.return(resjs); // resjs.Free;
  end;

end;

class procedure TMSDB.initRequestJson(ajs: TQjson);
begin
  ajs.Clear;
  ajs.parse('{Type:"",SQL:"",Value:{}}');
end;

class procedure TMSDB.SetRequestJsonValue(cmdjs, Vjs: TQjson);
var
  pjs: TQjson;
begin
  if cmdjs.DataType = jdtarray then
    pjs := cmdjs[2]
  else
    pjs := cmdjs.ForcePath('Value');
  pjs.Merge(Vjs, jmmReplace);
end;

class procedure TMSDB.RequestToStrings(aReq: TQjson; Fields: String; rs: TStrings);
var
  s: String;
  js, resjs: TQjson;
begin
  s := TMSDB.Exec(aReq);

  resjs := qjsonpool.get; // TQjson.create; ;
  try
    if not resjs.TryParse(s) then
    begin
      raise exception.create('错误！无法解析' + #13#10 + s);
      exit;
    end;

    if resjs.HasChild('Response', js) then
    begin
      ResponseJsonToStrings(js, Fields, rs);
    end;
  finally
    qjsonpool.return(resjs);
    // resjs.Free;
  end;

end;

class procedure TMSDB.ResponseJsonToStrings(aReq: TQjson; Fields: String; rs: TStrings);
var
  FMacroMgr: TQMacroManager;
  s: String;
  js: TQjson;
  i: integer;
begin
  FMacroMgr := TQMacroManager.create;
  try
    // if FMacroMgr.Count <> params.Count then
    FMacroMgr.Clear;
    for js in aReq do
    begin
      for i := 0 to js.Count - 1 do
      begin
        FMacroMgr.Push(js[i].Name, js[i].Value);
      end;
      s := FMacroMgr.Replace(Fields, '%', '%', MRF_ENABLE_ESCAPE);
      rs.Add(s);
    end;
  finally
    FMacroMgr.Free;
  end;
end;

{ TMSDB }
// aReqParams
// {
// SQL:"",
// Type:"",
// Value:{
//
// }
// }

class function TMSDB.Exec(aReqParams: TQjson): String;

var
  js: TQjson;

begin

  js := qjsonpool.get;
  try
    TMSDB.ExecJson(aReqParams, js);
    Result := js.ToString

  finally
    qjsonpool.return(js);
  end;

end;

class function TMSDB.Exec(aType, aSql: String; aValue: TQjson): String;
var
  ajson, js: TQjson;
  aErr: String;
  aV: String;
begin
  ajson := qjsonpool.get;
  try
    ExecJson(aType, aSql, aValue, ajson);
    Result := ajson.ToString;
  finally
    qjsonpool.return(ajson);
  end;

end;

class function TMSDB.Exec(aConfig: TQjson; aType, aSql: String; aValue: TQjson): String;
var
  ajson: TQjson;
  aErr: String;
  aV: String;
begin
  ajson := qjsonpool.get;
  try
    ExecJson(aConfig, aType, aSql, aValue, ajson);
    Result := ajson.ToString;
  finally
    qjsonpool.return(ajson);
  end;

end;

class function TMSDB.Exec(aType, aSql, aValue: String): String;
var
  ajson: TQjson;
begin
  ajson := qjsonpool.get;
  try

    TMSDB.ExecJson(aType, aSql, aValue, ajson);
    Result := ajson.ToString;
  finally
    qjsonpool.return(ajson);
  end;
end;

class function TMSDB.Exec(aConfig: TQjson; aValue: TQjson): String;
var
  ajson, js: TQjson;
  aErr: String;
  aV: String;
begin
  ajson := qjsonpool.get;
  try
    ExecJson(aConfig, aValue, ajson);
    Result := ajson.ToString;
  finally
    qjsonpool.return(ajson);
  end;

end;

class function TMSDB.ExecJson(aReqParams, aResult: TQjson): boolean;

var
  rq, ajson, Vjs, js: TQjson;
  aSql, aType, aErr: String;

begin
  Result := false;
  if not aReqParams.HasChild('Request', rq) then
    rq := aReqParams;

  if rq.DataType = jdtarray then
  begin
    aType := rq.Items[0].AsString;
    aSql := rq.Items[1].AsString;
    Vjs := rq.Items[2];
  end else begin
    aType := rq.ValueByName('Type', '');
    aSql := rq.Valuebypath('SQL', '');
    Vjs := rq.itembypath('Value');
    if Vjs = nil then
      rq.ForcePath('Value').parse('{}');
    Vjs := rq.itembypath('Value');

  end;
  if aType = '' then
  begin
    Result.parse('{“Error”:"缺少请求类型！"}');
    exit;
  end;
  if aSql = '' then
  begin
    Result.parse('{“Error”:"缺少请求命令！"}');
    exit;
  end;

  Result := TMSDB.ExecJson(aType, aSql, Vjs, aResult);

end;

class function TMSDB.ExecJson(aType, aSql: String; aValue, aResult: TQjson): boolean;
var
  ajson, js: TQjson;
  aErr: String;
  aV: String;
begin

  try
    ajson := qjsonpool.get;
    ajson.Assign(DBServerConfig);

    ajson.ForcePath('Type').AsString := aType;
    ajson.ForcePath('SQL').AsString := aSql;

    for js in aValue do
    begin
      aV := js.AsString.ToUpper();
      if (aV = uppercase('$$LoginUserID')) or (aV = uppercase('$$UserID')) or (aV = uppercase('$LoginUserID')) or
        (aV = uppercase('$UserID')) then
      begin
        // js.AsString := userinfo.UserNO;
      end;
    end;

    Result := FMuMSSQLExec.ExecJson(ajson, aValue, aErr, aResult);

    if aErr <> '' then
    begin

      if aResult.DataType = jdtarray then
      begin
        if aResult.Count > 0 then
          aResult[0].ForcePath('Error').AsString := aErr
        else
          aResult.Add().ForcePath('Error').AsString := aErr;
      end
      else
        aResult.ForcePath('Error').AsString := aErr;
      // Result := aResult.ToString();
      // messagebox(0, pchar(Result), '', 0);
    end;
  finally
    qjsonpool.return(ajson);
  end;

end;

class function TMSDB.ExecJson(aType, aSql, aValue: String; aResult: TQjson): boolean;
var
  ajson: TQjson;
begin
  ajson := qjsonpool.get;
  try
    if aValue = '' then
      aValue := '{}';
    ajson.parse(aValue);
    Result := TMSDB.ExecJson(aType, aSql, ajson, aResult);
  finally
    qjsonpool.return(ajson);
  end;
end;

class function TMSDB.ExecJson(aConfig: TQjson; aType, aSql: String; aValue, aResult: TQjson): boolean;
var
  ajson, js: TQjson;
  aErr: String;
  aV: String;
begin
  ajson := qjsonpool.get;
  try
    ajson.Assign(aConfig);

    ajson.ForcePath('Type').AsString := aType;
    ajson.ForcePath('SQL').AsString := aSql;

    for js in aValue do
    begin
      aV := js.AsString.ToUpper();
      if (aV = uppercase('$$LoginUserID')) or (aV = uppercase('$$UserID')) or (aV = uppercase('$LoginUserID')) or
        (aV = uppercase('$UserID')) then
      begin
        // js.AsString := userinfo.UserNO;
      end;
    end;

    Result := FMuMSSQLExec.ExecJson(ajson, aValue, aErr, aResult);

    if aErr <> '' then
    begin

      if aResult.DataType = jdtarray then
      begin
        if aResult.Count > 0 then
          aResult[0].ForcePath('Error').AsString := aErr
        else
          aResult.Add().ForcePath('Error').AsString := aErr;
      end
      else
        aResult.ForcePath('Error').AsString := aErr;

    end;
  finally
    qjsonpool.return(ajson);
  end;

end;

class function TMSDB.ExecJson(aConfig, aValue, aResult: TQjson): boolean;
var
  js: TQjson;
  aErr: String;
  aV: String;
begin
  try
    if aConfig.HasChild('Server', js) then
    begin
      js.Merge(DBServerConfig.ItemByName('Server'), jmmIgnore);
    end
    else
      aConfig.Add('Server').Assign(DBServerConfig.ItemByName('Server'));

    for js in aValue do
    begin
      aV := js.AsString.ToUpper();
      if (aV = uppercase('$$LoginUserID')) or (aV = uppercase('$$UserID')) or (aV = uppercase('$LoginUserID')) or
        (aV = uppercase('$UserID')) then
      begin
        // js.AsString := userinfo.UserNO;
      end;
    end;

    Result := FMuMSSQLExec.ExecJson(aConfig, aValue, aErr, aResult);

    if aErr <> '' then
    begin

      if aResult.DataType = jdtarray then
      begin
        if aResult.Count > 0 then
          aResult[0].ForcePath('Error').AsString := aErr
        else
          aResult.Add().ForcePath('Error').AsString := aErr;
      end
      else
        aResult.ForcePath('Error').AsString := aErr;

      // messagebox(0, pchar(Result), '', 0);
    end;
  finally

  end;

end;

class function TMSDB.getconn: TFDConnection;
begin
  // FSQLDBHelp.getconn;
end;

class procedure TMSDB.retrunconn(aConn: TFDConnection);
begin
  // FSQLDBHelp.returnConn(aConn);
end;

class procedure TMSDB.returnDataset(const aConfig: TQjson; aQuery: TFDRdbmsDataSet);
begin
  FMuMSSQLExec_ds.returnDataset(aConfig, aQuery);
end;

class procedure TMSDB.returnProc(const aConfig: TQjson; Proc: TFDStoredProc);
begin
  FMuMSSQLExec_ds.returnProc(aConfig, Proc);
end;

class procedure TMSDB.returnQuery(const aConfig: TQjson; aQuery: TFDQuery);
begin
  FMuMSSQLExec_ds.returnQuery(aConfig, aQuery);
end;

{ TCmdReturn }

class function TCmdReturn.create(rc: integer; rs, err: String): TCmdReturn;
begin
  Result.ReturnCode := rc;
  Result.Result := rs;
  Result.Error := err;
end;

initialization

loadconfig;

// FSQLDBHelp := TSQLDBHelp.Create(DBServerConfig.ItemByName('Server').asstring,
// DBServerConfig.ItemByName('Username').asstring,
// DBServerConfig.ItemByName('Password').asstring,
// DBServerConfig.ItemByName('Database').asstring);

FMuMSSQLExec := TMuMSSQLExec_Json.create;
FMuMSSQLExec_ds := TMuMSSQLExec_ds.create;

finalization

DBServerConfig.Free;

FMuMSSQLExec.Free;
FMuMSSQLExec_ds.Free;

// FSQLDBHelp.Free;

end.d.
