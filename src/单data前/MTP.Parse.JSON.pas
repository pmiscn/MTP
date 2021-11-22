unit MTP.Parse.JSON;

interface

uses sysutils, System.Classes, Generics.Collections,

  qstring, qjson, MTP.Utils, MTP.Types, MTP.Parse;

type
  TMDataParser_JSON = class(TInterfacedObject, IMDataParser) // TObjectInterfaced      TInterfacedObject
    public
      constructor Create();
      destructor Destroy; override;

      function DataByPath(const aData: Pointer; const aPath: String): Pointer;
      function TryDataByPath(const aData: Pointer; const aPath: String; var outdata: Pointer): Boolean;
      function TryGetData(const aData: Pointer; const aParams: Pointer; const AName: String; const aAllowOwn: Boolean;
        var r: string): Boolean;
      function DataCount(const aData: Pointer): Integer;

      function HasPath(const aData: Pointer; const aPath: String): Boolean;
      function Items(const aData: Pointer; const idx: Integer): Pointer;

  end;

var
  pubDataParser_JSON: TMDataParser_JSON;

implementation

{ TMDataParse_JSON }

constructor TMDataParser_JSON.Create;
begin

end;

function TMDataParser_JSON.DataByPath(const aData: Pointer; const aPath: String): Pointer;
begin
  result := TQJson(aData).ItemByPath(aPath);
end;

function TMDataParser_JSON.DataCount(const aData: Pointer): Integer;
begin
  result := TQJson(aData).Count;
end;

destructor TMDataParser_JSON.Destroy;
begin

  inherited;
end;

function TMDataParser_JSON.HasPath(const aData: Pointer; const aPath: String): Boolean;
begin
  result := TQJson(aData).ItemByPath(aPath) <> nil;
end;

function TMDataParser_JSON.Items(const aData: Pointer; const idx: Integer): Pointer;
begin
  result := TQJson(aData).Items[idx];
end;

function TMDataParser_JSON.TryDataByPath(const aData: Pointer; const aPath: String; var outdata: Pointer): Boolean;
var
  js: TQJson;
begin
  result := TQJson(aData).HasChild(aPath, js);
  if result then
    outdata := js;
end;

function TMDataParser_JSON.TryGetData(const aData: Pointer; const aParams: Pointer; const AName: String;
  const aAllowOwn: Boolean; var r: string): Boolean;

var
  aJdata, jParams, jd: TQJson;
  nama               : String;
  function jsValue(ajs: TQJson): string;
  begin
    case ajs.DataType of
      jdtarray, jdtobject:
        result := ajs.Encode(false);
      jdtNull:
        result := '';
    else
      result := ajs.AsString;
    end;
  end;

begin
  r       := '';
  aJdata  := TQJson(aData);
  jParams := TQJson(aParams);
  nama    := AName;
  // outputdebugstring(pchar(aJdata.ToString));
  if (nama = EXPrefix) and (aAllowOwn) then
  begin
    r      := jsValue(aJdata);
    result := true;
    exit;
  end;

  if nama[1] = EXPrefix then    //@
  begin
    System.delete(nama, 1, 1);
    if nama[1] = EXPrefix then // @@是公共变量
    begin
      System.delete(nama, 1, 1);
      if (nama = '') and (aAllowOwn) then
      begin
        r      := jsValue(jParams);
        result := true;
      end else if jParams.HasChild(nama, jd) then
      begin
        r      := jsValue(jd);
        result := true;
      end
    end else if aJdata.HasChild(nama, jd) then
    begin
      r      := jsValue(jd);
      result := true;
    end
  end else if aAllowOwn then
  begin
    r      := nama;
    result := true;
  end
  else
    result := false;

end;

initialization

pubDataParser_JSON := TMDataParser_JSON.Create;

finalization

freeandnil(pubDataParser_JSON);

end.
