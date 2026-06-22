DATA cm;
SET "C:\Users\giova\Giogiò\Universita\Biomedicina\Esame_CM_ETA_AREA_ANNO\Esame_CM_ETA_AREA_ANNO.sas7bdat"; 
RUN;

/*Punto 1*/

/*creazione variabile tasso e log(tasso)*/
DATA cm;
SET cm;
tasso = case/popu*100000;
log_tasso = log(tasso);
RUN;

/*creazione variabile age (numerica) e year1 (numerica) e age2 (age al quadrato)*/
DATA cm;
SET cm;
IF aged=1 THEN age=25;
IF aged=2 THEN age=35;
IF aged=3 THEN age=45;
IF aged=4 THEN age=55;
IF aged=5 THEN age=65;
year1 = year - 1995;
age2= age**2;
RUN;

/*descrizione tasso*/
PROC MEANS DATA= cm N MEAN STD MIN P25 MEDIAN P75 MAX;
VAR tasso;
RUN;

PROC UNIVARIATE DATA = cm;
VAR tasso;
HISTOGRAM / nmidpoints = 14;
RUN;

/*descrizione log_tasso*/
PROC MEANS DATA= cm N MEAN STD MIN P25 MEDIAN P75 MAX;
VAR log_tasso;
RUN;

/*descrizione tasso - area*/
PROC MEANS DATA= cm N MEAN STD MIN P25 MEDIAN P75 MAX;
VAR tasso;
CLASS area;
RUN;

/*descrizione tasso - anno*/
PROC MEANS DATA= cm N MEAN STD MIN P25 MEDIAN P75 MAX;
VAR tasso;
CLASS year;
RUN;

/*descrizione tasso - età*/
PROC MEANS DATA= cm N MEAN STD MIN P25 MEDIAN P75 MAX;
VAR tasso;
CLASS aged;
RUN;

/*Boxplot di tasso per età*/
PROC SORT DATA=cm;
BY aged;
RUN;

PROC BOXPLOT DATA=cm;
PLOT tasso*aged / BOXSTYLE = SCHEMATIC;
LABEL tasso = "tasso X 100,000";
RUN;

/*Boxplot di tasso per area*/
PROC SORT DATA=cm;
BY area;
RUN;

PROC BOXPLOT DATA = cm;
PLOT tasso*area;
LABEL tasso = "tasso X 100,000";
RUN;

/*Boxplot di tasso per anno*/
PROC SORT DATA=cm;
BY year;
RUN;

PROC BOXPLOT DATA = cm;
PLOT tasso*year;
LABEL tasso = "tasso X 100,000";
RUN;

/*Trend tasso anno*/
PROC SORT DATA=cm;
BY area year;
RUN;

DATA year_area;
   SET cm;
   RETAIN tot_case 0;
   RETAIN tot_popu 0;
   BY area year;
   IF first.year THEN DO;
      tot_case = 0;
      tot_popu = 0;
   END;
   tot_case + case;
   tot_popu + popu;
   IF last.year THEN OUTPUT;
   DROP case popu aged tasso log_tasso;
RUN;

DATA year_area;
SET year_area;
tasso = tot_case/tot_popu*100000;
RUN;

PROC SGPLOT DATA=year_area;
  SERIES X=year Y=tasso / GROUP=area LINEATTRS=(THICKNESS=2);
  XAXIS LABEL='year'  VALUES=(1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006);
  YAXIS LABEL='tasso X 100,000' VALUES=(25 to 55);
RUN;

/*Trend tasso classe di età*/
PROC SORT DATA=cm;
BY area aged;
RUN;

DATA aged_area;
   SET cm;
   RETAIN tot_case 0;
   RETAIN tot_popu 0;
   BY area aged;
   IF first.aged THEN DO;
      tot_case = 0;
      tot_popu = 0;
   END;
   tot_case + case;
   tot_popu + popu;
   IF last.aged THEN OUTPUT;
   DROP case popu year tasso year1 log_tasso;
RUN;

DATA aged_area;
SET aged_area;
tasso = tot_case/tot_popu*100000;
RUN;

PROC SGPLOT DATA=aged_area;
  SERIES X=aged Y=tasso / GROUP=area LINEATTRS=(THICKNESS=2);
  XAXIS LABEL='aged';
  YAXIS LABEL='tasso X 100,000' VALUES=(0 to 130);
RUN;

/*Punto 2*/

/*REGRESSIONE DI POISSON*/
data cm;
set cm;
log_popu=log(popu);
run;

PROC GENMOD DATA=cm;
     MAKE 'ParameterEstimates' OUT=stime_con;
     CLASS area aged (ref="1") year (ref="1995");
     MODEL  case = area aged year / LINK=LOG DIST=poisson TYPE3 OFFSET=log_popu;
     OUTPUT OUT=RESIDUI RESchi=residui p=predetti;
RUN;

/*modello senza year*/
PROC GENMOD DATA=cm;
     MAKE 'ParameterEstimates' OUT=stime_con;
     CLASS area aged (ref="1") ;
     MODEL  case = area aged  / LINK=LOG DIST=poisson TYPE3 OFFSET=log_popu;
     OUTPUT OUT=RESIDUI RESchi=residui p=predetti;
RUN;

/*Modello senza confondimenti*/
PROC GENMOD DATA=cm;
     MAKE 'ParameterEstimates' OUT=stime_senza;
     CLASS area ;
     MODEL  case = area / LINK=LOG DIST=poisson TYPE3 OFFSET=log_popu;
     OUTPUT OUT=RESIDUI RESchi=residui p=predetti;
RUN;

/*Punto 3*/

/*regressione andamento predetti tasso age (numerica)*/
PROC reg DATA=cm OUTEST=stime1 OUTSEB;
     MODEL log_tasso = age area year / CLB;
	 PLOT log_tasso*age P.*age / OVERLAY;
	 OUTPUT OUT=PLOT1 P = P_LTASSO;
RUN;
quit;
DATA PLOT2;
     SET PLOT1;
	 P_TASSO=EXP(P_LTASSO);
RUN;
PROC GPLOT DATA=PLOT2;
     SYMBOL1 INTERPOL=JOIN VALUE=DOT;
     PLOT log_tasso*age P_LTASSO*age ;	*plot del logaritmo del tasso (osservato e predetto), trend lineare;
    	*plot del tasso osservato e del tasso predetto come exp del predetto in scala logaritmica;
RUN;

/*proc loess tasso age*/
PROC LOESS DATA=cm;
MODEL tasso = age / SMOOTH=0.8 0.6 0.4 0.2;
LABEL tasso = "Tasso X 100,000";
RUN;

/*proc loess log_tasso age*/
PROC LOESS DATA=cm;
MODEL log_tasso = age / SMOOTH=0.8 0.6 0.4 0.2;
RUN;

/*regressione con age^2*/
PROC GENMOD DATA=cm;
     MAKE 'ParameterEstimates' OUT=stime_con;
     CLASS area year (ref="1995");
     MODEL case = area age age2 year / LINK=LOG DIST=poisson TYPE3 OFFSET=log_popu;
     OUTPUT OUT=RESIDUI RESchi=residui p=predetti;
RUN;

/*Punto 4*/
PROC SORT DATA=cm;
BY age;
RUN;

DATA cm;
     SET cm;
	 SPLINE=0;
	 IF age>45 THEN SPLINE=age-45;
RUN;

PROC GENMOD DATA=cm;
     MAKE 'ParameterEstimates' OUT=stime_con;
     CLASS area year (ref="1995");
     MODEL case = area age spline year / LINK=LOG DIST=poisson TYPE3 OFFSET=log_popu;
     OUTPUT OUT=RESIDUI RESchi=residui p=predetti;
RUN;

/*prova spline*/
PROC TRANSPOSE DATA=STIME_con 
     OUT =STIME2; 
RUN;
DATA DMP2;
     SET STIME2;
	 OBS=_N_;
	 IF OBS GT 1 THEN DELETE;
	 BETA_0=-14.9786;
     BETA_A=0.1449;
     BETA_S=-0.0680;
	 ES_BETA_0=0.1984;
     ES_BETA_A=0.0045;
     ES_BETA_S=0.0051;
	 DOF=105;
	 TSTA=ABS(TINV(0.025,DOF));
	 ***********************************************;
     SLOPE_1=BETA_A;
     ES_SLOPE_1=ES_BETA_A;
	 I_SLOPE_1=SLOPE_1-TSTA*ES_SLOPE_1;
	 S_SLOPE_1=SLOPE_1+TSTA*ES_SLOPE_1;
	 MR_1=EXP(BETA_A);
	 I_MR_1=EXP(I_SLOPE_1);
	 S_MR_1=EXP(S_SLOPE_1);
	 DMP_1=100*(MR_1-1);
	 I_DMP_1=100*(I_MR_1-1);
	 S_DMP_1=100*(S_MR_1-1);
	 TEST_1=SLOPE_1/ES_SLOPE_1;
	 PVAL_1=2*(1-CDF('T',ABS(TEST_1),DOF));
	 ***********************************************;
	 
	 FORMAT  SLOPE_1 I_SLOPE_1 S_SLOPE_1 MR_1 I_MR_1 S_MR_1 DMP_1 I_DMP_1 S_DMP_1 TEST_1 10.6;
	 
	 KEEP    SLOPE_1 I_SLOPE_1 S_SLOPE_1 MR_1 I_MR_1 S_MR_1 DMP_1 I_DMP_1 S_DMP_1 TEST_1 PVAL_1 
	         DOF;
RUN;
PROC TRANSPOSE DATA=DMP2 
     OUT =DMP3;
RUN;
DATA DMP4;
     SET DMP3;
     PARAMETRO=_NAME_; 
     STIMA=COL1;
     KEEP PARAMETRO STIMA; 
RUN;
PROC PRINT DATA=DMP4; RUN;

/***************/
DATA DMP2;
     SET STIME2;
	 OBS=_N_;
	 IF OBS GT 1 THEN DELETE;
	 BETA_0=14.9786;
     BETA_A=0.1449;
     BETA_S=-0.0680;
	 ES_BETA_0=0.1984;
     ES_BETA_A=0.0045;
     ES_BETA_S=0.0051;
	 DOF=105;
	 TSTA=ABS(TINV(0.025,DOF));
	 ***********************************************;
	 INTER_1=BETA_0;
     SLOPE_1=BETA_A;
     ES_SLOPE_1=ES_BETA_A;
	 I_SLOPE_1=SLOPE_1-TSTA*ES_SLOPE_1;
	 S_SLOPE_1=SLOPE_1+TSTA*ES_SLOPE_1;
	 MR_1=EXP(BETA_A);
	 I_MR_1=EXP(I_SLOPE_1);
	 S_MR_1=EXP(S_SLOPE_1);
	 DMP_1=100*(MR_1-1);
	 I_DMP_1=100*(I_MR_1-1);
	 S_DMP_1=100*(S_MR_1-1);
	 TEST_1=SLOPE_1/ES_SLOPE_1;
	 PVAL_1=2*(1-CDF('T',ABS(TEST_1),DOF));
	 ***********************************************;
	 INTER_2=BETA_0-45*BETA_S;
	 SLOPE_2=BETA_A+BETA_S;
	 ES_SLOPE_2=0.0095;
	 I_SLOPE_2=SLOPE_2-TSTA*ES_SLOPE_2;
	 S_SLOPE_2=SLOPE_2+TSTA*ES_SLOPE_2;
     MR_2=EXP(SLOPE_2);
	 I_MR_2=EXP(I_SLOPE_2);
	 S_MR_2=EXP(S_SLOPE_2);
	 DMP_2=100*(MR_2-1);
	 I_DMP_2=100*(I_MR_2-1);
	 S_DMP_2=100*(S_MR_2-1);
	 TEST_2=SLOPE_2/ES_SLOPE_2;
	 PVAL_2=2*(1-CDF('T',ABS(TEST_2),DOF));
	 FORMAT INTER_1 SLOPE_1 I_SLOPE_1 S_SLOPE_1 MR_1 I_MR_1 S_MR_1 DMP_1 I_DMP_1 S_DMP_1 TEST_1 10.6;
	 FORMAT INTER_2 SLOPE_2 I_SLOPE_1 S_SLOPE_1 MR_2 I_MR_2 S_MR_2 DMP_2 I_DMP_2 S_DMP_2 TEST_2 10.6;
	 KEEP   INTER_1 SLOPE_1 I_SLOPE_1 S_SLOPE_1 MR_1 I_MR_1 S_MR_1 DMP_1 I_DMP_1 S_DMP_1 TEST_1 PVAL_1 
	        INTER_2 SLOPE_2 I_SLOPE_2 S_SLOPE_2 MR_2 I_MR_2 S_MR_2 DMP_2 I_DMP_2 S_DMP_2 TEST_2 PVAL_2 DOF;
RUN;
PROC TRANSPOSE DATA=DMP2 
     OUT =DMP3;
RUN;
DATA DMP4;
     SET DMP3;
     PARAMETRO=_NAME_; 
     STIMA=COL1;
     KEEP PARAMETRO STIMA; 
RUN;
PROC PRINT DATA=DMP4; RUN;
/* di seguito il codice per ricavare Mediane, MR, DMP in automatico da SAS: */
PROC TRANSPOSE DATA=STIME_con 
     OUT =STIME2; 
RUN;
DATA DMP2;
     SET STIME2;
	 OBS=_N_;
	 IF OBS GT 1 THEN DELETE;
	 BETA_0=-16.3887;
     BETA_A=0.2370;
     BETA_S=-0.0014;
	 ES_BETA_0=0.2925;
     ES_BETA_A=0.0111;
     ES_BETA_S=0.0001;
	 DOF=105;
	 TSTA=ABS(TINV(0.025,DOF));
	 ***********************************************;
     SLOPE_1=BETA_A;
     ES_SLOPE_1=ES_BETA_A;
	 I_SLOPE_1=SLOPE_1-TSTA*ES_SLOPE_1;
	 S_SLOPE_1=SLOPE_1+TSTA*ES_SLOPE_1;
	 MR_1=EXP(BETA_A);
	 I_MR_1=EXP(I_SLOPE_1);
	 S_MR_1=EXP(S_SLOPE_1);
	 DMP_1=100*(MR_1-1);
	 I_DMP_1=100*(I_MR_1-1);
	 S_DMP_1=100*(S_MR_1-1);
	 TEST_1=SLOPE_1/ES_SLOPE_1;
	 PVAL_1=2*(1-CDF('T',ABS(TEST_1),DOF));
	 ***********************************************;
	 
	 FORMAT  SLOPE_1 I_SLOPE_1 S_SLOPE_1 MR_1 I_MR_1 S_MR_1 DMP_1 I_DMP_1 S_DMP_1 TEST_1 10.6;
	 
	 KEEP    SLOPE_1 I_SLOPE_1 S_SLOPE_1 MR_1 I_MR_1 S_MR_1 DMP_1 I_DMP_1 S_DMP_1 TEST_1 PVAL_1 
	         DOF;
RUN;
PROC TRANSPOSE DATA=DMP2 
     OUT =DMP3;
RUN;
DATA DMP4;
     SET DMP3;
     PARAMETRO=_NAME_; 
     STIMA=COL1;
     KEEP PARAMETRO STIMA; 
RUN;
PROC PRINT DATA=DMP4; RUN;

/*grafico relazione stimata tra tasso di incidenza di CM ed età nelle due aree aggiusta per anno*/
PROC GENMOD DATA=cm;
BY area;
     MAKE 'ParameterEstimates' OUT=stime_area;
     CLASS    year (ref="1995");
     MODEL  case = age age2 year / LINK=LOG DIST=poisson TYPE3 OFFSET=log_popu;
     OUTPUT OUT=RESIDUI RESchi=residui p=predetti;
RUN;

DATA vettore;
   DO eta = 21 TO 70; 
      OUTPUT;
   END;
RUN;

DATA vettore;
SET vettore;
area0 = exp(-16.3887 + 0.1681 + 0.2370 * eta - 0.0014 * eta**2)*100000;
area1 = exp(-16.3887 + 0.2370 * eta - 0.0014 * eta**2)*100000;
RUN;

PROC SGPLOT DATA=vettore;
   SERIES X=eta Y=area0 / LINEATTRS=(COLOR=blue THICKNESS=2);
   SERIES X=eta Y=area1 / LINEATTRS=(COLOR=red THICKNESS=2);
   XAXIS LABEL="age";
   YAXIS LABEL="frequenza CM X 100,000";
RUN;
