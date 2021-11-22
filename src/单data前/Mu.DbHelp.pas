unit Mu.DbHelp;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.VCLUI.Wait,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.Client, Data.DB, FireDAC.Comp.DataSet, FireDAC.Moni.RemoteClient, FireDAC.Phys.MSSQL,

  qjson, QSimplePool, qrbtree, uqdbjson, qworker,
  Generics.Collections, SyncObjs;

var
  SQLDBHelpStopALL: boolean = false;
  PbConnCount     : integer = 0;
  PbQueryCount    : integer = 0;
  PbProcCount     : integer = 0;

  PbCusOutTimeout: integer = 5; // 借出去超时时间，单位是分钟;

type

  TMTimeAndFDC = record
    sql: String;
    time: tdatetime;
    query: TFDQuery;
    proc: TFDStoredProc;
    qandp: boolean;
  end;

  TSQLDBHelp = class;

  TMTimeAndFDClist = class(TObject)
    private
      FLock: TCriticalSection;
      FList: TList<TMTimeAndFDC>;

      // FPoolCon, FPoolProc, FPoolQuery: TQSimplePool;
      FSDBHelp: TSQLDBHelp;
      function getCount(): integer;
    public
      constructor Create(aSDBHelp: TSQLDBHelp);
      destructor Destroy; override;

      procedure AddProc(aSql: String; aProc: TFDStoredProc);
      procedure AddQuery(aSql: String; aQuery: TFDQuery);

      function CheckFirst: boolean;

      procedure RemoveProc(aSql: String; aProc: TFDStoredProc);
      procedure RemoveQuery(aSql: String; aQuery: TFDQuery);

      property Count: integer read getCount;

  end;

  TSDBHelp = class(TObject)
    private
      FDConnection1: TFDConnection;
      FDCommand1   : TFDCommand;
      FDQuerys     : array of TFDQuery;

    protected

    public
      constructor Create(dbpath: string; username: string = ''; password: string = ''; Params: string = '');
      destructor Destroy; override;
      function execsql(sql: String): LongInt; overload;
      function execsql(const aSql: String; const AParams: array of Variant): LongInt; overload;
      property Conn: TFDConnection read FDConnection1;

      function getQuery(): TFDQuery;
      procedure returnQuery;

  end;

  TSQLDBHelp = class(TObject)
    private
      FCusQueryOutCount: integer;
      FCusProcOutCount : integer;

      FCusProcOutList   : TDictionary<TFDQuery, TFDConnection>;
      FCusQueryOutList  : TDictionary<TFDStoredProc, TFDConnection>;
      FCusOutWatchHandle: THandle;
      // FMTimeAndFDClist  : TMTimeAndFDClist;

      FID       : integer;
      FProcCount: integer;

      FConnectionDefName                      : string;
      FServer, FUsername, FPassword, FDatabase: string;

      oDef: IFDStanConnectionDef;

      FDPhysMSSQLDriverLink1 : TFDPhysMSSQLDriverLink;
      FDMoniRemoteClientLink1: TFDMoniRemoteClientLink;

      FDFConnPool: TQSimplePool;

      FCusProcs : TObjectDictionary<string, TQSimplePool>;
      FCusQuerys: TObjectDictionary<string, TQSimplePool>;

      FDQueryPool: TQSimplePool;
      FDProcPool : TQSimplePool;

      procedure FOnQueryCreate_c(Sender: TQSimplePool; var AData: Pointer);
      procedure FOnQueryFree_c(Sender: TQSimplePool; AData: Pointer);
      procedure FOnQueryReset_c(Sender: TQSimplePool; AData: Pointer);

      procedure FOnProcCreate(ASender: TQSimplePool; var AData: Pointer);
      procedure FOnProcFree(ASender: TQSimplePool; AData: Pointer);
      procedure FOnProcReset(ASender: TQSimplePool; AData: Pointer);

      procedure FOnConnCreate(ASender: TQSimplePool; var AData: Pointer);
      procedure FOnConnFree(ASender: TQSimplePool; AData: Pointer);
      procedure FOnConnReset(ASender: TQSimplePool; AData: Pointer);

      procedure setServer(Value: string);
      procedure setUsername(Value: string);
      procedure setPassword(Value: string);
      procedure setDatabase(Value: string);

      Procedure ConnOnLost(ASender: TObject);

      procedure CusOutWatch(aJob: PQJob);
    protected
      procedure AddCusQuery(aQueryName: String);
      procedure AddCusProc(aProcName: String);
    public
      constructor Create(aServer: string; ausername: string = ''; apassword: string = ''; aDatabase: string = '');
      procedure SetConnectionParams();
      destructor Destroy; override;
      function execsql(sql: String): LongInt; overload;
      function execsql(const aSql: String; const AParams: array of Variant): LongInt; overload;

      function GetConn(): TFDConnection;
      procedure ReturnConn(fdq: TFDConnection);

      function getQuery(): TFDQuery;
      procedure returnQuery(fdq: TFDQuery);
      function GetProc(): TFDStoredProc;
      procedure ReturnProc(fdq: TFDStoredProc);

      function GetCusProc(aProcName: String): TFDStoredProc;
      procedure ReturnCusProc(aProcName: String; proc: TFDStoredProc; aRemoveWatch: boolean = true);

      function GetCusQuery(aQueryName: String): TFDQuery;
      procedure ReturnCusQuery(aQueryName: String; fdq: TFDQuery; aRemoveWatch: boolean = true);

      property Server: String read FServer; // write setServer;
      property username: String read FUsername write setUsername;
      property password: String read FPassword write setPassword;
      property Database: String read FDatabase write setDatabase;

      property CusQueryOutCount: integer read FCusQueryOutCount;
      property CusProcOutCount: integer read FCusProcOutCount;

      // property ConnectionDefName: string read FConnectionDefName;
      property ID: integer read FID;
    published

  end;

  TSQLDBHelps = class
    FLock: TCriticalSection;
    FaTs: TList<TSQLDBHelp>;
    public
      constructor Create();
      destructor Destroy; override;
      function get(const sv: TQJson): TSQLDBHelp; overload;
      function get(const aServer, aUser, aPwd, aDbName: String): TSQLDBHelp; overload;
  end;

var

  // SQLDBHelp: TSQLDBHelp;
  SQLDBHelps: TSQLDBHelps;

implementation

uses qstring, typinfo, dateutils, math;

{ TSDBHelp }
constructor TSDBHelp.Create(dbpath: string; username: string = ''; password: string = ''; Params: string = '');
var
  i: integer;

begin
  FDConnection1 := TFDConnection.Create(nil);

  FDCommand1 := TFDCommand.Create(nil);

  for i := 0 to high(FDQuerys) do
  begin
    FDQuerys[i]            := TFDQuery.Create(nil);
    FDQuerys[i].Connection := FDConnection1;
  end;
  FDCommand1.Connection     := FDConnection1;
  FDConnection1.LoginPrompt := false;

  FDConnection1.Params.add('DriverID=SQLite');
  FDConnection1.Params.add('Database=' + dbpath);
  FDConnection1.Params.add('Password=' + password);
  FDConnection1.Params.add('UserName=' + username);
  // ournal Mode=WAL;
  FDConnection1.Params.add('ournal Mode=WAL');
  FDConnection1.Params.Pooled := true;
  FDConnection1.Open();

end;

destructor TSDBHelp.Destroy;
var
  i: integer;
begin

  for i := 0 to high(FDQuerys) do
  begin
    FDQuerys[i].Free;
  end;

  FDCommand1.Free;
  FDConnection1.Close;
  FDConnection1.Free;
  inherited;
end;

function TSDBHelp.execsql(sql: String): LongInt;
begin
  result := FDConnection1.execsql(sql);
end;

function TSDBHelp.execsql(const aSql: String; const AParams: array of Variant): LongInt;
begin
  result := FDConnection1.execsql(aSql, AParams);
end;

function TSDBHelp.getQuery: TFDQuery;
var
  i: integer;
begin
  result := nil;
  for i  := 0 to high(FDQuerys) do
  begin
    if not FDQuerys[i].Active then
    begin
      result := FDQuerys[i];
      break;
    end;
  end;
  if result = nil then
  begin
    i := Length(FDQuerys);
    SetLength(FDQuerys, i + 1);

    FDQuerys[i]            := TFDQuery.Create(nil);
    FDQuerys[i].Connection := FDConnection1;
    result                 := FDQuerys[i];
  end;

end;

procedure TSDBHelp.returnQuery;
begin

end;

{ TSQLDBHelp }

procedure TSQLDBHelp.SetConnectionParams;
var
  i: integer;
begin
  FDManager.CloseConnectionDef(FConnectionDefName);
  FDManager.ConnectionDefFileAutoLoad := false;
  // FDManager.ConnectionDefFileName := getexepath + 'config\def.ini';
  oDef := FDManager.ConnectionDefs.FindConnectionDef(FConnectionDefName);

  if oDef = nil then
  begin
    oDef := FDManager.ConnectionDefs.AddConnectionDef;
  end;

  oDef.Name                           := FConnectionDefName;
  oDef.Params.DriverID                := 'MSSQL';
  oDef.Params.Values['Server']        := FServer;
  oDef.Params.Database                := FDatabase;
  oDef.Params.username                := FUsername;
  oDef.Params.password                := FPassword;
  oDef.Params.Values['User_Name']     := FUsername;
  oDef.Params.Values['MetaDefSchema'] := 'dbo';
  oDef.Params.add('SharedCache=False');
  oDef.Params.add('LockingMode=Normal');
  oDef.Params.add('Synchronous=Full');
  oDef.Params.add('LockingMode=Normal');
  oDef.Params.add('CacheSize=60000');
  oDef.Params.add('BusyTimeOut=30000');
  oDef.Params.add('POOL_MaximumItems=1000');
  // oDef.Params.Values['MetaDefCatalog'] := FDatabase;
  // oDef.Params.Values['MonitorBy'] := 'Remote';
  // resourceoptions.autoreconnect

  oDef.Params.Pooled := true;
  // oDef.MarkPersistent;
  // FDManager.ConnectionDefs.Save;
  oDef.Apply;
end;

procedure TSQLDBHelp.AddCusProc(aProcName: String);
var
  aProcPool: TQSimplePool;
begin
  if not assigned(FCusProcs) then
    FCusProcs := TObjectDictionary<string, TQSimplePool>.Create();

  if FCusProcs.ContainsKey(aProcName) then
    exit;
  aProcPool := TQSimplePool.Create(100, FOnProcCreate, FOnProcFree, FOnProcReset);
  FCusProcs.add(aProcName, aProcPool);
  AtomicIncrement(FCusProcOutCount);
end;

function TSQLDBHelp.GetCusProc(aProcName: String): TFDStoredProc;
var
  proc: TFDStoredProc;
  con : TFDConnection;
begin
  AtomicIncrement(FProcCount);
  tmonitor.Enter(self);
  try

    result := nil;
    if not assigned(FCusProcs) then
      FCusProcs := TObjectDictionary<string, TQSimplePool>.Create();

    if not FCusProcs.ContainsKey(aProcName) then
      self.AddCusProc(aProcName);
  finally
    tmonitor.exit(self);
  end;
  result := TFDStoredProc(FCusProcs[aProcName].Pop);
  con    := FDFConnPool.Pop;

  result.Connection := con;

  // FMTimeAndFDClist.AddProc(aProcName, result);

  AtomicIncrement(FCusProcOutCount);
end;

procedure TSQLDBHelp.ReturnCusProc(aProcName: String; proc: TFDStoredProc; aRemoveWatch: boolean = true);
begin
  if not assigned(FCusProcs) then
    exit;
  try
    tmonitor.Enter(self);

    if FCusProcs.ContainsKey(aProcName) then
    begin
      try
        FDFConnPool.Push(proc.Connection);
      except
        on e: Exception do
          writeln('TSQLDBHelp.ReturnCusProc FDFConnPool.Push' + e.Message);
      end;

      FCusProcs[aProcName].Push(proc);

      // if aRemoveWatch then
      // FMTimeAndFDClist.RemoveProc(aProcName, proc);

      AtomicDecrement(FCusProcOutCount);
    end;
  finally
    tmonitor.exit(self);
  end;
end;

procedure TSQLDBHelp.AddCusQuery(aQueryName: String);
var
  aProcPool: TQSimplePool;
begin
  try
    tmonitor.Enter(self);

    if not assigned(FCusQuerys) then
      FCusQuerys := TObjectDictionary<string, TQSimplePool>.Create();

    if FCusQuerys.ContainsKey(aQueryName) then
      exit;
    aProcPool := TQSimplePool.Create(100, FOnQueryCreate_c, FOnQueryFree_c, FOnQueryReset_c);
    FCusQuerys.add(aQueryName, aProcPool);

    AtomicIncrement(FCusQueryOutCount);
  finally
    tmonitor.exit(self);
  end;
end;

function TSQLDBHelp.GetCusQuery(aQueryName: String): TFDQuery;
var
  qr : TFDQuery;
  con: TFDConnection;
begin
  try
    tmonitor.Enter(self);

    result := nil;
    if not assigned(FCusQuerys) then
      self.AddCusQuery(aQueryName)
    else if not FCusQuerys.ContainsKey(aQueryName) then
      self.AddCusQuery(aQueryName);
    begin
      con               := FDFConnPool.Pop;
      result            := TFDQuery(FCusQuerys[aQueryName].Pop);
      result.Connection := con;

      // FMTimeAndFDClist.AddQuery(aQueryName, result);
      AtomicIncrement(FCusQueryOutCount);
    end;
  finally
    tmonitor.exit(self);
  end;
end;

function TSQLDBHelp.GetProc: TFDStoredProc;
var
  con: TFDConnection;
begin
  try
    tmonitor.Enter(self);

    con               := FDFConnPool.Pop;
    result            := TFDStoredProc(FDProcPool.Pop);
    result.Connection := con;
  finally
    tmonitor.exit(self);
  end;
end;

function TSQLDBHelp.getQuery: TFDQuery;
var
  con: TFDConnection;
begin
  try
    tmonitor.Enter(self);

    result            := TFDQuery(FDQueryPool.Pop);
    con               := FDFConnPool.Pop; // TFDConnection.Create(nil);
    result.Connection := con;
  finally
    tmonitor.exit(self);
  end;
end;

procedure TSQLDBHelp.ReturnCusQuery(aQueryName: String; fdq: TFDQuery; aRemoveWatch: boolean = true);
var
  qr: TFDQuery;
begin
  try
    tmonitor.Enter(self);

    qr := TFDQuery(fdq);

    if not assigned(FCusQuerys) then
      exit;
    if FCusQuerys.ContainsKey(aQueryName) then
    begin
      FDFConnPool.Push(fdq.Connection);
      FCusQuerys[aQueryName].Push(fdq);
      // if aRemoveWatch then
      // FMTimeAndFDClist.RemoveQuery(aQueryName, fdq);
      AtomicDecrement(FCusQueryOutCount);
    end;
  finally
    tmonitor.exit(self);
  end;
end;

procedure TSQLDBHelp.ReturnProc(fdq: TFDStoredProc);
begin
  // fdq.Connection.Close;
  tmonitor.Enter(self);
  try
    if fdq.Active then
      fdq.Close;
    FDFConnPool.Push(fdq.Connection);
    FDProcPool.Push(fdq);
  finally
    tmonitor.exit(self);
  end;
end;

procedure TSQLDBHelp.returnQuery(fdq: TFDQuery);
begin
  try
    tmonitor.Enter(self);

    if fdq.Active then
      fdq.Close;
    FDFConnPool.Push(fdq.Connection);
    FDQueryPool.Push(fdq);
  finally
    tmonitor.exit(self);
  end;
end;

procedure TSQLDBHelp.ConnOnLost(ASender: TObject);
var
  Conn: TFDConnection;
begin
  try
    tmonitor.Enter(self);

    Conn := TFDConnection(ASender);
    Conn.Close;
    // try
    SetConnectionParams();
    // except
    // on e: exception do
    // logs.Post(llerror, 'ConnOnLost setConnectionParams ' + e.Message);
    // end;
  finally
    tmonitor.exit(self);
  end;
end;

constructor TSQLDBHelp.Create(aServer, ausername, apassword, aDatabase: string);
var
  i: integer;
begin
  FID        := random(10000000);
  FProcCount := 0;
  // FMTimeAndFDClist  := TMTimeAndFDClist.Create(self);
  FCusQueryOutCount := 0;
  FCusProcOutCount  := 0;

  FConnectionDefName := 'MSSQL_Connection';
  // FDConnection1 := TFDConnection.Create(nil);
  // FDConnection1.LoginPrompt := false;
  if aDatabase = '' then
    aDatabase := 'master';
  FServer     := aServer;
  FUsername   := ausername;
  FPassword   := apassword;
  FDatabase   := aDatabase;
  if (FServer <> '') then
    SetConnectionParams;

  FCusProcOutList  := TDictionary<TFDQuery, TFDConnection>.Create;
  FCusQueryOutList := TDictionary<TFDStoredProc, TFDConnection>.Create;

  // FDCommand1 := TFDCommand.Create(nil);

  FDFConnPool := TQSimplePool.Create(1000, FOnConnCreate, FOnConnFree, FOnConnReset);

  FDPhysMSSQLDriverLink1  := TFDPhysMSSQLDriverLink.Create(nil);
  FDMoniRemoteClientLink1 := TFDMoniRemoteClientLink.Create(nil);

  FDQueryPool := TQSimplePool.Create(100, FOnQueryCreate_c, FOnQueryFree_c, FOnQueryReset_c);
  FDProcPool  := TQSimplePool.Create(100, FOnProcCreate, FOnProcFree, FOnProcReset);

  FCusOutWatchHandle := workers.Delay(CusOutWatch, 10000 * 60 * PbCusOutTimeout, nil, false, jdfFreeByUser, true);

end;

procedure TSQLDBHelp.CusOutWatch(aJob: PQJob);
begin
  if self.FCusQueryOutCount > 0 then
  begin
    // while FMTimeAndFDClist.CheckFirst do;
  end;
end;

destructor TSQLDBHelp.Destroy;
var
  i  : integer;
  key: String;
begin
  FCusProcOutList.Free;
  FCusQueryOutList.Free;
  workers.ClearSingleJob(FCusOutWatchHandle, false);
  // FMTimeAndFDClist.Free;

  if FCusProcs <> nil then
  begin
    for key in FCusProcs.Keys do
      TQSimplePool(FCusProcs[key]).Free;

    FCusProcs.Free;
  end;

  if assigned(FCusQuerys) then
  begin
    for key in FCusQuerys.Keys do
      TQSimplePool(FCusQuerys[key]).Free;
    FCusQuerys.Free;
  end;

  FDQueryPool.Free;
  FDProcPool.Free;

  FDFConnPool.Free;

  FDManager.CloseConnectionDef(FConnectionDefName);

  FDPhysMSSQLDriverLink1.Free;

  FDMoniRemoteClientLink1.Free;

  inherited;
end;

function TSQLDBHelp.execsql(sql: String): LongInt;
var
  con: TFDConnection;
begin
  con := FDFConnPool.Pop;
  try
    result := con.execsql(sql);
  finally
    FDFConnPool.Push(con);
  end;
end;

function TSQLDBHelp.execsql(const aSql: String; const AParams: array of Variant): LongInt;
var
  con: TFDConnection;
begin
  con := self.FDFConnPool.Pop;
  try
    result := con.execsql(aSql, AParams);
  finally
    FDFConnPool.Push(con);
  end;
end;

procedure TSQLDBHelp.FOnQueryCreate_c(Sender: TQSimplePool; var AData: Pointer);
var
  qr : TFDQuery;
  con: TFDConnection;
begin

  AtomicIncrement(PbQueryCount);
  qr                   := TFDQuery.Create(nil);
  qr.FetchOptions.Mode := TFDFetchMode.fmAll; // cmTotal;

  qr.FetchOptions.AutoClose := false; // 支持多数据集
  AData                     := qr;
end;

procedure TSQLDBHelp.FOnQueryFree_c(Sender: TQSimplePool; AData: Pointer);
var
  qr: TFDQuery;
begin
  qr := TFDQuery(AData);
  if qr.Active then
    qr.Active := false;
  if qr.Connection <> nil then
  begin

  end;
  AtomicDecrement(PbQueryCount);
  freeandnil(qr);
end;

procedure TSQLDBHelp.FOnQueryReset_c(Sender: TQSimplePool; AData: Pointer);
begin

end;

procedure TSQLDBHelp.FOnConnCreate(ASender: TQSimplePool; var AData: Pointer);
var
  con: TFDConnection;
begin
  AtomicIncrement(PbConnCount);
  con                               := TFDConnection.Create(nil);
  con.LoginPrompt                   := false;
  con.OnLost                        := self.ConnOnLost;
  con.ConnectionDefName             := FConnectionDefName;
  con.ResourceOptions.autoreconnect := true;
  AData                             := con;
end;

procedure TSQLDBHelp.FOnConnFree(ASender: TQSimplePool; AData: Pointer);
var
  con: TFDConnection;
begin
  try
    // tmonitor.Enter(self);
    try
      con := TFDConnection(AData);
      if con.Connected then
        con.Close;
    finally
      // tmonitor.exit(self);
    end;
  except
    on e: Exception do
    begin
      writeln('TSQLDBHelp.FOnConnFree ' + e.Message);
    end;
  end;
  freeandnil(AData);
  AtomicDecrement(PbConnCount);
end;

procedure TSQLDBHelp.FOnConnReset(ASender: TQSimplePool; AData: Pointer);
begin

end;

procedure TSQLDBHelp.FOnProcCreate(ASender: TQSimplePool; var AData: Pointer);
var
  proc: TFDStoredProc;
  con : TFDConnection;
begin

  AtomicIncrement(FProcCount);
  AtomicIncrement(PbProcCount);

  proc      := TFDStoredProc.Create(nil);
  proc.Name := format('Proc%d_%d', [FProcCount, random(100000)]);
  // proc.Connection := con;
  proc.FetchOptions.AutoClose := false; // 支持多数据集
  AData                       := proc;

end;

procedure TSQLDBHelp.FOnProcFree(ASender: TQSimplePool; AData: Pointer);
var
  proc: TFDStoredProc;
begin
  try

    proc := TFDStoredProc(AData);

    if proc.Active then
      proc.Active := false;
    if proc.Connection <> nil then
    begin
      // proc.Connection.Close;
      // proc.Connection.Free;
    end;
    freeandnil(AData);
  except
    on e: Exception do
    begin
      writeln('TSQLDBHelp.FOnProcFree ' + e.Message);
    end;

  end;
  AtomicDecrement(PbProcCount);
end;

procedure TSQLDBHelp.FOnProcReset(ASender: TQSimplePool; AData: Pointer);
var
  proc: TFDStoredProc;
begin
  proc := TFDStoredProc(AData);
end;

function TSQLDBHelp.GetConn: TFDConnection;
begin
  tmonitor.Enter(self);
  try
    result := TFDConnection(FDFConnPool.Pop);
  finally
    tmonitor.exit(self);
  end;
end;

procedure TSQLDBHelp.ReturnConn(fdq: TFDConnection);
begin
  tmonitor.Enter(self);
  try
    FDFConnPool.Push(fdq);
  finally
    tmonitor.exit(self);
  end;
end;

procedure TSQLDBHelp.setDatabase(Value: string);
begin
  self.FDatabase := Value;
end;

procedure TSQLDBHelp.setPassword(Value: string);
begin
  self.FPassword := Value;
end;

procedure TSQLDBHelp.setServer(Value: string);
begin
  self.FServer := Value;
end;

procedure TSQLDBHelp.setUsername(Value: string);
begin
  self.FUsername := Value;
end;

{ TSQLDBHelps }

constructor TSQLDBHelps.Create;
begin
  FLock := TCriticalSection.Create;
  FaTs  := TList<TSQLDBHelp>.Create;
end;

destructor TSQLDBHelps.Destroy;
var
  i: integer;
begin
  FLock.Leave;
  FLock.Free;
  for i := (FaTs.Count) - 1 downto 0 do
  begin
    TSQLDBHelp(FaTs[i]).Free;
  end;
  FaTs.Free;
  inherited;
end;

function TSQLDBHelps.get(const aServer, aUser, aPwd, aDbName: String): TSQLDBHelp;
var
  i: integer;
begin
  FLock.Enter;
  try
    result := nil;

    for i := 0 to FaTs.Count - 1 do
    begin
      if FaTs[i].Server = aServer then
      begin
        result := FaTs[i];
        exit;
      end;
    end;

    result := TSQLDBHelp.Create(aServer, aUser, aPwd, aDbName);

    FaTs.add(result);

  finally
    FLock.Leave;
  end;

end;

function TSQLDBHelps.get(const sv: TQJson): TSQLDBHelp;
var
  i: integer;
begin
  //      outputdebugstring(pchar(sv.ToString()));
  result := get(sv.ItemByName('Server').AsString, sv.ItemByName('Username').AsString,
    sv.ItemByName('Password').AsString, sv.ItemByName('Database').AsString);

end;

procedure freeTSQLDBHelps();
begin
  SQLDBHelps.Free;
end;

{ TMTimeAndFDClist }

procedure TMTimeAndFDClist.AddProc(aSql: String; aProc: TFDStoredProc);
var
  aMTimeAndFDC: TMTimeAndFDC;
begin
  FLock.Enter;
  try
    aMTimeAndFDC.time  := now();
    aMTimeAndFDC.sql   := aSql;
    aMTimeAndFDC.proc  := aProc;
    aMTimeAndFDC.qandp := false;
    FList.add(aMTimeAndFDC);
  finally
    FLock.Leave;
  end;
end;

procedure TMTimeAndFDClist.AddQuery(aSql: String; aQuery: TFDQuery);
var
  aMTimeAndFDC: TMTimeAndFDC;
begin
  FLock.Enter;
  try
    aMTimeAndFDC.sql   := aSql;
    aMTimeAndFDC.time  := now();
    aMTimeAndFDC.query := aQuery;
    aMTimeAndFDC.qandp := true;
    FList.add(aMTimeAndFDC);
  finally
    FLock.Leave;
  end;
end;

function TMTimeAndFDClist.CheckFirst: boolean;
var
  m: integer;
begin
  result := false;
  FLock.Enter;
  try
    if FList.Count = 0 then
      exit;
    m := dateutils.MinutesBetween(FList[0].time, now());
    if dateutils.MinutesBetween(FList[0].time, now()) > PbCusOutTimeout then
    begin
      if FList[0].qandp then
        FSDBHelp.ReturnCusQuery(FList[0].sql, FList[0].query, false)
      else
        FSDBHelp.ReturnCusProc(FList[0].sql, FList[0].proc, false);
      FList.Delete(0);
    end;
  finally
    FLock.Leave;
  end;
end;

constructor TMTimeAndFDClist.Create(aSDBHelp: TSQLDBHelp);
begin
  { self.FPoolCon := aPoolCon;
    self.FPoolProc := aPoolProc;
    self.FPoolQuery := aPoolQuery;
  }
  FSDBHelp := aSDBHelp;
  FLock    := TCriticalSection.Create;
  FList    := TList<TMTimeAndFDC>.Create;
end;

destructor TMTimeAndFDClist.Destroy;
begin
  FLock.Enter;
  try
    FList.Free;
  finally
    FLock.Leave;
    FLock.Free;
  end;

  inherited;
end;

function TMTimeAndFDClist.getCount: integer;
begin
  FLock.Enter;
  try
    result := self.FList.Count;
  finally
    FLock.Leave;
  end;
end;

procedure TMTimeAndFDClist.RemoveProc(aSql: String; aProc: TFDStoredProc);
var
  i: integer;
begin
  FLock.Enter;
  try
    for i := FList.Count - 1 downto 0 do
    begin
      if (FList[i].sql = aSql) and (FList[i].proc = aProc) then
        FList.Delete(i);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TMTimeAndFDClist.RemoveQuery(aSql: String; aQuery: TFDQuery);
var
  i: integer;
begin
  FLock.Enter;
  try
    for i := FList.Count - 1 downto 0 do
    begin
      if (FList[i].sql = aSql) and (FList[i].query = aQuery) then
        FList.Delete(i);
    end;
  finally
    FLock.Leave;
  end;

end;

initialization

SQLDBHelps := TSQLDBHelps.Create;
// SQLDBHelp := TSQLDBHelp.Create('192.168.254.162', 'sa', 'Mu@1234.com', 'DCCDB');

finalization

freeTSQLDBHelps;
// SQLDBHelp.Free;

end.
