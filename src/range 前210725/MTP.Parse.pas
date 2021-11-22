unit MTP.Parse;

{$M+}

interface

uses sysutils, System.Classes, Generics.Collections, mu.pool.st,
  Data.DB, // qxml,
  qstring, qjson, MTP.Utils, MTP.Types, MTP.Expression;

{ <%each datapath=''%>
  <%if(@Data.ID=="1")%>
  <div><ul><%@Score[0]%></ul></div>
  <%else%>
  <%endif%>
  <%endeach%>
}
type

  TMTextParse = class
    private

    protected
      FMNode: TMNode;
      class function ParseNode2(aNode: TMNode; aData: Pointer; aRootData: Pointer; aDataParser: IMDataParser;
        aPath: String = ''; aParams: TQJson = nil; aLoopVar: String = ''; aLoopValue: String = ''): String;

    public
      constructor Create();
      destructor Destroy; override;

      class function ParseNode(aNode: TMNode; aData: Pointer; aDataParser: IMDataParser; aPath: String = '';
        aParams: TQJson = nil; aLoopVar: String = ''; aLoopValue: String = ''): String;

      class function GetAllNode(aText: String; node: TMNode; aAllowNotRegMark: Boolean = true;
        addNodeText: Boolean = false): Integer;

  end;

implementation

uses math, strutils, Character, MTP.Files;

constructor TMTextParse.Create;
begin
  FMNode := TMNode.Create;
end;

destructor TMTextParse.Destroy;
begin
  FMNode.Free;
  inherited;
end;

function XMLDecode(const p: PQCharW; l: Integer): QStringW;
var
  ps, ws, pd: PQCharW;
  c         : QCharW;
const
  EscapeEnd: PQCharW = ';<>';
begin
  SetLength(Result, l);
  ps := p;
  pd := PQCharW(Result);
  while ps - p < l do
  begin
    if ps^ = '&' then
    begin
      ws := ps;
      SkipUntilW(ps, EscapeEnd);
      if ps^ = ';' then
      begin
        Inc(ps);
        c := PQCharW(HtmlUnescape(StrDupX(ws, ps - ws)))^;
        if c <> #0 then
          pd^ := c
        else
          raise Exception.Create(Format('未知的XML转义字符串[%s]。', [StrDupX(ws, ps - ws)]));
        Inc(pd);
      end
      else // 兼容处理
      begin
        pd^ := ws^;
        ps  := ws;
        Inc(pd);
        Inc(ps);
        // raise Exception.Create(SBadXMLEscape);
      end;
    end else begin
      pd^ := ps^;
      Inc(ps);
      Inc(pd);
    end;
  end;
  SetLength(Result, pd - PQCharW(Result));
end;

class function TMTextParse.GetAllNode(aText: String; node: TMNode; aAllowNotRegMark, addNodeText: Boolean): Integer;
var
  pstr, p: Pchar;
  CsCount: Integer;
  // nnode: TMNode;
  LastContentStart: Integer;

  // 从头行找到属性，返回是否单行
  function getheader(n: TMNode): Boolean;
  var
    ws, ps      : Pchar;
    AttrName, vl: String;
  const
    TagStart: PQCharW     = '<';
    TagClose: PQCharW     = '>';
    Question: PQCharW     = '?';
    TagNameEnd: PQCharW   = #9#10#13#32'/>';
    AttrNameEnd: PQCharW  = #9#10#13#32'=/>';
    AttrValueEnd: PQCharW = #9#10#13#32'/>';
  begin
    Result := false;
    ps     := p;
    if (p^ <> '>') and (p^ <> '/') then
    begin
      // 解析属性
      while p^ <> #0 do
      begin
        SkipSpaceW(p);
        ws := p;
        SkipUntilW(p, AttrNameEnd);
        AttrName := StrDupX(ws, p - ws);
        SkipSpaceW(p);
        if p^ = '=' then
        begin
          Inc(p);
          SkipSpaceW(p);
          if (p^ = '''') or (p^ = '"') then
          begin
            ws := p;
            Inc(p);
            while p^ <> #0 do
            begin
              if p^ = ws^ then
              begin
                Inc(p);
                Break;
              end
              else
                Inc(p);
            end;
            n.NodeValue.Properties.Add(AttrName, XMLDecode(ws + 1, p - ws - 2));
          end
          else // 如果没有引号的
          begin
            vl := DecodeTokenW(p, AttrValueEnd, QCharW(#0), false, false);
            n.NodeValue.Properties.Add(AttrName, (vl));
          end;
          // raise Exception.Create('无效的XML属性值，属性值必需使用引号包裹1。');
        end else if (p^ = '/') or (p^ = '>') then
          Break
        else
          raise Exception.Create('无效的XML属性值，属性值必需使用引号包裹2。');
      end;
    end;
    Result := false;
    n.head := copy(ps, 1, p - ps);
    if p^ = '>' then
      Inc(p)
    else if (p[0] = '/') and (p[1] = '>') then // 直接结束，没有附加内容的结点
    begin
      Result := true;
      Inc(p, 2);
    end
  end;

  function addone(aNode: TMNode): TMNode;
  var
    l, idx, i2, ii    : Integer;
    n                 : TMNode;
    arange            : TMRange;
    filterstr, LoopVar: String;
    nodeName, head1   : String;
    rg                : TMRange;
    online            : Boolean;
    p2                : Pchar;
    aNodeType         : TMNodeType;
    kv                : TMKeyValues;
  const
    dsPWideChar: PWideChar  = ' />''"';
    dsPWideChar2: PWideChar = '>';
  begin
    Result := aNode;

    aNodeType.Create(p);

    if (aNodeType = mtExp) and (not aAllowNotRegMark) then
    begin
      Inc(p);
      exit;
    end;

    l      := p - pstr + 1;
    online := false;
    p2     := p;
    Inc(p, Length(EXStart));
    nodeName := DecodeTokenW(p, dsPWideChar, QCharW(#0), false, false);

    // 这种是表达式
    if nodeName = '' then
    begin
      aNodeType := mtExp;
    end;
    n := aNode.Add(aNodeType);
    // n.DataPath :=  getEachPath(p, i - 1, @rg, filterstr, LoopVar);
    // n.Filter := filterstr;
    n.LoopVar := LoopVar;
    n.Name    := nodeName;

    online := getheader(n);
    // n.head := head1;
    // n.NodeValue.Properties := kv;
    { idx := PosW(pEXEnd, p, false);
      ii := PosW(pEXEndL, p, false);

      // endMark := copy(EXEnd2, 1, length(EXEnd2) - length(EXEnd)) + nodeName + EXEnd;

      if (idx = 0) and (ii = 0) then
      raise Exception.Create(Format(' %s 没有结束符%s', [nodeName, EXEnd]));

      if (ii <= idx) and (ii > 0) then
      begin
      online := true;
      i := ii;
      end
      else
      i := idx;
    }

    // n.head := trim(copy(p, 1, i - 1));

    n.NodeStart := l;
    if n.Parent <> nil then
    begin
      n.NodeParentStart := l - (n.Parent.NodeStart + n.Parent.ContentStart - 1) + 1; // 字符索引都是从1开始的
      // n.NodeParentStart := l - (n.Parent.NodeStart - 1); // 字符索引都是从1开始的
    end
    else
      n.NodeParentStart := l;
    // n.NodeParentStart := l - LastContentStart + 1;
    l := EXEndLength;
    Inc(p, l - 1);
    n.ContentStart := p - pstr + 1 - n.NodeStart + 1; // p - pstr - n.NodeStart + 1;
    // n.NodeValue.Properties.Parse(n.head);
    n.DataPath := n.Properties.GetValue(ExDataPath);
    case n.NodeType of
      mtFor, mteach:
        begin
          n.NodeValue.Range.Parse(n.Properties.GetValue(ExRange));
          n.LoopVar := n.Properties.GetValue(ExLoopVar);
          if n.LoopVar = '' then
            n.LoopVar := '@I';
          n.Filter    := n.Properties.GetValue(ExFilter);
        end;
      mtIf, mtElseIf:
        begin
          n.Condition := n.Properties.GetValue(ExCondition);
          if (n.Condition = '') then
            n.Condition := n.head;
        end;
      mtInclude:
        ;
    end;

    if online then
    begin
      n.NodeLength := p - p2;
    end else begin
      Result := n;
    end;
  end;
  function endone(aNode: TMNode): TMNode;
  var
    l, i: Integer;
    n   : TMNode;
  begin
    Result := aNode;
    if not aAllowNotRegMark then
    begin
      if ExExp.CompEnd(p) then
      begin
        Inc(p);
        exit;
      end;
    end;
    // if aNode.NodeType = aNodeType then
    begin

      l := p - pstr; // 当前位置
      // aNode.ContentLength
      aNode.ContentLength := l - aNode.NodeStart - aNode.ContentStart + 2;
      // 有效内容
      if addNodeText then
        aNode.Content := copy(pstr, aNode.NodeStart + aNode.ContentStart - 1, aNode.ContentLength);
      Inc(p, TMNodeMark.GetEndLength(aNode.Name));
      aNode.NodeLength := p - pstr - aNode.NodeStart + 1;
      if addNodeText then
        aNode.NodeString := copy(pstr, aNode.NodeStart, aNode.NodeLength);
      exit(aNode.Parent);

    end
    { else
      begin
      //      raise Exception.Create(format('line %d ' + aNode.Name + 'end  没有匹配的' + aNode.Name + ' start', [l]));
      end; }
  end;

begin
  pstr := Pchar(aText);
  p    := pstr;
  if node.Parent = nil then
  begin
    node.NodeType      := mtRoot;
    node.isroot        := true;
    node.ContentStart  := 1;
    node.ContentLength := Length(aText);
    node.Content       := aText;
    node.NodeLength    := Length(aText);
  end;
  LastContentStart := 1;
  while p^ <> #0 do
  begin
    if PStrSame(p, pEXStart, true) = EXStartLength then
    begin
      node := addone(node);
    end else if PStrSame(p, pEXEndS, true) = EXEndSLength then
    begin
      node := endone(node);
    end
    else
      Inc(p);
  end;
  Result := node.count;
end;

class function TMTextParse.ParseNode(aNode: TMNode; aData: Pointer; aDataParser: IMDataParser; aPath: String;
  aParams: TQJson; aLoopVar, aLoopValue: String): String;

begin

  Result := TMTextParse.ParseNode2(aNode, aData, aData, aDataParser, aPath, aParams, aLoopVar, aLoopValue);

end;

class function TMTextParse.ParseNode2(aNode: TMNode; aData, aRootData: Pointer; aDataParser: IMDataParser;
  aPath: String; aParams: TQJson; aLoopVar, aLoopValue: String): String;
var
  dcnt: Integer;

  function replaceVarValue(aText: String; aLoopVar: String; aLoopValue: String): String;
  var
    p1, p, p2, ploopvar: Pchar;
    pos, loopvarlength : Integer;
  begin
    ploopvar      := Pchar(aLoopVar);
    loopvarlength := Length(aLoopVar);
    if Length(aLoopVar) = 0 then
      exit(aText);
    p      := Pchar(aText);
    p1     := p;
    Result := '';
    pos    := 1;
    while (p^ <> #0) do
    begin
      if (PStrSame(p, ploopvar, true) = loopvarlength) then
      begin
        // 如果是loop变量，就替换成loop的value，此时，loopvar后面紧跟的必须不是字母和数字。
        p2 := p;
        Inc(p2, loopvarlength);
        if IsLetterOrDigit(p2^) then
        begin
          Inc(p);
        end else begin
          Result := Result + copy(p1, pos, p - p1 - pos + 1) + aLoopValue;
          Inc(p, loopvarlength);
          pos := p - p1 + 1;
        end;
      end
      else
        Inc(p);
    end;
    if p^ = #0 then
    begin
      Result := Result + copy(p1, pos, p - p1 - pos + 1);
    end;
  end;

  function parseOneText(aText: String; aData: Pointer; aLoopVar: String = ''; aLoopValue: String = ''): String;
  var
    hstr, exp                  : string;
    i, l, estart, loopvarlength: Integer;
    p, p1, p2                  : Pchar;
    isInStart                  : Boolean;
  begin
    // 暂时不用cat
    exit(aText);

    // 下面不用解析了。
    Result        := '';
    isInStart     := false;
    loopvarlength := Length(aLoopVar);
    if (loopvarlength > 0) then
      aText := replaceVarValue(aText, aLoopVar, aLoopValue);
    // aNode.Value := aNode.Content;
    p := Pchar(aText);

    p1     := p;
    estart := 1;
    while p^ <> #0 do
    begin
      if PStrSame(p, pEXStart, true) = EXStartLength then
      begin
        Result := Result + copy(p1, estart, p - p1 - estart + 1);
        Inc(p, EXStartLength);
        // 如果紧跟的是结束，就是标准的xml了跳过去
        SkipSpaceW(p);
        if (PStrSame(p, pEXEnd, true) = EXEndLength) then
        begin
          Inc(p, EXEndLength);
        end
        else
          isInStart := true;
        SkipSpaceW(p);
        estart := p - p1 + 1;
      end

      else if isInStart and (PStrSame(p, pEXEndL, true) = EXEndLLength) then
      begin
        exp    := copy(p1, estart, p - p1 - estart + 1);
        Result := Result + TMExp.doExpression(exp, true, aData, aDataParser, aParams, aRootData);
        Inc(p, EXEndLLength);
        estart    := p - p1 + 1;
        isInStart := false;
      end else if isInStart and (PStrSame(p, pEXEnd, true) = EXEndLength) then
      begin
        exp    := copy(p1, estart, p - p1 - estart + 1);
        Result := Result + TMExp.doExpression(exp, true, aData, aDataParser, aParams, aRootData);
        Inc(p, EXEndLength);
        estart    := p - p1 + 1;
        isInStart := false;
      end else if (PStrSame(p, pEXEnd2, true) = EXEnd2Length) then
      begin
        exp    := copy(p1, estart, p - p1 - estart + 1);
        Result := Result + TMExp.doExpression(exp, true, aData, aDataParser, aParams, aRootData);
        Inc(p, EXEnd2Length);
        estart    := p - p1 + 1;
        isInStart := false;
      end
      else // else result:=
        Inc(p);
      if p^ = #0 then
      begin
        Result := Result + copy(p1, estart, p - p1 - estart + 1);
      end;
    end;
    // TMExp.doExpression()
  end;

  function parseNodeText(aNode: TMNode; aData: Pointer; aLoopVar: String = ''; aLoopValue: String = ''): string;
  var
    i, l     : Integer;
    nvalue, s: String;
  begin
    nvalue := '';

    if aNode.count > 0 then
    begin
      for i := 0 to aNode.count - 1 do
      begin
        // 吧前面的加上
        if i = 0 then
        begin
          nvalue := nvalue + parseOneText(copy(aNode.Content, 1, aNode[i].NodeParentStart - 1), aData, aLoopVar,
            aLoopValue);
        end else begin
          l      := aNode[i - 1].NodeParentStart + aNode[i - 1].NodeLength;
          nvalue := nvalue + parseOneText(copy(aNode.Content, l, aNode[i].NodeParentStart - l), aData, aLoopVar,
            aLoopValue);
        end;
        // 把数据传给下一级
        nvalue := nvalue + ParseNode2(aNode[i], aData, aRootData, aDataParser, aPath, aParams, aLoopVar, aLoopValue);
      end;
      // 吧后面的加上
      l := aNode[aNode.count - 1].NodeParentStart + aNode[aNode.count - 1].NodeLength;

      s := copy(aNode.Content, l, aNode.ContentLength - l + 1);

      nvalue := nvalue + parseOneText(copy(aNode.Content, l, aNode.ContentLength - l + 1), aData, aLoopVar, aLoopValue);
      // host
    end
    else
      nvalue := parseOneText(aNode.Content, aData, aLoopVar, aLoopValue);
    // aNode.Value := nvalue;
    Result := nvalue;
  end;

  function parseExp(aNode: TMNode; aData: Pointer): String;
  var
    exp : String;
    Data: Pointer;
  begin
    if aNode.DataPath <> '' then
    begin
      // if aData.HasChild(aNode.DataPath, Data) then
      if aDataParser.TryDataByPath(aData, aParams, aNode.DataPath, Data) then
      begin
      end
      else
        raise Exception.Create(Format('没有找到数据路径 %s', [aNode.DataPath]));
    end
    else
      Data := aData;

    exp := aNode.Content;

    if exp = '' then
    begin
      if not aNode.Properties.GetValue('value', exp) then
        exp := aNode.head;
    end;

    if (Length(aLoopVar) > 0) then
    begin
      exp := replaceVarValue(exp, aLoopVar, aLoopValue);
    end;

    Result := TMExp.doExpression(exp, true, Data, aDataParser, aParams, aRootData);
  end;

  function ParseEach(aNode: TMNode; aData: Pointer): String;
  var
    Data               : Pointer;
    ajs                : Pointer;
    i, fstart, fend, dc: Integer;
    rg                 : TMNode;
    r                  : String;
  begin
    // 暂时不用cat
    Data := aData;

    if aNode.DataPath <> '' then
    begin
      if aDataParser.TryDataByPath(aData, aParams, aNode.DataPath, Data) then
      begin
      end
      else
        raise Exception.Create(Format('没有找到数据路径 %s', [aNode.DataPath]));
    end
    else
      Data := aData;

    // aNode.Value := parseOneText(aNode.Value, adata);
    fstart := aNode.Range.RStart;
    if fstart < 0 then
      fstart := 0;
    fend     := aNode.Range.REnd;

    dc := aDataParser.DataCount(Data);

    if (fend = -1) then // or (fend > aDataParser.DataCount(Data) - 1)
      fend := dc - 1;
    if fend > dc - 1 then
      fend := dc - 1;

    for i := fstart to fend do
    begin
      if Length(aNode.Range.Indexs) > 0 then
      begin
        if not aNode.Range.Indexs.Exists(i) then
          Continue;
      end;

      ajs := aDataParser.Items(Data, i);
      if (aNode.Filter <> '') and (aNode.Filter.ToUpper <> 'NONE') then
      begin
        // outputdebugstring(Pchar(ajs.tostring));
        r := replaceVarValue(aNode.Filter, aLoopVar, aLoopValue);
        r := replaceVarValue(r, aNode.LoopVar, i.tostring);

        // outputdebugstring(Pchar(r));
        // outputdebugstring(Pchar(ajs.tostring));

        r := TMExp.doExpression(r, true, ajs, aDataParser, aParams, aRootData);
        if r <> 'True' then
          Continue;
      end;
      Result := Result + parseNodeText(aNode, ajs, aNode.LoopVar, i.tostring);
    end;
  end;

  function ParseFor(aNode: TMNode; aData: Pointer): String;
  var
    Data               : Pointer;
    i, ii, fstart, fend: Integer;
    rg                 : TMNode;
    r                  : String;

    function doNodeLoopVar(aNode: TMNode; idx: Integer): string;
    var
      LoopVar: String;
      exp    : String;
    begin
      LoopVar := aNode.LoopVar;

      Result := '';
      if (aNode.Filter <> '') and (aNode.Filter.ToUpper <> 'NONE') then
      begin
        exp := replaceVarValue(aNode.Filter, aLoopVar, aLoopValue);
        exp := replaceVarValue(exp, LoopVar, idx.tostring);

        r := TMExp.doExpression(exp, true, Data, aDataParser, aParams, aRootData);
        if r <> 'True' then
          exit;
      end;
      Result := parseNodeText(aNode, Data, LoopVar, idx.tostring);
    end;

  begin
    // 暂时不用cat
    if aNode.DataPath <> '' then
    begin
      // if aData.HasChild(aNode.DataPath, Data) then
      if aDataParser.TryDataByPath(aData, aParams, aNode.DataPath, Data) then
      begin
      end
      else
        raise Exception.Create(Format('没有找到数据路径 %s', [aNode.DataPath]));
    end
    else
      Data := aData;
    // aNode.Value := parseOneText(aNode.Value, adata);
    fstart := aNode.Range.RStart;
    fend   := aNode.Range.REnd;

    if Length(aNode.Range.Indexs) > 0 then
    begin
      for i := Low(aNode.Range.Indexs) to High(aNode.Range.Indexs) do
      begin
        Result := Result + doNodeLoopVar(aNode, aNode.Range.Indexs[i]);
      end;
    end
    else
      for i := fstart to fend do
      begin
        Result := Result + doNodeLoopVar(aNode, i);
      end;
  end;

  function ParseIF(aNode: TMNode; aData: Pointer): String;
  var
    r : String;
    nd: TMNode;
  begin
    Result := '';
    r      := replaceVarValue(aNode.Condition, aLoopVar, aLoopValue);
    r      := TMExp.doExpression(r, true, aData, aDataParser, aParams, aRootData);
    if r = 'True' then
    begin
      Result := parseNodeText(aNode, aData, aLoopVar, aLoopValue);
    end else begin
      nd := aNode.Next;
      while (nd <> nil) do
      begin
        if nd.NodeType = mtElseIf then
        begin
          if TMExp.doExpression(replaceVarValue(nd.Condition, aLoopVar, aLoopValue), true, aData, aDataParser, aParams,
            aRootData) = 'True' then
          begin
            Result := parseNodeText(nd, aData, aLoopVar, aLoopValue);
            Break;
          end else begin
            nd := nd.Next;
          end
        end else if nd.NodeType = mtElse then
        begin
          Result := parseNodeText(nd, aData, aLoopVar, aLoopValue);
          Break;
        end
        else
          Break;
      end;
    end;
  end;

  function ParseElse(aNode: TMNode; aData: Pointer): String;
  begin
    Result := parseNodeText(aNode, aData, aLoopVar, aLoopValue);
  end;

  function ParseInclude(aNode: TMNode; aData: Pointer): String;
  var
    p, pstr      : Pchar;
    l, pos, i, ii: Integer;
    fn, fs       : String;
    needparse    : Boolean;
    function getPath(p: Pchar; var needparse: Boolean): String;
    var
      idx: Integer;
      p1 : Pchar;
      s  : String;
    const
      dsPWideChar: PWideChar = ' =>%';
    begin
      Result    := '';
      p1        := p;
      needparse := false;
      while (p^ <> #0) do
      begin
        if PStrSame(p, pExFilePath, true) = ExFilePathLength then
        begin
          Inc(p, ExFilePathLength);
          SkipSpaceW(p);
          if (p^ = '=') then
          begin
            Inc(p);
            SkipSpaceW(p);
            Result := DecodeTokenW(p, dsPWideChar, QCharW(#0), true, false);
            Result := DequotedStrw(Result);
            Result := DequotedStrw(Result, '"');
            Result := DequotedStrw(Result, '''');
            // SkipSpaceW(p);
          end;
        end else if PStrSame(p, 'parse', true) = 5 then
        begin
          Inc(p, 5);
          SkipSpaceW(p);
          if (p^ = '=') then
          begin
            Inc(p);
            SkipSpaceW(p);
            s         := DecodeTokenW(p, dsPWideChar, QCharW(#0), true, false);
            s         := DequotedStrw(s);
            s         := DequotedStrw(s, '"');
            s         := DequotedStrw(s, '''');
            needparse := s.ToUpper() = 'TRUE';
            SkipSpaceW(p);
          end;
        end
        else
          Inc(p);
      end;
    end;

  begin
    Result := '';
    p      := Pchar(aNode.head);
    fn     := getPath(p, needparse);
    l      := ii + i;
    Inc(p, l - 1);
    pos := p - pstr + 1;

    fn := trim(fn);
    fn := TMFileParse.getFilePath(fn, aPath);
    if fileexists(fn) then
      fs   := TMFileParse.ParseFile(fn, aDataParser, aData, aParams, needparse);
    Result := fs;
  end;

  function ParseCustom(aNode: TMNode; aData: Pointer): String;
  var
    i: Integer;
  begin
    Result := '';
    for i  := 0 to pubCusNodeHandles.count - 1 do
    begin
      if pubCusNodeHandles[i].Name = aNode.Name then
      begin
        Result := pubCusNodeHandles[i].ParseNode(aNode, aData, aDataParser);
        Break;
      end;
    end;
  end;
  function ParsePlugin(aNode: TMNode; aData: Pointer): String;
  var
    i: Integer;
  begin
    Result := '';
    for i  := 0 to pubPluginsHandles.count - 1 do
    begin
      if pubPluginsHandles[i].Name = aNode.Name then
      begin
        Result := pubPluginsHandles[i].ParseNode(aNode, aData, aDataParser);
        Break;
      end;
    end;
  end;
  function ParseData(aNode: TMNode; aData: TQJson): String;
  begin
    Result := '';
  end;

begin

  Result := '';
  case aNode.NodeType of
    mtUnknow, mtRoot:
      Result := parseNodeText(aNode, aData);
    mtExp:
      Result := parseExp(aNode, aData);
    mteach:
      Result := ParseEach(aNode, aData);
    mtFor:
      Result := ParseFor(aNode, aData);
    mtIf:
      Result := ParseIF(aNode, aData);
    mtCustom:
      Result := ParseCustom(aNode, aData);
    mtInclude:
      Result := ParseInclude(aNode, aData);
    mtData:
      Result := '';
    mtPlugin:
      Result := ParsePlugin(aNode, aData);

  else
    Result := '';
  end;

end;

initialization

pubCusNodeHandles := TCusNodeHandles.Create;
pubPluginsHandles := TCusNodeHandles.Create;

finalization

pubCusNodeHandles.Free;
pubPluginsHandles.Free;

end.
