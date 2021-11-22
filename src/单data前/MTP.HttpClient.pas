unit MTP.HttpClient;

interface

uses sysutils, System.Classes, Generics.Collections,
  qstring, qjson, MTP.Types, MTP.Utils;

type
  TMHttpGet = class
  public
    class function get(aUrl: String): String;
  end;

implementation

{ TMHttpC }

class function TMHttpGet.get(aUrl: String): String;
begin

end;

end.
