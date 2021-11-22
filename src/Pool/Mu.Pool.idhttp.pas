unit Mu.Pool.idhttp;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  idhttp, IdBaseComponent, IdComponent, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL,
  IdSSLOpenSSL, QSimplePool,

  System.Classes;

type
  TidhttpPool = class(TObject)
  private
    FPool: TQSimplePool;
    procedure FOnidhttpCreate(Sender: TQSimplePool; var AData: Pointer);
    procedure FOnidhttpFree(Sender: TQSimplePool; AData: Pointer);
    procedure FOnidhttpReset(Sender: TQSimplePool; AData: Pointer);

  protected

  public
    constructor Create(Poolsize: integer = 20);
    destructor Destroy; override;
    function get(): Tidhttp;
    procedure return(adata: Tidhttp);

  end;

var

  idhttpPool: TidhttpPool;

implementation

{ TidhttpRequestPool }

constructor TidhttpPool.Create(Poolsize: integer);
begin
  FPool := TQSimplePool.Create(Poolsize, FOnidhttpCreate, FOnidhttpFree, FOnidhttpReset);

end;

destructor TidhttpPool.Destroy;
begin
  FPool.Free;
  inherited;
end;

procedure TidhttpPool.FOnidhttpCreate(Sender: TQSimplePool; var AData: Pointer);
var
  http: Tidhttp;
begin

  http := Tidhttp.Create(nil);
  http.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  http.HandleRedirects := true;
  AData := http;
end;

procedure TidhttpPool.FOnidhttpFree(Sender: TQSimplePool; AData: Pointer);
begin
  Tidhttp(AData).IOHandler.Free;
  Tidhttp(AData).Free;;
end;

procedure TidhttpPool.FOnidhttpReset(Sender: TQSimplePool; AData: Pointer);
begin

end;

function TidhttpPool.get: Tidhttp;
begin
  result := Tidhttp(FPool.pop);
end;

procedure TidhttpPool.return(adata: Tidhttp);
begin
  FPool.push(adata);
end;

initialization

idhttpPool := TidhttpPool.Create(100);

finalization

idhttpPool.Free;

end.
