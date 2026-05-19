*-------------------------------------------------------------------
* tableA5_by_gender.do  --  PNAS Nexus replication package
*
* Generates Table A.5 (Difference between AI and Human Performance by Customer Gender).
*
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "<REPLICATION_ROOT>"
}
run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/tableA5_by_gender.log", replace text

**# Appendix Table: gender effects
{
	
local i = 0
	
use  "$temp/vacation_connected_call_level"  , clear
replace province_capital = 1 if missing(province_capital)

drop if gender_customer == "Unknown" |  gender_cno == "Unknown" 
gen gender_customer_num = (gender_customer == "Female")
// egen gender_customer_num = group(gender_customer)
// egen gender_cno_num = group(gender_cno)

foreach y in if_succeed  bridge_duration_num bridge_duration_num n_policy_succeed payment_amt_num payment_amt_per if_refund scale_premium_num ins_amt_num {

// local group_variable gender_combine

keep if vacation == 1 

dis   "`y'"
	local i = `i' + 1

preserve

if "`y'" == "if_succeed"{
	local ytitle = "%"
	replace `y' = `y' * 100
	
}
if "`y'" == "payment_amt_num"{
	
// 	global ytitle = "Payment Amount (CNY)"
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

gen gender_group = . 
replace gender_group = 1 if if_AI
replace gender_group = 2 if !if_AI  & gender_customer == "Female" 
replace gender_group = 3 if !if_AI  & gender_customer == "Male" 


// reghdfe `y' i.gender_group##i.gender_customer_num   province_capital gap_create_first_call ///
// 		, absorb(date_create_time hour_create_time ) cl(crm_user_id)

reghdfe  `y'  i.if_AI##i.gender_customer_num   province_capital  gap_create_first_call ///
		, absorb(date_create_time hour_create_time ) cl(crm_user_id)
	estadd local mean_y = string(r(mean), "%9.2f") , replace
	estadd local date_fe "Yes" , replace
	estadd local control "Yes" , replace
	estadd local hour_create_time "Yes" , replace
	estadd local r2_a =  string(e(r2), "%9.3f") , replace
	estadd local N =  string(e(N), "%9.0f") , replace

	eststo table_by_gender_c`i'	
restore

}	
	dis `i'


#delimit ; 
esttab table_by_gender_c1 table_by_gender_c2 table_by_gender_c3 table_by_gender_c4 table_by_gender_c5 table_by_gender_c6 table_by_gender_c7 table_by_gender_c8  table_by_gender_c9 
	using  "$table_overleaf/table_by_gender.tex"
, replace f compress
b(%12.3f) se(%12.3f) star(* 0.10 ** 0.05 *** 0.01)  
keep( 1.if_AI  1.gender_customer_num 1.if_AI#1.gender_customer_num )   order(  1.gender_customer_num 1.if_AI#1.gender_customer_num  1.if_AI  ) coeflabels(
		1.gender_customer_num  " Female Customer "
		1.if_AI#1.gender_customer_num "$  \textit{AI} \times $ Female Customer "
		1.if_AI "$ \textit{AI} $"  )
 label booktabs noobs nonotes collabels(none) alignment(D{.}{.}{-1}) 
 stats( control date_fe hour_create_time r2_a N , labels(  "Controls" "Date FE" "Hour FE" "\hline Adjusted R-squared"  "Obs" ) )
 mtitles("Success rate" "Duration" "Duration (success)" "N succeed transcations"  "Payment amount" "Payment per second" "Refund rate" "Scale premium" "Insurance amount")
 nogaps  ;
 #delimit cr

	
}

capture log close
