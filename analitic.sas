FORK/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/*****************                                                                       *******************/
/****************                      ����� �� ��������� ���-2009                        ******************/
/*****************                                                                       *******************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/*������������� �����*/ *D - sony, Z - ���;
/*������������� �����*/ *D - sony, Z - ���;
%macro what_OC;
%if &sysscpl = W32_7PRO %then 
	%do;
		%let disk = D; *sony;
	%end;
%else/*%if &sysscpl = "W32_7PRO" %then */ 
	%do;
		%let disk = Z; *���������;
	%end;
%mend;


/*������������ ��*/
/*data comp;*/
/*	OC = "&sysscpl";*/
/*run;*/
/**/
/*proc print data = COMP;*/
/*run;*/
%what_OC;

%let LN = ALL2009; * ��� ����������;
Libname &LN "&disk.:\AC\OLL-2009\SAS"; * ���������� ������;
%let y = cl;
%let cens = (99, 132, 258, 264);

%macro Eventan(dat,T,C,i,s,cl,f,for, ttl);
/*
dat -��� ������ ������,
T - �����,
C - ������ �������/��������������,
i=0, ���� � ������ �������,
i=1, ���� � ������ ��������������.
s = �����,���� �������� ������ ������������
s = F, ���� �������� ������ ����������� �����������
cl = cl,���� ���������� ������������� ��������
cl = �����,���� �� ���������� ������������� ��������
s = F, ���� �������� ������ ����������� �����������
f = ������ (������) ���� ����� �� ��� ������
for = ������ (1.0 ��� ������������� ��������, ����� ��� ������������ �������)
ttl = ���������
*/

data _null_; set &dat;
   length tit1 $256 tit2 $256;
*������ ��������;
tit1=vlabel(&T);
%if &f ne %then %do; tit2=vlabel(&f);%end;
   * �������� ������� � ���������������;
   call symput('tt1',tit1);
   call symput('tt2',tit2);
output;
   stop;
   keep tit1 tit2;
run;
title1 &ttl;
title2 " ���������:  &tt1 // ������       :  &tt2";
ods graphics on;
ods exclude WilHomCov LogHomCov HomStats  Quartiles; *ProductLimitEstimates;
proc lifetest data=&dat plots =(s( &s &cl))  method=pl ;
    %if &f ne %then %do; strata &f/test=logrank;
    id &f;format   &f &for;%end;
    time &T*&C(&i) ;
run;
ods graphics off;
%mend;



proc format;
    value oc_f  1 = "B-���������" 2 = "T-���������" 3 = "����������������" 0 = "����������" ;
    value gender_f 1 = "�������" 2 = "�������";
    value risk_f 1 = "�����������" 2 = "�������" 3 = "��� ������";
    value age_group_f low-30 = "�� 30-�� ���" 30-high = "����� 30-�� ���";
	value tkm_f 0="���" 1="����" 2="����";
	value it_f 1="����" 0 = "���";
	value time_error_f . = "��� ������" 0 = "���� ���������� ������ �� ���������" 1 = "���� ���������� ������� (�����) ������ ��� ���� ���������� ��������";
	value new_group_risk_f 1 = "�����������" 2 = "�������";
	value y_n 0 = "���" 1 = "��";
run;

/*------------ ������������� �������������� ������� � ����������� ������ ---------------*/
data &LN..all_pt;
    set &LN..all_pt;
    rename
        new_protokol_ollid = pguid
		new_nbrpacient = pt_id
        new_name = name
        new_datest = pr_b
        new_datefn = pr_e
        new_lastvisitdate = lastdate
		new_blast_km = blast_km
        ;
	label 
		new_group_risk = "������ �����"
		
		;
run;
data &LN..all_et;
    set &LN..all_et;
    rename
        new_datest = ph_b
        new_datefn = ph_e
        new_protokolname = name_e
        new_protokol = pguid
		new_group_risk = fin_group_risk
		new_group_riskname = fin_group_riskname
        ;
run;
data &LN..all_ev;
    set &LN..all_ev;
    rename
        new_protokol_oll = pguid
        new_protokol_ollname = name
    ;
run;
/*------ ��������������, � ���������� ����������� ����������� ----------*/


data cens;
	set &LN..all_pt;
	if pt_id in &cens then output;
run;

proc print data = cens split='*' N;
	var pt_id name;
	label pt_id = '����� ��������*� ���������'
          name = '���*� ���� ���������';
	title "�� ���� ������������� ��������� ��������� ������" ;
run;

data null;
	set &LN..all_pt;
	if pt_id = . then output;
run;

proc print data = null split='*' N;
	var pt_id name;
	label pt_id = '����� ��������*� ���������'
          name = '���*� ���� ���������';
	title "� ���� �� ����� ������ � ���������" ;
run;

proc sort data=&LN..all_pt;
	by pt_id;
run;


/*----- ��������� �������� ��������. �� ������ �� ��������� ��������, ��� ��� ��� ������ ���������� ������� �� ����*/
proc sort data=&LN..tmp_age;
	by pt_id;
run;

data &LN..all_pt; 
	merge &LN..all_pt &LN..tmp_age;
	by pt_id;
run;


data &LN..all_pt; *������ �� ������� ���������;
    set &LN..all_pt;

	if new_group_risk = 3 then new_group_risk = .; * 3 -- ��� ��� "��� ������", ��� ���������� ���������� ������!;

/*���� �������� �������, ����� ����� ������������*/

if age = . then age = floor(yrdif(new_birthdate, pr_b,'AGE'));  *���� �������� ��� � ���� ��, �� ���������������� � ���� �� ���� �������� ������ ���������;
    *FORMAT age 2.0;

/*-------------------*/

    /* ��� ������� */
    select;
        when (new_oll_class in (1,2,3) )   oll_class = 1; /*B-OLL*/
        when (new_oll_class in (5,6,7,8) ) oll_class = 2; /*T-OLL*/
        when (new_oll_class = 99)  oll_class = 0; /*����������*/
        when (new_oll_class = 9 )  oll_class = 3; /*���������������*/
        otherwise;
    end;

/* ������ �������������� ������*/
    if NOT(new_nbrpacient in &cens ) then output;
run;

/*-----------------------------------���� �������� ������� �� ������----------------------*/
proc sort data=&LN..all_et;
    by pguid new_etap_protokol; *��������� ������� ������ �� ID ��������� � �� ������ ��������� (� ��������������� �������);
run;

proc sort data=&LN..all_pt;
    by pguid; *��������� ������� ������ �� ID ��������� � �� ������ ��������� (� ��������������� �������);
run;

/*��������� ������� ��������� � ������, ���������� ��� ���� �� ��������� ��� ������ �� ������*/
data &LN..new_et;
    merge &LN..all_pt (in = i1) &LN..all_et (in = i2);
    by pguid;

    it1 = i1;
    it2 = i2;
run;



/*����������� ��������� �������, ��� ������ ��������� ������ �������� ����� �� ������������, � ����� �����. ��������� ������� � �������*/
data &LN..new_pt &LN..error_timeline /*(keep=)*/;
    set &LN..new_et;
    by pguid;
    retain ec   d_ch faza time_error induct_b induct_e; *ec -- ��� ���������� ������ "���������";
    if first.pguid then do;  ec = 0;  end;
/*--------------------------------------------------*/
    if it2 then ec + 1;
	if lastdate = . then time_error = 0;

    if ph_b > lastdate and time_error = 0 then do; lastdate = ph_b; end; *�������� �� ��������� ����. ;
    if ph_b > lastdate then do; lastdate = ph_b; time_error = 1; end;
    if ph_e > lastdate and time_error = 0 then do; lastdate = ph_e; end;
	if ph_e > lastdate then do; lastdate = ph_e; time_error = 1; end;
	
	/*����������� ��������*/
/*	if */


    if new_smena_na_deksamet = 1 then
        do;
            d_ch = 1;
            faza = new_etap_protokol;
        end;
/*---------------------------------------------------*/
    if last.pguid then
        do;
            output &LN..new_pt;
			if time_error ne . then output &LN..error_timeline;
            d_ch = 0;
            faza = .;
			time_error = .;
        end;
	label d_ch = "����� �� ������������";
run;





/*��������� �� ������� �������� �������-����*/

proc sort data = &LN..error_ptVSet;
	by pt_id;
run;

data &LN..error_ptVSet;
	set &LN..new_et (keep = pt_id name name_e new_etap_protokolname it1 it2);
	if it1 ne it2 then output; 
run;

proc print data = &LN..error_ptVSet split='*' N obs="�����*������";
	var pt_id name name_e new_etap_protokolname it1 it2;
	label pt_id = '����� ��������*� ���������'
          name = '���*� ���� ���������'
          name_e = '���*� ���� ������'
		  new_etap_protokolname = '����'
		  it1 = '������*� ���� ���������' 
		  it2 = '������* � ���� ������';
	title "������ � ���� (���� ������� - ����)" ;
	format  it1 it2 it_f. ; 
run;

/*----------------------------------------------------------------------------------------*/



/*------------��� ����� ����� ��������� �������� ���������----------*/
/*------------------------------------------------------------------*/



/*------ ��� �������� ���������, ������ ����� ������� ���������� ������ ------------*/

proc sort data = &LN..error_timeline;
	by pt_id;
run;

proc print data = &LN..error_timeline split='*' N;
	var pt_id name time_error;
	label pt_id = '����� ��������*� ���������'
          name = '���*� ���� ���������'
		  time_error = "������";
	title "������ ���������� ���������" ;
	footnote '*���� ���������� ������ ��������� � ������������ � ��������� ����������� � �������'; 
	format  it1 it2 it_f. time_error time_error_f. ; 
run;



/*-------------------------- ���������� ���������� ��� ����������� ������� ----------------------------*/

/*����������� ������� ������� � ������ ��� �������������, ������� ������ ������*/
proc sort data=&LN..all_ev;
    by pguid new_event new_event_date ;
run;



data &LN..all_ev_red;
	set &LN..all_ev;
	by pguid new_event new_event_date ;
	if first.new_event then output;
run;


/*���������� ������� � ���������. ��� ����� ���������� � ���� �������� � ������*/

proc sort data=&LN..all_ev_red;
    by pguid;
run;

proc sort data=&LN..new_pt;
    by pguid;
run;

data &LN..new_ev;
    merge &LN..new_pt &LN..all_ev_red ;
    by pguid;
run;
/*  rel �������� = 1 */
/*  res �������������� = 2*/
/*  death ������ = 3*/
/*  rem ������� = 5*/


/*--- ���������� ���������� ��������/��������/������ ---*/
data &LN..new_pt;
    set &LN..new_ev;
    by pguid;
    retain i_rem date_rem /**/ i_death date_death /**/ i_rel date_rel /**/ i_res date_res /**/ Laspot;
    if first.pguid then 
		do; 
			i_rel = 0; date_rel = .;  
			i_res = 0; date_res = .; 
			i_death = 0; date_death = .; 
			i_rem = 0; date_rem = .; 
			Laspot = 0; 
		end;
/*----------------------------------*/
    if new_event = 1 then do; i_rem = 1; date_rem = new_event_date; end;
	if new_event = 2 then do; i_res = 1; date_res = new_event_date; end;
    if new_event = 3 then do; i_death = 1; date_death = new_event_date; end;
    if new_event = 5 then do; i_rel = 1; date_rel = new_event_date; end;
	if new_aspor_otmena = 1 then laspot = 1;
/*---------------------------------*/
    if last.pguid then 
		do; 
			output; 
			i_rel = 0; date_rel = .; 
			i_res = 0; date_res = .; 
			i_death = 0; date_death = .; 
			i_rem = 0; date_rem = .; 
			Laspot = 0; 
		end;
run;


/*��������� �������� ���� ����� �������� ����� ���� �� ����������� ���� <----------- ���� �� ���????*/
/*���������� ���������� �������� �� ���� ������*/
Data &LN..new_pt;
    set &LN..new_pt;
    if date_rem > lastdate then lastdate = date_rem;
    if date_death > lastdate then lastdate = date_death;
    if date_rel > lastdate then lastdate = date_rel;
    /*��������*/
    *lastdate = MDY(9,1,2013);
run;



/*������������*/
/*��������� � ������*/
Data &LN..new_pt;
    set &LN..new_pt;

    select (i_death);
        when (1) TLive = (date_death - pr_b)/30;
        when (0) TLive = (lastdate   - pr_b)/30;
        otherwise;
    end;

    select (i_rem);
        when (1) Trem = (date_rem - pr_b)/30;
        when (0) Trem = (lastdate - pr_b)/30;
        otherwise;
    end;

    select (i_rel);
        when (1) Trel = (date_rel - date_rem)/30;
        when (0) Trel = (lastdate - date_rem)/30;
        otherwise;
    end;
run;

/*������������� ������������*/
Data &LN..new_pt;
    set &LN..new_pt;
    iRF = i_rel | i_death;
    Select;
        when (i_rel)  TRF = Trel;
        when (i_death) TRF = (date_death - date_rem)/30;
        when (iRF = 0) TRF = (lastdate - date_rem)/30;
        otherwise;
    end;
run;

/*������ � ��������*/
/*�������� �����*/


/*-----------------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/
/*--------------------------------------------������������ ����������----------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/

/*1. ����� ���������� ������� � ��������*/
/*2. ������� (�������, �������)*/
/*3. ���*/
/*4. �������������:*/
/*	- ����������*/
/*	- B-��������� (�����, �������)*/
/*		-- ������ ���-B (���-��)*/
/*		-- common (���-��)*/
/*		-- ���-B (���-��)*/
/*	- T-��������� (�����, �������)*/
/*		-- ������ 1/2 (���-��)*/
/*		-- ������������ (���-��)*/
/*		-- ������ (���-��)*/
/*	- �����������������*/

footnote " ";

proc means data = &LN..all_pt N;
	var new_birthdate;
   title '����� �������';
run;

proc means data = &LN..all_pt median max min ;
   var age;
   title '������� ������� (�������, �������)';
run;


proc freq data=&LN..all_pt ;
   tables new_gendercodename / nocum;
   title '���';
run;

proc freq data=&LN..all_pt ;
   tables new_oll_classname / nocum;
   title '������������� (��������)';
run;

proc freq data=&LN..all_pt ; *���������� � ���������� (��� ���������);
   tables oll_class / nocum NOPERCENT;
   title '�������������';
   FORMAT oll_class oc_f.;
run;

data ift; *��������� �� ������� ������������� "����������" � ����������������;
	set &LN..all_pt;
	if oll_class in (1,2) then output;
run;

proc freq data=ift ;
   tables oll_class / nocum;
   title '�������������';
   FORMAT oll_class oc_f.;
run;

/*============= ��� ���������� ��� �������� 2�2 =============*/

data ift_b; *�������� ��� B-OLL;
	set &LN..all_pt;
	if oll_class = 1 then output;
run;

proc freq data=ift_b ;
   tables new_oll_classname / nocum;
   title '������������� / �������� ��� B-OLL';
   FORMAT oll_class oc_f.;
run;

data ift_b; *�������� ��� T-OLL;
	set &LN..all_pt;
	if oll_class = 2 then output;
run;

proc freq data=ift_b ;
   tables new_oll_classname / nocum;
   title '������������� / �������� ��� T-OLL';
   FORMAT oll_class oc_f.;
run;

/*==============================*/


/*proc freq data=&LN..all_pt ;*/
/*   tables*/
/*        new_citogenname*/
/*        / nocum;*/
/*   title '������������';*/
/*run;*/


/*proc sort data=&LN..all_pr;*/
/*    by new_citogenname;*/
/*run;*/
/**/
/*proc freq data=&LN..all_pr;*/
/*    by new_citogenname;*/
/*   tables*/
/*        new_mitozname*/
/*        / nocum;*/
/*   title '������������';*/
/*run;*/
/**/
/*proc freq data=&LN..all_pr;*/
/*    by new_citogenname;*/
/*   tables*/
/*        new_normkariotipname*/
/*        / nocum;*/
/*   title '���������� ��������';*/
/*run;*/
/**/
/*proc freq data=&LN..all_pr;*/
/*    by new_citogenname;*/
/*   tables*/
/*        new_t922name*/
/*new_bcrablname*/
/*new_t411name*/
/*new_anomal_oth*/
/**/
/*        / nocum;*/
/*   title '������ ��������';*/
/*run;*/
/**/
/*proc sort data=&LN..all_pr;*/
/*    by oll_class;*/
/*run;*/
/**/
/*proc freq data=&LN..all_pr;*/
/*    by oll_class;*/
/*    tables*/
/*        new_gendercodename*/
/*        / nocum;*/
/*   title '��������������� ���������� � �������';*/
/*   format oll_class oc_f.;*/
/*run;*/
/**/
/*proc means data = &LN..all_pr median mean max min ;*/
/*    by oll_class;*/
/*    var age;*/
/*   title '��������������� ���������� � �������';*/
/*   format oll_class oc_f.;*/
/*run;*/

/*----------- ������� ------------*/

/*8. ������������� �� ������� �����*/
/*- ������ ����� (n = ?) �� �������� ����������*/
/*	-- �������� (�����, �������)*/
/*	-- �������  (�����, �������)*/
/*- ����� �� ������������*/
/*	-- �� (�����, �������)*/

/*// ��������� ������� � ���� �������� 2�2 \\*/

/*9. ���������� �������� */

/*(�����, �������)| ��� (n = ?)	| B-OLL (n = ?)	| T-OLL (n = ?)	|*/
/*-----------------------------------------------------------------*/
/*��		|		|		|		|*/
/*  ����� �/�	|		|		|		|*/
/*  ����� 1 �.	|		|		|		|*/
/*  ����� 2 �.	|		|		|		|*/
/*-----------------------------------------------------------------*/
/*������ � ���.	|		|		|		|*/
/*-----------------------------------------------------------------*/
/*������������ �.	|		|		|		|*/
/*-----------------------------------------------------------------*/

*---------- ���������� ���������� -----------------;
/*proc means data = &LN..all_pt N;*/
/*	var new_group_risk;*/
/*   title '�� ������� ����� ����� ���������� � N ���������';*/
/*run;*/
/**/
/*proc freq data=&LN..all_pt ;*/
/*   tables new_group_risk / nocum;*/
/*   title '������ ����� ';*/
/*   format new_group_risk new_group_risk_f.;*/
/*run;*/
/*------------------------------------------------*/



/*����� �� ������������ */
/*���� ����� ��������, ����� ������ ���������� �� 7-�� ���� �� ��������� (�� ��������)*/

proc freq data=&LN..new_pt ;
   tables  d_ch*new_group_risk/ nocum;
   title '����� �� ������������ �� ������� �����';
   format new_group_risk new_group_risk_f. d_ch y_n.;
run;
proc freq data=&LN..new_pt ;
   tables  new_group_risk/ nocum;
   title '������ �����';
   format new_group_risk new_group_risk_f. d_ch y_n.;
run;
proc freq data=&LN..new_pt ;
   tables  d_ch/ nocum;
   title '����� �� ������������';
   format new_group_risk new_group_risk_f. d_ch y_n.;
run;

/*-----------����������  �������� -----------------*/

/*proc freq data=&LN..all_et;*/
/*    tables*/
/*new_etap_protokolname*/
/*        /nocum;*/
/*    title '����� ��������� ������';*/
/*run;*/
/*--------------------------------------------------*/



/*-----------------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/
/*---------------------------------------------- ������ ������������ ----------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/


/*------------------ ����� ���������� ----------------------*/
%eventan (&LN..new_pt, TLive, i_death, 0,,&y,,,"����� ����������. ������������"); *����� ������������;
%eventan (&LN..new_pt, TRF, iRF, 0,,&y,,,"����� ����������. ������������� ������������"); *������������� ������������;
%eventan (&LN..new_pt, Trel, i_rel, 0,F,&y,,,"����� ����������. ����������� �������� ��������"); *����������� �������� ��������;


*%eventan (&LN..new_pt, TLive, i_death, 0,F,&y,,,"����� ����������");
*%eventan (&LN..new_pt, TRF, iRF, 0,F,&y,,,"����� ����������");

/*���*/
/*%eventan (&LN..new_pt, TLive, i_death, 0,,&y,new_gendercode,gender_f.,"���");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,,&y,new_gendercode,gender_f.,"���");*/
/*%eventan (&LN..new_pt, TLive, i_death, 0,F,&y,new_gendercode,gender_f.,"���");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,F,&y,new_gendercode,gender_f.,"���");*/

/*---------------- ������������� �� ��������� ----------------*/
data  &LN..tmp;
    set &LN..new_pt;
    if (oll_class in (1,2)) then output;
run;

%eventan (&LN..tmp, TLive, i_death, 0,,&y,oll_class,oc_f.,"������������� �� ����������. ������������");
%eventan (&LN..tmp, TRF, iRF, 0,,&y,oll_class,oc_f.,"������������� �� ����������. ������������� ������������");
%eventan (&LN..tmp, Trel, i_rel, 0,F,&y,oll_class,oc_f.,"������������� �� ����������. ����������� �������� ��������"); *����������� �������� ��������;

*%eventan (&LN..tmp, TLive, i_death, 0,F,&y,oll_class,oc_f.,"������������� �� ����������");
*%eventan (&LN..tmp, TRF, iRF, 0,F,&y,oll_class,oc_f.,"������������� �� ����������");

/*---------------- ������������� �� ��������� -----------------*/

proc print data = &LN..new_pt;
	var pt_id name new_normkariotipname;
run; 

%eventan (&LN..new_pt, TLive, i_death, 0,,&y,new_normkariotipname,,"������������� �� ���������. ������������");
%eventan (&LN..new_pt, TRF, iRF, 0,,&y,new_normkariotipname,,"������������� �� ���������. ������������� ������������");
%eventan (&LN..new_pt, Trel, i_rel, 0,F,&y,new_normkariotipname,,"������������� �� ��������� ����������� �������� ��������"); *����������� �������� ��������;


*%eventan (&LN..new_pt, TLive, i_death, 0,F,&y,new_normkariotipname,,"������������� �� ���������");
*%eventan (&LN..new_pt, TRF, iRF, 0,F,&y,new_normkariotipname,,"������������� �� ���������");


/*�� ������� �����*/
/*%eventan (&LN..new_pt, TLive, i_death, 0,,&y,new_group_risk,risk_f.,"�� ������� �����");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,,&y,new_group_risk,risk_f.,"�� ������� �����");*/
/*%eventan (&LN..new_pt, TLive, i_death, 0,F,&y,new_group_risk,risk_f.,"�� ������� �����");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,F,&y,new_group_risk,risk_f.,"�� ������� �����");*/

/*������ � ����������� ������ �����*/
/*data  &LN..tmp;*/
/*  set &LN..new_pt;*/
/*  if (new_group_risk = 1) then output;*/
/*run;*/
/**/
/*%eventan (&LN..tmp, TLive, i_death, 0,,&y,d_ch,1.0,"����������� ������ �����");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,,&y,d_ch,1.0,"����������� ������ �����");*/
/*%eventan (&LN..tmp, TLive, i_death, 0,F,&y,d_ch,1.0,"����������� ������ �����");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,F,&y,d_ch,1.0,"����������� ������ �����");*/

/*,"������� ������ �����"*/
/*data  &LN..tmp;*/
/*  set &LN..new_pt;*/
/*  if (new_group_risk = 2) then output;*/
/*run;*/
/**/
/*%eventan (&LN..tmp, TLive, i_death, 0,,&y,d_ch,1.0,"������� ������ �����");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,,&y,d_ch,1.0,"������� ������ �����");*/
/*%eventan (&LN..tmp, TLive, i_death, 0,F,&y,d_ch,1.0,"������� ������ �����");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,F,&y,d_ch,1.0,"������� ������ �����");*/

/*�-��������� ���*/
data  &LN..tmp;
    set &LN..new_pt;
    if (oll_class = 2) then output;
run;

%eventan (&LN..tmp, TLive, i_death, 0,,&y,new_normkariotipname,,"�-��������� ���. ����� ������������");
%eventan (&LN..tmp, Trel, i_rel, 0,F,&y,new_normkariotipname,,"�-��������� ���. ������������� �� ���������. ����������� �������� ��������"); *����������� �������� ��������;

/*�-��������� ���*/
data  &LN..tmp;
    set &LN..new_pt;
    if (oll_class = 2) then output;
run;

%eventan (&LN..tmp, TLive, i_death, 0,,&y,new_normkariotipname,,"T-��������� ���. ����� ������������");
%eventan (&LN..tmp, Trel, i_rel, 0,F,&y,new_normkariotipname,,"T-��������� ���. ������������� �� ���������. ����������� �������� ��������"); *����������� �������� ��������;

/*� ���������� ������ �� 35*/
/*data  &LN..tmp;*/
/*  set &LN..new_pt;*/
/*  if (age < 35) then output;*/
/*run;*/
/**/
/*%eventan (&LN..tmp, TLive, i_death, 0,,&y,d_ch,1.0,"� ���������� ������ �� 35");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,,&y,d_ch,1.0,"� ���������� ������ �� 35");*/
/*%eventan (&LN..tmp, TLive, i_death, 0,F,&y,d_ch,1.0,"� ���������� ������ �� 35");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,F,&y,d_ch,1.0,"� ���������� ������ �� 35");*/

/*� ���������� ������ ������ 35*/
/*data  &LN..tmp;*/
/*  set &LN..new_pt;*/
/*  if (age < 35) then output;*/
/*run;*/
/**/
/*%eventan (&LN..tmp, TLive, i_death, 0,,&y,d_ch,1.0,"� ���������� ������ ������ 35");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,,&y,d_ch,1.0,"� ���������� ������ ������ 35");*/
/*%eventan (&LN..tmp, TLive, i_death, 0,F,&y,d_ch,1.0,"� ���������� ������ ������35");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,F,&y,d_ch,1.0,"� ���������� ������ ������ 35");*/
/**/

/*������������� �� ��������*/
%eventan (&LN..new_pt, TLive, i_death, 0,,&y,age,age_group_f.,"������������� �� ��������. ����� ������������");
%eventan (&LN..new_pt, TRF, iRF, 0,,&y,age,age_group_f.,"������������� �� ��������. ������������� ������������");
%eventan (&LN..new_pt, Trel, i_rel, 0,F,&y,age,age_group_f.,"������������� �� ��������. ����������� �������� ��������"); *����������� �������� ��������;


*%eventan (&LN..new_pt, TLive, i_death, 0,F,&y,age,age_group_f.,"������������� �� ��������");
*%eventan (&LN..new_pt, TRF, iRF, 0,F,&y,age,age_group_f.,"������������� �� ��������");


/*data AYA;*/
/*	set &LN..new_pt;*/
/*	if age < 30 then output;*/
/*run;*/

/*data adult;*/

proc freq data = &LN..new_pt;
	table age;
	format age age_group_f.;
run;

/*-----------------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/
/*-------------------------------------------------- ������ �������  ----------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/

/*1. ��������� ��������� ����*/
/*2. ��������� ������*/
/*3. ������������ ����������*/
/*4. ������ ������������*/

/*data a;*/
/*	set &LN..new_pt;*/
/*	if Trel > 30 and oll_class = 2 then output;*/
/*/*	if pguid = "BF9718B0-AD79-E211-A54D-10000001B347" then output;*/*/
/*run;*/

/*proc print data = a;*/
/*run;*/





/*VVVVVVVVVVVVVVVVVVVVVVVVV   �� ���������    VVVVVVVVVVVVVVVVVVVVVVVVVV*/

/*data &LN..fr;*/
/*    set &LN..new_pt;*/
/*    if new_etap_protokol = 3 then output;*/
/*run;*/
/**/
/*proc means data=&LN..new_pt N median mean max min;*/
/*   var  new_blast_km;*/
/*   title '������� � ��';*/
/*run;*/
/**/
/**/
/*data &LN..fr;*/
/*    set &LN..new_pt;*/
/*    if new_etap_protokol = 3 AND new_blast_km > 5 then output;*/
/*run;*/
/**/
/*proc means data=&LN..fr N median mean max min;*/
/*   var  new_blast_km;*/
/*   title '������� � �� > 5%';*/
/*run;*/
/**/
/*proc freq data=&LN..fr;*/
/*    tables new_gendercodename*oll_class /nocum;*/
/*    title '������ ��������� �� �� 70 ���� �������';*/
/*run;*/
/**/
/*/*������������ ��� ����� � ���������*/*/
/**/
/*proc sort data=&LN..all_pr;*/
/*    by pguid;*/
/*run;*/
/**/
/*proc sort data=&LN..all_et;*/
/*    by pguid;*/
/*run;*/
/**/
/*data &LN..RoI;*/
/*    merge &LN..all_pr &LN..all_et ;*/
/*    by pguid;*/
/*run;*/
/**/
/*/*������� ���������� ������ 1-2 ������ ��������*/*/
/*data &LN..RoI;*/
/*    set &LN..RoI;*/
/*    by pguid;*/
/*    retain TP1-TP4 ;*/
/*    if first.pguid then do; TP1 = .; TP2 = .; TP3 = .; TP4 = .; end;*/
/*/*--------------------------------------------------*/*/
/*    if new_etap_protokol = 2 then do; TP1 = ph_b; TP2 = ph_e; end;*/
/*    if new_etap_protokol = 3 then do; TP3 = ph_b; TP4 = ph_e; end;*/
/*    if TP4 = . then TP4 = DATE();*/
/*/*---------------------------------------------------*/*/
/*    if last.pguid then*/
/*        do;*/
/*            output;*/
/*        TP1 = .; TP2 = .; TP3 = .; TP4 = .;*/
/*        end;*/
/*run;*/
/**/
/**/
/*/*���������� �������, ���������� ��������� �� ��� � �����������, ���������� �������*/*/
/**/
/*proc sort data=&LN..RoI;*/
/*    by pguid;*/
/*run;*/
/**/
/*proc sort data=&LN..all_ev;*/
/*    by pguid;*/
/*run;*/
/**/
/*data &LN..RoI;*/
/*    merge &LN..RoI &LN..all_ev ;*/
/*    by pguid;*/
/*run;*/
/**/
/*data &LN..RoI;*/
/*    set &LN..RoI;*/
/*    by pguid;*/
/*    retain event ev_date;*/
/*    if first.pguid then do; event = 4; ev_date = .; end;*/
/*/*--------------------------------------------------*/*/
/*    if TP1 <= new_event_date AND new_event_date <= TP4 then do;*/
/*        ev_date = new_event_date;*/
/*        if new_event in (1,2,3) then event = new_event;*/
/*        /*if new_event = 1 then do; event = 1 ; end; *������ ��������;*/
/*        if new_event = 2 then do; event = 2 ; end; *�������������;*/
/*        if new_event = 3 then do; event = 3 ; end; *������;*/
/*        */*/
/*    end;*/
/**else event = 4; *��������������;*/
/*/*---------------------------------------------------*/*/
/*    if last.pguid then*/
/*        do;*/
/*            output;*/
/*        event = .;*/
/*        ev_date = .;*/
/*        end;*/
/*run;*/
/*proc freq data=&LN..RoI;*/
/*    tables event*oll_class /nocum;*/
/*    title '��';*/
/*run;*/
/**/
/*data &LN..tmp;*/
/*	set &LN..All_pr;*/
/*	if new_ldh ne then; */
/*	do;*/
/*		if new_ldh > 400 then ldg = 1; else ldg = 0;*/
/*		output;*/
/*	end;*/
/*run;*/
/**/
/*proc freq data=&LN..tmp;*/
/*	tables ldg*oll_class /nocum;*/
/*run;*/
/*	*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,,&y,Laspot,,"� ����������� �� ������ L-�����������");*/
/**/
/**/

