# Slide Outline

## Slide 1 — JavaScript Refresher for React

* Why JavaScript comes before React
* Modern JavaScript (ES6+) essentials
* Skills required for React development

---

## Slide 2 — React is JavaScript

* React is a JavaScript library
* React uses JavaScript syntax extensively
* Strong JS knowledge accelerates React learning

---

## Slide 3 — Variables and Constants

* var
* let
* const
* Best practices

Example:

```javascript
const name = "Sean";
```

---

## Slide 4 — JavaScript Data Types

* String
* Number
* Boolean
* Undefined
* Null
* Symbol
* BigInt

---

## Slide 5 — Functions

* Function declaration
* Function expression
* Reusability
* Return values

Example:

```javascript
function greet(name) {
  return `Hello ${name}`;
}
```

---

## Slide 6 — Arrow Functions

Traditional:

```javascript
function greet() {}
```

Modern:

```javascript
const greet = () => {};
```

Why React prefers arrow functions

---

## Slide 7 — Template Literals

Before:

```javascript
"Hello " + name
```

After:

```javascript
`Hello ${name}`
```

Benefits:

* Readability
* Dynamic values

---

## Slide 8 — Arrays

* Creating arrays
* Accessing elements
* Iteration

Example:

```javascript
["HTML", "CSS", "JavaScript"]
```

---

## Slide 9 — Array Methods

* map()
* filter()
* find()
* reduce()

React list rendering with map()

---

## Slide 10 — Objects

* Key-value pairs
* Nested objects
* Real-world data representation

Example:

```javascript
const user = {
  name: "Sean"
};
```

---

## Slide 11 — Destructuring

Before:

```javascript
user.name
```

After:

```javascript
const { name } = user;
```

Benefits:

* Cleaner code
* Common in React props

---

## Slide 12 — Spread and Rest Operators

Spread:

```javascript
{ ...user }
```

Rest:

```javascript
(...args)
```

React state update patterns

---

## Slide 13 — Conditional Logic

* if statements
* Ternary operators
* Short-circuit operators

Examples in JSX

---

## Slide 14 — JavaScript Modules

Export:

```javascript
export
```

Import:

```javascript
import
```

How React organizes code

---

## Slide 15 — Promises

* Asynchronous programming
* then()
* catch()

Example:

```javascript
fetch()
```

---

## Slide 16 — Async/Await

Benefits:

* Cleaner syntax
* Easier error handling

Example:

```javascript
async/await
```

---

## Slide 17 — JavaScript Features Used Daily in React

* Arrow Functions
* map()
* Destructuring
* Spread Operator
* Modules
* Async/Await

---

## Slide 18 — DOM vs React

Traditional JavaScript:

```javascript
document.getElementById()
```

React:

```jsx
<Component />
```

React's declarative approach

---

## Slide 19 — JavaScript Skills Checklist

✓ Variables
✓ Functions
✓ Arrays
✓ Objects
✓ Destructuring
✓ Spread Operator
✓ Modules
✓ Promises
✓ Async/Await

---

## Slide 20 — Key Takeaways

* React requires modern JavaScript knowledge.
* ES6+ features are heavily used.
* Master JavaScript first, React becomes easier.
* Arrays, objects, functions, and async code are essential foundations. ([jQuery Plugins][1])

[1]: https://jquery-plugins.net/30-days-of-react-guide-to-learn-react-in-30-days?utm_source=chatgpt.com "30 Days Of React – Guide to Learn React in 30 Days | jQuery Plugins"
