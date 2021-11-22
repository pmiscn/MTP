unit Unit_pub;

interface

uses messages;

const
  wm_resetThread = wm_user + 1026;

type
  TLocalsetup = record

    httptype: integer;

    logsLevel: integer;

    httptimeout: integer;
    ShowException: boolean;

    showlog: boolean;
    showlevel: integer;

  end;

var
  localsetup: TLocalsetup;

var
  successcount    : integer;
  AppLicationClose: boolean = false;

procedure loadLocalsetup();

implementation

uses inifiles, mu.fileinfo;

procedure loadLocalsetup();
var
  inf: TIniFile;
begin
  inf := TIniFile.Create(getexepath + 'config\config.ini');
  try

    localsetup.httptimeout   := inf.ReadInteger('http', 'httptimeout', 20);
    localsetup.ShowException := inf.ReadBool('http', 'ShowException', false);

    localsetup.httptype := inf.ReadInteger('http', 'httptype', 0);

    localsetup.showlog   := inf.ReadBool('logs', 'showlog', true);
    localsetup.logsLevel := inf.ReadInteger('logs', 'logsLevel', -2);
    localsetup.showlevel := inf.ReadInteger('logs', 'showlevel', 5);

  finally
    inf.Free;
  end;
end;

initialization

successcount := 0;
loadLocalsetup();

finalization

end.
