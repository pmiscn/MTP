unit MTP.QMathExpr.Extend;

interface

uses System.SysUtils, Variants, System.classes, qstring, // ListEngine,
  QMathExpr, winapi.windows;

type
  TQMathExpression_ = class helper for TQMathExpression
    public
      procedure CusReg;
      procedure RegFromDll(aDllFile: String; aNameSpace: String = '');
  end;

  TDLLFile = record
    FileName: String;
    Handle: THandle;
  end;

  TDLLFiles = TArray<TDLLFile>;

  TRunTimeDll = class(TObject)
    private
      // ProcList: THashList;
    public
      constructor Create;
      destructor Destroy; override;
  end;

implementation

uses mu.fileinfo, qjson, dateutils;

var
  DLlfiles: TDLLFiles;

procedure _Number(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  i: Integer;
  d: Tdatetime;
  v: TQMathVar;
begin
  i := length(AVar.Params);
  if i > 0 then
    AResult := Double(AVar.Params[0].Value)
  else
    AResult := null;
end;

procedure _Str(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  i: Integer;
  d: Tdatetime;
  v: TQMathVar;
begin
  i := length(AVar.Params);
  if i > 0 then
    AResult := Vartostr(AVar.Params[0].Value);
end;

procedure _Trim(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  i: Integer;
  d: Tdatetime;
  v: TQMathVar;
begin
  i := length(AVar.Params);
  if i > 0 then
    AResult := Trim(AVar.Params[0].Value);
end;

procedure _Length(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  i: Integer;
  d: Tdatetime;
  v: TQMathVar;
begin
  i := length(AVar.Params);
  if i > 0 then
    AResult := length(AVar.Params[0].Value);
end;

procedure _JsonLength(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  i : Integer;
  d : Tdatetime;
  v : TQMathVar;
  js: TQJson;
begin
  i       := length(AVar.Params);
  AResult := 0;
  if i > 0 then
  begin
    js := qjson.AcquireJson;
    try
      if js.TryParse(AVar.Params[0].Value) then
        AResult := js.Count
    finally
      qjson.ReleaseJson(js);
    end;

  end;
end;

procedure _IntToStr(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  s: String;
  i: Integer;
begin
  AResult := (AVar.Params[0].Value)
end;

procedure _StrToInt(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  s: int64;
  i: Integer;
begin
  AResult := int64(AVar.Params[0].Value)
end;

procedure _SubStr(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  s: String;
  i: Integer;
begin
  with AVar do
    case length(Params) of
      0:
        AResult := '';
      1:
        AResult := Params[0].Value;
      2:
        begin
          s       := Vartostr(Params[0].Value);
          i       := Integer(Params[1].Value);
          AResult := s.Substring(i);
        end;
      3 .. 9:
        begin
          s       := Vartostr(Params[0].Value);
          i       := Integer(Params[1].Value);
          AResult := s.Substring(i, Params[2].Value)
        end;
    end;
end;

procedure _Replace(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  s: String;
begin
  with AVar do
  begin
    s       := Vartostr(AVar.Params[0].Value);
    AResult := s.Replace(Vartostr(Params[1].Value), Vartostr(Params[2].Value));
  end;
end;

procedure _SplitByIndex(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  s, sp: String;
  sa   : TArray<string>;
  i    : Integer;
begin
  AResult := '';
  with AVar do
  begin
    s  := Vartostr(AVar.Params[0].Value);
    sp := Vartostr(AVar.Params[1].Value);
    if sp = '' then
      sp := ' ';
    sa   := s.Split(sp[1]);
    if VarIsNumeric(AVar.Params[2].Value) then
      i := AVar.Params[2].Value
    else
      i := 0;
    if i < length(sa) then
      AResult := sa[i];
  end;
end;

procedure _CharIndex(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
begin
  with AVar do
  begin
    case length(Params) of
      2:
        AResult := pos(Vartostr(Params[0].Value), Vartostr(Params[1].Value)) - 1;
      3:
        AResult := pos(Vartostr(Params[0].Value), Vartostr(Params[1].Value), strtoint(Vartostr(Params[2].Value))) - 1;

    end;

  end;
end;

procedure _Remove(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  s: String;
  i: Integer;
begin
  with AVar do
    case length(Params) of
      0:
        AResult := '';
      1:
        AResult := Params[0].Value;
      2:
        begin
          s       := Vartostr(Params[0].Value);
          i       := Params[1].Value;
          AResult := s.Remove(i)
        end;
      3 .. 9:
        begin
          s       := Vartostr(Params[0].Value);
          i       := Params[1].Value;
          AResult := s.Remove(i, (Params[2].Value))
        end;
    end;
end;

procedure _Insert(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  s: String;
  i: Integer;
begin
  with AVar do
  begin
    s := Params[0].Value;
    case length(Params) of
      1:
        AResult := Params[0].Value;
      2:
        begin
          s       := Vartostr(Params[0].Value);
          AResult := s.Insert(0, Vartostr(Params[1].Value))
        end;
      3 .. 9:
        begin
          s       := Vartostr(Params[0].Value);
          i       := Params[1].Value;
          AResult := s.Insert(i, Vartostr(Params[2].Value))
        end;
    end;
    AResult := s;
  end;
end;

procedure _RemoveStr(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  s: String;
  i: Integer;
begin
  with AVar do
  begin
    s       := Params[0].Value;
    for i   := 1 to High(Params) do
      s     := s.Replace(Vartostr(Params[i].Value), '');
    AResult := s;
  end;
end;

procedure _Format(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  i : Integer;
  ar: array of Variant;
begin
  { setlength(ar, length(Param) - 1);

    for i := 1 to high(Param) do
    ar[i - 1] := Param[i];
    result := format(Param[0], ar);
  }
  with AVar do
  begin
    case High(Params) of
      1:
        AResult := Params[0].Value;
      2:
        AResult := format(Params[0].Value, [Params[1].Value]);
      3:
        AResult := format(Params[0].Value, [Params[1].Value, Params[2].Value]);
      4:
        AResult := format(Params[0].Value, [Params[1].Value, Params[2].Value, Params[3].Value]);
      5:
        AResult := format(Params[0].Value, [Params[1].Value, Params[2].Value, Params[3].Value, Params[4].Value]);
      6:
        AResult := format(Params[0].Value, [Params[1].Value, Params[2].Value, Params[3].Value, Params[4].Value,
          Params[5].Value]);
      7:
        AResult := format(Params[0].Value, [Params[1].Value, Params[2].Value, Params[3].Value, Params[4].Value,
          Params[5].Value, Params[6].Value]);
      8:
        AResult := format(Params[0].Value, [Params[1].Value, Params[2].Value, Params[3].Value, Params[4].Value,
          Params[5].Value, Params[6].Value, Params[7].Value]);
      9:
        AResult := format(Params[0].Value, [Params[1].Value, Params[2].Value, Params[3].Value, Params[4].Value,
          Params[5].Value, Params[6].Value, Params[7].Value, Params[8].Value]);
      10:
        AResult := format(Params[0].Value, [Params[1].Value, Params[2].Value, Params[3].Value, Params[4].Value,
          Params[5].Value, Params[6].Value, Params[7].Value, Params[8].Value, Params[9].Value]);
    end;
  end;
end;


// Datetiem

procedure _FormatDatetime(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
begin
  with AVar do
  begin
    case length(Params) of
      1:
        AResult := formatdatetime('yyyy-MM-dd hh:mm:ss', qstring.DateTimeFromString(Params[1].Value));
      2:
        AResult := formatdatetime(Params[0].Value, qstring.DateTimeFromString(Params[1].Value));
    end;
  end;
end;

procedure _now(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
begin
  AResult := now();
end;

procedure _DayOfMonth(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
var
  i: Integer;
  d: Tdatetime;
  v: TQMathVar;
begin
  // d := arctan2(aexpr.Params[0].GetValueEx(ACallParams), aexpr.Params[1].GetValueEx(ACallParams));
  i := length(AVar.Params);
  // v := AVar.Params[0];
  d       := qstring.DateTimeFromString(AVar.Params[0].Value);
  AResult := DayOfTheMonth(d);
end;

{ TQMathExpression_ }

procedure TQMathExpression_.CusReg;
begin
  Self.Add('IntToStr', 1, 1, _IntToStr, mvVolatile);
  Self.Add('StrToInt', 1, 1, _StrToInt, mvVolatile);

  Self.Add('SubStr', 2, 3, _SubStr, mvVolatile);
  Self.Add('CharIndex', 2, 3, _CharIndex, mvVolatile);
  Self.Add('Replace', 2, 3, _Replace, mvVolatile);
  Self.Add('Remove', 2, 3, _Remove, mvVolatile);
  Self.Add('RemoveStr', 2, 3, _RemoveStr, mvVolatile);
  Self.Add('Insert', 3, 3, _Insert, mvVolatile);

  Self.Add('Format', 2, 10, _Format, mvVolatile);
  Self.Add('FormatDatetime', 1, 2, _FormatDatetime, mvVolatile);
  Self.Add('Now', 1, 1, _now, mvVolatile);

  Self.Add('DayOfMonth', 1, 1, _DayOfMonth, mvVolatile);
  Self.Add('Number', 1, 1, _Number, mvVolatile);
  Self.Add('Str', 1, 1, _Str, mvVolatile);
  Self.Add('Trim', 1, 1, _Trim, mvVolatile);
  Self.Add('Length', 1, 1, _Length, mvVolatile);
  Self.Add('JsonLength', 1, 1, _JsonLength, mvVolatile);
  Self.Add('SplitByIndex', 3, 3, _SplitByIndex, mvVolatile);

end;

function getdllhandle(aFileName: String): THandle;
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
  DLlfiles[i].Handle   := LoadLibrary(PWideChar(aFileName));
  result               := DLlfiles[i].Handle;
end;

procedure TQMathExpression_.RegFromDll(aDllFile, aNameSpace: String);
var
  st  : Tstringlist;
  i   : Integer;
  h   : THandle;
  regn: string;
begin
  if aDllFile = '' then
    exit;
  if pos(':', aDllFile) < 1 then
  begin
    if aDllFile[1] = '\' then
      System.delete(aDllFile, 1, 1);
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

    h     := getdllhandle(aDllFile);
    for i := 0 to st.Count - 1 do
    begin
      regn := aNameSpace + '.' + st[i]; // DateTime.GetDate
      Self.Add(regn, 0, maxint, TQMathValueEventG(GetProcAddress(h, PWideChar(st[i]))));

    end;
  finally
    st.Free;
  end;

end;

{ TRunTimeDll }

constructor TRunTimeDll.Create;
begin
  // ProcList := THashList.Create;
end;

destructor TRunTimeDll.Destroy;
begin

  inherited;
end;

end.
