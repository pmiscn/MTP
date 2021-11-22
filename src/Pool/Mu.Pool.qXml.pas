unit Mu.Pool.qXml;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  QSimplePool, Generics.Collections,
  SyncObjs, qXml,
  System.Classes;

type

  TXmlPool = class(TObject)
    private
      FPool: TQSimplePool;
      procedure FOnObjectCreate(Sender: TQSimplePool; var AData: Pointer);
      procedure FOnObjectFree(Sender: TQSimplePool; AData: Pointer);
      procedure FOnObjectReset(Sender: TQSimplePool; AData: Pointer);
    protected

    public
      constructor Create(Poolsize: integer = 100);
      destructor Destroy; override;
      function get(): TQXML;
      procedure return(aSt: TQXML);
      procedure release(aSt: TQXML);

  end;

var
  XmlPool: TXmlPool;

implementation

constructor TXmlPool.Create(Poolsize: integer);
begin

  FPool := TQSimplePool.Create(Poolsize, FOnObjectCreate, FOnObjectFree, FOnObjectReset);
end;

destructor TXmlPool.Destroy;
begin
  FPool.Free;
  inherited;
end;

procedure TXmlPool.FOnObjectCreate(Sender: TQSimplePool; var AData: Pointer);
begin
  TQXML(AData) := TQXML.Create;
end;

procedure TXmlPool.FOnObjectFree(Sender: TQSimplePool; AData: Pointer);
begin
  TQXML(AData).Free;
end;

procedure TXmlPool.FOnObjectReset(Sender: TQSimplePool; AData: Pointer);
begin
  TQXML(AData).Clear;
end;

function TXmlPool.get: TQXML;
begin
  result := TQXML(FPool.pop);
end;

procedure TXmlPool.release(aSt: TQXML);
begin
  aSt.Clear;
  FPool.push(aSt);
end;

procedure TXmlPool.return(aSt: TQXML);
begin
  release(aSt);
end;

initialization

XmlPool := TXmlPool.Create(100);

finalization

if assigned(XmlPool) then
  XmlPool.Free;

end.
