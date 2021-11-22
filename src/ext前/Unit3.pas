unit Unit3;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Generics.Collections,
  System.Classes, Vcl.Graphics, qjson, qstring,
  MTP.Files, QMathExpr,   MTP.Parse.json, Mu.DbHelp, MTP.Parse.Dataset,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ComCtrls, Data.DB, Data.Win.ADODB,
  FireDAC.Comp.Client, FireDAC.Comp.Dataset, FireDAC.Moni.RemoteClient, FireDAC.Phys.MSSQL,
  FireDAC.Stan.StorageJSON, FireDACJSONReflect,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf;

type
  TForm3 = class(TForm)
    BitBtn1: TBitBtn;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Memo1: TMemo;
    TabSheet2: TTabSheet;
    Memo2: TMemo;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    ADODataSet1: TADODataSet;
    BitBtn5: TBitBtn;
    BitBtn6: TBitBtn;
    NetHTTPClient1: TNetHTTPClient;
    Button1: TButton;
    Button2: TButton;
    BitBtn7: TBitBtn;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);
    procedure BitBtn6Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure BitBtn7Click(Sender: TObject);
  private
    Data: TQjson;
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

uses MTP.Parse, MTP.expression, dateutils, MTP.types, Mu.fileinfo;
{$R *.dfm}

function TryGetData(AName: String; var r: string; aJdata: TQjson; aAllowOwn: Boolean): Boolean;
var
  jd: TQjson;
  function jsValue(ajs: TQjson): string;
  begin
    case ajs.DataType of
      jdtarray, jdtobject:
        result := ajs.Encode(false);
      jdtNull:
        result := '';
    else
      result := ajs.AsString;
    end;
  end;

begin
  r := '';
  // outputdebugstring(pchar(aJdata.ToString));
  if (AName = EXPrefix) and (aAllowOwn) then
  begin
    r := jsValue(aJdata);
    result := true;
    exit;
  end;

  if AName[1] = EXPrefix then
  begin
    delete(AName, 1, 1);
    if aJdata.HasChild(AName, jd) then
    begin
      r := jsValue(jd);
      result := true;
    end
  end else if aAllowOwn then
  begin
    r := AName;
    result := true;
  end
  else
    result := false;
end;

procedure TForm3.BitBtn1Click(Sender: TObject);
var
  nd: TMNode;
  i, t: int64;
  path, s: String;
begin
  nd := TMNode.Create;
  nd.IsRoot := true;
  path := getexepath + 'web\';
  try
    t := gettickcount;
    // nd.clear;
    TMTextParse.GetAllNode(Memo1.Lines.Text, nd, true, false);
    for i := 0 to 0 do
    begin
      s := TMTextParse.ParseNode(nd, Data, pubDataParser_JSON, path);
    end;
    Memo2.Text := nd.toJsonString;

    caption := (gettickcount - t).ToString;

    Memo2.Lines.Add(s);

  finally
    nd.Free;
  end;
end;

procedure TForm3.BitBtn6Click(Sender: TObject);
var
  nd: TMNode;
  i, t: int64;
  path, s: String;
begin
  nd := TMNode.Create;
  nd.IsRoot := true;
  path := getexepath + 'web\';
  try
    t := gettickcount;

    for i := 0 to 1000 do
    begin
      nd.clear;
      TMTextParse.GetAllNode(Memo1.Lines.Text, nd, true, false);
      s := TMTextParse.ParseNode(nd, Data, pubDataParser_JSON, path);
    end;
    caption := (gettickcount - t).ToString;

    Memo2.Text := nd.toJsonString;
    Memo2.Lines.Add(s);

  finally
    nd.Free;
  end;

end;

procedure TForm3.BitBtn7Click(Sender: TObject);
var

  i, t: int64;
  path, s: String;
begin

  try
    t := gettickcount;
    for i := 0 to 0 do
    begin
      s := TMFileParse.Parse(getexepath + 'web\index_json_db_dataset.htm');
    end;
    Memo2.Text := s;
    caption := (gettickcount - t).ToString;
  finally

  end;

end;

procedure TForm3.Button1Click(Sender: TObject);
begin
  // self.caption := format('query:%d,proc:%d', [SQLDBHelp.CusQueryOutCount, SQLDBHelp.CusProcOutCount]);
end;

procedure TForm3.BitBtn2Click(Sender: TObject);
var

  i, t: int64;
  path, s: String;

begin

  try
    t := gettickcount;

    for i := 0 to 0 do
    begin
      // s := TMFileParse.ParseFile(getexepath + 'web\index_json_db.htm', pubDataParser_JSON);
      s := TMFileParse.Parse(getexepath + 'web\index_json.htm');
    end;
    Memo2.Text := s;

    caption := (gettickcount - t).ToString;

  finally

  end;

end;

procedure TForm3.BitBtn3Click(Sender: TObject);
var
  exp: IQMathExpression;
  v: Variant;
  d: TDatetime;
  i: integer;
  js, j: TQjson;
  s: String;
begin
  s := '[{"ID": "1","Name": "amu","Score": [ 80, 90, 100 ]}, ' + '{"ID": "2","Name": "amu2", "Score": [ 70, 80, 90 ] },'
    + '{"ID": "3","Name": "amu3","Score": [ 60, 70, 80 ]}, ' + '{"ID": "4","Name": "amu4","Score": [ 50, 60, 70 ] }]';
  js := TQjson.Create;
  js.Parse(s);
  aexpr.OnLookupMissedA := procedure(Sender: IQMathExpression; const AVarName: String; var AVar: TQMathVar)
    begin
      AVar := Sender.Add(AVarName, 0, 0,
        procedure(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant)
        var
          r: string;
        begin
          if TryGetData(AVarName, r, ACallParams.Params, true) then
          begin
            AResult := r;
          end
          else
            AResult := Unassigned;
        end);
    end;
  for i := 0 to js.Count - 1 do
  begin
    j := js[i];
    aexpr.Parse('  (Number(@ID)+1)');
    // v := aexpr.Eval('(3+1)');
    v := aexpr.Eval(js[i]);

    Memo2.Lines.Add(js[i].ToString + ' ' + vartostr(v));

  end;
  s := aexpr.Eval('DateTime.GetDate()');
  Memo2.Lines.Add(s);
  js.Free;
end;

procedure TForm3.BitBtn4Click(Sender: TObject);
var
  s: String;
  i: integer;
  kv: TMKeyValues;
begin
  s := '  month=''2020-01'' asd= showday=true datapath="Date" datefield="date"';
  kv.Parse(s);
  for i := 0 to High(kv) do
    Memo2.Lines.Add(kv[i].key + '=' + kv[i].Value);
end;

procedure TForm3.BitBtn5Click(Sender: TObject);
begin
  // self.ADODataSet1;

end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  MTP.Files.MRootPath := getexepath + 'config\';
  qjson.JsonRttiEnumAsInt := false;

  Data := TQjson.Create;
  Memo1.Lines.LoadFromFile(getexepath + 'web\index_JSON.htm');
  Data.LoadFromFile(getexepath + 'web\data.json');

end;

procedure TForm3.FormDestroy(Sender: TObject);
begin
  Data.Free;
end;

end.
