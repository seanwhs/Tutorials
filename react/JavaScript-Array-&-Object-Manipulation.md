# 🧠 JavaScript Array & Object Manipulation

# The Complete Beginner-Friendly Handbook

## A Deep Dive into Arrays, Objects, ES6+, Higher-Order Functions, Immutability, and Modern JavaScript Thinking

---

# 🌟 Introduction

If you continue learning JavaScript, you will eventually realize something important:

> Most JavaScript programming is actually:
>
> # 👉 manipulating arrays and objects

Whether you build:

* React apps
* Node.js APIs
* databases
* dashboards
* shopping carts
* todo apps
* admin systems
* games

you will constantly manipulate:

# 👉 arrays

and

# 👉 objects

This is one of the MOST important JavaScript skills.

---

# Why Beginners Struggle

Beginners often try to memorize syntax:

```js id="jlwm001"
map()
filter()
reduce()
spread syntax
```

…but don’t truly understand:

# 👉 WHAT is happening in memory

or:

# 👉 WHY modern JavaScript prefers immutable patterns

This tutorial explains EVERYTHING slowly and visually.

We will cover:

* arrays
* objects
* references
* mutation
* immutability
* higher-order functions
* ES6+
* declarative programming
* modern JavaScript mental models

---

# 📚 Table of Contents

---

# PART 1 — Arrays Fundamentals

1. What Arrays Are
2. Why Arrays Exist
3. Accessing Items
4. Updating Items
5. Adding Items
6. Removing Items
7. Array Length
8. Mutating Methods
9. References and Memory
10. Copying Arrays
11. Shallow Copy

---

# PART 2 — Modern Array Methods

12. map()
13. filter()
14. find()
15. some()
16. every()
17. reduce()
18. sort()
19. forEach()

---

# PART 3 — Objects Fundamentals

20. What Objects Are
21. Object Properties
22. Reading Properties
23. Updating Properties
24. Adding Properties
25. Deleting Properties
26. Nested Objects
27. References in Objects
28. Object Spread

---

# PART 4 — Modern JavaScript (ES6+)

29. ES6 and ES7
30. Arrow Functions
31. Destructuring
32. Spread Syntax
33. Computed Property Names
34. Optional Chaining
35. Nullish Coalescing

---

# PART 5 — Functional Programming & Immutability

36. Mutation vs Immutability
37. Declarative Programming
38. Higher-Order Functions
39. Pure Functions
40. Real-World Patterns

---

# PART 6 — Real Examples

41. Shopping Cart
42. Todo App
43. Form Handling
44. Updating Nested Data

---

# PART 1 — 📦 Arrays Fundamentals

---

# 1. 📦 What is an Array?

An array stores MULTIPLE values in order.

Example:

```js id="jlwm002"
const fruits = ["apple", "banana", "orange"];
```

Visual:

```text id="jlwm003"
Index:      0         1         2

         apple    banana    orange
```

---

# Why Arrays Exist

Imagine storing 100 student names.

Without arrays:

```js id="jlwm004"
const student1 = "John";
const student2 = "Sarah";
const student3 = "Alex";
```

This becomes impossible to manage.

Arrays solve this problem.

Arrays group related data together.

---

# Arrays Can Store Anything

---

# Numbers

```js id="jlwm005"
const numbers = [1, 2, 3];
```

---

# Strings

```js id="jlwm006"
const colors = ["red", "blue"];
```

---

# Booleans

```js id="jlwm007"
const flags = [true, false, true];
```

---

# Objects

```js id="jlwm008"
const users = [
  { name: "Sean" },
  { name: "Alex" }
];
```

---

# Mixed Types (Possible but usually avoided)

```js id="jlwm009"
const weird = [1, "hello", true];
```

---

# 2. 🔢 Array Indexes

Arrays use:

# 👉 Zero-based indexing

Meaning:

```text id="jlwm010"
First item = index 0
Second item = index 1
Third item = index 2
```

---

# Accessing Items

```js id="jlwm011"
const fruits = ["apple", "banana", "orange"];

console.log(fruits[0]);
```

Result:

```js id="jlwm012"
apple
```

---

# More Examples

```js id="jlwm013"
console.log(fruits[1]);
```

Result:

```js id="jlwm014"
banana
```

---

# Last Item

```js id="jlwm015"
console.log(fruits[fruits.length - 1]);
```

Result:

```js id="jlwm016"
orange
```

---

# Why `length - 1`?

Suppose:

```js id="jlwm017"
fruits.length
```

equals:

```js id="jlwm018"
3
```

Indexes:

```text id="jlwm019"
0
1
2
```

Last index is always:

```js id="jlwm020"
length - 1
```

---

# 3. ✏️ Updating Array Items

```js id="jlwm021"
const fruits = ["apple", "banana", "orange"];

fruits[1] = "grape";

console.log(fruits);
```

Result:

```js id="jlwm022"
["apple", "grape", "orange"]
```

---

# What Happened?

We replaced:

```text id="jlwm023"
banana
```

with:

```text id="jlwm024"
grape
```

at index:

```text id="jlwm025"
1
```

---

# 4. ➕ Adding Items to Arrays

---

# push()

Adds to END.

```js id="jlwm026"
const numbers = [1, 2, 3];

numbers.push(4);

console.log(numbers);
```

Result:

```js id="jlwm027"
[1, 2, 3, 4]
```

---

# Visual

Before:

```text id="jlwm028"
[1, 2, 3]
```

After:

```text id="jlwm029"
[1, 2, 3, 4]
```

---

# unshift()

Adds to FRONT.

```js id="jlwm030"
numbers.unshift(0);
```

Result:

```js id="jlwm031"
[0, 1, 2, 3, 4]
```

---

# 5. ➖ Removing Items

---

# pop()

Removes LAST item.

```js id="jlwm032"
numbers.pop();
```

---

# shift()

Removes FIRST item.

```js id="jlwm033"
numbers.shift();
```

---

# splice()

Can remove ANY position.

```js id="jlwm034"
const fruits = ["apple", "banana", "orange"];

fruits.splice(1, 1);

console.log(fruits);
```

Result:

```js id="jlwm035"
["apple", "orange"]
```

---

# Understanding splice()

```js id="jlwm036"
splice(startIndex, deleteCount)
```

---

# Example

```js id="jlwm037"
splice(1, 1)
```

means:

```text id="jlwm038"
Start at index 1
Remove 1 item
```

---

# splice() Can Also Insert

```js id="jlwm039"
const fruits = ["apple", "orange"];

fruits.splice(1, 0, "banana");

console.log(fruits);
```

Result:

```js id="jlwm040"
["apple", "banana", "orange"]
```

---

# Breaking It Down

```js id="jlwm041"
splice(1, 0, "banana")
```

means:

```text id="jlwm042"
Start at index 1
Remove 0 items
Insert "banana"
```

---

# 6. 📏 Array Length

```js id="jlwm043"
const colors = ["red", "blue", "green"];

console.log(colors.length);
```

Result:

```js id="jlwm044"
3
```

---

# Important

Length is:

# 👉 number of items

NOT:

```text id="jlwm045"
last index
```

---

# 7. ⚠️ Mutating Methods

These methods MUTATE original array:

| Method    | Mutates? |
| --------- | -------- |
| push()    | ✅        |
| pop()     | ✅        |
| shift()   | ✅        |
| unshift() | ✅        |
| splice()  | ✅        |
| sort()    | ✅        |

Mutation means:

# 👉 changing original array directly

---

# Why Mutation Matters

Mutation can cause:

* React bugs
* unexpected side effects
* difficult debugging
* shared state problems

---

# 8. 🧠 Understanding References

Arrays are:

# 👉 Reference Types

This is EXTREMELY important.

---

# Example

```js id="jlwm046"
const a = [1, 2, 3];

const b = a;
```

Visual:

```text id="jlwm047"
a ───┐
     └──> [1, 2, 3]
b ───┘
```

Both variables point to SAME array.

---

# Mutation Affects Both

```js id="jlwm048"
b.push(4);

console.log(a);
```

Result:

```js id="jlwm049"
[1, 2, 3, 4]
```

Why?

Because:

```text id="jlwm050"
a and b reference SAME array
```

---

# 9. 🆕 Copying Arrays

---

# Spread Syntax

```js id="jlwm051"
const copy = [...original];
```

---

# slice()

```js id="jlwm052"
const copy = original.slice();
```

---

# Array.from()

```js id="jlwm053"
const copy = Array.from(original);
```

All create NEW arrays.

---

# Example

```js id="jlwm054"
const a = [1, 2, 3];

const b = [...a];

b.push(4);

console.log(a);
console.log(b);
```

Result:

```js id="jlwm055"
[1, 2, 3]
[1, 2, 3, 4]
```

Now arrays are independent.

---

# 10. ⚠️ Shallow Copy

This is VERY important.

Spread syntax only copies FIRST level.

---

# Example

```js id="jlwm056"
const users = [
  { name: "Sean" }
];

const copy = [...users];
```

Visual:

```text id="jlwm057"
NEW array
BUT same object inside
```

---

# Dangerous Example

```js id="jlwm058"
copy[0].name = "Alex";

console.log(users);
```

Result:

```js id="jlwm059"
[{ name: "Alex" }]
```

Because inner object still shared.

---

# PART 2 — 🚀 Modern Array Methods

---

# 11. 🗺️ map()

One of the MOST IMPORTANT JavaScript methods.

---

# What map() Does

Transforms EVERY item.

---

# Example

```js id="jlwm060"
const numbers = [1, 2, 3];

const doubled = numbers.map(n => n * 2);

console.log(doubled);
```

Result:

```js id="jlwm061"
[2, 4, 6]
```

---

# Visualizing map()

```text id="jlwm062"
1 → 2
2 → 4
3 → 6
```

---

# Original Array Untouched

```js id="jlwm063"
console.log(numbers);
```

Result:

```js id="jlwm064"
[1, 2, 3]
```

---

# More map() Examples

---

# Convert to Strings

```js id="jlwm065"
const nums = [1, 2, 3];

const strings = nums.map(n => String(n));
```

Result:

```js id="jlwm066"
["1", "2", "3"]
```

---

# Extract Property

```js id="jlwm067"
const users = [
  { name: "Sean" },
  { name: "Alex" }
];

const names = users.map(user => user.name);
```

Result:

```js id="jlwm068"
["Sean", "Alex"]
```

---

# Add New Property

```js id="jlwm069"
const updated = users.map(user => ({
  ...user,
  active: true
}));
```

---

# 12. 🧹 filter()

Keeps matching items.

---

# Example

```js id="jlwm070"
const numbers = [1, 2, 3, 4];

const even = numbers.filter(n => n % 2 === 0);

console.log(even);
```

Result:

```js id="jlwm071"
[2, 4]
```

---

# Visual

```text id="jlwm072"
1 ❌
2 ✅
3 ❌
4 ✅
```

---

# More filter() Examples

---

# Remove Empty Strings

```js id="jlwm073"
const words = ["hello", "", "world"];

const cleaned = words.filter(word => word !== "");
```

---

# Filter Adults

```js id="jlwm074"
const people = [
  { name: "John", age: 15 },
  { name: "Sarah", age: 25 }
];

const adults = people.filter(person => person.age >= 18);
```

---

# 13. 🔍 find()

Returns FIRST matching item.

---

# Example

```js id="jlwm075"
const users = [
  { id: 1, name: "Sean" },
  { id: 2, name: "Alex" }
];

const user = users.find(u => u.id === 2);

console.log(user);
```

Result:

```js id="’wini076"
{ id: 2, name: "Alex" }
```

---

# Difference Between find() and filter()

---

# find()

Returns:

# 👉 ONE item

---

# filter()

Returns:

# 👉 ARRAY of items

---

# Example

```js id="’wini077"
const numbers = [1, 2, 3, 4];

numbers.find(n => n > 2);
```

Result:

```js id="’wini078"
3
```

---

```js id="’wini079"
numbers.filter(n => n > 2);
```

Result:

```js id="’wini080"
[3, 4]
```

---

# 14. ✅ some()

Checks if:

# 👉 AT LEAST ONE item matches

---

# Example

```js id="’wini081"
const numbers = [1, 2, 3];

const hasEven = numbers.some(n => n % 2 === 0);

console.log(hasEven);
```

Result:

```js id="’wini082"
true
```

---

# 15. ✅ every()

Checks if:

# 👉 ALL items match

---

# Example

```js id="’wini083"
const numbers = [1, 2, 3];

const allPositive = numbers.every(n => n > 0);

console.log(allPositive);
```

Result:

```js id="’wini084"
true
```

---

# 16. 🧮 reduce() — The Most Powerful Array Method

Beginners fear `reduce()`.

That is completely normal.

It is more abstract.

But once understood, it becomes extremely powerful.

---

# What reduce() Does

It reduces MANY values into ONE value.

---

# Example — Sum Numbers

```js id="’wini085"
const numbers = [1, 2, 3, 4];

const total = numbers.reduce(
  (accumulator, current) => accumulator + current,
  0
);

console.log(total);
```

Result:

```js id="’wini086"
10
```

---

# Understanding reduce() Step-by-Step

---

# Initial Value

```text id="’wini087"
accumulator = 0
```

---

# Step 1

```text id="’wini088"
0 + 1 = 1
```

---

# Step 2

```text id="’wini089"
1 + 2 = 3
```

---

# Step 3

```text id="’wini090"
3 + 3 = 6
```

---

# Step 4

```text id="’wini091"
6 + 4 = 10
```

---

# Final Result

```text id="’wini092"
10
```

---

# Real-World reduce() Example

Shopping cart total:

```js id="’wini093"
const cart = [
  { price: 5 },
  { price: 10 },
  { price: 20 }
];

const total = cart.reduce(
  (sum, item) => sum + item.price,
  0
);

console.log(total);
```

Result:

```js id="’wini094"
35
```

---

# Another reduce() Example

Count occurrences:

```js id="’wini095"
const fruits = ["apple", "banana", "apple"];

const count = fruits.reduce((acc, fruit) => {
  acc[fruit] = (acc[fruit] || 0) + 1;
  return acc;
}, {});
```

Result:

```js id="’wini096"
{
  apple: 2,
  banana: 1
}
```

---

# Understanding `(acc[fruit] || 0)`

Suppose:

```js id="’wini097"
acc["apple"]
```

does not exist yet.

It becomes:

```js id="’wini098"
undefined
```

So:

```js id="’wini099"
undefined || 0
```

returns:

```js id="’wini100"
0
```

Then:

```js id="’wini101"
0 + 1
```

becomes:

```js id="’wini102"
1
```

Very common JavaScript pattern.
