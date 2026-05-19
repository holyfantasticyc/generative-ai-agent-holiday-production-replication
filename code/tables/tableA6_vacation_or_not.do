*-------------------------------------------------------------------
* tableA6_vacation_or_not.do  --  PNAS Nexus replication package
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "<REPLICATION_ROOT>"
}

run "$replication/code/00_declare_path.do"



capture log close
log using "$replication_log/tableA6_vacation_or_not.log", replace text

* date: Dec, 2, 2024

*******************************************
*   Compare Productivity Vacation or Not 
********************************************


global control_color "blue%50"
global treat_color "red%50"
**# Compare numbers of worked on duty 
// use "$temp/full_data_no_collapse" , clear  
// merge m:1 date_create_time using "$temp/vacation_date_create_time" , keep(3) nogen
// collapse  , by(crm_user_id agent_name )


**# Connected Rate

use "$temp/full_data_no_collapse" , clear  
merge m:1 date_create_time using "$temp/vacation_date_create_time" , keep(3) nogen

// codebook crm_user_id

bys crm_user_id : gen flag_n_calls = _N
// drop if flag_n_calls < 500
drop if gap_creat_lastcall > 3600

replace if_connected = if_connected * 100
reghdfe if_connected vacation_create_time   , a( crm_user_id  year_create_time month_create_time day_create_time dow_create_time hour_create_time ) cl(crm_user_id)
sum if_connected
estadd local mean_y = string(r(mean), "%9.2f") , replace
estadd local crm_user_fe "Yes" , replace
estadd local year_fe "Yes" , replace
estadd local month_fe "Yes" , replace
estadd local day_fe "Yes" , replace
estadd local dow_fe "Yes" , replace
estadd local hour_fe "Yes" , replace

eststo tab_vaction_or_not_c1



**# 
use  "$temp/full_connected_call_level"  , clear
bys crm_user_id : gen flag_n_calls = _N
// drop if flag_n_calls < 500

// merge m:1 date_create_time using "$temp/vacation_date_create_time" , keep(3) nogen
merge m:1 date_create_time using "$temp/vacation_date_create_time" 
gen pre_period = (_m == 1)
drop _m

preserve

	sum date_create_time if !pre_period
	keep if vacation_create_time
	collapse (mean)  ave_if_succeed = if_succeed  ave_payment_amt_num = payment_amt_num , by(crm_user_id)
	***********  drop extreme agent  *****************
	winsor2 ave_if_succeed , trim cut(5 95)
	drop if missing(ave_if_succeed_tr)
	winsor2 ave_payment_amt_num , trim cut(5 95)
	drop if missing(ave_payment_amt_num_tr)
// 	sum  ave_if_succeed , de
// 	drop if ave_if_succeed > 0.6
	***************************************************
	gsort -ave_if_succeed
	gen rank_succeed_rate = _n
	gsort -ave_payment_amt_num
	gen rank_ave_payment_amt = _n	
	save "$temp/temp_history_productivity" , replace
	
restore

drop if pre_period
merge m:1 crm_user_id using "$temp/temp_history_productivity" ,  keep(1 3) gen(flag_mathced_his_productivity) 

gen ln_gap_create_first_call = ln(gap_create_first_call)

foreach var in  payment_amt_num {
	
	cap drop  ln_`var'
	gen ln_`var' = log(`var')
	
}
drop if if_AI == 1

// reghdfe if_succeed vacation_create_time  , a(  hour_create_time minute_create_time) cl(crm_user_id)
replace if_succeed = if_succeed * 100
reghdfe if_succeed vacation_create_time  , a( crm_user_id  year_create_time month_create_time day_create_time dow_create_time hour_create_time ) cl(crm_user_id)
sum if_succeed
estadd local mean_y = string(r(mean), "%9.2f") , replace
estadd local crm_user_fe "Yes" , replace
estadd local year_fe "Yes" , replace
estadd local month_fe "Yes" , replace
estadd local day_fe "Yes" , replace
estadd local dow_fe "Yes" , replace
estadd local hour_fe "Yes" , replace
eststo tab_vaction_or_not_c2


reghdfe payment_amt_num vacation_create_time  , a( crm_user_id  year_create_time month_create_time day_create_time dow_create_time hour_create_time ) cl(crm_user_id)
sum payment_amt_num
estadd local mean_y = string(r(mean), "%9.2f") , replace
estadd local crm_user_fe "Yes" , replace
estadd local year_fe "Yes" , replace
estadd local month_fe "Yes" , replace
estadd local day_fe "Yes" , replace
estadd local dow_fe "Yes" , replace
estadd local hour_fe "Yes" , replace
eststo tab_vaction_or_not_c3


reghdfe bridge_duration_num vacation_create_time , a( crm_user_id  year_create_time month_create_time day_create_time dow_create_time hour_create_time ) cl(crm_user_id)
sum bridge_duration_num
estadd local mean_y = string(r(mean), "%9.2f") , replace
estadd local crm_user_fe "Yes" , replace
estadd local year_fe "Yes" , replace
estadd local month_fe "Yes" , replace
estadd local day_fe "Yes" , replace
estadd local dow_fe "Yes" , replace
estadd local hour_fe "Yes" , replace
eststo tab_vaction_or_not_c4

replace if_refund = if_refund * 100
reghdfe if_refund vacation_create_time , a( crm_user_id  year_create_time month_create_time day_create_time dow_create_time hour_create_time ) cl(crm_user_id)
sum if_refund
estadd local mean_y = string(r(mean), "%9.2f") , replace
estadd local crm_user_fe "Yes" , replace
estadd local year_fe "Yes" , replace
estadd local month_fe "Yes" , replace
estadd local day_fe "Yes" , replace
estadd local dow_fe "Yes" , replace
estadd local hour_fe "Yes" , replace
eststo tab_vaction_or_not_c5

//
// reghdfe if_succeed vacation_create_time  work_month_num, a(  month_create_time hour_create_time minute_create_time) cl(crm_user_id)
//
// reghdfe if_succeed vacation_create_time  work_month_num, a( crm_user_id agent_name month_create_time hour_create_time minute_create_time) cl(crm_user_id)
//
// reghdfe if_succeed vacation_create_time  work_month_num, a( crm_user_id agent_name month_create_time day_create_time hour_create_time minute_create_time ) cl(crm_user_id)

// reghdfe ln_payment_amt_num vacation_create_time  work_month_num, a( crm_user_id agent_name  hour_create_time  ) cl(crm_user_id)
//
// reghdfe ln_payment_amt_num vacation_create_time  work_month_num, a( crm_user_id agent_name month_create_time day_create_time hour_create_time minute_create_time ) cl(crm_user_id)
//
// reghdfe payment_amt_num vacation_create_time  work_month_num, a( crm_user_id agent_name month_create_time day_create_time hour_create_time minute_create_time ) cl(crm_user_id)
//
// reghdfe bridge_duration_num vacation_create_time  work_month_num, a( crm_user_id agent_name month_create_time day_create_time hour_create_time minute_create_time ) cl(crm_user_id)
//
//
// reghdfe if_succeed i.vacation_create_time##i.hour_create_time  work_month_num, a( crm_user_id agent_name month_create_time day_create_time  minute_create_time ) cl(crm_user_id)
//

/*
tw || ///
	 fpfitci if_succeed bridge_duration_num if vacation_create_time == 0 , ciplot(rline) color($control_color) clp(solid) clw(medthick) alp(dash) || ///
	 fpfitci if_succeed bridge_duration_num if vacation_create_time == 1 , ciplot(rline) color($treat_color)  clp(solid)  clw(medthick) alp(dash) || ///
	, ytitle("$ytitle") xtitle("Call Duration (s)") xsca(alt )   ///
	legend(order( 2 "no vacation" 4 "vacation" ) ring(0) rows(1) pos(11) size(small))  ///
	 xline(450) xlabel(0(200)800 900 , nogrid) ylabel(, nogrid) fysize(80) subtitle("$title",size(small)) ///
		 saving(relation, replace) 
*/

		 
**# Prob of working on vacation
use "$temp/full_data_no_collapse" , clear  
bys crm_user_id : gen flag_n_calls = _N
// drop if flag_n_calls < 500
merge m:1 date_create_time using "$temp/vacation_date_create_time" , keep(3) nogen
merge m:1 crm_user_id using "$temp/temp_history_productivity" ,  keep(1 3) gen(flag_mathced_his_productivity) 

gen female_cno = gender_cno ==  "Female"
replace female_cno = . if missing(gender_cno)

replace ave_if_succeed = ave_if_succeed * 100

collapse (mean) vacation_create_time ave_if_succeed ave_payment_amt_num, by(crm_user_id)

reg vacation_create_time ave_if_succeed  , r
sum vacation_create_time
estadd local mean_y = string(r(mean), "%9.2f") , replace
estadd local crm_user_fe "No" , replace
estadd local year_fe "No" , replace
estadd local month_fe "No" , replace
estadd local day_fe "No" , replace
estadd local dow_fe "No" , replace
estadd local hour_fe "No" , replace
eststo tab_vaction_or_not_c6


reg vacation_create_time ave_payment_amt_num  , r
sum vacation_create_time
estadd local mean_y = string(r(mean), "%9.2f") , replace
estadd local crm_user_fe "No" , replace
estadd local year_fe "No" , replace
estadd local month_fe "No" , replace
estadd local day_fe "No" , replace
estadd local dow_fe "No" , replace
estadd local hour_fe "No" , replace
eststo tab_vaction_or_not_c7


#delimit ; 
esttab tab_vaction_or_not_c1 tab_vaction_or_not_c2 tab_vaction_or_not_c3 tab_vaction_or_not_c4 tab_vaction_or_not_c5 tab_vaction_or_not_c6
	using  "$table_overleaf/tab_vaction_or_not.tex"
, replace f compress
b(%12.3f) se(%12.3f) star(* 0.10 ** 0.05 *** 0.01)  
keep( vacation_create_time  ave_if_succeed )   order(  vacation_create_time  ave_if_succeed   ) coeflabels(
		vacation_create_time  " If Holiday "
		ave_if_succeed " Average succeed rate  " )
 label booktabs noobs nonotes collabels(none) alignment(D{.}{.}{-1}) 
 stats( mean_y crm_user_fe year_fe month_fe day_fe dow_fe hour_fe , labels(  "Mean of Y" "Representative FE" "Year FE" "Month FE" "Day FE" "Day-of-week FE" "Hour FE" "\hline Obs" ) )
 mtitles("Connected rate" "Success rate" "Duration" "Payment amount" "Refund rate" "If Holiday")
 nogaps  ;
 #delimit cr



// binscatter vacation_create_time ave_if_succeed , absorb(month_create_time)


// reghdfe vacation_create_time work_month_num if work_month_num < 32 , a(month_create_time) cl(crm_user_id)
//
// reghdfe vacation_create_time ave_if_succeed if ave_if_succeed < 0.05 , a(month_create_time) cl(crm_user_id)

// reghdfe vacation_create_time female_cno , a(month_create_time) cl(crm_user_id)
//
// reghdfe vacation_create_time work_month_num , a(month_create_time) cl(crm_user_id)
//
// reghdfe vacation_create_time ave_if_succeed , a(year_create_time month_create_time day_create_time dow_create_time hour_create_time) cl(crm_user_id)
//
// reghdfe vacation_create_time ave_if_succeed , noa cl(crm_user_id)
//
// reg vacation_create_time ave_if_succeed , cl(crm_user_id)

// reghdfe vacation_create_time ave_payment_amt_num , a(month_create_time) cl(crm_user_id)

// reghdfe vacation_create_time ave_payment_amt_num , noa cl(crm_user_id)


// reghdfe if_succeed ave_if_succeed , a(month_create_time day_create_time hour_create_time) cl(crm_user_id)
//
// reghdfe payment_amt_num ave_payment_amt_num , a(month_create_time day_create_time hour_create_time) cl(crm_user_id)



//
// gen overtime = (hour_create_time >= 20)
//
// reghdfe overtime ave_if_succeed , a(month_create_time) cl(crm_user_id)
//
// reghdfe overtime ave_payment_amt_num , a(month_create_time) cl(crm_user_id)
//
// reghdfe overtime ave_if_succeed , noa cl(crm_user_id)
//
// reg overtime ave_if_succeed , cl(crm_user_id)
//
// reghdfe overtime rank_succeed_rate , noa vce(cl crm_user_id)
//
// reghdfe overtime ave_payment_amt_num , noa vce(cl crm_user_id)
//
// reghdfe overtime rank_ave_payment_amt , noa vce(cl crm_user_id)
//
// reghdfe overtime work_month_num , noa cl(crm_user_id)

capture log close
