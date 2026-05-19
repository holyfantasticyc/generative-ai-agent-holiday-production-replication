*-------------------------------------------------------------------
* 00_master.do
* Master orchestrator for the PNAS Nexus replication package.
*
* Runs every figure and table do-file in sequence. Each subordinate
* do-file is also fully self-contained and can be run independently
* once $replication has been declared in 00_declare_path.do.
*-------------------------------------------------------------------

clear all

* Step 1. set the replication root before anything else.
* (Edit this path on a new machine to match your local checkout.)
global replication "<REPLICATION_ROOT>"

* Step 2. load all paths and global conventions.
do "$replication/code/00_declare_path.do"

*-------------------------------------------------------------------
* Tables
*-------------------------------------------------------------------
do "$replication/code/tables/table1_balance.do"
do "$replication/code/tables/table2_revenue_decomposition_estimates.do"
* Note: Table 2 final formatting is in the accompanying Jupyter notebook
*       table2_revenue_decomposition.ipynb. Run it separately in Jupyter
*       after table2_revenue_decomposition_estimates.do has been executed.
do "$replication/code/tables/tableA1_summary_statistics.do"
do "$replication/code/tables/tableA2_main.do"
do "$replication/code/tables/tableA3_robust_notcontrols.do"
do "$replication/code/tables/tableA4_robust_w_1h.do"
do "$replication/code/tables/tableA5_by_gender.do"
do "$replication/code/tables/tableA6_vacation_or_not.do"

*-------------------------------------------------------------------
* Figures
*-------------------------------------------------------------------
do "$replication/code/figures/fig1_outcome_bars.do"
do "$replication/code/figures/fig2_workload_coef.do"
do "$replication/code/figures/fig3_duration_relationship.do"
do "$replication/code/figures/fig4_case_study.do"
do "$replication/code/figures/figA3_coef_alter_FEs.do"
do "$replication/code/figures/figA4_workload_duration.do"
do "$replication/code/figures/figA5_gender_succeed.do"
do "$replication/code/figures/figA6_gender_payment_refund.do"
do "$replication/code/figures/figA7_ai_success_weekly.do"

*-------------------------------------------------------------------
* Clean up intermediate .gph files dropped into $scratch by Stata
* during graph combine. Final figure PDFs in $figure_overleaf are
* untouched.
*-------------------------------------------------------------------
local gphs : dir "$scratch" files "*.gph"
foreach f of local gphs {
    cap erase "$scratch/`f'"
}

display "All replication scripts completed."
