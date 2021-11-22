unit MTP.Expression;

interface

uses System.SysUtils, Variants, System.classes, qjson, qstring, windows,
  QMathExpr, MTP.QMathExpr.Extend, Data.DB,
  MTP.utils, MTP.Types;

type
  TMRuntime = class

  end;

  PMExpInput = ^TMExpInput;

  TMExpInput = record
    Data: Pointer;
    Params: TQjson;
    Parser: IMDataParser;
    RootData: Pointer;
  end;

  TMExp = class
    public
      class function doExpression(aExp: String; aEmptyReturnParam: Boolean; aData: Pointer; aDataParser: IMDataParser;
        aParams: TQjson; aRootData: Pointer): String;
      class function Exp(aExp: String; aEmptyReturnParam: Boolean; aData: Pointer; aDataParser: IMDataParser;
        aParams: TQjson; aRootData: Pointer): String;
  end;

var
  MRuntime: TMRuntime;

  pubExpr: IQMathExpression;

implementation

uses {$IFDEF MSWINDOWS}mu.fileinfo, {$ENDIF} dateutils;
{ TMExp }

class function TMExp.Exp(aExp: String; aEmptyReturnParam: Boolean; aData: Pointer; aDataParser: IMDataParser;
  aParams: TQjson; aRootData: Pointer): String;
begin
  result := TMExp.doExpression(aExp, aEmptyReturnParam, aData, aDataParser, aParams, aRootData);
end;

class function TMExp.doExpression(aExp: String; aEmptyReturnParam: Boolean; aData: Pointer; aDataParser: IMDataParser;
  aParams: TQjson; aRootData: Pointer): String;
var
  p       : pchar;
  Exp     : String;
  i       : Integer;
  ExpInput: TMExpInput;

  aexpr: IQMathExpression;
  mcomp: IQMathCompiled;
  // ExpInput: PMExpInput;
begin
  p := pchar(aExp);
  SkipSpaceW(p);
  result := '';
  // 直接应用变量的
  if p^ = '=' then
  begin
    inc(p);
    SkipSpaceW(p);
  end;
  aExp := p;

  // writeln(int64(aRootData),' ',TQJSON(arootData).Count);

  aexpr := pubExpr; // TQMathExpression.Create;
  tmonitor.Enter(aexpr as TObject);
  try
    aexpr.OnLookupMissedA := procedure(Sender: IQMathExpression; const AVarName: String; var AVar: TQMathVar)
      begin

        try
          AVar := Sender.Add(AVarName, 0, 0,
            procedure(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant)
            var
              r: string;
              ipt: PMExpInput;
            begin
              try
                if ACallParams.Params = nil then
                  exit;
                ipt := PMExpInput(ACallParams.Params);

                // if aDataParser <> nil then
                if ipt.Parser <> nil then
                begin
                  // if aDataParser.TryGetData(ACallParams.Params, AVarName, true, r) then

                  if ipt.Parser.TryGetData(ipt.Data, ipt.Params, ipt.RootData, AVarName, true, r) then
                  begin
                    AResult := r;
                  end
                  else
                    AResult := Unassigned;

                end;
              except
                on E: Exception do
                begin
                  OutputDebugString('Error 95');
                end;

              end;
            end);
        except
          on E: Exception do
          begin
            OutputDebugString(pchar(E.Message));
          end;
        end;

      end;
  finally
    tmonitor.exit(aexpr as TObject);
  end;
  mcomp := aexpr.Parse(aExp);
  // new(ExpInput);
  ExpInput.Data     := aData;
  ExpInput.Params   := aParams;
  ExpInput.Parser   := aDataParser;
  ExpInput.RootData := aRootData;
  try
    result := mcomp.Eval(@ExpInput);
  except
    on E: Exception do
    begin
      writeln(format('Exxception %s error:%s',[aExp,E.Message]));
      result := '';
    end;
  end;
  // dispose(ExpInput);
end;

function LoadTextFromFile(aFileName: String): String;
begin
  result := '';
  if pos(':', aFileName) < 1 then
    aFileName := aFileName; // FCurPath + 这个需要弄个函数
  if fileExists(aFileName) then
    result := LoadTextW(aFileName);
end;

procedure LoadFunsFromDll(aexpr: TQMathExpression; afile: String);
begin
  aexpr.RegFromDll(afile);
end;

{$IFDEF MSWINDOWS}

procedure LoadFunsFromDllPath(aexpr: TQMathExpression; aPath: String);
var
  st: TStringList;
  i : Integer;
begin
  st := TStringList.Create;
  try
    filefind(aPath, '*.dll', st);
    for i := 0 to st.Count - 1 do
    begin
      LoadFunsFromDll(aexpr, st[i]);
    end;
  finally
    st.Free;
  end;
end;
{$ENDIF}

initialization

pubExpr := TQMathExpression.Create(true);
TQMathExpression(pubExpr).CusReg();

{$IFDEF MSWINDOWS}
if DirectoryExists(getexepath + 'plugins\Expression\') then
  LoadFunsFromDllPath(TQMathExpression(pubExpr), getexepath + 'plugins\Expression\');
{$ENDIF}

finalization

// freeandnil(aexpr);

end.
