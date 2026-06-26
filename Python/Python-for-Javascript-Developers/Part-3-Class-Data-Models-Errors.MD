## Python for JavaScript Developers — Part 3: Classes, Data Models, and Errors

Once functions and modules feel familiar, the next big unlock is understanding how Python models “objects with state and behavior”. If you’re coming from modern JavaScript, think in terms of **classes, instances, and methods**, plus a Python-native way to define plain data containers.

***

### Classes ↔ JavaScript Classes

The mental model is almost identical: a class defines a blueprint, an instance is a concrete object, and methods operate on that instance.

#### Python

```python
class User:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def greet(self):
        return f"Hello, {self.name}!"

alice = User("Alice", 30)
print(alice.greet())
```

#### JavaScript

```javascript
class User {
  constructor(name, age) {
    this.name = name;
    this.age = age;
  }

  greet() {
    return `Hello, ${this.name}!`;
  }
}

const alice = new User("Alice", 30);
console.log(alice.greet());
```

Key mappings:

- `__init__` ≈ `constructor`  
- `self` ≈ `this` (explicitly passed in Python, implicit in JS)  
- Methods are just functions that take `self` as their first argument  

For JS devs, the big adjustment is seeing `self` as “this, but explicit”.

***

### Instance vs Class Attributes

Both languages distinguish between per‑instance state and shared state.

#### Python

```python
class Counter:
    # Class attribute (shared)
    total_counters = 0

    def __init__(self):
        self.value = 0      # Instance attribute
        Counter.total_counters += 1

    def increment(self):
        self.value += 1

c1 = Counter()
c2 = Counter()

c1.increment()
print(c1.value)           # 1
print(Counter.total_counters)  # 2
```

#### JavaScript

```javascript
class Counter {
  static totalCounters = 0;

  constructor() {
    this.value = 0;
    Counter.totalCounters += 1;
  }

  increment() {
    this.value += 1;
  }
}

const c1 = new Counter();
const c2 = new Counter();

c1.increment();
console.log(c1.value);          // 1
console.log(Counter.totalCounters); // 2
```

Mapping:

- Class attributes ≈ static fields  
- Instance attributes ≈ properties on `this`  

Calling this out explicitly helps JS devs avoid confusion when seeing attributes defined directly on the class body.

***

### Data Classes ↔ Plain Objects / DTOs

Python has a built‑in way to define “just data” classes with minimal boilerplate: `dataclasses.dataclass`. This feels a lot like the common JS pattern of “plain objects used as models”.

#### Python

```python
from dataclasses import dataclass

@dataclass
class UserProfile:
    name: str
    email: str
    is_active: bool = True

profile = UserProfile(name="Alice", email="alice@mail.com")
print(profile.name)
print(profile.is_active)
```

#### JavaScript Rough Equivalent

```javascript
function createUserProfile({ name, email, isActive = true }) {
  return { name, email, isActive };
}

const profile = createUserProfile({
  name: "Alice",
  email: "alice@mail.com"
});

console.log(profile.name);
console.log(profile.isActive);
```

Why this matters for JS devs:

- Data classes give you a “typed, structured object” without wiring up a full class manually.  
- They’re ideal for request/response models, config objects, and simple entities.

You can position them as “Python’s ergonomic way to define data‑shaped things” compared to JS’s plain objects.

***

### Error Handling: try/except ↔ try/catch

Error handling feels almost identical across both languages.

#### Python

```python
def parse_age(raw):
    try:
        return int(raw)
    except ValueError:
        return None

age = parse_age("not-a-number")
print(age)  # None
```

#### JavaScript

```javascript
function parseAge(raw) {
  try {
    return parseInt(raw, 10);
  } catch (err) {
    return null;
  }
}

const age = parseAge("not-a-number");
console.log(age); // null
```

Mapping:

- `try/except` ≈ `try/catch`  
- Python uses specific exception types (`ValueError`, `TypeError`, etc.)  
- You can catch broad exceptions, but catching specific ones is more idiomatic  

This is a good point to mention that many Python APIs signal failure with exceptions rather than returned error values, so `try/except` is common in real-world code.

***

### Raising Errors: fail fast

Just like `throw` in JS, Python uses `raise` to signal errors.

#### Python

```python
def require_positive(x):
    if x <= 0:
        raise ValueError("x must be positive")
    return x
```

#### JavaScript

```javascript
function requirePositive(x) {
  if (x <= 0) {
    throw new Error("x must be positive");
  }
  return x;
}
```

Encouraging JS devs to think in terms of “raise/throw early, catch at the right boundary” aligns nicely with how both ecosystems write robust code.

***

### Small Real-World Example: User Registry

Tie classes, dicts, and error handling together in a way that directly mirrors a JS mental model.

#### Python

```python
class UserRegistry:
    def __init__(self):
        self._users = {}  # id -> user dict

    def add_user(self, user_id, name):
        if user_id in self._users:
            raise ValueError(f"user_id {user_id} already exists")

        self._users[user_id] = {"id": user_id, "name": name}

    def get_user(self, user_id):
        try:
            return self._users[user_id]
        except KeyError:
            return None

registry = UserRegistry()
registry.add_user(1, "Alice")
registry.add_user(2, "Bob")

print(registry.get_user(1))   # {'id': 1, 'name': 'Alice'}
print(registry.get_user(99))  # None
```

#### JavaScript

```javascript
class UserRegistry {
  constructor() {
    this._users = {}; // id -> user object
  }

  addUser(userId, name) {
    if (this._users[userId]) {
      throw new Error(`userId ${userId} already exists`);
    }
    this._users[userId] = { id: userId, name };
  }

  getUser(userId) {
    return this._users[userId] ?? null;
  }
}

const registry = new UserRegistry();
registry.addUser(1, "Alice");
registry.addUser(2, "Bob");

console.log(registry.getUser(1));   // { id: 1, name: "Alice" }
console.log(registry.getUser(99));  // null
```

This example reinforces:

- Python dicts as backing stores for keyed data  
- Classes as “containers” for both state and behavior  
- Exceptions as a primary tool for guarding invariants  

***

### Where this positions the reader

By the end of Part 3, a JS developer should be comfortable with:

- Defining Python classes that feel like JS classes  
- Using data classes as structured, lightweight models  
- Handling errors using `try/except` and raising them with `raise`  
- Combining data structures, classes, and error handling in small, realistic components  

From here, natural follow‑ups for later parts include:

- Async and concurrency (`async def`, `await`, `asyncio`) vs JS promises  
- File I/O and working with external resources  
- Packaging and virtual environments (mapping to npm, node modules, and toolchains)
