unit MTP.Types;

interface

uses sysutils, System.Classes, Generics.Collections, MTP.Utils, qjson;

type
  TMtpConfig = record
    PoolFile: boolean;
    public
      class function create(): TMtpConfig; static;
  end;

  // 节点属性，暂时不用了，就那么几个，列举就够了
  TMKeyValue = record
    key: String;
    value: String;
  end;

  PMKeyValues = ^TMKeyValues;

  TMKeyValues = TArray<TMKeyValue>;

  TMKeyValues_help = record helper for TMKeyValues
    protected
      procedure setValue(const aKey, aValue: String);
    public
      function Parse(s: String): TMKeyValues;
      procedure Add(aKey, aValue: String);
      function GetValue(const aKey: String; var aValue: String): boolean; overload;
      function GetValue(const aKey: String): String; overload;
      function HasKey(aKey: String): boolean;
      function IndexOf(const aKey: String): integer;
      property value[const aKey: String]: String Read GetValue write setValue;
  end;

  TMDataOrigin = (mdoUnknow, mdoJson, mdoHttp, mdoMuDB, mdoFile, mdoMfp, mdoFileList, mdoPlugin, mdoQPlugin, mdoCustom);

  TMDataType = (mdtUnknow, mdtJson, mdtDataset);

  TMDataProp = record
    OriginName: String;
    Origin: TMDataOrigin;
    DataType: TMDataType;
    Path: String;
    Timeout: integer;
    Content: String;
    DataPath: String;
    Properties: TMKeyValues;
  end;

  TMDataOriginExec = function(aDataProp: TMDataProp; var aResult: Pointer): integer;

  TMDataOrigin_ = record helper for TMDataOrigin
    public
      class var FOriginProc: TDictionary<string, TMDataOriginExec>;
      class constructor create;
      class destructor Destroy;
      class function IsRegisted(const aName: string): boolean; static;
      class function ExecCustom(const aDataProp: TMDataProp; aResult: Pointer): integer; static;
      class function RegCustomExec(const aName: String; afunc: TMDataOriginExec): integer; static;

      function create(const s: String): TMDataOrigin; overload;
      function create(const p: PChar): TMDataOrigin; overload;

  end;

  TMNodeType = (mtUnknow, mtRoot, { mtValue, } mtdata, mtIf, mtExp, mtElseIf, mtElse, mtFor, mtEach, mtInclude,
    mtCustom, mtPlugin);
  TMNodeTypes = set of TMNodeType;

  TMNodeType_ = record helper for TMNodeType
    public
      function create(aName: String): TMNodeType; overload;
      function create(p: PChar): TMNodeType; overload;
  end;

  TMDataType_ = record helper for TMDataType
    public
      function create(s: String): TMDataType; overload;
      function create(p: PChar): TMDataType; overload;
  end;

  TMNodeMark = record
    Name: String;
    Start: String;
    End_: String;
    PStart: PChar;
    PEnd: PChar;
    Length: integer;
    EndLength: integer;
    public
      class function create(aName: String): TMNodeMark; static;
      class function GetStartLength(aName: String): integer; static;
      class function GetEndLength(aName: String): integer; static;

      function CompStart(p: PChar; ANotLetterFollow: boolean = false): boolean;
      function CompEnd(p: PChar): boolean;
  end;

  PMNodeValue    = ^TMNodeValue;
  TMNRangeIndexs = TArray<integer>;

  TMNRangeIndexs_ = record helper for TMNRangeIndexs
    public
      function Exists(i: integer): boolean;
  end;

  PMRange = ^TMRange;

  TMRange = record
    RStart: integer;
    REnd: integer;
    Indexs: TMNRangeIndexs;
    public
      class function create(aStart, aEnd: integer): TMRange; static;
      function Parse(rangestr: String): boolean;

  end;

  TMNodeValue = record
    // NodeType: TMNodeType;
    Name: String;
    Head: String;

    // Data: TQjson;   //这个要缓存，不能直接存数据，可以存数据目录
    DataPath: String;

    NodeStart: integer; // 在整个页面起始位置，包括 控制符号
    NodeParentStart: integer;
    NodeLength: integer; // 在整个页面结束位置，包括 控制符号
    NodeString: String;

    ContentStart: integer;  // 有效内容在parent的NodeString的的起始位置
    ContentLength: integer; //
    Content: String;
    // each用的，就不单独为each弄个nodevalue了

    Filter: String;
    Range: TMRange;
    Properties: TMKeyValues;
    LoopVar: String;
    Condition: string;

    { RangeStart: integer;
      RangeEnd: integer;
      RangeIndexs: TMNRangeIndexs;
    }
    public
      {
        function

        property RangeStart: integer read GeTMRangeStart write SeTMRangeStart;
        property RangeEnd: integer read GeTMRangeEnd write SeTMRangeEnd;
        property Indexs: TMNRangeIndexs read GeTMRangeIndexs write SeTMRangeIndexs;
      }
      // root 的content和nodstring是一样的。
    public

  end;

  TMNodeValues = TList<TMNodeValue>;

  TMNode      = class;
  TMNodes     = TList<TMNode>;
  TMNodeArray = TArray<TMNode>;
  TMPage      = class;

  TMNode = class
    private

      procedure SetEndPos(APos: integer);
      procedure SetNodeStart(APos: integer);
      procedure SetContentEnd(APos: integer);
      procedure SetContentStart(APos: integer);
      procedure SetNodeParentStart(APos: integer);

      procedure SetContent(aValue: String);
      procedure SetNodeString(aValue: String);
      procedure SetHead(aValue: String);
      procedure SetDataPath(aValue: String);
      procedure SetFilter(aValue: String);

      procedure SetParent(aValue: TMNode);

      function GetContent(): String;
      function GetFilter(): String;

      function GetHead(): String;
      function GetDataPath(): String;
      function GetNodeStart(): integer;
      function GetEndPos(): integer;
      function GetNodeString(): String;

      function GetContentStart(): integer;
      function GetContentEnd(): integer;
      function GetNodeParentStart(): integer;
      function GetRange(): TMRange;
      procedure SetRange(aValue: TMRange);

      function GetRangeStart: integer;
      procedure SetRangeStart(const value: integer);
      function GetRangeEnd: integer;
      procedure SetRangeEnd(const value: integer);
      function GetRangeIndexs: TMNRangeIndexs;
      procedure SetRangeIndexs(const value: TMNRangeIndexs);
      function GetName: String;
      procedure SetName(const value: String);
      function GetLoopVar: String;
      procedure SetLoopVar(const value: String);
      function GetProperties: TMKeyValues;
      procedure SetProperties(const value: TMKeyValues);
      function GetCondition: String;
      procedure SetCondition(const value: String);

      // function GetConditions(): TMConditions;
    protected
      FNodeType: TMNodeType;

      FNodeValue: TMNodeValue;
      FParent   : TMNode;
      FRoot     : TMNode;
      FItems    : TMNodes;
      FPage     : TMPage;
      FDeep     : integer;
      FIsRoot   : boolean;
      FValue    : String;
      FIndex    : integer;

      function GetItems(const AIndex: integer): TMNode;

      function GetCount(): integer;
      function getPrevious(): TMNode;
      function getNext(): TMNode;
      function GetDataType(): TMDataType;
    public
      constructor create(aParent: TMNode = nil);
      destructor Destroy; override;

      function Parse(aData: TQjson): String;

      function Add(aNodeType: TMNodeType = mtUnknow): TMNode; overload;
      function Add(): TMNode; overload;
      function Add(aNodeValue: TMNodeValue): TMNode; overload;
      function ToJsonString(): String;

      function HasLastChild(var nd: TMNode): boolean;
      function HasDataNode(var nd: TMNode): boolean;
      function HasDataNodes(var nds: TMNodeArray): boolean;

      procedure Clear;
      procedure ToJson(json: TQjson);
      procedure FromJson(json: TQjson);
      property item[const AIndex: integer]: TMNode read GetItems; default;
      property Root: TMNode read FRoot write FRoot;
      property Parent: TMNode read FParent write SetParent;
      property Count: integer read GetCount;
      property NodeValue: TMNodeValue read FNodeValue write FNodeValue;

      property Previous: TMNode read getPrevious;
      property Next: TMNode read getNext;

      property RangeIndexs: TMNRangeIndexs read GetRangeIndexs write SetRangeIndexs;
      property Range: TMRange read GetRange write SetRange;
      property Properties: TMKeyValues read GetProperties write SetProperties;
      property DataType: TMDataType read GetDataType;
    published

      property Items   : TMNodes read FItems;
      property NodeType: TMNodeType read FNodeType write FNodeType;

      property DataPath: String read GetDataPath write SetDataPath;

      property Head           : String read GetHead write SetHead;
      property NodeStart      : integer read GetNodeStart write SetNodeStart;
      property NodeParentStart: integer read GetNodeParentStart write SetNodeParentStart;

      property NodeLength: integer read GetEndPos write SetEndPos;
      property NodeString: String read GetNodeString write SetNodeString;

      property ContentStart : integer read GetContentStart write SetContentStart;
      property ContentLength: integer read GetContentEnd write SetContentEnd;
      property Content      : String read GetContent write SetContent;
      property Filter       : String read GetFilter write SetFilter;
      property Name         : String read GetName write SetName;

      property RangeStart: integer read GetRangeStart write SetRangeStart;
      property RangeEnd  : integer read GetRangeEnd write SetRangeEnd;
      property LoopVar   : String read GetLoopVar write SetLoopVar;
      property Condition : String read GetCondition write SetCondition;

      property value    : String read FValue write FValue;
      property NodeIndex: integer read FIndex write FIndex;
      property Deep     : integer read FDeep write FDeep;

      property IsRoot: boolean read FIsRoot write FIsRoot;
  end;

  TMDataProp_ = record helper for TMDataProp
    public
      function create(kv: TMKeyValues): TMDataProp; overload;
      function create(aNode: TMNode): TMDataProp; overload;
  end;

  //
  TMInterface = class(TObject, IInterface) // TObject
    protected
      function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
      function _AddRef: integer; stdcall;
      function _Release: integer; stdcall;
    public
  end;

  IMDataParser = interface
    ['{D43FE0DE-AF63-4925-AE06-5603674D2DDB}']
    function DataByPath(const aData: Pointer; const aParams: Pointer; const aPath: String): Pointer;
    function TryDataByPath(const aData: Pointer; const aParams: Pointer; const aPath: String;
      var outdata: Pointer): boolean;
    function TryGetData(const aData: Pointer; const aParams: Pointer; const aRootData: Pointer; const aName: String;
      const aAllowOwn: boolean; var r: string): boolean;
    function DataCount(const aData: Pointer): integer;
    function hasPath(const aData: Pointer; const aParams: Pointer; const aPath: String): boolean;
    function Items(const aData: Pointer; const idx: integer): Pointer; overload;

  end;

  // 自定义注册字段
  // TCusGetNodeP = reference to function(var p: Pchar; aNode: TMNode): TMNode;
  TCusParseNodeP = reference to function(aNode: TMNode; data: Pointer; aDataParser: IMDataParser): string;

  TCusNodeHandle = record
    Name: String;
    NodeStart: String;
    NodeEnd: String;
    pNodeStart: PChar;
    pNodeEnd: PChar;
    // GetNode: TCusGetNodeP;
    ParseNode: TCusParseNodeP;
  end;

  TCusNodeHandles = TList<TCusNodeHandle>;

  TCusNodeHandles_ = class helper for TCusNodeHandles
    public
      function RegNodeHandler(aNodeName: String; aParseNode: TCusParseNodeP): integer;
  end;

  //
  TParseNodeFun = function(aNode: TMNode; aData: Pointer; aPath: String = ''; aParams: TQjson = nil;
    aLoopVar: String = ''; aLoopValue: String = ''): String;
  TParseNodeFunA = reference to function(aNode: TMNode; aData: Pointer; aPath: String = ''; aParams: TQjson = nil;
    aLoopVar: String = ''; aLoopValue: String = ''): String;

  TMPage = class
    public
      constructor create();
      destructor Destroy; override;

  end;

var
  pubCusNodeHandles: TCusNodeHandles;
  pubPluginsHandles: TCusNodeHandles;
  pubMtpConfig     : TMtpConfig;

var
  EXPrefix: string = '@';

  EXStart: string = '<#';
  EXEnd  : string = '>';
  EXEndL : string = '/>';

  EXEnd2: string = '</#>';
  EXEndS: string = '</#';

  ExExp    : TMNodeMark;
  ExEach   : TMNodeMark;
  EXIf     : TMNodeMark;
  EXElse   : TMNodeMark;
  EXElseIf : TMNodeMark;
  ExFor    : TMNodeMark;
  EXInclude: TMNodeMark;
  EXData   : TMNodeMark;

  ExDataPath : string = 'datapath';
  ExFilePath : string = 'path';
  ExRange    : String = 'range';
  ExFilter   : String = 'filter';
  ExLoopVar  : String = 'loopvar';
  ExCondition: String = 'condition';

  EXStartLength, EXEndLength, EXEndLLength, EXEndSLength, EXEnd2Length, ExDataPathLength, ExFilePathLength,
    ExRangeLength, ExFilterLength, ExLoopVarLength: integer;

  pEXStart, pEXEnd, pEXEndL, pEXEnd2, pEXEndS, pEXPrefix, pExDataPath, pExFilePath, pExRange, pExFilter,
    pExLoopVar: PChar;

implementation

uses strutils, qstring, Character;

{ TMDataOrigin_ }

function TMDataOrigin_.create(const p: PChar): TMDataOrigin;
begin
  if PStrSame(p, 'json', true) = 4 then
  begin
    self := TMDataOrigin.mdoJson;
  end else if PStrSame(p, 'mudb', true) = 4 then
  begin
    self := TMDataOrigin.mdoMuDB;
  end else if PStrSame(p, 'database', true) = 8 then
  begin
    self := TMDataOrigin.mdoMuDB;
  end else if PStrSame(p, 'db', true) = 2 then
  begin
    self := TMDataOrigin.mdoMuDB;
  end else if PStrSame(p, 'http', true) = 4 then
  begin
    self := TMDataOrigin.mdoHttp;
  end else if (PStrSame(p, 'mfp', true) = 3) or (PStrSame(p, 'mpkg', true) = 4) then
  begin
    self := TMDataOrigin.mdoMfp;
  end else if (PStrSame(p, 'dirlookup', true) = 9) or (PStrSame(p, 'filelist', true) = 8) then
  begin
    self := TMDataOrigin.mdoFileList;
  end else if PStrSame(p, 'file', true) = 4 then // file要放在filelist的后面
  begin
    self := TMDataOrigin.mdoFile;
  end else if PStrSame(p, 'plugin', true) = 6 then
  begin
    self := TMDataOrigin.mdoPlugin;
  end else if PStrSame(p, 'qplugin', true) = 7 then
  begin
    self := TMDataOrigin.mdoQPlugin;
  end else begin
    if IsRegisted(p) then
      self := TMDataOrigin.mdoCustom
    else
      self := TMDataOrigin.mdoUnknow;
  end;
  result := self;
end;

class destructor TMDataOrigin_.Destroy;
begin
  FOriginProc.Free;
end;

class function TMDataOrigin_.ExecCustom(const aDataProp: TMDataProp; aResult: Pointer): integer;
var
  afunc: TMDataOriginExec;
begin
  if FOriginProc.ContainsKey(aDataProp.OriginName) then
    result := FOriginProc[aDataProp.OriginName](aDataProp, aResult)
  else
    result := -1;
end;

class function TMDataOrigin_.IsRegisted(const aName: string): boolean;
begin
  result := FOriginProc.ContainsKey(aName);
end;

class function TMDataOrigin_.RegCustomExec(const aName: String; afunc: TMDataOriginExec): integer;
begin
  if FOriginProc.ContainsKey(aName) then
    FOriginProc[aName] := afunc
  else
    FOriginProc.Add(aName, afunc);
end;

function TMDataOrigin_.create(const s: String): TMDataOrigin;
begin
  self   := create(PChar(s));
  result := self;
end;

class constructor TMDataOrigin_.create;
begin
  FOriginProc := TDictionary<string, TMDataOriginExec>.create;
end;

{ TMDataType_ }
function TMNodeType_.create(aName: String): TMNodeType;
begin
  self.create(PChar(aName));
  result := self;
end;

function TMDataType_.create(p: PChar): TMDataType;
begin
  if PStrSame(p, 'json', true) = 4 then
  begin
    self := TMDataType.mdtJson;
  end else if PStrSame(p, 'dataset', true) = 7 then
  begin
    self := TMDataType.mdtDataset;
  end
  else
    self := TMDataType.mdtUnknow;
  result := self;
end;

function TMDataType_.create(s: String): TMDataType;
begin
  self   := create(PChar(s));
  result := self;
end;

{ TMNode }

function TMNode.Add: TMNode;
begin
  result := Add(mtUnknow);
end;

function TMNode.Add(aNodeType: TMNodeType = mtUnknow): TMNode;
var
  node: TMNode;
begin
  if not assigned(FItems) then
    FItems := TMNodes.create;

  node          := TMNode.create;
  node.NodeType := aNodeType;
  node.Deep     := self.Deep + 1;
  node.Parent   := self;
  node.Root     := self.Root;

  FItems.Add(node);
  node.NodeIndex := FItems.Count - 1;
  result         := node;
end;

function TMNode.Add(aNodeValue: TMNodeValue): TMNode;
begin
  result           := self.Add(mtUnknow);
  result.NodeValue := aNodeValue;
end;

procedure TMNode.Clear;
var
  i: integer;
begin
  if FItems <> nil then
  begin

    for i := FItems.Count - 1 downto 0 do
    begin
      FreeObject(FItems[i]);
      // FItems[i].clear;
    end;

    FItems.Clear;
  end;
end;

constructor TMNode.create(aParent: TMNode = nil);
begin
  FNodeType            := mtUnknow;
  FDeep                := 0;
  FIsRoot              := false;
  self.NodeStart       := 1;
  self.NodeParentStart := 1;
  self.NodeLength      := 0;
  self.ContentStart    := 1;
  self.ContentLength   := 0;
  self.Parent          := aParent;
  self.Filter          := '';

  self.Range := TMRange.create(-1, -1);
  if FParent <> nil then
  begin
    Parent := aParent;
  end
  else
    self.Root := self;

  FParent := nil;
end;

destructor TMNode.Destroy;
var
  i: integer;
begin
  if assigned(FItems) then
  begin
    for i := FItems.Count - 1 downto 0 do
      FreeObject(FItems[i]); // FItems[i].Free;
    FreeObject(FItems);
  end;
  inherited;
end;

function TMNode.GetContentEnd: integer;
begin
  result := FNodeValue.ContentLength;
end;

function TMNode.GetContentStart: integer;
begin
  result := FNodeValue.ContentStart;
end;

function TMNode.GetCount: integer;
begin
  if assigned(FItems) then
    result := self.FItems.Count
  else
    result := 0;
end;

function TMNode.GetCondition: String;
begin
  result := FNodeValue.Condition
end;

function TMNode.GetContent: String;
var
  s: String;
begin
  result := Copy(FRoot.NodeValue.Content, NodeStart + ContentStart - 1, ContentLength);
end;

function TMNode.GetDataPath: String;
begin
  result := FNodeValue.DataPath;
end;

function TMNode.GetDataType: TMDataType;
var
  nd: TMNode;
begin
  result := mdtUnknow;
  if self.HasDataNode(nd) then
    result.create(nd.Properties.GetValue('type'));
end;

function TMNode.GetEndPos: integer;
begin
  result := FNodeValue.NodeLength;
end;

function TMNode.GetFilter: String;
begin
  result := self.FNodeValue.Filter;
end;

function TMNode.GetHead: String;
begin
  result := FNodeValue.Head;
end;

function TMNode.GetItems(const AIndex: integer): TMNode;
begin
  result := self.Items[AIndex];
end;

function TMNode.GetLoopVar: String;
begin
  result := FNodeValue.LoopVar;
end;

function TMNode.GetName: String;
begin
  result := self.FNodeValue.Name;
end;

function TMNode.getNext: TMNode;
begin
  if self.Parent.Count - 1 > self.NodeIndex then
    result := self.Parent[self.NodeIndex + 1]
  else
    result := nil
end;

function TMNode.GetNodeString: String;
begin
  result := Copy(FRoot.NodeValue.Content, FNodeValue.NodeStart, FNodeValue.NodeLength);
end;

function TMNode.getPrevious: TMNode;
begin
  if self.NodeIndex > 0 then
    result := self.Parent[self.NodeIndex - 1]
  else
    result := nil
end;

function TMNode.GetProperties: TMKeyValues;
begin
  result := FNodeValue.Properties;
end;

function TMNode.GetRange: TMRange;
begin
  result := FNodeValue.Range;
end;

function TMNode.GetRangeEnd: integer;
begin
  result := FNodeValue.Range.REnd;
end;

function TMNode.GetRangeIndexs: TMNRangeIndexs;
begin
  result := FNodeValue.Range.Indexs;
end;

function TMNode.GetRangeStart: integer;
begin
  result := FNodeValue.Range.RStart;
end;

function TMNode.HasDataNode(var nd: TMNode): boolean;
var
  i: integer;
begin
  result := false;
  nd     := nil;
  if self.NodeType = mtdata then
    nd := self
  else
    for i := 0 to self.Count - 1 do
      if self[i].NodeType = mtdata then
      begin
        nd := self[i];
        break;
      end;
  result := nd <> nil;

end;

function TMNode.HasDataNodes(var nds: TMNodeArray): boolean;
var
  i, l: integer;
  procedure addNode(nd: TMNode);
  var
    l: integer;
  begin
    l := Length(nds);
    setlength(nds, l + 1);
    nds[l] := nd;
  end;

begin
  result := false;
  setlength(nds, 0);
  if self.NodeType = mtdata then
    addNode(self)
  else
    for i := 0 to self.Count - 1 do
      if self[i].NodeType = mtdata then
      begin
        addNode(self[i]);
      end;
  result := Length(nds ) > 0;

end;

function TMNode.HasLastChild(var nd: TMNode): boolean;
begin
  result := self.Count > 0;
  if result then
    nd := FItems[self.Count - 1];
end;

function TMNode.GetNodeParentStart: integer;
begin
  result := FNodeValue.NodeParentStart;
end;

function TMNode.GetNodeStart(): integer;
begin
  result := FNodeValue.NodeStart;
end;

function TMNode.Parse(aData: TQjson): String;
begin

end;

procedure TMNode.SetCondition(const value: String);
begin
  FNodeValue.Condition := value;
end;

procedure TMNode.SetContent(aValue: String);
begin
  FNodeValue.Content := aValue;
end;

procedure TMNode.SetContentEnd(APos: integer);
begin
  FNodeValue.ContentLength := APos;
end;

procedure TMNode.SetContentStart(APos: integer);
begin
  FNodeValue.ContentStart := APos;
end;

procedure TMNode.SetDataPath(aValue: String);
begin
  FNodeValue.DataPath := aValue;
end;

procedure TMNode.SetEndPos(APos: integer);
begin
  FNodeValue.NodeLength := APos;
end;

procedure TMNode.SetFilter(aValue: String);
begin
  FNodeValue.Filter := aValue;
end;

procedure TMNode.SetHead(aValue: String);
begin
  FNodeValue.Head := aValue;
end;

procedure TMNode.SetLoopVar(const value: String);
begin
  FNodeValue.LoopVar := value;
end;

procedure TMNode.SetNodeString(aValue: String);
begin
  FNodeValue.NodeString := aValue;
end;

procedure TMNode.SetParent(aValue: TMNode);
begin
  if aValue <> nil then
  begin
    self.FParent   := aValue;
    self.Root      := FParent.Root;
    self.Deep      := FParent.Deep + 1;
    self.NodeIndex := FParent.Items.Count - 1;
    self.FIndex    := FParent.Count - 1;
    self.Root      := FParent.Root;
  end;
end;

procedure TMNode.SetProperties(const value: TMKeyValues);
begin
  self.FNodeValue.Properties := value;
end;

procedure TMNode.SetRange(aValue: TMRange);
begin
  self.FNodeValue.Range := aValue;
end;

procedure TMNode.SetRangeEnd(const value: integer);
begin
  FNodeValue.Range.REnd := value;
end;

procedure TMNode.SetRangeIndexs(const value: TMNRangeIndexs);
begin
  FNodeValue.Range.Indexs := value;
end;

procedure TMNode.SetRangeStart(const value: integer);
begin
  FNodeValue.Range.RStart := value;
end;

procedure TMNode.SetName(const value: String);
begin
  self.FNodeValue.Name := value;
end;

procedure TMNode.SetNodeParentStart(APos: integer);
begin
  FNodeValue.NodeParentStart := APos;
end;

procedure TMNode.SetNodeStart(APos: integer);
begin
  FNodeValue.NodeStart := APos;
end;

procedure TMNode.FromJson(json: TQjson);
begin
  json.FromRtti(self);
  // self.NodeValue
end;

procedure TMNode.ToJson(json: TQjson);
var
  js: TQjson;
  i : integer;

begin
  json.FromRtti(self);
  json.Add('Range').FromRecord<TMRange>(self.Range);
  // json.FromRecord<TMNodeValue>(self.NodeValue);

  json.ForcePath('Deep').AsInteger   := self.Deep;
  json.ForcePath('IsRoot').AsBoolean := self.IsRoot;
  json.ForcePath('Properties').FromRecord<TMKeyValues>(self.Properties);

  js := json.Add('Items', jdtarray);
  if assigned(self.Items) then
    for i := 0 to self.Items.Count - 1 do
    begin
      Items[i].ToJson(js.Add);
    end;

end;

function TMNode.ToJsonString: String;
var
  js: TQjson;
begin
  js := TQjson.create;
  try
    ToJson(js);
    result := js.AsString;
  finally
    js.Free;
  end;
end;

{ TMPage }

constructor TMPage.create;
begin

end;

destructor TMPage.Destroy;
begin

  inherited;
end;

procedure initheaders();
var
  fn: String;
  js: TQjson;
begin
  fn := getexepath + 'config/TmpHeader.json';
  if fileexists(fn) then
  begin
    js := TQjson.create;

    try
      js.LoadFromFile(fn);
      EXStart  := js.ValueByName('EXStart', EXStart);
      EXEnd    := js.ValueByName('EXEnd', EXEnd);
      EXEndL   := js.ValueByName('EXEndL', EXEndL);
      EXEnd2   := js.ValueByName('EXEnd2', EXEnd2);
      EXEndS   := js.ValueByName('EXEndS', EXEndS);
      EXPrefix := js.ValueByName('EXPrefix', EXPrefix);

      ExEach    := TMNodeMark.create(js.ValueByName('EXEach', 'each'));
      EXIf      := TMNodeMark.create(js.ValueByName('EXIf', 'if'));
      EXElse    := TMNodeMark.create(js.ValueByName('EXElse', 'else'));
      EXElseIf  := TMNodeMark.create(js.ValueByName('EXElseIf', 'elseif'));
      ExFor     := TMNodeMark.create(js.ValueByName('ExFor', 'for'));
      EXInclude := TMNodeMark.create(js.ValueByName('EXInclude', 'include'));
      EXData    := TMNodeMark.create(js.ValueByName('EXData', 'data'));

      ExDataPath := js.ValueByName('ExDataPath', ExDataPath);
      ExFilePath := js.ValueByName('ExFilePath', ExFilePath);
      ExRange    := js.ValueByName('ExRange', ExRange);
      ExFilter   := js.ValueByName('ExFilter', ExFilter);
      ExLoopVar  := js.ValueByName('ExLoopVar', ExLoopVar);

    finally
      js.Free;
    end;
  end else begin
    ExEach    := TMNodeMark.create('each');
    EXIf      := TMNodeMark.create('if');
    EXElse    := TMNodeMark.create('else');
    EXElseIf  := TMNodeMark.create('elseif');
    ExFor     := TMNodeMark.create('for');
    EXInclude := TMNodeMark.create('include');
    EXData    := TMNodeMark.create('data');
  end;
  ExExp := TMNodeMark.create('');

  EXStartLength := Length(EXStart);

  EXEndLength  := Length(EXEnd);
  EXEndLLength := Length(EXEndL);
  EXEnd2Length := Length(EXEnd2);
  EXEndSLength := Length(EXEndS);

  pEXStart := PChar(EXStart);
  pEXEnd   := PChar(EXEnd);
  pEXEndL  := PChar(EXEndL);
  pEXEnd2  := PChar(EXEnd2);
  pEXEndS  := PChar(EXEndS);

  pExRange  := PChar(ExRange);
  pExFilter := PChar(ExFilter);

  pExDataPath := PChar(ExDataPath);
  pExFilePath := PChar(ExFilePath);

  pExRange   := PChar(ExRange);
  pExFilter  := PChar(ExFilter);
  pExLoopVar := PChar(ExLoopVar);

  ExDataPathLength := Length(ExDataPath);
  ExFilePathLength := Length(ExFilePath);
  ExRangeLength    := Length(ExRange);
  ExFilterLength   := Length(ExFilter);
  ExLoopVarLength  := Length(ExLoopVar);

  fn := getexepath + 'config/TmpConfig.json';
  if fileexists(fn) then
  begin
    js := TQjson.create;

    try
      js.LoadFromFile(fn);
      js.ToRecord<TMtpConfig>(pubMtpConfig);

    finally
      js.Free;
    end;
  end;

end;

{ TMRange }

class function TMRange.create(aStart, aEnd: integer): TMRange;
begin
  result.RStart := aStart;
  result.REnd   := aEnd;
end;

function TMRange.Parse(rangestr: String): boolean;
var
  i, l   : integer;
  str, es: string;
  p      : PChar;
  procedure addone(const idx: integer);
  begin
    l := Length(self.Indexs);
    setlength(self.Indexs, l + 1);
    self.Indexs[l] := idx;
  end;

begin
  // 1..10 3,4,5,6
  i := pos('..', rangestr);
  if i > 0 then
  begin
    str := trim(leftstr(rangestr, i - 1));
    es  := trim(rangestr.Substring(i + 1));
    if IsDigitStr(str) then
    begin
      self.RStart := strtoint(str);
    end;
    if IsDigitStr(es) then
    begin
      self.REnd := strtoint(es);
    end;
    if self.RStart + self.RStart = -2 then
      raise Exception.create(format('%s 不是有效的区间', [rangestr]));
  end else begin
    p := PChar(rangestr);
    while p^ <> #0 do
    begin
      str := DecodeTokenW(p, ',"''', QCharW(#0), true, false);

      str := trim(str);
      if (Length(str) > 0) and IsDigitStr(str) then
      begin
        addone(strtoint(str));
      end;
      inc(p);
    end;
  end;
end;

{ TMNRangeIndexs_ }

function TMNRangeIndexs_.Exists(i: integer): boolean;
var
  idx: integer;
begin
  result  := false;
  for idx := Low(self) to High(self) do
  begin
    if self[idx] = i then
      exit(true);
  end;
end;

{ TMKeyValues_help }

procedure TMKeyValues_help.Add(aKey, aValue: String);
var
  l: integer;
begin
  l := Length(self);
  setlength(self, l + 1);
  self[l].key   := aKey;
  self[l].value := aValue;
end;

function TMKeyValues_help.GetValue(const aKey: String; var aValue: String): boolean;
var
  i: integer;
begin
  result := false;
  for i  := Low(self) to High(self) do
  begin
    if self[i].key = aKey then
    begin
      aValue := self[i].value;
      exit(true);
    end;
  end;
end;

function TMKeyValues_help.GetValue(const aKey: String): String;
var
  i: integer;
begin
  result := '';
  for i  := Low(self) to High(self) do
  begin
    if self[i].key = aKey then
    begin
      exit(self[i].value);
    end;
  end;
end;

function TMKeyValues_help.HasKey(aKey: String): boolean;
var
  i: integer;
begin
  result := false;
  for i  := Low(self) to High(self) do
  begin
    if self[i].key = aKey then
    begin
      exit(true);
    end;
  end;
end;

function TMKeyValues_help.IndexOf(const aKey: String): integer;
var
  i: integer;
begin
  result := -1;
  for i  := Low(self) to High(self) do
  begin
    if self[i].key = aKey then
    begin
      exit(i);
    end;
  end;
end;

function TMKeyValues_help.Parse(s: String): TMKeyValues;
var
  p, p1, p2: PChar;
  k, v     : String;
  i, idx   : integer;
  qt       : Char;
  isqt     : boolean;
begin
  p := PChar(s);
  SkipSpaceW(p);
  p1   := p;
  i    := 1;
  isqt := true;
  while p^ <> #0 do
  begin
    if Character.IsLetterOrDigit(p^) then
    begin
      inc(p);
      continue;
    end;

    if p^ = '=' then
    begin
      k := Copy(p1, 1, p - p1);
      inc(p);
      qt := p^;
      if qt in ['''', '"'] then
      begin
        inc(p);
        p2 := p;
        while p2 <> #0 do
        begin
          SkipUntilW(p2, [qt, #0]);
          if p2^ = qt then
          begin
            dec(p2); // 退回去看看
            if p2 = '\' then
            begin
              inc(p2, 2);
            end else begin
              inc(p2, 2);
              break;
            end;
          end
          else
            inc(p2);
        end;

        v := Copy(p, 1, p2 - p - 1); // 要把最后的硬腭引号去掉
        self.Add(k, v);
        k := '';
        SkipSpaceW(p2);
        p  := p2;
        p1 := p;
        inc(p);

      end
      else // 如果没有引号，属性还是要支持的
      begin
        p1 := p;
        SkipUntilW(p, [' ', #10, #13, #9, #0]); // 遇到空格就算是一个了
        v := Copy(p1, 1, p - p1);               // 要把最后的硬腭引号去掉
        self.Add(k, v);
        k := '';
        SkipSpaceW(p);
        p1 := p;
        inc(p);
      end;
    end else if IsSpaceW(p) then // 没有值，只有属性
    begin
      self.Add(Copy(p1, 1, p - p1), '');
      k := '';
      SkipSpaceW(p);
      p1 := p;
      inc(p);
    end
    else // 其他符号的，直接跳过，就不处理了，当成属性的一部分
      inc(p);
  end;

  result := self;
end;

procedure TMKeyValues_help.setValue(const aKey, aValue: String);
var
  idx: integer;
begin
  idx := IndexOf(aKey);
  if idx <> -1 then
  begin
    self[idx].value := aValue;
  end
  else
    self.Add(aKey, aValue);
end;

{ TMNodeMark }

function TMNodeMark.CompEnd(p: PChar): boolean;
begin
  result := PStrSame(p, self.PEnd, true) = self.EndLength;
end;

function TMNodeMark.CompStart(p: PChar; ANotLetterFollow: boolean): boolean;
begin
  result := PStrSame(p, self.PStart, true, ANotLetterFollow) = self.Length;
end;

class function TMNodeMark.create(aName: String): TMNodeMark;
begin
  result.Name      := aName;
  result.Start     := EXStart + aName;
  result.End_      := EXEndS + aName + EXEnd;
  result.PStart    := PChar(result.Start);
  result.PEnd      := PChar(result.End_);
  result.Length    := System.Length(result.Start);
  result.EndLength := System.Length(result.End_);
end;

class function TMNodeMark.GetEndLength(aName: String): integer;
begin
  result := System.Length(EXEndS + aName + EXEnd);
end;

class function TMNodeMark.GetStartLength(aName: String): integer;
begin
  result := System.Length(EXStart + aName);
end;

{ TMNodeType_ }

function TMNodeType_.create(p: PChar): TMNodeType;
var
  i : integer;
  p2: PChar;
begin
  self := mtUnknow;
  if PStrSame(p, ExExp.PStart, true, false) = ExExp.Length then
  begin
    p2 := p;
    inc(p2, ExExp.Length);
    if not((p2^ in ['0', '9']) or (p2^ in ['a' .. 'z']) or (p2^ in ['A' .. 'Z']) or (p2^ in ['_', '-'])) then
    begin
      self := mtExp;
      exit();
    end;
  end;

  if PStrSame(p, ExEach.PStart, true, true) = ExEach.Length then
  begin
    self := mtEach;
  end else if PStrSame(p, ExFor.PStart, true, true) = ExFor.Length then
  begin
    self := mtFor;
  end else if PStrSame(p, EXIf.PStart, true, true) = EXIf.Length then
  begin
    self := mtIf;
  end else if PStrSame(p, EXElseIf.PStart, true, true) = EXElseIf.Length then
  begin
    self := mtElseIf;
  end else if PStrSame(p, EXElse.PStart, true, true) = EXElse.Length then
  begin
    self := mtElse;
  end else if PStrSame(p, EXData.PStart, true, true) = EXData.Length then
  begin
    self := mtdata;
  end else if PStrSame(p, EXInclude.PStart, true, true) = EXInclude.Length then
  begin
    self := mtInclude;
  end else begin
    for i := 0 to pubCusNodeHandles.Count - 1 do
    begin
      // 暂时不支持嵌套，就是加入了自定义处理。
      if PStrSame(p, pubCusNodeHandles[i].pNodeStart, true) = Length(pubCusNodeHandles[i].NodeStart) then
      begin
        self := mtCustom;
        // getSigleNode(aNode, mtCustom, pubCusNodeHandles[i].NodeStart, pubCusNodeHandles[i].NodeEnd);
        // inc(c);
      end;
    end;
    for i := 0 to pubPluginsHandles.Count - 1 do
    begin
      // 暂时不支持嵌套，就是加入了自定义处理。
      if PStrSame(p, pubPluginsHandles[i].pNodeStart, true) = Length(pubPluginsHandles[i].NodeStart) then
      begin
        self := mtPlugin;

      end;
    end;
  end;
  result := self;
end;
{ TMDataBase }
{ TCusNodeHandles_ }

function TCusNodeHandles_.RegNodeHandler(aNodeName: String; aParseNode: TCusParseNodeP): integer;
var
  ch: TCusNodeHandle;
begin
  ch.Name      := aNodeName;
  ch.NodeStart := aNodeName;
  // if copy(ch.NodeStart, 1, EXStartLength) <> EXStart then
  begin
    ch.NodeStart := EXStart + ch.NodeStart;
  end;

  ch.NodeEnd := aNodeName;

  // if copy(ch.NodeEnd, 1, EXEndSLength) <> EXEndS then
  begin
    ch.NodeEnd := EXEndS + ch.NodeEnd + EXEnd;
  end;

  ch.pNodeStart := PChar(ch.NodeStart);
  ch.pNodeEnd   := PChar(ch.NodeEnd);
  // ch.GetNode := aGetNode;
  ch.ParseNode := aParseNode;
  self.Add(ch);

end;

{ TMInterface }

function TMInterface.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    result := 0
  else
    result := E_NOINTERFACE;
end;

function TMInterface._AddRef: integer;
begin
  // Result:=inherited;
end;

function TMInterface._Release: integer;
begin
  // Result:=inherited;
end;

{ TMDataProp_ }

function TMDataProp_.create(aNode: TMNode): TMDataProp;
begin
  self.create(aNode.Properties);
  self.Content := aNode.Content;
  result       := self;
end;

function TMDataProp_.create(kv: TMKeyValues): TMDataProp;
var
  tm: String;
begin
  self.Origin.create(kv.value['origin']);
  self.DataType.create(kv.value['type']);
  self.Path     := (kv.value['path']);
  tm            := kv.value['timeout'];
  self.DataPath := kv.value['datapath'];
  if tm = '' then
    tm            := '-1';
  self.Timeout    := strtointdef(tm, -1);
  self.OriginName := kv.value['origin'];
  self.Properties := kv;
  result          := self;
end;

{ TMtpConfig }

class function TMtpConfig.create: TMtpConfig;
begin
  result.PoolFile := true;
end;

initialization

pubMtpConfig := TMtpConfig.create;

initheaders();

finalization

end.
