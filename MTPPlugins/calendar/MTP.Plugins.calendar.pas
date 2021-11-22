unit MTP.Plugins.calendar;

interface

uses System.SysUtils, MTP.Utils, MTP.Types, MTP.Expression, MTP.Plugin.base, qplugins, qplugins_params, qstring;

type
  TMuMTPNodeParserCalendar = class(TMuMTPNodeParserPlugin)
    private
    protected
      FNodeName     : String;
      FCusParseNodeP: TCusParseNodeP;
    public
      constructor create(const AName: QStringW); override;
      destructor Destroy; override;
      function NodeParser: TCusParseNodeP; override;
  end;

implementation

uses Winapi.windows, System.classes, qjson, dateutils;

function parseOneText(aText: String; adata: Pointer; aDataParser: IMDataParser): String;
var
  hstr, r, exp               : string;
  i, l, estart, loopvarlength: integer;
  p, p1, p2                  : Pchar;
  isInStart                  : boolean;

begin
  // 暂时不用cat
  result    := '';
  isInStart := false;
  // aNode.Value := aNode.Content;
  p := Pchar(aText);

  p1     := p;
  estart := 1;
  while p^ <> #0 do
  begin
    if PStrSame(p, pEXStart, true) = EXStartLength then
    begin
      result := result + copy(p1, estart, p - p1 - estart + 1);
      inc(p, EXStartLength);
      // 如果紧跟的是结束，就是标准的xml了跳过去
      SkipSpaceW(p);
      if (PStrSame(p, pEXEnd, true) = EXEndLength) then
      begin
        inc(p, EXEndLength);
      end
      else
        isInStart := true;
      SkipSpaceW(p);
      estart := p - p1 + 1;
    end

    else if isInStart and (PStrSame(p, pEXEndL, true) = EXEndLLength) then
    begin
      exp    := copy(p1, estart, p - p1 - estart + 1);
      result := result + TMExp.doExpression(exp, false, adata, aDataParser);

      inc(p, EXEndLLength);
      estart    := p - p1 + 1;
      isInStart := false;
    end else if isInStart and (PStrSame(p, pEXEnd, true) = EXEndLength) then
    begin
      exp    := copy(p1, estart, p - p1 - estart + 1);
      r      := TMExp.doExpression(exp, false, adata, aDataParser);
      result := result + r;
      inc(p, EXEndLength);
      estart    := p - p1 + 1;
      isInStart := false;
    end else if (PStrSame(p, pEXEnd2, true) = EXEnd2Length) then
    begin
      exp    := copy(p1, estart, p - p1 - estart + 1);
      r      := TMExp.doExpression(exp, false, adata, aDataParser);
      result := result + r;
      inc(p, EXEnd2Length);
      estart    := p - p1 + 1;
      isInStart := false;
    end
    else // else result:=
      inc(p);
    if p^ = #0 then
    begin
      result := result + copy(p1, estart, p - p1 - estart + 1);
    end;
  end;
  // TMExp.doExpression()
end;

function GetFirstDate(y, m: String): Tdate;
var
  i, iy, im: integer;
begin
  if y = '' then
  begin
    i := pos('-', m);
    if i <= 0 then
      i := pos('/', m);
    if i <= 0 then
    begin
    end else begin
      y := copy(m, 1, i - 1);
      m := copy(m, i + 1, length(m) - i);
    end;

  end;
  iy := strtointdef(y, 2020);
  im := strtointdef(m, 2020);

  result := RecodeYear(result, iy);
  result := RecodeMonth(result, im);
  result := RecodeDay(result, 1);
end;

function hp_calendar(aNode: TMNode; pdata: Pointer; aDataParser: IMDataParser): String;
var
  kv         : TMKeyValues;
  data, adata: TQjson;
  content, r : String;
  yearstr, nonthstr, datefield, datapath, cls, dateformat, monthclass, emptydateclass, dateclass: String;
  i               : integer;
  dt, dttmp, dtend: Tdatetime;

  function oneli(ct: String; dt: TQjson; idate: integer): String;
  begin
    if ct = '' then
      result := idate.ToString
    else
      result := parseOneText(ct, dt, aDataParser);
  end;

  function getdatejson(d: Tdatetime): TQjson;
  var
    ds: String;
    i : integer;
    j : TQjson;
  begin
    ds := formatdatetime(dateformat, d);
    if data.HasChild(ds, result) then
      exit();

    for i := 0 to data.Count - 1 do
    begin
      if data[i].HasChild(datefield, j) then
      begin
        if j.AsDateTime = d then
          exit(data[i]);
      end;
    end;
    result := data;
  end;

begin
  result := '';
  // kv.Parse(aNode.Head);
  kv         := aNode.Properties;
  content    := aNode.content;
  datefield  := kv.GetValue('datefield');
  datapath   := kv.GetValue('datapath');
  nonthstr   := kv.GetValue('month');
  yearstr    := kv.GetValue('yearstr');
  dateformat := kv.GetValue('dateformat');
  cls        := kv.GetValue('class');
  monthclass := kv.GetValue('monthclass');

  if dateformat = '' then
    dateformat   := 'yyyy-MM-dd';
  emptydateclass := kv.GetValue('emptydateclass');
  dateclass      := kv.GetValue('dateclass');

  // dateformat="yyyy-MM-dd" class="mm" monthclass="mn" emptydateclass="nn" dateclass=""
  adata := TQjson(pdata);

  if not adata.HasChild(datapath, data) then
    data := adata;

  dt     := GetFirstDate(yearstr, nonthstr);
  result := format('<div class="%s">%d<br />%d</div>', [monthclass, YearOf(dt), Monthof(dt)]);
  dtend  := dt + DaysInMonth(dt);
  r      := '';
  if DayOfTheWeek(dt) > 1 then
  begin
    r     := r + '<ul>';
    for i := DayOfTheWeek(dt) - 1 downto 1 do
    begin
      dttmp := dt - i;
      // r := r + format('<li class="%s">%s</li>', [emptydateclass, oneli(content, getdatejson(dttmp),
      // DayOfTheMonth(dttmp))]);
      r := r + format('<li class="%s">%s</li>', [emptydateclass, DayOfTheMonth(dttmp).ToString]);
    end;
  end;
  while dt < dtend do
  begin
    case DayOfTheWeek(dt) of
      1:
        begin
          // if r <> '' then
          // r := r + '</ul>';
          r := r + '<ul>';
        end;
      7:
        ;
    end;
    r := r + format('<li class="%s">%s</li>', [dateclass, oneli(content, getdatejson(dt), DayOfTheMonth(dt))]);

    if DayOfTheWeek(dt) = 7 then
      r := r + '</ul>';

    dt := dt + 1;
  end;
  if DayOfTheWeek(dt) < 7 then
  begin
    r := r + '</ul>';
  end;

  result := format('<div class="%s">%s %s</div>', [cls, result, r]); // aNode.Head;
end;

//
{ TMuMTPNodeParserCalendar }

constructor TMuMTPNodeParserCalendar.create(const AName: QStringW);
begin
  inherited create(AName);
  FCusParseNodeP := function(aNode: TMNode; pdata: Pointer; aDataParser: IMDataParser): PWideChar
    var
      i: integer;
      s: String;
    begin
      for i  := 0 to 1076 do
        s    := s + 'a';
      result :=  (s);
    end;
  // this is in plugins
  // hp_calendar;
end;

destructor TMuMTPNodeParserCalendar.Destroy;
begin

  inherited;
end;

function TMuMTPNodeParserCalendar.NodeParser: TCusParseNodeP;
begin
  result := FCusParseNodeP;
end;

initialization

RegisterServices('/Services/MtpPlugins', [TMuMTPNodeParserCalendar.create('calendar')]);

finalization

// UnregisterServices('/Services/ModulePlugins', ['auth/login']);

end.
