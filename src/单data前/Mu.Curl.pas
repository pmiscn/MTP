unit Mu.Curl;

interface

uses System.SysUtils, System.Variants, System.Classes,
  Curl.Lib, Curl.Easy, Curl.Interfaces;

type
  TEasyCurlImpl_ = class helper for TEasyCurlImpl
  private
    function GetChatset: RawByteString;
    function GetContentLength: double;
    function GetContentType: RawByteString;
    function GetRemoteIP: RawByteString;
    function GetResultUrl: RawByteString;
    function GetReferer: RawByteString;
    procedure SetReferer(const Value: RawByteString);
  public
    property ResultUrl: RawByteString read GetResultUrl;
    property RemoteIP: RawByteString read GetRemoteIP;
    Property ContentType: RawByteString read GetContentType;
    property Charset: RawByteString read GetChatset;
    property ContentLength: double read GetContentLength;
    property Referer: RawByteString read GetReferer write SetReferer;
  end;

  IMCURL = ICurl;
  TMCURL = TEasyCurlImpl;

implementation

{ TEasyCurlImpl_ }

function TEasyCurlImpl_.GetChatset: RawByteString;
  function CharsetFromContentType(aContentType: RawByteString): RawByteString; { V8.50 }
  var
    i: integer;
  begin
    Result := '';
    aContentType := LowerCase(aContentType);
    i := Pos('charset=', aContentType);
    if i = 0 then
      Exit;
    Result := Copy(aContentType, i + 8, 999);
  end;

begin
  Result := CharsetFromContentType(ContentType);
end;

function TEasyCurlImpl_.GetContentLength: double;
begin
  Result := GetInfo(CURLINFO_SIZE_DOWNLOAD);
end;

function TEasyCurlImpl_.GetContentType: RawByteString;
begin
  Result := GetInfo(CURLINFO_CONTENT_TYPE);
end;

function TEasyCurlImpl_.GetReferer: RawByteString;
begin
  // Result := GetInfo(CURLOPT_REFERER);
end;

function TEasyCurlImpl_.GetRemoteIP: RawByteString;
begin
  Result := GetInfo(CURLINFO_PRIMARY_IP);
end;

function TEasyCurlImpl_.GetResultUrl: RawByteString;
begin
  Result := GetInfo(CURLINFO_EFFECTIVE_URL);
end;

procedure TEasyCurlImpl_.SetReferer(const Value: RawByteString);
begin
  setOpt(CURLOPT_REFERER, Value)
end;

end.
