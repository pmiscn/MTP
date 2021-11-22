unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  MuVParse, qjson, PascalStrings,

  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  Vcl.Buttons;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    FileOpenDialog1: TFileOpenDialog;
    Open: TButton;
    Parse: TButton;
    Button3: TButton;
    Button4: TButton;
    TabSheet3: TTabSheet;
    E_In: TMemo;
    E_Out: TMemo;
    Memo3: TMemo;
    NetHTTPClient1: TNetHTTPClient;
    Button1: TButton;
    BitBtn1: TBitBtn;
    Button2: TButton;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    procedure OpenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ParseClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
  private
    FData: TQJson;
    mvp: TMVParse;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses Utils.Utils, mtp.types;
{$R *.dfm}

procedure TForm1.BitBtn1Click(Sender: TObject);
var
  amvp: TMVParse;
begin
  amvp := TMVParse.create('');
  amvp.FixText.Text := self.E_In.Text;
  amvp.Data := FData;
  self.E_Out.Text := amvp.OutText.Text;
  amvp.Free;

end;

procedure TForm1.BitBtn2Click(Sender: TObject);
var
  n: TMNode;
begin
  n := TMNode.create;
  try

  finally
    n.Free;
  end;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
var
  s: TPascalString;
  ps: PChar;
  c: char;
begin
  s := 'asdf1234567891320';
   ps := PChar( s.buff);
  while ps^ <> #0 do
  begin
    c := ps^;

    inc(ps);
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  amvp: TMVParse;
begin
  amvp := TMVParse.create(TUtils.AppPath + 'web\index.htm');
  amvp.Data := FData;
  self.E_Out.Text := amvp.OutText.Text;
  amvp.Free;
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  i: integer;
  t: integer;
begin
  t := gettickcount();
  for i := 1 to 1000 do
    mvp.OutText.Text;
  self.caption := (format('”√ ±º‰£∫%d', [gettickcount - t]));

  self.E_Out.Text := mvp.OutText.Text;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  fn: String;
begin

  fn := TUtils.AppPath + 'web\index.htm';
  FData := TQJson.create;
  FData.LoadFromFile(TUtils.AppPath + 'web\data.json');
  if fileExists(fn) then
    E_In.Lines.LoadFromFile(fn);
  mvp := TMVParse.create(fn);
  mvp.Data := FData;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  mvp.Free;
  FData.Free;
end;

procedure TForm1.OpenClick(Sender: TObject);
begin
  if FileOpenDialog1.Execute then
    self.E_In.Lines.LoadFromFile(FileOpenDialog1.FileName);
end;

procedure TForm1.ParseClick(Sender: TObject);

begin

  // self.E_Out.Text:=mvp.FixText.Text;
  self.E_Out.Text := mvp.OutText.Text;

end;

end.
