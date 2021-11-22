unit Mu.HttpGet;

interface

{$I httpget.inc}

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.Variants, System.zlib, // ZLibExGZ,
  QSimplePool, Mu.Pool.St, MTP.Logs,

  System.Net.URLClient, System.NetConsts, System.Net.Mime, System.Net.HttpClient

{$IFDEF CURL}
    , Mu.Curl, Curl.lib, Curl.easy, Curl.interfaces,
{$ENDIF}
{$IFDEF INDY}
, idhttp, IdIOHandler, IdSSL, IdSSLOpenSSL
{$ENDIF}
{$IFDEF ICS}
    , OverbyteIcsHttpProt, OverbyteIcsCharsetUtils, OverbyteIcsWSocket
{$ENDIF}
    ;

type
  TUTF8EncodingFixHelper = class helper for TMBCSEncoding
    public
      procedure SetMBToWCharFlagWithZero;
  end;

  TMuHttpGetBase = class(TMLog)
    private

    protected
      FURL      : String;
      FURI      : TURI;
      FIP       : String;
      FIPS      : String;
      FUserAgent: string;
      FReferer  : String;
      // proxy 暂时不用，不写了
      FUsername, FPassword: String;

      FContentString: String;
      FContentType  : String;
      FContentLength: integer;
      FTimeOut      : integer;
      FStatusCode   : integer;
      FLastUrl      : String;
      FHtmlCodePage : integer;
      FCharset      : String;
      FIndex        : integer;
      FShowException: boolean;
      FCusHeaders   : TNetHeaders;
      procedure SetTimeout(const Value: integer); virtual;
      // function inithttp(): pointer; virtual;
      // procedure freehttp(aObject: pointer); virtual;

      function HtmlStreamToString(aStream: TStream; var Charset: String): String;
      function doget(aInst: TMuHttpGetBase; aUrl: String): String; virtual; abstract;

      function PrepairUrl: String;
    public
      constructor Create; virtual;
      destructor Destroy; override;

      function Get(aUrl: String): String; virtual;

      property URL: String read FURL write FURL;
      property IP: String read FIP;
      property IPs: String read FIPS;
      property UserAgent: String read FUserAgent write FUserAgent;
      property Referer: String read FReferer write FReferer;
      property Timeout: integer read FTimeOut write SetTimeout;
      property ShowException: boolean read FShowException write FShowException;
      property Index: integer read FIndex write FIndex;

      property ContentString: String read FContentString;
      property ContentType: String read FContentType;
      property ContentLength: integer read FContentLength;
      property StatusCode: integer read FStatusCode;
      property HtmlCodePage: integer read FHtmlCodePage;
      property LastUrl: String read FLastUrl;
      property Charset: String read FCharset;
      property Username: String read FUsername write FUsername;
      property Password: String read FPassword write FPassword;
      property CusHeaders: TNetHeaders read FCusHeaders write FCusHeaders;
  end;

  TMuHttpGetBaseClass = class of TMuHttpGetBase;
{$IFDEF INDY}

  TMuHttpGet_indy = class(TMuHttpGetBase)
    private

    protected
      function inithttp(): Tidhttp;
      procedure freehttp(aObject: Tidhttp);
      function doget(aInst: TMuHttpGetBase; aUrl: String): String; override;
    public
      function Get(aUrl: String): String; virtual;
  end;
{$ENDIF}
{$IFDEF ICS}

  TMuHttpGet_ics = class(TMuHttpGetBase)
    private

    protected
      function inithttp(): pointer;
      procedure freehttp(aObject: pointer);
      function doget(aInst: TMuHttpGetBase; aUrl: String): String; override;
    public
      function Get(aUrl: String): String; virtual;
  end;
{$ENDIF}
{$IFDEF CURL}

  TMuHttpGet_curl = class(TMuHttpGetBase)
    private
    protected
      function inithttp(): pointer;
      procedure freehttp(aObject: pointer);
      function doget(aInst: TMuHttpGetBase; aUrl: String): String; override;
    public
      function Get(aUrl: String): String; virtual;
  end;
{$ENDIF}

  TMuHttpGet_wnet = class(TMuHttpGetBase)
    private
    protected
      function inithttp(): Thttpclient;
      procedure freehttp(aObject: Thttpclient);
      function doget(aInst: TMuHttpGetBase; aUrl: String): String; override;
    public
      function Get(aUrl: String): String; virtual;
  end;

  TMuHttpget = TMuHttpGetBase;

  TMuHttpgetM = class
    private
      class var FMuHttpGetBaseClass: TMuHttpGetBaseClass;
    public
      class constructor Create;
      class destructor Destroy;
      class procedure RegisterMuHttpGetBaseClass(const aMuHttpGetBaseClass: TMuHttpGetBaseClass);
    protected
    public
      class function Create: TMuHttpget; static;
  end;

  TMuHttpPool = class
    private
      FPool: TQSimplePool;
      procedure FOnObjectCreate(Sender: TQSimplePool; var AData: pointer);
      procedure FOnObjectFree(Sender: TQSimplePool; AData: pointer);
      procedure FOnObjectReset(Sender: TQSimplePool; AData: pointer);
    protected

    public
      constructor Create(Poolsize: integer = 10);
      destructor Destroy; override;
      function Get(): TMuHttpget;
      procedure return(AData: TMuHttpget);
  end;

  { TMuHttpGetBaseClass_indy = class of TMuHttpGet_indy;
    TMuHttpGetBaseClass_ics = class of TMuHttpGet_ics;
    TMuHttpGetBaseClass_Curl = class of TMuHttpGet_curl;
    TMuHttpGetBaseClass_wnet = class of TMuHttpGet_wnet; }

var
  MuHttpPool: TMuHttpPool;

implementation

uses qstring, unit_pub, Mu.Pool.HttpClient, Mu.Pool.idhttp, {$IFDEF CURL}Mu.Pool.Curl, {$ENDIF} IdGlobalProtocols;

procedure TUTF8EncodingFixHelper.SetMBToWCharFlagWithZero;
begin
  with Self do
  begin
    FMBToWCharFlags := 0;
  end;
end;

function DecompressGZip(inStream, outStream: TStream): boolean;
begin
  Result := false;
  if (inStream.Size <= 0) or (not Assigned(outStream)) then
    Exit;
  try
    inStream.Seek(0, 0);
    outStream.Position := 0;

    // GZDecompressStream(inStream, outStream);
    ZDecompressStream(inStream, outStream);

    Result := true;
  except
    on E: Exception do
      OutputDebugString(PChar(E.Message));
  end;
end;

function isutf8bom(m: TMemoryStream): boolean;
var
  S: AnsiString;
begin
  Result := false;
  setlength(S, 4);
  m.Position := 0;
  m.Write(m.Memory^, 4);
  if (S[1] = #$EF) and (S[2] = #$BB) and (S[3] = #$BF) then
    Result := true;
  // BB BF
end;

function getCharsetFromXmlBody(pp: QStringA): string;
const
  ValueDelimiters: PAnsiChar = '''" )?>,;'#9#10#13;
var
  S, ss: QStringA;

  l, i : integer;
  Token: QCharA;
  p    : PQCharA;

  AValueDelimiters: TBytes;
begin
  Result           := '';
  AValueDelimiters := BytesOf(ValueDelimiters);
  p                := PQCharA(pp);
  ss               := 'encoding';
  i                := PosA(PQCharA(ss), p, true, 1);
  if i = 0 then
    Exit;
  inc(p, i + 8 - 1);
  SkipSpaceA(p);
  if p^ = ord('=') then
  begin
    inc(p);
    SkipSpaceA(p);
    if char(p^) in ['''', '"'] then
      Token := p^
    else
      Token := 0;
    // <?xml version="1.0" encoding="Shift_JIS"?>
    S := DequotedStrA(DecodeTokenA(p, AValueDelimiters, Token, true), Token);
    if length(S) > 0 then
    begin
      Result := S;
    end;
  end;
end;

function CharsetFromContentType(ContentType: String): String; { V8.50 }
var
  i: integer;
begin
  Result      := '';
  ContentType := LowerCase(ContentType);
  i           := Pos('charset=', ContentType);
  if i = 0 then
    Exit;
  Result := Copy(ContentType, i + 8, 999);
end;

function DecodeCharset(ps: QStringA; ASize: integer): string;
const
  ValueDelimiters: PAnsiChar = '''" )?/>,;'#9#10#13;
var
  S, ss: QStringA;

  l, i : integer;
  Token: QCharA;
  pp, p: PQCharA;

  AValueDelimiters: TBytes;
begin
  Result           := '';
  AValueDelimiters := BytesOf(ValueDelimiters);

  p  := PQCharA(ps);
  pp := PQCharA(ps);

  ss := DecodeLineA(p, true, 100); // 跳过了100个了

  if LowerCase(Copy(ss, 1, 5)) = '<?xml' then
  begin
    Result := getCharsetFromXmlBody(ss);
    if Result <> '' then
    begin
      Exit;
    end;
  end;
  p := pp;

  ss := '<head';
  i  := PosA(PQCharA(ss), p, true, 1);
  if (i < 1) or (i > ASize) then
    Exit;

  inc(p, i);

  while p^ <> 0 do
  begin
    if (p^ = ord('>')) then
    begin
      inc(p);
      Break;
    end;
    inc(p);
  end;

  if (p^ = 0) or (i > ASize) then
    Exit;

  i := PosA(PAnsiChar('<meta'), p, true, 1);
  while (i > 0) and (IntPtr(p) - IntPtr(pp) < ASize) do
  begin
    inc(p, i);
    SkipSpaceA(p);
    i := PosA(PAnsiChar('charset'), p, true, 1);
    if i > 0 then
    begin
      inc(p, i + 7 - 1);
      SkipSpaceA(p);
      if p^ = ord('=') then
      begin
        inc(p);
        SkipSpaceA(p);
        if char(p^) in ['''', '"'] then
          Token := p^
        else
          Token := 0;
        // content="text/html; charset='Shift_JIS'"
        S := DecodeTokenA(p, AValueDelimiters, Token, true);
        S := DequotedStrA(S, Token);
        if length(S) > 0 then
        begin
          Result := S;
          Break;
        end;
      end;
    end;
    // I := PosA(pAnsichar('charset'), p, True, 1);
    i := PosA(PAnsiChar('<meta'), p, true, 1);
  end;

end;

function GetCharsetFromStm(stm: TStream): String;
var
  pbody: PAnsiChar;
  S    : AnsiString;
  ASize: integer;
begin
  ASize := stm.Size;
  if ASize > 2048 then
    ASize      := 2048;
  stm.Position := 0;
  setlength(S, ASize);
  stm.ReadBuffer(PAnsiChar(S)^, length(S));
  Result := DecodeCharset((S), ASize);
end;

function GetStrFromStm(stm: TStream): String;
var
  pbody: PAnsiChar;
  S    : AnsiString;
  ASize: integer;
begin
  ASize        := stm.Size;
  stm.Position := 0;
  setlength(S, ASize);
  stm.ReadBuffer(PAnsiChar(S)^, length(S));
  Result := S;
end;

{ TMuHttpGet }

constructor TMuHttpGetBase.Create;
begin
  FTimeOut       := 30;
  FShowException := false;
end;

destructor TMuHttpGetBase.Destroy;
begin
  inherited;
end;

function TMuHttpGetBase.Get(aUrl: String): String;
begin
  Result := doget(Self, aUrl);
end;

procedure TMuHttpGetBase.SetTimeout(const Value: integer);
begin
  FTimeOut := Value;
end;

function TMuHttpGetBase.HtmlStreamToString(aStream: TStream; var Charset: String): String;
begin
  aStream.Position := 0;
  if (Charset = '') or (Charset = 'ISO-8859-1') then
    Charset        := GetCharsetFromStm(aStream);
  aStream.Position := 0;
  if Charset = '' then
  begin
    Result := qstring.LoadTextA(aStream, TTextEncoding.teAuto);
  end
  else
    Result := ReadStringAsCharset(aStream, Charset);
end;

function TMuHttpGetBase.PrepairUrl: String;
begin
  FURI := TURI.Create(FURL);
  if FUsername <> '' then
    FURI.Username := Self.FUsername;
  if FPassword <> '' then
    FURI.Password := Self.FPassword;
  FURL            := Self.FURI.ToString();
  Result          := FURL;
end;

function TMuHttpGet_wnet.doget(aInst: TMuHttpGetBase; aUrl: String): String;
begin
  Result := TMuHttpGet_wnet(aInst).Get(aUrl);
end;

procedure TMuHttpGet_wnet.freehttp(aObject: Thttpclient);
begin
  inherited;
  HttpClientPool.return(Thttpclient(aObject));
end;

function TMuHttpGet_wnet.inithttp: Thttpclient;
begin
  Result := HttpClientPool.Get;
end;

function TMuHttpGet_wnet.Get(aUrl: String): String;
var
  i       : integer;
  http    : Thttpclient;
  BOMSize : integer;
  Encoding: TEncoding;
  S       : AnsiString;
  stm     : TMemoryStream;
  resp    : IHTTPResponse;
  AHeaders: TNetHeaders;
  Request : IHTTPRequest;
begin
  // inherited;
  // resp := Http.Get(Edit1.text);

  if aUrl <> '' then
    FURL := aUrl;
  PrepairUrl;
  Result := '';
  if FTimeOut < 1000 then
    FTimeOut := FTimeOut * 1000;
  // Self.inithttp;
  http := Thttpclient(inithttp);
  // http := THttpClient.Create;
  FStatusCode := 0;

  try
    FLastUrl := FURL;

    // http.r := Self.FReferer;

    http.AutomaticDecompression := [THTTPCompressionMethod.Deflate, THTTPCompressionMethod.GZip,
      THTTPCompressionMethod.Brotli, THTTPCompressionMethod.Any];

    http.ResponseTimeout   := FTimeOut;
    http.ConnectionTimeout := FTimeOut;
    http.HandleRedirects   := true;

    FLastUrl := FURL;

    try
      if not Assigned(stmpool) then
        stmpool := TStmPool.Create(10);

      stm := stmpool.Get; // TmemoryStream.Create;
      try
        log('get url:%s', [FURL]);
        try
          Request := http.GetRequest(sHTTPMethodGet, FURL);
          if FReferer <> '' then
            Request.HeaderValue['Referer'] := FReferer;

          for i := Low(FCusHeaders) to High(FCusHeaders) do
            Request.AddHeader(FCusHeaders[i].Name, FCusHeaders[i].Value);

          Request.UserAgent := FUserAgent;

          resp := http.Execute(Request, stm, nil);

          FStatusCode := (resp.StatusCode);

          FLastUrl := Request.URL.ToString;
          if FLastUrl = '' then
            FLastUrl := FURL;
        except
          on E: Exception do
          begin
            Result := '';
            Exit;
          end;
        end;
        stm.Position := 0;
        FCharset     := resp.ContentCharSet;
        if (FCharset = 'utf8') then
          FCharset     := 'utf-8';
        Result         := HtmlStreamToString(stm, FCharset);
        FContentString := Result;
        FContentType   := resp.ContentEncoding;; // (http.Response.ContentType);

        log('get url:%s,code:%d', [FURL, FStatusCode]);
      finally
        // stm.Free;
        stmpool.return(stm);
      end;
    except
      on E: Exception do
      begin
        Result := '';
      end;
    end;
    Self.FContentString := Result;

  finally
    // http.Free;
    //
    freehttp(http);
    // Self.freehttp;
  end;
end;

{ TMuHttpget }

class constructor TMuHttpgetM.Create;
begin

end;

class destructor TMuHttpgetM.Destroy;
begin

end;

class function TMuHttpgetM.Create: TMuHttpget;
begin
  Result := TMuHttpget(FMuHttpGetBaseClass.Create);
end;

class procedure TMuHttpgetM.RegisterMuHttpGetBaseClass(const aMuHttpGetBaseClass: TMuHttpGetBaseClass);
begin
  FMuHttpGetBaseClass := aMuHttpGetBaseClass;
end;

{ TMuHttpGet_indy }

{$IFDEF INDY}

function TMuHttpGet_indy.inithttp: Tidhttp;
var
  http: Tidhttp;
begin
  http                 := Tidhttp.Create(nil);
  http.IOHandler       := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  http.HandleRedirects := true;
  Result               := http;
  // Result := idhttpPool.Get;
end;

procedure TMuHttpGet_indy.freehttp(aObject: Tidhttp);
begin
  aObject.IOHandler.Free;
  aObject.Free;
  // idhttpPool.return(Tidhttp(aObject));
end;

function TMuHttpGet_indy.doget(aInst: TMuHttpGetBase; aUrl: String): String;
begin
  Result := TMuHttpGet_indy(aInst).Get(aUrl);
end;

function TMuHttpGet_indy.Get(aUrl: String): String;
var
  http    : Tidhttp;
  BOMSize : integer;
  Encoding: TEncoding;
  S       : AnsiString;
  stm     : TMemoryStream;

begin
  // inherited;
  if aUrl <> '' then
    FURL := aUrl;
  PrepairUrl;
  Result := '';
  if FTimeOut < 1000 then
    FTimeOut  := FTimeOut * 1000;
  http        := Tidhttp(inithttp());
  FStatusCode := 0;
  try
    http.Request.UserAgent := Self.FUserAgent;
    http.Request.Referer   := Self.FReferer;

    if FTimeOut < 1000 then
      FTimeOut := FTimeOut * 1000;

    http.ReadTimeout    := FTimeOut;
    http.ConnectTimeout := FTimeOut;

    FLastUrl := FURL;
    try
      stm := stmpool.Get; // TmemoryStream.Create;
      try
        log('get url:%s', [FURL]);
        try
          http.Get(FURL, stm);
        except
          on E: Exception do
          begin
            Result := '';
            // FIP := http.Socket.Binding.PeerIP;
            FStatusCode := (http.ResponseCode);
            Exit;
          end;
        end;
        stm.Position := 0;
        FCharset     := http.Response.Charset;
        if (FCharset = 'utf8') then
          FCharset     := 'utf-8';
        Result         := HtmlStreamToString(stm, FCharset);
        FContentString := Result;

        FLastUrl := http.URL.URI;
        FIP      := http.Socket.Binding.PeerIP;

        FContentType := (http.Response.ContentType);
        FStatusCode  := (http.ResponseCode);

        log('get url:%s,code:%d', [FURL, FStatusCode]);
      finally
        // stm.Free;
        stmpool.return(stm);
      end;
    except
      on E: Exception do
      begin
        Result := '';
      end;
    end;
    Self.FContentString := Result;
  finally
    Self.freehttp(http);
  end;

end;
{$ENDIF}
{$IFDEF ICS}

{ TMuHttpGet_ics }
function TMuHttpGet_ics.doget(aInst: TMuHttpGetBase; aUrl: String): String;
begin
  Result := TMuHttpGet_ics(aInst).Get(aUrl);
end;

procedure TMuHttpGet_ics.freehttp(aObject: pointer);
begin
  inherited;

end;

function TMuHttpGet_ics.inithttp: pointer;
begin

  inherited;
end;

function TMuHttpGet_ics.Get(aUrl: String): String;

var
  BOMSize        : integer;
  Encoding       : TEncoding;
  S              : AnsiString;
  m              : TMemoryStream;
  FResponseStream: TMemoryStream;
  FSslHttpCli    : TSslHttpCli;
  FSslContext    : TSslContext;
begin
  // inherited;
  if aUrl <> '' then
    FURL := aUrl;
  PrepairUrl;
  if FTimeOut < 1000 then
    FTimeOut      := FTimeOut * 1000;
  FResponseStream := stmpool.Get;
  FStatusCode     := 0;
  try
    try
      // ICS 有个bug，就是连续使用的到时候 timeout计数还是从第一个开始，不能用池

      FSslHttpCli               := TSslHttpCli.Create(nil);
      FSslContext               := TSslContext.Create(nil);
      FSslContext.SslMinVersion := sslVerTLS1;
      FSslHttpCli.SslContext    := FSslContext;
      // FSslHttpCli.OnSelectDns := SslHttpCliSelectDns;
      FSslHttpCli.Timeout := FTimeOut;

      FSslHttpCli.Agent     := Self.FUserAgent;
      FSslHttpCli.Reference := Self.FReferer;
      FSslHttpCli.Timeout   := FTimeOut;
      FLastUrl              := FURL;

      FSslHttpCli.RcvdStream := FResponseStream;
      FSslHttpCli.URL        := FURL;

      // FSslHttpCli.CtrlSocket.Counter.ConnectTick := gettickcount;
      FSslHttpCli.Get;

      Self.FIP := (FSslHttpCli.DnsResult);;

      FContentType := (FSslHttpCli.ContentType);
      FStatusCode  := (FSslHttpCli.StatusCode);
      if FSslHttpCli.StatusCode div 200 = 1 then
      begin
        FLastUrl       := (FSslHttpCli.Location);
        FContentLength := FSslHttpCli.ContentLength;

        // first look for codepage in HTTP charset header, rarely set
        BOMSize := 0;

        // ICS是没有解压的
        if Pos('gzip', LowerCase(FSslHttpCli.ContentEncoding)) > 0 then
        begin
          m := TMemoryStream.Create;
          try
            DecompressGZip(FResponseStream, m);
            FResponseStream.Position := 0;
            FResponseStream.Write(m.Memory^, m.Size);
            FResponseStream.Size := FResponseStream.Position;
          finally
            m.Free;
          end;
        end;
        FCharset := CharsetFromContentType(FSslHttpCli.ContentType);
        if (FCharset = 'utf8') then
          FCharset     := 'utf-8';
        FContentString := Self.HtmlStreamToString(FResponseStream, FCharset);

        Result := FContentString;
      end;
    except
      on E: Exception do
      begin
        log('ics httpget %s', [E.Message]);
      end;
    end;
    // FResponseStream.Position := 0;
    // FResponseStream.Clear;
  finally
    if FSslHttpCli.Connected then
      FSslHttpCli.Abort;
    FSslHttpCli.Free;
    FSslContext.Free;

    stmpool.return(FResponseStream);
  end;

end;
{$ENDIF}
{ TMuHttpGet_curl }
{$IFDEF CURL}

function TMuHttpGet_curl.inithttp: pointer;
begin
  Result := CurlhttpsPool.Get();
end;

function TMuHttpGet_curl.doget(aInst: TMuHttpGetBase; aUrl: String): String;
begin
  Result := TMuHttpGet_curl(aInst).Get(aUrl);
end;

procedure TMuHttpGet_curl.freehttp(aObject: pointer);
begin
  inherited;
  CurlhttpsPool.return(IMCURL(aObject));
end;

function TMuHttpGet_curl.Get(aUrl: String): String;
var
  httpt: TMCURL;
  http : IMCURL;
  stm  : TMemoryStream;
begin
  if aUrl <> '' then
    FURL := aUrl;
  PrepairUrl;
  if FTimeOut < 1000 then
    FTimeOut  := FTimeOut * 1000;
  FStatusCode := 0;
  // http := CurlhttpsPool.Get();
  http := TMCURL.Create;

  stm := stmpool.Get; // TmemoryStream.Create;
  try
    try
      try
        if FReferer <> '' then
        begin
          TMCURL(http).Referer := FReferer;
        end;
        FLastUrl := FURL;
        http.SetUrl(FURL).SetFollowLocation(true).SetSslVerifyPeer(false).SetRecvStream(stm, []).Perform;

        FLastUrl := TMCURL(http).ResultUrl;

        if FLastUrl = '' then
          FLastUrl := FURL;

        FCharset       := TMCURL(http).Charset;
        FContentType   := TMCURL(http).ContentType;
        FContentString := HtmlStreamToString(stm, FCharset);

        FStatusCode := http.ResponseCode;

        if (FCharset = 'utf8') then
          FCharset := 'utf-8';

        Result := FContentString;

      except
        on E: Exception do
        begin
          log('curl httpget %s', [E.Message]);
        end;
      end;
    finally
      stmpool.return(stm);
    end;
  finally
    http := nil;
    // CurlhttpsPool.return(http);
  end;
end;
{$ENDIF}
// { TMuHttpPool } -----------------------------------------------------------------------------------------------------

constructor TMuHttpPool.Create(Poolsize: integer);
begin
  FPool := TQSimplePool.Create(Poolsize, FOnObjectCreate, FOnObjectFree, FOnObjectReset);
end;

destructor TMuHttpPool.Destroy;
begin
  FPool.Free;
  inherited;
end;

procedure TMuHttpPool.FOnObjectCreate(Sender: TQSimplePool; var AData: pointer);
var
  http: TMuHttpget;
begin
  http           := TMuHttpgetM.Create;
  http.UserAgent :=
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.37 (KHTML, like Gecko) Chrome/78.0.3626.121 Safari/537.36';
  http.Timeout       := localsetup.httptimeout;
  http.ShowException := localsetup.ShowException;
  AData              := http;
end;

procedure TMuHttpPool.FOnObjectFree(Sender: TQSimplePool; AData: pointer);
begin
  freeandnil(TMuHttpGetBase(AData));
end;

procedure TMuHttpPool.FOnObjectReset(Sender: TQSimplePool; AData: pointer);
var
  http: TMuHttpGetBase;
begin
  http                := (AData);
  http.FURL           := '';
  http.FIP            := '';
  http.FLastUrl       := '';
  http.FCharset       := '';
  http.FHtmlCodePage  := 0;
  http.FContentLength := 0;
end;

function TMuHttpPool.Get: TMuHttpget;
begin
  Result := TMuHttpget(FPool.pop);
end;

procedure TMuHttpPool.return(AData: TMuHttpget);
begin
  FPool.Push(AData);
end;

// -----------------------------------------------------------------------------------------------------

var
  HTTPPoolDefaultCount: integer = 1;
  MuHttpGetBaseClass  : TMuHttpGetBaseClass;

initialization

case localsetup.httptype of
  0:
    MuHttpGetBaseClass := TMuHttpGet_wnet;
  1:
    MuHttpGetBaseClass := {$IFDEF INDY} TMuHttpGet_indy {$ELSE} TMuHttpGet_wnet {$ENDIF};
  2:
    MuHttpGetBaseClass := {$IFDEF ICS}TMuHttpGet_ics {$ELSE} TMuHttpGet_wnet {$ENDIF};
  3:
    MuHttpGetBaseClass := {$IFDEF CURL} TMuHttpGet_curl {$ELSE} TMuHttpGet_wnet {$ENDIF};

else
  MuHttpGetBaseClass := TMuHttpGet_wnet;
end;

TMuHttpgetM.RegisterMuHttpGetBaseClass(MuHttpGetBaseClass);

MuHttpPool := TMuHttpPool.Create(HTTPPoolDefaultCount);

case localsetup.httptype of
  3:
{$IFDEF CURL} curl_global_init(CURL_GLOBAL_DEFAULT){$ENDIF};

end;

finalization

{$IFDEF CURL}
if localsetup.httptype = 3 then
  curl_global_cleanup;
case localsetup.httptype of
  3:
    curl_global_cleanup;

end;
{$ENDIF}
if Assigned(MuHttpPool) then
  MuHttpPool.Free;

end.
