unit MTP.HtmlPlugin;

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
      FCusParseNodeP: TCusParseNodeP;
    public
      constructor create(aNodeName: String); virtual;
      destructor Destroy; override;
      function NodeName: String; virtual;
      function NodeParser: TCusParseNodeP; virtual;
  end;

implementation

{ TMuMTPNodeParserPlugin }

constructor TMuMTPNodeParserPlugin.create(aNodeName: String);
begin
  self.FNodeName := aNodeName;
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
  result := self.FCusParseNodeP;
end;

procedure initplugins(filter: String);
var
  aPath   : String;
  i       : integer;
  ARoot   : IQServices;
  AService: IMuMTPNodeParserPlugin;
  names   : String;
begin
  aPath := ExtractFilePath(paramstr(0)) + 'MtpPlugins\';

  if extractfileext(filter).tolower() <> '.dll' then
    filter := filter + '.dll';

  PluginsManager.Loaders.Add(TQDLLLoader.create(aPath, filter, true));
  PluginsManager.Start;

  ARoot := FindService('/Services/MtpPlugins') as IQServices;
  if Assigned(ARoot) then
  begin
    for i := 0 to ARoot.Count - 1 do
    begin
      if Supports(ARoot[i], IMuMTPNodeParserPlugin, AService) then
      begin
        if ARoot[i].Name <> '' then
        begin
          AService := ARoot[i] as IMuMTPNodeParserPlugin;
          // FServices.Add(ARoot[i]);
          pubPluginsHandles.RegNodeHandler(AService.NodeName, AService.NodeParser);
        end;
      end
    end;
  end;

end;

initialization

// pubCusNodeHandles.RegNodeHandler('calendar', hp_calendar);

initplugins('*.dll');

finalization

end.
