*-------------------------------------------------------------------
* figA7_ai_success_weekly.do  --  PNAS Nexus replication package
*-------------------------------------------------------------------
if "${replication}" == "" {
    global replication "<REPLICATION_ROOT>"
}

run "$replication/code/00_declare_path.do"

capture log close
log using "$replication_log/figA7_ai_success_weekly.log", replace text

* date: April, 2, 2026
*============================================================*
* AI performance over time: weekly deviation relative to base week
* Keep sample from 2024 week 30 onward
*============================================================*

use "$temp/vacation_connected_call_level", clear

replace total_payment_amt_num = 0 if missing(total_payment_amt_num)
keep if vacation == 1

cap gen gender_customer_num = (gender_customer == "Female")
replace province_capital = 1 if missing(province_capital)

* outcome
gen success_rate = if_succeed * 100

* week variable in Stata weekly-date format
gen week = wofd(date_create_time)
format week %tw

* keep only 2024 week 30 onward
keep if week >= yw(2024,30)

* set base week = first week in retained sample
summ week, meanonly
local baseweek = r(min)

display "Base week used in regression: " %tw `baseweek'

*============================================================*
* Regression: AI interacted with week dummies
*============================================================*
reghdfe success_rate i.if_AI##ib`baseweek'.week province_capital gender_customer_num, ///
    absorb(hour_create_time) vce(cluster crm_user_id)

eststo ai_week_interact

* Optional regression table
esttab ai_week_interact using "$table_overleaf/ai_success_week_interact.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) ///
    b(%9.3f) se(%9.3f) ///
    title("AI-week interaction in success rate")

*============================================================*
* Extract week-specific deviations relative to base week
* base week = 0 by construction
*============================================================*
tempname B
matrix `B' = J(1,4,.)   // placeholder row

levelsof week, local(weeks)

foreach w of local weeks {

    if `w' == `baseweek' {
        matrix `B' = `B' \ (`w', 0, 0, 0)
    }
    else {
        quietly lincom 1.if_AI#`w'.week
        matrix `B' = `B' \ (`w', r(estimate), r(lb), r(ub))
    }
}

* drop placeholder row
matrix `B' = `B'[2...,1...]

clear
svmat `B', names(col)

rename c1 week
rename c2 coef
rename c3 lb
rename c4 ub

format week %tw
gen zero = 0

*============================================================*
* Plot week-specific deviations relative to omitted week
*============================================================*
twoway ///
    (rarea lb ub week, sort color(gs12%35) lcolor(gs12%35)) ///
    (connected coef week, sort msymbol(O) mcolor(black) ///
        lcolor(black) lwidth(medthick)) ///
    (line zero week, sort lpattern(dash) lcolor(black) lwidth(medium)), ///
    xtitle("Week") ///
    ytitle("Change in human–AI success-rate gap relative to base week") ///
    legend(off) ///
    xlabel(`=yw(2024,30)'(2)`=yw(2024,43)', format(%tw) nogrid) ///
    ylabel(, nogrid) ///
    graphregion(color(white)) ///
    plotregion(color(white))
graph export "$figure_overleaf/ai_success_week_interaction_relative.pdf", replace

*============================================================*
* Save extracted coefficients if needed
*============================================================*
save "$temp/ai_success_week_interaction_relative.dta", replace

capture log close
