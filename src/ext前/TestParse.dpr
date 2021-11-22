program TestParse;

uses
  Vcl.Forms,
  MTP.Types in 'MTP.Types.pas',
  MTP.Parse in 'MTP.Parse.pas',
  MTP.Expression in 'MTP.Expression.pas',
  Unit3 in 'Unit3.pas' {Form3},
  MTP.Files in 'MTP.Files.pas',
  MTP.Utils in 'MTP.Utils.pas',
  MTP.msdb in 'MTP.msdb.pas',
  MTP.HttpClient in 'MTP.HttpClient.pas',
  MTP.Plugin.host,
  MTP.QMathExpr.Extend in 'MTP.QMathExpr.Extend.pas',
  MTP.Parse.json in 'MTP.Parse.json.pas',
  MTP.Param in 'MTP.Param.pas';

{$R *.res}


begin
//  ReportMemoryLeaksOnShutdown := true;
  Application.Initialize;
  Application.MainFormOnTaskbar := true;
  Application.CreateForm(TForm3, Form3);
  Application.Run;

end.
