/*---------------------------------------------------------------
* NAME: Geo_Mean.sas
*
* PURPOSE: Calculate the geometric mean of an asset.
*
* MACRO OPTIONS:
* returns - Required.  Data Set containing returns.
* dateColumn - Optional. Date column in Data Set. Default=Date
* outGeo - Optional. Output Data Set with geometric mean. [Default= _geoMean]
* MODIFIED:
* 7/21/2015 � DP - Initial Creation
* 3/05/2016 � RM - Comments modification 
*
* Copyright (c) 2015 by The Financial Risk Group, Cary, NC, USA.
*-------------------------------------------------------------*/

%macro geo_mean(returns, 	 
					dateColumn=Date,
					outGeo= _geoMean);
%local vars _geo;

%let vars= %get_number_column_names(_table= &returns, _exclude= &dateColumn &BM); 
%put VARS IN CoMoments: (&vars);

%let _geo= %ranname();


proc transpose data=&returns out= &_geo;
by &dateColumn;
var &vars;
run;

proc sort data=&_geo;
by _name_;
run;

proc sql noprint;
create table &outGeo as
select exp(mean(log(1+col1)))-1 as GeoMean,
	   _name_
	from &_geo
	where col1^=.
	group by _name_;

proc transpose data= &outGeo out= &outGeo;
id _name_;
run;

data &outGeo(rename= _name_= _STAT_);
	retain _name_ &vars;
set &outGeo;
run;

proc datasets lib= work nolist;
delete &_geo;
run;
quit;
%mend;
