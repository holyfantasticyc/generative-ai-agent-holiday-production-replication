*-------------------------------------------------------------------
* fig3_duration_relationship.do  --  PNAS Nexus replication package
*
* Generates Figure 3 (Relationship Between Success Rate and Call Duration).
*
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "<REPLICATION_ROOT>"
}
run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/fig3_duration_relationship.log", replace text

**# Figure: Success Rate - time relationship 

{
use  "$temp/vacation_connected_callcontract_level"  , clear

* calcualte precentile
preserve
cap drop temp
gen temp = bridge_duration_num <= 450  // Target comparison
sum temp 
restore

bys if_succeed: sum bridge_duration_num , de

keep if bridge_duration_num < 900

set scheme white_ptol



**## Histogram - Human
sum bridge_duration_num if if_AI == 0 & if_succeed == 0, de
local x_median = round(r(p50),1)
local x_mean = round(r(mean),1)

twoway (histogram bridge_duration_num if if_AI == 0 & if_succeed == 0, fraction fc($control_color)) ///
		, xtitle(" Human Representative - Unsuccessful Calls ")   ///
		ylabel(0(0.1)0.4, nogrid labelminlen(3) labsize(vsmall)) ///
		xline(`x_mean' , lc($control_color)) ///
		text(0.3 160 "Mean = `x_mean'" , color(black) size(small)) ///
		xlabel(0(200)800 900 , nogrid gmax) fysize(30) saving(hx1, replace) 

sum bridge_duration_num if if_AI == 0 & if_succeed == 1, de
local x_median = round(r(p50),1)
local x_mean = round(r(mean),1)

twoway (histogram bridge_duration_num if if_AI == 0 & if_succeed == 1, fraction fc($control_color)) ///
		, xtitle(" Human Representative - Successful Calls ")   ///
		ylabel(0(0.1)0.4, nogrid labelminlen(3) labsize(vsmall)) ///
		xline(`x_mean' , lc($control_color)) ///
		text(0.3 380 "Mean = `x_mean'" , color(black) size(small)) ///
		xlabel(0(200)800 900 , nogrid gmax) fysize(30) saving(hx2, replace)
			
 graph combine  hx1.gph hx2.gph ///
		,    rows(2)  imargin(0 0 0 0) ///
		graphregion(margin(zero)) fysize(60) ///
	   saving(hx_human, replace) 

**## Histogram - AI

sum bridge_duration_num if if_AI == 1 & if_succeed == 0, de
local x_median = round(r(p50),1)
local x_mean = round(r(mean),1)

twoway (histogram bridge_duration_num if if_AI == 1 & if_succeed == 0, fraction fc($treat_color)) ///
		, xtitle(" AI Representative - Unsuccessful Calls ")   ///
		ylabel(0(0.1)0.4, nogrid labelminlen(3) labsize(vsmall)) ///
		xline(`x_mean' , lc($control_color)) ///
		text(0.3 150 "Mean = `x_mean'" , color(black) size(small)) ///
		xlabel(0(200)800 900 , nogrid gmax) fysize(30) saving(hx1, replace) 

sum bridge_duration_num if if_AI == 1 & if_succeed == 1, de
local x_median = round(r(p50),1)
local x_mean = round(r(mean),1)

twoway (histogram bridge_duration_num if if_AI == 1 & if_succeed == 1, fraction fc($treat_color)) ///
		, xtitle(" AI Representative - Successful Calls ")   ///
		ylabel(0(0.1)0.4, nogrid labelminlen(3) labsize(vsmall)) ///
		xline(`x_mean' , lc($control_color)) ///
		text(0.3 280 "Mean = `x_mean'" , color(black) size(small)) ///
		xlabel(0(200)800 900 , nogrid gmax) fysize(30) saving(hx2, replace)
			
 graph combine  hx1.gph hx2.gph ///
		,    rows(2)  imargin(0 0 0 0) ///
		graphregion(margin(zero)) fysize(60) ///
		saving(hx_AI, replace) 

		
 graph combine  hx_human.gph hx_AI.gph ///
		,    rows(1)  imargin(0 0 0 0) ///
		graphregion(margin(zero)) fysize(60) ///
		subtitle("Panel C. Distribution of Call Duration",size(small)) saving(hx, replace) 

		
**## Relationship
		
foreach y in if_succeed  {
// local y if_succeed

if "`y'" == "if_succeed"{
	
	global ytitle = "% Succeed"
	global title = "Panel B. Success Rate - Call Duration Relationship"
	
}
if "`y'" == "payment_amt_num"{
	
// 	keep if if_succeed
	global ytitle = "Payment Amount (CNY)"
	global title = "Payment Amount - Call Duration"
	
}

tw || ///
	 fpfitci `y' bridge_duration_num if if_AI == 0 , ciplot(rline) color($control_color) clp(solid) clw(medthick) alp(dash) || ///
	 fpfitci `y' bridge_duration_num if if_AI == 1 , ciplot(rline) color($treat_color)  clp(solid)  clw(medthick) alp(dash) || ///
	, ytitle("$ytitle") xtitle("Call Duration (s)") xsca(alt )   ///
	legend(order( 2 "Human Representative " 4 "AI Representative " ) ring(0) rows(1) pos(11) size(small))  ///
	 xline(450) xlabel(0(200)800 900 , nogrid) ylabel(, nogrid) fysize(120) subtitle("$title",size(small)) ///
		 saving(relation, replace) 
		
}
		

**## t-test

use  "$temp/vacation_connected_callcontract_level"  , clear

**### < 450

{
local y  if_succeed
local group_variable if_AI

preserve
keep if vacation == 1 
keep if bridge_duration_num < 450 

if "`y'" == "if_succeed"{
	
	global ytitle = "%"
	replace `y' = `y' * 100
	
}

	* regression coefficent 
	reghdfe `y' if_AI , noa 
	local coe = round(_b[if_AI],0.01)
	
	* figure
	collapse (mean) mean= `y' (sem) sem= `y', by(`group_variable')
	gen lower_bound = mean - 1.96 * sem
	gen upper_bound = mean + 1.96 * sem

	set scheme white_ptol
	twoway (bar mean `group_variable' if `group_variable' == 0 , barwidth(0.5) fcolor($control_color) lcolor($control_color) lwidth(medium)) ///
		   (bar mean `group_variable' if `group_variable' == 1 , barwidth(0.5) fcolor($treat_color) lcolor($treat_color) lwidth(medium)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 0, lw(medium) lcolor($control_color) lp(dash)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 1 , lw(medium) lcolor($treat_color) lp(dash)) ///
		   (scatteri 2.45 0 2.45 1,  recast(line) lw(medthin)  mc(none) lc(black) lp("-")) ///
		   (scatteri 2.45 0 2.45 1,  recast(dropline) base(2.35) lw(medthin) mc(none) lc(black) lp(solid)) ///
		   , legend(off ) xlabel( 0 "Human Representative " 1 "AI Representative "  , nogrid ) ///
		    ylabel(1(0.5)2.6, nogrid ) 	subtitle("< 450s")	   	text(2.6 0.5 "diff = `coe', p > 0.1") ///
		   xtitle("")   ytitle($ytitle )  	 graphregion(margin(zero)) ///
		   saving(ttest1, replace)

// 			   name("Fig_`y'_vacation",replace ) 
			
// gr_edit .plotregion1.plot2.style.editstyle marker(size(huge)) 		

restore

}

**### > 450

{
local y  if_succeed
local group_variable if_AI

preserve
keep if vacation == 1 
keep if bridge_duration_num > 450 

if "`y'" == "if_succeed"{
	
	global ytitle = "%"
	replace `y' = `y' * 100
	
}

	* regression coefficent 
	reghdfe `y' if_AI , noa 
	local coe = round(_b[if_AI],0.01)
	
	* figure
	collapse (mean) mean= `y' (sem) sem= `y', by(`group_variable')
	gen lower_bound = mean - 1.96 * sem
	gen upper_bound = mean + 1.96 * sem

	set scheme white_ptol
	twoway (bar mean `group_variable' if `group_variable' == 0 , barwidth(0.5) fcolor($control_color) lcolor($control_color) lwidth(medium)) ///
		   (bar mean `group_variable' if `group_variable' == 1 , barwidth(0.5) fcolor($treat_color) lcolor($treat_color) lwidth(medium)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 0, lw(medium) lcolor($control_color) lp(dash)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 1 , lw(medium) lcolor($treat_color) lp(dash)) ///
		   (scatteri 42.5 0 42.5 1,  recast(line) lw(medthin)  mc(none) lc(black) lp("-")) ///
		   (scatteri 42.5 0 42.5 1,  recast(dropline) base(41) lw(medthin) mc(none) lc(black) lp(solid)) ///
		   , legend(off ) xlabel( 0 "Human Representative " 1 "AI Representative "  , nogrid ) ///
		    ylabel(10(10)47, nogrid ) 	subtitle("> 450s")		   	text(46 0.5 "diff = `coe', p{superscript:***} < 0.01") ///
		   xtitle("")   ytitle($ytitle ) 	 graphregion(margin(zero)) ///
		   saving(ttest2, replace)

// 			   name("Fig_`y'_vacation",replace ) 
			
// gr_edit .plotregion1.plot2.style.editstyle marker(size(huge)) 		

restore

}

 graph combine  ttest1.gph ttest2.gph ///
		,    rows(1)  imargin(0 0 0 0) ///
		graphregion(margin(zero)) fysize(60) ///
		subtitle("Panel A. Success Rate Difference by Call Duration",size(small)) ///   
		saving(ttest, replace) 
		
		
{


**## *Figure: Duration
use  "$temp/vacation_connected_call_level"  , clear
cap gen gender_customer_num = ( gender_customer == "Female" )
replace province_capital = 1 if missing(province_capital)

replace payment_amt_num = 0 if missing(payment_amt_num)
replace total_payment_amt_num = 0 if missing(total_payment_amt_num)

* only succeed phone call
{
	
local y bridge_duration_num
local group_variable if_AI

if "`y'" == "bridge_duration_num"{
	
	global ytitle = " Seconds "
	
}

preserve

keep if if_succeed

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
		   (scatteri 920 0 920 1,  recast(line) lw(medthin)  mc(none) lc(black) lp("-")) ///
		   (scatteri 920 0 920 1,  recast(dropline) base(860) lw(medthin) mc(none) lc(black) lp(solid)) ///
		   , legend(off ) xlabel( 0 "Human Representative " 1 "AI Representative " , nogrid)  ///
				   xtitle("")   ytitle( $ytitle ) /// 
		    ylabel(100(200)980, nogrid ) 		text(955 0.5 "diff = `coe', p{superscript:***} < 0.01") ///
		   subtitle("Duration of Success Calls")  graphregion(margin(zero)) 
		graph export "$figure_overleaf/Bar_plot2_duration_succeed_FE.png", as(png) name("Graph") replace		
		graph export "$figure_overleaf/Bar_plot2_duration_succeed_FE.pdf", as(pdf) name("Graph") replace		

restore


}



}	

		
		
		
**## Combine
		
 graph combine    ttest.gph relation.gph  hx.gph ///
		,    cols(1)      imargin(0 0 0 0) ///
		graphregion(margin(medium))   xsize(4)  ysize(3) 
		
	graph export "$figure_overleaf/relationship_duration_succeed.png", as(png) name("Graph") replace		
	graph export "$figure_overleaf/relationship_duration_succeed.pdf", as(pdf) name("Graph") replace		


}

capture log close
