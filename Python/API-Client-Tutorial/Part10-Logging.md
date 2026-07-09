# Part 10: Logging Configuration & Observability

## Goal
Centralize logging setup in `logging_config.py` so every module (`client.py`, `async_client.py`, `service.py`) produces consistent, structured, environment-appropriate log output — human-readable text locally, JSON in production.

## Why not just `print()`?

`print()` statements can't be filtered by severity, can't be redirected to a file/log aggregator without shell redirection hacks, and can't be turned off in production without deleting code. The standard `logging` module (used everywhere in this series via `logger = logging.getLogger(__name__)`) gives us severity levels, per-module control, and pluggable output formats/destinations — all configured in exactly one place.

## `logging_config.py`

```python
"""
Centralized logging configuration.

Rationale: Every module in this project does `logger = logging.getLogger(__name__)`
and just calls logger.debug/info/warning/error — none of them configure
handlers, formatters, or levels themselves. This file is the ONE place
that decides how logs actually look and where they go, called once at
application startup (see main.py, Part 11).

This keeps logging concerns out of business logic entirely, and lets you
swap text logging for JSON logging (e.g. for shipping to Datadog/ELK) by
changing only this file.
"""
import logging
import logging.config
import os


def configure_logging(level: str | None = None, json_format: bool | None = None) -> None:
    """Configure the root logger for the whole application.

    Args:
        level: e.g. "DEBUG", "INFO", "WARNING". Defaults to LOG_LEVEL env
            var, or "INFO" if unset.
        json_format: if True, emit structured JSON logs (recommended for
            production log aggregators). Defaults to the LOG_JSON env var
            ("true"/"false"), or False (human-readable text) if unset.
    """
    level = level or os.getenv("LOG_LEVEL", "INFO")
    if json_format is None:
        json_format = os.getenv("LOG_JSON", "false").lower() == "true"

    text_formatter = {
        "format": "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
        "datefmt": "%Y-%m-%d %H:%M:%S",
    }
    json_formatter = {
        # Minimal hand-rolled JSON formatter — no extra dependency needed.
        # For heavier structured-logging needs, python-json-logger is a
        # common drop-in choice.
        "()": "logging_config.JsonFormatter",
    }

    logging.config.dictConfig({
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "text": text_formatter,
            "json": json_formatter,
        },
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "formatter": "json" if json_format else "text",
                "level": level,
            },
        },
        "root": {
            "handlers": ["console"],
            "level": level,
        },
        "loggers": {
            # Quiet down noisy third-party libraries unless we're at DEBUG.
            "httpx": {"level": "WARNING" if level != "DEBUG" else "DEBUG"},
            "httpcore": {"level": "WARNING" if level != "DEBUG" else "DEBUG"},
        },
    })


class JsonFormatter(logging.Formatter):
    """Minimal JSON log formatter — one JSON object per line.

    Production log aggregators (Datadog, ELK, CloudWatch Logs Insights,
    etc.) parse structured JSON far more reliably than free-text logs.
    """

    def format(self, record: logging.LogRecord) -> str:
        import json as json_module

        payload = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S"),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json_module.dumps(payload)
```

## Design notes

- **`configure_logging()` is called exactly once, at startup** (in `main.py`, Part 11) — never inside `client.py`, `service.py`, etc. Library-style modules should only ever create loggers (`logging.getLogger(__name__)`) and emit records; they should never configure handlers/formatters themselves, since that's an application-level concern (a caller embedding this client into a larger app may already have their own logging config that shouldn't be clobbered).
- **`__name__` as the logger name everywhere**: this gives you a logger hierarchy matching your module structure (`client`, `service`, `async_client`), so you can selectively raise/lower verbosity per module in production without touching code (e.g. `logging.getLogger("client").setLevel(logging.DEBUG)` temporarily during an incident).
- **Quieting `httpx`/`httpcore` loggers**: these libraries log every single request/response at INFO/DEBUG by default, which is extremely noisy. We cap them at WARNING unless we're explicitly debugging at the DEBUG level ourselves.
- **Environment-driven config (`LOG_LEVEL`, `LOG_JSON`)**: lets you flip to verbose debug logging or JSON output in any environment (staging, prod, local) purely via environment variables — no code change or redeploy needed just to change log verbosity.
- **Text format locally, JSON in production**: humans reading a terminal want `2024-01-15 10:30:00 | INFO | service | Fetching GitHub user: octocat`. Log aggregators want structured JSON they can query/filter on. This lets both worlds be served from the same codebase.
- **Why not `loguru` here, given the "Quick Reference" table calls it out?** The original requirements specified the standard `logging` module explicitly; we honor that while noting `loguru` is a valid, easier-to-configure upgrade path — see the callout at the end of this part.

## Checkpoint

```python
from logging_config import configure_logging
import logging

configure_logging(level="DEBUG")
logger = logging.getLogger("my_test")
logger.debug("debug message")
logger.info("info message")
logger.warning("warning message")
```

Expected output (text format):
```
2024-01-15 10:30:00 | DEBUG    | my_test | debug message
2024-01-15 10:30:00 | INFO     | my_test | info message
2024-01-15 10:30:00 | WARNING  | my_test | warning message
```

Now test JSON mode:
```python
configure_logging(level="INFO", json_format=True)
logger.info("structured log test")
```

Expected output:
```json
{"timestamp": "2024-01-15T10:30:00", "level": "INFO", "logger": "my_test", "message": "structured log test"}
```

## Optional upgrade: switching to `loguru`

If you want prettier console output and less boilerplate config, swap `logging_config.py`'s internals for:

```python
from loguru import logger
logger.add("app.log", rotation="10 MB", level="INFO", serialize=True)  # serialize=True gives JSON
```

Because every other file in this series does `logger = logging.getLogger(__name__)`, switching fully to loguru would require touching those call sites too (loguru discourages per-module logger instances in favor of one global `logger`) — a worthwhile trade-off for solo/small-team projects, less so for large codebases with many contributors used to stdlib `logging`.

## Troubleshooting

- **No logs appear at all** — make sure `configure_logging()` is actually called before any other module logs anything; if `client.py` is imported and used before `configure_logging()` runs, Python's logging module falls back to a default "no handler" warning-only behavior.
- **Duplicate log lines** — usually means `configure_logging()` was called more than once (e.g. once in a test fixture and once in `main.py`); the `dictConfig` call with `disable_existing_loggers: False` should prevent most duplication issues, but avoid calling it twice in the same process when possible.
- **httpx still noisy at INFO level** — confirm you're not overriding the `httpx`/`httpcore` logger levels elsewhere in your code after calling `configure_logging()`.

---

Next up: **Part 11 — Putting It All Together: main.py End-to-End Example**. 
