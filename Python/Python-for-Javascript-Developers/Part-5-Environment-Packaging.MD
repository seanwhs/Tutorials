## Python for JavaScript Developers — Part 5: Environments, Packaging, and Project Layout

Once you’re comfortable writing Python code, the next question is: *how do you structure, install, and run it like a real project?* If you come from Node, you’re used to:

- `npm`/`pnpm` for dependencies  
- `package.json` for scripts and metadata  
- `node_modules` and lockfiles  
- Project layouts with `src/`, `tests/`, etc.  

Python has its own ecosystem for environments, packaging, and structure. The concepts map well once you see the parallels.

***

### Virtual Environments ↔ node_modules + per-project deps

In JS, you naturally get per-project dependencies via `node_modules` and `package.json`. Python achieves per-project isolation with **virtual environments**.

High-level mapping:

- Python `venv` ≈ “a local Python with its own site-packages”  
- JS `node_modules` ≈ “per-project dependencies”  

Typical workflow:

```bash
# Create a virtual environment
python -m venv .venv

# Activate it (Unix/macOS)
source .venv/bin/activate

# Activate it (Windows PowerShell)
.\.venv\Scripts\Activate.ps1

# Install dependencies inside this env
pip install requests
```

Once activated, `python` and `pip` point to that environment, not your global install.

For JS devs: you can frame `venv` as “the Python way to avoid global `pip install` hell—like making sure each project’s deps live in its own sandbox.”

***

### Dependencies: pip ↔ npm

Just as `npm` installs packages from the registry, `pip` installs Python packages from PyPI.

Common operations:

```bash
pip install requests
pip install "fastapi[standard]"
pip freeze > requirements.txt
```

The `requirements.txt` file is roughly analogous to `package.json`’s dependency list, but it’s usually just a plain list of pinned versions.

Quick mapping:

- `pip install package` ≈ `npm install package`  
- `requirements.txt` ≈ `package.json` + `package-lock` (but simpler)  
- Tools like Poetry/uv/hatch ≈ pnpm/Yarn—opinionated package managers with lockfiles and extra features.

You can choose to mention one modern tool (e.g., Poetry or uv) as “a more JS-like experience” for readers who want richer project metadata.

***

### Basic Project Layout ↔ src/ + tests/

In Node, a common structure is:

```text
my-app/
  package.json
  src/
    index.js
    lib/
  tests/
    ...
```

Python has similar conventions, especially for apps and libraries.

Example layout:

```text
my_app/
  pyproject.toml        # optional, modern project metadata
  requirements.txt      # dependencies
  src/
    my_app/
      __init__.py
      main.py
      services.py
      models.py
  tests/
    test_main.py
    test_services.py
```

Key ideas:

- A folder with `__init__.py` is a package (e.g., `my_app`).  
- Code lives in `src/my_app/` to avoid certain import pitfalls.  
- Tests go in `tests/`, commonly using `pytest`.

For JS devs, you can say: “Think of `src/my_app` as your `src/` in Node, and of `__init__.py` as the marker that ‘this folder is importable as a module’.”

***

### Running Code: Scripts ↔ npm scripts

In Node, you use `npm run dev`, `npm run build`, etc., defined in `package.json`. Python doesn’t have a single canonical “scripts” mechanism, but you get similar behavior via:

- Direct CLI entry points (`python -m my_app.main`)  
- Tool-driven scripts (e.g., `pytest`, `uv run`, `poetry run`, `invoke` tasks)  

Simple example:

```bash
# Inside the project
python -m my_app.main
```

If `main.py` has:

```python
def main():
    print("Hello from Python")

if __name__ == "__main__":
    main()
```

You can run it either with `python src/my_app/main.py` or `python -m my_app.main` (module-style).

For JS devs, it’s helpful to frame `python -m package.module` as “similar to running `node` with an entry file, but using the module naming instead of path.”

***

### Comparing JS and Python Project Tooling

Here’s a quick side-by-side:

| Concept                  | JavaScript (Node)             | Python                                |
|--------------------------|-------------------------------|----------------------------------------|
| Package manager          | npm, pnpm, Yarn               | pip, Poetry, uv, Hatch   |
| Dependency file          | package.json, lockfile        | requirements.txt, pyproject.toml |
| Per-project deps         | node_modules/                 | virtualenv (.venv/)            |
| Entry point              | index.js, scripts             | `python -m package.module`, CLI tools |
| Test runner              | Jest, Vitest                  | pytest                          |

This table reassures JS devs that nothing here is alien—it’s the same concerns with different tooling and conventions.

***

### Minimal “JS-like” Python App Example

Pull it together with a tiny “hello-API” style project layout that mirrors a Node mental model.

Assume:

```text
fast_api_demo/
  .venv/
  requirements.txt
  src/
    fast_api_demo/
      __init__.py
      main.py
```

`requirements.txt`:

```text
fastapi
uvicorn
```

`src/fast_api_demo/main.py`:

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/hello")
def hello():
    return {"message": "Hello from Python"}
```

Run it:

```bash
# activate venv first
uvicorn fast_api_demo.main:app --reload
```

You can explicitly map this to a JS mental model:

- `FastAPI` ≈ `Express`/`Hono` style HTTP framework.  
- `uvicorn` ≈ `node` + dev server (like `nodemon` with hot reload).  
- Project layout ≈ typical Node backend with `src/` and a single main entry.

This gives your JS readers a concrete “I can now spin up a Python web API” moment.

***

### What we have achieved?

After this part, you should be able to:

- Set up isolated Python environments per project (`venv` or a higher-level tool).  
- Install and pin dependencies with `pip` and `requirements.txt` (or `pyproject.toml`).  
- Organize code with `src/`, packages, and tests.  
- Run code in a way that maps cleanly to their Node experience.
