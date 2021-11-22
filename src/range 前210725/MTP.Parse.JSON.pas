unit MTP.Parse.JSON;

interface

uses sysutils, System.Classes, Generics.Collections,

  qstring, qjson, MTP.Utils, MTP.Types, MTP.Parse;

type
  TMDataParser_JSON = class(TInterfacedObject, IMDataParser) // TObjectInterfaced      TInterfacedObject
    public
      constructor Create();
      destructor Destroy; override;

      function DataByPath(const aData: Pointer; const aParams: Pointer; const aPath: String): Pointer;
      function TryDataByPath(const aData: Pointer; const aParams: Pointer; const aPath: String;
        var outdata: Pointer): Boolean;
      function TryGetData(const aData: Pointer; const aParams: Pointer; const aRootData: Pointer; const AName: String;
        const aAllowOwn: Boolean; var r: string): Boolean;
      function DataCount(const aData: Pointer): Integer;

      function HasPath(const aData: Pointer; const aParams: Pointer; const aPath: String): Boolean;
      function Items(const aData: Pointer; const idx: Integer): Pointer;

  end;

var
  pubDataParser_JSON: TMDataParser_JSON;

implementation

{ TMDataParse_JSON }

constructor TMDataParser_JSON.Create;
begin

end;

function TMDataParser_JSON.DataByPath(const aData: Pointer; const aParams: Pointer; const aPath: String): Pointer;
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

function TMDataParser_JSON.HasPath(const aData: Pointer; const aParams: Pointer; const aPath: String): Boolean;
begin
  if (aPath <> '') then
    if aPath[1] = EXPrefix then
      exit(TQJson(aParams).ItemByPath(aPath.Substring(1)) <> nil);

  result := TQJson(aData).ItemByPath(aPath) <> nil;
end;

function TMDataParser_JSON.Items(const aData: Pointer; const idx: Integer): Pointer;
begin
  result := TQJson(aData).Items[idx];
end;

function TMDataParser_JSON.TryDataByPath(const aData: Pointer; const aParams: Pointer; const aPath: String;
  var outdata: Pointer): Boolean;
var
  js: TQJson;
begin
  if (aPath <> '') and (aPath[1] = EXPrefix) then
  begin
    result := TQJson(aParams).HasChild(aPath.Substring(1), js);
  end
  else
    result := TQJson(aData).HasChild(aPath, js);
  if result then
    outdata := js;
end;

function TMDataParser_JSON.TryGetData(const aData: Pointer; const aParams: Pointer; const aRootData: Pointer;
  const AName: String; const aAllowOwn: Boolean; var r: string): Boolean;

var
  aJdata, jParams, jd, jRootData: TQJson;
  name                          : String;
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
  r         := '';
  aJdata    := TQJson(aData);
  jParams   := TQJson(aParams);
  jRootData := TQJson(aRootData);
  name      := AName;

  // outputdebugstring(pchar(aJdata.ToString));
  if (name = EXPrefix) and (aAllowOwn) then
  begin
    r      := jsValue(aJdata);
    result := true;
    exit;
  end;

  if name[1] = EXPrefix then // @
  begin
    System.delete(name, 1, 1);
    if name[1] = EXPrefix then // @@是公共变量
    begin
      System.delete(name, 1, 1);
      if (length(name) > 0) and (name[1] = EXPrefix) then // @@@是公共变量   是根
      begin
        System.delete(name, 1, 1);

        if (name = '') and (aAllowOwn) then
        begin
          r      := jsValue(jRootData);
          result := true;
        end else if jRootData.HasChild(name, jd) then
        begin
          r := jsValue(jd);

          result := true;
        end;
        // ASSERT(, 'Pageindex error');

      end else begin
        if (name = '') and (aAllowOwn) then
        begin
          r      := jsValue(jParams);
          result := true;
        end else if jParams.HasChild(name, jd) then
        begin
          r      := jsValue(jd);
          result := true;
        end
      end;

    end else if aJdata.HasChild(name, jd) then
    begin
      r      := jsValue(jd);
      result := true;
    end
  end else if aAllowOwn then
  begin
    r      := name;
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
