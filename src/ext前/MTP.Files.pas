unit MTP.Files;

interface

uses sysutils, windows,
  System.Classes, Generics.Collections, FireDAC.Comp.Client,

  qstring, qjson, MTP.Types, MTP.Data, MTP.Utils, MTP.Parse, MTP.Expression;

var
  MRootPath: string;

type

  TMFileCatch = class

    public
      constructor Create();
      destructor Destroy; override;

  end;

  TFileNodeList = TObjectDictionary<String, TMNode>;
  TTextNodeList = TObjectDictionary<String, TMNode>;

  TMFileParse = class
    protected
      FFileList: TFileNodeList;
    public
      constructor Create();
      destructor Destroy; override;

      function GetNodeFromFilePool(const afile: string; params: TQjson): TMNode;
      function GetNodeFromTextPool(const atext: string): TMNode;
      function CreateNode(const aFileName: String): TMNode;

      class function getFilePath(const afile, aPath: string): string;

      class function getdata(aNode: TMNode; aPath: string; aParams: TQjson; Data: Pointer): boolean;
      class function getdata_dataset(aNode: TMNode; aPath: string; aParams: TQjson; Data: Pointer): boolean;

      class function ParseFile(const aFileName: String; aDataParser: IMDataParser; aData: Pointer = nil;
        aParams: TQjson = nil; aNeedParse: boolean = true): String;

      class function Parse(const aFileName: String; aParams: TQjson = nil; aNeedParse: boolean = true): String;
      class function Parse_Dataset(const aNode: TMNode; const aPath: String; aParams: TQjson = nil;
        aNeedParse: boolean = true): String;

      class function ParseText(const atext: String; aDataParser: IMDataParser; aData: Pointer = nil;
        aParams: TQjson = nil; aNeedParse: boolean = true): String;
  end;

var
  MFileParse: TMFileParse;

implementation

uses MTP.HttpClient, Mu.Pool.qjson, MTP.Parse.JSON, MTP.Parse.dataset;
{ TMFileParse }

constructor TMFileParse.Create;
begin
  FFileList := TFileNodeList.Create([doOwnsValues], 10);

end;

function TMFileParse.CreateNode(const aFileName: String): TMNode;
var
  ps: String;
begin
  result        := TMNode.Create(nil);
  result.IsRoot := true;

  ps := qstring.LoadTextW(aFileName);
  TMTextParse.GetAllNode(ps, result, true, false);

end;

destructor TMFileParse.Destroy;
var
  i: integer;
var
  p: TPair<string, TMNode>;
begin
  // for p in FFileList do
  // freeobject(p.Value);
  FFileList.Clear;
  freeobject(FFileList);
  inherited;
end;

class function TMFileParse.getdata(aNode: TMNode; aPath: string; aParams: TQjson; Data: Pointer): boolean;
var
  p, pstr             : Pchar;
  l, poss, pose, i, i2: integer;
  isOneline           : boolean;
  fpath, jsstr        : String;
  dprop               : TMDataProp;
  nd                  : TMNode;
begin

  result := false;
  nd     := nil;
  if aNode.NodeType = mtData then
    nd := aNode
  else
    for i := 0 to aNode.count - 1 do
      if aNode[i].NodeType = mtData then
      begin
        nd := aNode[i];
        break;
      end;
  if nd = nil then
    exit;

  dprop.Create(nd);
  // file

  result := TMData.getdata(dprop, aParams, Data);

end;

class function TMFileParse.getdata_dataset(aNode: TMNode; aPath: string; aParams: TQjson; Data: Pointer): boolean;
begin

end;

class function TMFileParse.getFilePath(const afile, aPath: string): string;
var
  p: String;
begin
  if pos(':', afile) < 1 then
  begin
    if (afile[1] in ['/', '\']) or (aPath = '') then
    begin
      // 根目录开始
      result := MRootPath + afile;
    end else begin
      p := aPath;
      if not(p[length(p)] in ['/', '\']) then
        p    := p + '/';
      result := p + afile;
    end;
  end;
end;

function TMFileParse.GetNodeFromTextPool(const atext: string): TMNode;
var
  n: TMNode;
begin
  if not self.FFileList.TryGetValue(atext, result) then
  begin
    n        := TMNode.Create(nil);
    n.IsRoot := true;
    TMTextParse.GetAllNode(atext, n, false, true);
    FFileList.Add(atext, n);
    result := n;
  end;
end;

function TMFileParse.GetNodeFromFilePool(const afile: string; params: TQjson): TMNode;
var
  n : TMNode;
  ps: String;
begin
  if not FFileList.TryGetValue(afile, result) then
  begin
    n        := TMNode.Create(nil);
    n.IsRoot := true;
    ps       := qstring.LoadTextW(afile);
    TMTextParse.GetAllNode(ps, n, true, false);

    FFileList.Add(afile, n);
    result := n;
  end;
end;

class function TMFileParse.Parse(const aFileName: String; aParams: TQjson; aNeedParse: boolean): String;
var
  ps   : String;
  aData: Pointer;
  nd   : TMNode;

begin
  result := '';

  if not aNeedParse then
  begin
    result := qstring.LoadTextW(aFileName);
    exit;
  end;
  // 用池的时候经常出现闪退，暂时不用，以后检测。

  // nd := MFileParse.GetNodeFromFilePool(aFileName, aParams);
  nd := MFileParse.CreateNode(aFileName);

  try
    if nd.count = 0 then
    begin
      result := qstring.LoadTextW(aFileName);
      exit;
    end;
    if nd.DataType = TMDataType.mdtDataset then
    begin
      result := Parse_Dataset(nd, extractfilepath(aFileName), aParams, aNeedParse);
    end else begin

      try
        aData := qjsonPool.get;
        if TMFileParse.getdata(nd, extractfilepath(aFileName), aParams, aData) then
        begin // pubDataParser_JSON
          result := TMTextParse.ParseNode(nd, aData, TMDataParser_JSON.Create, extractfilepath(aFileName), aParams);
        end;
      finally
        qjsonPool.return(TQjson(aData));
      end;
    end;
  finally
    nd.Free;
  end;
end;

class function TMFileParse.Parse_Dataset(const aNode: TMNode; const aPath: String; aParams: TQjson;
  aNeedParse: boolean): String;
var
  ps   : String;
  nd   : TMNode;
  dsCfg: TQjson;

begin
  dsCfg := qjsonPool.get;
  try
    // 这里不经过data单元处理了
    ps := '';
    if aNode.HasDataNode(nd) then
    begin
      if not dsCfg.tryParse(nd.Content) then
        exit;
      TMDatasetData.getdata(dsCfg, aParams,
        procedure(ADataset: Pointer)
        begin
          ps := TMTextParse.ParseNode(aNode, ADataset,TMDataParser_Dataset.Create , aPath, aParams) //   pubDataParser_dataset
        end);
    end;
    result := ps;
  finally
    qjsonPool.return(dsCfg);
  end;
end;

class function TMFileParse.ParseFile(const aFileName: String; aDataParser: IMDataParser; aData: Pointer = nil;
aParams: TQjson = nil; aNeedParse: boolean = true): String;
var
  ps   : String;
  jdata: Pointer;
  nd   : TMNode;
begin
  result := '';
  if not aNeedParse then
  begin
    result := qstring.LoadTextW(aFileName);
    exit;
  end;

  nd := MFileParse.GetNodeFromFilePool(aFileName, aParams);

  if nd.count = 0 then
    exit;

  if nd.DataType = TMDataType.mdtDataset then
  begin
  end else begin

    try
      jdata := qjsonPool.get;
      if TMFileParse.getdata(nd, extractfilepath(aFileName), aParams, jdata) then
        result := TMTextParse.ParseNode(nd, jdata, aDataParser, extractfilepath(aFileName), aParams)
      else if aData <> nil then
        result := TMTextParse.ParseNode(nd, aData, aDataParser, extractfilepath(aFileName), aParams);
    finally
      qjsonPool.return(jdata);
    end;
  end;
end;

class function TMFileParse.ParseText(const atext: String; aDataParser: IMDataParser; aData: Pointer; aParams: TQjson;
aNeedParse: boolean): String;
var
  ps   : String;
  jdata: Pointer;
  nd   : TMNode;
begin
  result := '';
  nd     := TMNode.Create(nil);
  try
    nd.IsRoot := true;
    TMTextParse.GetAllNode(atext, nd, true, false);

    if nd.count = 0 then
      exit;

    if nd.DataType = TMDataType.mdtDataset then
    begin
    end else begin

      try
        jdata := qjsonPool.get;
        if TMFileParse.getdata(nd, '', aParams, jdata) then
          result := TMTextParse.ParseNode(nd, jdata, aDataParser, '', aParams)
        else if aData <> nil then
          result := TMTextParse.ParseNode(nd, aData, aDataParser, '', aParams);
      finally
        qjsonPool.return(jdata);
      end;
    end;

  finally
    nd.Free;
  end;
end;

{ TMFileCatch }

constructor TMFileCatch.Create;
begin
end;

destructor TMFileCatch.Destroy;
begin

  inherited;
end;

initialization

MFileParse := TMFileParse.Create;

finalization

MFileParse.Free;
// freeandnil(MFileParse);

end.
