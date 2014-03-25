/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/*****************                                                                       *******************/
/****************                      ����� �� ��������� ���-2009                        ******************/
/*****************                          ������ �� �-���                              *******************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/*������������� �����*/ *D - sony, Z - ���;
*��� ���������� ����������� �� ��������;
%let disk = .;
%let lastname= .;
%macro what_OC;
%if &sysscpl = W32_7PRO %then 
	%do;
		%let disk = D; *sony;
	%end;
%if &sysscpl = X64_7PRO %then 
	%do;
		%let disk = Z; *������;
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
%let cens = (0);
*20, 27, 99, 132, 258, 264;

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
ods exclude WilHomCov LogHomCov HomStats  Quartiles ; *ProductLimitEstimates;
proc lifetest data=&dat plots =(s( &s &cl))  method=pl ;
    %if &f ne %then %do; strata &f/test=logrank;
    id &f;format   &f &for;%end;
    time &T*&C(&i) ;
run;
ods graphics off;
%mend;

title1 "T-Oll";

proc format;
    value oc_f  1 = "B-���������" 2 = "T-���������" 3 = "����������������" 0 = "����������" ;
    value gender_f 1 = "�������" 2 = "�������";
    value risk_f 1 = "�����������" 2 = "�������" 3 = "��� ������";
    value age_group_f low-30 = "�� 30-�� ���" 30-high = "����� 30-�� ���";
	value tkm_f 0="���" 1="����" 2="����";
	value it_f 1="����" 0 = "���";
	value time_error_f . = "��� ������" 
		0 = "���� ���������� ������ �� ���������" 
		1 = "���� ���������� ������� (�����) ������ ��� ���� ���������� ��������" 
		2 = "���� �������� ������ ���� ���������� ��������" 
		3 = "���� �������� ������ ���� ���������� ��������"
		4 = "date bmt > lastdate";

/*	  if date_rem > lastdate then do; time_error = 2; lastdate = date_rem; end;*/
/*    if date_rel > lastdate then do; time_error = 3; lastdate = date_rel; end;*/
	value new_group_risk_f 1 = "�����������" 2 = "�������";
	value y_n 0 = "���" 1 = "��";
	value au_al_f 1 = "����" 2 = "���� - �����������" ;
	value reg_f 0 = "�������" 1 = "���"; 
	value T_class12_f 0 = "T1+T2" 1 = "T3" 2 = "T4";
	value T_class124_f 0 = "T1+T2+T4" 1 = "T3";
	value TR_f 0 = "������ ��������" 1 = "������ � ��������" 2 = "������������ �����";
	value BMinv_f 0 = "��� ���������" 1 = "� ����������";
	value AAC_f 0 = "������������" 1 = "���� ���" 2 = "���� ���" 3 = "������ �������" 4 = "������ � ��������" 5 = "�� �������� (T < 5 ���)";
	value FRint_f 0 = "�� �� ������ ����" 1 = "�� �� 1-�� ���� ��������" 2 = "�� �� 2-�� ���� ��������";
	value BMT_f 0 = "������������" 1 = "���";
	value tkm_au_al_f 0 = "������������" 1="����-���" 2="����-���";
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
		ownerid = ownerid_et
		owneridname = owneridname_et	
		createdby = createdby_et
		createdbyname	= createdbyname_et
		createdon	= createdon_et
		Modifiedby	= Modifiedby_et
		Modifiedbyname	= Modifiedbyname_et
		Modifiedon = Modifiedon_et
        ;
		run;
data &LN..all_ev;
    set &LN..all_ev;
    rename
        new_protokol_oll = pguid
        new_protokol_ollname = name
		ownerid = ownerid_ev
		owneridname = owneridname_ev	
		createdby = createdby_ev
		createdbyname	= createdbyname_ev
		createdon	= createdon_ev
		Modifiedby	= Modifiedby_ev
		Modifiedbyname	= Modifiedbyname_ev
		Modifiedon = Modifiedon_ev
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
/*-- ���������� ������ �� &LN..rps --*/
proc sort data=&LN..tmp_age;
	by pt_id;
run;


proc sort data=&LN..rps;
	by pt_id;
run;

data &LN..all_pt; 
	merge &LN..all_pt &LN..tmp_age &LN..rps;
	by pt_id;
run;


data &LN..all_pt; *������ �� ������� ���������;
    set &LN..all_pt;

	if new_group_risk = 3 then new_group_risk = .; * 3 -- ��� ��� "��� ������", ��� ���������� ���������� ������!;



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

/*����������� ������*/


/* ������ �������������� ������*/
    if NOT (pt_id in &cens ) then output;
run;

*----------------------------------------------------------------------------------------------------;
*----------------------------------------------------------------------------------------------------;
*----------------------------------------------------------------------------------------------------;
*---------------------                �������� ������ �-���                  ------------------------;
*----------------------------------------------------------------------------------------------------;
*----------------------------------------------------------------------------------------------------;
*----------------------------------------------------------------------------------------------------;

data &LN..all_pt; 
	set &LN..all_pt;
	if (oll_class = 2);
run;

*----------------------------------------------------------------------------------------------------;
*----------------------------------------------------------------------------------------------------;
*----------------------------------------------------------------------------------------------------;


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

*������� ��������������� ������;
data &LN..new_et;
	set &LN..new_et;
	if it1 ne 0;
run;



/*����������� ��������� �������, ��� ������ ��������� ������ �������� ����� �� ������������, � ����� �����. ��������� ������� � �������*/
data &LN..new_pt /*(keep=)*/;
    set &LN..new_et;
    by pguid;
    retain ec d_ch faza time_error ind1bg ind1end ind2bg ind2end; *ec -- ��� ���������� ������ "���������";
    if first.pguid then 
		do;  
			ec = 0; 
			d_ch = 0; 
			faza = .; 
			time_error = .; 
			ind1bg = .; 
			ind1end = .; 
			ind2bg = .; 
			ind2end = .; 
		end;
/*--------------------------------------------------*/
    if it2 then ec + 1;
	if lastdate = . then time_error = 0;

    if ph_b > lastdate and time_error = 0 then do; lastdate = ph_b; end; *�������� �� ��������� ����. ;
    if ph_b > lastdate then do; lastdate = ph_b; time_error = 1; end;
    if ph_e > lastdate and time_error = 0 then do; lastdate = ph_e; end;
	if ph_e > lastdate then do; lastdate = ph_e; time_error = 1; end;
	
	if new_etap_protokol = 2 then do; ind1bg = ph_b; ind1end = ph_e; end;
	if new_etap_protokol = 3 then do; ind2bg = ph_b; ind2end = ph_e; end;

if new_smena_na_deksamet = 1 then
        do;
            d_ch = 1;
            faza = new_etap_protokol;
        end;
/*---------------------------------------------------*/
    if last.pguid then
        do;
			*if time_error ne . then output &LN..error_timeline;

            output &LN..new_pt;
            d_ch = 0;
            faza = .;
			time_error = .;
			ind1bg = .; 
			ind1end = .; 
			ind2bg = .; 
			ind2end = .; 
        end;
	label d_ch = "����� �� ������������";
run;

data &LN..new_pt;
	set &LN..new_pt;
			if (ind1bg  = .) then ind1bg  = pr_b + 7; 
			if (ind1end = .) then ind1end = ind1bg + 36;
			if (ind2bg  = .) then ind2bg  = ind1end;
			if (ind2end = .) then ind2end = ind1bg + 70;
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
    merge &LN..new_pt (in = i1) &LN..all_ev_red(in = i2) ;
    by pguid;

    ie1 = i1;
    ie2 = i2;
run;

proc sort data=&LN..new_ev;
    by pguid;
run;

/*  rem �������� = 1 */
/*  res �������������� = 2*/
/*  death ������ = 3*/
/*  tkm ��� = 4*/
/*  rel ������� = 5*/


/*--- ���������� ���������� ��������/��������/������ ---*/
data &LN..new_pt;
    set &LN..new_ev;
    by pguid;
    retain i_rem date_rem FRint /**/ i_death date_death i_ind_death /**/i_tkm date_tkm tkm_au_al/**/ i_rel date_rel /**/ i_res date_res /**/ Laspot;
    if first.pguid then 
		do; 
			i_rem = 0; date_rem = .; FRint = .; 
			i_res = 0; date_res = .; 
			i_death = 0; date_death = .; i_ind_death = 0; 
			i_tkm = 0; date_tkm = .; tkm_au_al = 0;
			i_rel = 0; date_rel = .;
			Laspot = 0; 
		end;
/*----------------------------------*/
    if new_event = 1 then 
		do; 
			i_rem = 1; 
			date_rem = new_event_date; 

			*���� ��� ���� ������ �������, ������������, ��� ��� ���� �� ����������;


			select;
				when (ind1bg-10 <= date_rem <= ind1end+15) FRint = 1; *��������� �����;
				*when (ind1bg-2 <= date_rem <= ind2bg +2 /*ind1end*/) FRint = 1; *��������� �����;
				when (ind2bg+15   <= date_rem <= ind2end+2) FRint = 2;  
				otherwise FRint = 0;
			end;
		end;
	if new_event = 2 then do; i_res = 1; date_res = new_event_date; end;
    if new_event = 3 then do; i_death = 1; date_death = new_event_date; end;
	 if new_event_txt = "� ��������" then i_ind_death = 1; 
	if new_event = 4 then do; i_tkm = 1; date_tkm = new_event_date; end;
	 if new_event_txt = "����" then tkm_au_al = 1; 
	 if new_event_txt in ("���� - �����������","���� - �������������")  then tkm_au_al = 2;
    if new_event = 5 then do; i_rel = 1; date_rel = new_event_date; end;
	if new_aspor_otmena = 1 then laspot = 1;
/*---------------------------------*/
    if last.pguid then 
		do; 
			if ie1 ne 0 then  output; *<-----------------------;
			i_rem = 0; date_rem = .; FRint = .;
			i_res = 0; date_res = .; 
			i_death = 0; date_death = .; i_ind_death = 0; 
			i_tkm = 0; date_tkm = .; tkm_au_al = 0;
			i_rel = 0; date_rel = .;
			Laspot = 0; 
		end;
run;

*������� ��������������� ������;
data &LN..new_pt;
	set &LN..new_pt;
	if ie1 ne 0;
run;
	

/*��������� �������� ���� ����� �������� ����� ���� �� ����������� ���� <----------- ���� �� ���????*/
/*���������� ���������� �������� �� ���� ������*/  
Data &LN..new_pt;
    set &LN..new_pt;
	if time_error = . then 
		do;
    	if date_rem > lastdate then time_error = 2;
    	if date_rel > lastdate then time_error = 3;
		if date_tkm > lastdate then time_error = 4;
		end;

    if date_rem > lastdate then lastdate = date_rem; 
    if date_rel > lastdate then lastdate = date_rel;
	if date_tkm > lastdate then lastdate = date_tkm;
	if date_death ne .     then lastdate = date_death; 

	if i_death = 1 and time_error = 0 then time_error = .;

run;

/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

data &LN..error_timeline;
	set &LN..new_pt;
	if time_error ne . then output;
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

	if (i_tkm) then Ttkm = (date_tkm - date_rem)/30;
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

*���������� ����� ������;

Data &LN..new_pt;
    set &LN..new_pt;
    select (new_oll_class);
        when (5) do; T_class12 = 0 ; T_class124 = 0 ; end;  *T1;
		when (6) do; T_class12 = 0 ; T_class124 = 0 ; end; *T2;
		when (7) do; T_class12 = 1 ; T_class124 = 1; end; *T3;
		when (8) do; T_class12 = 2 ; T_class124 = 0; end; *T4;
        otherwise;
    end;
	
	Select; 
		when (blast_km => 5) BMinv = 1; 
		when (blast_km = .) BMinv = .;
		when (blast_km  < 5) BMinv = 0;

		otherwise;
	end; 

	*���������� ������� ������ � ��������;

	if i_rel = 0 and i_death = 1 and i_rem = 1 then rem_death = 1; else rem_death = 0; 

	*if (new_blast_km = .) then BMinv = .;

	label T_class12  = "������� ��� ";
	label T_class124 = "������� ��� ";
	label BMinv = "��������� �������� �����";

run;

*---------        ����� �������         ---------;

Data &LN..new_pt;
    set &LN..new_pt;
    Select;
        when (i_rem)       do; TR = 0; TR_date = date_rem;   end;
        when (i_res)       do; TR = 1; TR_date = date_res;   end;
        when (i_ind_death) do; TR = 2; TR_date = date_death; end;
        otherwise;
    end;
run;

*---------        ����/����/����         ---------;

*value AAC 0 = "������������" 1 = "���� ���" 2 = "���� ���" 3 = "������ �������" 4 = "������ � ��������" 5 = "�� �������� (T < 5 ���)";



data   &LN..new_pt;
    set &LN..new_pt;
	reg = 0;
    if (ownerid = "51362F93-2C7B-E211-A54D-10000001B347") then reg=1; *���������� ������ ��������;
	select (tkm_au_al);
		when (1,2) BMT = 1;
		when (0) BMT = 0;
		otherwise;
	end;
	label	BMT = "��� vs ������������"
			reg = "��� ����������� �������";
	
run;


data &LN..NLM;
	set &LN..new_pt;
	if not(TRF > 6 or tkm_au_al in (1,2));
	if pr_b > mdy(08,01,13) then onT = 1; else onT = 0;
run;

data &LN..LM;
	set &LN..new_pt;

	if TRF > 6 or tkm_au_al in (1,2);

	select (tkm_au_al);
		when (0) 
			do;
				TRF_LM = TRF - 6;
				TLive_LM = TLive - 6;
				Trel_LM = Trel - 6;
			end;
		when (1,2) 
			do;
				TRF_LM = TRF - Ttkm;
				TLive_LM = TLive - Ttkm;
				Trel_LM = Trel - Ttkm;
			end;
		otherwise;
	end;
run; 

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
   tables age / nocum;
   title '�������, ������';
   format age age_group_f.;
run;

proc freq data=&LN..all_pt ;
   tables new_gendercodename / nocum;
   title '���';
run;



proc sort data=&LN..all_pt;
	by new_oll_class;
run;

proc means data = &LN..new_pt median max min ;
   var Ttkm;
   title '������� ���. ���. �� ��� (�������, �������)';
run;
proc freq data=&LN..all_pt ORDER = DATA;
   tables new_oll_classname / nocum;
   title '������������� (��������)';
run;


/*proc freq data=ift ;*/
/*   tables oll_class / nocum;*/
/*   title '�������������';*/
/*   FORMAT oll_class oc_f.;*/
/*run;*/

proc freq data=&LN..new_pt ORDER = DATA;
   tables TR / nocum;
   title '���������� �������';
   format TR TR_f.;
run;

proc freq data=&LN..LM ORDER = DATA;
   tables TR / nocum;
   title '���������� ������� (��������)';
   format TR TR_f.;
run;

proc freq data=&LN..NLM ORDER = DATA;
   tables TR / nocum;
   title '���������� (��������)';
   format TR TR_f.;
run;

proc freq data=&LN..NLM ORDER = DATA;
   tables onT / nocum;
   title '���������� (��������) �� �������';
   format TR TR_f.;
run;

/*proc freq data=&LN..new_pt ;*/
/*   tables TR*T_class12/ nocum;*/
/*   title '���������� ������������ �������';*/
/*   format T_class12 T_class12_f. TR TR_f.;*/
/*run;*/
/**/
/*proc freq data=&LN..new_pt ;*/
/*   tables new_normkariotipname*T_class12/ nocum;*/
/*   title '����������� ��������';*/
/*   format T_class12 T_class12_f.;*/
/*run;*/
/**/
/*proc freq data=&LN..new_pt ;*/
/*   tables BMinv*T_class12/ nocum;*/
/*   title '��������� �/�';*/
/*   format T_class12 T_class12_f. BMinv BMinv_f.;*/
/*run;*/
*--------------------------------------------------------------------------;
*-------------------     ������������� ����������    ----------------------;
*-------------------              ��������           ----------------------;
*--------------------------------------------------------------------------;

proc freq data=&LN..LM;
   tables tkm_au_al/ nocum;
   title '����-���/����-���/�� (��������)';
   format tkm_au_al tkm_au_al_f. ;
run;


proc freq data=&LN..LM;
   tables tkm_au_al*d_ch/ nocum;
   title '����-���/����-���/�� X ����� �� ������������ (��������)';
   format tkm_au_al tkm_au_al_f. ;
run;

proc freq data=&LN..LM;
   tables tkm_au_al*FRint/ nocum;
   title '����-���/����-���/�� � �� ����� ���� �������� (��������)';
   format tkm_au_al tkm_au_al_f. FRint FRint_f.;
run;
 
data tmp;
	set &LN..LM;
	if tkm_au_al in (0,1);
run; 

proc freq data=tmp;
   tables T_class12*tkm_au_al/ nocum;
   title '����-���/�� X ������� ��� (��������)';
   format tkm_au_al tkm_au_al_f. T_class12 T_class12_f.;
run;

proc freq data=tmp;
   tables BMinv*tkm_au_al/ nocum;
   title '����-���/�� � ��������� �� (��������)';
   format tkm_au_al tkm_au_al_f. BMinv BMinv_f.;
run;

proc freq data=&LN..LM;
   tables BMinv*tkm_au_al/ nocum;
   title '��� ������� � ��������� �� (��������)';
   format tkm_au_al tkm_au_al_f. BMinv BMinv_f.;
run;

proc freq data=tmp;
   tables new_normkariotip*tkm_au_al/ nocum;
   title '����-���/�� � ����������� �������� (��������)';
   format tkm_au_al tkm_au_al_f. new_normkariotip y_n.;
run;

proc freq data=tmp;
   tables new_neyrolek*tkm_au_al/ nocum;
   title '����-���/�� � ��������� ��� (��������)';
   format tkm_au_al tkm_au_al_f. new_neyrolek y_n.;
run;

proc freq data=tmp;
   tables  new_group_risk*tkm_au_al/ nocum;
   title '����-���/�� � ������ ����� (��������)';
   format tkm_au_al tkm_au_al_f. new_group_risk new_group_risk_f.;
run;

proc freq data=tmp;
   tables  d_ch*tkm_au_al/ nocum;
   title '����-���/�� � ����� �� ������������ (��������)';
   format tkm_au_al tkm_au_al_f. d_ch y_n.;
run;
 
proc freq data=tmp;
   tables  FRint*tkm_au_al/ nocum;
   title '����-���/�� � �� �� ����� ���� (��������)';
   format tkm_au_al tkm_au_al_f. FRint FRint_f.;
run;

proc sort data=&LN..LM;
	by tkm_au_al;
run;

proc means data = &LN..LM median max min ;
	by tkm_au_al;
   var Ttkm;
   title '������� ���. ���. �� ��� (�������, �������) (��������)';
      format tkm_au_al tkm_au_al_f. ;
run;

proc means data=&LN..all_pt n median max min ;
	var age new_hb	new_l	new_tp	blast_km	new_blast_pk	new_creatinine	new_bilirubin	new_ldh	new_albumin	new_protromb_ind	new_dlin_rs	new_poperech_rs;
	title "����� ������������ ����������";
run;

/*proc sort data=&LN..all_pt;*/
/*	by new_oll_classname;*/
/*run;*/
/**/
/*proc means data=&LN..all_pt n median max min ;*/
/*	by new_oll_classname;*/
/*	var age new_hb	new_l	new_tp	blast_km	new_blast_pk	new_creatinine	new_bilirubin	new_ldh	new_albumin	new_protromb_ind	new_dlin_rs	new_poperech_rs;*/
/*	title "������������ ���������� �� ���� �������";*/
/*run;*/
/*proc freq data=&LN..all_pt ;*/
/*   tables  * new_oll_classname / nocum;*/
/*   title '����������� ���������� �� ���� �������';  */
/**/
/*run;*/

/*new_neyrolekname	������������� (����������� ����������)*/
/*new_splenomegname	������������� (����������� ����������)*/
/*new_gepatomegname	������������� (����������� ����������)*/
/*new_uvsredostenname	���������� ����������� (����������� ����������)*/
/*new_inf_donow_tername	�������� �� ������ ������� (����������� ����������)*/
/*new_gemorag_sindrname	��������������� ������� (����������� ����������)*/
/*new_peref_uluname	�������������� (���������� ���. �����)*/
/*new_vnutrigrud_uluname	������������� (���������� ���. �����)*/
/*new_abdomi_uluname	������������� (���������� ���. �����)*/
/*new_razmer_limfouzlov	������ (���������� ���. �����)*/
/*new_ekstramodname	����������������� �����*/
/*new_skin_eoname	���� (����������������� �����)*/
/*new_gonad_eoname	������� (����������������� �����)*/
/*new_testis_eoname	����� (����������������� �����)*/
/*new_intratumor_eoname	���������� (����������������� �����)*/
/*new_other_eo	������ ����������������� �����*/
/**/


/*proc sort data=&LN..new_pt;*/
/*	by T_class12;*/
/*run;*/
/**/
/*proc means data=&LN..new_pt n median max min ;*/
/*	by T_class12;*/
/*	var age new_hb	new_l	new_tp	blast_km	new_blast_pk	new_creatinine	new_bilirubin	new_ldh	new_albumin	new_protromb_ind	new_dlin_rs	new_poperech_rs;*/
/*	title "������������ ���������� �� ������������ �������";*/
/*	format T_class12 T_class12_f.;*/
/*run;*/


proc sort data=&LN..LM;
	by tkm_au_al;
run;

proc means data=&LN..LM n median max min ;
	by tkm_au_al;
	var age new_hb	new_l	new_tp	blast_km	new_blast_pk	new_creatinine	new_bilirubin	new_ldh	new_albumin	new_protromb_ind	new_dlin_rs	new_poperech_rs;
	title "(��������) ��������� ������������ ���������� �� ���� �������";
	format tkm_au_al tkm_au_al_f.;
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



/*-----------------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/
/*---------------------------------------------- ������ ������������ ----------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/


/*------------------ ����� ���������� ----------------------*/
%eventan (&LN..new_pt, TLive, i_death, 0,,&y,,,"����� ����������. ������������"); *����� ������������;
%eventan (&LN..new_pt, TRF, iRF, 0,,&y,,,"����� ����������. ������������� ������������"); *������������� ������������;
%eventan (&LN..new_pt, Trel, i_rel, 0,F,&y,,,"����� ����������. ����������� �������� ��������"); *����������� �������� ��������;



%eventan (&LN..new_pt, TLive, i_death, 0,,&y,T_class12,T_class12_f.,"������������� �� ��������� �-���. ������������");
%eventan (&LN..new_pt, TRF, iRF, 0,,&y,T_class12,T_class12_f.,"������������� �� ��������� �-���. ������������� ������������");
%eventan (&LN..new_pt, Trel, i_rel, 0,F,&y,T_class12,T_class12_f.,"������������� �� ��������� �-���. ����������� �������� ��������"); *����������� �������� ��������;

/*%eventan (&LN..new_pt, TLive, i_death, 0,,&y,new_gendercodename,,"������������� �� ����. ������������");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,,&y,new_gendercodename,,"������������� ��  ����. ������������� ������������");*/
/*%eventan (&LN..new_pt, Trel, i_rel, 0,F,&y,new_gendercodename,,"������������� ��  ����. ����������� �������� ��������"); *����������� �������� ��������;*/



/*---------------- ������������� �� ��������� -----------------*/

/*proc freq data = &LN..new_pt;*/
/*	table new_normkariotipname;*/
/*run;*/
/**/
/**/
/*%eventan (&LN..new_pt, TLive, i_death, 0,,&y,new_normkariotipname,,"������������� �� ���������. ������������");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,,&y,new_normkariotipname,,"������������� �� ���������. ������������� ������������");*/
/*%eventan (&LN..new_pt, Trel, i_rel, 0,F,&y,new_normkariotipname,,"������������� �� ��������� ����������� �������� ��������"); *����������� �������� ��������;*/


*---- ������������ �� �������� -----;
/*������ ������ 21C015D6-BF19-E211-B588-10000001B347 or ������ �*/
/*proc freq data = &LN..new_pt;*/
/*	table reg;*/
/*run;*/
/**/
/*proc freq data = &LN..LM;*/
/*	table reg*BMT/ nocum;*/
/*	title "������ ������� �� �������� (��������)";*/
/*	format reg reg_f. BMT BMT_f.;*/
/*run;*/
/**/
/*%eventan (&LN..new_pt, TLive, i_death, 0,,&y,reg,reg_f.,"��� vs �������. ����� ������������");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,,&y,reg,reg_f.,"��� vs �������. ������������� ������������");*/
/*%eventan (&LN..new_pt, Trel, i_rel, 0,F,&y,reg,reg_f.,"��� vs �������. ����������� �������� ��������"); *����������� �������� ��������;*/
/**/
/*%eventan (&LN..LM, TLive_LM, i_death, 0,,&y,reg,reg_f.,"��������. ��� vs �������. ����� ������������");*/
/*%eventan (&LN..LM, TRF_LM, iRF, 0,,&y,reg,reg_f.,"��������. ��� vs �������. ������������� ������������");*/
/*%eventan (&LN..LM, Trel_LM, i_rel, 0,F,&y,reg,reg_f.,"��������. ��� vs �������. ����������� �������� ��������"); *����������� �������� ��������;*/
/**/
/*data tmp;*/
/*	set &LN..new_pt;*/
/*	if reg = 1;*/
/*run;*/
/**/
/*data tmp2;*/
/*	set &LN..LM;*/
/*	if reg = 1;*/
/*run;*/
/**/
/*%eventan (tmp, TLive, i_death, 0,,&y,tkm_au_al, tkm_au_al_f.,"���. ����� ������������");*/
/*%eventan (tmp, TRF, iRF, 0,,&y,tkm_au_al, tkm_au_al_f.,"���. ������������� ������������");*/
/*%eventan (tmp, Trel, i_rel, 0,F,&y,tkm_au_al, tkm_au_al_f.,"���. ����������� �������� ��������"); */
/**/
/*%eventan (tmp2, TLive_LM, i_death, 0,,&y,tkm_au_al, tkm_au_al_f.,"��������. ���. ������������� �� ���� �������. ����� ������������");*/
/*%eventan (tmp2, TRF_LM, iRF, 0,,&y,tkm_au_al, tkm_au_al_f.,"��������. ���. ������������� �� ���� �������. ������������� ������������");*/
/*%eventan (tmp2, Trel_LM, i_rel, 0,F,&y,tkm_au_al, tkm_au_al_f.,"��������. ���. ������������� �� ���� �������. ����������� �������� ��������");*/
/**/
/*%eventan (tmp2, TLive_LM, i_death, 0,,&y,BMT, BMT_f.,"��������. ���. ������������� �� ���� �������. ����� ������������");*/
/*%eventan (tmp2, TRF_LM, iRF, 0,,&y,BMT, BMT_f.,"��������. ���. ������������� �� ���� �������. ������������� ������������");*/
/*%eventan (tmp2, Trel_LM, i_rel, 0,F,&y,BMT, BMT_f.,"��������. ���. ������������� �� ���� �������. ����������� �������� ��������");*/
/**/
/**/
/*%eventan (tmp, TLive, i_death, 0,,&y,FRint, FRint_f.,"���. ������������� �� ��. ����� ������������");*/
/*%eventan (tmp, TRF, iRF, 0,,&y,FRint, FRint_f.,"���. ������������� �� ��. ������������� ������������");*/
/*%eventan (tmp, Trel, i_rel, 0,F,&y,FRint, FRint_f.,"���. ������������� �� ��. ����������� �������� ��������");*/
/**/
/*%eventan (tmp, TLive, i_death, 0,,&y,FRint, FRint_f.,"���. ������������� �� ��. ����� ������������");*/
/*%eventan (tmp, TRF, iRF, 0,,&y,FRint, FRint_f.,"���. ������������� �� ��. ������������� ������������");*/
/*%eventan (tmp, Trel, i_rel, 0,F,&y,FRint, FRint_f.,"���. ������������� �� ��. ����������� �������� ��������");*/
/**/
/*data tmp;*/
/*	set &LN..new_pt;*/
/*	if reg = 0;*/
/*run;*/
/**/
/*data tmp2;*/
/*	set &LN..LM;*/
/*	if reg = 0;*/
/*run;*/
/**/
/*%eventan (tmp, TLive, i_death, 0,,&y,tkm_au_al, tkm_au_al_f.,"�������. ����� ������������");*/
/*%eventan (tmp, TRF, iRF, 0,,&y,tkm_au_al, tkm_au_al_f.,"�������. ������������� ������������");*/
/*%eventan (tmp, Trel, i_rel, 0,F,&y,tkm_au_al, tkm_au_al_f.,"�������. ����������� �������� ��������"); */
/**/
/*%eventan (tmp2, TLive_LM, i_death, 0,,&y,tkm_au_al, tkm_au_al_f.,"��������. �������. ������������� �� ���� �������. ����� ������������");*/
/*%eventan (tmp2, TRF_LM, iRF, 0,,&y,tkm_au_al, tkm_au_al_f.,"��������. �������. ������������� �� ���� �������. ������������� ������������");*/
/*%eventan (tmp2, Trel_LM, i_rel, 0,F,&y,tkm_au_al, tkm_au_al_f.,"��������. �������. ������������� �� ���� �������. ����������� �������� ��������");*/
/**/
/*%eventan (tmp2, TLive_LM, i_death, 0,,&y,BMT, BMT_f.,"��������. �������. ������������� �� ���� �������. ����� ������������");*/
/*%eventan (tmp2, TRF_LM, iRF, 0,,&y,BMT, BMT_f.,"��������. �������. ������������� �� ���� �������. ������������� ������������");*/
/*%eventan (tmp2, Trel_LM, i_rel, 0,F,&y,BMT, BMT_f.,"��������. �������. ������������� �� ���� �������. ����������� �������� ��������");*/

*---- LM �������� -----;

/*%eventan (&LN..LM, TLive_LM, i_death, 0,,&y,tkm_au_al, tkm_au_al_f.,"�������� ������. ����� ������������");*/
/*%eventan (&LN..LM, TRF_LM, iRF, 0,,&y,tkm_au_al, tkm_au_al_f.,"�������� ������. ������������� ������������");*/
/*%eventan (&LN..LM, Trel_LM, i_rel, 0,F,&y,tkm_au_al, tkm_au_al_f.,"�������� ������. ����������� �������� ��������"); */
/**/
/*%eventan (&LN..LM, TLive_LM, i_death, 0,,&y,FRint, FRint_f.,"�������� ������. ������������� �� ��. ����� ������������");*/
/*%eventan (&LN..LM, TRF_LM, iRF, 0,,&y,FRint, FRint_f.,"�������� ������. ������������� �� ��. ������������� ������������");*/
/*%eventan (&LN..LM, Trel_LM, i_rel, 0,F,&y,FRint, FRint_f.,"�������� ������. ������������� �� ��. ����������� �������� ��������");*/
/**/
/*%eventan (&LN..LM, TLive_LM, i_death, 0,,&y, BMT, BMT_f.,"�������� ������. ��� vs ������������. ����� ������������");*/
/*%eventan (&LN..LM, TRF_LM, iRF, 0,,&y,BMT, BMT_f.,"�������� ������. ��� vs ������������. ������������� ������������");*/
/*%eventan (&LN..LM, Trel_LM, i_rel, 0,F,&y,BMT, BMT_f.,"�������� ������. ��� vs ������������. ����������� �������� ��������"); */
/**/

*---- ������ ��� �� -----;
data tmp;
	set &LN..new_pt;
	if tkm_au_al = 0;
run;

data tmp2;
	set &LN..LM;
	if tkm_au_al = 0;
run;
%eventan (tmp2, TRF_LM, iRF, 0,,&y,,,"������������. �������� ������. ������������� ������������");


/*%eventan (tmp2, TLive_LM, i_death, 0,,&y,FRint, FRint_f.,"������������. �������� ������. ������������� �� ��. ����� ������������");*/
%eventan (tmp2, TRF_LM, iRF, 0,,&y,FRint, FRint_f.,"������������. �������� ������. ������������� �� ��. ������������� ������������");
/*%eventan (tmp2, Trel_LM, i_rel, 0,F,&y,FRint, FRint_f.,"������������. �������� ������. ������������� �� ��. ����������� �������� ��������");*/


/*%eventan (tmp2, TLive, i_death, 0,,&y,T_class12,T_class12_f.,"������������. �������� ������. ������������� �� ��������� �-���. ����� ������������");*/
%eventan (tmp2, TRF, iRF, 0,,&y,T_class12,T_class12_f.,"������������. �������� ������. ������������� �� ��������� �-���. ������������� ������������");
/*%eventan (tmp2, Trel, i_rel, 0,F,&y,T_class12,T_class12_f.,"������������. �������� ������. ������������� �� ��������� �-���. ����������� �������� ��������");*/

/*%eventan (tmp2, TLive, i_death, 0,,&y,T_class12,T_class12_f.,"������������. �������� ������. ������������� �� ��������� �-���. ����� ������������");*/
%eventan (tmp2, TRF, iRF, 0,,&y,T_class12,T_class12_f.,"������������. �������� ������. ������������� �� ��������� �-���. ������������� ������������");
/*%eventan (tmp2, Trel, i_rel, 0,F,&y,T_class12,T_class12_f.,"������������. �������� ������. ������������� �� ��������� �-���. ����������� �������� ��������");*/


/*%eventan (tmp, TLive, i_death, 0,,&y,reg, reg_f.,"������������. ����� ������������");*/
/*%eventan (tmp, TRF, iRF, 0,,&y,reg, reg_f.,"������������.   ������������� ������������");*/
/*%eventan (tmp, Trel, i_rel, 0,F,&y,reg, reg_f.,"������������.   ����������� �������� ��������");*/


*------- phreg -------;
/*proc phreg data=a; 
	model �����*���������_��������������(0)= ������1 ������2; 
run; */

/*proc phreg data=&LN..LM; */
/*	model TLive_LM*i_death(0)=BMT reg; */
/*	title "��������.  ����� ������������";*/
/*run; */
/**/
/*proc phreg data=&LN..LM; */
/*	model TRF_LM*iRF(0)= BMT reg; */
/*	title "��������. ������������� ������������";*/
/*run; */
/**/
/*proc phreg data=&LN..LM; */
/*	model Trel_LM*i_rel(0)= BMT reg; */
/*	title "��������. ����������� �������� ��������";*/
/*run; */


/**/
/*proc sort  data = &LN..LM;*/
/*	by FRint;*/
/*run;*/
/*proc print data = &LN..new_pt;*/
/*	var pt_id name FRint Ttkm TR;*/
/*	format FRint FRint_f.;*/
/*	title "��������. ����������� �������� ��������";*/
/*run;*/

proc sort data = &LN..NLM;
	by pr_b;
run;

proc print data = &LN..NLM;
	var pt_id name FRint Ttkm TR i_death i_rel pr_b rem_death;
	format FRint FRint_f. TR TR_f.;
	title "��������. ����������";
run;

data tmp2;
	set &LN..LM;
	if tkm_au_al in (0,1);
run;

/*%eventan (tmp2, TLive_LM, i_death, 0,,&y,tkm_au_al, tkm_au_al_f.,"�������� ������. ����� ������������");*/
%eventan (tmp2, TRF_LM, iRF, 0,,&y, tkm_au_al, tkm_au_al_f.,"�������� ������. ������������� ������������");
/*%eventan (tmp2, Trel_LM, i_rel, 0,F,&y,tkm_au_al, tkm_au_al_f.,"�������� ������. ����������� �������� ��������");*/

data tmp;
	set &LN..new_pt;
	if rem_death = 1;
	title "������ � ��������";
run;

proc print data = tmp;
var pt_id name TR i_death i_rel i_rem rem_death;
run;


data tmp2;
	set &LN..LM;
	if tkm_au_al = 0;
run;


proc freq data=tmp2;
   tables d_ch/ nocum;
   title '�� -- ����� �� ������������ (��������)';
run;

proc freq data=tmp2;
   tables FRint/ nocum;
   title '�� -- �� ����� ���� �������� (��������)';
run;
 

proc freq data=tmp2;
   tables T_class12/ nocum;
   title '�� -- ������� ��� (��������)';
run;

proc freq data=tmp2;
   tables BMinv/ nocum;
   title '�� -- ��������� �� (��������)';
run;


proc freq data=tmp2;
   tables new_normkariotip/ nocum;
   title '�� -- ����������� �������� (��������)';
   format new_normkariotip y_n.;
run;

proc freq data=tmp2;
   tables new_neyrolek/ nocum;
   title '�� -- ��������� ��� (��������)';
   format  new_neyrolek y_n.;
run;

proc freq data=tmp2;
   tables  new_group_risk/ nocum;
   title '�� -- ������ ����� (��������)';
   format new_group_risk new_group_risk_f.;
run;


