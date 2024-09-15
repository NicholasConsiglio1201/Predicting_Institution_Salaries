# Predicting Average Instructional Salary for Four-Year Institutions in the United States

**Goal**: Be able to create a Regression Model that will be able to predict the Average Salary for Instructional Staff at Four-Year universities. 

**Dataset**: Our Dataset comes from the IPeds (Integrated Postsecondary Education Data System) database.
We worked with and joined ___ tables together to form the main dataset used for this analysis.

### Note: The variables listed below are the variables used in our Regression Model. These are not all the variables found within the datasets.

***Ipeds.Salaries***: This dataset contained data on instructional staff salaries for each university.
* sa09mct --> Total number of Instructional Staff on 9-Month Contract.
* sa09mcm --> Total number of Men Instructional Staff on 9-Month Contract.
* sa09mcw --> Total number of Women Instructional Staff on 9-Month Contract.
* sa09mot --> Total salary outlays for instructional staff on 9-Month Contract.
* average_salary --> **Feature Created** that calculates the average salary at each univeristy.
* mf_staff_ratio --> **Feature_Created** that calculates the male to female ratio for each university.

***Ipeds.TuitionandCosts***: This dataset contains data on the amount of tuition and various costs for each university.
* tuition1 --> In-district tuition for full-time undergraduates.
* tuition2 --> In-state tuition for full-time undergraduates.
* roomamt --> Average room charge for the academic year.
* boardamt --> Average board charge for the academic year.
* roomcap --> Total number of student that can live through the university housing.

***Ipeds.Characteristics***: This dataset contains a lot of dimensional data about each university.
* fips --> FIPS State Code.
* control --> Is it a Private or Public Insitution?
* locale --> Is the institution located in a rural, town, suburb, city, or none type of area.
* c21enprf --> What type of students can enroll at the institution?
* region --> Feature Created that assigns each university to either "South", "Midwest", "Northeast", "West", or "Non-Continental."

***Ipeds.Graduation***: This dataset contains data about the graduating cohorts as well as the graduation rates for each university.
* graduation_rate: **Feature Created** to calculate the graduation rate for each university.
* total_cohort: Total number of students in the graduating class.
