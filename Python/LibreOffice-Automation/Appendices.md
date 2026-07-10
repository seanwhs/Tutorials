# Appendices

## Appendix A: Codebase Reference

### Final Project File Tree

```text
office-automation-toolkit/
├── .venv/                          # Python virtual environment (system Python)
├── .vscode/
│   └── settings.json               # points VS Code at soffice's PyUNO path
├── bin/
│   └── office_cli.py               # Part 7: argparse CLI entry point
├── data/
│   ├── sales_raw.csv                # sample input data
│   └── monthly/                     # batch-mode input directory
├── output/                          # generated PDFs/ODS land here (gitignored)
├── templates/
│   ├── monthly_report.odt           # Writer template with {{PLACEHOLDER}} tokens
│   └── assets/
│       └── logo.png
├── src/
│   ├── __init__.py
│   ├── uno_bridge.py                # Part 1/2: connect(), connect_scriptforge()
│   ├── calc_tools.py                 # Part 3: Calc read/write/format/formula helpers
│   ├── writer_tools.py               # Part 4: Writer template/table/image helpers
│   └── pipeline.py                   # Part 5: cross-application orchestration
├── tests/
│   ├── fixtures/
│   │   └── sample_sales.csv
│   └── test_calc_tools.py
├── ~/.config/libreoffice/4/user/Scripts/python/
│   └── sales_report_macro.py        # Part 6: internal macro (outside project repo)
├── requirements.txt
├── README.md
└── .gitignore
```

### `requirements.txt`

```text
# Note: `uno` itself is NOT pip-installable — it ships inside LibreOffice.
# These are the *additional* packages your external scripts may use.

# Optional but recommended for real-world CSV/data wrangling:
pandas>=2.2

# Optional: nicer CLI output formatting
rich>=13.7

# Testing
pytest>=8.0
```

### `.gitignore` (recommended)

```text
.venv/
output/*.pdf
output/*.ods
__pycache__/
*.pyc
```

---

## Appendix B: ScriptForge Cheat Sheet

### Bootstrapping (external scripts only — see Part 2.5)

| Task | Code |
|---|---|
| Import ScriptForge from LO's bundled path | `sys.path.insert(0, "/usr/lib/libreoffice/program"); from scriptforge import CreateScriptService` |
| Bootstrap the bridge + ScriptForge | `desktop, ctx = uno_bridge.connect_scriptforge()` |

### UI Service

| Task | Code |
|---|---|
| Open an existing document | `ui.OpenDocument(path, hidden=True)` |
| Create a new blank document | `ui.CreateDocument("Calc", hidden=True)` (or `"Writer"`, `"Impress"`) |
| List currently open documents | `ui.Documents` |

### Calc Service

| Task | Code |
|---|---|
| Get a Calc service handle from a doc | `CreateScriptService("Calc", doc)` |
| Read one cell | `calc.GetValue("Sheet1.A1")` |
| Write one cell | `calc.SetValue("Sheet1.A1", "text or number")` |
| Write a formula | `calc.SetFormula("Sheet1.D2", "=B2*C2")` |
| Read a rectangular range as 2D list | `calc.GetArray("Sheet1.A1:D10")` |
| Write a 2D list in one call | `calc.SetArray("Sheet1.A1", rows)` |
| Apply a named cell style | `calc.SetCellStyle("Sheet1.A1:D1", "Heading 1")` |
| Apply a number format | `calc.SetFormat("Sheet1.C2:C10", "#,##0.00")` |
| Save under a new name/format | `calc.SaveAs(path, overwrite=True)` |
| Close the document | `calc.CloseDocument(savechanges=False)` |
| Access the raw UNO document (escape hatch) | `calc.XComponent` |

### Writer Service

| Task | Code |
|---|---|
| Get a Writer service handle from a doc | `CreateScriptService("Writer", doc)` |
| Replace all occurrences of text | `writer.ReplaceAll("{{NAME}}", "Acme Corp")` |
| Insert text at the end of the document | `writer.InsertString(text, "AtEnd")` |
| Move "cursor" to end of document | `writer.EndOfDocument()` |
| Export current document to PDF | `writer.ExportToPDF(output_path)` |
| Save under a new name/format | `writer.SaveAs(output_path, overwrite=True)` |
| Close the document | `writer.CloseDocument(savechanges=False)` |
| Access the raw UNO document (escape hatch) | `writer.XComponent` |

### FileSystem Service

| Task | Code |
|---|---|
| Create the service | `CreateScriptService("FileSystem")` |
| Check if a file exists | `fs.FileExists(path)` |
| Build a cross-platform path | `fs.BuildPath(folder, filename)` |
| List files matching a pattern | `fs.Files(folder, "*.csv")` |

### Exception Service

| Task | Code |
|---|---|
| Create the service | `CreateScriptService("Exception")` |
| Raise a fatal error with a custom message | `sf_exception.RaiseFatal("MyError", "details...")` |
| Get the last raised exception's info | `sf_exception.Description` |

### Things ScriptForge Does NOT Cover (drop to raw UNO)

- Chart creation/embedding (Part 5.3)
- Text table creation in Writer (Part 4.5)
- Fine-grained borders/conditional formatting (Part 3.4)
- Page header/footer manipulation (Part 4 exercise)

---

## Appendix C: Troubleshooting Headless Mode

### "Connection refused" / socket never accepts connections

**Symptom:** `LibreOfficeConnectionError: Port 2002 ... never accepted a connection`

**Causes & fixes:**
1. `soffice` isn't actually running — check with `ps aux | grep soffice` (Linux/macOS) or Task Manager (Windows).
2. The `--accept` flag has a typo. It must be exactly: `--accept="socket,host=localhost,port=2002;urp;StarOffice.ComponentContext"` — note the semicolons, not commas, separating the three segments.
3. A firewall is blocking localhost traffic on that port (rare, but happens on some hardened Linux servers) — test with `telnet localhost 2002` or `nc -zv localhost 2002`.
4. You started `soffice` with a *different* port than your script is trying to connect to — grep your launch command and your Python `port=` argument to confirm they match.

### Zombie / stuck `soffice.bin` processes

**Symptom:** A previous run crashed or was killed uncleanly (e.g. `Ctrl+C` mid-operation, or an OOM kill), leaving a `soffice.bin` process that holds the port but no longer responds to new UNO connections — new launches fail with "address already in use" or connections silently hang forever.

**Fix — find and kill it:**

```bash
# Find all soffice processes:
ps aux | grep soffice

# Kill by PID:
kill -9 <PID>

# Or kill everything named soffice.bin at once (use with care):
pkill -9 -f soffice.bin
```

**Prevention:**
- Always use the systemd/supervisord process supervision from Part 7.5-7.4 in any long-running deployment — a supervisor cleanly restarts a crashed process instead of leaving zombies.
- In scripts, register a cleanup handler so your *own* process failures don't cascade into leaving documents open:

```python
import atexit

def register_cleanup(doc):
    atexit.register(lambda: doc.CloseDocument(savechanges=False))
```

- Never `kill -9` your *only* running `soffice` instance while other automation is mid-flight on the same port — coordinate via a lock file or a single supervised long-lived process instead of ad hoc launches per script run.

### Path resolution issues ("file not found" despite the file existing)

**Symptom:** `loadComponentFromURL` or `storeToURL` fails even though the file clearly exists on disk.

**Cause:** UNO's URL-based APIs require **file:// URLs**, not bare OS paths, and require **absolute** paths — relative paths silently fail or resolve against the wrong working directory (often LibreOffice's own install directory, not your script's `cwd`).

**Fix:**

```python
import os

def to_file_url(path: str) -> str:
    """Always convert a local path to an absolute file:// URL before
    passing it to any UNO/ScriptForge open/save call."""
    absolute_path = os.path.abspath(path)
    # On Windows, must also convert backslashes and add a leading slash:
    if os.name == "nt":
        absolute_path = absolute_path.replace("\\", "/")
        return f"file:///{absolute_path}"
    return f"file://{absolute_path}"
```

Note that ScriptForge's `OpenDocument`/`SaveAs`/`ExportToPDF` generally accept plain OS paths directly (it converts internally) — this URL conversion is mainly needed when dropping down to raw UNO calls like `loadComponentFromURL` or `storeToURL`, as seen in Parts 2, 5, and 6.

### "RuntimeException: object is disposed" during long-running scripts

**Symptom:** A previously-valid document/cell/sheet reference suddenly throws `com.sun.star.lang.DisposedException` mid-script.

**Cause:** The document (or the whole LibreOffice bridge) was closed or crashed while your script still held a reference to an object inside it. Common in long batch jobs where an earlier stage's `.CloseDocument()` fires, but a later stage still references a variable from that closed document.

**Fix:** Scope document handles tightly (as done throughout Part 5's `stage_1`/`stage_3` pattern) — never hold a document reference across a stage boundary once you've called `.CloseDocument()` on it, and always wrap document lifetimes in `try/finally` as shown in Parts 4 and 5.

### Headless LibreOffice consuming excessive memory over time

**Symptom:** After processing thousands of documents in a long-running server process, `soffice.bin`'s RSS memory climbs steadily and never comes back down.

**Cause:** Documents not explicitly closed (Part 1.3's core warning), or LibreOffice's internal caches (undo history, autocorrect dictionaries) accumulating.

**Fix:**
- Audit every code path for a matching `.CloseDocument()`/`.close()` — especially exception paths; use `try/finally` everywhere, as modeled throughout this series.
- For very long-running supervised processes, schedule a periodic restart (e.g. nightly, via the systemd unit's `Restart=` combined with a cron-triggered `systemctl restart libreoffice-headless`) as a pragmatic safety net rather than chasing every possible internal cache leak.

---

That's the complete 7-part series plus all three appendices — the full **"Mastering Office Automation: Python & LibreOffice for Enterprise Workflows"** tutorial is now done and saved across 9 notes. Let me know if you'd like any part expanded, revised, or if you want the exercise challenges from any part actually solved out in full code.
