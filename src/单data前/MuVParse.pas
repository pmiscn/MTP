unit MuVParse;

interface

uses System.SysUtils, Variants, System.classes,
  windows,
  CoreClasses, CoreCompress, DataFrameEngine, DoStatusIO, Fast_MD5,
  GeometryLib, ZS_JsonDataObjects, ListEngine,
  MemoryStream64, opCode, opCode_Help,
  PascalStrings, TextDataEngine, TextParsing, UnicodeMixedLib, zExpression,

  qjson, qrbtree, qmacros, qstring;

const
  EXStart = '<%';
  EXEnd = '%>';
  EXPrefix = '@';
  EXInnerChar = '_';

var
  publicVarInt: integer;
  SpecialAsciiToken: TListPascalString;

 
type
  TMVParse = class(TObject)
  private
    FCurPath: string;
    procedure initRuntime();
    function LoadTextFromFile(aFileName: String): TPascalString;
    procedure QMacroMissEvent(ASender: TQMacroManager; AName: QStringW;
      const AQuoter: QCharW; var AHandled: Boolean);
  protected
    FFixText: TPascalString;
    FMacroMgr: TQMacroManager;
    FComplied: TQMacroComplied;
    FIsGetMacro: Boolean;
    FBaseMacroPoint: integer;
    FMacroList: TStringList;

    FData: TQJson;
    FtmpData: TQJson;
    FOpCustomRunTime: TOpCustomRunTime;
    function fixInclude(): integer;
    function GetOutText: TPascalString;
    function GetData(AName: String; aJdata: TQJson = nil;
      aAllowOwn: Boolean = false): TPascalString; overload;

    function TryGetData(AName: String; var r: TPascalString;
      aJdata: TQJson = nil; aAllowOwn: Boolean = false): Boolean;

    function foreachdo(aPathName: String; aOutput: String; aStart: integer = 0;
      aEnd: integer = -1): TPascalString;
    function foreach(aPathName: String; aOutput: String; aStart: integer = 0;
      aEnd: integer = -1): TPascalString;

    function fordo(aVar: String; aOutput: String; aStart, aEnd: integer)
      : TPascalString;

    procedure OnGetExpressionValue(const DeclName: SystemString;
      var ValType: TExpressionDeclType; var Value: Variant);
    function doExpression(aExp: String; aEmptyReturnParam: Boolean = false;
      aData: TQJson = nil): TPascalString;

    function PrepareExpression(aExp: Pchar; aLen: integer = -1): TPascalString;
    procedure OnDeclValueMethod(DeclName: SystemString;
      var ValType: TExpressionDeclType; var Value: Variant);

  public

    constructor Create(aFileName: String);
    destructor Destroy; override;

    procedure LoadFunsFromDll(afile: String);
    procedure LoadFunsFromDllPath(aPath: String);

    property OutText: TPascalString read GetOutText;
    property FixText: TPascalString read FFixText;
    property data: TQJson read FData write FData;

    property OpCustomRunTime: TOpCustomRunTime read FOpCustomRunTime
      write FOpCustomRunTime;

  end;

implementation

uses strutils, mu.fileinfo;

{ TOpCustomRunTime_ }

{ TMVParse }

function isIntoken(s: string; var ss: String): Boolean;
var
  l: integer;
begin
  l := length(s);
  result := false;
  if l < 2 then
    exit;
  if ((s[1] = '"') and (s[l] = '"')) or ((s[1] = '''') and (s[l] = '''')) then
  begin
    result := true;
    ss := copy(s, 2, l - 2);
  end
  else
    ss := s;
end;

constructor TMVParse.Create(aFileName: String);
begin
  TextParsing.SpacerSymbol.V :=
    #44#43#45#42#47#40#41#59#58#61#35#64#94#38#37#33#34#60#62#63#123#125#39#36#124#64;
  // #46 #91#93
  FtmpData := TQJson.Create;
  FIsGetMacro := false;
  FBaseMacroPoint := -1;
  FMacroList := TStringList.Create;
  FMacroMgr := TQMacroManager.Create;

  initRuntime;
  FCurPath := ExtractFilePath(aFileName);
  if fileExists(aFileName) then
    FFixText.Text := LoadTextW(aFileName);

  fixInclude;

  if DirectoryExists(getexepath + 'pluginsFun\') then
    LoadFunsFromDllPath(getexepath + 'pluginsFun\');

end;

destructor TMVParse.Destroy;
begin
  if DefaultOpRT <> FOpCustomRunTime then
    disposeObject(FOpCustomRunTime);

  freeobject(FMacroMgr);
  freeobject(FComplied);
  freeobject(FMacroList);
  FtmpData.Free;
  inherited;
end;

procedure TMVParse.initRuntime;
begin
  FOpCustomRunTime := DefaultOpRT; // TOpCustomRunTime.Create;
  FOpCustomRunTime.CusReg;
  FOpCustomRunTime.RegOpP('include',
    function(var Param: TOpParam): Variant
    var
      i: integer;
      s: TPascalString;
    begin
      s.Text := '';
      for i := low(Param) to high(Param) do
        s.Append(LoadTextFromFile(Param[i]).Text); // 这个可以保存到缓存。或者可能是模板文件，需要处理
      result := s.Text;
    end);
  FOpCustomRunTime.RegOpP(EXPrefix,
    function(var Param: TOpParam): Variant
    var
      i: integer;
      V: Variant;
    begin
      V := (GetData(Param[0]));
      for i := 1 to high(Param) do
        V := V + (GetData(Param[i]));
      result := V;
    end);

  FOpCustomRunTime.RegOpP('Length',
    function(var Param: TOpParam): Variant
    var
      s: String;
      js: TQJson;
    begin

      s := (Param[0]);
      if s = '' then
        exit(0);
      if s[1] = EXPrefix then
      begin
        delete(s, 1, 1);
        if self.data.HasChild(s, js) then
        begin
          case js.DataType of
            jdtarray, jdtobject:
              exit(js.Count);
          else
            exit(length(js.AsString));
          end;
        end;
      end
      else
        exit(length(s));
    end);
  FOpCustomRunTime.RegOpP('$',
    function(var Param: TOpParam): Variant
    var
      i: integer;
      V: Variant;
    begin
      V := Param[0];
      for i := 1 to high(Param) do
        V := V + Param[i];
      result := V;
    end);
  FOpCustomRunTime.RegOpP('Write',
    function(var Param: TOpParam): Variant
    var
      i: integer;
      V: Variant;
    begin
      V := (GetData(Param[0]));
      for i := 1 to high(Param) do
        V := V + (GetData(Param[i]));
      result := V;
    end);
  FOpCustomRunTime.RegOpP(EXInnerChar,
    function(var Param: TOpParam): Variant
    var
      i: integer;
      V: Variant;
    begin
      V := (GetData(Param[0]));
      for i := 1 to high(Param) do
        V := V + (GetData(Param[i]));
      result := V;
    end);
  FOpCustomRunTime.RegOpP('Print',
    function(var Param: TOpParam): Variant
    var
      i: integer;
      V: Variant;
    begin
      V := (GetData(Param[0]));
      for i := 1 to high(Param) do
        V := V + (GetData(Param[i]));
      result := V;
    end);
  FOpCustomRunTime.RegOpP('if',
    function(var Param: TOpParam): Variant
    var
      aExp, aexp2: TPascalString;
      tv, fv: TPascalString;
      i: integer;
      V: Variant;
    begin
      case length(Param) of
        1:
          begin
            aExp := Param[0];
            result := doExpression(aExp);
          end;
        2:
          begin
            aExp := Param[0];
            aexp2 := Param[1];
            tv := doExpression(aExp);
            fv := doExpression(aexp2);
            result := tv = fv;
          end;
      end;
    end);
  FOpCustomRunTime.RegOpP('ifthen',
    function(var Param: TOpParam): Variant
    var
      cexp: Boolean;
      tv, fv: TPascalString;
      i: integer;
      V: Variant;
    begin
      if length(Param) <= 1 then
        exit;
      cexp := Param[0];
      if cexp then
        result := doExpression(VarToStr(Param[1]), true)
      else if length(Param) = 2 then
        exit('')
      else
        result := doExpression(VarToStr(Param[2]), true);
    end);
  FOpCustomRunTime.RegOpP('foreachdo',
    function(var Param: TOpParam): Variant
    begin
      result := '';
      case length(Param) of
        2:
          result := foreachdo(Param[0], Param[1]);
        3:
          result := foreachdo(Param[0], Param[1], Param[2]);
        4:
          result := foreachdo(Param[0], Param[1], Param[2], Param[3]);
      end;
    end);

  FOpCustomRunTime.RegOpP('foreach',
    function(var Param: TOpParam): Variant
    begin
      result := '';
      case length(Param) of
        2:
          result := foreach(Param[0], Param[1]);
        3:
          result := foreach(Param[0], Param[1], Param[2]);
        4:
          result := foreach(Param[0], Param[1], Param[2], Param[3]);
      end;
    end);
  FOpCustomRunTime.RegOpP('fordo',
    function(var Param: TOpParam): Variant
    begin
      result := '';
      case length(Param) of
        3:
          result := fordo(Param[0], Param[1], 0, Param[2]);
        4:
          result := fordo(Param[0], Param[1], Param[2], Param[3]);
      end;
    end);

end;

procedure TMVParse.LoadFunsFromDll(afile: String);
begin
  self.FOpCustomRunTime.RegFromDll(afile);
end;

procedure TMVParse.LoadFunsFromDllPath(aPath: String);
var
  st: TStringList;
  i: integer;
begin
  st := TStringList.Create;
  try
    filefind(aPath, '*.dll', st);
    for i := 0 to st.Count - 1 do
      LoadFunsFromDll(st[i]);
  finally
    st.Free;
  end;
end;

function TMVParse.LoadTextFromFile(aFileName: String): TPascalString;
begin
  result.Text := '';
  if pos(':', aFileName) < 1 then
    aFileName := self.FCurPath + aFileName; // 这个需要弄个函数
  if fileExists(aFileName) then
    result.Text := LoadTextW(aFileName);

end;

procedure TMVParse.QMacroMissEvent(ASender: TQMacroManager; AName: QStringW;
const AQuoter: QCharW; var AHandled: Boolean);
begin
  // FComplied.EnumUsedMacros(FMacroList);
  FMacroList.Add(AName);

end;

function TMVParse.fixInclude: integer;
var
  i: integer;
  V: TPascalString;
begin
  // FMacroMgr.IgnoreCase := true;
  FMacroMgr.Clear;
  FComplied := FMacroMgr.Complie(FFixText.Text, EXStart + 'include', EXEnd,
    MRF_DELAY_BINDING or MRF_IN_SINGLE_QUOTER or MRF_IN_DBL_QUOTER);
  if FComplied <> nil then
  begin
    FComplied.EnumUsedMacros(FMacroList);
    // sp := FMacroMgr.SavePoint;
    for i := 0 to FMacroList.Count - 1 do
    begin
      FMacroMgr.Push(FMacroList[i], VarToStr(EvaluateExpressionValue(tsC,
        'include' + FMacroList[i], FOpCustomRunTime)));
      // FMacroMgr.Push(FMacroList[I], v.Text);
    end;
    FFixText.Text := FComplied.Replace;
    FMacroList.Clear;
    // FMacroMgr.Restore(sp);
  end;
end;

function TMVParse.GetData(AName: String; aJdata: TQJson = nil;
aAllowOwn: Boolean = false): TPascalString;
var
  jd: TQJson;
  function jsValue(ajs: TQJson): TPascalString;
  begin
    case ajs.DataType of
      jdtarray, jdtobject:
        result.Text := ajs.Encode(false);
      // result.Text := TQJson.JsonEscape(ajs.Encode(false), true);
      jdtNull:
        result.Text := '';
    else
      result.Text := ajs.AsString;
    end;
  end;

begin
  if aJdata = nil then
    aJdata := FData;
  if (AName = EXPrefix) and (aAllowOwn) then
  begin
    exit(jsValue(aJdata));
  end;
  if AName[1] = EXPrefix then
  begin
    delete(AName, 1, 1);
    if aJdata.HasChild(AName, jd) then
    begin
      result := jsValue(jd);
      exit;
    end;
  end
  else
    result := AName;
end;

function TMVParse.TryGetData(AName: String; var r: TPascalString;
aJdata: TQJson = nil; aAllowOwn: Boolean = false): Boolean;
var
  jd: TQJson;
  function jsValue(ajs: TQJson): TPascalString;
  begin
    case ajs.DataType of
      jdtarray, jdtobject:
        result.Text := ajs.Encode(false);
      // TQJson.JsonEscape(ajs.Encode(false), true);
      jdtNull:
        result.Text := '';
    else
      result.Text := ajs.AsString;
    end;
  end;

begin
  r := '';
  if aJdata = nil then
    aJdata := FData;

  if (AName = EXPrefix) and (aAllowOwn) then
  begin
    r := jsValue(aJdata);
    result := true;
    exit;
  end;

  if AName[1] = EXPrefix then
  begin
    delete(AName, 1, 1);
    if aJdata.HasChild(AName, jd) then
    begin
      r := jsValue(jd);
      result := true;
    end
  end
  else
    result := false;

end;

function TMVParse.GetOutText: TPascalString;
var
  tmpSym: TSymbolExpression;
  op: TOpCode;
var
  i: integer;
  V: QStringW;
begin
  FMacroMgr.Clear;
  if not FIsGetMacro then
  begin

    FMacroList.Clear;
    FMacroMgr.OnMacroMissed := self.QMacroMissEvent;
    FComplied := FMacroMgr.Complie(FFixText.Text, EXStart, EXEnd,
      MRF_DELAY_BINDING or MRF_IN_SINGLE_QUOTER or MRF_IN_DBL_QUOTER);
    if FComplied <> nil then
    begin
      // FComplied.EnumUsedMacros(FMacroList);
      // FBaseMacroPoint := FMacroMgr.SavePoint;
    end;
    FIsGetMacro := true;
  end
  else
  begin
    // if FBaseMacroPoint > 0 then
    // FMacroMgr.Restore(FBaseMacroPoint);
  end;

  for i := 0 to FMacroList.Count - 1 do
  begin
    FMacroMgr.Push(FMacroList[i], doExpression(FMacroList[i]).Text);
  end;
  result.Text := FComplied.Replace;

  // SaveTextW(TUtils.AppPath + 'tmp.htm', result.Text);

end;

procedure TMVParse.OnDeclValueMethod(DeclName: SystemString;
var ValType: TExpressionDeclType; var Value: Variant);
var
  n: String;
  V: TExpressionDeclType;
begin
  n := DeclName;
end;

function ReplacetoDefault(p: Pchar): integer;
var
  p1, p2: Pchar;
begin
  { p1 := p;
    while p1^ <> #0 do
    begin
    if p1^ = EXPrefix then
    begin
    SkipSpaceW(p1);
    p2 := p1 + 1;
    if p2^ = '(' then // 函数引用
    begin
    p1^ := EXInnerChar;
    inc(p1);
    end;
    end;
    inc(p1);
    end;
  }
end;

function TMVParse.PrepareExpression(aExp: Pchar; aLen: integer = -1)
  : TPascalString;
var
  p, p1, p2: Pchar;
  ts: QStringW;
  s: TPascalString;
  offset, l, l2: integer;
const
  dsPWideChar: PWideChar = ' +-*/^=><,&|()%''"×÷!≠'#9#13#10;

begin
  p := aExp;
  SkipSpaceW(p);
  offset := 0;

  s := '';
  p := aExp;
  p1 := p;
  p2 := p1;
  while (p1^ <> #0) and ((aLen = -1) or (aLen < p1 - p)) do
  begin
    // 函数已经处理了，这里剩下的，都是变量
    if p1^ = EXPrefix then
    begin
      l := p1 - p2;
      if l > 0 then
      begin
        l2 := s.Len;
        setlength(s.Buff, l2 + l);
        CopyPtr(p2, @s.Buff[l2], l * 2);
        p2 := p1;
      end;
      // inc(p1);    //不要往后走，要留着 @ ,从数据提取。

      ts := DecodeTokenW(p1, dsPWideChar, QCharW(#0), true, false);
      if ts <> '' then
      begin
        s.Append(self.GetData(ts));
        // inc(p1);
        // inc(p1, length(ts));
        p2 := p1;
      end;
    end; // 此时可以依据到尾了。
    if p1^ = #0 then
      break;
    inc(p1);
  end;
  if p1 > p2 then
  begin
    l := p1 - p2;
    if l > 0 then
    begin
      l2 := s.Len;
      setlength(s.Buff, l2 + l);
      CopyPtr(p2, @s.Buff[l2], l * 2);
    end;
  end;
  if s.Len = 0 then
    result := aExp
  else
    result := s;
  // se := ParseTextExpressionAsSymbol(tsC, '', aExp, OnDeclValueMethod,
  // FOpCustomRunTime); //
end;

procedure TMVParse.OnGetExpressionValue(const DeclName: SystemString;
var ValType: TExpressionDeclType; var Value: Variant);
var
  r: TPascalString;
var
  dname: String;
begin
  dname := DeclName;
  if dname[1] = EXPrefix then
  begin
    // delete(dname, 1, 1);
    if TryGetData(dname, r) then
    begin
      Value := r.Text;
      ValType := TExpressionDeclType.edtString;
      exit;
    end
  end
  else
  begin
    ValType := TExpressionDeclType.edtProcExp;
  end;
end;

function TMVParse.doExpression(aExp: String; aEmptyReturnParam: Boolean = false;
aData: TQJson = nil): TPascalString;
var
  p: Pchar;
  se: TSymbolExpression;
  exp: String;
  usecatch: Boolean;
  function DoExp(ap: Pchar; isRepare: Boolean = true): TPascalString;
  var
    aExp: string;
  begin
    SkipSpaceW(ap);
    if isRepare then
      aExp := PrepareExpression(ap).Text
    else
      aExp := ap;
    result.Text := VarToStr(EvaluateExpressionValue(tsC, aExp,
      FOpCustomRunTime));
  end;

  function DoExp_(aEx: String): TPascalString;
  var
    sym: TSymbolExpression;
    op: TOpCode;
    i: integer;
  begin
    result.Text := VarToStr(EvaluateExpressionValue_P(usecatch,
      SpecialAsciiToken, TTextParsing, tsC, aEx,
      procedure(const DeclName: SystemString; var ValType: TExpressionDeclType;
        var Value: Variant)
      var
        r: TPascalString;
      var
        dname: String;
      begin
        dname := DeclName;
        if dname[1] = EXPrefix then
        begin
          if TryGetData(dname, r, aData, true) then
          begin
            Value := r.Text;
            ValType := TExpressionDeclType.edtString;
            exit;
          end
        end
        { else if dname[1] = '$' then
          begin
          Value := dname;
          ValType := TExpressionDeclType.edtString;
          exit;
          end }
        else
        begin
          ValType := TExpressionDeclType.edtProcExp;
        end;
      end));
  end;

// (ParsingEng: TTextParsing; const uName: SystemString;
// const OnGetValue: TOnDeclValueMethod; RefrenceOpRT: TOpCustomRunTime): TSymbolExpression; overload;
begin

  if aData = nil then
  begin
    aData := self.FData;
    usecatch := true;
  end
  else
    usecatch := false;

  p := Pchar(aExp);
  SkipSpaceW(p);
  result.Text := '';
  // 直接应用变量的

  if p^ = '=' then
  begin
    inc(p);
    SkipSpaceW(p);
    result.Text := DoExp(p);
  end
  else
  begin
    result.Text := DoExp_(p);
  end;
  if aEmptyReturnParam and (result.Len = 0) then
    result.Text := aExp;
  // VarToStr(EvaluateExpressionValue(aExp, FOpCustomRunTime))
end;

function TMVParse.fordo(aVar: String; aOutput: String; aStart, aEnd: integer)
  : TPascalString;
var
  i: integer;
  s: String;
  sourTp, t: TTextParsing;
begin
  result := '';

  self.FOpCustomRunTime.RegOpP(aVar,
    function(var Param: TOpParam): Variant
    begin
      result := i;
    end);

  for i := aStart to aEnd do
  begin
    s := VarToStr(EvaluateExpressionValue(tsC, aOutput, FOpCustomRunTime));
    result.Append(s);
  end;
  FOpCustomRunTime.ProcList.delete(aVar);
  // result := aVar + aOutput;
end;

function TMVParse.foreachdo(aPathName: String; aOutput: String;
aStart: integer = 0; aEnd: integer = -1): TPascalString;
var
  i: integer;
  p: Pchar;
  djs: TQJson;
  V: TPascalString;
const
  dsPWideChar: PWideChar = ' +-*/^=><,&|()%''"×÷!≠'#9#13#10;
begin
  p := Pchar(aOutput);
  if aPathName = '' then
    exit('');
  if aPathName[1] = EXPrefix then
  begin
    delete(aPathName, 1, 1);
    if aPathName = '' then
    begin
      djs := self.data;
    end
    else if not self.data.HasChild(aPathName, djs) then
    begin
      exit('')
    end;

  end
  else
  begin
    if not FtmpData.TryParse(aPathName) then
      exit('');
    djs := FtmpData;
  end;
  if aEnd = -1 then
    aEnd := djs.Count - 1;
  for i := aStart to aEnd do
  begin
    V := doExpression(aOutput, true, djs[i]);
    if (V = '') then
      V := aOutput;
    result.Append(V);
  end;
end;

function TMVParse.foreach(aPathName: String; aOutput: String;
aStart: integer = 0; aEnd: integer = -1): TPascalString;
var
  i: integer;
  p: Pchar;
  djs: TQJson;
  V: TPascalString;
const
  dsPWideChar: PWideChar = ' +-*/^=><,&|()%''"×÷!≠'#9#13#10;

  function OutputStr(js: TQJson): TPascalString;
  var
    p1, p2: Pchar;
    ts: QStringW;
    s: TPascalString;
    i, l, l2: integer;
  begin
    s := '';

    p1 := p;
    p2 := p1;
    while (p1^ <> #0) do
    begin
      // 函数已经处理了，这里剩下的，都是变量
      if p1^ = EXPrefix then
      begin
        l := p1 - p2;
        if l > 0 then
        begin
          l2 := s.Len;
          setlength(s.Buff, l2 + l);
          CopyPtr(p2, @s.Buff[l2], l * 2);
        end;
        // inc(p1);
        ts := DecodeTokenW(p1, dsPWideChar, QCharW(#0), true, false);
        if ts <> '' then
        begin
          s.Append(GetData(ts, js, true));
          // inc(p1, length(ts));
          p2 := p1;
        end;
      end;
      // 此时可以依据到尾了。
      if p1^ = #0 then
        break;
      inc(p1);
    end;
    if p1 > p2 then
    begin
      l := p1 - p2;
      if l > 0 then
      begin
        l2 := s.Len;
        setlength(s.Buff, l2 + l);
        CopyPtr(p2, @s.Buff[l2], l * 2);
      end;
    end;
    if s.Len = 0 then
      result := ''
    else
      result := s;
  end;

begin
  p := Pchar(aOutput);
  if aPathName = '' then
    exit('');
  if aPathName[1] = EXPrefix then
    delete(aPathName, 1, 1);
  if not self.data.HasChild(aPathName, djs) then
  begin
    if not FtmpData.TryParse(aPathName) then
      exit('');
    djs := FtmpData;
  end;
  if aEnd = -1 then
    aEnd := djs.Count - 1;
  for i := aStart to aEnd do
  begin
    V := (OutputStr(djs[i]));
    V := doExpression(V, true);

    result.Append(V);
  end;
end;

initialization

SpecialAsciiToken := TListPascalString.Create;
SpecialAsciiToken.Add(EXPrefix);
SpecialAsciiToken.Add(EXPrefix + EXPrefix);

finalization

freeobject(SpecialAsciiToken);

end.
