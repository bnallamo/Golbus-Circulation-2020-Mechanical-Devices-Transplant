*****************************************
AUTHOR: Kashvi Gupta
DATE: 22 May 2020
MANUSCRIPT TITLE: Changes in Type of Temporary Mechanical Support Device Use Under the New Heart Allocation Policy
RAW DATA SOURCE: Scientific Registry of Transplant Recpients (SRTR)
DATSETS: tx_hr and institution
		
		tx_hr: One record per heart transplant 
			   Each unique procedure is identified using px_id and each unique person is identified using pers_id
			   The center where the transplant was performed is identified using rec_ctr_id

		institution: This file is a referrence table for the various institutions found in the data
					 Each unique institution is identified using ctr_id

PART A: DATA CLEANING
Datasets: tx_hr and institution
1) Prepare dataset for adult heart transplants between 1 January 2017 and 31 January 2020
2) Exclude multiple organ transplants, living donor transplants, data coding errors
3) Merge institution data using rec_ctr_id in tx_hr and ctr_id in institution to exclude transplants in PR
4) Exclude transplants in October 2018 when the new heart allocation policy came into effect
5) Categorize VAD devices as temporary and durable based on VAD brand. Exclude those missing information on presence or type of VAD 

PART B: ANALYSIS
Dataset: tx, n=7,923 var=13
1) Use of ECMOs in all transplants and by gender
2) Use of IABPs in all transplants and by gender
3) Use of temporary VADs in all transplants and by gender
4) Time trends in use of IABPs, ECMOs and temporary VADs in all and by gender 
5) Likelhood of getting a MCS device in the new policy period by gender
6) Use of multiple MCS devices in the same recpient 
*****************************************;

*Library;
libname data "S:\Kashvi\Temp\data";

options FMTSEARCH=(data.formats) nofmterr;
*****************************************;
*Saving files as temp datasets;

*saving heart transplants as a temporary file called tx_hr;
data tx_hr; 
	set data.tx_hr; 
run; 

*saving institution info as a temporary file called insti;
data insti; 
	set data.institution; 
run; 

*****************************************;
*PART A: DATA CLEANING;
*****************************************;

*Selecting variables of interest for the analsysis;
*tx_hr, n=76,839 var=15;
*insti, n=705 var=4;

data tx_hr; 
	set tx_hr;
		keep    px_id pers_id rec_ctr_id 
				rec_tx_dt can_age_at_listing can_gender
				can_init_stat can_last_stat
				can_rem_cd rec_tx_ty 
				rec_ecmo rec_iabp rec_vad_ty rec_vad1 rec_vad2;
run;

data insti; 
	set insti; 
		keep	ctr_id region entire_name primary_state;
run;

*****************************************;
*A.1. Prepare dataset for adult heart transplants between 1 January 2017 and 31 January 2020;
*tx_hr, n=9,010 var=15;

data tx_hr; 
	set tx_hr; 
		where (rec_tx_dt between '01Jan2017'd and '31Jan2020'd) and can_age_at_listing > 17 ; 
run; 

*****************************************;
*A.2 3 4 and 5. 

EXCLUSION CRITERIA:
a) Data coding errors = 3
b) Multiple organ transplants = 748
c) Living donor transplants = 2
d) Transplants in PR = 10
e) Transplants in October 2018 = 236
f) Missing data for VAD or type of VAD = 86+3

After applying exclusion criteria dataset tx_hr_insti, n=8,012 var=20;
*****************************************;

*A.2. Exclude multiple organ transplants, living donor transplants, data coding errors and missing data for VAD;

*a) Individuals in the new policy period with the old transplant status;
proc freq data = tx_hr;
	tables can_last_stat; 
		where  rec_tx_dt between '01Nov2018'd and '31Jan2020'd;
run;
*There are 3 individuals transplanted after policy change with old status;

*b) Individuals with multiple organ transplants;
proc freq data = tx_hr; 
	tables rec_tx_ty; 
run; 
*There are 748 multiple organ transplants;

*c) Individuals with living donor transplants;
proc freq data = tx_hr; 
	tables can_rem_cd; 
run;
*There are 2 living donor transplants;

*Deleting a), b) and c);
data tx_hr; 
	set tx_hr; 	
		if (rec_tx_dt > '31Oct2018'd and (can_last_stat < 2110)) OR
			rec_tx_ty = 2 OR
			can_rem_cd = 15 then delete;
run; 
*Dataset following deletion, tx_hr, n=8,258 var=15;

*****************************************;
*A.3. Merge institution data using rec_ctr_id in tx_hr and ctr_id in institution to exclude transplants in PR;
*Dataset following merge, tx_hr_insti, n=8,248 var=20;

*Creating merging variable; 
data tx_hr; 
	set tx_hr;
		m = rec_ctr_id; 
run; 

*Checking code, if prints 0 then correct;
proc print data = tx_hr; 
	var rec_ctr_id m; 
		where rec_ctr_id ne m;  
run;
 
*Creating merge variable for insti;
data insti; 
	set insti; 
		m = ctr_id; 
run; 

*Checking code, if prints 0 then correct;
proc print data = insti; 
	var ctr_id m; 
		where ctr_id ne m;  
run; 

*Sorting data for merge by variable 'm' that represnts the center ID where the transplant was performed;
proc sort data = insti; *n=705 var=5;
	by m; 
run; 

proc sort data = tx_hr; *n=8,258 var=16;
	by m; 
run; 

*Merging data by 'm' if represented in dataset tx_hr;
data tx_hr_insti;
	merge tx_hr (in=A) insti (in=B) ;
		by m ;
			if A;
run;
*Merged dataset tx_hr_insti, n=8,258 var=20;

*Checking transplants in PR;
proc freq data = tx_hr_insti; 	
	tables primary_state; 
run;
*There are 10 transplants in PR;

*Excluding transplants in PR;
data tx_hr_insti; 
	set tx_hr_insti;
		if primary_state = "PR" then delete;
run;
*tx_hr_insti, n=8,248 var=20;

*****************************************;
*A.4. Exclude transplants in October 2018 when the new heart allocation policy came into effect;
data tx_hr_insti; 
	set tx_hr_insti;
		if rec_tx_dt >= '01Oct2018'd and  rec_tx_dt <='31Oct2018'd then delete;
run;
*tx_hr_insti, n=8,012 var=20;

*****************************************;
*A.5. Categorize VAD devices as temporary and durable based on VAD brand;

*Checking completeness of variable indicating the kind of VAD implanted;
proc freq data = tx_hr_insti; 
	tables rec_vad_ty; 
run; 
*Missing=86 for rec_vad_ty;

*Collapsing those with a LVAD, RVAD and BiVAD as a single variable, VAD = Y else VAD = N;
data tx_hr_insti; 
	set tx_hr_insti; 
		if rec_vad_ty = 2 or rec_vad_ty = 3 or rec_vad_ty = 5 then vad = 1;
		else if rec_vad_ty = . then vad = .;
		else vad = 0;
run;

proc freq data = tx_hr_insti; 
	tables vad; 
run; 
*LVAD(2)=3321 + RVAD(3)=19 + BiVAD (5)=116 -> VAD(Y)=3,456;

*Checking frequencies of VAD brands;
proc freq data = tx_hr_insti; 
	tables rec_vad1 rec_vad2; 
run;

*Checking if someone has a VAD but the VAD brand is missing=3;
proc print data = tx_hr_insti; 
	var rec_vad1 rec_vad2 vad ; 
		where rec_vad1 = . and rec_vad2 = . and vad = 1;
run;
*The majority with VAD have the VAD brand so okay to use this variable;

data tx_hr_insti;	
	set tx_hr_insti;
		if vad = . or (vad = 1 and rec_vad1 = . and rec_vad2 = .) then delete;
run;

*Creating variable for VAD type as temporary(1) and durable (0);
data tx_hr_insti; 
	set tx_hr_insti;
		if (rec_vad1 > = 205 and rec_vad1 < =210) or
			rec_vad1 = 217 or
			rec_vad1 = 224 or 
			rec_vad1 = 236 or 
			rec_vad1 = 313 or 
			rec_vad1 = 316 or 
			rec_vad2 = 316 or 
			rec_vad2 = 330 then vad_ty = 0; *durable;

		if (rec_vad1 > = 225 and rec_vad1 < = 235)or
		   (rec_vad1 > = 318 and rec_vad1 < = 332) or 
			rec_vad1 = 215 or 
			rec_vad1 = 237 or
 			rec_vad2 = 311 or 
			rec_vad2 = 320 or 
			rec_vad2 = 321 then vad_ty = 1; *temporary;
run;

*Creating indicator variable for temporary VAD;
data tx_hr_insti; 
	set tx_hr_insti;
		temporary_vad = (vad_ty=1);
run;

*Checking frequencies of vad_ty;
proc freq data = tx_hr_insti;
	tables vad_ty temporary_vad;
run;

*****************************************;
*Creating Variables:
Female: female = 1 or 0
Policy period, before or after October 2018: tx_p = 0 (before) tx_p = 1 (after)
Candidate month of transplat: month_tx = 1 to 37

*Sex: females=2208 and males=5804;
data tx_hr_insti; 
	set tx_hr_insti;
		if can_gender = "M" then female = 0;
		else female = 1;
run; 

*Policy period: pre policy transplants=4625 and post policy transplants=3387;;
data tx_hr_insti; 
	set tx_hr_insti; 
		if  rec_tx_dt > = '01Jan2017'd and rec_tx_dt < = '30Sep2018'd then tx_p = 0;
		if  rec_tx_dt > = '01Nov2018'd and  rec_tx_dt < = '31Jan2020'd then tx_p = 1; 
run;

*Month of transplant;
data tx_hr_insti; 
	set tx_hr_insti; 

	*pre policy;
	if rec_tx_dt > = '01Jan2017'd and rec_tx_dt < = '31Jan2017'd then month_tx = 1;
	if rec_tx_dt > = '01Feb2017'd and rec_tx_dt < = '28Feb2017'd then month_tx = 2;
	if rec_tx_dt > = '01Mar2017'd and rec_tx_dt < = '31Mar2017'd then month_tx = 3;
	if rec_tx_dt > = '01Apr2017'd and rec_tx_dt < = '30Apr2017'd then month_tx = 4;
	if rec_tx_dt > = '01May2017'd and rec_tx_dt < = '31May2017'd then month_tx = 5;
	if rec_tx_dt > = '01Jun2017'd and rec_tx_dt < = '30Jun2017'd then month_tx = 6;
	if rec_tx_dt > = '01Jul2017'd and rec_tx_dt < = '31Jul2017'd then month_tx = 7;
	if rec_tx_dt > = '01Aug2017'd and rec_tx_dt < = '31Aug2017'd then month_tx = 8;
	if rec_tx_dt > = '01Sep2017'd and rec_tx_dt < = '30Sep2017'd then month_tx = 9;
	if rec_tx_dt > = '01Oct2017'd and rec_tx_dt < = '31Oct2017'd then month_tx = 10;
	if rec_tx_dt > = '01Nov2017'd and rec_tx_dt < = '30Nov2017'd then month_tx = 11;
	if rec_tx_dt > = '01Dec2017'd and rec_tx_dt < = '31Dec2017'd then month_tx = 12;
	if rec_tx_dt > = '01Jan2018'd and rec_tx_dt < = '31Jan2018'd then month_tx = 13;
	if rec_tx_dt > = '01Feb2018'd and rec_tx_dt < = '28Feb2018'd then month_tx = 14;
	if rec_tx_dt > = '01Mar2018'd and rec_tx_dt < = '31Mar2018'd then month_tx = 15;
	if rec_tx_dt > = '01Apr2018'd and rec_tx_dt < = '30Apr2018'd then month_tx = 16;
	if rec_tx_dt > = '01May2018'd and rec_tx_dt < = '31May2018'd then month_tx = 17;
	if rec_tx_dt > = '01Jun2018'd and rec_tx_dt < = '30Jun2018'd then month_tx = 18;
	if rec_tx_dt > = '01Jul2018'd and rec_tx_dt < = '31Jul2018'd then month_tx = 19;
	if rec_tx_dt > = '01Aug2018'd and rec_tx_dt < = '31Aug2018'd then month_tx = 20;
	if rec_tx_dt > = '01Sep2018'd and rec_tx_dt < = '30Sep2018'd then month_tx = 21;

	*post policy;
	if rec_tx_dt > = '01Nov2018'd and rec_tx_dt < = '30Nov2018'd then month_tx = 22;
	if rec_tx_dt > = '01Dec2018'd and rec_tx_dt < = '31Dec2018'd then month_tx = 23;
	if rec_tx_dt > = '01Jan2019'd and rec_tx_dt < = '31Jan2019'd then month_tx = 24;
	if rec_tx_dt > = '01Feb2019'd and rec_tx_dt < = '28Feb2019'd then month_tx = 25;
	if rec_tx_dt > = '01Mar2019'd and rec_tx_dt < = '31Mar2019'd then month_tx = 26;
	if rec_tx_dt > = '01Apr2019'd and rec_tx_dt < = '30Apr2019'd then month_tx = 27;
	if rec_tx_dt > = '01May2019'd and rec_tx_dt < = '31May2019'd then month_tx = 28;
	if rec_tx_dt > = '01Jun2019'd and rec_tx_dt < = '30Jun2019'd then month_tx = 29;
	if rec_tx_dt > = '01Jul2019'd and rec_tx_dt < = '31Jul2019'd then month_tx = 30;
	if rec_tx_dt > = '01Aug2019'd and rec_tx_dt < = '31Aug2019'd then month_tx = 31;
	if rec_tx_dt > = '01Sep2019'd and rec_tx_dt < = '30Sep2019'd then month_tx = 32;
	if rec_tx_dt > = '01Oct2019'd and rec_tx_dt < = '31Oct2019'd then month_tx = 33;
	if rec_tx_dt > = '01Nov2019'd and rec_tx_dt < = '30Nov2019'd then month_tx = 34;
	if rec_tx_dt > = '01Dec2019'd and rec_tx_dt < = '31Dec2019'd then month_tx = 35;
	if rec_tx_dt > = '01Jan2020'd and rec_tx_dt < = '31Jan2020'd then month_tx = 36;
	if rec_tx_dt > = '01Feb2020'd and rec_tx_dt < = '03Mar2020'd then month_tx = 37;
run;

*Checking frequencies;
proc freq data = tx_hr_insti; 
	tables female tx_p month_tx;
run;

*Selecting variables for analysis;
data tx; 
	set tx_hr_insti;
		keep    px_id pers_id
				can_init_stat can_last_stat 
				rec_tx_dt month_tx tx_p
				female 
				rec_ecmo rec_iabp temporary_vad
				region entire_name;
run;
*tx, n=7,923 var=13;

*****************************************;
*Dataset tx with n=7,923 var=13 represnts adult heart transplants between 1 January 2017 and 31 January 2020
with the exclusion criteria as stated above. The dataset was created to analyze the effect of the new 
heart allocation policy on use of temporary MCS in all transplants and by gender. 
The unit of analysis is unique procedures coded by px_id.
*****************************************;
*PART B: DATA ANALYSIS

1) Use of ECMOs in all transplants and by gender
2) Use of IABPs in all transplants and by gender
3) Use of temporary VADs in all transplants and by gender
4) Time trends in use of IABPs, ECMOs and temporary VADs in all and by gender 
5) Likelihood of getting a MCS device in the new policy period by gender
6) Use of multiple MCS devices in the same recpient 
*****************************************;

*n(%) for the table;
proc freq data = tx; 
	tables female*tx_p; 
run;

*checking number of centers where patients underwent a heart transplant;
proc freq data = tx; 
	tables entire_name; 
run;

*****************************************;
*B.1. Use of ECMOs in all transplants and by gender;

*all;
proc freq data = tx; 
	tables rec_ecmo*tx_p/chisq; 
run;

*stratified by sex;
proc freq data = tx; 
	tables rec_ecmo*female/chisq; 
		where tx_p = 1; *change tx_p = 0 or 1 to get other values;
run;

*****************************************;
*B.2. Use of IABPs in all transplants and by gender;

*all;
proc freq data = tx; 
	tables rec_iabp*tx_p/chisq; 
run;

*stratified by sex;
proc freq data = tx; 
	tables rec_iabp*female/chisq; 
		where tx_p = 1; *change tx_p = 0 or 1 to get other values;
run;

*****************************************;
*B.3. Use of temporary VADs in all transplants and by gender;

*all;
proc freq data = tx; 
	tables temporary_vad*tx_p/chisq;
run;

*stratified by sex;
proc freq data = tx; 
	tables temporary_vad*female/chisq;
		where tx_p = 0; *change tx_p = 0 or 1 to get other values;
run;

*****************************************;
*B.5. Time trends in use of ECMOs, IABPs, and temporary VADs in all and by gender
Numbers were exported to an excel sheet for graphing;

*Figure 1A - plotting use of MCS in all;
proc freq data = tx; 
	tables month_tx*rec_ECMO  / nofreq nopercent nocol;
run;

proc freq data = tx; 
	tables month_tx*rec_IABP  / nofreq nopercent nocol;
run;

proc freq data = tx; 
	tables month_tx*temporary_vad / nofreq nopercent nocol;
run;

*Figure 1B and 1C - plotting use of MCS by gender;
proc freq data = tx; 
	tables month_tx*rec_ECMO / nofreq nopercent nocol;
	where female = 0; *change to female = 0/1 to get other values;
run;

proc freq data = tx; 
	tables month_tx*rec_IABP / nofreq nopercent nocol;
	where female = 0; *change to female = 0/1 to get other values;
run;

proc freq data = tx; 
	tables month_tx*temporary_vad/ nofreq nopercent nocol;
	where female = 0; *change to female = 0/1 to get other values;
run;

********************************************;
*B.6. Likelihood of getting a MCS device in the new policy period by gender;

*creating an interaction term for female and transplant in the post-policy period;
data tx; 
	set tx; 
		female_tx_p = female*tx_p;
run;

proc logistic data=tx descending;
	class female (ref= '0') tx_p(ref='0') / param = ref;
	title "IABP";
	model rec_iabp (event = '1') = female tx_p female_tx_p / clodds=wald;
run;

proc logistic data=tx descending;
	class female (ref= '0') tx_p (ref='0') / param = ref;
	title "ECMO";
	model rec_ecmo (event = '1') = female tx_p female_tx_p / clodds=wald;
run;

proc logistic data=tx descending;
	class female (ref= '0') tx_p (ref='0') / param = ref;
	title "Temporary VAD";
	model temporary_vad (event = '1') = female tx_p female_tx_p / clodds=wald;
run;

***********************************************;
*B.7. Use of multiple MCS devices in the same recpient in the post policy period;

*Change rec_iabp, rec_ecmo, temporary_vad and tx_p to 1/0 to get other values;

proc print data = tx; 
	var rec_iabp rec_ecmo temporary_vad; 
		where (rec_iabp = 1 and rec_ecmo = 0 and temporary_vad = 1) AND tx_p = 1;
run;

******************END*************************;

