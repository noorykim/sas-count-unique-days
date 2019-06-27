/* ------------------------------------------------------------------
    code (with modified input data) from 
      Su, Pon. (2007). 
      "Calculating Duration via the Lagged Values of Variables." 
      Presented at the SAS Global Forum 2007 conference. 
      http://www2.sas.com/proceedings/forum2007/029-2007.pdf.   

      Pages 1-2.
   ------------------------------------------------------------------ */

data temp;
  input id $ startdt:yymmdd10. stopdt:yymmdd10.;  
  format startdt stopdt yymmdd10.;  
  cards;
101-001 2019-01-01 2019-01-06
101-001 2019-01-03 2019-01-09
101-001 2019-01-11 2019-01-17
101-001 2019-01-12 2019-01-14
101-001 2019-01-16 2019-01-18
101-001 2019-01-21 2019-01-28
101-001 2019-01-25 2019-01-31
;
run;


data temp1;
  set temp;

  format startdt stopdt lagstop  yymmdd10.;

  real_days = stopdt - startdt + 1;

  lagstop =lag(stopdt);

  if id = lag(id) then if lagstop >= stopdt then real_days = 0;
  else if lagstop >= startdt then real_days = stopdt - lagstop;
run;
 
proc timeplot data=temp1;
  plot startdt ='<' stopdt='>' / overlay ref='15JAN19'd   hiloc;
  by id;
run;
proc print data=temp1;
run;
proc sql;
  select 
      id, 
      sum(real_days) as duration_in_days        
    from temp1        
    group by id        
    order by id
  ;
quit;