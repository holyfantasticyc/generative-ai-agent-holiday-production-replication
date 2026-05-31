*-------------------------------------------------------------------
* tableA3_robust_notcontrols.do  --  PNAS Nexus replication package
*
* Generates Table A.3 (Robustness: No Controls and Fixed Effects).
*
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "/Users/holyfantastic/Dropbox/AI/PNAS_NEXUS/replication_package"
}
run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/tableA3_robust_notcontrols.log", replace text

**# Appendix Table: main results, robustness, no controls and fixed effects 

{

use  "$temp/vacation_connected_call_level"  , clear
keep if vacation == 1
replace total_payment_amt_num = 0 if missing(total_payment_amt_num)

cap gen gender_customer_num = ( gender_customer == "Female" )
replace province_capital = 1 if missing(province_capital)
replace gap_creat_lastcallthrough = gap_creat_lastcallthrough / 1

local i = 0
foreach y in if_succeed  bridge_duration_num bridge_duration_num n_policy_succeed payment_amt_num payment_amt_per if_refund scale_premium_num ins_amt_num {

// foreach y in if_succeed n_policy_succeed {

dis   "`y'"
	local i = `i' + 1

preserve

if "`y'" == "if_succeed"{
	local ytitle = "%"
	replace `y' = `y' * 100
	
}
if "`y'" == "payment_amt_num"{
	
	local ytitle = "Chinese Yuan (CNY)"

}
if "`y'" == "bridge_duration_num" & `i' == 2{
	global ytitle = " Seconds "
	
}
if "`y'" == "bridge_duration_num" & `i' == 3{
	keep if if_succeed
	global ytitle = " Seconds "
	
}
if "`y'" == "payment_amt_per"{
	
	keep if if_succeed 
	cap drop payment_amt_per
	gen payment_amt_per = total_payment_amt_num / bridge_duration_num

	global ytitle = "Chinese Yuan (CNY)"
	
}
if "`y'" == "if_refund"{
	
	local ytitle = "%"
	replace `y' = `y' * 100
	
}


if "`y'" == "n_policy_succeed"{
	keep if if_succeed

	global ytitle = "Count"
	
}
if "`y'" == "scale_premium_num"{
	
	global ytitle = "Scale Premium (CNY)"
	
}

if "`y'" == "ins_amt_num"{
	
	replace `y' = `y' / 10000

	global ytitle = "Insurance Amount (10000 CNY)"
	
}

	reghdfe `y' if_AI    ///
	, noa  cl(crm_user_id)
	qui: sum  `y'
	estadd local mean_y = string(r(mean), "%9.2f") , replace
	estadd local date_fe "Yes" , replace
	estadd local hour_create_time "Yes" , replace
	estadd local r2_a =  string(e(r2_a), "%9.3f") , replace
	estadd local N =  string(e(N), "%9.0f") , replace

	eststo table_main_c`i'

	
restore	
}	
	
	
dis `i'


#delimit ; 
esttab table_main_c1 table_main_c2 table_main_c3 table_main_c4 table_main_c5 table_main_c6 table_main_c7 table_main_c8  table_main_c9 
	using  "$table_overleaf/table_robust_notcontrols.tex"
, replace f compress
b(%12.3f) se(%12.3f) star(* 0.10 ** 0.05 *** 0.01)  
keep( if_AI province_capital gender_customer_num )   order( if_AI province_capital gender_customer_num ) coeflabels(
		if_AI "$ \textit{AI} $" 
		province_capital "Capital cities" 
		gender_customer_num "Female customer"   )
 label booktabs noobs nonotes collabels(none) alignment(D{.}{.}{-1}) 
 stats(  mean_y date_fe hour_create_time r2_a N , labels(  "Mean of Y" "Date FE" "Hour FE" "\hline Adjusted R-squared"  "Obs" ) )
 mtitles("Success rate" "Duration" "Duration (success)" "N succeed transcations"  "Payment amount" "Payment per second" "Refund rate" "Scale premium" "Insurance amount")
 nogaps  ;
 #delimit cr

 }

capture log close
