*-------------------------------------------------------------------
* 00_declare_path.do
* Path declarations for the PNAS Nexus replication package
*
* USER ACTION REQUIRED (only before the first run on a new machine):
*   1. Update $replication below to point to your local copy of this
*      replication package.
*   2. Update $data below to point to the folder containing the
*      cleaned .dta files (vacation_full_data_no_collapse.dta,
*      vacation_connected_call_level.dta, full_data_no_collapse.dta,
*      vacation_date_create_time.dta, full_connected_call_level.dta).
*-------------------------------------------------------------------

set more off, perm
macro drop _all

*=== USER-EDITABLE: replication package root =======================
global replication "<REPLICATION_ROOT>"

*=== USER-EDITABLE: location of cleaned .dta files =================
* Frozen, isolated copy maintained alongside the replication package
* so that future edits to the original working data folder do not
* retroactively change inputs to this replication.
global data "<DATA_ROOT>"

*=== Derived paths (do not edit) ===================================
global temp "$data/temp"
global raw  "$data/raw"

global replication_code   "$replication/code"
global replication_output "$replication/output"
global replication_log    "$replication/logs"

* outputs of figure / table do-files land in output/
global figure_overleaf "$replication_output/figure"
global table_overleaf  "$replication_output/table"

* scratch directory — Stata's saving(name, replace) inside graph combine
* writes intermediate .gph files to the current working directory; we keep
* them isolated here so the code/ folder stays clean. Cleared by 00_master.do.
global scratch "$replication/scratch"

* ensure output directories exist
cap mkdir "$replication_output"
cap mkdir "$figure_overleaf"
cap mkdir "$table_overleaf"
cap mkdir "$replication_log"
cap mkdir "$scratch"

* run subsequent saving()/graph combine commands against the scratch dir
cd "$scratch"

* graph color conventions (used by some figure scripts)
global control_color "blue%50"
global treat_color   "red%50"
