/* Main Objective: Build your Best Model to predict average instructional salary for four
	year institutions.*/

/*By: Nicholas Consiglio, Corey Dearing, Nicholas Young*/
/* Jenner compatibility bundle: the original script reads five IPEDS extract tables via
	an external `ipeds` libname (ipeds.salaries, ipeds.tuitionandcosts,
	ipeds.characteristics, ipeds.agedist, ipeds.graduation) plus a PROC FORMAT CNTLIN=
	catalog that only exist on the authors' local SAS session. Below we inline small
	fabricated datasets with the same column shapes (all institution-level aggregates,
	matching IPEDS' own grain -- no individual salary records) so the rest of the
	pipeline -- every rename, feature, sort, merge, and the PROC GLM model itself --
	runs exactly as written. */

/*Creating a new 'salaries' dataset.*/
data ipeds_salaries;
	length unitid 8 rank 8 sa09mct sa09mcm sa09mcw sa09mot sa09mom sa09mow 8;
	input unitid rank sa09mct sa09mcm sa09mcw sa09mot sa09mom sa09mow;
	datalines;
100001 7 120 65 55 9600000 5300000 4300000
100002 7 80  40 40 6800000 3500000 3300000
100003 7 200 110 90 17500000 9800000 7700000
100004 7 45  20 25 3200000 1450000 1750000
100005 7 310 160 150 27900000 14800000 13100000
100006 7 60  35 25 4600000 2700000 1900000
100007 7 150 80 70 12800000 7000000 5800000
100008 7 90  50 40 7400000 4200000 3200000
100009 7 275 140 135 24100000 12600000 11500000
100010 7 55  30 25 4100000 2300000 1800000
100011 7 130 70 60 10900000 6100000 4800000
100012 7 175 95 80 15200000 8500000 6700000
;
run;

/*Cleaning up the Tuition and Costs datasets*/
data ipeds_tuitionandcosts;
	length unitid 8 tuition1 tuition2 tuition3 fee1 fee2 fee3 roomamt boardamt roomcap 8;
	input unitid tuition1 tuition2 tuition3 fee1 fee2 fee3 roomamt boardamt roomcap;
	datalines;
100001 9800 11200 21500 1200 1300 1900 6200 4800 3200
100002 7200 8100 16500 900  980  1500 5100 4100 2100
100003 12500 14200 27800 1600 1750 2400 7400 5600 5400
100004 6100 6900 13800 700  760  1100 4200 3400 1400
100005 15800 17600 32500 2100 2250 3100 8600 6300 7800
100006 6900 7700 15200 800  860  1250 4800 3900 1700
100007 10500 11900 22800 1350 1450 2050 6700 5100 3900
100008 8300 9200 18300 1050 1120 1650 5700 4500 2500
100009 14200 15900 30100 1900 2050 2850 8100 6000 7100
100010 6500 7300 14600 760  820  1200 4500 3700 1600
100011 9600 10900 21000 1180 1280 1850 6100 4700 3500
100012 11800 13300 26100 1500 1620 2250 7100 5400 4900
;
run;

/*Cleaning up the Characteristics Table.*/
data ipeds_characteristics;
	length unitid 8 instnm $60 fips 8 iclevel $2 control $10 hloffer $10
		c21enprf $20 cbsatype $20 locale $20;
	input unitid instnm $ fips iclevel $ control $ hloffer $ c21enprf $ cbsatype $ locale $;
	datalines;
100001 State_Univ_A 1  4yr Public Doctoral Fulltime Metro City
100002 State_Univ_B 17 4yr Public Masters  Fulltime Metro Suburb
100003 Private_Coll_C 36 4yr Private Doctoral Fulltime Metro City
100004 State_Univ_D 6  4yr Public Bachelor Parttime Micro Town
100005 Private_Univ_E 9 4yr Private Doctoral Fulltime Metro City
100006 State_Coll_F 20 4yr Public Masters  Fulltime Micro Rural
100007 State_Univ_G 48 4yr Public Doctoral Fulltime Metro Suburb
100008 Private_Coll_H 25 4yr Private Masters  Fulltime Metro City
100009 State_Univ_I 4  4yr Public Doctoral Fulltime Metro Suburb
100010 State_Coll_J 19 4yr Public Bachelor Parttime Micro Rural
100011 Private_Univ_K 42 4yr Private Doctoral Fulltime Metro City
100012 State_Univ_L 12 4yr Public Doctoral Fulltime Metro City
;
run;

/*Ipeds Age Dataset*/
/*Cleaning the Age Distribution Dataset.*/
data ipeds_agedist;
	length unitid 8 efbage 8 efage01-efage09 8;
	input unitid efbage efage01 efage02 efage03 efage04 efage05 efage06 efage07 efage08 efage09;
	datalines;
100001 1 3200 3500 900 1100 6700 2000 4100 4600 8700
100002 1 2100 2300 600 700  4400 1300 2700 3000 5700
100003 1 5200 5600 1400 1600 10800 3000 6600 7200 13800
100004 1 1200 1300 350 400  2500 750  1550 1700 3250
100005 1 6800 7300 1900 2100 14100 4000 8700 9400 18100
100006 1 1600 1750 470 520  3350 990  2070 2270 4340
100007 1 4100 4400 1150 1250 8500 2400 5250 5650 10900
100008 1 2700 2900 780 850  5600 1630 3480 3750 7230
100009 1 6200 6650 1750 1900 12850 3650 7950 8550 16500
100010 1 1450 1550 420 460  3000 880  1870 2010 3880
100011 1 3600 3850 1000 1100 7450 2100 4600 4950 9550
100012 1 4600 4950 1300 1400 9550 2700 5900 6350 12250
;
run;

/*Cleaning the Ipeds Graduation Data*/
data ipeds_graduation;
	length unitid 8 men women total 8;
	input unitid men women total;
	datalines;
100001 . . 500
100001 210 240 450
100002 . . 340
100002 150 165 302
100003 . . 820
100003 360 390 690
100004 . . 210
100004 90  95  165
100005 . . 1100
100005 480 510 910
100006 . . 260
100006 115 120 205
100007 . . 620
100007 275 290 510
100008 . . 380
100008 165 175 300
100009 . . 940
100009 410 435 780
100010 . . 230
100010 100 105 180
100011 . . 560
100011 245 260 460
100012 . . 700
100012 305 325 590
;
run;

/*Creating a new 'salaries' dataset.*/
data work.salaries;
	/*Referencing the 'ipeds.salaries' dataset and renaming
		a bunch of variables.*/
	set ipeds_salaries (rename = (sa09mct = total_staff
								  sa09mcm = total_staff_men
								  sa09mcw = total_staff_women
								  sa09mot = total_salary
								  sa09mom = total_salary_men
								  sa09mow = total_salary_women));
	/*We only want to look at the instructional staff salaries which is 'Rank' = 7*/
	where rank = 7;
	/*We want all the observations where the total staff is not equal to 0.*/
	if total_staff ne 0;
	if total_staff_women ne 0;
	/*Feature Creation*/
	mf_staff_ratio = round((total_staff_men / total_staff_women), 0.0001);
	average_salary = round((total_salary / total_staff), 0.01);
	format total_salary total_salary_men total_salary_women average_salary dollar20.
		   total_staff comma10.;
run;
/**************************************************************************************************************/
/*Cleaning up the Tuition and Costs datasets*/
data work.tuitioncosts;
	/*Renaming the variables to be easier to understand.*/
	set ipeds_tuitionandcosts (rename = (tuition1 = in_district_tuition
										 tuition2 = in_state_tuition
										 tuition3 = out_state_tuition
										 fee1 = in_district_fees
										 fee2 = in_state_fees
										 fee3 = out_state_fees));
	/*Feature Creation*/
	avg_tuition = ((in_district_tuition + in_state_tuition + out_state_tuition) / 3);
	avg_fee = ((in_district_fees + in_state_fees + out_state_fees / 3));
	/*Applying the formats to our data.*/
	format in_district_tuition in_state_tuition out_state_tuition roomamt dollar10.
		   in_district_fees in_state_fees out_state_fees boardamt dollar10.
		   avg_tuition avg_fee dollar10.
		   roomcap comma10.;
run;
/***********************************************************************************/
/***Ipeds Characteristics Table***/

/*Cleaning up the Characteristics Table.*/
data work.character;
	/*Renaming a bunch of different variable names.*/
	set ipeds_characteristics (rename = (instnm = instname
										 fips = fipscode
										 iclevel = institution_level
										 control = institution_control
										 hloffer = highest_offering
										 c21enprf = enroll_profile
										 cbsatype = metro_micro));
	/*Creating a New Variable Called 'Region'*/
	length region $40.;
    if fipscode in (1, 5, 10, 12, 13, 21, 22, 24, 28, 37, 40, 45, 47, 48, 51, 54)
    	then region = 'South';
    else if fipscode in (17, 18, 19, 20, 26, 27, 29, 31, 38, 39, 46, 55)
    	then region = 'Midwest';
    else if fipscode in (9, 23, 25, 33, 34, 36, 42, 44, 50)
    	then region = 'Northeast';
    else if fipscode in (2, 4, 6, 8, 15, 16, 30, 32, 35, 41, 49, 53, 56)
    	then region = 'West';
    else if region = ' '
    	then region = 'non-continental';
run;
/********************************************************************/
/*Ipeds Age Dataset*/
/*Cleaning the Age Distribution Dataset.*/
data work.age;
	/*Renaming Some Variables in this Dataset*/
	set ipeds_agedist (rename = (efbage = age_cat
								 efage01 = ft_men
								 efage02 = ft_women
								 efage03 = pt_men
								 efage04 = pt_women
								 efage05 = ft_total
								 efage06 = pt_total
								 efage07 = total_men
								 efage08 = total_women
								 efage09 = total_students));

	/*Formatting the variables to look appropriately.*/
	format age_cat ft_men ft_women pt_men pt_women ft_total comma10.
		   pt_total total_men total_women total_students comma10.;
run;

proc sql;
  create table work.age_summed as
  select
    unitid,
    sum(total_students) as total_students_final
  from work.age
  group by unitid;
quit;
/***************************************************************************/
/*Cleaning the Ipeds Graduation Data*/
data work.graduation(drop = lastUnitID total);
	set ipeds_graduation (rename = (men = graduating_men
									women = graduating_women));
	by UnitID;
	total_cohort = lag1(total);
	grad_cohort = total;
	if last.UnitID and lastUnitID ne first.UnitID;
	/*Creating the 'graduation_rate' variable*/
	graduation_rate = grad_cohort / total_cohort;
	/*Formatting the 'graduation_rate' variable*/
	format graduation_rate percent8.2;
run;
/***************************************************************************/
/*Sorting all the tables to prepare them for merging.*/
/*Sorting the 'Salaries' Table.*/
proc sort data = work.salaries;
	by unitid;
run;
/*Sorting the 'TuitionCosts' Table.*/
proc sort data = tuitioncosts;
	by unitid;
run;
/*Sorting the 'Characteristics' table.*/
proc sort data = work.character;
	by unitid;
run;
/*Sorting the 'age' table*/
proc sort data = work.age_summed;
	by unitid;
run;
/*Sorting the 'Graduation' table.*/
proc sort data = work.graduation;
	by unitid;
run;
/*********************************************************************************/
/*Merging all of the datasets together.*/

/*Combining the 'Salaries' and 'TuitionCosts' together.*/
data work.combined;
	merge work.salaries(in = in_salaries) work.tuitioncosts;
	by unitid;
	if in_salaries;
run;
/*Combining the 'Salaries'/'TuitionCosts' table with the 'Characteristics' table.*/
data work.combined1;
	merge work.combined(in = in_combined) work.character;
	by unitid;
	if in_combined;
run;
/*Combining the 'Salaries'/'TuitionCosts'/'Characteristics' table with the 'age' table*/
data work.combined2;
	merge work.combined1(in = in_combined1) work.age_summed;
	by unitid;
	if in_combined1;
run;

/*Combining the 'Salaries'/'TuitionCosts'/'Characteristics'/'Age' table with the
	'Graduation' table.*/
data work.combined3;
	merge work.combined2(in = in_combined2) work.graduation(in = in_graduation);
	by unitid;
	if in_graduation and in_combined2;
run;

/***********************************************************************************/
/*Developing our Model*/

proc glm data = work.combined3;
	class institution_control enroll_profile region locale;
	model average_salary = graduation_rate total_staff roomamt total_cohort
		in_state_tuition mf_staff_ratio institution_control enroll_profile roomcap
		region in_district_tuition locale boardamt / solution;
	output out = predictions predicted = predicted_average_salary;
run;

/*Seeing the Output*/
proc print data = work.predictions;
	var instname average_salary predicted_average_salary;
	where predicted_average_salary ne .;
	format predicted_average_salary dollar12.;
run;

proc sgplot data = work.predictions;
	title "Predicted Average Institutional Salaries";
	scatter x = average_salary y = predicted_average_salary;
	 xaxis label = "Average Salary";
	 yaxis label = "Average Salary";
	reg x = average_salary y = predicted_average_salary / lineattrs = (color = red);
run;
