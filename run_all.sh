#!/usr/bin/env bash
#
# run_all.sh -- one-shot driver for the PNAS Nexus replication package
#
# Runs, in order:
#   1. Stata 00_master.do                  (all tables and figures)
#   2. Python table2_revenue_decomposition.py   (final Table 2 .tex)
#   3. Python combine_panels.py            (assemble multi-panel figure PDFs)
#
# Usage:
#   ./run_all.sh
#
# Override defaults if needed:
#   STATA=/Applications/Stata/StataMP.app/Contents/MacOS/StataMP \
#   PYTHON=python3 \
#   ./run_all.sh
#

set -euo pipefail

# --- locate the replication root from this script's location ---
REPLICATION_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPLICATION_PATH

# --- auto-detect Stata on macOS if not specified ---
if [ -z "${STATA:-}" ]; then
    for cand in \
        "/Applications/Stata/StataMP.app/Contents/MacOS/StataMP" \
        "/Applications/Stata/StataSE.app/Contents/MacOS/StataSE" \
        "/Applications/Stata/Stata.app/Contents/MacOS/Stata" \
        "stata-mp" "stata-se" "stata"
    do
        if command -v "$cand" >/dev/null 2>&1; then
            STATA="$cand"
            break
        fi
        if [ -x "$cand" ]; then
            STATA="$cand"
            break
        fi
    done
fi

if [ -z "${STATA:-}" ]; then
    echo "ERROR: Stata binary not found. Set STATA=/path/to/stata before running." >&2
    exit 1
fi

PYTHON="${PYTHON:-python3}"

echo "=================================================================="
echo "  Replication root: $REPLICATION_PATH"
echo "  Stata:            $STATA"
echo "  Python:           $PYTHON"
echo "=================================================================="

# --- step 1: Stata master ---
echo ""
echo ">>> Step 1/3: running Stata 00_master.do"
echo ""
cd "$REPLICATION_PATH/code"
"$STATA" -b do "$REPLICATION_PATH/code/00_master.do"
# stata -b writes a .log next to the .do; move it into logs/
if [ -f "$REPLICATION_PATH/code/00_master.log" ]; then
    mv "$REPLICATION_PATH/code/00_master.log" "$REPLICATION_PATH/logs/00_master.log"
fi

# --- step 2: Python -- Table 2 final formatter ---
echo ""
echo ">>> Step 2/3: running table2_revenue_decomposition.py"
echo ""
"$PYTHON" "$REPLICATION_PATH/code/tables/table2_revenue_decomposition.py"

# --- step 3: Python -- combine multi-panel figure PDFs ---
echo ""
echo ">>> Step 3/3: running combine_panels.py"
echo ""
"$PYTHON" "$REPLICATION_PATH/code/figures/combine_panels.py"


# --- step 4: scrub identifying paths from logs and output text files ---
# Stata records absolute paths in the log header (e.g. "log: /Users/.../...")
# and echoes paths from `use`, `log using`, etc. We strip these so the logs
# you ship to the journal contain no information about your local machine.
echo ""
echo ">>> Step 4/4: scrubbing local paths and username from logs/output"
echo ""
"$PYTHON" - "$REPLICATION_PATH" <<'PYEOF'
import os, re, sys

REPL = sys.argv[1]
PARENT = os.path.dirname(REPL)

mac_user = os.environ.get("USER") or os.environ.get("LOGNAME") or ""
home = os.path.expanduser("~")

# longer / more specific patterns first so a longer prefix is replaced
# before a shorter prefix that would otherwise eat its lead
SUBS = sorted(
    [
        (REPL,                                              "<REPLICATION_ROOT>"),
        (os.path.join(PARENT, "replication_package_data"),  "<DATA_ROOT>"),
        (home,                                              "/path/to/<user>"),
    ]
    + ([(mac_user, "<user>")] if mac_user else []),
    key=lambda x: -len(x[0]),
)

SCRUB_DIRS = [
    os.path.join(REPL, "logs"),
    os.path.join(REPL, "output", "table"),
]
EXTS = (".log", ".txt")

# Stata wraps long lines in logs at ~80 chars with a leading "> " on
# continuation lines, which breaks naive string substitution of full
# paths. Merge those continuations before substituting, then leave the
# log un-wrapped (still readable; just slightly different formatting).
WRAP_RE = re.compile(r"\n> ")

n_files = 0
n_subs  = 0
for d in SCRUB_DIRS:
    if not os.path.isdir(d):
        continue
    for f in os.listdir(d):
        p = os.path.join(d, f)
        if not (os.path.isfile(p) and f.endswith(EXTS)):
            continue
        try:
            with open(p, encoding="utf-8", errors="replace") as fh:
                content = fh.read()
        except Exception:
            continue

        # merge Stata's wrap continuations
        unwrapped = WRAP_RE.sub("", content)

        new = unwrapped
        local_subs = 0
        for old, repl in SUBS:
            if not old:
                continue
            c = new.count(old)
            if c:
                local_subs += c
                new = new.replace(old, repl)

        if new != content:
            with open(p, "w", encoding="utf-8") as fh:
                fh.write(new)
            n_files += 1
            n_subs  += local_subs
print(f"  scrubbed {n_files} files, {n_subs} substitutions")
PYEOF

echo ""
echo "=================================================================="
echo "  DONE. Outputs are under $REPLICATION_PATH/output/"
echo "  Stata logs are under   $REPLICATION_PATH/logs/  (paths scrubbed)"
echo "=================================================================="
