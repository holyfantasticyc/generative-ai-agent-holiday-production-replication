*-------------------------------------------------------------------
* figA3_coef_alter_FEs.do  --  PNAS Nexus replication package
*
* Generates Figure A.3 (Estimated Performance Gap with Alternative Controls and FEs).
*
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "<REPLICATION_ROOT>"
}
run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/figA3_coef_alter_FEs.log", replace text

**# *Figure: Results with difference FEs and controls
{

use  "$temp/vacation_connected_call_level"  , clear
replace total_payment_amt_num = 0 if missing(total_payment_amt_num)

cap gen gender_customer_num = ( gender_customer == "Female" )
replace province_capital = 1 if missing(province_capital)
replace payment_amt_num = 0 if if_succeed == 0

foreach y in  if_succeed payment_amt_num if_refund bridge_duration_num {
dis   "`y'"
preserve

if "`y'" == "if_succeed"{
	
	local ytitle = "%"
	replace `y' = `y' * 100
	
}
if "`y'" == "payment_amt_num"{
	
	local ytitle = "Chinese Yuan (CNY)"

}
if "`y'" == "bridge_duration_num"{
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

{
	matrix A=J(5,3,.)
	local k = 1

	/*Gap line*/
	mat A[`k',1]=`k'
	mat A[`k',2]=.
	mat A[`k',3]=.
	local k = `k' + 1
	
	* Parsimonious
	{

	reghdfe `y' if_AI ///
	, noa cl(crm_user_id)

	mat A[`k',1]=`k'
	mat A[`k',2]=_b[if_AI]
	mat A[`k',3]=_se[if_AI]
	local k = `k' + 1
	
	
	}
	
	*with controls

	{

	reghdfe `y' if_AI province_capital gender_customer_num ///
	, noa cl(crm_user_id)

	mat A[`k',1]=`k'
	mat A[`k',2]=_b[if_AI]
	mat A[`k',3]=_se[if_AI]
	local k = `k' + 1
	
	
	}

	* add date fixed effects
	{

	reghdfe `y' if_AI province_capital gender_customer_num ///
	, absorb(date_create_time )  cl(crm_user_id)

	mat A[`k',1]=`k'
	mat A[`k',2]=_b[if_AI]
	mat A[`k',3]=_se[if_AI]
	local k = `k' + 1
	

	}

	* add hour fixed effects
	{

	reghdfe `y' if_AI province_capital gender_customer_num ///
	, absorb(date_create_time hour_create_time)  cl(crm_user_id)

	mat A[`k',1]=`k'
	mat A[`k',2]=_b[if_AI]
	mat A[`k',3]=_se[if_AI]
	local k = `k' + 1

	}

}	

	mat list A
	clear
	svmat A
	sum A1 
	drop if A1>r(max)
	drop if A2 == .
	keep A1 A2 A3
	
	rename A2 coef
	rename A3 se
	rename A1 n1
	gen up = coef + 1.96 * se
	gen low = coef - 1.96 * se
	replace n1 = - n1
	
	set scheme white_ptol

	*------------------------------------------------------begin------------
	if "`y'" == "if_succeed"{	
		
	#delimit ;	
	tw 
	(bar  coef n1 , barwidth(0.7) color(orange%50) hori lwidth(medium)   )
	(rcap up low n1 , lp(dash) lc(black) hori  lw(medthick))	
	, legend(off)
	ylabel( -2 "No Controls" -3 "Add Controls" -4 `""Controls" "+ Date FE""'  -5 `""Controls" "+ Date FE" "+ Hours FE" "'    , nogrid) ytitle("")
	xlabel( -3(0.5)0 , nogrid) xtitle("Difference in Success Rate, %") 
	saving(f_`y', replace) 
	;
	#delimit cr
	
	}
	
	if "`y'" == "payment_amt_num"{

	#delimit ;	
	tw 
	(bar  coef n1 , barwidth(0.7) color(orange%50) hori lwidth(medium)   )
	(rcap up low n1 , lp(dash) lc(black) hori  lw(medthick))	
	, legend(off)
	ylabel( -2 "No Controls" -3 "Add Controls" -4 `""Controls" "+ Date FE""'  -5 `""Controls" "+ Date FE" "+ Hours FE" "'    , nogrid) ytitle("")
	xlabel(  , nogrid) xtitle("Difference in Payment Amount per calling, CNY")
	saving(f_`y', replace) 
	;
	#delimit cr
	
	}	
		
	if "`y'" == "bridge_duration_num"{

	#delimit ;	
	tw 
	(bar  coef n1 , barwidth(0.7) color(orange%50) hori lwidth(medium)   )
	(rcap up low n1 , lp(dash) lc(black) hori  lw(medthick))	
	, legend(off)
	ylabel( -2 "No Controls" -3 "Add Controls" -4 `""Controls" "+ Date FE""'  -5 `""Controls" "+ Date FE" "+ Hours FE" "'    , nogrid) ytitle("")  
	xlabel(-650(100)-350, nogrid) xtitle("Difference in  Duration of Success Calls, s")
	saving(f_`y', replace) 
	;
	#delimit cr
	
	}	
	

	if "`y'" == "if_refund"{

	#delimit ;	
	tw 
	(bar  coef n1 , barwidth(0.7) color(orange%50) hori lwidth(medium)   )
	(rcap up low n1 , lp(dash) lc(black) hori  lw(medthick))	
	, legend(off)
	ylabel( -2 "No Controls" -3 "Add Controls" -4 `""Controls" "+ Date FE""'  -5 `""Controls" "+ Date FE" "+ Hours FE" "'    , nogrid) ytitle("")
	xlabel(  , nogrid) xtitle("Difference in Refund Rate , %")
	saving(f_`y', replace) 
	;
	#delimit cr
	
	}			
	*------------------------------------------------------over------------
	
restore	
}	
	
	 
	 graph combine  f_if_succeed.gph f_payment_amt_num.gph ///
					f_if_refund.gph f_bridge_duration_num.gph  ///
		,    rows(2)  imargin(0 0 0 0) ///
		graphregion(margin(vsmall)) 
		
	graph export "$figure_overleaf/Coef_w_alter_FEs.png", as(png) name("Graph") replace		
	graph export "$figure_overleaf/Coef_w_alter_FEs.pdf", as(pdf) name("Graph") replace		
	
	
}

capture log close
