unit MTP.Plugin.base;

interface

uses sysutils, windows, System.Classes, Generics.Collections, //
  qplugins_base, qplugins, qplugins_params, qplugins_loader_lib,
  qstring, qjson, MTP.Utils, MTP.Types, MTP.Expression;

// function hp_calendar(aNode: TMNode; pdata: Pointer; aDataParser: IMDataParser): String;
type
  IMuMTPNodeParserPlugin = interface
    ['{E47E406D-9605-4D2A-90FB-45291E711639}']
    function NodeName: String;
    function NodeParser: TCusParseNodeP;
    // function NodeParser(aNode: TMNode; pdata: Pointer; aDataParser: IMDataParser): String;
  end;

type
  TMuMTPNodeParserPlugin = class(TQService, IMuMTPNodeParserPlugin)
    private
    protected
      FNodeName     : String;
    public
      constructor create(const AName: QStringW); reintroduce; virtual;
      destructor Destroy; override;
      function NodeName: String; virtual;
      function NodeParser: TCusParseNodeP; virtual;
  end;

implementation

{ TMuMTPNodeParserPlugin }

constructor TMuMTPNodeParserPlugin.create(const AName: QStringW);
begin
  inherited create(TGUID.NewGuid, AName);
  self.FNodeName := AName;
end;

destructor TMuMTPNodeParserPlugin.Destroy;
begin

  inherited;
end;

function TMuMTPNodeParserPlugin.NodeName: String;
begin
  result := FNodeName;
end;

function TMuMTPNodeParserPlugin.NodeParser: TCusParseNodeP;
begin

end;

initialization

finalization

end.
