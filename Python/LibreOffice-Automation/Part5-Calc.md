# Part 5: Cross-Application Workflows

This is the integration part: one script, `src/pipeline.py`, that reads raw CSV data, processes it in Calc (including generating a chart), embeds that chart image into a Writer report, and exports the final PDF — reusing `calc_tools.py` and `writer_tools.py` from Parts 3 and 4 unmodified.

## 5.1 Pipeline Architecture

```text
data/sales_raw.csv
        │
        ▼
[1] Calc: load + compute (calc_tools.build_sales_summary logic, reused)
        │
        ▼
[2] Calc: generate chart, export chart as PNG
        │
        ▼
[3] Writer: open template, replace placeholders, insert table + chart image
        │
        ▼
output/sales_report_<date>.pdf
```

Each stage is a small, independently testable function — this is deliberate. Enterprise automation scripts fail in production; when they do, you want to know *which stage* failed (bad CSV? Calc chart export bug? missing template?), not just "the script crashed."

## 5.2 Stage 1 — Load and Compute (Reusing Part 3)

```python
import sys
sys.path.insert(0, "/usr/lib/libreoffice/program")
from scriptforge import CreateScriptService
import uno_bridge
import calc_tools
import writer_tools


def stage_1_build_summary(csv_path: str) -> "CalcService":
    calc = calc_tools.new_calc(hidden=True)
    row_count = calc_tools.load_csv_into_calc(calc, "Sheet1", csv_path)
    calc_tools.add_revenue_formulas(calc, "Sheet1", 2, row_count)
    calc_tools.add_totals_row(calc, "Sheet1", row_count, ["B", "D"])
    calc_tools.format_header_row(calc, "Sheet1.A1:D1")
    calc_tools.format_currency_column(calc, f"Sheet1.C2:D{row_count + 1}")
    return calc, row_count
```

## 5.3 Stage 2 — Generating a Chart and Exporting It as an Image

ScriptForge does not currently expose chart creation directly, so chart generation is raw UNO — one of the few places in this series that requires it end to end.

```python
import uno


def create_bar_chart(calc, data_range: str, chart_name: str = "RevenueChart"):
    """Insert a bar chart on Sheet1 visualizing a data range, e.g.
    'Sheet1.A1:B5' (Product names + Units Sold)."""
    document = calc.XComponent
    sheet = document.Sheets.getByName("Sheet1")
    charts = sheet.Charts

    if charts.hasByName(chart_name):
        charts.removeByName(chart_name)

    rect = uno.createUnoStruct("com.sun.star.awt.Rectangle")
    rect.X, rect.Y = 8000, 500      # position, 1/100 mm
    rect.Width, rect.Height = 10000, 8000  # size, 1/100 mm

    sheet_name, cell_range_str = data_range.split(".", 1)
    range_address = sheet.getCellRangeByName(cell_range_str).RangeAddress

    charts.addNewByName(chart_name, rect, (range_address,), True, True)

    chart = charts.getByName(chart_name).EmbeddedObject
    chart.setDiagram(chart.createInstance("com.sun.star.chart.BarDiagram"))
    chart.Title.String = "Revenue by Product"
    return chart


def export_chart_as_image(calc, chart_name: str, output_png_path: str) -> None:
    """Export a named chart object as a standalone PNG for embedding
    into the Writer report."""
    document = calc.XComponent
    sheet = document.Sheets.getByName("Sheet1")
    chart_object = sheet.Charts.getByName(chart_name)

    controller = document.CurrentController
    controller.select(chart_object)
    selected_shape = controller.getSelection()

    graphic_export_provider = document.createInstance(
        "com.sun.star.drawing.GraphicExportFilter"
    )
    graphic_export_provider.setSourceDocument(selected_shape)

    export_props = (
        _prop("URL", f"file://{output_png_path}"),
        _prop("MediaType", "image/png"),
    )
    graphic_export_provider.filter(export_props)


def _prop(name, value):
    p = uno.createUnoStruct("com.sun.star.beans.PropertyValue")
    p.Name = name
    p.Value = value
    return p
```

## 5.4 Stage 3 — Building the Writer Report (Reusing Part 4)

```python
def stage_3_build_report(row_count: int, chart_image_path: str, output_pdf_path: str) -> None:
    writer = writer_tools.open_writer_template_safe("templates/monthly_report.odt")
    try:
        writer_tools.replace_placeholders(writer, {
            "CUSTOMER_NAME": "Acme Corp",
            "REPORT_DATE": "2026-03-31",
        })
        writer_tools.insert_image(writer, chart_image_path, width_mm=140, height_mm=90)
        leftovers = writer_tools.warn_on_unreplaced_placeholders(writer)
        if leftovers:
            print(f"WARNING: unreplaced placeholders remain: {leftovers}")
        writer_tools.export_pdf(writer, output_pdf_path)
    finally:
        writer.CloseDocument(savechanges=False)
```

## 5.5 Full Orchestration Script

```python
import os
from datetime import date


def run_pipeline(csv_path: str, output_dir: str = "output") -> str:
    os.makedirs(output_dir, exist_ok=True)
    chart_png = os.path.join(output_dir, "_tmp_chart.png")
    report_pdf = os.path.join(
        output_dir, f"sales_report_{date.today().isoformat()}.pdf"
    )

    print(f"[1/3] Loading and computing '{csv_path}'...")
    calc, row_count = stage_1_build_summary(csv_path)

    try:
        print("[2/3] Generating chart and exporting as PNG...")
        create_bar_chart(calc, f"Sheet1.A1:B{row_count + 1}")
        export_chart_as_image(calc, "RevenueChart", chart_png)
    finally:
        calc.CloseDocument(savechanges=False)

    print("[3/3] Building Writer report and exporting PDF...")
    stage_3_build_report(row_count, chart_png, report_pdf)

    if os.path.exists(chart_png):
        os.remove(chart_png)  # clean up the intermediate PNG

    print(f"Done. Report written to: {report_pdf}")
    return report_pdf


if __name__ == "__main__":
    run_pipeline("data/sales_raw.csv")
```

## 5.6 Error Handling Across Stage Boundaries

Because each stage can fail independently, wrap the orchestration with stage-aware error context rather than one broad `try/except`:

```python
class PipelineStageError(Exception):
    def __init__(self, stage: str, original: Exception):
        super().__init__(f"Pipeline failed at stage '{stage}': {original}")
        self.stage = stage
        self.original = original


def run_pipeline_safe(csv_path: str, output_dir: str = "output") -> str:
    try:
        calc, row_count = stage_1_build_summary(csv_path)
    except Exception as exc:
        raise PipelineStageError("load_and_compute", exc) from exc

    try:
        chart_png = os.path.join(output_dir, "_tmp_chart.png")
        create_bar_chart(calc, f"Sheet1.A1:B{row_count + 1}")
        export_chart_as_image(calc, "RevenueChart", chart_png)
    except Exception as exc:
        calc.CloseDocument(savechanges=False)
        raise PipelineStageError("chart_generation", exc) from exc
    else:
        calc.CloseDocument(savechanges=False)

    try:
        report_pdf = os.path.join(output_dir, "sales_report.pdf")
        stage_3_build_report(row_count, chart_png, report_pdf)
    except Exception as exc:
        raise PipelineStageError("report_generation", exc) from exc

    return report_pdf
```

## Checkpoint

By the end of Part 5 you should have `src/pipeline.py` containing:

- [ ] `stage_1_build_summary()` reusing `calc_tools.py`
- [ ] `create_bar_chart()` and `export_chart_as_image()` (raw UNO)
- [ ] `stage_3_build_report()` reusing `writer_tools.py`
- [ ] `run_pipeline()` full orchestration
- [ ] `PipelineStageError` and `run_pipeline_safe()` for production-grade error attribution

## Exercise Challenge

Modify the pipeline to accept a list of CSV paths and produce one combined multi-page PDF (one Writer section per CSV) instead of one PDF per file, reusing the same chart-generation logic per section.

## What's Next

Part 6 takes this same logic and repackages it as an internal Python macro triggered by a button inside the LibreOffice UI — showing exactly what changes (and what doesn't) between the external-script model and the embedded-macro model.
