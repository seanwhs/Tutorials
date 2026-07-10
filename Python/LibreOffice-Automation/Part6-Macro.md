# Part 6: Internal Macros vs. External Scripts

## 6.1 The Key Architectural Difference

Recall from Part 1: internal macros run *inside* the LibreOffice process, with no socket, no bridge, and no `uno.getComponentContext()` bootstrap — the runtime hands you a ready-made global, `XSCRIPTCONTEXT`, giving direct access to the current document and its `Desktop`, since your code is already "inside the room."

| Aspect | External Script (Parts 1–5, 7) | Internal Macro (this part) |
|---|---|---|
| Process | Separate Python process | Runs inside `soffice.bin` |
| Connection | Socket + UNO URL resolver | None needed — `XSCRIPTCONTEXT` provided |
| Trigger | You run the script (CLI, cron, CI) | User clicks a UI button / menu / keyboard shortcut |
| Python interpreter | Any (venv, system, or LO's bundled one) | LibreOffice's bundled interpreter *only* |
| Best for | Bulk/batch/server-side processing | End-user-triggered, single-document actions |
| Packages available | Anything you `pip install` | Only what's on LO's bundled interpreter's path (no easy pip install) |

**This is the single biggest practical tradeoff**: internal macros can't easily use third-party packages like `pandas` or `requests` (no straightforward `pip install` into LibreOffice's embedded Python), while external scripts can use your full normal Python environment. For anything beyond trivial UI convenience actions, prefer external scripts — but enterprise users often want a literal "click this button" experience for one specific document-level action, which is exactly what this part covers.

## 6.2 Where LibreOffice Looks for Python Macros

Two locations:

- **User-level** (available to one user, all documents): `~/.config/libreoffice/4/user/Scripts/python/` (Linux); `%APPDATA%\LibreOffice\4\user\Scripts\python\` (Windows).
- **Document-level** (embedded *inside* a single `.odt`/`.ods` file, travels with it): stored inside the document's own `Scripts/python/` folder within its zip structure — created via **Tools → Macros → Organize Macros → Python** or by manually editing the document package.

For this tutorial we use the user-level location, since it's simpler to iterate on with a text editor and doesn't require editing a zip archive.

## 6.3 Converting Part 5's Pipeline into a Macro

Create `~/.config/libreoffice/4/user/Scripts/python/sales_report_macro.py`:

```python
"""
sales_report_macro.py
Internal macro version of Part 5's pipeline: generates the sales report
PDF for the CURRENTLY OPEN Calc document, triggered by a UI button.
"""
import os
import uno
from datetime import date


def _prop(name, value):
    p = uno.createUnoStruct("com.sun.star.beans.PropertyValue")
    p.Name = name
    p.Value = value
    return p


def generate_report_from_active_document(*args):
    """
    Entry point LibreOffice calls when the macro is triggered.
    Note the *args signature — LibreOffice may pass an XScriptContext-like
    event argument depending on how the macro is invoked; we ignore it and
    use the global XSCRIPTCONTEXT instead, which is always available to
    internal Python macros regardless of trigger type.
    """
    model = XSCRIPTCONTEXT.getDocument()
    desktop = XSCRIPTCONTEXT.getDesktop()

    if not hasattr(model, "Sheets"):
        _show_message_box(
            model, "This macro only works on a Calc spreadsheet. "
            "Please run it with the sales data spreadsheet active."
        )
        return

    try:
        sheet = model.Sheets.getByName("Sheet1")
        used_range = sheet.getCellRangeByName("A1:D1000").queryContentCells(
            7  # com.sun.star.sheet.CellFlags.VALUE | STRING (non-empty)
        )
        addresses = used_range.RangeAddresses
        last_row = max(a.EndRow for a in addresses) if addresses else 0

        output_dir = os.path.expanduser("~/office-automation-toolkit/output")
        os.makedirs(output_dir, exist_ok=True)
        output_pdf = os.path.join(
            output_dir, f"sales_report_{date.today().isoformat()}.pdf"
        )

        export_props = (_prop("FilterName", "calc_pdf_Export"),)
        model.storeToURL(f"file://{output_pdf}", export_props)

        _show_message_box(model, f"Report exported successfully to:\n{output_pdf}")

    except Exception as exc:
        _show_message_box(model, f"Report generation failed:\n{exc}")


def _show_message_box(model, message: str) -> None:
    """Show a simple OK dialog — the internal-macro equivalent of print()."""
    frame = model.CurrentController.Frame
    window = frame.ContainerWindow
    toolkit = window.Toolkit
    msg_box = toolkit.createMessageBox(
        window,
        uno.Enum("com.sun.star.awt.MessageBoxType", "INFOBOX"),
        1,  # com.sun.star.awt.MessageBoxButtons.BUTTONS_OK
        "Sales Report Macro",
        message,
    )
    msg_box.execute()


# Required for LibreOffice's macro selector to list this function.
g_exportedScripts = (generate_report_from_active_document,)
```

Key differences from the external version worth calling out explicitly:

- No `connect()`/`connect_scriptforge()` call at all — `XSCRIPTCONTEXT` is simply available as a global.
- Errors surface via a **message box**, not stdout — there's no terminal for the end user to read.
- `g_exportedScripts` is required boilerplate telling LibreOffice's macro picker which function(s) in this file are runnable entry points.

## 6.4 Attaching the Macro to a UI Button

1. Open the target spreadsheet in LibreOffice Calc.
2. **View → Toolbars → Forms** (or **Insert → Push Button** in newer versions).
3. Draw a push button anywhere on the sheet.
4. Right-click the button → **Control Properties** → set **Label** to "Generate Sales Report".
5. Still in Control Properties, go to the **Events** tab → find **Execute Action** (or **Mouse button pressed**, depending on version) → click the `...` button → **Macro...**
6. In the macro browser: **My Macros → sales_report_macro → generate_report_from_active_document** → OK.
7. Exit Form Design mode (toggle the "Design Mode" icon off in the Forms toolbar) so the button becomes clickable rather than editable.
8. Save the document. Click the button — the report should generate and a confirmation dialog should appear.

## 6.5 ScriptForge Inside Internal Macros

ScriptForge is actually *more* convenient inside internal macros than in external scripts, since no manual bootstrap (Section 2.5) is required — `CreateScriptService` works immediately:

```python
from scriptforge import CreateScriptService

def generate_report_scriptforge_version(*args):
    doc = CreateScriptService("Calc", XSCRIPTCONTEXT.getDocument())
    ui = CreateScriptService("UI")
    # ... same logic as calc_tools.py, but no connect() call needed at all.
```

## 6.6 When to Choose Which Model

- **Choose external scripts** when: processing happens in bulk/batch, runs unattended (cron/CI/server), needs third-party packages (`pandas`, `requests`, `boto3`), or must be triggered by something other than a human clicking a document.
- **Choose internal macros** when: a specific person needs a one-click action on a specific open document, the logic is simple enough to not need external packages, or you're distributing a self-contained "smart template" `.odt`/`.ods` file to non-technical users who just need to click a button — no Python environment setup required on their end at all.

## Checkpoint

By the end of Part 6 you should have:

- [ ] `sales_report_macro.py` placed in LibreOffice's user Python macro directory
- [ ] A push button embedded in a real spreadsheet, wired to `generate_report_from_active_document`
- [ ] Verified the macro runs and shows a message box on both success and failure
- [ ] A clear mental model of when to reach for macros vs. external scripts

## Exercise Challenge

Convert `generate_report_scriptforge_version()` into a full working macro that also calls the chart-generation code from Part 5 (Section 5.3), embedding the resulting chart image into a companion Writer document, all triggered by the same button click.

## What's Next

Part 7 goes the other direction: wrapping everything from Parts 3–5 into a proper `argparse`-based command-line tool, suitable for headless Linux servers, cron jobs, and CI pipelines — completing the enterprise deployment story.
