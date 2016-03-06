/*---------------------------------------------------------------
* NAME: Chart_Histogram.sas
*
* PURPOSE: Create a simple histogram with options for an asset or instrument using a returns data set.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* asset - Required.  Specifies the variable name of benchmark asset or index in the returns data set.
* scale - Optional. Specifies whether the y-axis should go by probability or frequency. {count, percent, proportion}, [Default= count]  
* title - Optional.  Title for histogram. [Default= asset returns]
* bindwidth - Optional. Specifies the range of returns to select for each bar. [Default= 0.001]
* density - Optional. Overlay a normal density curve on top of the histogram for comparison. 
*           [Default= TRUE]. If true, [TRUE=TURE]. {TRUE, FALSE}.
* color - Optional. Change the color of the histogram bins. [Default= cornflowerblue]
* densitycolor - Optional. Change the color of the density line. [Default= red]
* histogramTransparency - Optional. Change the transparency of the histogram bins. [Default= 0.8]
* keepOutliers - Optional. Delete outlier returns from the histogram within the range of Q1- 1.5IQR and Q3+1.5IQR.
                 [Default= TRUE]. {TRUE, FALSE}
* qqplot - Optional. Display a QQ Plot in addition to the histogram. [Default= FALSE]. {TRUE,FALSE}
* rug - Optional. Display a fringe plot overlayed onto the histogram. [Default= FALSE]. {TRUE,FALSE}
* dateColumn - Optional. Specifies the date column for returns in the data set. [Default= Date]
*
* Future Modifications: Overlay VaR line once the VaR macro is completed.
*
* MODIFIED:
* 1/7/2016 � CJ - Initial Creation
*
* Copyright (c) 2016 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro Chart_histogram(returns, 
								asset=,
								scale= count,
								title= &asset returns,
								binwidth= 0.001,
								density=TRUE,
								color= cornflowerblue,
								densitycolor= red,
								histogramTransparency= 0.8, 
								KeepOutliers= TRUE,
								qqplot= FALSE,
								rug= FALSE,
								dateColumn= Date);

%let IQR= %ranname();

%if &KeepOutliers= FALSE %then %do;
proc univariate data= &returns noprint;
var &asset;
output out=&IQR QRange= InterQuartileRange Q1= Quartile1 Q3= Quartile3;
run;

data &IQR;
set &IQR;
call symput('InterQuartileRange', InterQuartileRange);
call symput('Quartile1', Quartile1);
call symput('Quartile3', Quartile3);
run;

%let InterQR= %sysfunc(putn(&InterQuartileRange, best12.2));
%let Quartile1= %sysfunc(putn(&Quartile1, best12.2));
%let Quartile3= %sysfunc(putn(&Quartile3, best12.2));
%let lowerBound= %sysevalf(&Quartile1 - 1.5*&InterQR);
%let upperBound= %sysevalf(&Quartile3 + 1.5*&InterQR);

data &returns;
format &asset percent10.2;
set &returns;
where &asset > &lowerBound and &asset < &upperBound;
run;
%end;

proc template;
define statgraph fringeplot;
dynamic VAR VARLABEL;
begingraph;
entrytitle "Histogram for &asset";
layout overlay / xaxisopts= (label= VARLABEL)
				 yaxisopts= (offsetmin= 0.03);
%if %upcase(&rug)= %upcase(true) %then %do;
		fringeplot VAR/ datatransparency= &histogramTransparency fringeheight= 3pct;
%end;
		histogram &asset / datatransparency= &histogramTransparency scale=&scale binwidth= &binwidth fillattrs= (color= &color);
		%if %upcase(&density)= %upcase(true) %then %do;
			densityplot &asset / lineattrs=(color=&densitycolor) normal() name="Normal";
			densityplot &asset / lineattrs=(color=darkblue) kernel() name="Kernel";
				discretelegend "Normal" "Kernel" / location=inside across=1
					autoalign=(topright topleft);
		%end;
	endlayout;
	endgraph;
end;
run;
title "&title";
proc sgrender data= &returns template= fringeplot;
dynamic var= "&asset" varlabel= "&asset returns"; 
run;

%if &qqplot= TRUE %then %do;
proc univariate data= &returns noprint;
var &asset;
qqplot;
title "QQ Plot for &asset";
run;
%end;

proc datasets lib= work nolist;
delete &IQR;
quit;
%mend;
 
