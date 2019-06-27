/* ------------------------------------------------------------------
    code (with modified input data) from 
      Cheng, Alice M. (2006). 
      "Duration Calculation from a Clinical Programmer’s Perspective." 
      Presented at the SAS User Group International 31 conference. 
      http://www2.sas.com/proceedings/sugi31/048-31.pdf 

      Pages 3-4.
   ------------------------------------------------------------------ */

data ae_dur;
  input subjid $ startdate:yymmdd10. stopdate:yymmdd10.;  
  format startdate stopdate yymmdd10.;  
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

proc sort data=AE_DUR;
  by SUBJID STARTDATE;
run;
proc transpose data=AE_DUR out=STARTDT (drop=_name_) prefix=START;
  by SUBJID;
  var STARTDATE;
run;
proc transpose data=AE_DUR out=STOPDT (drop=_name_) prefix=STOP;
  by SUBJID;
  var STOPDATE;
run;
data AE_DURH;
  merge STARTDT STOPDT;
  by SUBJID;
run;

data METHOD1; 
  retain TOTDUR; 
  set AE_DURH; 

  *--- Use Horizontal Data Representation. ---*; 
  array START{*} START:; 
  array STOP{*} STOP:; 

  /*  duration of first interval*/
  TOTDUR=STOP1-START1+1; 

  do i=2 to dim(START); 
    do j=1 to i-1; 

      *--- Make overlapping but not embedded intervals disjoint. ---*; 
      if (. < START(i) <= STOP(j) ) and (STOP(i) > STOP(j) > .) then do; 
        START(i)=STOP(j)+1; 
      end; 

      *--- Embedded in previous interval. Will not contribute to duration. ---*; 
      else do; 
        if (. < START(i) <= STOP(j) )  and (. < STOP(i) <= STOP(j) ) then do; 
          START(i)=.; 
          STOP(i)=.;
        end;
      end;
    end;

    if START(i) ne . and STOP(i) ne . then DUR=STOP(i)-START(i)+1;
    else DUR=0;
    TOTDUR+DUR;
  end;

  label TOTDUR='DURATION |(DAYS)';
run;

proc print data=METHOD1 label split='|';
  var SUBJID TOTDUR;
run; 