unit MTP.Logs;

interface

uses
  Windows, Messages, SysUtils, // uConsoleClass, Unit_Console_Ext,
  Variants, Classes, SyncObjs, Generics.Collections,
  qlog;

type



  TMLogStatusValue = record
    StatusStr: String;
    StatusID: Integer;
  end;

  TMLog = class(TObject)
  protected
    FIndex: Integer;
    FLogmark: String;
  public
    procedure log(s: String; l: Integer = 9); overload;
    procedure log(s: String; p: array of const; l: Integer = 9); overload;

    property index: Integer read FIndex write FIndex default -1;
    property mark: String read FLogmark write FLogmark;
  end;

procedure addLogs(s: string; level: Integer = 0); overload;
procedure addLogs(s: string; p: Array of const; level: Integer = 0); overload;

// var
// pubLogLevel: Integer = 9;

implementation

uses unit_pub, mu.fileinfo;

procedure addLogs(s: string; p: Array of const; level: Integer = 0);
begin
   addLogs(format(s, p), level);
end;

procedure addLogs(s: string; level: Integer = 0);
var
  ll: TQLogLevel;
begin
  if localsetup.showlevel >= level then
    if localsetup.showlog or (level <= 0) then
    begin
      try
        writeln(formatdatetime('hh:mm:ss', now()) + '  ' + s);
      except
      end;
    end;

  if localsetup.logsLevel < level then
    exit;
  case level of
    9:
      ll := lldebug;
    8:
      ll := lldebug;
    7:
      ll := llMessage;
    6:
      ll := llMessage;
    5:
      ll := llHint;
    4:
      ll := llWarning;
    3:
      ll := llError;
    2:
      ll := llFatal;
    1:
      ll := llAlert;
    0:
      ll := llError;
  end;
  qlog.PostLog(ll, s);
end;


{ TMLog }

procedure TMLog.log(s: String; p: array of const; l: Integer);
begin
  try
    log(format(s, p), l);
  except
  end;
end;

procedure TMLog.log(s: String; l: Integer);
  function ls(ss: String): string;
  begin
    while length(ss) < 3 do
      ss := ' ' + ss;
    result := ss;
  end;

begin
  if FIndex >= 0 then
  begin
    if self.FLogmark <> '' then
      addLogs(format('%s %3d %s', [self.FLogmark, self.index, s]), l)
    else
      addLogs(format('%s %s', [self.FLogmark, s]), l);
  end
  else
  begin
    if self.FLogmark <> '' then
      addLogs(self.FLogmark + ' ' + s, l)
    else
      addLogs(s, l);
  end;
end;

initialization

qlog.SetDefaultLogFile(getexepath() + 'logs\log.log', 20000000)

  finalization

end.
