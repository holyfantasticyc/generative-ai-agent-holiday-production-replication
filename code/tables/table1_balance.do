*-------------------------------------------------------------------
* table1_balance.do  --  PNAS Nexus replication package
*
* Generates Table 1 (Balance Test Using Pre- and Early-Connecting Variables).
*
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "<REPLICATION_ROOT>"
}
run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/table1_balance.log", replace text

**# Table: balance test

* Full data, including not connected
use "$temp/vacation_full_data_no_collapse" , clear
keep if month_create_time > 5 
drop if month_create_time == 10 & day_create_time == 27 // drop this because it might have less refund window compared with other dates. And it will also help to reduce the to sample size to < 10,000

cap gen gender_customer_num = ( gender_customer == "Female" )


// forvalue i = 9(1)20{ // call time is not balance
// }
gen if_hang_w_60 =  if_connected * (bridge_duration_num < 60)
gen if_hang_w_30 =  if_connected * (bridge_duration_num < 30)
gen if_hang_w_10 =  if_connected * (bridge_duration_num < 10)
gen if_hang_w_5 =  if_connected * (bridge_duration_num < 5)
gen if_hang_w_3 =  if_connected * (bridge_duration_num < 3)   

{
local i = 1

reghdfe gender_customer_num if_AI   , a(date_create_time ) cl(crm_user_id)
estadd local date_fe "Yes" , replace
estadd local obs = round(round(e(N),1),1) , replace
eststo table_balance_c`i'
local i = `i' + 1

replace province_capital = 1 if missing(province_capital)
reghdfe province_capital if_AI  , a(date_create_time ) cl(crm_user_id)
estadd local date_fe "Yes" , replace
estadd local obs = round(round(e(N),1),1) , replace
eststo table_balance_c`i'
local i = `i' + 1

reghdfe if_connected if_AI   , a( date_create_time  ) cl(crm_user_id)
estadd local date_fe "Yes" , replace
estadd local obs = round(round(e(N),1),1) , replace
eststo table_balance_c`i'
local i = `i' + 1

reghdfe if_hang_w_10 if_AI   , a( date_create_time  ) cl(crm_user_id)
estadd local date_fe "Yes" , replace
estadd local obs = round(round(e(N),1),1) , replace
eststo table_balance_c`i'
local i = `i' + 1

#delimit ; 
esttab table_balance_c1  table_balance_c2  table_balance_c3 table_balance_c4
	using  "$table_overleaf/table_balance.tex"
, replace f compress
b(%12.3f) se(%12.3f) star(* 0.10 ** 0.05 *** 0.01)  
keep( if_AI )   order( if_AI ) coeflabels( if_AI " AI Representative  " )
 label booktabs noobs nonotes  collabels(none) alignment(D{.}{.}{-1}) 
 stats( date_fe r2_a obs , labels(  "Date FE" "Adjusted R-squared" "Obs" ) )
nogaps
 mtitles(  "Customer is Female" "Customer is from Major Cities" "If Answered" "Hang up within 10 seconds")
  ;
 #delimit cr

}

capture log close
