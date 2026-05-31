*-------------------------------------------------------------------
* fig2_workload_coef.do  --  PNAS Nexus replication package
*
* Generates the two panels of Figure 2 (success-rate gap by within-day task order; statutory overtime compensation schedule).
*
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "/Users/holyfantastic/Dropbox/AI/PNAS_NEXUS/replication_package"
}
run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/fig2_workload_coef.log", replace text

*===================================================================
* Panel A: Coef_by_workload.pdf
*===================================================================
**# Figure: Results: by workload
* Call-level data (one row per call): used so within-day task_order counts each
* call exactly once, rather than once per contract sold.
use  "$temp/vacation_connected_call_level"  , clear
keep if gap_creat_lastcallthrough < 3600 // restrict to follow-up within 1 hour

{
replace if_succeed = if_succeed * 100
sort crm_user_id date_create_time hour_create_time minute_create_time
bys crm_user_id date_create_time: gen task_order = _n
bys crm_user_id date_create_time  (task_order): egen cumulative_payment = sum(payment_amt_num)


replace task_order = 0 if if_AI 

gen bin_task_order = recode(task_order,0,3,6,10,15,20,30,50,100) // 0 to 0; 1-3 to 3; 4-6 to 6 ...

preserve

gen N = 1
collapse (sum) N , by(bin_task_order)
drop if bin_task_order == 0
egen total_N = sum(N)
gen fraction = N / total_N
gen x = _n
tw bar fraction x ,  barwi(0.8)	color($control_color)	xlabel( ///
			1 "1-3" 2 "4-6" 3 "7-10" 4 "11-15"  ///
			5 "15-20" 6 "21-30" 7 "31-50" 8 ">51" , nogrid gmax) ///
		ylabel( , nogrid labelminlen(3) labsize(small)) ///
				graphregion(margin(small)) ///
		ytitle("Fraction") /// 
		xtitle("Task's Order", size(medium))  fysize(20) saving(hx, replace)
		
restore


* If success as Y
reghdfe if_succeed ib0.bin_task_order  ///
		, absorb(date_create_time hour_create_time)   cl(crm_user_id)
		
		
	coefplot, vertical keep(*.bin_task_order) ///
		omitted  scheme(plotplain) ///
		recast(connected) lcolor($control_color) ///
		mcolor($control_color) ///
		msymbol(diamond) msize(small)  ///
		ciopt(recast(rcap)  lpattern(dash) 	lw(medthick) lcolor($control_color) ) ///
		yline(0, lpattern(solid) lcolor(gs12)) ///
		xlabel( ///
			1 "1-3" 2 "4-6" 3 "7-10" 4 "11-15"  ///
			5 "15-20" 6 "21-30" 7 "31-50" 8 ">51" ) ///
		xsca(alt )  ///
		ytitle(" Effects Size: % " , size(small)) /// 
		graphregion(margin(small)) ///
		saving(effect_by_load, replace)  xlabel(, nogrid) ylabel(, nogrid) fysize(60)

			graph combine  effect_by_load.gph hx.gph  ///
		,    cols(1)      imargin(0 0 0 0) ///
		graphregion(margin(medium))  xsize(4)  ysize(3)

			
			graph export "$figure_overleaf/Coef_by_workload.png", as(png) name("Graph") replace		
			graph export "$figure_overleaf/Coef_by_workload.pdf", as(pdf) name("Graph") replace
}

*===================================================================
* Panel B: Overtime_rule_panel.pdf  (statutory overtime compensation)
*===================================================================
**# Figure: statutory overtime compensation under Chinese labor law
clear

*------------------------------------------------------------*
* Build plotting dataset manually
*------------------------------------------------------------*
input ///
    x    pay
    1    100
    2    150
    3    200
    4    300
end

gen str8 pay_label = string(pay) + "%"

label define paycat ///
    1 "Base" ///
    2 "Overtime" ///
    3 "Rest day" ///
    4 "Holiday"
label values x paycat

*------------------------------------------------------------*
* Plot: compact panel version for combining
*------------------------------------------------------------*
twoway ///
    (bar pay x, ///
        barw(0.68) ///
        color(gs11) ///
        lcolor(black) ///
        lwidth(medthick)) ///
    (scatter pay x, ///
        msymbol(none) ///
        mlabel(pay_label) ///
        mlabposition(12) ///
        mlabgap(*0.2) ///
        mlabsize(8) ///
        mlabcolor(black)) ///
    , ///
        scheme(plotplain) ///
        legend(off) ///
        xlabel( ///
            1 "Base" ///
            2 "Overtime" ///
            3 "Rest day" ///
            4 "Holiday", ///
            nogrid labsize(6) ///
        ) ///
        ylabel(0 100 200 300, nogrid labsize(6)) ///
        ytitle("Pay (% of normal wage)", size(6)) ///
        xtitle("Compensation regime", size(10)) ///
        yline(100, lpattern(solid) lcolor(gs12)) ///
        xscale(range(0.65 4.35)) ///
        yscale(range(0 320)) ///
        graphregion(margin(zero)) ///
        xsize(12) ///
        ysize(3) ///
        name(overtime_rule, replace)

graph export "$figure_overleaf/Overtime_rule_panel.png", as(png) name("overtime_rule") replace
graph export "$figure_overleaf/Overtime_rule_panel.pdf", as(pdf) name("overtime_rule") replace

capture log close
