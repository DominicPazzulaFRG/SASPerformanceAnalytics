/*---------------------------------------------------------------
* NAME: table_correlation.sas
*
* PURPOSE: computes the Pearson correlations between assets in a data set.  Presents this data in a table.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns of the portfolio.
* returnsCompare - Required.  Specifies the variable to compute correlations against.
* dateColumn - Optional. Date column in Data Set. Default=DATE
* outCorr - Optional. Specifies name of output Data Set of correlations.  Default="Correlations".
* printTable - Optional. Option to print output table. {PRINT, NOPRINT} Default= [NOPRINT]
* MODIFIED:
* 6/23/2015 � DP - Initial Creation
* 3/05/2016 � RM - Comments modification 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro table_correlation(returns, 
								returnsCompare=, 
								dateColumn= DATE, 
								outCorr= Correlations,
								printTable= NOPRINT);

%local lib ds;

%let lib= %scan(&returns, 1, %str(.));
%let ds= %scan(&returns, 2, %str(.));
%if "&ds" = "" %then %do;
	%let ds=&lib;
	%let lib=work;
%end;
%put lib:&lib ds:&ds;

proc sql noprint;
select name
into :vars separated by ' '
     from sashelp.vcolumn
where libname = upcase("&lib")
 and memname = upcase("&ds")
 and type = "num"
 and upcase(name) ^= upcase("&dateColumn");
quit;

data _tempRet;
set &returns;
drop date;
run;

ods output FisherPearsonCorr= &outCorr;
proc corr data= _tempRet fisher;
var &vars;
with &returnsCompare;
run;

data &outCorr;
set &outCorr;
drop NObs zval biasadj correst;

proc sql noprint;
select name
	into :varStats separated by ' '
	from sashelp.vcolumn
		where libname = upcase("work")
 		and memname = upcase("&outCorr")
 		and type = "num"
		and upcase(name) ^= upcase("&dateColumn");
quit;

data &outCorr(drop= i);
set &outCorr;

array fixStats[*] &varStats;

do i= 1 to dim(fixStats);
if fixStats[i]= . then fixStats[i]= 1;
end;

data &outCorr;
rename corr= Correlation;
rename pvalue= p_value;
rename lcl= Lower_CI;
rename ucl= Upper_CI;
set &outCorr;
run;

data &outCorr;
retain var withvar Correlation p_value Lower_CI Upper_CI;
set &outCorr;
if var= withvar then p_value= 0;
run;

proc datasets lib= work nolist;
delete _tempRet;

%if %upcase(&printTable)= PRINT %then %do;
proc print data= &outCorr noobs;
run;
%end;
%mend;
