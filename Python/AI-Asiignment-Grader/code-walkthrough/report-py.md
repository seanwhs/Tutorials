## 1. Imports and PDF tools

```python
import io
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Table, TableStyle
from reportlab.lib.units import mm
from reportlab.lib.styles import getSampleStyleSheet
```

### Why this block exists
This section brings in the PDF-building tools. `io` lets the code create PDFs in memory, `A4` defines the page size, and the `platypus` classes help assemble text, tables, and styles into a document. This module’s job is to turn grading results into a polished report the user can download.

### Python concepts used
- Imports from nested packages.
- In-memory binary buffers with `io`.
- Layout components from a PDF library.
- Measurement units like `mm` for precise sizing.

### Pattern analysis
This is a **document generation setup**. It prepares the building blocks for a report instead of using low-level drawing commands everywhere.

### What if
Change the page size from `A4` to `letter` and see how the layout proportions shift.

***

## 2. Base style helper

```python
def _base_styles():
    """Initializes and configures the document paragraph styles."""
    return getSampleStyleSheet()
```

### Why this block exists
This function creates a standard style set for paragraphs and headings. It gives the report a consistent visual structure without manually defining every font and spacing rule.

### Python concepts used
- A function that returns a library-generated object.
- A docstring describing purpose.
- Helper naming with a leading underscore.

### Pattern analysis
This is a **style initialization helper**. It centralizes formatting so other functions can reuse the same style definitions.

### What if
Modify the returned stylesheet later to add your own custom heading style and compare the result.

***

## 3. Metadata table

```python
def _meta_table(student, subject, filename, styles):
    """Generates a small metadata table for tracking assignment context."""
    data = [
        [Paragraph("<b>Student</b>", styles["SmallMeta"]), Paragraph(student, styles["BodyText"])],
        [Paragraph("<b>Subject</b>", styles["SmallMeta"]), Paragraph(subject, styles["BodyText"])],
        [Paragraph("<b>File</b>", styles["SmallMeta"]), Paragraph(filename, styles["SmallMeta"])],
    ]
    t = Table(data, colWidths=[38*mm, None])
    # Styling for the table... [22]
    return t
```

### Why this block exists
This builds a small information table so the report clearly shows which student, subject, and file it refers to. That helps with organization and record keeping.

### Python concepts used
- Lists of lists represent table rows and columns.
- `Paragraph(...)` lets table cells contain formatted text.
- `colWidths=[38*mm, None]` fixes one column width and lets the other adapt.

### Pattern analysis
This is a **metadata block**. It separates identification details from the main feedback content.

### What if
Add a fourth row for the submission date and see how the report becomes more complete.

***

## 4. Marked PDF generator

```python
def create_marked_pdf(student, subject, filename, marked_image_buffer, overall_feedback="", grade="", report_text="", corrections=None):
    """Creates a two-page PDF with annotated image and feedback report."""
    buffer = io.BytesIO()
    PAGE_W, PAGE_H = A4
    # PDF assembly logic (Page 1: Image, Page 2: Text Report)... [20]
    return buffer
```

### Why this block exists
This is the main export function for image-based assignments. It creates a report with the marked-up image on one page and the teacher-style written feedback on another page.

### Python concepts used
- In-memory output with `BytesIO`.
- Default parameter values like `overall_feedback=""`.
- Page constants from the PDF library.

### Pattern analysis
This is an **output assembly function**. It combines multiple pieces into one downloadable document.

### What if
Change it from two pages to one page and observe how much tighter the layout would need to become.

***

## 5. Text-only PDF generator

```python
def create_pdf_report(student, subject, filename, feedback):
    """Generates a streamlined, text-focused PDF report for non-image assignments."""
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4)
    # Text-only feedback assembly... [23]
    return buffer
```

### Why this block exists
This is the simpler report path for assignments that do not need image annotations. It builds a text-focused PDF containing the grading feedback and context.

### Python concepts used
- `SimpleDocTemplate` is a high-level document builder.
- Returns a binary buffer instead of writing to disk.
- The same PDF page size is reused for consistency.

### Pattern analysis
This is a **branch-specific report builder**. It handles the text workflow separately from the image workflow.

### What if
Add a summary heading at the top and compare how it changes readability.

## Big-picture reading of the module

This file is the report layer of the system. Its main job is to take the grading result and package it into a readable, shareable PDF. It does not decide grades or create annotations; it only formats the output.

The main ideas here are:
- **Consistent document styling**.
- **Table-based metadata** for clarity.
- **Separate paths for image and text submissions**.
- **In-memory PDF generation** for smooth download handling.
