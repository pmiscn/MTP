program Https;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Curl.Lib in '..\..\..\Curl.Lib.pas',
  Curl.Easy in '..\..\..\Curl.Easy.pas',
  Curl.Interfaces in '..\..\..\Curl.Interfaces.pas';

var
  curl : ICurl;

function CheckCurlCode(ACode: TCurlCode;  ARaiseException: Boolean=false): Boolean;
var
  E: EInOutError;
begin
  Result := (ACode = CURLE_OK);
  if (not Result) and ARaiseException then
  begin
 //   FStatusCode := 599;
//    FStatusText := curl_easy_strerror(ACode);
 //   E := EInOutError.Create(FStatusText);
    E.ErrorCode := Ord(ACode);
    raise E;
  end;
end;

begin
  try
  //curl_easy_setopt(FHandle, CURLOPT_REFERER, PAnsiChar(FReferer)
    curl := CurlGet;
    curl.SetUrl('https://www.163.com/')
        .SetFollowLocation(true)
        .SetSslVerifyPeer(false)
        .SwitchRecvToString
        .setOpt(CURLOPT_REFERER,'http://www.baidu.com')
 //     .SetCaFile('cacert.pem')
        // Unicode is also supported!
        //.SetCaFile('α×β.pem')
        // Perform the request, res will get the return code
        .Perform;
   // curl.ResponseBody;
    // Check for errors
    Writeln(curl.getinfo(CURLINFO_EFFECTIVE_URL));
    Writeln(curl.getinfo(CURLINFO_SIZE_DOWNLOAD).ToString);
    Writeln(curl.getinfo(CURLINFO_CONTENT_TYPE));
    Writeln(curl.getinfo(CURLINFO_PRIMARY_IP));

    Writeln(curl.getinfo(CURLINFO_PRIVATE));



    Writeln(curl.ResponseBody);
    Writeln;
    Writeln(Format('HTTP response code: %d', [ curl.ResponseCode ] ));
  except
    on e : Exception do
      writeln('cURL failed: ', e.Message);
  end;

  Readln;
end.
