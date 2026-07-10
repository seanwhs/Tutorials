# Part 4: Mastering LibreOffice Writer (Documents)

This part builds `src/writer_tools.py` — reusable helpers for template-driven report generation with LibreOffice Writer, used again in Part 5's PDF pipeline.

## 4.1 The Template-Driven Report Pattern

The professional pattern for generating reports (invoices, contracts, monthly summaries) is: design a `.odt` **template** once in the Writer UI with placeholder text (e.g. `{{CUSTOMER_NAME}}`, `{{REPORT_DATE}}`), then have Python open a *copy* of that template and replace placeholders with real data — never generate a document from a blank page programmatically if you can avoid it. This keeps formatting/branding in the hands of whoever owns the template (often not a developer) and keeps your Python code focused purely on data.

Project convention: templates live in `templates/`, generated output in `output/`.

## 4.2 Opening a Template and Working with Text

```python
import sys
sys.path.insert(0, "/usr/lib/libreoffice/program")
from scriptforge import CreateScriptService
import uno_bridge


def open_writer_template(template_path: str, hidden: bool = True):
    """Open a .odt template and return the ScriptForge Writer service."""
    desktop, context = uno_bridge.connect_scriptforge()
    ui = CreateScriptService("UI")
    doc = ui.OpenDocument(template_path, hidden=hidden)
    return CreateScriptService("Writer", doc)
```

## 4.3 Replacing Template Variables (Find & Replace)

ScriptForge's `Writer` service exposes a straightforward `ReplaceAll`:

```python
def replace_placeholders(writer, replacements: dict[str, str]) -> None:
    """
    Replace every {{KEY}}-style placeholder in the document with its
    corresponding value. Example:
        replace_placeholders(writer, {"CUSTOMER_NAME": "Acme Corp"})
    replaces every literal "{{CUSTOMER_NAME}}" in the document body.
    """
    for key, value in replacements.items():
        placeholder = f"{{{{{key}}}}}"   # -> "{{KEY}}"
        writer.ReplaceAll(placeholder, str(value))
```

```python
writer = open_writer_template("templates/monthly_report.odt")
replace_placeholders(writer, {
    "CUSTOMER_NAME": "Acme Corp",
    "REPORT_DATE": "2026-03-31",
    "TOTAL_REVENUE": "$48,210.00",
})
```

Raw-UNO equivalent (for reference; useful when you need regex-based replacement, which ScriptForge's `ReplaceAll` does not directly support):

```python
def replace_placeholders_regex(document, replacements: dict[str, str]) -> None:
    """Regex-capable find & replace using the raw UNO XReplaceable interface."""
    replace_descriptor = document.createReplaceDescriptor()
    replace_descriptor.SearchRegularExpression = True
    for key, value in replacements.items():
        replace_descriptor.SearchString = r"\{\{" + key + r"\}\}"
        replace_descriptor.ReplaceString = str(value)
        document.replaceAll(replace_descriptor)
```

## 4.4 Formatting Text Programmatically

Appending a new styled paragraph at the end of the document:

```python
def append_paragraph(writer, text: str, style: str = "Default Paragraph Style") -> None:
    """Append a new paragraph with a given paragraph style to the document end."""
    writer.EndOfDocument()  # move the "cursor" ScriptForge tracks internally
    writer.InsertString(text, "AtEnd")  # ScriptForge helper writes at doc end
    # Paragraph style application still needs the raw UNO cursor for full control:
    document = writer.XComponent
    text_obj = document.getText()
    cursor = text_obj.createTextCursorByRange(text_obj.getEnd())
    cursor.ParaStyleName = style
```

Inline character formatting via raw UNO (bold a specific run of text you just inserted):

```python
def bold_last_paragraph(writer) -> None:
    document = writer.XComponent
    text_obj = document.getText()
    enum = text_obj.createEnumeration()
    last_paragraph = None
    while enum.hasMoreElements():
        last_paragraph = enum.nextElement()
    if last_paragraph is not None:
        para_cursor = text_obj.createTextCursorByRange(last_paragraph.Start)
        para_cursor.gotoEndOfParagraph(True)  # extend selection to end
        para_cursor.CharWeight = 150.0  # BOLD
```

## 4.5 Inserting Tables Programmatically

Writer tables are inserted via the raw UNO `TextTable` service (ScriptForge does not yet wrap table creation as of current versions, so this section is raw UNO by necessity):

```python
def insert_table(writer, rows: list[list[str]], name: str = "DataTable") -> None:
    """Insert a table at the end of the document from a 2D list of strings.
    rows[0] is treated as the header row."""
    document = writer.XComponent
    text_obj = document.getText()

    n_rows = len(rows)
    n_cols = len(rows[0]) if rows else 0

    table = document.createInstance("com.sun.star.text.TextTable")
    table.initialize(n_rows, n_cols)
    table.setName(name)

    text_obj.insertTextContent(text_obj.getEnd(), table, False)

    for r, row in enumerate(rows):
        for c, cell_value in enumerate(row):
            cell_name = table.getCellNames()[r * n_cols + c]
            cell = table.getCellByName(cell_name)
            cell.setString(str(cell_value))
            if r == 0:  # bold the header row
                cell.getText().createTextCursor().CharWeight = 150.0
```

```python
insert_table(writer, [
    ["Product", "Units Sold", "Revenue"],
    ["Widget A", "120", "$1,198.80"],
    ["Widget B", "75", "$1,087.50"],
])
```

## 4.6 Inserting Images (e.g. a Company Logo or a Chart Export)

```python
def insert_image(writer, image_path: str, width_mm: int = 40, height_mm: int = 40) -> None:
    """Insert an image (e.g. logo.png, or a chart exported from Calc in
    Part 5) at the end of the document, sized in millimeters."""
    import os
    if not os.path.isfile(image_path):
        raise FileNotFoundError(f"Image not found: {image_path}")

    document = writer.XComponent
    text_obj = document.getText()

    graphic = document.createInstance("com.sun.star.text.TextGraphicObject")
    graphic.GraphicURL = f"file://{os.path.abspath(image_path)}"
    graphic.AnchorType = 0  # com.sun.star.text.TextContentAnchorType.AT_PARAGRAPH
    graphic.Width = width_mm * 100    # 1/100 mm units
    graphic.Height = height_mm * 100

    text_obj.insertTextContent(text_obj.getEnd(), graphic, False)
```

## 4.7 Saving and Exporting to PDF

```python
def save_as_odt(writer, output_path: str) -> None:
    writer.SaveAs(output_path, overwrite=True)


def export_pdf(writer, output_path: str) -> None:
    """Export the current document to PDF using ScriptForge's ExportToPDF."""
    writer.ExportToPDF(output_path)
```

## 4.8 Full Report-Generation Pipeline

```python
def generate_monthly_report(template_path: str, data: dict, output_pdf_path: str) -> None:
    writer = open_writer_template(template_path)
    try:
        replace_placeholders(writer, data["placeholders"])
        insert_table(writer, data["table_rows"])
        if data.get("logo_path"):
            insert_image(writer, data["logo_path"])
        export_pdf(writer, output_pdf_path)
    finally:
        writer.CloseDocument(savechanges=False)


if __name__ == "__main__":
    generate_monthly_report(
        template_path="templates/monthly_report.odt",
        data={
            "placeholders": {
                "CUSTOMER_NAME": "Acme Corp",
                "REPORT_DATE": "2026-03-31",
            },
            "table_rows": [
                ["Product", "Units Sold", "Revenue"],
                ["Widget A", "120", "$1,198.80"],
            ],
            "logo_path": "templates/assets/logo.png",
        },
        output_pdf_path="output/acme_corp_march_2026.pdf",
    )
```

## 4.9 Error Handling: Missing Templates and Broken Placeholders

```python
def open_writer_template_safe(template_path: str):
    import os
    if not os.path.isfile(template_path):
        raise FileNotFoundError(
            f"Template not found at '{template_path}'. Confirm the file "
            f"exists in templates/ and the working directory is the "
            f"project root."
        )
    return open_writer_template(template_path)


def warn_on_unreplaced_placeholders(writer) -> list[str]:
    """After replace_placeholders(), scan for any leftover {{...}} tokens
    that weren't matched by a supplied key — usually a typo in the
    template or in the calling code."""
    import re
    document = writer.XComponent
    full_text = document.getText().getString()
    leftovers = re.findall(r"\{\{[A-Z0-9_]+\}\}", full_text)
    return leftovers
```

## Checkpoint

By the end of Part 4 you should have `src/writer_tools.py` containing:

- [ ] `open_writer_template()` / `open_writer_template_safe()`
- [ ] `replace_placeholders()` and the regex-capable raw-UNO variant
- [ ] `append_paragraph()` / `bold_last_paragraph()`
- [ ] `insert_table()`
- [ ] `insert_image()`
- [ ] `export_pdf()` / `save_as_odt()`
- [ ] `generate_monthly_report()` end-to-end pipeline
- [ ] `warn_on_unreplaced_placeholders()` validation helper

## Exercise Challenge

Add a `header_footer.py` helper that sets a page header showing `{{CUSTOMER_NAME}}` and a page footer showing "Page X of Y" using the document's `PageStyles` — a raw-UNO-only operation. Wire it into `generate_monthly_report()`.

## What's Next

Part 5 combines everything so far into one real pipeline: raw CSV data → Calc processing and chart generation → a Writer report with that chart embedded → final PDF export.
