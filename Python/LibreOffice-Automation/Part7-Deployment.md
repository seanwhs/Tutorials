# Part 7: Deployment & CLI Automation

This final part wraps the pipeline from Part 5 into a proper `argparse`-based CLI tool, `bin/office_cli.py`, suitable for headless Linux servers, cron jobs, and CI/CD pipelines — and covers process supervision so the underlying `soffice` listener stays healthy over long-running deployments.

## 7.1 CLI Design Goals

An enterprise-ready CLI tool should:

- Accept input paths as arguments, not hardcoded strings
- Support batch processing (many CSVs in one invocation)
- Exit with meaningful, non-zero exit codes on failure (critical for cron/CI to detect problems)
- Log to stdout/stderr in a way that's easy to capture in server logs
- Manage (or at least detect) the underlying `soffice` listener process itself, rather than assuming a human started it manually

## 7.2 The CLI Tool

Create `bin/office_cli.py`:

```python
#!/usr/bin/env python3
"""
office_cli.py — CLI entry point for the office-automation-toolkit.

Usage:
    office_cli.py report --input data/sales_raw.csv --output output/
    office_cli.py report --input-dir data/monthly/ --output output/
    office_cli.py check-connection --port 2002
"""
import argparse
import glob
import logging
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
sys.path.insert(0, "/usr/lib/libreoffice/program")

import pipeline  # Part 5's run_pipeline_safe(), PipelineStageError
import uno_bridge


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    stream=sys.stdout,
)
log = logging.getLogger("office_cli")


def cmd_check_connection(args: argparse.Namespace) -> int:
    try:
        uno_bridge.wait_for_port(args.host, args.port, timeout=args.timeout)
        log.info(f"Port {args.port} on {args.host} is accepting connections.")
        desktop, ctx = uno_bridge.connect(host=args.host, port=args.port)
        log.info("UNO bridge connection established successfully.")
        return 0
    except uno_bridge.LibreOfficeConnectionError as exc:
        log.error(f"Connection check failed: {exc}")
        return 1


def cmd_report(args: argparse.Namespace) -> int:
    csv_paths = []
    if args.input:
        csv_paths.append(args.input)
    if args.input_dir:
        csv_paths.extend(sorted(glob.glob(os.path.join(args.input_dir, "*.csv"))))

    if not csv_paths:
        log.error("No input CSVs specified. Use --input or --input-dir.")
        return 2

    os.makedirs(args.output, exist_ok=True)
    exit_code = 0

    for csv_path in csv_paths:
        log.info(f"Processing '{csv_path}'...")
        try:
            report_path = pipeline.run_pipeline_safe(csv_path, output_dir=args.output)
            log.info(f"OK: '{csv_path}' -> '{report_path}'")
        except pipeline.PipelineStageError as exc:
            log.error(f"FAILED: '{csv_path}': {exc}")
            exit_code = 1
            if not args.continue_on_error:
                return exit_code
        except Exception as exc:
            log.error(f"UNEXPECTED ERROR on '{csv_path}': {exc}")
            exit_code = 1
            if not args.continue_on_error:
                return exit_code

    return exit_code


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="office_cli.py",
        description="CLI automation tool for LibreOffice report generation.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    check_parser = subparsers.add_parser(
        "check-connection", help="Verify the headless LibreOffice UNO bridge is reachable."
    )
    check_parser.add_argument("--host", default="localhost")
    check_parser.add_argument("--port", type=int, default=2002)
    check_parser.add_argument("--timeout", type=float, default=15.0)
    check_parser.set_defaults(func=cmd_check_connection)

    report_parser = subparsers.add_parser(
        "report", help="Generate one or more sales reports from CSV input."
    )
    report_parser.add_argument("--input", help="Path to a single input CSV file.")
    report_parser.add_argument(
        "--input-dir", help="Directory containing multiple input CSV files."
    )
    report_parser.add_argument(
        "--output", default="output/", help="Output directory for generated PDFs."
    )
    report_parser.add_argument(
        "--continue-on-error",
        action="store_true",
        help="Keep processing remaining files if one fails (batch mode).",
    )
    report_parser.set_defaults(func=cmd_report)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
```

Make it executable:

```bash
chmod +x bin/office_cli.py
```

## 7.3 Running the CLI

Single file:

```bash
/usr/lib/libreoffice/program/python3 bin/office_cli.py report \
    --input data/sales_raw.csv \
    --output output/
```

Batch mode, continuing past individual failures (useful in nightly batch jobs where one bad file shouldn't block the rest):

```bash
/usr/lib/libreoffice/program/python3 bin/office_cli.py report \
    --input-dir data/monthly/ \
    --output output/ \
    --continue-on-error
```

Connection health check (useful as a pre-flight step in deployment scripts):

```bash
/usr/lib/libreoffice/program/python3 bin/office_cli.py check-connection --port 2002
echo "Exit code: $?"
```

## 7.4 Supervising the Headless LibreOffice Process on a Server

In production you do not want to manually run the `soffice --accept=...` command in a terminal and hope it survives. Use a real process supervisor. Two common free/open-source options:

**Option A — systemd unit** (typical for a dedicated Linux server):

Create `/etc/systemd/system/libreoffice-headless.service`:

```ini
[Unit]
Description=Headless LibreOffice UNO listener for office automation
After=network.target

[Service]
Type=simple
User=automation
ExecStart=/usr/bin/soffice --headless --invisible --nocrashreport \
    --nodefault --norestore --nologo --nofirststartwizard \
    --accept="socket,host=localhost,port=2002;urp;StarOffice.ComponentContext"
Restart=on-failure
RestartSec=5
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now libreoffice-headless.service
sudo systemctl status libreoffice-headless.service
```

`Restart=on-failure` is the key line — if `soffice.bin` crashes (it occasionally does under heavy load), systemd relaunches it automatically, and our CLI's `check-connection`/`wait_for_port` retry logic from Part 1 rides through the brief restart window gracefully.

**Option B — supervisord** (useful in Docker containers or non-systemd environments):

```ini
; /etc/supervisor/conf.d/libreoffice-headless.conf
[program:libreoffice-headless]
command=/usr/bin/soffice --headless --invisible --nocrashreport --nodefault --norestore --nologo --nofirststartwizard --accept="socket,host=localhost,port=2002;urp;StarOffice.ComponentContext"
autostart=true
autorestart=true
user=automation
```

## 7.5 Scheduling with Cron

```cron
# Run the nightly batch sales report job at 2:00 AM every day.
0 2 * * * cd /opt/office-automation-toolkit && /usr/lib/libreoffice/program/python3 bin/office_cli.py report --input-dir data/monthly/ --output output/ --continue-on-error >> /var/log/office_cli.log 2>&1
```

Cron jobs are silent by default; always redirect stdout/stderr to a log file (as above) since our `logging` setup writes to stdout, which cron would otherwise discard.

## 7.6 A Minimal CI Pipeline Example (GitHub Actions, free tier)

```yaml
# .github/workflows/report-check.yml
name: Report Generation Smoke Test
on: [push]
jobs:
  test-report-generation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install LibreOffice
        run: sudo apt-get update && sudo apt-get install -y libreoffice libreoffice-script-provider-python python3-uno
      - name: Start headless LibreOffice
        run: |
          soffice --headless --invisible --nocrashreport --nodefault --norestore --nologo --nofirststartwizard --accept="socket,host=localhost,port=2002;urp;StarOffice.ComponentContext" &
          sleep 8
      - name: Run report generation on sample data
        run: /usr/lib/libreoffice/program/python3 bin/office_cli.py report --input tests/fixtures/sample_sales.csv --output /tmp/output
```

This runs entirely on GitHub's free-tier runners with zero paid services, validating the whole toolkit end-to-end on every push.

## Checkpoint

By the end of Part 7 you should have:

- [ ] `bin/office_cli.py` with `report` and `check-connection` subcommands
- [ ] A systemd unit (or supervisord config) keeping headless LibreOffice alive and auto-restarting
- [ ] A working cron entry for nightly batch report generation
- [ ] A CI workflow that smoke-tests the pipeline on every push, using only free tools

## Exercise Challenge

Add a third subcommand, `office_cli.py cleanup --older-than 30`, that deletes generated PDFs in the output directory older than N days — a common requirement in real deployments to avoid unbounded disk growth from a long-running nightly job.

## Series Complete

You've now built a full, license-free automation toolkit spanning the UNO bridge architecture, ScriptForge, Calc, Writer, cross-application pipelines, internal macros, and production deployment. See **Appendix A** for the complete final file tree and `requirements.txt`, **Appendix B** for the ScriptForge quick-reference cheat sheet, and **Appendix C** for troubleshooting headless-mode issues you're likely to hit in the field.

---

Want the appendices next? Just say "next" or "appendices."
