*-------------------------------------------------------------------
* figA4_workload_duration.do  --  PNAS Nexus replication package
*
* Generates Figure A.4 (Gap in Call Duration between Human and AI Representatives by Work Load). The plotting block was commented out in the working .do file; uncommented in this replication package.
*
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "<REPLICATION_ROOT>"
}
run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/figA4_workload_duration.log", replace text

**# Figure: Results: by workload
use  "$temp/vacation_connected_callcontract_level"  , clear
keep if gap_creat_lastcallthrough < 3600 // get rid of follow up call the next day

{
// append using  "$temp/connected_call_level_2023"  
replace if_succeed = if_succeed * 100
sort crm_user_id date_create_time hour_create_time minute_create_time
bys crm_user_id date_create_time: gen task_order = _n
bys crm_user_id date_create_time  (task_order): egen cumulative_payment = sum(payment_amt_num)

// binsreg if_succeed task_order , by(if_AI)  absorb(date_create_time hour_create_time)
// reghdfe if_succeed task_order if !if_AI ,  absorb(date_create_time hour_create_time) 

replace task_order = 0 if if_AI 

gen bin_task_order = recode(task_order,0,3,6,10,15,20,30,50,100) // 0 to 0; 1-3 to 3; 4-6 to 6 ...

*-------------------------------------------------------------------
* Figure A.4: Coef_by_workload_duration
*  (this block was commented out with /* ... */ in the working
*   copy of analysis_data_vacation.do; it is restored here so the
*   replication package reproduces Figure A.4.)
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
