*-------------------------------------------------------------------
* table2_revenue_decomposition_estimates.do  --  PNAS Nexus replication package
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "/Users/holyfantastic/Dropbox/AI/PNAS_NEXUS/replication_package"
}

run "$replication/code/00_declare_path.do"

capture log close standard
log using "$replication_log/table2_revenue_decomposition_estimates.log", replace text name(standard)

capture log close delta
log using "$table_overleaf/delta.log", replace text name(delta)
**# Part 1

{

use  "$temp/vacation_connected_call_level"  , clear
replace total_payment_amt_num = 0 if missing(total_payment_amt_num)
	keep if vacation == 1 

cap gen gender_customer_num = ( gender_customer == "Female" )
replace province_capital = 1 if missing(province_capital)
replace gap_creat_lastcallthrough = gap_creat_lastcallthrough / 1

local i = 0
foreach y in if_succeed  payment_amt_num  {

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

	reghdfe `y' if_AI province_capital gender_customer_num  ///
	, absorb(date_create_time hour_create_time)  cl(crm_user_id)

	
	matrix V = e(V)
	matrix b = e(b)

	display "Constant = " _b[_cons]
	display "SE(Constant) = " _se[_cons]

	display "if_AI = " _b[if_AI]
	display "SE(if_AI) = " _se[if_AI]

	display "Cov(Constant, if_AI) = " V[colnumb(V,"_cons"), colnumb(V,"if_AI")]

	* AI success rate = Constant + if_AI
	lincom _cons + if_AI
	
restore	
}	
	
	
}

**# Part 2

	use "$temp/full_data_no_collapse" , clear  
	replace if_connected = 1 if if_succeed == 1
	replace if_connected = if_connected * 100
	replace if_succeed = if_succeed * 100
	
	
	gen if_call_w_1_day  = gap_create_first_call < 3600 * 24
	gen if_call_w_30_min  = gap_create_first_call < 3600 * 1/2	
	gen if_call_w_6_hour  = gap_create_first_call < 3600 * 6
	gen if_call_w_3_day  = gap_create_first_call < 3600 * 24 * 3

	* baseline within 10 min
	gen bin_gap_range = 0 if if_call_w_10_min
	replace bin_gap_range = 1 if !if_call_w_10_min & if_call_w_30_min
	replace bin_gap_range = 2 if !if_call_w_30_min & if_call_w_1_hour
	replace bin_gap_range = 3 if !if_call_w_1_hour & if_call_w_6_hour
	replace bin_gap_range = 4 if !if_call_w_6_hour & if_call_w_1_day
	replace bin_gap_range = 5 if !if_call_w_1_day & if_call_w_3_day
	replace bin_gap_range = 6 if !if_call_w_3_day 
	
	reghdfe if_succeed ib0.bin_gap_range  , a(crm_user_id date_create_time) vce(cl crm_user_id)

* =========================================================
* Primitive coefficients and variance-covariance terms
* for Delta Method calculation
* =========================================================

reghdfe if_succeed ib0.bin_gap_range, a(crm_user_id date_create_time) vce(cl crm_user_id)

display "--------------------------------------------------"
display "Baseline coefficient"
display "beta_0 (_cons)   = " %12.8f _b[_cons]
display "se_beta_0        = " %12.8f _se[_cons]

display "--------------------------------------------------"
display "Delay-bucket coefficients"
display "beta_4 (6h-1d)   = " %12.8f _b[4.bin_gap_range]
display "se_beta_4        = " %12.8f _se[4.bin_gap_range]

display "beta_5 (<3d)     = " %12.8f _b[5.bin_gap_range]
display "se_beta_5        = " %12.8f _se[5.bin_gap_range]

display "beta_6 (>3d)     = " %12.8f _b[6.bin_gap_range]
display "se_beta_6        = " %12.8f _se[6.bin_gap_range]

* =========================================================
* Variance-covariance matrix elements
* =========================================================
matrix V = e(V)

local c_cons = colnumb(V, "_cons")
local c4     = colnumb(V, "4.bin_gap_range")
local c5     = colnumb(V, "5.bin_gap_range")
local c6     = colnumb(V, "6.bin_gap_range")

display "--------------------------------------------------"
display "Covariances with baseline coefficient"
display "cov(_cons, beta_4) = " %12.8f V[`c_cons', `c4']
display "cov(_cons, beta_5) = " %12.8f V[`c_cons', `c5']
display "cov(_cons, beta_6) = " %12.8f V[`c_cons', `c6']

display "--------------------------------------------------"
display "Variances of delay-bucket coefficients"
display "var(beta_4)        = " %12.8f V[`c4', `c4']
display "var(beta_5)        = " %12.8f V[`c5', `c5']
display "var(beta_6)        = " %12.8f V[`c6', `c6']

display "--------------------------------------------------"
display "Implied delayed human success rates"
display "p_h0      = beta_0            = " %12.8f _b[_cons]
display "p_h_ideal = beta_0 + beta_4  = " %12.8f (_b[_cons] + _b[4.bin_gap_range])
display "p_h_lower = beta_0 + beta_5  = " %12.8f (_b[_cons] + _b[5.bin_gap_range])
display "p_h_med   = beta_0 + beta_6  = " %12.8f (_b[_cons] + _b[6.bin_gap_range])

display "--------------------------------------------------"

* =========================================================
* lincom standard errors for delayed human success rates
* =========================================================
display "SE for implied delayed human success rates"
lincom _cons + 4.bin_gap_range
lincom _cons + 5.bin_gap_range
lincom _cons + 6.bin_gap_range

display "--------------------------------------------------"

		
	local base = _b[_cons]
	
	matrix B=J(7,3,0)
	forvalues i=1(1)6{ 
	   scalar a`i'=_b[`i'.bin_gap_range] / `base'
	   scalar b`i'=_se[`i'.bin_gap_range] / `base'
		mat B[`i',1]=`i'
		mat B[`i',2]=a`i'
		mat B[`i',3]=b`i'
	}
	
	mat list B

log close delta
log close standard

capture log close _all
