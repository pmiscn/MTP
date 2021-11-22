program Simple;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Curl.Easy in '..\..\..\Curl.Easy.pas',
  Curl.Lib in '..\..\..\Curl.Lib.pas',
  Curl.Form in '..\..\..\Curl.Form.pas',
  Curl.Interfaces in '..\..\..\Curl.Interfaces.pas';

const
  // I won�t use example.com, as someone removed redirection from example.com
  // AFAIK, ithappens.ru redirects to ithappens.me
  Url = 'https://www.163.com/';
var
  curl : ICurl;
  code : integer;
  ul, dl : TCurlOff;
  effurl : PAnsiChar;
  engines : PCurlSList;
begin
  try
    curl := CurlGet;
    curl.SetUrl(Url)
        .SetFollowLocation(true)
        .Perform;

    // Check for some info
    code := curl.ResponseCode;
    ul := curl.GetInfo(CURLINFO_SIZE_UPLOAD_T);
    dl := curl.GetInfo(CURLINFO_SIZE_DOWNLOAD_T);
    effurl := curl.GetInfo(CURLINFO_EFFECTIVE_URL);
    engines := curl.GetInfo(CURLINFO_SSL_ENGINES);
    Writeln(Format('HTTP response code: %d', [ code ] ));
    Writeln(Format('Uploaded: %d', [ ul ] ));
    Writeln(Format('Downloaded: %d', [ dl ] ));
    Writeln(Format('Effective URL: %s', [ effurl ] ));
    Writeln('SSL engines:');
    while engines <> nil do begin
      Writeln ('- ', engines^.Data);
      engines := engines^.Next;
    end;
  except
    on e : Exception do
      Writeln(Format('cURL failed: %s',
              [ e.Message ] ));
  end;

  Readln;
end.

