unit MTP.Utils;

interface

uses
  System.SysUtils, System.Variants,
  System.Classes, Generics.Collections;

function PStrSame(const s1, s2: Pchar; AIgnoreCase: boolean; ANotLetterFollow: boolean = false): integer;
function IsDigitStr(aStr: string): boolean;

function getexepath(): String;

implementation

function getexepath(): String;
begin
  result := extractfilepath(paramstr(0));
end;

function IsDigitStr(aStr: string): boolean;
var
  s: Pchar;
begin
  result := false;
  s := Pchar(aStr);
  while s^ <> #0 do
  begin
    if not(((s^ >= '0') and (s^ <= '9')) or ((s^ >= #65296) and (s^ <= #65305))) then
      exit();
    inc(s);
  end;
  result := true;
end;

function PStrSame(const s1, s2: Pchar; AIgnoreCase: boolean; ANotLetterFollow: boolean = false): integer;
var
  p, p1, p2: Pchar;
  c1, c2: char;
begin
  p1 := s1;
  p2 := s2;
  result := 0;
  try
    if AIgnoreCase then
    begin
      while (p1^ <> #0) and (p2^ <> #0) do
      begin
        if p1^ <> p2^ then
        begin
          if (p1^ >= 'a') and (p1^ <= 'z') then
            c1 := char(Word(p1^) xor $20)
          else
            c1 := p1^;
          if (p2^ >= 'a') and (p2^ <= 'z') then
            c2 := char(Word(p2^) xor $20)
          else
            c2 := p2^;
          if c1 <> c2 then
            exit;
        end;
        inc(p1);
        inc(p2);
        inc(result);
      end;
    end
    else
    begin
      while (p1^ <> #0) and (p2^ <> #0) do
      begin
        if p1^ <> p2^ then
        begin
          exit;
        end;
        inc(p1);
        inc(p2);
        inc(result);
      end;
    end;
  finally
    if ANotLetterFollow and (result > 0) then
    begin
      if (p1^ <> #0) then
      begin
        if (p1^ in ['0' .. '9']) or (p1^ in ['A' .. 'Z']) or (p1^ in ['a' .. 'z']) then
        begin
          result := 0;
        end;
      end;
    end;
  end;
end;

end.
