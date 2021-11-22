unit MTP.Expression_z;

interface

uses System.SysUtils, Variants, System.classes, windows,

  CoreClasses, CoreCompress, DataFrameEngine, DoStatusIO,
  GeometryLib, ZS_JsonDataObjects, ListEngine,
  MemoryStream64, opCode, opCode_Help,
  PascalStrings, TextDataEngine, TextParsing, UnicodeMixedLib, zExpression,

  MTP.Types, qjson, qstring;

var
  publicVarInt: integer;
  SpecialAsciiToken: TListPascalString;
  FOpCustomRunTime: TOpCustomRunTime;

type
  TMRuntime = class

  end;

  TMExp = class
  public
    class function GetData(AName: String; aJdata: TQJson = nil; aAllowOwn: Boolean = false): TPascalString; overload;
    class function TryGetData(AName: String; var r: TPascalString; aJdata: TQJson = nil;
      aAllowOwn: Boolean = false): Boolean;
    class function doExpression(aExp: String; aEmptyReturnParam: Boolean; aData: TQJson): String;
    class function Exp(aExp: String; aEmptyReturnParam: Boolean; aData: TQJson): String;
  end;

var
  MRuntime: TMRuntime;

implementation

uses mu.fileinfo;
{ TMExp }

class function TMExp.Exp(aExp: String; aEmptyReturnParam: Boolean; aData: TQJson): String;
begin
  result := TMExp.doExpression(aExp, aEmptyReturnParam, aData);
end;

class function TMExp.GetData(AName: String; aJdata: TQJson; aAllowOwn: Boolean): TPascalString;
var
  jd: TQJson;
  function jsValue(ajs: TQJson): TPascalString;
  begin
    case ajs.DataType of
      jdtarray, jdtobject:
        result := ajs.Encode(false);
      // result.Text := TQJson.JsonEscape(ajs.Encode(false), true);
      jdtNull:
        result := '';
    else
      result := ajs.AsString;
    end;
  end;

begin

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

class function TMExp.TryGetData(AName: String; var r: TPascalString; aJdata: TQJson; aAllowOwn: Boolean): Boolean;
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

class function TMExp.doExpression(aExp: String; aEmptyReturnParam: Boolean; aData: TQJson): String;
var
  p: Pchar;
  se: TSymbolExpression;
  Exp: String;
  usecatch: Boolean;
  { function DoExp(ap: Pchar; isRepare: Boolean = true): TPascalString;
    var
    aExp: string;
    begin
    SkipSpaceW(ap);
    if isRepare then
    aExp := PrepareExpression(ap).Text
    else
    aExp := ap;
    result.Text := VarToStr(EvaluateExpressionValue(tsC, aExp, FOpCustomRunTime));
    end;
  }
  function DoExp_(aEx: String): TPascalString;
  var
    sym: TSymbolExpression;
    op: TOpCode;
    i: integer;
  begin
    result.Text := VarToStr(EvaluateExpressionValue_P(usecatch, SpecialAsciiToken, TTextParsing, tsC, aEx,
      procedure(const DeclName: SystemString; var ValType: TExpressionDeclType; var Value: Variant)
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
        else
        begin
          ValType := TExpressionDeclType.edtProcExp;
        end;
      end));
  end;

// (ParsingEng: TTextParsing; const uName: SystemString;
// const OnGetValue: TOnDeclValueMethod; RefrenceOpRT: TOpCustomRunTime): TSymbolExpression; overload;
begin

  usecatch := false;

  p := Pchar(aExp);
  SkipSpaceW(p);
  result := '';
  // 直接应用变量的

  if p^ = '=' then
  begin
    inc(p);
    SkipSpaceW(p);
    result := DoExp_(p);
  end
  else
  begin
    result := DoExp_(p);
  end;
  if aEmptyReturnParam and (length(result) = 0) then
    result := aExp;
  // VarToStr(EvaluateExpressionValue(aExp, FOpCustomRunTime))
end;

function LoadTextFromFile(aFileName: String): String;
begin
  result := '';
  if pos(':', aFileName) < 1 then
    aFileName := aFileName; // FCurPath + 这个需要弄个函数
  if fileExists(aFileName) then
    result := LoadTextW(aFileName);
end;

procedure LoadFunsFromDll(aOpCustomRunTime: TOpCustomRunTime; afile: String);
begin
  aOpCustomRunTime.RegFromDll(afile);
end;

procedure LoadFunsFromDllPath(aOpCustomRunTime: TOpCustomRunTime; aPath: String);
var
  st: TStringList;
  i: integer;
begin
  st := TStringList.Create;
  try
    filefind(aPath, '*.dll', st);
    for i := 0 to st.Count - 1 do
      LoadFunsFromDll(aOpCustomRunTime, st[i]);
  finally
    st.Free;
  end;
end;

procedure initRuntime(aOpCustomRunTime: TOpCustomRunTime);
begin
  { aOpCustomRunTime.RegOpP('include',
    function(var Param: TOpParam): Variant
    var
    i: integer;
    s: TPascalString;
    begin
    s.Text := '';
    for i := low(Param) to high(Param) do
    s.Append(LoadTextFromFile(Param[i])); // 这个可以保存到缓存。或者可能是模板文件，需要处理
    result := s.Text;
    end);
  }

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
            // result := 0(aExp);
          end;
        2:
          begin
            aExp := Param[0];
            aexp2 := Param[1];
            // tv := doExpression(aExp);
            // fv := doExpression(aexp2);
            result := tv = fv;
          end;
      end;
    end);
  {
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
    if data.HasChild(s, js) then
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
  }
end;

initialization

SpecialAsciiToken := TListPascalString.Create;
SpecialAsciiToken.Add(EXPrefix);
SpecialAsciiToken.Add(EXPrefix + EXPrefix);
TextParsing.SpacerSymbol.V := #44#43#45#42#47#40#41#59#58#61#35#64#94#38#37#33#34#60#62#63#123#125#39#36#124#64;
// FOpCustomRunTime := TOpCustomRunTime.Create;
FOpCustomRunTime := DefaultOpRT;
FOpCustomRunTime.CusReg;

if DirectoryExists(getexepath + 'pluginsFun\') then
  LoadFunsFromDllPath(FOpCustomRunTime, getexepath + 'pluginsFun\');

finalization

freeobject(SpecialAsciiToken);
// freeobject(FOpCustomRunTime);

end.
