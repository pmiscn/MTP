unit MTP.Plugin.host;

interface

uses sysutils, windows, System.Classes, Generics.Collections, //
  qplugins_base, qplugins, qplugins_params, qplugins_loader_lib,
  qstring, qjson, MTP.Utils, MTP.Types, MTP.plugin.base;

implementation

procedure initplugins(filter: String);
var
  aPath   : String;
  i       : integer;
  ARoot   : IQServices;
  AService: IMuMTPNodeParserPlugin;
  names   : String;
begin
  aPath := ExtractFilePath(paramstr(0)) + 'plugins\MtpPlugins\';

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

initplugins('.dll');

finalization

end.
