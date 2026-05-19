"""
combine_panels.py  --  PNAS Nexus replication package
-----------------------------------------------------

Post-processing step that builds the manuscript-ready combined figure
PDFs from the individual panel PDFs produced by the upstream .do files.

The journal requires that each figure be submitted as a single image
file, with multi-panel figures combined into one page and each panel
labeled by a letter (A, B, C, ...) in the upper-left corner. This
script implements that transformation.

Inputs (read from $REPLICATION_PATH/output/figure):
    Bar_plot_outcome_if_succeed_FE.pdf
    Bar_plot_outcome_payment_amt_num_uncon_FE.pdf
    Bar_plot2_if_refund_FE.pdf
    Coef_by_workload.pdf
    Overtime_rule_panel.pdf
    relationship_duration_succeed.pdf
    case_study_nationalday_R1.pdf
    rate_time_gap_relationsip_R1.pdf

Outputs (written to $REPLICATION_PATH/output/figure/Submission):
    Fig1_outcome_combined.pdf       Figure 1 (3 panels)
    Fig2_workload_combined.pdf      Figure 2 (2 panels)
    Fig3_duration_combined.pdf      Figure 3 (3 panels, single source PDF)
    Fig4_case_study_combined.pdf    Figure 4 (2 panels)

Run after 00_master.do has populated output/figure with the panel PDFs:

    REPLICATION_PATH=/path/to/replication_package python combine_panels.py

If REPLICATION_PATH is not set, the default below is used.

Dependencies: pip install pymupdf
"""

import os
import fitz  # PyMuPDF


REPLICATION_PATH = os.environ.get(
    "REPLICATION_PATH",
    "<REPLICATION_ROOT>",
)
SRC_DIR = os.path.join(REPLICATION_PATH, "output", "figure")
OUT_DIR = os.path.join(SRC_DIR, "Submission")


def stack_with_letters(
    panel_files,
    out_name,
    target_width=480,
    gap=10,
    label_band=24,
    label_font="helv",
    label_size=18,
    label_x=6,
):
    """Stack separate-panel PDFs vertically, scale to a common width,
    and place an upper-left letter label (A, B, C, ...) above each
    panel inside a reserved whitespace band.
    """
    panels = []
    for f in panel_files:
        path = os.path.join(SRC_DIR, f)
        d = fitz.open(path)
        rect = d[0].rect
        scale = target_width / rect.width
        scaled_h = rect.height * scale
        panels.append((d, scale, scaled_h))

    total_h = sum(label_band + h for _, _, h in panels) + gap * (len(panels) - 1)
    out = fitz.open()
    page = out.new_page(width=target_width, height=total_h)

    y = 0
    for idx, (d, scale, h) in enumerate(panels):
        letter = chr(ord("A") + idx)
        page.insert_text(
            fitz.Point(label_x, y + label_band - 5),
            letter,
            fontname=label_font,
            fontsize=label_size,
            color=(0, 0, 0),
        )
        page.show_pdf_page(
            fitz.Rect(0, y + label_band, target_width, y + label_band + h), d, 0
        )
        y += label_band + h + gap

    out_path = os.path.join(OUT_DIR, out_name)
    out.save(out_path)
    out.close()
    for d, *_ in panels:
        d.close()
    print(f"  -> {out_name}  ({target_width:.0f} x {total_h:.0f} pts)")


def overlay_letters_on_single_pdf(
    src_filename,
    out_name,
    panel_y_tops,
    left_band=18,
    letter_size=11,
    label_font="helv",
):
    """For a source PDF that already contains all panels in a single
    page, expand the canvas to the left and place a letter label inside
    that left margin at the vertical position corresponding to each
    panel's top edge.
    """
    src_path = os.path.join(SRC_DIR, src_filename)
    d = fitz.open(src_path)
    old_w, old_h = d[0].rect.width, d[0].rect.height
    new_w, new_h = old_w + left_band, old_h

    out = fitz.open()
    page = out.new_page(width=new_w, height=new_h)
    page.show_pdf_page(fitz.Rect(left_band, 0, new_w, new_h), d, 0)

    for letter, y_top in panel_y_tops:
        page.insert_text(
            fitz.Point(3, y_top + letter_size),
            letter,
            fontname=label_font,
            fontsize=letter_size,
            color=(0, 0, 0),
        )

    out_path = os.path.join(OUT_DIR, out_name)
    out.save(out_path)
    out.close()
    d.close()
    print(f"  -> {out_name}  ({new_w:.0f} x {new_h:.0f} pts)")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    print("Figure 1 (3 panels A/B/C):")
    stack_with_letters(
        [
            "Bar_plot_outcome_if_succeed_FE.pdf",
            "Bar_plot_outcome_payment_amt_num_uncon_FE.pdf",
            "Bar_plot2_if_refund_FE.pdf",
        ],
        "Fig1_outcome_combined.pdf",
    )

    print("\nFigure 2 (2 panels A/B):")
    stack_with_letters(
        [
            "Coef_by_workload.pdf",
            "Overtime_rule_panel.pdf",
        ],
        "Fig2_workload_combined.pdf",
    )

    print("\nFigure 3 (single source PDF, 3 panels A/B/C overlaid):")
    overlay_letters_on_single_pdf(
        "relationship_duration_succeed.pdf",
        "Fig3_duration_combined.pdf",
        panel_y_tops=[("A", 4), ("B", 76), ("C", 148)],
    )

    print("\nFigure 4 (2 panels A/B):")
    stack_with_letters(
        [
            "case_study_nationalday_R1.pdf",
            "rate_time_gap_relationsip_R1.pdf",
        ],
        "Fig4_case_study_combined.pdf",
    )

    print("\nDone. Output is in:", OUT_DIR)


if __name__ == "__main__":
    main()
