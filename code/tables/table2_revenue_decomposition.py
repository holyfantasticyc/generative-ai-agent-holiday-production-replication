"""
table2_revenue_decomposition.py  --  PNAS Nexus replication package

Generates Table 2 (Revenue Decomposition Under Alternative Counterfactual
Capacity Assumptions). The calibrated parameter values hard-coded below
are computed by the upstream Stata script
table2_revenue_decomposition_estimates.do, which prints them into
$REPLICATION_PATH/output/table/delta.log. After re-running the .do file,
copy the latest values from delta.log into the INPUTS block below
before re-running this script.

Output:
    $REPLICATION_PATH/output/table/revenue_results_decomposition_table.tex
    $REPLICATION_PATH/output/table/revenue_results_decomposition_table.xlsx

Run from a shell:
    REPLICATION_PATH=/path/to/replication_package python3 \
        "$REPLICATION_PATH/code/tables/table2_revenue_decomposition.py"
"""

import os
import math
import pandas as pd

# ============================================================
# OUTPUT PATH
# ============================================================
import os
replication_root = os.environ.get("REPLICATION_PATH", "<REPLICATION_ROOT>")
table_overleaf = os.path.join(replication_root, "output", "table")
os.makedirs(table_overleaf, exist_ok=True)

# ============================================================
# INPUTS
# ============================================================
k = 3.38
se_k = 0.0

p_h0 = 3.777799 / 100
se_p_h0 = 0.29882 / 100

p_ai = 2.561433 / 100
se_p_ai = 0.1767427 / 100

m_ai = 114.8695
se_m_ai = 6.356324

m_h = 129.8188
se_m_h = 4.094225

# ============================================================
# SCENARIOS
# r = 0  -> callback eventually attempted
# r = 1  -> no callback / fully lost
# ============================================================
scenarios = {
    "Optimal Benchmark": {
        "colnum": "(1)",
        "constraint_level": "No Constraint",
        "delay": r"$<$10min",
        "r": 0,
        "delta": 0.0,
        "se_delta": 0.0,
    },
    "Low Constraint": {
        "colnum": "(2)",
        "constraint_level": "Low Constraint",
        "delay": r"$<$1d",
        "r": 0,
        "delta": 0.24986710,
        "se_delta": 0.08357919,
    },
    "Medium Constraint": {
        "colnum": "(3)",
        "constraint_level": "Medium Constraint",
        "delay": "1 to 3d",
        "r": 0,
        "delta": 0.67617122,
        "se_delta": 0.11580034,
    },
    "High Constraint": {
        "colnum": "(4)",
        "constraint_level": "High Constraint",
        "delay": r"$>$3d",
        "r": 0,
        "delta": 0.76118596,
        "se_delta": 0.16623609,
    },
    "Full Constraint": {
        "colnum": "(5)",
        "constraint_level": "Full Constraint",
        "delay": "No Callback",
        "r": 1,
        "delta": 1.0,
        "se_delta": 0.0,
    },
}

scenario_order = [
    "Optimal Benchmark",
    "Low Constraint",
    "Medium Constraint",
    "High Constraint",
    "Full Constraint",
]

# ============================================================
# DELTA METHOD: CAPACITY PERCENTAGE CHANGE
# g_cap = (C_withAI - C_withoutAI) / C_withoutAI
#       = [k(A-B)] / [1+kB]
# where A = pA/pH, B = (1-r)(1-delta)
# ============================================================
def delta_method_se_capacity_pct_change(
    k, se_k,
    p_ai, se_p_ai,
    p_h0, se_p_h0,
    delta, se_delta,
    r
):
    A = p_ai / p_h0
    B = (1 - r) * (1 - delta)

    num = k * (A - B)
    den = 1 + k * B

    dg_dA = k / den
    dg_dB = (-k * den - num * k) / (den ** 2)
    dg_dk = ((A - B) * den - num * B) / (den ** 2)

    dA_dp_ai = 1 / p_h0
    dA_dp_h0 = -p_ai / (p_h0 ** 2)
    dB_ddelta = -(1 - r)

    dg_dp_ai = dg_dA * dA_dp_ai
    dg_dp_h0 = dg_dA * dA_dp_h0
    dg_ddelta = dg_dB * dB_ddelta

    var_g = (
        (dg_dk ** 2) * (se_k ** 2)
        + (dg_dp_ai ** 2) * (se_p_ai ** 2)
        + (dg_dp_h0 ** 2) * (se_p_h0 ** 2)
        + (dg_ddelta ** 2) * (se_delta ** 2)
    )
    return math.sqrt(max(var_g, 0.0))


# ============================================================
# DELTA METHOD: REVENUE PERCENTAGE CHANGE
# g_rev = (R_withAI - R_withoutAI) / R_withoutAI
#       = [k(A-B)] / [1+kB]
# where A = (mA*pA)/(mH*pH), B = (1-r)(1-delta)
# ============================================================
def delta_method_se_revenue_pct_change(
    k, se_k,
    p_ai, se_p_ai,
    p_h0, se_p_h0,
    delta, se_delta,
    m_ai, se_m_ai,
    m_h, se_m_h,
    r
):
    A = (m_ai * p_ai) / (m_h * p_h0)
    B = (1 - r) * (1 - delta)

    num = k * (A - B)
    den = 1 + k * B

    dg_dA = k / den
    dg_dB = (-k * den - num * k) / (den ** 2)
    dg_dk = ((A - B) * den - num * B) / (den ** 2)

    dA_dp_ai = m_ai / (m_h * p_h0)
    dA_dp_h0 = -m_ai * p_ai / (m_h * (p_h0 ** 2))
    dA_dm_ai = p_ai / (m_h * p_h0)
    dA_dm_h = -m_ai * p_ai / ((m_h ** 2) * p_h0)

    dB_ddelta = -(1 - r)

    dg_dp_ai = dg_dA * dA_dp_ai
    dg_dp_h0 = dg_dA * dA_dp_h0
    dg_dm_ai = dg_dA * dA_dm_ai
    dg_dm_h = dg_dA * dA_dm_h
    dg_ddelta = dg_dB * dB_ddelta

    var_g = (
        (dg_dk ** 2) * (se_k ** 2)
        + (dg_dp_ai ** 2) * (se_p_ai ** 2)
        + (dg_dp_h0 ** 2) * (se_p_h0 ** 2)
        + (dg_ddelta ** 2) * (se_delta ** 2)
        + (dg_dm_ai ** 2) * (se_m_ai ** 2)
        + (dg_dm_h ** 2) * (se_m_h ** 2)
    )
    return math.sqrt(max(var_g, 0.0))


# ============================================================
# COMPUTE RESULTS
# ============================================================
results = {}

for scenario_name in scenario_order:
    vals = scenarios[scenario_name]
    r = vals["r"]
    delta = vals["delta"]
    se_delta = vals["se_delta"]

    # --------------------------------------------------------
    # HANDLING CAPACITY BLOCK
    # --------------------------------------------------------
    a = 100.0
    spike = 100.0 * k
    b = 100.0 * k * (1 - r) * (1 - delta)
    c = 100.0 * k * (p_ai / p_h0)

    cap_without_ai = a + b
    cap_with_ai = a + c
    cap_diff = cap_with_ai - cap_without_ai
    cap_pct = cap_diff / cap_without_ai

    se_cap_pct = delta_method_se_capacity_pct_change(
        k, se_k,
        p_ai, se_p_ai,
        p_h0, se_p_h0,
        delta, se_delta,
        r
    )
    cap_ci_low = cap_pct - 1.96 * se_cap_pct
    cap_ci_high = cap_pct + 1.96 * se_cap_pct

    # --------------------------------------------------------
    # TOTAL REVENUE BLOCK
    # --------------------------------------------------------
    d = a * m_h
    e = b * m_h
    f = c * m_ai

    rev_without_ai = d + e
    rev_with_ai = d + f
    rev_diff = rev_with_ai - rev_without_ai
    rev_pct = rev_diff / rev_without_ai

    se_rev_pct = delta_method_se_revenue_pct_change(
        k, se_k,
        p_ai, se_p_ai,
        p_h0, se_p_h0,
        delta, se_delta,
        m_ai, se_m_ai,
        m_h, se_m_h,
        r
    )
    rev_ci_low = rev_pct - 1.96 * se_rev_pct
    rev_ci_high = rev_pct + 1.96 * se_rev_pct

    results[scenario_name] = {
        "colnum": vals["colnum"],
        "constraint_level": vals["constraint_level"],
        "delay": vals["delay"],
        "success_rate_change": -delta,   # decimal
        "a": a,
        "spike": spike,
        "b": b,
        "c": c,
        "cap_without_ai": cap_without_ai,
        "cap_with_ai": cap_with_ai,
        "cap_diff": cap_diff,
        "cap_pct": cap_pct,
        "cap_ci_low": cap_ci_low,
        "cap_ci_high": cap_ci_high,
        "d": d,
        "e": e,
        "f": f,
        "rev_without_ai": rev_without_ai,
        "rev_with_ai": rev_with_ai,
        "rev_diff": rev_diff,
        "rev_pct": rev_pct,
        "rev_ci_low": rev_ci_low,
        "rev_ci_high": rev_ci_high,
    }

# ============================================================
# BUILD DISPLAY DATAFRAME
# ============================================================
display_index = [
    "Parameters:",
    "  Constraint level",
    "  Callback delay",
    "  Relative success-rate change",
    "Handling Capacity",
    "  Constant demand",
    "    Human immediate (a)",
    "  Demand spike (3.38x)",
    "    Human callback (b)",
    "    AI immediate (c)",
    "  Capacity without AI [(C.1)=(a)+(b)]",
    "  Capacity with AI [(C.2)=(a)+(c)]",
    "  Capacity enhancement [Diff = (C.2) - (C.1)]",
    "    Percentage change",
    "    95% CI",
    "Total Revenue",
    "  Human immediate [(d)=(a)*129.8]",
    "  Human callback [(e)=(b)*129.8]",
    "  AI immediate [(f)=(c)*114.9]",
    "  Revenue without AI [(R.1)=(d)+(e)]",
    "  Revenue with AI [(R.2)=(d)+(f)]",
    "  Revenue enhancement [Diff = (R.2) - (R.1)]",
    "    Percentage change",
    "    95% CI",
]

display_columns = ["Counterfactual Scenarios"] + [results[name]["colnum"] for name in scenario_order]

display_data = [
    [""] + [""] * len(scenario_order),
    [""] + [results[name]["constraint_level"] for name in scenario_order],
    [""] + [results[name]["delay"] for name in scenario_order],
    [""] + [
        ("0 (benchmark)" if name == "Optimal Benchmark" else f"{results[name]['success_rate_change']:.1%}")
        for name in scenario_order
    ],

    [""] + [""] * len(scenario_order),
    [""] + [""] * len(scenario_order),
    [""] + [f"{results[name]['a']:.1f}" for name in scenario_order],
    [""] + [""] * len(scenario_order),
    [""] + [f"{results[name]['b']:.1f}" for name in scenario_order],
    [""] + [f"{results[name]['c']:.1f}" for name in scenario_order],
    [""] + [f"{results[name]['cap_without_ai']:.1f}" for name in scenario_order],
    [""] + [f"{results[name]['cap_with_ai']:.1f}" for name in scenario_order],
    [""] + [f"{results[name]['cap_diff']:.1f}" for name in scenario_order],
    [""] + [f"{results[name]['cap_pct']*100:.1f}%" for name in scenario_order],
    [""] + [f"[{results[name]['cap_ci_low']*100:.1f}%, {results[name]['cap_ci_high']*100:.1f}%]" for name in scenario_order],

    [""] + [""] * len(scenario_order),
    [""] + [f"{results[name]['d']:.2f}" for name in scenario_order],
    [""] + [f"{results[name]['e']:.1f}" for name in scenario_order],
    [""] + [f"{results[name]['f']:.1f}" for name in scenario_order],
    [""] + [f"{results[name]['rev_without_ai']:.1f}" for name in scenario_order],
    [""] + [f"{results[name]['rev_with_ai']:.1f}" for name in scenario_order],
    [""] + [f"{results[name]['rev_diff']:.1f}" for name in scenario_order],
    [""] + [f"{results[name]['rev_pct']*100:.1f}%" for name in scenario_order],
    [""] + [f"[{results[name]['rev_ci_low']*100:.1f}%, {results[name]['rev_ci_high']*100:.1f}%]" for name in scenario_order],
]

df_display = pd.DataFrame(display_data, index=display_index, columns=display_columns)
print(df_display)

# ============================================================
# EXPORT TO EXCEL
# ============================================================
xlsx_path = os.path.join(table_overleaf, "revenue_results_decomposition_table.xlsx")
df_display.to_excel(xlsx_path)

# ============================================================
# EXPORT TO TEX
# Keep the tex filename the same as your earlier code
# ============================================================
tex_path = os.path.join(table_overleaf, "revenue_results_decomposition_table.tex")

def make_row(label, values):
    return label + " & " + " & ".join(values) + r" \\"

latex_lines = []
latex_lines.append(r"\begin{tabular}{lccccc}")
latex_lines.append(r"\toprule")
latex_lines.append(make_row("", [results[name]["colnum"] for name in scenario_order]))
latex_lines.append(r"\midrule")

latex_lines.append(make_row(r"\textbf{Parameters}", [""] * len(scenario_order)))
latex_lines.append(make_row(r"\hspace{1em} Constraint level",
                            [results[name]["constraint_level"] for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{1em} Callback delay",
                            [results[name]["delay"] for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{1em} Relative success-rate change",
                            [("0 (benchmark)" if name == "Optimal Benchmark" else f"{results[name]['success_rate_change']:.1%}".replace("%", r"\%"))
                             for name in scenario_order]))

latex_lines.append(r"\midrule")
latex_lines.append(make_row(r"\textbf{Handling Capacity}", [""] * len(scenario_order)))
latex_lines.append(make_row(r"\hspace{1em} Constant demand", [""] * len(scenario_order)))
latex_lines.append(make_row(r"\hspace{2em} Human immediate (a)",
                            [f"{results[name]['a']:.1f}" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{1em} Demand spike (3.38x)", [""] * len(scenario_order)))
latex_lines.append(make_row(r"\hspace{2em} Human callback (b)",
                            [f"{results[name]['b']:.1f}" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{2em} AI immediate (c)",
                            [f"{results[name]['c']:.1f}" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{1em} Capacity without AI [(C.1)=(a)+(b)]",
                            [f"{results[name]['cap_without_ai']:.1f}" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{1em} Capacity with AI [(C.2)=(a)+(c)]",
                            [f"{results[name]['cap_with_ai']:.1f}" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{1em} Capacity enhancement [= (C.2) - (C.1)]",
                            [f"{results[name]['cap_diff']:.1f}" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{2em} Percentage change",
                            [f"{results[name]['cap_pct']*100:.1f}\\%" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{2em} 95\% CI",
                            [f"[{results[name]['cap_ci_low']*100:.1f}\\%, {results[name]['cap_ci_high']*100:.1f}\\%]" for name in scenario_order]))

latex_lines.append(r"\midrule")
latex_lines.append(make_row(r"\textbf{Total Revenue}", [""] * len(scenario_order)))
latex_lines.append(make_row(r"\hspace{1em} Human immediate [(d)=(a)*129.8]",
                            [f"{results[name]['d']:.2f}" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{1em} Human callback [(e)=(b)*129.8]",
                            [f"{results[name]['e']:.1f}" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{1em} AI immediate [(f)=(c)*114.9]",
                            [f"{results[name]['f']:.1f}" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{1em} Revenue without AI [(R.1)=(d)+(e)]",
                            [f"{results[name]['rev_without_ai']:.1f}" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{1em} Revenue with AI [(R.2)=(d)+(f)]",
                            [f"{results[name]['rev_with_ai']:.1f}" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{1em} Revenue enhancement [= (R.2) - (R.1)]",
                            [f"{results[name]['rev_diff']:.1f}" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{2em} Percentage change",
                            [f"{results[name]['rev_pct']*100:.1f}\\%" for name in scenario_order]))
latex_lines.append(make_row(r"\hspace{2em} 95\% CI",
                            [f"[{results[name]['rev_ci_low']*100:.1f}\\%, {results[name]['rev_ci_high']*100:.1f}\\%]" for name in scenario_order]))

latex_lines.append(r"\bottomrule")
latex_lines.append(r"\end{tabular}")

with open(tex_path, "w", encoding="utf-8") as f:
    f.write("\n".join(latex_lines))

print("Saved Excel table to:", xlsx_path)
print("Saved TeX table to:", tex_path)
