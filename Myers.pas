unit Myers;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, RegExpr, Metric;

type
  TMainForm = class(TForm)
    memoCode: TMemo;
    btnLode: TButton;
    btnExec: TButton;
    OpenDialog1: TOpenDialog;
    memoResult: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    procedure btnLodeClick(Sender: TObject);
    procedure btnExecClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;


(******************************************************************************)
(****************************implementation part*******************************)
(******************************************************************************)

implementation

{$R *.dfm}

//Загрузка кода в Memo
procedure TMainForm.btnLodeClick(Sender: TObject);
begin
  if OpenDialog1.Execute then memoCode.Lines.LoadFromFile(OpenDialog1.FileName);
end;


//Произвести предварительные действия перед подсчётом метрики и сам его подсчёт
procedure TMainForm.btnExecClick(Sender: TObject);
var predicateCount,arcCount,nodeCount,i:integer;
    blockOperator:boolean;
    expr:TRegExpr;
    posBegin,posEnd:integer;

  //Процедура, удаляющая комментарии и строки в коде
  procedure DelCommentsInCode;
  const FIRSTSIMBOL = 1;
  var i:integer;
      expr:TRegExpr;
      lineOfCode:string;

      //Процедура, удаляющая комментарии и строки в строчке кода (за ненадобностью)
      procedure DeleteExcessPart(var code:string; chr:char; pos:integer);
      const TOEND  = 255;
            SIMBOL = 1;
      begin
        if chr = '"' then
          begin
            Delete(code,pos,SIMBOL);
            while (pos < length(code)) and (code[pos]<>'"') do Delete(code,pos,SIMBOL);
            Delete(code,pos,SIMBOL);
          end
        else
          begin
            Delete(code,pos,TOEND);
          end;
      end; {DelExcessPart}

  begin {DelCommentsInCode}
    expr := TRegExpr.Create;
    expr.Expression := '".|\-\-';
    for i:=0 to memoCode.Lines.Count-1 do
    begin
      lineOfCode:= ' '+memoCode.Lines.Strings[i]+' ';
      expr.InputString := lineOfCode;
      while expr.Exec do
      begin
        DeleteExcessPart(lineOfCode,expr.Match[0][FIRSTSIMBOL],expr.MatchPos[0]);
        expr.InputString := lineOfCode;
      end;
      memoCode.Lines.Strings[i] := lineOfCode;
    end;
  end; {DelCommentsInCode}



  //Процедура, удаляющая пустые строки в коде
  procedure DelEmptyLines;
  var i:integer;
  begin
    i:=0;
    while i<=memoCode.Lines.Count-1 do
    begin
      if Trim(memoCode.Lines.Strings[i]) = '' then
        memoCode.Lines.Delete(i)
      else
        inc(i);
    end;
  end; {DelEmptyLines}


begin {btnExecClick}
  memoResult.Lines.Clear;
  DelCommentsInCode;      //Удаляем комментарии
  DelEmptyLines;          //Удаляем пустые строки
  expr:=TRegExpr.Create;
  i:=0;
  while i<=memoCode.Lines.Count-1 do
  begin
    expr.Expression:='\s(procedure|function)\s+(.+)\s*\(';
    expr.InputString:=memoCode.Lines.Strings[i];
    if expr.Exec then
    begin
      //Поиск начала процедуры(функции)
      while Pos(' begin ',memoCode.Lines.Strings[i])=0 do
        inc(i);
      inc(i);
      posBegin:=i;

      //Поиск конца процедуры(функции)
      while Pos(' end '+expr.Match[2],memoCode.Lines.Strings[i])=0 do
        inc(i);
      posEnd:=i-1;

      //Инициализация переменных
      arcCount:=0;
      nodeCount:=0;
      predicateCount:=0;
      blockOperator:=true;

      //Подсчёт узлов, дуг и предикатов в данной процедуре(функции)
      for i:=posBegin to posEnd do FindNode(memoCode.Lines.Strings[i],arcCount,nodeCount,blockOperator);
      for i:=posBegin to posEnd do DeterminatePredicate(memoCode.Lines.Strings[i],predicateCount);

      //Добавляем узлы входа выхода и связи с ними нашего графа
      inc(arcCount);
      inc(nodeCount,2);

      //Вывод результата в Memo
      memoResult.Lines.Add(expr.Match[2]+': ['+inttostr(arcCount-nodeCount+2)+';'+inttostr(arcCount-nodeCount+2+predicateCount)+']');
    end;
    inc(i); //Переходим на следующую строку
  end;
end; {btnExecClick}

end.
