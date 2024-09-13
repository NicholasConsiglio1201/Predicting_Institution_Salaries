/* Main Objective: Build your Best Model to predict average instructional salary for four
	year institutions.*/
	
/*By: Nicholas Consiglio, Corey Dearing, Nicholas Young*/

proc format cntlin = ipeds.ipedsformats;
run;
options fmtsearch = (IPEDSData);
ods trace on;

/*Creating a new 'salaries' dataset.*/
data work.salaries;
	/*Referencing the 'ipeds.salaries' dataset and renaming
		a bunch of variables.*/
	set ipeds.salaries (rename = (sa09mct = total_staff
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
	set ipeds.tuitionandcosts (rename = (tuition1 = in_district_tuition
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
	set ipeds.characteristics (rename = (instnm = instname
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
	set ipeds.agedist (rename = (efbage = age_cat
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
	set ipeds.graduation (rename = (men = graduating_men
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
/* proc glmselect data = work.combined3; */
/* 	class institution_level institution_control highest_offering locale */
/* 		instcat enroll_profile metro_micro region; */
/* 	model average_salary = unitid total_staff mf_staff_ratio in_district_tuition */
/* 		in_district_fees in_state_tuition in_state_fees out_state_tuition */
/* 		out_state_fees room roomcap board roomamt boardamt avg_tuition avg_fee */
/* 		institution_level institution_control highest_offering locale instcat */
/* 		enroll_profile metro_micro total_students_final */
/* 		graduating_men graduating_women total_cohort grad_cohort graduation_rate region/ */
/* 	selection = stepwise(select = SL slentry = 0.10 slstay = 0.10) stats = (AIC CP SBC); */
/* run; */

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

/*Exploratory Data Analysis*/

/*Visualizing average_salary vs. grad_rate*/
/* proc sgplot data = work.combined3; */
/* 	scatter x = graduation_rate y = average_salary; */
/* 	reg x = graduation_rate y = average_salary / lineattrs = (color = red); */
/* run; */
/*  */
/* proc sgplot data = work.combined3; */
/* 	scatter x = total_staff y = average_salary; */
/* 	reg x = total_staff y = average_salary / lineattrs = (color = red); */
/* run; */
/*  */
/* proc sgplot data = work.combined3; */
/* 	scatter x = roomamt y = average_salary; */
/* 	reg x = roomamt y = average_salary / lineattrs = (color = red); */
/* run; */
/*  */
/* proc sgplot data = work.combined3; */
/* 	scatter x = total_cohort y = average_salary; */
/* 	reg x = total_cohort y = average_salary / lineattrs = (color = red); */
/* run; */
/*  */
/* proc sgplot data = work.combined3; */
/* 	scatter x = boardamt y = average_salary; */
/* 	reg x = boardamt y = average_salary / lineattrs = (color = red); */
/* run; */
/*  */
/* proc sgplot data = work.combined3; */
/* 	scatter x = mf_staff_ratio y = average_salary; */
/* 	reg x = mf_staff_ratio y = average_salary / lineattrs = (color = red); */
/* run; */


	
