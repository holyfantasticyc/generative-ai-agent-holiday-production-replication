*-------------------------------------------------------------------
* tableA1_summary_statistics.do  --  PNAS Nexus replication package
*
* Generates Table A.1 (Table of Summary Statistics).
*
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "<REPLICATION_ROOT>"
}
run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/tableA1_summary_statistics.log", replace text

**## Task/raw data level
macro drop  variable_list1
global variable_list1 if_connected if_AI if_call_w_1_min if_call_w_10_min if_call_w_1_hour province_capital gender_customer_num

use "$temp/vacation_full_data_no_collapse" , clear
keep if month_create_time > 5 
drop if month_create_time == 10 & day_create_time == 27 // drop this because it might have less refund window compared with other dates. And it will also help to reduce the to sample size to < 10,000
cap gen gender_customer_num = ( gender_customer == "Female" )

preserve
	tabstat $variable_list1  ,  stat(N mean sd min max ) save
	mat A = r(StatTotal)'
	count 
	local N_A = r(N)
restore

**## connected call level

global variable_list2 if_succeed bridge_duration_num
use  "$temp/vacation_connected_call_level"  , clear
replace if_succeed = if_succeed * 100   // express as percentage to match Table A.1 in the manuscript

preserve
	tabstat $variable_list2  ,  stat( N mean sd min max ) save
	mat B = r(StatTotal)'
	count 
	local N_B = r(N)
restore

**## succeed call level
global variable_list3  bridge_duration_num  n_policy_succeed payment_amt_num payment_amt_per if_refund scale_premium_num ins_amt_num
use  "$temp/vacation_connected_call_level"  , clear
keep if if_succeed
gen payment_amt_per = total_payment_amt_num / bridge_duration_num
replace ins_amt_num = ins_amt_num / 10000
preserve
	tabstat $variable_list3  ,  stat(N mean sd min max ) save
	mat C = r(StatTotal)'
	count 
	local N_C = r(N)
restore

**## Human agent level
use "$temp/vacation_full_data_no_collapse" , clear
keep if !if_AI 
sort crm_user_id date_create_time hour_create_time minute_create_time
bys crm_user_id date_create_time: gen task_order = _n
bys crm_user_id date_create_time  (task_order): egen cumulative_payment = sum(payment_amt_num)
gen gender_cno_num = ( gender_cno == "Female" )
replace gender_cno_num = . if gender_cno == "Unknown" | missing(gender_cno)
replace working_hours = . if working_hours == 0

collapse (mean) start_working_hour work_month_num cumulative_payment (max) task_order gender_cno_num, by(crm_user_id)

global variable_list4 start_working_hour work_month_num task_order cumulative_payment gender_cno_num 
preserve
	tabstat $variable_list4  ,  stat(N mean sd min max ) save
	mat D = r(StatTotal)'
	count 
	local N_D = r(N)
restore


**# Output 
mat temp_A = [.,.,.,.,.]
matrix rownames temp_A = "\textbf{Panel A. All Customer Calls}"
matrix rownames A = "Connected" "AI" "Call within 1 min" "Call within 10 min" "Call within 1 hour"  "Capital cities" "Female customer"

mat temp_B = [.,.,.,.,.]
matrix rownames temp_B = "\textbf{Panel B. Connected Calls}"
matrix rownames B = "Success rate, \%" "Duration, (s)"

mat temp_C = [.,.,.,.,.]
matrix rownames temp_C = "\textbf{Panel C. Success Calls}"
matrix rownames C = "Duration, (s)"  "Number of Transcations" "Payment amount (CNY)" "Payment per seconds (CNY/s)" "Refund" "Scale premium (CNY)" "Insurance amount (10,000 CNY)"
 
mat temp_D = [.,.,.,.,.]
matrix rownames temp_D = "\textbf{Panel D. Human Representatives}"
matrix rownames D = "Starting working hour"  "Working experiences (month)" "Total task per day" "Cumulative revenue (CNY)" "Female representative"
 
mat E = temp_A\A\temp_B\B\temp_C\C\temp_D\D
mat list E , format(%9.2f)

estadd matrix E, replace
esttab e(E, fmt(2)) using "$table_overleaf/table_summary_statistics.tex", ///
    replace booktabs  noobs nonotes nonumber nomtitle nolabel fragment ///
    alignment(D{.}{.}{-1}) ///
    collabel("Obs" "Mean" "SD" "Min" "Max", lhs("Variables")) 

file open myfile using "$table_overleaf/table_summary_statistics.tex", write append
// file write myfile "\bottomrule" _n
file close myfile	



capture log close
