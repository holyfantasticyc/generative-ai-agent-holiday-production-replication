*-------------------------------------------------------------------
* figA5_gender_succeed.do  --  PNAS Nexus replication package
*
* Generates Figure A.5 (success rate by representative-customer gender pairing).
*
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "/Users/holyfantastic/Dropbox/AI/PNAS_NEXUS/replication_package"
}
run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/figA5_gender_succeed.log", replace text

**## Success rate
{
	
use  "$temp/vacation_connected_call_level"  , clear
replace province_capital = 1 if missing(province_capital)


gen gender_combine = .
replace gender_combine = 0 if if_AI & gender_customer  == "Female" 
replace gender_combine = 1 if !if_AI & gender_cno == "Female"  &gender_customer  == "Female"
replace gender_combine = 2 if !if_AI & gender_cno == "Male"  &gender_customer  == "Female"
replace gender_combine = 4 if if_AI & gender_customer  == "Male"
replace gender_combine = 5 if !if_AI & gender_cno == "Female"  &gender_customer  == "Male"
replace gender_combine = 6 if !if_AI & gender_cno == "Male"  &gender_customer  == "Male"

drop if missing(gender_combine)

gen gender_cno_redefine = 1 if gender_cno == "Female" 
replace gender_cno_redefine = 2 if gender_cno == "Male" 
replace gender_cno_redefine = 0 if if_AI

gen gender_customer_redefine = 1 if gender_customer == "Female" 
replace gender_customer_redefine = 2 if gender_customer == "Male" 
replace gender_customer_redefine = 0 if if_AI

local y  if_succeed
local group_variable gender_combine

keep if vacation == 1 

if "`y'" == "if_succeed"{
	
	global ytitle = "%"
	replace `y' = `y' * 100
	
}

	* first tease out fixed effects
	cap drop `y'_res
	reghdfe `y' province_capital  , absorb(date_create_time hour_create_time)  cl(crm_user_id) res(`y'_res)
	local mean_control = _b[_cons]
	local se_control = _se[_cons]

	replace `y'_res = `y'_res + _b[_cons]

reghdfe `y'_res  i.gender_combine province_capital   ///
		, absorb(date_create_time hour_create_time) cl(crm_user_id)


	lincom 1.gender_combine	
	local coef1 = round(r(estimate),0.001)
	lincom 5.gender_combine - 4.gender_combine
	local coef2 = round(r(estimate),0.001)
	lincom 5.gender_combine - 4.gender_combine - 1.gender_combine	
	local coef3 = round(r(estimate),0.001)
		
		
	* figure
	clear
	set obs 6
	
	gen gender_combine = 0 in 1
	replace gender_combine = 1 in 2		
	replace gender_combine = 2 in 3		
	replace gender_combine = 4 in 4		
	replace gender_combine = 5 in 5		
	replace gender_combine = 6 in 6		

	gen mean = _b[_cons] if gender_combine == 0 

	replace mean = _b[1.gender_combine] + _b[_cons] if gender_combine == 1	
	replace mean = _b[2.gender_combine] + _b[_cons] if gender_combine == 2	
	replace mean = _b[4.gender_combine] + _b[_cons] if gender_combine == 4	
	replace mean = _b[5.gender_combine] + _b[_cons] if gender_combine == 5	
	replace mean = _b[6.gender_combine] + _b[_cons] if gender_combine == 6	
	gen sem = _se[_cons] if gender_combine == 0 
	
	lincom 1.gender_combine + _cons
	local se_treat1 = r(se)
	lincom 2.gender_combine + _cons
	local se_treat2 = r(se)
	lincom 4.gender_combine + _cons
	local se_treat3 = r(se)
	lincom 5.gender_combine + _cons
	local se_treat4 = r(se)	
	lincom 6.gender_combine + _cons
	local se_treat5 = r(se)		
	
	replace sem = `se_treat1' if gender_combine == 1	
	replace sem = `se_treat2' if gender_combine == 2	
	replace sem = `se_treat3' if gender_combine == 4	
	replace sem = `se_treat4' if gender_combine == 5	
	replace sem = `se_treat5' if gender_combine == 6		
	gen lower_bound = mean - 1.96 * sem
	gen upper_bound = mean + 1.96 * sem
	
	set scheme white_ptol
	
	
twoway (bar mean `group_variable' if `group_variable' == 0 , barwidth(0.7) fcolor($treat_color) lcolor($treat_color) lwidth(medium)) ///
		   (bar mean `group_variable' if `group_variable' == 1, barwidth(0.7) fcolor($control_color) lcolor($control_color) lwidth(medium)) ///
		   (bar mean `group_variable' if `group_variable' == 2 , barwidth(0.7) fcolor($control_color) lcolor($control_color) lwidth(medium)) ///
			(bar mean `group_variable' if `group_variable' == 4 , barwidth(0.7)  fcolor($treat_color) lcolor($treat_color) lwidth(medium)) ///
		   (bar mean `group_variable' if `group_variable' == 5 , barwidth(0.7)  fcolor($control_color) lcolor($control_color) lwidth(medium)) ///
		   (bar mean `group_variable' if `group_variable' == 6 , barwidth(0.7)  fcolor($control_color) lcolor($control_color) lwidth(medium)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 0, lw(medium) lcolor(black) lp(dash)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 1 , lw(medium) lcolor(black) lp(dash)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 2 , lw(medium) lcolor(black) lp(dash)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 4 , lw(medium) lcolor(black) lp(dash)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 5 , lw(medium) lcolor(black) lp(dash)) ///
		   (rcap lower_bound upper_bound `group_variable' if `group_variable' == 6 , lw(medium) lcolor(black) lp(dash)) ///
		   (scatteri 5.4 0 5.4 1,  recast(line) lw(medthin)  mc(none) lc(black) lp("-")) ///
		   (scatteri 5.4 0 5.4 1,  recast(dropline) base(5.1) lw(medthin) mc(none) lc(black) lp(solid)) ///
		   (scatteri 6.9 4 6.9 5,  recast(line) lw(medthin)  mc(none) lc(black) lp("-")) ///
		   (scatteri 6.9 4 6.9 5,  recast(dropline) base(6.6) lw(medthin) mc(none) lc(black) lp(solid)) ///
		   (scatteri 7.8 0.5 7.8 4.5,  recast(line) lw(medthin)  mc(none) lc(black) lp("-")) ///
		   (scatteri 7.8 0.5 7.8 4.5,  recast(dropline) base(7.5) lw(medthin) mc(none) lc(black) lp(solid)) ///
		   , legend(off )  ///
		    ylabel(0(1)9 , nogrid ) ///
			text(5.7 0.5 "diff = `coef1', p{superscript:***} < 0.01")  ///
			text(7.2 4.5 "diff = `coef2', p{superscript:***} < 0.01")  ///
			text(8.1 3 "diff = `coef3', p{superscript:*} < 0.1")  ///
			xlabel( ///
			0 `"AI (Female-voice)"' 1 `"Female"' 2  `"Male"' 3 " " 4 `"AI (Female-voice)"' 5 `"Female "' 6 `"Male"', nogrid labsize(small)) ///
		xtitle("")  ytitle($ytitle ) title("Success Rate") 	 graphregion(margin(zero)) ///
		 text(9 1 "{bf: Female Customer}") ///
		 text(9 5 "{bf: Male Customer}") 
		   
		graph export "$figure_overleaf/Coef_by_gender_if_succeed.png", as(png) name("Graph") replace	
		graph export "$figure_overleaf/Coef_by_gender_if_succeed.pdf", as(png) name("Graph") replace

}

capture log close
