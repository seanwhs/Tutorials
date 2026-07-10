# Part 3: Mastering LibreOffice Calc (Spreadsheets)

This part builds `src/calc_tools.py` — a reusable module for reading, writing, formatting, and computing with Calc spreadsheets, used again in Parts 5 and 7.

## 3.1 Opening and Creating Spreadsheets

```python
import sys
sys.path.insert(0, "/usr/lib/libreoffice/program")
from scriptforge import CreateScriptService
import uno_bridge


def open_calc(path: str, hidden: bool = True):
    """Open an existing Calc file (.ods/.xlsx/.csv) and return the
    ScriptForge Calc service handle."""
    desktop, context = uno_bridge.connect_scriptforge()
    ui = CreateScriptService("UI")
    doc = ui.OpenDocument(path, hidden=hidden)
    return CreateScriptService("Calc", doc)


def new_calc(hidden: bool = True):
    """Create a brand-new, blank Calc document."""
    desktop, context = uno_bridge.connect_scriptforge()
    ui = CreateScriptService("UI")
    doc = ui.CreateDocument("Calc", hidden=hidden)
    return CreateScriptService("Calc", doc)
```

Both functions return a ScriptForge `Calc` service object (referred to as `calc` below), which wraps the underlying document.

## 3.2 Reading and Writing Cells and Ranges

Single cell:

```python
calc.SetValue("Sheet1.A1", "Product")
calc.SetValue("Sheet1.B1", "Units Sold")
value = calc.GetValue("Sheet1.A1")   # -> "Product"
```

**Bulk operations matter.** Looping cell-by-cell across a socket bridge is slow (Part 1's memory/lifecycle warning). For tabular data, always write/read whole 2D arrays at once:

```python
def write_table(calc, sheet_name: str, start_cell: str, rows: list[list]):
    """Write a 2D list of rows starting at start_cell in a single bridge call."""
    range_address = f"{sheet_name}.{start_cell}"
    calc.SetArray(range_address, rows)


def read_table(calc, range_address: str) -> list[list]:
    """Read a rectangular range as a 2D list in a single bridge call."""
    return calc.GetArray(range_address)
```

Example — loading a sales table:

```python
data = [
    ["Product", "Units Sold", "Unit Price", "Revenue"],
    ["Widget A", 120, 9.99, None],
    ["Widget B", 75, 14.50, None],
    ["Widget C", 200, 3.25, None],
]
write_table(calc, "Sheet1", "A1", data)
```

Equivalent raw-UNO version (for reference — this is what ScriptForge is doing under the hood, and useful to know when you need finer control):

```python
sheet = document.Sheets.getByName("Sheet1")
cell_range = sheet.getCellRangeByName("A1:D4")
cell_range.setDataArray(tuple(tuple(row) for row in data))
```

## 3.3 Writing Formulas Programmatically

Formulas are just strings starting with `=`, written the same way as values:

```python
def add_revenue_formulas(calc, sheet_name: str, first_row: int, last_row: int):
    """Insert a Revenue = Units * Price formula for each data row."""
    for row in range(first_row, last_row + 1):
        calc.SetFormula(f"{sheet_name}.D{row}", f"=B{row}*C{row}")
```

```python
add_revenue_formulas(calc, "Sheet1", 2, 4)
```

**Triggering recalculation explicitly** is sometimes necessary — e.g. after bulk `SetArray` writes with `Auto Calculate` disabled, or after changing values that feed volatile functions:

```python
calc.Forms  # (unrelated - just demonstrating calc has many sub-areas)

# Force a full recalculation of all formulas in the document:
document = calc.XComponent  # underlying raw UNO document object
document.calculateAll()
```

## 3.4 Applying Cell Formatting

ScriptForge exposes common formatting directly:

```python
def format_header_row(calc, range_address: str):
    calc.SetCellStyle(range_address, "Heading 1")

def format_currency_column(calc, range_address: str):
    calc.SetFormula  # (not used here — illustrative separation)
    calc.SetValue    # ditto
    # Number format codes follow LibreOffice's format-string syntax:
    calc.SetFormat(range_address, "#,##0.00 [$$-409]")
```

```python
format_header_row(calc, "Sheet1.A1:D1")
format_currency_column(calc, "Sheet1.C2:D4")
```

For formatting attributes ScriptForge doesn't expose directly (borders, conditional formatting, merged cells), drop to raw UNO on the underlying document:

```python
def bold_and_border(calc, range_address: str):
    """Raw-UNO fallback: bold text + thin bottom border on a range."""
    document = calc.XComponent
    sheet_name, cell_range_str = range_address.split(".", 1)
    sheet = document.Sheets.getByName(sheet_name)
    cell_range = sheet.getCellRangeByName(cell_range_str)

    cell_range.CharWeight = 150.0  # com.sun.star.awt.FontWeight.BOLD

    border = uno.createUnoStruct("com.sun.star.table.BorderLine2")
    border.LineStyle = 0       # SOLID
    border.LineWidth = 26      # ~0.026cm hairline, in 1/100 mm units
    cell_range.BottomBorder = border
```

```python
bold_and_border(calc, "Sheet1.A1:D1")
```

## 3.5 Processing Tabular Data: A Realistic Example

A common enterprise task: ingest a CSV of transactions, load it into Calc, add computed columns and a totals row, format it, and save.

```python
import csv


def load_csv_into_calc(calc, sheet_name: str, csv_path: str, start_cell: str = "A1"):
    """Read a CSV file and bulk-write it into a Calc sheet."""
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        rows = list(reader)

    # Coerce numeric-looking strings to real numbers so formulas work.
    def coerce(value: str):
        try:
            return float(value)
        except ValueError:
            return value

    numeric_rows = [
        [coerce(cell) for cell in row] if i > 0 else row
        for i, row in enumerate(rows)
    ]
    calc.SetArray(f"{sheet_name}.{start_cell}", numeric_rows)
    return len(numeric_rows)


def add_totals_row(calc, sheet_name: str, data_row_count: int, numeric_cols: list[str]):
    """Add a SUM() formula under each numeric column."""
    total_row = data_row_count + 1  # +1 because row 1 is the header
    calc.SetValue(f"{sheet_name}.A{total_row}", "TOTAL")
    for col in numeric_cols:
        calc.SetFormula(
            f"{sheet_name}.{col}{total_row}",
            f"=SUM({col}2:{col}{data_row_count})"
        )
    return total_row
```

Full pipeline:

```python
def build_sales_summary(csv_path: str, output_path: str):
    calc = new_calc(hidden=True)
    row_count = load_csv_into_calc(calc, "Sheet1", csv_path)
    add_revenue_formulas(calc, "Sheet1", 2, row_count)
    total_row = add_totals_row(calc, "Sheet1", row_count, ["B", "D"])

    format_header_row(calc, "Sheet1.A1:D1")
    format_currency_column(calc, f"Sheet1.C2:D{total_row}")

    calc.SaveAs(output_path, overwrite=True)
    calc.CloseDocument(savechanges=False)


if __name__ == "__main__":
    build_sales_summary("data/sales_raw.csv", "output/sales_summary.ods")
```

## 3.6 Error Handling for File Operations

```python
import os

def load_csv_into_calc_safe(calc, sheet_name: str, csv_path: str, start_cell: str = "A1"):
    if not os.path.isfile(csv_path):
        raise FileNotFoundError(
            f"Expected input CSV at '{csv_path}' — check the path and "
            f"that the batch job has read permissions on this file."
        )
    try:
        return load_csv_into_calc(calc, sheet_name, csv_path, start_cell)
    except UnicodeDecodeError as exc:
        raise ValueError(
            f"'{csv_path}' is not valid UTF-8 — re-export the source file "
            f"as UTF-8 or pass an explicit encoding."
        ) from exc
```

## Checkpoint

By the end of Part 3 you should have `src/calc_tools.py` containing:

- [ ] `open_calc()` / `new_calc()` helpers
- [ ] `write_table()` / `read_table()` bulk array I/O
- [ ] `add_revenue_formulas()` demonstrating programmatic formula insertion
- [ ] `format_header_row()` / `format_currency_column()` / `bold_and_border()`
- [ ] `load_csv_into_calc()` + `add_totals_row()` + `build_sales_summary()` end-to-end pipeline
- [ ] File-not-found and encoding error handling

## Exercise Challenge

Extend `build_sales_summary()` to add a fifth column, `Margin %`, computed as `(Revenue - Cost) / Revenue`, formatted as a percentage, assuming a `Cost` column exists in the source CSV. Add a guard clause that raises a clear error if the CSV is missing the `Cost` header.

## What's Next

Part 4 moves to LibreOffice Writer: generating dynamic reports from `.odt` templates, replacing placeholder variables, inserting tables and images programmatically.
