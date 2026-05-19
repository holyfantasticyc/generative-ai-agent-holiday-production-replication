*-------------------------------------------------------------------
* fig1_outcome_bars.do  --  PNAS Nexus replication package
*
* Generates the three panels of Figure 1 (success rate, expected payment per call, refund rate).
*
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "<REPLICATION_ROOT>"
}
run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/fig1_outcome_bars.log", replace text

**# Figure 1: Main Results 
{

**## Figure: Main Results: Succeed
* Connect data, 电话(通)-合同 level
// use  "$temp/vacation_connected_callcontract_level"  , clear
use  "$temp/vacation_connected_call_level"  , clear
cap gen gender_customer_num = ( gender_customer == "Female" )
replace province_capital = 1 if missing(province_capital)

sum bridge_duration_num , de

// gen ln_gap_create_first_call = ln(gap_create_first_call)
// reghdfe if_succeed if_AI ln_gap_create_first_call  if vacation == 1 , a(date_create_time hour_create_time) cl(crm_user_id)

// reghdfe if_succeed if_AI ln_gap_create_first_call if hour_create_time == 20 , a(date_create_time hour_create_time) cl(crm_user_id)

{
local y  if_succeed
local group_variable if_AI

preserve
keep if vacation == 1 

if "`y'" == "if_succeed"{
	
	global ytitle = "%"
	replace `y' = `y' * 100
	
}

	
	* first tease out fixed effects
// 	local y if_succeed
	cap drop `y'_res
	reghdfe `y' province_capital gender_customer_num , absorb(date_create_time hour_create_time)  cl(crm_user_id) res(`y'_res)
// 	local mean_control = _b[_cons]
// 	local se_control = _se[_cons]

	replace `y'_res = `y'_res + _b[_cons]
	
	* regression coefficent with fixed effects
	reghdfe `y' if_AI province_capital gender_customer_num , absorb(date_create_time hour_create_time)  cl(crm_user_id)
	local coe = round(_b[if_AI],0.001)
	local mean_treat = _b[if_AI] + _b[_cons]
	local mean_control = _b[_cons]
	local se_control = _se[_cons]
	lincom if_AI + _cons
	local se_treat = r(se)

	* figure
	clear
	set obs 2
	gen `group_variable' = 0 in 1
	replace `group_variable' = 1 in 2
	gen mean = `mean_control' if `group_variable' == 0 
	replace mean = `mean_treat' if `group_variable' == 1 
	gen sem = `se_control' if `group_variable' == 0 
	replace sem = `se_treat' if `group_variable' == 1 	
	gen lower_bound = mean - 1.96 * sem
	gen upper_bound = mean + 1.96 * sem
	
	set scheme white_ptol
	twoway (bar mean `group_variable' if `group_variable' == 0 , barwidth(0.5) fcolor($control_color) lcolor($control_color) lwidth(medium)) ///
		   (bar mean `group_variable' if `group_variable' == 1 , barwidth(0.5) fcolor($treat_color) lcolor($treat_color) lwidth(medium)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 0, lw(medium) lcolor($control_color) lp(dash)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 1 , lw(medium) lcolor($treat_color) lp(dash)) ///
		   (scatteri 4.8 0 4.8 1,  recast(line) lw(medthin)  mc(none) lc(black) lp("-")) ///
		   (scatteri 4.8 0 4.8 1,  recast(dropline) base(4.5) lw(medthin) mc(none) lc(black) lp(solid)) ///
		   , legend(off ) xlabel( 0 "Human Representative " 1 "AI Representative "  , nogrid ) ///
		    ylabel(1(1)5, nogrid ) 		   	text(4.95 0.5 "diff = `coe', p{superscript:***} < 0.01") ///
		   xtitle("")   ytitle($ytitle ) title("Success Rate") 	 graphregion(margin(zero))
		  graph export "$figure_overleaf/Bar_plot_outcome_`y'_FE.png", as(png) name("Graph") replace
		  graph export "$figure_overleaf/Bar_plot_outcome_`y'_FE.pdf", as(pdf) name("Graph") replace

// 			   name("Fig_`y'_vacation",replace ) 
			
// gr_edit .plotregion1.plot2.style.editstyle marker(size(huge)) 		

restore

}
	
// 	graph export "$figure_overleaf/Bar_plot_`y'.png", as(png) name("Graph") replace

**## Figure: Main Results: Amount
* Connect data, 电话(通) level

// use  "$temp/vacation_connected_call_level"  , clear
use  "$temp/vacation_connected_call_level"  , clear
cap gen gender_customer_num = ( gender_customer == "Female" )
replace province_capital = 1 if missing(province_capital)
keep if if_succeed


// gen ln_payment_amt_num = log(payment_amt_num) 
// reghdfe ln_payment_amt_num if_AI if vacation == 1  , a(date_create_time hour_create_time) cl(crm_user_id)

{
	

	
foreach var in  payment_amt_num {
	
	cap drop  ln_`var'
	gen ln_`var' = log(`var')
	

	local y  `var'
	local group_variable if_AI


if "`var'" == "n_policy_succeed"{
	
	global ytitle = "Number of Policies"
	
}

if "`var'" == "payment_amt_num"{
	
// 	global ytitle = "Payment Amount (CNY)"
	global ytitle = "Chinese Yuan (CNY)"

}

if "`var'" == "scale_premium_num"{
	
	global ytitle = "Scale Premium (CNY)"
	
}

if "`var'" == "ins_amt_num"{
	
	replace `var' = `var' / 10000

	global ytitle = "Insurance Amount (10000 CNY)"
	
}


preserve
	keep if vacation == 1 
	
	* first tease out fixed effects
// 	local y if_succeed
	cap drop `y'_res
	reghdfe `y' province_capital gender_customer_num , absorb(date_create_time hour_create_time)  cl(crm_user_id) res(`y'_res)
// 	local mean_control = _b[_cons]
// 	local se_control = _se[_cons]

	replace `y'_res = `y'_res + _b[_cons]
	
	* regression coefficent with fixed effects
	reghdfe `y' if_AI province_capital gender_customer_num , absorb(date_create_time hour_create_time)  cl(crm_user_id)
	local coe = round(_b[if_AI],0.001)
	local mean_treat = _b[if_AI] + _b[_cons]
	local mean_control = _b[_cons]
	local se_control = _se[_cons]
	lincom if_AI + _cons
	local se_treat = r(se)

	* figure
	clear
	set obs 2
	gen `group_variable' = 0 in 1
	replace `group_variable' = 1 in 2
	gen mean = `mean_control' if `group_variable' == 0 
	replace mean = `mean_treat' if `group_variable' == 1 
	gen sem = `se_control' if `group_variable' == 0 
	replace sem = `se_treat' if `group_variable' == 1 	
	gen lower_bound = mean - 1.96 * sem
	gen upper_bound = mean + 1.96 * sem


// 	set scheme s1mono
	set scheme white_ptol


		twoway (bar mean `group_variable' if `group_variable' == 0 , barwidth(0.5) fcolor($control_color) lcolor($control_color) lwidth(medium)) ///
		   (bar mean `group_variable' if `group_variable' == 1 , barwidth(0.5) fcolor($treat_color) lcolor($treat_color) lwidth(medium)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 0, lw(medium) lcolor($control_color) lp(dash)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 1 , lw(medium) lcolor($treat_color) lp(dash)) ///
		   (scatteri 148 0 148 1,  recast(line) lw(medthin)  mc(none) lc(black) lp("-")) ///
		   (scatteri 148 0 148 1,  recast(dropline) base(142) lw(medthin) mc(none) lc(black) lp(solid)) ///
		   , legend(off ) xlabel( 0 "Human Representative " 1 "AI Representative " , nogrid) title(" Payment Amount per Transcations ") ///
		   xtitle("")   ytitle( $ytitle ) /// 
		    ylabel(60(20)153, nogrid ) 		text(152 0.5 "diff = `coe', p{superscript:***} < 0.01") graphregion(margin(zero))
		  graph export "$figure_overleaf/Bar_plot_outcome_`var'_FE.png", as(png) name("Graph") replace
		  graph export "$figure_overleaf/Bar_plot_outcome_`var'_FE.pdf", as(pdf) name("Graph") replace

restore

 ///
// 		   name("Fig_`var'_vacation",replace ) 
	
	
}

}		




**## Figure: Main Results: Unconditional Amount
* Connect data, 电话(通) level

// use  "$temp/vacation_connected_call_level"  , clear
use  "$temp/vacation_connected_call_level"  , clear
cap gen gender_customer_num = ( gender_customer == "Female" )
replace province_capital = 1 if missing(province_capital)
replace payment_amt_num = 0 if if_succeed == 0


// gen ln_payment_amt_num = log(payment_amt_num) 
// reghdfe ln_payment_amt_num if_AI if vacation == 1  , a(date_create_time hour_create_time) cl(crm_user_id)

{
	

	
foreach var in  payment_amt_num {
	
	cap drop  ln_`var'
	gen ln_`var' = log(`var')
	

	local y  `var'
	local group_variable if_AI


if "`var'" == "n_policy_succeed"{
	
	global ytitle = "Number of Policies"
	
}

if "`var'" == "payment_amt_num"{
	
// 	global ytitle = "Payment Amount (CNY)"
	global ytitle = "Chinese Yuan (CNY)"

}

if "`var'" == "scale_premium_num"{
	
	global ytitle = "Scale Premium (CNY)"
	
}

if "`var'" == "ins_amt_num"{
	
	replace `var' = `var' / 10000

	global ytitle = "Insurance Amount (10000 CNY)"
	
}


preserve
	keep if vacation == 1 
	
	* first tease out fixed effects
// 	local y if_succeed
	cap drop `y'_res
	reghdfe `y' province_capital gender_customer_num , absorb(date_create_time hour_create_time)  cl(crm_user_id) res(`y'_res)
// 	local mean_control = _b[_cons]
// 	local se_control = _se[_cons]

	replace `y'_res = `y'_res + _b[_cons]
	
	* regression coefficent with fixed effects
	reghdfe `y' if_AI province_capital gender_customer_num , absorb(date_create_time hour_create_time)  cl(crm_user_id)
	local coe = round(_b[if_AI],0.001)
	local mean_treat = _b[if_AI] + _b[_cons]
	local mean_control = _b[_cons]
	local se_control = _se[_cons]
	lincom if_AI + _cons
	local se_treat = r(se)

	* figure
	clear
	set obs 2
	gen `group_variable' = 0 in 1
	replace `group_variable' = 1 in 2
	gen mean = `mean_control' if `group_variable' == 0 
	replace mean = `mean_treat' if `group_variable' == 1 
	gen sem = `se_control' if `group_variable' == 0 
	replace sem = `se_treat' if `group_variable' == 1 	
	gen lower_bound = mean - 1.96 * sem
	gen upper_bound = mean + 1.96 * sem


// 	set scheme s1mono
	set scheme white_ptol


		twoway (bar mean `group_variable' if `group_variable' == 0 , barwidth(0.5) fcolor($control_color) lcolor($control_color) lwidth(medium)) ///
		   (bar mean `group_variable' if `group_variable' == 1 , barwidth(0.5) fcolor($treat_color) lcolor($treat_color) lwidth(medium)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 0, lw(medium) lcolor($control_color) lp(dash)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 1 , lw(medium) lcolor($treat_color) lp(dash)) ///
		  (scatteri 5.9 0 5.9 1,  recast(line) lw(medthin)  mc(none) lc(black) lp("-")) ///
		  (scatteri 5.9 0 5.9 1,  recast(dropline) base(5.7) lw(medthin) mc(none) lc(black) lp(solid)) ///
/// 
		  , legend(off ) xlabel( 0 "Human Representative " 1 "AI Representative " , nogrid) title(" Payment Amount per Calling ") ///
		   xtitle("")   ytitle( $ytitle ) ///
		   ylabel(2(0.5)6 6.2 " ", nogrid ) 		text(6.08 0.5 "diff = `coe', p{superscript:***} < 0.01") graphregion(margin(zero))

		  
		  graph export "$figure_overleaf/Bar_plot_outcome_`var'_uncon_FE.png", as(png) name("Graph") replace
		  graph export "$figure_overleaf/Bar_plot_outcome_`var'_uncon_FE.pdf", as(pdf) name("Graph") replace

restore

}

}		


**## Figure: refund

use  "$temp/vacation_connected_call_level"  , clear
cap gen gender_customer_num = ( gender_customer == "Female" )
replace province_capital = 1 if missing(province_capital)

replace payment_amt_num = 0 if missing(payment_amt_num)
replace total_payment_amt_num = 0 if missing(total_payment_amt_num)
* only succeed phone call
{		
local y  if_refund
local group_variable if_AI

if "`y'" == "if_refund"{
	
	global ytitle = "%"
	
}

preserve
	keep if if_succeed 
	replace if_refund = if_refund * 100

	* first tease out fixed effects
// 	local y if_succeed
	cap drop `y'_res
	reghdfe `y' province_capital gender_customer_num , absorb(date_create_time hour_create_time)  cl(crm_user_id) res(`y'_res)
// 	local mean_control = _b[_cons]
// 	local se_control = _se[_cons]

	replace `y'_res = `y'_res + _b[_cons]
	
	* regression coefficent with fixed effects
	reghdfe `y' if_AI province_capital gender_customer_num , absorb(date_create_time hour_create_time)  cl(crm_user_id)
	local coe = round(_b[if_AI],0.001)
	local mean_treat = _b[if_AI] + _b[_cons]
	local mean_control = _b[_cons]
	local se_control = _se[_cons]
	lincom if_AI + _cons
	local se_treat = r(se)

	* figure
	clear
	set obs 2
	gen `group_variable' = 0 in 1
	replace `group_variable' = 1 in 2
	gen mean = `mean_control' if `group_variable' == 0 
	replace mean = `mean_treat' if `group_variable' == 1 
	gen sem = `se_control' if `group_variable' == 0 
	replace sem = `se_treat' if `group_variable' == 1 	
	gen lower_bound = mean - 1.96 * sem
	gen upper_bound = mean + 1.96 * sem

	set scheme white_ptol
	twoway (bar mean `group_variable' if `group_variable' == 0 , barwidth(0.5) fcolor($control_color) lcolor($control_color) lwidth(medium)) ///
		   (bar mean `group_variable' if `group_variable' == 1 , barwidth(0.5) fcolor($treat_color) lcolor($treat_color) lwidth(medium)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 0, lw(medium) lcolor($control_color) lp(dash)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 1 , lw(medium) lcolor($treat_color) lp(dash)) ///
		(scatteri 27.1 0 27.1 1,  recast(line) lw(medthin)  mc(none) lc(black) lp("-")) ///
	   (scatteri 27.1 0 27.1 1,  recast(dropline) base(25.8) lw(medthin) mc(none) lc(black) lp(solid)) ///
		   , legend(off ) xlabel( 0 "Human Representative " 1 "AI Representative " , nogrid)  ///
				 xtitle("")   ytitle( $ytitle ) ///
			ylabel(10(5)25 29 " ", nogrid ) 		text(27.8 0.5 "diff = `coe', p{superscript:**} < 0.05") ///
		title("Refund Rate") graphregion(margin(zero))
		graph export "$figure_overleaf/Bar_plot2_if_refund_FE.png", as(png) name("Graph") replace		
		graph export "$figure_overleaf/Bar_plot2_if_refund_FE.pdf", as(pdf) name("Graph") replace		
	   
restore

//  ///
// 	    name("Fig_if_refund",replace ) 
		   

}


}

capture log close
