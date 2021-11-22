library DateTime;

uses
  System.SysUtils,
  System.Classes, QMathExpr, dateutils;

{$R *.res}

procedure GetDate(Sender: TObject; AVar: TQMathVar; const ACallParams: PQEvalData; var AResult: Variant);
begin
  AResult := formatdatetime('yyyy-MM-dd hh:mm:ss', now());
end;

exports
  GetDate;

begin

end.
