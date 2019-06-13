%macro countUniqueDays(
  inputDataset=, idVariable=, startDateVariable=, endDateVariable=, 
  outputDataset=);

  /* ---------------------------------------------------------------------

     Teach us to count our days rightly, that we may obtain a wise heart. 
     - Psalm 90:12

     ---------------------------------------------------------------------

     Required parameters:  
       inputDataset - name of input data set
       idVariable – identifier, e.g. subject ID
       startDateVariable - variable with numeric start date
       endDateVariable - variable with numeric end date

     Default values:
       Name of output dataset: &inputDataset._daycount
       Missing value for &endDateVariable replaced by value for    
         &startDateVariable

     Names of temporary datasets: _temp0, _temp11, _temp12, _temp21

     Output data set variables:
       &idVariable
       DAYCOUNT - number of distinct days for each value of &idVariable
       BLOCKCOUNT - number of disjoint time intervals for each value of 
        &idVariable

     --------------------------------------------------------------------- */

    /* define name of outputDataset if null */
  %if &outputDataset eq  %then %let outputDataset= &inputDataset._daycount;
  %put Name of outputDataset: &outputDataset;

    /* Step 0: Sort intervals (with the same id) chronologically. */
  proc sort data=&inputDataset out=_temp0;
    by &idVariable &startDateVariable &endDateVariable;
  run;

    /* Step 1.1: Determine which intervals overlap and can thus be combined. */
  data _temp11;
    format &idVariable blockseq lag_max_endt &startDateVariable &endDateVariable;
    set _temp0;
    by &idVariable;

    retain max_endt;

    if first.&idVariable then max_endt = &endDateVariable;
    else max_endt = max(max_endt, &endDateVariable);

    lag_max_endt = lag(max_endt);

    if first.&idVariable then do;
      blockseq = 1;
      lag_max_endt = .;
    end;
    else if (.z < lag_max_endt < &startDateVariable - 1) then blockseq+1;

    format max_endt lag_max_endt yymmdd10.;
  run;

    /* Step 1.2: Determine the start and end date of each combined interval. */
  proc sql;
    create table _temp12 as
      select 
        &idVariable,
        blockseq,
        min(&startDateVariable) as block_stdt  format=yymmdd10.,
        max(&endDateVariable) as block_endt  format=yymmdd10.,
        &startDateVariable,
        &endDateVariable
      from _temp11
      group by &idVariable, blockseq
      order by &idVariable, blockseq, &startDateVariable, &endDateVariable
    ;
  quit;

    /* Step 2.1: Determine the # of distinct days in each combined interval. */
  data _temp21;
    set _temp12 (drop=&startDateVariable &endDateVariable);
    by &idVariable blockseq;

    if nmiss(block_stdt, block_endt) = 0 then do;
      block_daycount = block_endt - block_stdt + 1;
    end;

    if last.blockseq;
  run;

    /* Step 2.2: Add up day counts from all combined intervals. */
  proc sql;
    create table &outputDataset as
      select 
        &idVariable,
        sum(block_daycount) as dayCount,
        count(unique blockseq) as blockCount
      from _temp21
      group by &idVariable
    ;
  quit;

%mend countUniqueDays;



  /* ------------ EXAMPLE ------------ */

data one;
  input usubjid $ stdt:yymmdd10. endt:yymmdd10.;  
  format stdt endt yymmdd10.;  
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

%countUniqueDays(inputDataset=one, idVariable=usubjid, 
                 startDateVariable=stdt, endDateVariable=endt,
                 outputDataset=two); 
