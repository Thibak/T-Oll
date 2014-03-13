/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/*****************                                                                       *******************/
/****************                      Отчет по протоколу ОЛЛ-2009                        ******************/
/*****************                          Только по Т-ОЛЛ                              *******************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/*идентификатор компа*/ *D - sony, Z - ГНЦ;
*Без предефайна оказывается не работает;
%let disk = .;
%let lastname= .;
%macro what_OC;
%if &sysscpl = W32_7PRO %then 
	%do;
		%let disk = D; *sony;
	%end;
%if &sysscpl = X64_7PRO %then 
	%do;
		%let disk = Z; *работа;
	%end;
%mend;


/*определитель ОС*/
/*data comp;*/
/*	OC = "&sysscpl";*/
/*run;*/
/**/
/*proc print data = COMP;*/
/*run;*/
%what_OC;

%let LN = ALL2009; * имя библиотеки;
Libname &LN "&disk.:\AC\OLL-2009\SAS"; * Библиотека данных;
%let y = cl;
%let cens = (99, 132, 258, 264);

%macro Eventan(dat,T,C,i,s,cl,f,for, ttl);
/*
dat -имя набора данных,
T - время,
C - индекс события/цензурирования,
i=0, если с индекс события,
i=1, если с индекс цензурирования.
s = пусто,если строится кривая выживаемости
s = F, если строится кривая накопленной вероятности
cl = cl,если показывать доверительный интервал
cl = пусто,если не показывать доверительный интервал
s = F, если строится кривая накопленной вероятности
f = фактор (страта) ЕСЛИ ПУСТО ТО БЕЗ СТРАТЫ
for = формат (1.0 для целочисленных значаний, когда нет специального формата)
ttl = заголовок
*/

data _null_; set &dat;
   length tit1 $256 tit2 $256;
*чтение лейболов;
tit1=vlabel(&T);
%if &f ne %then %do; tit2=vlabel(&f);%end;
   * положили лейбала в макропеременную;
   call symput('tt1',tit1);
   call symput('tt2',tit2);
output;
   stop;
   keep tit1 tit2;
run;
title2 &ttl;
title3 " зависимая:  &tt1 // фактор       :  &tt2";
ods graphics on;
ods exclude WilHomCov LogHomCov HomStats  Quartiles ProductLimitEstimates; *;
proc lifetest data=&dat plots =(s( &s &cl))  method=pl ;
    %if &f ne %then %do; strata &f/test=logrank;
    id &f;format   &f &for;%end;
    time &T*&C(&i) ;
run;
ods graphics off;
%mend;

title1 "T-Oll";

proc format;
    value oc_f  1 = "B-клеточный" 2 = "T-клеточный" 3 = "Бифенотипический" 0 = "Неизвестен" ;
    value gender_f 1 = "Мужчины" 2 = "Женщины";
    value risk_f 1 = "Стандартная" 2 = "Высокая" 3 = "нет данных";
    value age_group_f low-30 = "до 30-ти лет" 30-high = "после 30-ти лет";
	value tkm_f 0="нет" 1="ауто" 2="алло";
	value it_f 1="есть" 0 = "нет";
	value time_error_f . = "нет ошибок" 
		0 = "дата последнего визита не заполнена" 
		1 = "дата последнего события (этапа) больше чем дата последнего контакта" 
		2 = "дата ремиссии больше даты последнего контакта" 
		3 = "дата рецедива больше даты последнего контакта";
/*	  if date_rem > lastdate then do; time_error = 2; lastdate = date_rem; end;*/
/*    if date_rel > lastdate then do; time_error = 3; lastdate = date_rel; end;*/
	value new_group_risk_f 1 = "стандартная" 2 = "высокая";
	value y_n 0 = "нет" 1 = "да";
	value au_al_f 1 = "ауто" 2 = "алло - родственная" ;
	value reg_f 0 = "Регионы" 1 = "ГНЦ"; 
run;

/*------------ препроцессинг восстановления реляций и целостности данных ---------------*/
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
		new_group_risk = "группа риска"
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
/*------ цензурирование, и вычисление производных показателей ----------*/


data cens;
	set &LN..all_pt;
	if pt_id in &cens then output;
run;

proc print data = cens split='*' N;
	var pt_id name;
	label pt_id = 'Номер пациента*в протоколе'
          name = 'Имя*в базе пациентов';
	title "Из базы принудительно исключены следующие записи" ;
run;

data null;
	set &LN..all_pt;
	if pt_id = . then output;
run;

proc print data = null split='*' N;
	var pt_id name;
	label pt_id = 'Номер пациента*в протоколе'
          name = 'Имя*в базе пациентов';
	title "В базе не имеют номера в протоколе" ;
run;

proc sort data=&LN..all_pt;
	by pt_id;
run;


/*----- очередная заплатка возраста. По данным ЕН обнавляем возраста, там где нет данных заклеиваем данными из базы*/
proc sort data=&LN..tmp_age;
	by pt_id;
run;

data &LN..all_pt; 
	merge &LN..all_pt &LN..tmp_age;
	by pt_id;
run;


data &LN..all_pt; *только по таблице пациентов;
    set &LN..all_pt;

	if new_group_risk = 3 then new_group_risk = .; * 3 -- код для "нет данных", что равноценно отсутствию данных!;



if age = . then age = floor(yrdif(new_birthdate, pr_b,'AGE'));  *если возраста нет в базе ЕН, то предположительно в базе АС дата рождения забита правильно;
    *FORMAT age 2.0;

/*-------------------*/

    /* тип лейкоза */
    select;
        when (new_oll_class in (1,2,3) )   oll_class = 1; /*B-OLL*/
        when (new_oll_class in (5,6,7,8) ) oll_class = 2; /*T-OLL*/
        when (new_oll_class = 99)  oll_class = 0; /*неизвестен*/
        when (new_oll_class = 9 )  oll_class = 3; /*бифенотипически*/
        otherwise;
    end;

/* ручное цензурирование данных*/
    if NOT (pt_id in &cens ) then output;
run;

*----------------------------------------------------------------------------------------------------;
*----------------------------------------------------------------------------------------------------;
*----------------------------------------------------------------------------------------------------;
*---------------------                Отделяем только Т-ОЛЛ                  ------------------------;
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


/*-----------------------------------блок парсинга событий на этапах----------------------*/
proc sort data=&LN..all_et;
    by pguid new_etap_protokol; *сортируем таблицу этапов по ID пациентов и по этапам протокола (в хронологическом порядке);
run;

proc sort data=&LN..all_pt;
    by pguid; *сортируем таблицу этапов по ID пациентов и по этапам протокола (в хронологическом порядке);
run;

/*Соединяем таблицы пациентов и этапов, определяем для кого из пациентов нет записи об этапах*/
data &LN..new_et;
    merge &LN..all_pt (in = i1) &LN..all_et (in = i2);
    by pguid;

    it1 = i1;
    it2 = i2;
run;

*убираем цензурированные записи;
data &LN..new_et;
	set &LN..new_et;
	if it1 ne 0;
run;



/*прочесываем созданную таблицу, для каждой последней записи загоняем смену на дексаметазон, и номер этапа. Последнюю выводим в датасет*/
data &LN..new_pt /*(keep=)*/;
    set &LN..new_et;
    by pguid;
    retain ec   d_ch faza time_error; *ec -- это количество этапов "свернутых";
    if first.pguid then do;  ec = 0; d_ch = 0; faza = .; time_error = .; end;
/*--------------------------------------------------*/
    if it2 then ec + 1;
	if lastdate = . then time_error = 0;

    if ph_b > lastdate and time_error = 0 then do; lastdate = ph_b; end; *Проверка на последнюю дату. ;
    if ph_b > lastdate then do; lastdate = ph_b; time_error = 1; end;
    if ph_e > lastdate and time_error = 0 then do; lastdate = ph_e; end;
	if ph_e > lastdate then do; lastdate = ph_e; time_error = 1; end;
	
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
        end;
	label d_ch = "Смена на дексаметазон";
run;





/*РЕПОРТИНГ ОБ ОШИБКАХ РЕЛЯЦИЯХ ПАЦИЕНТ-ЭТАП*/

proc sort data = &LN..error_ptVSet;
	by pt_id;
run;

data &LN..error_ptVSet;
	set &LN..new_et (keep = pt_id name name_e new_etap_protokolname it1 it2);
	if it1 ne it2 then output; 
run;

proc print data = &LN..error_ptVSet split='*' N obs="Номер*ошибки";
	var pt_id name name_e new_etap_protokolname it1 it2;
	label pt_id = 'Номер пациента*в протоколе'
          name = 'Имя*в базе пациентов'
          name_e = 'Имя*в базе этапов'
		  new_etap_protokolname = 'этап'
		  it1 = 'Запись*в базе пациентов' 
		  it2 = 'Запись* в базе этапов';
	title "Ошибки в базе (пара пациент - этап)" ;
	format  it1 it2 it_f. ; 
run;

/*----------------------------------------------------------------------------------------*/





/*-------------------------- подготовка переменных для событийного анализа ----------------------------*/

/*прошерстить таблицу событий и убрать все повторяющиеся, оставив только первые*/
proc sort data=&LN..all_ev;
    by pguid new_event new_event_date ;
run;



data &LN..all_ev_red;
	set &LN..all_ev;
	by pguid new_event new_event_date ;
	if first.new_event then output;
run;


/*Прицепляем события к пациентам. Нам нужны индикаторы и даты рецедива и смерти*/

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


/*  rel ремиссия = 1 */
/*  res резистентность = 2*/
/*  death Смерть = 3*/
/*  tkm ТКМ = 4*/
/*  rem рецедив = 5*/


/*--- генерируем индикаторы рецидива/ремиссии/смерти ---*/
data &LN..new_pt;
    set &LN..new_ev;
    by pguid;
    retain i_rem date_rem /**/ i_death date_death i_ind_death /**/i_tkm date_tkm tkm_au_al/**/ i_rel date_rel /**/ i_res date_res /**/ Laspot;
    if first.pguid then 
		do; 
			i_rel = 0; date_rel = .;  
			i_res = 0; date_res = .; 
			i_death = 0; date_death = .; i_ind_death = 0; 
			i_tkm = 0; date_tkm = .; tkm_au_al = 0;
			i_rem = 0; date_rem = .; 
			Laspot = 0; 
		end;
/*----------------------------------*/
    if new_event = 1 then do; i_rem = 1; date_rem = new_event_date; end;
	if new_event = 2 then do; i_res = 1; date_res = new_event_date; end;
    if new_event = 3 then do; i_death = 1; date_death = new_event_date; 
		if new_event_txt = "В индукции" then i_ind_death = 1; end;
	if new_event = 4 then do; i_tkm = 1; date_tkm = new_event_date;
			if new_event_txt = "ауто" then tkm_au_al = 1; 
			if new_event_txt = "алло - родственная" then tkm_au_al = 2;
			end;
    if new_event = 5 then do; i_rel = 1; date_rel = new_event_date; end;
	if new_aspor_otmena = 1 then laspot = 1;
/*---------------------------------*/
    if last.pguid then 
		do; 
			if ie1 = 1 and ie2 = 1 then  output; 
			i_rel = 0; date_rel = .; 
			i_res = 0; date_res = .; 
			i_death = 0; date_death = .; i_ind_death = 0; 
			i_tkm = 0; date_tkm = .; tkm_au_al = 0;
			i_rem = 0; date_rem = .; 
			Laspot = 0; 
		end;
run;

*убираем цензурированные записи;
data &LN..new_pt;
	set &LN..new_pt;
	if ie1 ne 0;
run;
	

/*поставить заплатку если время рецидива равно нулю то сегодняшняя дата <----------- ЕСТЬ ЛИ ЭТО????*/
/*обновление последнего контакта за счет смерти*/  
Data &LN..new_pt;
    set &LN..new_pt;
	if time_error = . then 
		do;
    	if date_rem > lastdate then time_error = 2;
    	if date_rel > lastdate then time_error = 3;
		end;

    if date_rem > lastdate then lastdate = date_rem; 
    if date_death ne .     then lastdate = date_death; 
    if date_rel > lastdate then lastdate = date_rel; 

	if i_death = 1 and time_error = 0 then time_error = .;
    /*ЗАПЛАТКА*/
    *lastdate = MDY(9,1,2013);
run;

/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

data &LN..error_timeline;
	set &LN..new_pt;
	if time_error ne . then output;
run;

/*Выживаемость*/
/*переводим в месяцы*/
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

/*Безрецедивная выживаемость*/
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

/*Смерть в индукции*/
/*отобрать индук*/

/*------ все проверки проведены, делаем вывод записей содержащих ошибки ------------*/

proc sort data = &LN..error_timeline;
	by pt_id;
run;


proc print data = &LN..error_timeline split='*' N;
	var pt_id name time_error;
	label pt_id = 'Номер пациента*в протоколе'
          name = 'Имя*в базе пациентов'
		  time_error = "Ошибки";
	title "ошибки заполнения таймлайна" ;
	footnote '*дата последнего визита обнавлена в соответствии с имеющейся информацией о лечении'; 
	format  it1 it2 it_f. time_error time_error_f. ; 
run;

/*-----------------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/
/*--------------------------------------------описательная статистика----------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/

/*1. Общее количество записей в регистре*/
/*2. Возраст (медиана, разброс)*/
/*3. Пол*/
/*4. Иммунофенотип:*/
/*	- неизвестен*/
/*	- B-клеточный (всего, процент)*/
/*		-- ранний пре-B (кол-во)*/
/*		-- common (кол-во)*/
/*		-- пре-B (кол-во)*/
/*	- T-клеточный (всего, процент)*/
/*		-- ранний 1/2 (кол-во)*/
/*		-- кортикальный (кол-во)*/
/*		-- зрелый (кол-во)*/
/*	- бифенотипическийъ*/

footnote " ";




proc means data = &LN..all_pt N;
	var new_birthdate;
   title 'Всего записей';
run;

proc means data = &LN..all_pt median max min ;
   var age;
   title 'Возраст больных (медиана, разброс)';
run;


proc freq data=&LN..all_pt ;
   tables new_gendercodename / nocum;
   title 'пол';
run;

proc sort data=&LN..all_pt;
	by new_oll_class;
run;

proc freq data=&LN..all_pt ORDER = DATA;
   tables new_oll_classname / nocum;
   title 'Иммунофенотип (детально)';
run;


proc freq data=ift ;
   tables oll_class / nocum;
   title 'Иммунофенотип';
   FORMAT oll_class oc_f.;
run;


/*==============================*/


/*proc freq data=&LN..all_pt ;*/
/*   tables*/
/*        new_citogenname*/
/*        / nocum;*/
/*   title 'Цитогенетика';*/
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
/*   title 'Цитогенетика';*/
/*run;*/
/**/
/*proc freq data=&LN..all_pr;*/
/*    by new_citogenname;*/
/*   tables*/
/*        new_normkariotipname*/
/*        / nocum;*/
/*   title 'Нормальный кариотип';*/
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
/*   title 'Другие анамолии';*/
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
/*   title 'Демографические показатели у больных';*/
/*   format oll_class oc_f.;*/
/*run;*/
/**/
/*proc means data = &LN..all_pr median mean max min ;*/
/*    by oll_class;*/
/*    var age;*/
/*   title 'Демографические показатели у больных';*/
/*   format oll_class oc_f.;*/
/*run;*/

/*----------- пропуск ------------*/

/*8. Распределения по группам риска*/
/*- группы риска (n = ?) по исходным параметрам*/
/*	-- высокого (всего, процент)*/
/*	-- низкого  (всего, процент)*/
/*- смена на дексаметазон*/
/*	-- да (всего, процент)*/

/*// предлагаю сделать в виде таблички 2х2 \\*/

/*9. результаты индукции */

/*(всего, процент)| все (n = ?)	| B-OLL (n = ?)	| T-OLL (n = ?)	|*/
/*-----------------------------------------------------------------*/
/*ПР		|		|		|		|*/
/*  после п/ф	|		|		|		|*/
/*  после 1 ф.	|		|		|		|*/
/*  после 2 ф.	|		|		|		|*/
/*-----------------------------------------------------------------*/
/*смерть в инд.	|		|		|		|*/
/*-----------------------------------------------------------------*/
/*резистентная ф.	|		|		|		|*/
/*-----------------------------------------------------------------*/

*---------- избыточная информация -----------------;
/*proc means data = &LN..all_pt N;*/
/*	var new_group_risk;*/
/*   title 'По группам риска всего информация о N пациентах';*/
/*run;*/
/**/
/*proc freq data=&LN..all_pt ;*/
/*   tables new_group_risk / nocum;*/
/*   title 'Группы риска ';*/
/*   format new_group_risk new_group_risk_f.;*/
/*run;*/
/*------------------------------------------------*/



/*Смена на дексаметазон */
/*факт смены вычеслен, смена всегда происходит на 7-ой день по протоколу (на предфазе)*/

proc freq data=&LN..new_pt ;
   tables  d_ch*new_group_risk/ nocum;
   title 'Смена на дексаметазон по группам риска';
   format new_group_risk new_group_risk_f. d_ch y_n.;
run;
proc freq data=&LN..new_pt ;
   tables  new_group_risk/ nocum;
   title 'Группы риска';
   format new_group_risk new_group_risk_f. d_ch y_n.;
run;
proc freq data=&LN..new_pt ;
   tables  d_ch/ nocum;
   title 'Смена на дексаметазон';
   format new_group_risk new_group_risk_f. d_ch y_n.;
run;



/*-----------------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/
/*---------------------------------------------- анализ выживаемости ----------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------------------------*/


/*------------------ общие показатели ----------------------*/
%eventan (&LN..new_pt, TLive, i_death, 0,,&y,,,"Общие показатели. Выживаемость"); *общая выживаемость;
%eventan (&LN..new_pt, TRF, iRF, 0,,&y,,,"Общие показатели. Безрецидивная выживаемость"); *безрецидивная выживаемость;
%eventan (&LN..new_pt, Trel, i_rel, 0,F,&y,,,"Общие показатели. Вероятность развития рецидива"); *вероятность развития рецидива;


*%eventan (&LN..new_pt, TLive, i_death, 0,F,&y,,,"Общие показатели");
*%eventan (&LN..new_pt, TRF, iRF, 0,F,&y,,,"Общие показатели");

/*пол*/
/*%eventan (&LN..new_pt, TLive, i_death, 0,,&y,new_gendercode,gender_f.,"пол");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,,&y,new_gendercode,gender_f.,"пол");*/
/*%eventan (&LN..new_pt, TLive, i_death, 0,F,&y,new_gendercode,gender_f.,"пол");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,F,&y,new_gendercode,gender_f.,"пол");*/

/*---------------- стратификация по фенотипам ----------------*/
data  &LN..tmp;
    set &LN..new_pt;
    if (oll_class in (1,2)) then output;
run;

%eventan (&LN..tmp, TLive, i_death, 0,,&y,oll_class,oc_f.,"стратификация по нозологиям. Выживаемость");
%eventan (&LN..tmp, TRF, iRF, 0,,&y,oll_class,oc_f.,"стратификация по нозологиям. Безрецидивная выживаемость");
%eventan (&LN..tmp, Trel, i_rel, 0,F,&y,oll_class,oc_f.,"Стратификация по нозологиям. Вероятность развития рецидива"); *вероятность развития рецидива;



/*---------------- стратификация по кариотипу -----------------*/

proc freq data = &LN..new_pt;
	table new_normkariotipname;
run;


%eventan (&LN..new_pt, TLive, i_death, 0,,&y,new_normkariotipname,,"Стратификация по кариотипу. Выживаемость");
%eventan (&LN..new_pt, TRF, iRF, 0,,&y,new_normkariotipname,,"Стратификация по кариотипу. Безрецидивная выживаемость");
%eventan (&LN..new_pt, Trel, i_rel, 0,F,&y,new_normkariotipname,,"Стратификация по кариотипу Вероятность развития рецидива"); *вероятность развития рецидива;



/*регион москва 21C015D6-BF19-E211-B588-10000001B347 or Москва г*/
data  tmp;
    set &LN..new_pt;
	reg = 0;
    if (ownerid = "51362F93-2C7B-E211-A54D-10000001B347") then reg=1; *Ахмерзаева Залина Хатаевна;
run;

proc freq data = tmp;
	table reg;
run;

%eventan (tmp, TLive, i_death, 0,,&y,reg,reg_f.,"ГНЦ vs регионы. Общая выживаемость");
%eventan (tmp, TRF, iRF, 0,,&y,reg,reg_f.,"ГНЦ vs регионы. Безрецидивная выживаемость");
%eventan (tmp, Trel, i_rel, 0,F,&y,reg,reg_f.,"ГНЦ vs регионы. Вероятность развития рецидива"); *вероятность развития рецидива;






