/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/*****************                                                                       *******************/
/****************                      Отчет по протоколу ОЛЛ-2009                        ******************/
/*****************                                                                       *******************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/
/***********************************************************************************************************/

Libname &LN "Z:\AC\OLL-2009\SAS"; * Библиотека данных;
%let y = cl;
%let cens = (99, 132, 258, 264)

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
title1 &ttl;
title2 " зависимая:  &tt1 // фактор       :  &tt2";
ods graphics on;
ods exclude WilHomCov LogHomCov HomStats ProductLimitEstimates Quartiles;
proc lifetest data=&dat plots =(s( &s &cl))  method=pl ;
    %if &f ne %then %do; strata &f/test=logrank;
    id &f;format   &f &for;%end;
    time &T*&C(&i) ;
run;
ods graphics off;
%mend;



proc format;
    value oc_f  1 = "Т-клеточный" 2 = "B-клеточный" 3 = "Бифенотипический" 0 = "Неизвестен" ;
    value gender_f 1 = "Мужчины" 2 = "Женщины";
    value risk_f 1 = "Стандартная" 2 = "Высокая" 3 = "нет данных";
    value age_group_f low-30 = "младшая (до 30)" 30-40 = "средняя (30-40)" 40-high = "старшая (40-55)";
	value tkm_f 0="нет" 1="ауто" 2="алло";
	value it_f 1="есть" 0 = "нет";
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
/*------ цензурирование, и вычисление производных показателей ----------*/

data &LN..all_pt; *только по таблице пациентов;
    set &LN..all_pt;

/*пока обнуляем возраст, потом будем перезабивать*/
    new_birthdate = .;
*   age = floor((today()-DATEPART(new_birthdate))/365.25);
*   age = floor(yrdif(DATEPART(new_birthdate),DATEPART(new_datest),'AGE'));  *вычисляем возраст, добиваем его в доп. столбец;
*   age = floor(yrdif(new_birthdate, pr_b,'AGE'));  *для нового формата данных;
/*    FORMAT age 2.0;*/

/*-----------------*/
	/* парсинг цитогенетики ДОПИСАТЬ */
    if new_citogenname = 'Проведена'
        then nocito = 'point';
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
    if NOT(new_nbrpacient in &cens ) then output;
run;

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


/*ТУТ ДОПИСАТЬ ПРОВЕРКУ ТАЙМЛАЙНА*/


/*прочесываем созданную таблицу, для каждой последней записи загоняем смену на дексаметазон, и номер этапа. Последнюю выводим в датасет*/
data &LN..new_pt &LN..error_timeline /*(keep=)*/;
    set &LN..new_et;
    by pguid;
    retain lastdate ec   d_ch faza time_error ; *ec -- это количество этапов "свернутых";
    if first.pguid then do; lastdate = .; ec = 0; time_error = 0; end;
/*--------------------------------------------------*/
    if it2 then ec + 1;
    if ph_b > lastdate then do; lastdate = ph_b; time_error = 1; end; *Проверка на последнюю дату. ;
    if ph_e > lastdate then do; lastdate = ph_e; time_error = 1; end;

    if new_smena_na_deksamet = 1 then
        do;
            d_ch = 1;
            faza = new_etap_protokol;
        end;
/*---------------------------------------------------*/
    if last.pguid then
        do;
            output &LN..new_pt;
			if time_error ne 0 then output &LN..error_timeline;
            d_ch = 0;
            faza = .;
			time_error = 0;
        end;
run;





/*РЕПОРТИНГ ОБ ОШИБКАХ РЕЛЯЦИЯХ ПАЦИЕНТ-ЭТАП*/

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

/*------------тут нужно будет подцепить заплатку возрастов----------*/
/*------------------------------------------------------------------*/


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

proc means data = &LN..all_pt N;
	var pt_id;
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

proc freq data=&LN..all_pt ;
   tables oll_class / nocum;
   title 'Иммунофенотип';
   FORMAT oll_class oc_f.;
run;

proc freq data=&LN..all_pt ;
   tables new_oll_classname / nocum;
   title 'Иммунофенотип (детально)';
run;


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

proc means data = &LN..all_pt N;
	var new_group_risk;
   title 'По группам риска всего информация о N пациентах';
run;

proc freq data=&LN..all_pt ;
   tables new_group_riskname / nocum;
   title 'Группы риска ';
run;




/*VVVVVVVVVVVVVVVVVVVVVVVVV   не разобрано    VVVVVVVVVVVVVVVVVVVVVVVVVV*/


/*Смена на дексаметазон */
/*Работаем с другой таблицей (этап протокола)*/
/*1. СЧЕТЧИК СМЕНЫ*/


/*парсить не надо, есть переменная new_etap_protokol*/

/*data &LN..all_et;*/
/*    set &LN..all_et;*/
/*        select;*/
/*        when (new_etap_protokolname = 'Предфаза')  ne = 1;*/
/*        when (new_etap_protokolname = 'Первая фаза индукции')  ne = 2;*/
/*        when (new_etap_protokolname = 'Вторая фаза индукции')  ne = 3;*/
/*        when (new_etap_protokolname = 'Курс консолидации I')  ne = 4;*/
/*        when (new_etap_protokolname = 'Курс консолидации II')  ne = 5;*/
/*        when (new_etap_protokolname = 'Курс консолидации III')  ne = 6;*/
/*        when (new_etap_protokolname = 'Курс консолидации IV')  ne = 7;*/
/**/
/*        otherwise;*/
/*    end;*/
/*run;*/


proc sort data=&LN..all_et;
    by pguid ne;
run;
/*так надо сделать но пока не сделано:*/
/*Подцепляем маркер дексаметазона в таблицу пациентов на этапе вычисления последней даты, т.е. не здесь!!*/
/*data &LN..dex_ch;*/
/*  set &LN..all_et;*/
/*  by pguid;*/
/*  retain d_ch faza;*/
/*  if new_smena_na_deksametname = 'Да' then */
/*  do;*/
/*      d_ch = 1;*/
/*      faza = new_etap_protokolname;*/
/*  end;*/
/*  if last.pguid then*/
/*  do;*/
/*      output;*/
/*      d_ch = 0;*/
/*      faza = .;*/
/*  end;*/
/*run;*/

/*proc sort data=&LN..dex_ch;*/
/*  by new_protokolname;*/
/*run;*/

/*proc freq data=&LN..dex_ch;*/
/*  tables */
/*d_ch*/
/*      /nocum;*/
/*run;*/


/*-----------непонятный  рудимент -----------------*/

/*proc freq data=&LN..all_et;*/
/*    tables*/
/*new_etap_protokolname*/
/*        /nocum;*/
/*    title 'Всего проведено этапов';*/
/*run;*/
/*--------------------------------------------------*/

proc sort data=&LN..all_pr;
    by pguid;
run;


/*Соединяем таблицы пациентов и этапов, определяем для кого из пациентов нет записи об этапах*/
data &LN..new_et;
    merge &LN..all_pr (in = i1) &LN..all_et (in = i2);
    by pguid;

    it1 = i1;
    it2 = i2;
run;


proc sort data=&LN..all_et;
    by pguid;
run;



data &LN..new_pt;
    set &LN..new_et;
    by pguid;
    retain lastdate ec   d_ch faza ;
    if first.pguid then do; lastdate = .; ec = 0; end;
/*--------------------------------------------------*/
    if it2 then ec + 1;
    if ph_b > lastdate then  lastdate = ph_b;
    if ph_e > lastdate then  lastdate = ph_e;

    if new_smena_na_deksametname = 'Да' then
        do;
            d_ch = 1;
            faza = new_etap_protokolname;
        end;
/*---------------------------------------------------*/
    if last.pguid then
        do;
            output;
            d_ch = 0;
            faza = .;
        end;
run;


/*Прицепляем события к пациентам. Нам нужны индикаторы и даты рецедива и смерти*/
proc sort data=&LN..all_ev;
    by pguid;
run;

proc sort data=&LN..new_pt;
    by pguid;
run;

data &LN..new_ev;
    merge &LN..new_pt &LN..all_ev ;
    by pguid;
run;
/*  rel ремиссия = 1 */
/*  death Смерть = 3*/
/*  rem рецедив = 5*/

data &LN..new_pt;
    set &LN..new_ev;
    by pguid;
    retain i_rem date_rem /**/ i_death date_death /**/ i_rel date_rel /**/ Laspot;
    if first.pguid then do; i_rel = 0; date_rel = .; /**/ i_death = 0; date_death = .; /**/ i_rem = 0; date_rem = .; Laspot = 0; end;
/*----------------------------------*/
    if new_event = 1 then do; i_rem = 1; date_rem = new_event_date; end;
    if new_event = 3 then do; i_death = 1; date_death = new_event_date; end;
    if new_event = 5 then do; i_rel = 1; date_rel = new_event_date; end;
	if new_aspor_otmena = 1 then laspot = 1;
/*---------------------------------*/
    if last.pguid then do; output; i_rel = 0; date_rel = .; /**/ i_death = 0; date_death = .; /**/ i_rem = 0; date_rem = .; Laspot = 0; end;
run;

/*поставить заплатку если время рецидива равно нулю то сегодняшняя дата*/
/*обновление последнего контакта за счет смерти*/
Data &LN..new_pt;
    set &LN..new_pt;
    if date_rem > lastdate then lastdate = date_rem;
    if date_death > lastdate then lastdate = date_death;
    if date_rel > lastdate then lastdate = date_rel;
    /*ЗАПЛАТКА*/
    *lastdate = MDY(9,1,2013);
run;




/*подготовка переменных для событийного анализа*/

/*Выживаемость*/
Data &LN..new_pt;
    set &LN..new_pt;

    select (i_death);
        when (1) TLive = date_death - pr_b;
        when (0) TLive = lastdate   - pr_b;
        otherwise;
    end;

    select (i_rem);
        when (1) Trem = date_rem - pr_b;
        when (0) Trem = lastdate - pr_b;
        otherwise;
    end;

    select (i_rel);
        when (1) Trel = date_rel - date_rem;
        when (0) Trel = lastdate - date_rem;
        otherwise;
    end;
run;

/*Безрецедивная выживаемость*/
Data &LN..new_pt;
    set &LN..new_pt;
    iRF = i_rel | i_death;
    Select;
        when (i_rel)  TRF = Trel;
        when (i_death) TRF = date_death - date_rem;
        when (iRF = 0) TRF = lastdate - date_rem;
        otherwise;
    end;
run;

/*----------------------------------------*/
/*Смена на дексаметазон*/
%eventan (&LN..new_pt, TLive, i_death, 0,,&y,,,"Общие показатели");
%eventan (&LN..new_pt, TRF, iRF, 0,,&y,,,"Общие показатели");
%eventan (&LN..new_pt, TLive, i_death, 0,F,&y,,,"Общие показатели");
%eventan (&LN..new_pt, TRF, iRF, 0,F,&y,,,"Общие показатели");

/*пол*/
/*%eventan (&LN..new_pt, TLive, i_death, 0,,&y,new_gendercode,gender_f.,"пол");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,,&y,new_gendercode,gender_f.,"пол");*/
/*%eventan (&LN..new_pt, TLive, i_death, 0,F,&y,new_gendercode,gender_f.,"пол");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,F,&y,new_gendercode,gender_f.,"пол");*/

/*по нозологиям*/
data  &LN..tmp;
    set &LN..new_pt;
    if (oll_class in (1,2)) then output;
run;

%eventan (&LN..tmp, TLive, i_death, 0,,&y,oll_class,oc_f.,"по нозологиям");
%eventan (&LN..tmp, TRF, iRF, 0,,&y,oll_class,oc_f.,"по нозологиям");
%eventan (&LN..tmp, TLive, i_death, 0,F,&y,oll_class,oc_f.,"по нозологиям");
%eventan (&LN..tmp, TRF, iRF, 0,F,&y,oll_class,oc_f.,"по нозологиям");

/*По кариотипу*/
%eventan (&LN..new_pt, TLive, i_death, 0,,&y,new_normkariotipname,,"Нормальный кариотип");
%eventan (&LN..new_pt, TRF, iRF, 0,,&y,new_normkariotipname,,"Нормальный кариотип");
%eventan (&LN..new_pt, TLive, i_death, 0,F,&y,new_normkariotipname,,"Нормальный кариотип");
%eventan (&LN..new_pt, TRF, iRF, 0,F,&y,new_normkariotipname,,"Нормальный кариотип");


/*по группам риска*/
/*%eventan (&LN..new_pt, TLive, i_death, 0,,&y,new_group_risk,risk_f.,"по группам риска");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,,&y,new_group_risk,risk_f.,"по группам риска");*/
/*%eventan (&LN..new_pt, TLive, i_death, 0,F,&y,new_group_risk,risk_f.,"по группам риска");*/
/*%eventan (&LN..new_pt, TRF, iRF, 0,F,&y,new_group_risk,risk_f.,"по группам риска");*/

/*анализ в стандартной группе риска*/
/*data  &LN..tmp;*/
/*  set &LN..new_pt;*/
/*  if (new_group_risk = 1) then output;*/
/*run;*/
/**/
/*%eventan (&LN..tmp, TLive, i_death, 0,,&y,d_ch,1.0,"Стандартная группа риска");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,,&y,d_ch,1.0,"Стандартная группа риска");*/
/*%eventan (&LN..tmp, TLive, i_death, 0,F,&y,d_ch,1.0,"Стандартная группа риска");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,F,&y,d_ch,1.0,"Стандартная группа риска");*/

/*,"Высокая группа риска"*/
/*data  &LN..tmp;*/
/*  set &LN..new_pt;*/
/*  if (new_group_risk = 2) then output;*/
/*run;*/
/**/
/*%eventan (&LN..tmp, TLive, i_death, 0,,&y,d_ch,1.0,"Высокая группа риска");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,,&y,d_ch,1.0,"Высокая группа риска");*/
/*%eventan (&LN..tmp, TLive, i_death, 0,F,&y,d_ch,1.0,"Высокая группа риска");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,F,&y,d_ch,1.0,"Высокая группа риска");*/

/*В-клеточный ОЛЛ*/
data  &LN..tmp;
    set &LN..new_pt;
    if (oll_class = 2) then output;
run;

%eventan (&LN..tmp, TLive, i_death, 0,,&y,new_normkariotipname,,"В-клеточный ОЛЛ");
%eventan (&LN..tmp, TRF, iRF, 0,,&y,new_normkariotipname,,"В-клеточный ОЛЛ");
%eventan (&LN..tmp, TLive, i_death, 0,F,&y,new_normkariotipname,,"В-клеточный ОЛЛ");
%eventan (&LN..tmp, TRF, iRF, 0,F,&y,d_ch,,"В-клеточный ОЛЛ");

/*Т-клеточный ОЛЛ*/
data  &LN..tmp;
    set &LN..new_pt;
    if (oll_class = 2) then output;
run;

%eventan (&LN..tmp, TLive, i_death, 0,,&y,new_normkariotipname,,"Т-клеточный ОЛЛ");
%eventan (&LN..tmp, TRF, iRF, 0,,&y,new_normkariotipname,,"Т-клеточный ОЛЛ");
%eventan (&LN..tmp, TLive, i_death, 0,F,&y,new_normkariotipname,,"Т-клеточный ОЛЛ");
%eventan (&LN..tmp, TRF, iRF, 0,F,&y,new_normkariotipname,,"T-клеточный ОЛЛ");

/*В возростной группе до 35*/
/*data  &LN..tmp;*/
/*  set &LN..new_pt;*/
/*  if (age < 35) then output;*/
/*run;*/
/**/
/*%eventan (&LN..tmp, TLive, i_death, 0,,&y,d_ch,1.0,"В возростной группе до 35");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,,&y,d_ch,1.0,"В возростной группе до 35");*/
/*%eventan (&LN..tmp, TLive, i_death, 0,F,&y,d_ch,1.0,"В возростной группе до 35");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,F,&y,d_ch,1.0,"В возростной группе до 35");*/

/*В возростной группе старше 35*/
/*data  &LN..tmp;*/
/*  set &LN..new_pt;*/
/*  if (age < 35) then output;*/
/*run;*/
/**/
/*%eventan (&LN..tmp, TLive, i_death, 0,,&y,d_ch,1.0,"В возростной группе старше 35");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,,&y,d_ch,1.0,"В возростной группе старше 35");*/
/*%eventan (&LN..tmp, TLive, i_death, 0,F,&y,d_ch,1.0,"В возростной группе старше35");*/
/*%eventan (&LN..tmp, TRF, iRF, 0,F,&y,d_ch,1.0,"В возростной группе старше 35");*/
/**/

/*Стратификация по возрасту*/
%eventan (&LN..new_pt, TLive, i_death, 0,,&y,age,age_group_f.,"Стратификация по возрасту");
%eventan (&LN..new_pt, TRF, iRF, 0,,&y,age,age_group_f.,"Стратификация по возрасту");
%eventan (&LN..new_pt, TLive, i_death, 0,F,&y,age,age_group_f.,"Стратификация по возрасту");
%eventan (&LN..new_pt, TRF, iRF, 0,F,&y,age,age_group_f.,"Стратификация по возрасту");

data &LN..fr;
    set &LN..new_pt;
    if new_etap_protokol = 3 then output;
run;

proc means data=&LN..new_pt N median mean max min;
   var  new_blast_km;
   title 'бластов в КМ';
run;


data &LN..fr;
    set &LN..new_pt;
    if new_etap_protokol = 3 AND new_blast_km > 5 then output;
run;

proc means data=&LN..fr N median mean max min;
   var  new_blast_km;
   title 'бластов в КМ > 5%';
run;

proc freq data=&LN..fr;
    tables new_gendercodename*oll_class /nocum;
    title 'Анализ пунктатов КМ на 70 день терапии';
run;

/*присоединяем все этапы к пациентам*/

proc sort data=&LN..all_pr;
    by pguid;
run;

proc sort data=&LN..all_et;
    by pguid;
run;

data &LN..RoI;
    merge &LN..all_pr &LN..all_et ;
    by pguid;
run;

/*Создаем промежутки этапов 1-2 этапов индукции*/
data &LN..RoI;
    set &LN..RoI;
    by pguid;
    retain TP1-TP4 ;
    if first.pguid then do; TP1 = .; TP2 = .; TP3 = .; TP4 = .; end;
/*--------------------------------------------------*/
    if new_etap_protokol = 2 then do; TP1 = ph_b; TP2 = ph_e; end;
    if new_etap_protokol = 3 then do; TP3 = ph_b; TP4 = ph_e; end;
    if TP4 = . then TP4 = DATE();
/*---------------------------------------------------*/
    if last.pguid then
        do;
            output;
        TP1 = .; TP2 = .; TP3 = .; TP4 = .;
        end;
run;


/*подцепляем события, определяем произошли ли они в промежутках, составляем таблицу*/

proc sort data=&LN..RoI;
    by pguid;
run;

proc sort data=&LN..all_ev;
    by pguid;
run;

data &LN..RoI;
    merge &LN..RoI &LN..all_ev ;
    by pguid;
run;

data &LN..RoI;
    set &LN..RoI;
    by pguid;
    retain event ev_date;
    if first.pguid then do; event = 4; ev_date = .; end;
/*--------------------------------------------------*/
    if TP1 <= new_event_date AND new_event_date <= TP4 then do;
        ev_date = new_event_date;
        if new_event in (1,2,3) then event = new_event;
        /*if new_event = 1 then do; event = 1 ; end; *полная ремиссия;
        if new_event = 2 then do; event = 2 ; end; *Резистивность;
        if new_event = 3 then do; event = 3 ; end; *смерть;
        */
    end;
*else event = 4; *резистентность;
/*---------------------------------------------------*/
    if last.pguid then
        do;
            output;
        event = .;
        ev_date = .;
        end;
run;
proc freq data=&LN..RoI;
    tables event*oll_class /nocum;
    title 'ПР';
run;

data &LN..tmp;
	set &LN..All_pr;
	if new_ldh ne then; 
	do;
		if new_ldh > 400 then ldg = 1; else ldg = 0;
		output;
	end;
run;

proc freq data=&LN..tmp;
	tables ldg*oll_class /nocum;
run;
	
%eventan (&LN..new_pt, TRF, iRF, 0,,&y,Laspot,,"В зависимости от отмены L-аспоргиназы");


