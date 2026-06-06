#!/usr/bin/env python3
"""
post_process_table_headers.py  --  PNAS Nexus replication package

esttab writes long column titles into single \\multicolumn{1}{c}{...} cells.
With many columns (e.g. nine outcome columns in Tables A.2--A.5) or long
phrase titles (e.g. "Customer is from Major Cities" in Table 1), the
resulting table exceeds the page width.

This script edits the auto-generated .tex files in place to wrap long
column titles onto a second header row, matching the layout used in the
previously submitted manuscript.  Run-and-forget; invoked automatically
by run_all.sh after the Stata master script finishes.

Output:
    Same files, rewritten in place.
"""

import os
import re
import sys
from pathlib import Path

REPL = os.environ.get(
    "REPLICATION_PATH",
    "<REPLICATION_ROOT>",
)
TABLE_DIR = Path(REPL) / "output" / "table"

# ---- header splits -----------------------------------------------------
# For each affected file, list the per-column (line-1, line-2) split.
# The script only rewrites if it can match the single-line header exactly.

SPLITS_4COL = [
    ("Customer is Female",            "Customer is",       " Female"),
    ("Customer is from Major Cities", "Customer is from",  "Major Cities"),
    ("If Answered",                   "If Answered",       ""),
    ("Hang up within 10 seconds",     "Hang up within",    "10 seconds"),
]

SPLITS_9COL = [
    ("Success rate",            "Success rate", ""),
    ("Duration",                "Duration",     ""),
    ("Duration (success)",      "Duration",     "(success)"),
    ("N succeed transcations",  "N succeed",    "transcations"),
    ("Payment amount",          "Payment",      "amount"),
    ("Payment per second",      "Payment",      "per second"),
    ("Refund rate",             "Refund rate",  ""),
    ("Scale premium",           "Scale premium", ""),
    ("Insurance amount",        "Insurance",    "amount"),
]

FILE_SPLITS = {
    "table_balance.tex":          SPLITS_4COL,
    "table_main.tex":             SPLITS_9COL,
    "table_robust_notcontrols.tex": SPLITS_9COL,
    "table_robust_w_1h.tex":      SPLITS_9COL,
    "table_by_gender.tex":        SPLITS_9COL,
}

# Additional row-label tweak: in Table 1 the coefficient row label is
# "AI Representative" (long) but the published table uses italicized "AI".
# Apply only to table_balance.tex.
ROW_LABEL_TWEAK = {
    "table_balance.tex": (
        r" AI Representative  &",
        r"\textit{AI}       &",
    ),
}


def build_two_row_header(splits):
    """Return (line1_str, line2_str) — each is the cell sequence for one
    header row, in the order of `splits`."""
    line1_cells = []
    line2_cells = []
    for _orig, top, bottom in splits:
        line1_cells.append(rf"\multicolumn{{1}}{{c}}{{{top}}}")
        line2_cells.append(rf"\multicolumn{{1}}{{c}}{{{bottom}}}")
    line1 = "                &" + "&".join(line1_cells) + r"\\"
    line2 = "                &" + "&".join(line2_cells) + r"\\"
    return line1, line2


def process(fname, splits):
    path = TABLE_DIR / fname
    if not path.exists():
        print(f"  [skip] {fname}: not found")
        return
    text = path.read_text()

    # Build the single-line header esttab would have written.
    single_cells = [rf"\multicolumn{{1}}{{c}}{{{orig}}}" for orig, _, _ in splits]
    single_line = "                &" + "&".join(single_cells) + r"\\"

    if single_line not in text:
        # already split (or unexpected layout); skip silently
        print(f"  [skip] {fname}: single-line header not detected (probably already split)")
        return

    line1, line2 = build_two_row_header(splits)
    new_text = text.replace(single_line, line1 + "\n" + line2)

    # Optional row-label tweak
    if fname in ROW_LABEL_TWEAK:
        old, new = ROW_LABEL_TWEAK[fname]
        if old in new_text:
            new_text = new_text.replace(old, new)

    path.write_text(new_text)
    print(f"  [done] {fname}: split header into 2 rows")


def process_summary_table():
    """
    Tidy up table_summary_statistics.tex:
      1. Blank out the dot cells in the four Panel-header rows ('Panel A.', etc.)
         so the header rows read as bold labels rather than rows of "." values.
      2. Render the Obs column as integers (drop the trailing ".00" on the first
         numeric cell of every data row); leave the four statistics columns
         (Mean / SD / Min / Max) at two decimal places.
    """
    fname = "table_summary_statistics.tex"
    path = TABLE_DIR / fname
    if not path.exists():
        print(f"  [skip] {fname}: not found")
        return

    lines = path.read_text().split("\n")
    n_blanked = 0
    n_obs_fixed = 0

    for i, line in enumerate(lines):
        if r"\textbf{Panel" in line:
            # Panel-header row: cells look like  "&           .&  .... &           .\\"
            # Strip every "& <spaces> .<spaces?>" cell down to "&" (empty cell).
            new_line = re.sub(r"&\s*\.\s*(?=&|\\\\)", "&            ", line)
            if new_line != line:
                n_blanked += 1
            lines[i] = new_line
        else:
            # Data row: the first numeric cell after the row label is the Obs
            # count.  esttab emits it as e.g.  "&    42537.00&".  Strip ".00".
            new_line, k = re.subn(
                r"(&\s*\d+)\.00(\s*&)",
                r"\1\2",
                line, count=1,
            )
            if k:
                n_obs_fixed += 1
            lines[i] = new_line

    path.write_text("\n".join(lines))
    print(f"  [done] {fname}: blanked {n_blanked} panel-header rows, "
          f"integer-formatted Obs on {n_obs_fixed} data rows")


def main():
    print(f"Splitting long table headers in {TABLE_DIR}")
    for fname, splits in FILE_SPLITS.items():
        process(fname, splits)
    process_summary_table()


if __name__ == "__main__":
    main()
