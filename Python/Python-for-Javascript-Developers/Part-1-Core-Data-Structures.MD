### Python for JavaScript Developers — Part 1: Core Data Structures

When transitioning from JavaScript to Python, the fastest way to feel productive is to map what you already know. Fortunately, Python’s core data structures closely mirror JavaScript concepts—just with different syntax and a few important behavioral differences.

This guide focuses on the four essential structures you’ll use daily: lists, tuples, dictionaries, and sets.

***

### The Big Picture

Here’s the mental model to anchor everything:

- List → JavaScript Array  
- Tuple → Immutable Array (no direct JS equivalent)  
- Dictionary → Object / Map  
- Set → Set  

***

### Lists ↔ Arrays

Lists are Python’s version of dynamic arrays. They are ordered, mutable, and allow duplicates.

#### Conceptual Model

```
Index:   0      1        2
       -------------------------
Value: |  1  | "hello" | 3.14 |
       -------------------------
```

#### Python

```python
items = [1, "hello", 3.14]

# Access
print(items[0])      # 1
print(items[-1])     # 3.14 (last item)

# Modify
items[1] = "world"

# Add
items.append(42)

# Insert (costly)
items.insert(1, "new")

# Remove
items.pop()          # removes last
items.remove("new")  # removes by value
```

#### JavaScript Equivalent

```javascript
const items = [1, "hello", 3.14];

console.log(items[0]);
items[1] = "world";

items.push(42);
items.splice(1, 0, "new");

items.pop();
```

#### Performance Insight

- Append: \(O(1)\)  
- Insert/delete (middle): \(O(n)\)  
- Search: \(O(n)\)

Use lists when order matters and data changes frequently.

***

### Tuples ↔ Immutable Arrays (Conceptual)

Tuples are like lists, but immutable—once created, they cannot change.

#### Conceptual Model

```
(10, 20, 30)

✅ Fixed structure
❌ Cannot modify after creation
```

#### Python

```python
point = (10, 20)

print(point[0])  # 10

# point[0] = 5  # ❌ TypeError
```

#### JavaScript Approximation

```javascript
const point = Object.freeze([10, 20]);
```

#### Why Tuples Matter

- Safer for fixed data (coordinates, configs)
- Slightly more memory efficient
- Can be used as dictionary keys (lists cannot)

#### Tuple Unpacking (Very Common)

```python
user = ("Alice", 30)

name, age = user
print(name, age)
```

***

### Dictionaries ↔ Object / Map

Dictionaries store key-value pairs and are optimized for fast lookups.

#### Conceptual Model

```
"name" → "Alice"
"age"  → 30

(hash table underneath)
```

#### Python

```python
user = {
    "name": "Alice",
    "age": 30
}

# Access
print(user["name"])

# Safe access
print(user.get("email", "Not found"))

# Add / update
user["email"] = "alice@mail.com"

# Delete
del user["age"]
```

#### JavaScript (Object)

```javascript
const user = {
  name: "Alice",
  age: 30
};

console.log(user.name);
user.email = "alice@mail.com";
```

#### JavaScript (Map)

```javascript
const user = new Map();

user.set("name", "Alice");
console.log(user.get("name"));
```

#### Performance Insight

- Lookup: \(O(1)\)  
- Insert/delete: \(O(1)\)

Use dictionaries when you need fast key-based access.

***

### Sets ↔ Set

Sets store unique values and are optimized for membership checks.

#### Conceptual Model

```
Input:  [1, 2, 2, 3]
Output: {1, 2, 3}

✅ Unique values only
```

#### Python

```python
nums = {1, 2, 2, 3}
print(nums)  # {1, 2, 3}

nums.add(4)
nums.remove(2)

print(3 in nums)  # True
```

#### JavaScript

```javascript
const nums = new Set([1, 2, 2, 3]);

nums.add(4);
nums.delete(2);

console.log(nums.has(3));
```

#### Set Operations (Python advantage)

```python
a = {1, 2, 3}
b = {3, 4, 5}

print(a | b)  # union
print(a & b)  # intersection
print(a - b)  # difference
```

***

### Performance Intuition

Understanding internal structure helps:

#### Lists / Tuples (Array-like)

```
[ A ][ B ][ C ][ D ]
   ↑ direct index
```

- Fast indexing: \(O(1)\)  
- Slow search: \(O(n)\)

#### Dicts / Sets (Hash Tables)

```
key → hash → bucket → value
```

- Fast lookup: \(O(1)\)  
- Higher memory usage

***

### Choosing the Right Structure

Use this quick decision flow:

- Need ordered, mutable collection → List  
- Need fixed, read-only data → Tuple  
- Need key → value mapping → Dictionary  
- Need uniqueness or fast lookup → Set  

***

### Real Example (Bridging Both Worlds)

#### Problem: Remove duplicates + count frequency

Python:

```python
from collections import Counter

data = ["a", "b", "a", "c"]

unique = set(data)
counts = Counter(data)

print(unique)   # {'a', 'b', 'c'}
print(counts)   # {'a': 2, 'b': 1, 'c': 1}
```

JavaScript:

```javascript
const data = ["a", "b", "a", "c"];

const unique = new Set(data);

const counts = {};
for (const item of data) {
  counts[item] = (counts[item] || 0) + 1;
}
```

***

This foundation is enough to start writing real Python while thinking in JavaScript terms. Once these feel natural, the next step is behavior—functions, classes, and async patterns.

***

