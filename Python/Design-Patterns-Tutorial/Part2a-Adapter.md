# Part 2a — Adapter

Converts the interface of one class into another interface clients expect — a "translator" between incompatible APIs.

```python
class LegacyPrinter:
    """Third-party/legacy code we cannot modify."""
    def old_print_method(self, text: str) -> None:
        print(f"[Legacy] {text}")

class ModernPrinter:
    """The interface our application code actually expects."""
    def print(self, text: str) -> None:
        raise NotImplementedError

class LegacyPrinterAdapter(ModernPrinter):
    def __init__(self, legacy_printer: LegacyPrinter):
        self._legacy_printer = legacy_printer

    def print(self, text: str) -> None:
        # Translate the modern call into the legacy method signature
        self._legacy_printer.old_print_method(text)


# Usage -- client code only ever talks to ModernPrinter.print()
def print_report(printer: ModernPrinter, text: str) -> None:
    printer.print(text)

legacy = LegacyPrinter()
adapter = LegacyPrinterAdapter(legacy)
print_report(adapter, "Quarterly Report")
```

**Expected output:**
```
[Legacy] Quarterly Report
```

---

