## Python for JavaScript Developers — Part 2: Functions, Modules, and Imports

Now that the core data structures feel familiar, the next step is understanding how Python organizes behavior and code. In JavaScript terms: this is the Python view of “functions + files + modules”.

In JS, you’re used to thinking in terms of:

- Functions, callbacks, and higher-order functions  
- Files that export/import things  
- Modules (ESM or CommonJS) as units of organization  

Python has direct analogs for all of these, just with different syntax and a few opinionated conventions.

***

### Functions ↔ JS Functions

At the core, Python functions behave like JavaScript functions: they take arguments, do work, and return values.

#### Python

```python
def greet(name):
    return f"Hello, {name}!"

message = greet("Alice")
print(message)
```

#### JavaScript

```javascript
function greet(name) {
  return `Hello, ${name}!`;
}

const message = greet("Alice");
console.log(message);
```

Key parallels:

- `def` in Python ≈ `function` in JS  
- Functions return values explicitly with `return`  
- You can pass functions around as values in both languages

***

### Positional vs Keyword Arguments

Python’s big ergonomics win is how it handles arguments—especially keyword arguments. This maps loosely to JS’s object parameter pattern.

#### Python

```python
def create_user(name, age, is_admin=False):
    return {
        "name": name,
        "age": age,
        "is_admin": is_admin
    }

user1 = create_user("Alice", 30)
user2 = create_user(name="Bob", age=25, is_admin=True)
```

#### JavaScript Equivalent

```javascript
function createUser({ name, age, isAdmin = false }) {
  return { name, age, isAdmin };
}

const user1 = createUser({ name: "Alice", age: 30 });
const user2 = createUser({ name: "Bob", age: 25, isAdmin: true });
```

Mental mapping:

- Python positional args ≈ plain ordered parameters in JS  
- Python keyword args ≈ passing an options object in JS  
- Default values behave similarly in both languages

Once JS devs see keyword arguments as “object-like calling syntax”, Python functions feel much more natural.

***

### *args and **kwargs ↔ Rest Parameters

Both languages support “variable numbers of arguments”.

#### Python

```python
def log_all(*args, **kwargs):
    print("args:", args)
    print("kwargs:", kwargs)

log_all(1, 2, 3, level="info", tag="demo")
```

#### JavaScript

```javascript
function logAll(...args) {
  console.log("args:", args);
}

logAll(1, 2, 3);
```

Mapping:

- `*args` ≈ `...args` (rest parameters) for positional arguments  
- `**kwargs` ≈ a “rest object” built from remaining properties  

For JS developers, framing `*args` / `**kwargs` as “rest parameters for positional + named arguments” helps the pattern click quickly.

***

### Modules and Imports ↔ Files and ES Modules

In JavaScript, every file is a module. Python is similar: each `.py` file is a module, and packages are folders with `__init__.py` (in traditional layouts).

#### Python

```python
# utils.py
def add(a, b):
    return a + b
```

```python
# main.py
from utils import add

result = add(2, 3)
print(result)
```

#### JavaScript (ES Modules)

```javascript
// utils.js
export function add(a, b) {
  return a + b;
}

// main.js
import { add } from "./utils.js";

const result = add(2, 3);
console.log(result);
```

Mental mapping:

- `from module import name` ≈ `import { name } from "./module.js"`  
- `import module` ≈ `import * as module from "./module.js"`  
- Python search path ≈ Node/ESM module resolution (but more convention-driven)

You can also note that top-level code executes when the module is imported, similar to how JS modules run once when first imported.

***

### Namespaces and `__name__ == "__main__"` ↔ “Run this file directly”

JS devs often use a dedicated entry file (`index.js`, `server.js`). Python has a convention to detect “run vs import”.

#### Python

```python
# main.py
def run():
    print("Running main")

if __name__ == "__main__":
    run()
```

This roughly matches “only run this when this is the entry-point script”, which JS developers usually handle with CLI tooling or explicit entry files.

You don’t need this immediately, but calling it out early prevents confusion when people see `if __name__ == "__main__":` in examples.

***

### First-Class Functions and Lambdas

Python, like JavaScript, treats functions as first-class citizens: you can pass them around, store them in data structures, and return them from other functions.

#### Python

```python
def square(x):
    return x * x

nums = [1, 2, 3]
squared = list(map(square, nums))
```

Or with a lambda (Python’s compact anonymous function syntax):

```python
nums = [1, 2, 3]
squared = [x * x for x in nums]
```

#### JavaScript

```javascript
const square = x => x * x;

const nums = [1, 2, 3];
const squared = nums.map(square);
```

Key points for JS devs:

- Python `lambda` is more limited than JS arrow functions (single expression)  
- Idiomatic Python often uses list comprehensions instead of `map`/`filter`  

That “comprehension” style is worth a dedicated section later, especially since it maps nicely to array transforms in JS.

***

### What we can achieve?

By this point, you can:

- Work with Python’s core data structures  
- Define and call functions with positional and keyword arguments  
- Organize code across multiple files/modules  
- Start recognizing Python’s idiomatic patterns (e.g., `if __name__ == "__main__"`)
