unit opCode_Help;

interface

uses System.SysUtils, Variants, System.classes, qstring,
  opCode, ListEngine, PascalStrings, winapi.windows;

type
  TOpCustomRunTime_ = class helper for TOpCustomRunTime
  public
    procedure CusReg;
    procedure RegFromDll(aDllFile: String; aNameSpace: String = '');
  end;

  TDLLFile = record
    FileName: String;
    Handle: Thandle;
  end;

  TDLLFiles = Tarray<TDLLFile>;

  TRunTimeDll = class(TObject)
  private
    ProcList: THashList;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses dateutils, mu.fileinfo;

var
  DLlfiles: TDLLFiles;

function _IntToStr(var Param: TOpParam): Variant;
var
  s: String;
  i: Integer;
begin
  s := '';
  for i := low(Param) to high(Param) do
    s := s + Inttostr(Param[i]);
  result := s;
end;

function _StrToInt(var Param: TOpParam): Variant;
var
  s: int64;
  i: Integer;
begin
  s := 0;
  for i := low(Param) to high(Param) do
    s := s + strtoInt(Param[i]);
  result := s;
end;

function _SubStr(var Param: TOpParam): Variant;
var
  s: String;
  i: Integer;
begin
  case length(Param) of
    0:
      result := '';
    1:
      result := Param[0];
    2:
      begin
        s := Vartostr(Param[0]);
        i := Param[1];
        result := s.Substring(i)
      end;
    3 .. 9:
      begin
        s := Vartostr(Param[0]);
        i := Param[1];
        result := s.Substring(i, Param[2])
      end;
  end;
end;

function _Replace(var Param: TOpParam): Variant;
var
  s: String;
begin
  s := Vartostr(Param[0]);
  result := s.Replace(Vartostr(Param[1]), Vartostr(Param[2]));
end;

function _CharIndex(var Param: TOpParam): Variant;
begin
  result := pos(Vartostr(Param[0]), Vartostr(Param[1])) - 1;
end;

function _Remove(var Param: TOpParam): Variant;
var
  s: String;
  i: Integer;
begin
  case length(Param) of
    0:
      result := '';
    1:
      result := Param[0];
    2:
      begin
        s := Vartostr(Param[0]);
        i := Param[1];
        result := s.Remove(i)
      end;
    3 .. 9:
      begin
        s := Vartostr(Param[0]);
        i := Param[1];
        result := s.Remove(i, (Param[2]))
      end;
  end;
end;

function _Insert(var Param: TOpParam): Variant;
var
  s: String;
  i: Integer;
begin
  s := Param[0];
  case length(Param) of
    1:
      result := Param[0];
    2:
      begin
        s := Vartostr(Param[0]);
        result := s.Insert(0, Vartostr(Param[1]))
      end;
    3 .. 9:
      begin
        s := Vartostr(Param[0]);
        i := Param[1];
        result := s.Insert(i, Vartostr(Param[2]))
      end;
  end;
  result := s;
end;

function _RemoveStr(var Param: TOpParam): Variant;
var
  s: String;
  i: Integer;
begin
  s := Param[0];
  for i := 1 to High(Param) do
    s := s.Replace(Vartostr(Param[i]), '');
  result := s;
end;

function _Format(var Param: TOpParam): Variant;
var
  i: Integer;
  ar: array of Variant;
begin
  { setlength(ar, length(Param) - 1);

    for i := 1 to high(Param) do
    ar[i - 1] := Param[i];
    result := format(Param[0], ar);
  }
  case High(Param) of
    1:
      result := Param[0];
    2:
      result := format(Param[0], [Param[1]]);
    3:
      result := format(Param[0], [Param[1], Param[2]]);
    4:
      result := format(Param[0], [Param[1], Param[2], Param[3]]);
    5:
      result := format(Param[0], [Param[1], Param[2], Param[3], Param[4]]);
    6:
      result := format(Param[0], [Param[1], Param[2], Param[3], Param[4], Param[5]]);
    7:
      result := format(Param[0], [Param[1], Param[2], Param[3], Param[4], Param[5], Param[6]]);
    8:
      result := format(Param[0], [Param[1], Param[2], Param[3], Param[4], Param[5], Param[6], Param[7]]);
    9:
      result := format(Param[0], [Param[1], Param[2], Param[3], Param[4], Param[5], Param[6], Param[7], Param[8]]);
    10:
      result := format(Param[0], [Param[1], Param[2], Param[3], Param[4], Param[5], Param[6], Param[7], Param[8],
        Param[9]]);
  end;

end;


// Datetiem

function _FormatDatetime(var Param: TOpParam): Variant;
begin
  result := formatdatetime(Param[0], Param[1]);
end;

function _now(var Param: TOpParam): Variant;
begin
  result := now();
end;

procedure TOpCustomRunTime_.CusReg;
begin
  Self.RegOpC('IntToStr', _IntToStr);
  Self.RegOpC('StrToInt', _StrToInt);

  Self.RegOpC('SubStr', _SubStr);
  Self.RegOpC('CharIndex', _CharIndex);
  Self.RegOpC('Replace', _Replace);
  Self.RegOpC('Remove', _Remove);
  Self.RegOpC('RemoveStr', _RemoveStr);
  Self.RegOpC('Insert', _Insert);

  Self.RegOpC('Format', _Format);
  Self.RegOpC('FormatDatetime', _FormatDatetime);
  Self.RegOpC('Now', _now);

  Self.RegOpP('DayOfMonth',
    function(var Param: TOpParam): Variant
    var
      d: Tdatetime;
    begin
      d := qstring.DateTimeFromString(Param[0]);
      result := DayOfTheMonth(d);
    end);


end;

function fromdll(dllname: String; var Param: TOpParam): Variant;
begin
  result := now();
end;

function getdllhandle(aFileName: String): Thandle;
var
  i: Integer;
begin
  for i := Low(DLlfiles) to High(DLlfiles) do
  begin
    if DLlfiles[i].FileName = aFileName then
      exit(DLlfiles[i].Handle);
  end;

  i := length(DLlfiles);
  setlength(DLlfiles, i + 1);
  DLlfiles[i].FileName := aFileName;
  DLlfiles[i].Handle := LoadLibrary(PWideChar(aFileName));
  result := DLlfiles[i].Handle;
end;

procedure TOpCustomRunTime_.RegFromDll(aDllFile, aNameSpace: String);
var
  st: Tstringlist;
  i: Integer;
  h: Thandle;
  regn: string;
begin
  if aDllFile = '' then
    exit;
  if pos(':', aDllFile) < 1 then
  begin
    if aDllFile[1] = '\' then
      delete(aDllFile, 1, 1);
    aDllFile := getexepath + aDllFile;
  end;
  if not fileexists(aDllFile) then
    exit;

  st := Tstringlist.Create;
  try
    TLocalFileInfo.GetDLLInfo(aDllFile, st);
    if st.Count = 0 then
      exit;
    if aNameSpace = '' then
      aNameSpace := changefileext(extractfilename(aDllFile), '');

    h := getdllhandle(aDllFile);
    for i := 0 to st.Count - 1 do
    begin
      regn := aNameSpace + '_' + st[i]; // DateTime.GetDate
      Self.RegOpC(regn, TOnOpCall(GetProcAddress(h, PWideChar(st[i]))));
      {
        Self.RegOpP(aNameSpace + '.' + st[i],
        function(var Param: TOpParam): Variant
        begin
        result := fromdll(aDllFile, st[i], Param); // now();
        end);
      }
    end;
  finally
    st.Free;
  end;
end;

{ TRunTimeDll }

constructor TRunTimeDll.Create;
begin
  ProcList := THashList.Create;
end;

destructor TRunTimeDll.Destroy;
begin

  inherited;
end;

end.
