*-------------------------------------------------------------------
* fig4_case_study.do  --  PNAS Nexus replication package
*
* Produces the two panels of Figure 4 ("Overall Impact of Introducing
* AI Representative during Holiday"):
*   Panel A: case_study_nationalday_R1.pdf  (handling capacity)
*   Panel B: rate_time_gap_relationsip_R1.pdf (delay-vs-success)
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "/Users/holyfantastic/Dropbox/AI/PNAS_NEXUS/replication_package"
}
run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/fig4_case_study.log", replace text

*===================================================================
* Panel A: National Day case study (handling capacity)
*  source: RR1/Figure_case_study_nationalday.do
*===================================================================
**# Figure: Impact of AI on company case handelling capacity
	
**## vacation
use "$temp/full_data_no_collapse_w_AI" , clear  

gen if_call_w_1_day  = gap_create_first_call < 3600 * 24
gen if_call_w_30_min  = gap_create_first_call < 3600 * 1/2	
gen if_call_w_6_hour  = gap_create_first_call < 3600 * 6
merge m:1 date_create_time using "$temp/vacation_date_create_time" , keep(3) nogen
gen overtime = (hour_create_time >= 20)
cap drop if overtime == 1
*drop data that should not exists
drop if if_AI == 1 & vacation_create_time == 0 & overtime == 0
gen N = 1

preserve
	collapse (max) if_AI_date = if_AI , by( date_create_time year_create_time month_create_time day_create_time dow_create_time )
	save "$temp/temp" , replace
restore

**### Case study: national day long weekend
merge m:1  date_create_time using "$temp/temp" , keep(3) 

keep if (date_create_time >= 23623 & date_create_time <= 23656 ) ///
		| (date_create_time >= 23254 & date_create_time <= 23288 )

gen national_holiday = ( (date_create_time >= 23650 & date_create_time <= 23656 ) ///
		| (date_create_time >= 23282 & date_create_time <= 23288 ))
	
replace if_AI = 0 if national_holiday == 0
replace payment_amt_num = 0 if if_succeed == 0

collapse (sum) N_total_calls = N  N_succeed_calls = if_succeed tota_payment = payment_amt_num (mean) if_call_w_1_d  , by( date_create_time national_holiday year_create_time month_create_time day_create_time dow_create_time if_AI if_AI_date )

bys year_create_time : egen temp_min = min(date_create_time) if national_holiday
bys year_create_time : egen temp_min2 = min(temp_min) 
gen x = date_create_time - temp_min2

gen x_week = -4 if x >= -28 & x <= -22 
replace x_week = -3 if x >= -21 & x <= -15 
replace x_week = -2 if x >= -14 & x <= -8 
replace x_week = -1 if x >= -7 & x <= -1
replace x_week = 0 if x >= 0 & x <= 6

collapse (mean) N_total_calls N_succeed_calls tota_payment (mean) if_call_w_1_d  , by( year_create_time x_week  if_AI )

sum N_total_calls if  year_create_time == 2024 & x_week == 0 & if_AI == 0   
replace N_total_calls = N_total_calls + r(mean) if  year_create_time == 2024 & x_week == 0 & if_AI == 1  

global counterfactual = 0
* create counterfactual
if $counterfactual == 1{
	
foreach var in N_total_calls N_succeed_calls tota_payment{
	qui: sum `var' if year_create_time == 2023 & x_week == -1
	local y1 =  r(mean) 
	qui: sum `var' if year_create_time == 2023 & x_week == 0
	local y2 = r(mean)  
	local dy = `y2' / `y1'
	qui: sum `var' if year_create_time == 2024 & x_week == -1
	local y3 = r(mean)  
	
	replace `var' = `dy' * `y3' if year_create_time == 2024 & x_week == 0 & if_AI == 0
	
}

}

* normalize
preserve 
	cap drop n y temp* normalizer
	gen y = N_total_calls
	bys year_create_time : gen n = _n

	global normalize_method = 2
	if $normalize_method == 1{
		gen temp = y if n == 1
		bys year_create_time: egen normalizer = max(temp)
	}
	if $normalize_method == 2{
		gen temp = y if n == 1 & year_create_time == 2023
		egen normalizer = max(temp)
	}
	replace y = y / normalizer

		qui: sum y if year_create_time == 2024 & x_week == 0 & if_AI == 0
		local y1 =  r(mean) 
		qui: sum y if year_create_time == 2024 & x_week == 0 & if_AI == 1
		local y2 =  r(mean) 
		local boost = round( (`y2' - `y1') / `y1' * 100 , 1  )
		dis `boost'
		
		
	set scheme white_ptol

	twoway || ///
		scatter y x if year_create_time == 2023 ,mcolor(blue%50) msize(medium) connect(l) lcolor(blue%50) lpattern(solid) lw(medium)   || ///
		scatter y x if year_create_time == 2024 & x != 0, mcolor(red%50) msize(medium) connect(l) lcolor(red%50) lpattern(solid) lw(medium) || ///
		scatter y x if year_create_time == 2024 & if_AI == 0 & x >= -1 , mcolor(red%50) msize(medium) connect(l) lcolor(red) lpattern(shortdash_dot) lw(medium) || ///
		scatter y x if year_create_time == 2024 & ((if_AI == 1 & x >= -1) | (if_AI == 0 & x == -1)) , ms(d) connect(l) mcolor(red) msize(medium) connect(l) lcolor(red) lpattern(solid) lw(thick) || ///
		scatteri 1.27 0.3 0.29 0.3 , recast(line) lw(medthin)  mc(none) lc(black) lp("-") ||  ///
		scatteri 1.27 0.3 1.27 0.18 , recast(line) lw(medthin)  mc(none) lc(black) lp(solid) ||  ///
		scatteri 0.29 0.3 0.29 0.18 , recast(line) lw(medthin)  mc(none) lc(black) lp(solid) ||  ///
		, legend(on order(1 "Only Human, 2023 Sept. + Holiday Week" 2 "Only Human, 2024 Sept." 4 "Human + AI, 2024 Holiday Week" 3 "Only Human, 2024 Holiday Week"  ) ring(0) pos(7) rows(4)) xlabel( -4  "T-4 Week" -3 "T-3 Week" -2 "T-2 Week" -1 "T-1 Week" 0 `" "Holiday Week"  "{bf: (AI Treatment)}" "' 1.5 " " , nogrid) ///
	   xtitle("")   ytitle( " Number of Calls Finished (normalized)" ) /// 
		ylabel(0(0.5)1.7, nogrid ) 	 text(0.78 0.7 "{bf: AI boost:}" )  text(0.72 1.0 "# of calls: `boost'%") graphregion(margin(zero))
		
		graph export "$figure_overleaf/case_study_nationalday_R1.png", as(png) name("Graph") replace
		graph export "$figure_overleaf/case_study_nationalday_R1.pdf", as(pdf) name("Graph") replace

restore

*===================================================================
* Panel B: Decline in connection / success rate by follow-up delay
*  source: RR1/Figure_rate_time_gap_relationsip.do
*===================================================================
**#Figure: Relationship between call gap and Success Rate

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

	reghdfe if_connected ib0.bin_gap_range  , a(crm_user_id date_create_time) vce(cl crm_user_id)

	local base = _b[_cons]
	
	matrix A=J(7,4,0)
	forvalues i=1(1)6{ 
	   scalar a`i'=_b[`i'.bin_gap_range] / `base' 
	   scalar b`i'=(_b[`i'.bin_gap_range]+1.96*_se[`i'.bin_gap_range]) / `base'
	   scalar c`i'=(_b[`i'.bin_gap_range]-1.96*_se[`i'.bin_gap_range]) / `base' 
		mat A[`i',1]=`i'
		mat A[`i',2]=a`i'
		mat A[`i',3]=b`i'
		mat A[`i',4]=c`i'
	}
	
	preserve
		clear
		svmat A
		gen bin = A1
		replace A1 = A1 
		save "$temp/temp_A" , replace
	restore

preserve
	
	
	reghdfe if_succeed ib0.bin_gap_range  , a(crm_user_id date_create_time) vce(cl crm_user_id)
	local base = _b[_cons]
	
	matrix B=J(7,4,0)
	forvalues i=1(1)6{ 
	   scalar a`i'=_b[`i'.bin_gap_range] / `base'
	   scalar b`i'=(_b[`i'.bin_gap_range]+1.96*_se[`i'.bin_gap_range]) / `base'
	   scalar c`i'=(_b[`i'.bin_gap_range]-1.96*_se[`i'.bin_gap_range]) / `base'
		mat B[`i',1]=`i'
		mat B[`i',2]=a`i'
		mat B[`i',3]=b`i'
		mat B[`i',4]=c`i'
	}
	clear
	svmat B
	gen bin = B1
	replace B1 = B1 + 0.1 if B1 != 0 
	save "$temp/temp_B" , replace
	
restore


use "$temp/temp_A" , clear
merge 1:1 bin using "$temp/temp_B", nogen

foreach var in A2 A3 A4 B2 B3 B4{
	replace `var' = `var' * 100
}

set scheme white_jet

twoway  /// 
    (scatter A2 A1, mcolor(green%60) msize(small) connect(l) ///
        lcolor(green%60) lpattern(dash) lw(medium)) ///
    (rcap A3 A4 A1 if A1 != 0, lcolor(green%60) lpattern(solid)) ///
    (scatter B2 B1,  ms(d) mcolor(orange) msize(small) ///
        connect(l) lcolor(orange) lpattern(solid) lw(medthick)) ///
    (rcap B3 B4 B1 if A1 != 0,lcolor(orange) ///
        lpattern(solid) lw(medium)) ///
    , ///
    yscale(range(-100 0)) ///
    ylabel(-100(20)0, nogrid) ///
    yline(0, lcolor(gs10)) ///
    xlabel(0 "< 10min" 1 "10 - 30min" 2 "30min - 1h" 3 "1 - 6h" ///
           4 "6h - 1d" 5 "1d - 3d" 6 "> 3d", nogrid) ///
    ytitle("Percentage Changes, %") ///
    legend(order(2 "Connected Rate" 4 "Success Rate") ///
           ring(0) pos(7) rows(1) size(medium)) ///
    xtitle("")

graph export "$figure_overleaf/rate_time_gap_relationsip_R1.png", as(png) name("Graph") replace		
graph export "$figure_overleaf/rate_time_gap_relationsip_R1.pdf", as(pdf) name("Graph") replace

capture log close
