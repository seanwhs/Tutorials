# Part 1: Environment Setup & Dependencies

## Goal
Get a clean, isolated Python environment with all dependencies installed and verified.

## Step 1 — Create the project folder and virtual environment

```bash
mkdir api-client-tutorial && cd api-client-tutorial
python3 -m venv .venv

# Activate it:
source .venv/bin/activate        # macOS/Linux
.venv\Scripts\activate           # Windows (PowerShell: .venv\Scripts\Activate.ps1)
```

You should see `(.venv)` prefixed in your shell prompt once activated.

## Step 2 — Create `requirements.txt`

```txt
httpx>=0.27.0
pydantic>=2.7.0
tenacity>=8.2.3
python-dotenv>=1.0.1
```

We'll add test-only dependencies (`pytest`, `respx`) in Part 12 to keep production installs lean.

## Step 3 — Install

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

## Step 4 — Verify installation

Create a scratch file `verify.py`:

```python
import httpx
import pydantic
import tenacity
import dotenv

print("httpx:", httpx.__version__)
print("pydantic:", pydantic.VERSION)
print("tenacity:", tenacity.__version__)
print("python-dotenv OK")
```

Run it:

```bash
python verify.py
```

Expected output (versions may differ slightly, that's fine):

```
httpx: 0.27.0
pydantic: 2.7.1
tenacity: 8.2.3
python-dotenv OK
```

Delete `verify.py` once confirmed — it's not part of the final project.

## Step 5 — Initialize the project layout

```bash
touch config.py exceptions.py models.py client.py async_client.py service.py logging_config.py main.py
mkdir tests
touch tests/__init__.py tests/test_service.py
touch .env .env.example
echo ".env" >> .gitignore
echo ".venv/" >> .gitignore
echo "__pycache__/" >> .gitignore
```

> **Why `.env` is gitignored but `.env.example` is not:** `.env.example` documents *which* variables are needed without leaking real secrets. Anyone cloning the repo copies it to `.env` and fills in their own values.

## Checkpoint

At this point you should have:
```
api-client-tutorial/
├── .venv/
├── .env
├── .env.example
├── .gitignore
├── requirements.txt
├── config.py
├── exceptions.py
├── models.py
├── client.py
├── async_client.py
├── service.py
├── logging_config.py
├── main.py
└── tests/
    ├── __init__.py
    └── test_service.py
```
All files empty except `requirements.txt` and `.gitignore` — that's expected, we fill them in over the next parts.

## Troubleshooting

- **`pip: command not found`** — make sure the venv is activated; use `python -m pip install ...` as a fallback.
- **SSL errors installing packages** — corporate proxy/firewall issue; try `pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org -r requirements.txt`.
- **Wrong Python version** — run `python3 -m venv .venv` explicitly (not `python`) if your system defaults to Python 2 or an old 3.x.

---

Next up: **Part 2 — Configuration & Credentials**. 
