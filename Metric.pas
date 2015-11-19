unit Metric;

interface

procedure FindNode(lineOfCode:string; var arc,node:integer;var blockOperator:boolean);
procedure DeterminatePredicate(lineOfCode:string; var predicate:integer);


(******************************************************************************)
(****************************implementation part*******************************)
(******************************************************************************)

implementation

  uses RegExpr;

  //Процедура, наглядно заменяющая пустой оператор
  procedure DoNothing;
  begin
  end;

  //Процедура увеличивающая значение дуг и узлов на определённое значение
  procedure IncArcAndNode(var arc,node:integer; const incArc,incNode:integer);
  begin
    inc(arc,incArc);
    inc(node,incNode);
  end;{IncArcAndNode}

  //Процедура для поиска вершин графа
  procedure FindNode(lineOfCode:string; var arc,node:integer;var blockOperator:boolean);
  var expr:TRegExpr;

        //Процедура по подсчёту текущего значения дуг и узлов и определение дальнейшего
        //алгоритма действия
        procedure DeterminateArcAndNode(const incArc,incNode:integer; probOfNullArc:boolean);
        const NULLOPERATOR='null;';
        begin
          if probOfNullArc then
            if Pos(NULLOPERATOR,lineOfCode)=0 then
              IncArcAndNode(arc,node,incArc,incNode)
            else
              DoNothing
          else
            IncArcAndNode(arc,node,incArc,incNode);
          blockOperator:=true;
        end; {DeterminateArcAndNode}

  begin {FindNode}
    //Задаём регулярное выражение по поиску ключевых слов
    expr:=TRegExpr.Create;
    expr.Expression:='\sif\s|\scase\s|\sfor\s|\selse\s|\selif\s|\swhen\s|\swhile\s|\sbegin\s|\send\s|\sloop\s|\snull;';
    expr.InputString:=lineOfCode;

    //Смотрим какое ключевое слово мы встретили и, отталкивая от этого, расчитывем
    //количество новых дуг и узлов и прибавляем их к текущему
    if expr.Exec then
        if expr.Match[0]=' if ' then
            DeterminateArcAndNode(2,1,false)
        else if expr.Match[0]=' case ' then
            DeterminateArcAndNode(1,1,false)
        else if expr.Match[0]=' else ' then
            DeterminateArcAndNode(0,0,false)
        else if expr.Match[0]=' elif ' then
            DeterminateArcAndNode(2,1,false)
        else if expr.Match[0]=' when ' then
            if Pos(' others ',lineOfCode)<>0 then
                DeterminateArcAndNode(2,1,true)
            else
                DeterminateArcAndNode(1,1,true)
        else if expr.Match[0]=' while ' then
            DeterminateArcAndNode(2,1,false)
        else if expr.Match[0]=' for ' then
            DeterminateArcAndNode(2,1,false)
        else if expr.Match[0]=' end ' then
            DeterminateArcAndNode(0,0,false)
        else if expr.Match[0]=' loop ' then
            DeterminateArcAndNode(0,0,false)
        else
            DoNothing
    //Если мы встретили оператор действия(который можно рассмотреть как сост. оператор)
    else
        if blockOperator then
        begin
          IncArcAndNode(arc,node,1,1);
          blockOperator:=false;
        end;
  end;{FindNode}

  //Процедура по подсчёту значения предиката
  procedure DeterminatePredicate(lineOfCode:string; var predicate:integer);
  var expr:TRegExpr;
  begin
    expr:=TRegExpr.Create;
    expr.Expression:='\sand\s|\sor\s|\sxor\s';
    expr.InputString:=lineOfCode;
    if expr.Exec then
    begin
      inc(predicate);
      while expr.ExecNext do
        inc(predicate);
    end;
  end;{DeterminatePredicate}

end.
