# Mastering Office Automation: Python & LibreOffice for Enterprise Workflows

**A 7-part, code-heavy tutorial series for Python developers who want a free, open-source alternative to VBA / MS Office Interop.**

Every tool used in this series is **100% free and open source**: Python (the interpreter bundled with LibreOffice, or your system Python + `python3-uno`), LibreOffice itself, the UNO (Universal Network Objects) API, and the **ScriptForge** library that ships with modern LibreOffice (7.1+/7.6+ recommended).

---

## Why this series exists

Enterprises spend real money on Microsoft Office + VBA/Interop licensing just to automate spreadsheets and documents. LibreOffice is free, scriptable in Python, and — via UNO and ScriptForge — just as capable for bulk document generation, report automation, and headless server-side processing. This series treats LibreOffice as **infrastructure**: something you run headless on a Linux box, drive from external Python processes, and integrate into CI/CD or cron pipelines — not just "macros in a spreadsheet."

## Series Structure

| Part | Title | What You'll Build |
|---|---|---|
| 1 | The Automation Environment | Dev environment setup, VS Code config, first socket connection to a headless LibreOffice instance |
| 2 | The UNO API & ScriptForge | Understanding the UNO object model; rewriting raw-UNO code using ScriptForge |
| 3 | Mastering LibreOffice Calc | Programmatic spreadsheet reads/writes, formatting, formulas, bulk data processing |
| 4 | Mastering LibreOffice Writer | Template-driven report generation, find & replace, tables, images |
| 5 | Cross-Application Workflows | CSV → Calc (chart generation) → Writer → PDF pipeline |
| 6 | Internal Macros vs. External Scripts | Converting the external script into a UI-triggered internal macro with a button |
| 7 | Deployment & CLI Automation | `argparse`-based CLI tool for headless batch processing on a Linux server |

Each part is its own note, titled **"LibreOffice Automation - Part N: [name]"**.

Plus:
- **Appendix A** — Codebase reference (full file tree + `requirements.txt`)
- **Appendix B** — ScriptForge Cheat Sheet
- **Appendix C** — Troubleshooting Headless Mode

All three appendices live in note **"LibreOffice Automation - Appendices A-C"**.

## Project: `office-automation-toolkit`

Across the series we incrementally build one real project — a **billing/reporting automation toolkit** that:

1. Connects to headless LibreOffice over a UNO socket (Part 1)
2. Uses ScriptForge for clean, pythonic document manipulation (Part 2)
3. Ingests raw sales data into Calc, formats it, computes formulas (Part 3)
4. Generates a Writer report from a `.odt` template with placeholders, tables, and a logo image (Part 4)
5. Chains Calc chart generation + Writer templating into one PDF-producing pipeline (Part 5)
6. Ships as both a UI macro (Part 6) and a CLI tool for cron/CI (Part 7)

Final file tree is in Appendix A — every part tells you exactly which file(s) you're adding or editing.

## Prerequisites

- LibreOffice 7.1+ installed (7.6+ ideal — ScriptForge is bundled and enabled by default from 7.1 onward; on Debian/Ubuntu you may need `libreoffice-script-provider-python`)
- Basic Python 3.8+ knowledge (functions, classes, context managers)
- Comfortable with a terminal / shell
- No Windows-only tools, no paid licenses, no cloud APIs — everything runs locally

## Recommended reading order

Strictly sequential, Part 1 → 7. Part 2 concepts (UNO service model) are assumed known from Part 3 onward. Part 5 assumes Parts 3 & 4's code exists in your project. Part 6 refactors Part 5's script. Part 7 wraps Part 6/5's logic in a CLI.
