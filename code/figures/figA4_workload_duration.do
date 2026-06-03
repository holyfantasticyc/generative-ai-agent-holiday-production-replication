*-------------------------------------------------------------------
* figA4_workload_duration.do  --  PNAS Nexus replication package
*
* Generates Figure A.4 (Gap in Call Duration between Human and AI Representatives by Work Load).
*
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "/Users/holyfantastic/Dropbox/AI/PNAS_NEXUS/replication_package"
}
run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/figA4_workload_duration.log", replace text

**# Figure: Results: by workload
* Call-level data: same dataset and task_order convention as Figure 2, so the
* duration version (Figure A.4) lines up with the success-rate version.
use  "$temp/vacation_connected_call_level"  , clear
keep if gap_creat_lastcallthrough < 3600 // restrict to leads whose last connected call occurs within 1 hour of lead creation

{
replace if_succeed = if_succeed * 100
sort crm_user_id date_create_time hour_create_time minute_create_time
bys crm_user_id date_create_time: gen task_order = _n
bys crm_user_id date_create_time  (task_order): egen cumulative_payment = sum(payment_amt_num)


replace task_order = 0 if if_AI 

gen bin_task_order = recode(task_order,0,3,6,10,15,20,30,50,100) // 0 to 0; 1-3 to 3; 4-6 to 6 ...

*-------------------------------------------------------------------
* Figure A.4: Coef_by_workload_duration
*-------------------------------------------------------------------
* Call duration as Y
		
reghdfe bridge_duration_num ib0.bin_task_order  ///
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
		ytitle(" Effects Size: Second " , size(small)) /// 
		graphregion(margin(small)) ///
	  xlabel(, nogrid) ylabel(, nogrid)
		
	graph export "$figure_overleaf/Coef_by_workload_duration.png", as(png) name("Graph") replace		
	graph export "$figure_overleaf/Coef_by_workload_duration.pdf", as(pdf) name("Graph") replace

}

capture log close
