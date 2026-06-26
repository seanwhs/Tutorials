## Python for JavaScript Developers — Part 6: Testing and Tooling (pytest ↔ Jest/Vitest)

By Part 5, your JS readers can structure a Python project with environments, dependencies, and basic layout. The next thing they’ll naturally look for is: *“How do I test this like I do with Jest or Vitest?”* Part 6 is a great place to introduce **pytest** and connect it directly to modern JS testing habits.

You can frame this entire part as: “If you already know Jest/Vitest, pytest will feel like a slightly more minimal but very powerful cousin.”

***

### Testing Mindset: Same Goals, Different Syntax

JS testing mental model:

- Write small, focused tests  
- Group them with `describe` / `test` / `it`  
- Use assertions like `expect(value).toBe(...)`  

Python testing with pytest is similar:

- Write functions whose names start with `test_`  
- Group tests in files like `test_something.py`  
- Use plain `assert` statements, plus helpers/fixtures.

You can explicitly say: “Think of `assert` in pytest as your `expect(...).toBe(...)` in Jest, but with less ceremony.”

***

### Basic pytest Test ↔ Basic Jest Test

#### Python (pytest)

```python
# src/math_utils.py
def add(a, b):
    return a + b
```

```python
# tests/test_math_utils.py
from src.math_utils import add

def test_add():
    result = add(2, 3)
    assert result == 5
```

Run:

```bash
pytest
```

#### JavaScript (Jest/Vitest)

```javascript
// src/mathUtils.js
export function add(a, b) {
  return a + b;
}
```

```javascript
// tests/mathUtils.test.js
import { add } from "../src/mathUtils.js";

test("add", () => {
  const result = add(2, 3);
  expect(result).toBe(5);
});
```

Mapping:

- `test_add` function ≈ `test("add", ...)` block.  
- `assert result == 5` ≈ `expect(result).toBe(5)`.  
- `pytest` CLI ≈ `jest` or `vitest` CLI.

For JS devs, highlight that pytest relies heavily on **convention over configuration**—just like Vitest’s default file naming patterns.

***

### Organizing Tests: Files and Folders

JS habits:

- `tests/` or `__tests__/` directory  
- Mirrors `src/` structure  

Python conventions with pytest:

```text
my_app/
  src/
    my_app/
      math_utils.py
      services.py
  tests/
    test_math_utils.py
    test_services.py
```

Rules of thumb:

- Test files named `test_xxx.py`.  
- Tests inside those files as `test_something` functions.  
- `pytest` auto-discovers everything that matches `test_*.py` and `test_*` inside.  

The mental mapping is straightforward: “Replace `.test.js` with `test_*.py`, keep the same idea of mirroring your source structure.”

***

### Fixtures ↔ Test Setup / beforeEach

JS testing tools offer `beforeEach`, `afterEach`, and custom helpers for reusable setup. Pytest exposes **fixtures**, which are a very powerful and ergonomic way to share setup logic.

#### Python (pytest fixtures)

```python
# tests/conftest.py
import pytest

@pytest.fixture
def sample_user():
    return {"id": 1, "name": "Alice"}
```

```python
# tests/test_users.py
def test_user_has_name(sample_user):
    assert sample_user["name"] == "Alice"
```

Pytest will:

- Discover the `sample_user` fixture.  
- Inject it into tests that declare a `sample_user` parameter.  

#### JavaScript (rough equivalent)

```javascript
// tests/users.test.js
function createSampleUser() {
  return { id: 1, name: "Alice" };
}

test("user has name", () => {
  const user = createSampleUser();
  expect(user.name).toBe("Alice");
});
```

You can describe fixtures as “dependency injection for tests”—just declare what you need in the function signature, and pytest wires it up. This aligns well with JS devs who like clean, reusable setup helpers.

***

### Parametrized Tests ↔ Data-Driven Tests

JS devs often use `test.each` or loops to run the same test against multiple inputs. Pytest has **parametrized tests**, which are extremely handy.

#### Python

```python
import pytest
from src.math_utils import add

@pytest.mark.parametrize(
    "a,b,expected",
    [
        (1, 2, 3),
        (0, 5, 5),
        (-1, 1, 0),
    ],
)
def test_add_various_cases(a, b, expected):
    assert add(a, b) == expected
```

#### JavaScript (Jest `test.each`)

```javascript
import { add } from "../src/mathUtils.js";

test.each([
  [1, 2, 3],
  [0, 5, 5],
  [-1, 1, 0],
])("add(%i, %i) = %i", (a, b, expected) => {
  expect(add(a, b)).toBe(expected);
});
```

Call out explicitly: “If you’re used to `test.each` in Jest, pytest’s `@pytest.mark.parametrize` is the Python version.”

***

### Mocking and Patching ↔ jest.mock

JS tools mock modules and functions with `jest.mock`, `vi.mock`, etc. Python’s equivalent in the standard library is `unittest.mock`, often used via `pytest`.

Basic idea:

```python
from unittest.mock import patch
from src.services import send_welcome_email

def test_send_welcome_email_calls_mailer():
    with patch("src.services.mailer") as mock_mailer:
        send_welcome_email("alice@mail.com")
        mock_mailer.send.assert_called_once()
```

You can map this to JS:

```javascript
import { sendWelcomeEmail } from "../src/services.js";
import * as mailer from "../src/mailer.js";

jest.mock("../src/mailer.js");

test("sendWelcomeEmail calls mailer", () => {
  sendWelcomeEmail("alice@mail.com");
  expect(mailer.send).toHaveBeenCalledTimes(1);
});
```

Mental model:

- `patch("module.path")` ≈ `jest.mock("module-path")`.  
- Mock objects expose assertions like `.assert_called_once()`, similar to Jest’s `.toHaveBeenCalledTimes(1)`.  

You don’t need to go super deep here, but giving one example reassures JS readers that their mocking habits carry over.

***

### Comparing Jest/Vitest vs pytest

A quick table helps cement the mapping:

| Concept                 | JavaScript (Jest/Vitest)            | Python (pytest)                       |
|-------------------------|-------------------------------------|---------------------------------------|
| Test file naming        | `*.test.js`, `*.spec.js`           | `test_*.py`                           |
| Test definition         | `test()` / `it()`                   | `def test_...()`                      |
| Assertions              | `expect(value).toBe(...)`          | `assert value == ...`                 |
| Setup/teardown          | `beforeEach`, `afterEach`          | Fixtures (`@pytest.fixture`)   |
| Parametrized tests      | `test.each(...)`                    | `@pytest.mark.parametrize`     |
| Mocking                 | `jest.mock`, `vi.mock`              | `unittest.mock.patch`                 |
| CLI                     | `jest`, `vitest`                    | `pytest`                              |

For your audience, emphasize that pytest is intentionally minimal at the syntax level but extremely powerful in behavior.

***

### Minimal Real-World Flow: Testing a FastAPI Endpoint

JS devs will immediately ask: “How do I test my web API in Python?” Show a tiny example that’s analogous to testing an Express/Hono route.

Assume a FastAPI app from Part 5:

```python
# src/fast_api_demo/main.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/hello")
def hello():
    return {"message": "Hello from Python"}
```

Test it with `httpx` and pytest:

```python
# tests/test_main.py
from fast_api_demo.main import app
from httpx import AsyncClient
import pytest

@pytest.mark.asyncio
async def test_hello_endpoint():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/hello")

    assert response.status_code == 200
    assert response.json() == {"message": "Hello from Python"}
```

Mapping to JS:

- `AsyncClient` ≈ `supertest`/`fetch`-based tests.  
- `@pytest.mark.asyncio` ≈ Jest’s `test("...", async () => { ... })`.  
- `assert response.status_code == 200` ≈ `expect(response.status).toBe(200)`.

