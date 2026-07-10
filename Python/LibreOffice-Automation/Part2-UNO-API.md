# Part 2: The UNO API & ScriptForge

## 2.1 The UNO Object Model: Services, Interfaces, Structs

Every "thing" you interact with in LibreOffice via automation — a document, a sheet, a cell, a paragraph, a shape — is exposed as a **UNO object** that implements one or more **interfaces**. Understanding three core UNO concepts unlocks the entire API:

- **Service** — a named, instantiable component (e.g. `com.sun.star.sheet.SpreadsheetDocument`, `com.sun.star.text.TextDocument`). You ask a `ServiceManager` to create instances of services by name.
- **Interface** — a contract of methods an object supports (e.g. `XSpreadsheetDocument`, `XCellRange`, `XText`). UNO objects support *multiple* interfaces simultaneously, and PyUNO automatically exposes all of them on the same Python proxy object — you rarely need to explicitly "cast," unlike in Java/C++ UNO code.
- **Struct** — a plain data container passed by value (e.g. `com.sun.star.beans.PropertyValue`, `com.sun.star.table.CellRangeAddress`). You construct these directly with `uno.createUnoStruct(...)`.

Every interface name is prefixed with `X` (Microsoft COM developers will recognize the convention). For example, a spreadsheet cell supports (among others):

- `XCell` — numeric/formula value access
- `XText` — rich text content within the cell
- `XPropertySet` — generic getProperty/setProperty access to formatting attributes

## 2.2 Discovering an Object's Capabilities at Runtime

Because UNO is dynamically introspectable, you can ask any live object what it supports, which is invaluable when the official documentation is thin (a common complaint with UNO):

```python
def describe(uno_object) -> None:
    """Print all supported interfaces and (if available) properties
    of a live UNO object — a debugging tool for exploring the API."""
    print("Supported interfaces:")
    for iface in uno_object.SupportedServiceNames if hasattr(
        uno_object, "SupportedServiceNames"
    ) else []:
        print(" -", iface)

    if hasattr(uno_object, "getPropertySetInfo"):
        print("Properties:")
        for prop in uno_object.getPropertySetInfo().getProperties():
            print(f" - {prop.Name} ({prop.Type.typeName})")
```

Usage against a live cell object (assumes `sheet` and `desktop` already exist — we build the full open-document helper in Section 2.5):

```python
cell = sheet.getCellByPosition(0, 0)
describe(cell)
```

This single technique — instantiate, then interrogate — is how most working UNO automation code actually gets written in practice, since IDE autocomplete doesn't work for remote proxy objects.

## 2.3 Working with Structs: PropertyValue Example

Many UNO methods (especially `storeToURL`, used for PDF export) take arguments as an array of `PropertyValue` structs rather than keyword arguments, since UNO predates Python keyword-argument conventions and needs to work identically across Basic, Java, and C++:

```python
import uno

def make_property(name: str, value):
    """Build a single com.sun.star.beans.PropertyValue struct."""
    prop = uno.createUnoStruct("com.sun.star.beans.PropertyValue")
    prop.Name = name
    prop.Value = value
    return prop

def make_properties(**kwargs):
    """Convenience: build an array of PropertyValue structs from kwargs."""
    return tuple(make_property(k, v) for k, v in kwargs.items())
```

Example: exporting a document to PDF (full Writer/Calc PDF pipelines are built in Parts 4 and 5) requires exactly this pattern:

```python
export_props = make_properties(FilterName="calc_pdf_Export")
document.storeToURL("file:///tmp/output.pdf", export_props)
```

## 2.4 Raw UNO vs. ScriptForge: Why We're Switching

Raw UNO code is verbose, has poor discoverability, and forces you to think in terms of URL-encoded file paths, struct arrays, and interface names. **ScriptForge** is an official LibreOffice library (bundled since 7.1, actively maintained by the LibreOffice project itself, available both for internal Basic/Python macros *and* — with a small trick — for external Python scripts) that wraps the most common automation tasks in a clean, pythonic API.

Compare opening a document and reading a cell:

**Raw UNO:**

```python
url = "file:///home/user/data.ods"
props = make_properties(Hidden=True)
document = desktop.loadComponentFromURL(url, "_blank", 0, props)
sheet = document.Sheets.getByIndex(0)
value = sheet.getCellByPosition(0, 0).getValue()
document.close(False)
```

**ScriptForge:**

```python
from scriptforge import CreateScriptService

ui = CreateScriptService("UI")
doc = ui.OpenDocument("/home/user/data.ods", hidden=True)
value = doc.GetValue("A1")
doc.CloseDocument(savechanges=False)
```

No manual URL construction, no PropertyValue arrays, no struct boilerplate, and cell references use familiar spreadsheet notation ("A1") instead of zero-indexed `(col, row)` tuples. This is the API we use for the bulk of Parts 3, 4, and 5 — dropping back to raw UNO only when ScriptForge doesn't cover a specific operation (which we call out explicitly whenever it happens).

## 2.5 Bootstrapping ScriptForge for External Scripts

ScriptForge's `CreateScriptService` is designed primarily for macros running *inside* LibreOffice, where a hidden `ScriptForge` Basic library auto-initializes a bridge context. For **external** scripts (our primary mode), you must bootstrap that bridge manually the first time, in every script, right after connecting.

Update `src/uno_bridge.py` with a ScriptForge-aware connector — add this function:

```python
def connect_scriptforge(host: str = "localhost", port: int = 2002, retries: int = 3):
    """
    Connect to headless LibreOffice AND bootstrap the ScriptForge library
    for external-script use. Returns (desktop, context) exactly like
    connect(), but also makes CreateScriptService() usable afterward.
    """
    desktop, context = connect(host=host, port=port, retries=retries)

    # ScriptForge needs its Basic library initialized once per bridge
    # session before CreateScriptService() will work from Python.
    smgr = context.ServiceManager
    script_provider_factory = smgr.createInstanceWithContext(
        "com.sun.star.script.provider.MasterScriptProviderFactory", context
    )
    master_provider = script_provider_factory.createScriptProvider("")
    script = master_provider.getScript(
        "vnd.sun.star.script:ScriptForge.SF_Root.Initialize?"
        "language=Basic&location=application"
    )
    try:
        script.invoke((), (), ())
    except Exception:
        # Already initialized in this session — safe to ignore.
        pass

    return desktop, context
```

Then, in scripts that need ScriptForge, import and use it like so:

```python
from scriptforge import CreateScriptService
import uno_bridge

desktop, context = uno_bridge.connect_scriptforge()
ui = CreateScriptService("UI")
```

**Note on the `scriptforge` Python package:** for external-process use, `pip install` a small shim package is not sufficient by itself — the actual `scriptforge.py` module ships inside LibreOffice's own installation (`/usr/lib/libreoffice/program/scriptforge.py` on Linux, or accessible via the LibreOffice Python interpreter's path). Run external ScriptForge scripts using LibreOffice's bundled Python (as in Part 1), or add that path to `PYTHONPATH`/`sys.path` at the top of your script:

```python
import sys
sys.path.insert(0, "/usr/lib/libreoffice/program")
from scriptforge import CreateScriptService
```

## 2.6 Core ScriptForge Services You'll Use Constantly

| Service | Created via | Purpose |
|---|---|---|
| `UI` | `CreateScriptService("UI")` | Open/create documents, list open windows |
| `Calc` | `CreateScriptService("Calc", doc)` | Spreadsheet-specific operations (Part 3) |
| `Writer` | `CreateScriptService("Writer", doc)` | Document-specific operations (Part 4) |
| `FileSystem` | `CreateScriptService("FileSystem")` | Cross-platform path/file helpers |
| `Exception` | `CreateScriptService("Exception")` | Structured error inspection |

Full method-level cheat sheet lives in **Appendix B**.

## 2.7 Error Handling Patterns for Both APIs

Raw UNO throws native UNO exceptions (`com.sun.star.uno.RuntimeException`, `com.sun.star.io.IOException`, etc.) which subclass Python's `Exception`, so standard `try/except` works, but messages are often terse. ScriptForge additionally exposes a structured `Exception` service:

```python
from scriptforge import CreateScriptService

def safe_open(ui, path: str):
    try:
        return ui.OpenDocument(path, hidden=True)
    except Exception as exc:
        sf_exception = CreateScriptService("Exception")
        sf_exception.RaiseFatal(
            "OpenDocumentError",
            f"Could not open '{path}': {exc}"
        )
```

## Checkpoint

By the end of Part 2 you should be able to:

- [ ] Explain the difference between a UNO service, interface, and struct
- [ ] Use a `describe()`-style introspection helper against a live UNO object
- [ ] Build `PropertyValue` struct arrays for methods like `storeToURL`
- [ ] Bootstrap ScriptForge from an external Python script via `connect_scriptforge()`
- [ ] Open a document and read a cell value using ScriptForge's `UI` and `Calc` services

## What's Next

Part 3 puts ScriptForge (and raw UNO where necessary) to work on real spreadsheet automation: reading/writing ranges in bulk, applying number formats and cell styles, triggering formula recalculation, and processing tabular business data.
