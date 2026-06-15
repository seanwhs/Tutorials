# Slide Outline: React State

## Slide 1 — React State

* Day 8: States
* Dynamic UI with React
* Why state is the heart of React applications

---

## Slide 2 — Learning Objectives

* Understand state
* Create state
* Read state
* Update state
* Connect state to events
* Build interactive components

---

## Slide 3 — What is State?

* Component's current condition
* Dynamic data
* Changes over time
* Triggers UI updates

Examples:

* Counter
* Login status
* Form fields
* Theme settings

---

## Slide 4 — State vs Static UI

Without State:

* Fixed interface

With State:

* Interactive interface
* Automatic updates

---

## Slide 5 — Declaring State

```jsx
state = {
  count: 0
}
```

* State object
* Initial values
* Component-owned data

---

## Slide 6 — Accessing State

```jsx
this.state.count
```

* Read state values
* Display state in JSX

---

## Slide 7 — Rendering State

```jsx
<h1>{this.state.count}</h1>
```

* React renders current value
* UI reflects state

---

## Slide 8 — Updating State

```jsx
this.setState({
  count: 1
})
```

* Proper update mechanism
* Triggers re-render

---

## Slide 9 — Never Mutate State

❌

```javascript
this.state.count = 1
```

✅

```javascript
this.setState({
  count: 1
})
```

---

## Slide 10 — Building a Counter

* Initial count
* Add button
* Display value
* Dynamic updates

Demo walkthrough

---

## Slide 11 — Increment Example

```jsx
this.setState({
  count: this.state.count + 1
})
```

Flow:

* Click
* Update
* Re-render

---

## Slide 12 — Decrement Example

```jsx
this.setState({
  count: this.state.count - 1
})
```

---

## Slide 13 — Refactoring Logic

```jsx
addOne()
minusOne()
```

Benefits:

* Cleaner JSX
* Better organization
* Reusability

---

## Slide 14 — Event Handling and State

```jsx
onClick
```

User Action → State Change → UI Update

---

## Slide 15 — State Flow Diagram

```text
User Action
    ↓
Event
    ↓
setState()
    ↓
State Updated
    ↓
Re-render
    ↓
UI Updated
```

---

## Slide 16 — Passing State to Children

Parent:

```jsx
<App />
```

Child:

```jsx
<Count />
```

Using Props:

* Data down
* Events up

---

## Slide 17 — State vs Props

Comparison table:

* Ownership
* Mutability
* Usage
* Lifecycle

---

## Slide 18 — State Data Types

```javascript
Number
String
Boolean
Array
Object
```

Examples for each

---

## Slide 19 — Real-World State Examples

* Shopping cart
* User profile
* Dashboard metrics
* Theme switcher
* API responses

---

## Slide 20 — Best Practices

* Keep state minimal
* Use setState
* Avoid duplication
* Extract methods
* Keep components focused

---

## Slide 21 — Common Mistakes

* Direct mutation
* Too much state
* Incorrect prop/state usage
* Duplicated state

---

## Slide 22 — Summary

* State makes React interactive
* State drives rendering
* Use `this.state`
* Update with `setState`
* State + Props = React application architecture

## References

* [30 Days of React – States Lesson](https://www.30daysofreact.com/30-days-of-react/64c591c568fee3b99bf644cd?utm_source=chatgpt.com)
* [30 Days of React Home](https://www.30daysofreact.com/?utm_source=chatgpt.com)
* Asabeneh Yetayeh React learning curriculum and examples.

[1]: https://www.30daysofreact.com/30-days-of-react/64c591c568fee3b99bf644cd?utm_source=chatgpt.com "30 Days Of React - Learn React in 30 Days"
