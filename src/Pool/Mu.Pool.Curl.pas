unit Mu.Pool.Curl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  Mu.Curl, QSimplePool,

  System.Classes;

type
  TCurlhttpsPool = class(TObject)
  private
    FPool: TQSimplePool;
    procedure FOnCUrlCreate(Sender: TQSimplePool; var AData: Pointer);
    procedure FOnCUrlFree(Sender: TQSimplePool; AData: Pointer);
    procedure FOnCUrlReset(Sender: TQSimplePool; AData: Pointer);

  protected

  public
    constructor Create(Poolsize: integer = 20);
    destructor Destroy; override;
    function get(): IMCURL;
    procedure return(aData: IMCURL);

  end;

var

  CurlhttpsPool: TCurlhttpsPool;

implementation

uses Curl.interfaces;
{ TCurlhttpsRequestPool }

constructor TCurlhttpsPool.Create(Poolsize: integer);
begin
  FPool := TQSimplePool.Create(Poolsize, FOnCUrlCreate, FOnCUrlFree, FOnCUrlReset);

end;

destructor TCurlhttpsPool.Destroy;
begin
  FPool.Free;
  inherited;
end;

procedure TCurlhttpsPool.FOnCUrlCreate(Sender: TQSimplePool; var AData: Pointer);
begin
  AData := TMCURL.Create;
end;

procedure TCurlhttpsPool.FOnCUrlFree(Sender: TQSimplePool; AData: Pointer);
begin
  ICloseable(AData) := nil;
  // IMCURL(AData) := nil;
//  AData := nil;
end;

procedure TCurlhttpsPool.FOnCUrlReset(Sender: TQSimplePool; AData: Pointer);
begin

end;

function TCurlhttpsPool.get: IMCURL;
begin
  result := TMCURL(FPool.pop);
end;

procedure TCurlhttpsPool.return(aData: IMCURL);
begin
  FPool.push(aData);
end;

initialization

CurlhttpsPool := TCurlhttpsPool.Create(10);

finalization

CurlhttpsPool.Free;

end.
