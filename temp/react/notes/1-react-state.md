# Notes: React State (Day 8 – 30 Days of React)

State is one of the most important concepts in React because it allows components to store and manage data that changes over time. When state changes, React automatically re-renders the component so the UI stays synchronized with the underlying data. ([30daysofreact.com][1])

---

# 1. What is State?

A **state** represents the current condition of a component at a specific moment.

Examples of state in applications:

* Counter value (0, 1, 2, 3...)
* User logged in or logged out
* Light on or off
* Form input values
* Loading or completed status
* Shopping cart contents

React uses state to determine what should be displayed on the screen.

### Key Idea

> State is data that changes over time and causes React to re-render the component when updated. ([30daysofreact.com][1])

---

# 2. Why State Matters

Without state:

* UI remains static
* User interactions cannot update the interface

With state:

* Components become interactive
* Data changes trigger UI updates
* Applications become dynamic and reactive

---

# 3. Declaring State in Class Components

State can be declared inside a class component.

```jsx
class App extends React.Component {
  state = {
    count: 0
  }

  render() {
    return (
      <h1>{this.state.count}</h1>
    )
  }
}
```

### State Object

```javascript
{
  count: 0
}
```

Here:

* `count` is the state property
* `0` is the initial value

React renders the current value.

---

# 4. Accessing State

State is accessed using:

```jsx
this.state.propertyName
```

Example:

```jsx
const count = this.state.count
```

Then display it:

```jsx
<h1>{count}</h1>
```

---

# 5. Updating State

State should never be changed directly.

❌ Incorrect:

```javascript
this.state.count = 1
```

React will not properly track the update.

Instead use:

```javascript
this.setState()
```

✅ Correct:

```javascript
this.setState({
  count: 1
})
```

This tells React:

1. State changed
2. Re-render the component

([30daysofreact.com][1])

---

# 6. Simple Counter Example

```jsx
class App extends React.Component {
  state = {
    count: 0
  }

  render() {
    return (
      <div>
        <h1>{this.state.count}</h1>

        <button
          onClick={() =>
            this.setState({
              count: this.state.count + 1
            })
          }
        >
          Add One
        </button>
      </div>
    )
  }
}
```

### Flow

```text
Click Button
      ↓
setState()
      ↓
State Updated
      ↓
React Re-renders
      ↓
UI Updates
```

---

# 7. Multiple State Updates

Increasing count:

```jsx
this.setState({
  count: this.state.count + 1
})
```

Decreasing count:

```jsx
this.setState({
  count: this.state.count - 1
})
```

Result:

```text
0 → 1 → 2 → 3
3 → 2 → 1 → 0
```

([30daysofreact.com][1])

---

# 8. Extracting Logic into Methods

Instead of placing logic directly inside JSX:

```jsx
<button
  onClick={() =>
    this.setState({
      count: this.state.count + 1
    })
  }
>
```

Create methods:

```jsx
addOne = () => {
  this.setState({
    count: this.state.count + 1
  })
}

minusOne = () => {
  this.setState({
    count: this.state.count - 1
  })
}
```

Use them:

```jsx
<button onClick={this.addOne}>+1</button>
<button onClick={this.minusOne}>-1</button>
```

### Benefits

* Cleaner code
* Better readability
* Easier maintenance
* Easier testing

---

# 9. State and Events

State is commonly updated through events.

Examples:

```jsx
onClick
onChange
onSubmit
onMouseEnter
```

Example:

```jsx
<button onClick={this.addOne}>
  +1
</button>
```

The event triggers:

```javascript
this.setState()
```

which updates the UI.

---

# 10. Passing State Through Components

The example introduces a `Count` component:

```jsx
const Count = ({
  count,
  addOne,
  minusOne
}) => (
  <div>
    <h1>{count}</h1>

    <Button text="+1" onClick={addOne} />
    <Button text="-1" onClick={minusOne} />
  </div>
)
```

State remains in the parent component while child components receive:

* State values
* State update functions

through props. ([30daysofreact.com][1])

---

# 11. State vs Props

| State                | Props                                 |
| -------------------- | ------------------------------------- |
| Managed by component | Passed from parent                    |
| Mutable              | Read-only                             |
| Changes over time    | Usually static from child perspective |
| Causes re-render     | Causes re-render when changed         |
| Local to component   | Shared between components             |

### State

```jsx
this.state.count
```

### Props

```jsx
this.props.count
```

---

# 12. Real-World Uses of State

State is used for:

### Counters

```jsx
count
```

### Forms

```jsx
name
email
password
```

### Toggles

```jsx
isDarkMode
```

### Authentication

```jsx
isLoggedIn
```

### Loading Indicators

```jsx
loading
```

### API Data

```jsx
users
products
posts
```

---

# 13. Example Application State

The larger example contains:

```javascript
state = {
  count: 0,
  styles: {
    backgroundColor: '',
    color: ''
  }
}
```

This demonstrates that state can store:

* Numbers
* Strings
* Arrays
* Objects
* Booleans

React state can represent nearly any UI data. ([30daysofreact.com][1])

---

# 14. State Management Flow

```text
User Interaction
        ↓
Event Handler
        ↓
setState()
        ↓
State Updated
        ↓
React Re-renders
        ↓
Virtual DOM Updated
        ↓
Browser UI Updated
```

---

# 15. Best Practices

### Keep State Minimal

Store only necessary data.

### Never Mutate State Directly

Use:

```javascript
setState()
```

### Extract Logic into Methods

```javascript
addOne()
minusOne()
```

### Pass State Down via Props

```jsx
<Count count={count} />
```

### Keep Components Focused

Separate UI from business logic.

---

# Key Takeaways

* State stores dynamic data.
* State changes trigger re-renders.
* Class components use `this.state`.
* State updates use `this.setState()`.
* Never mutate state directly.
* Events often trigger state updates.
* State and props work together.
* State is the foundation of interactive React applications.
* Most React applications are built around managing and updating state efficiently. ([30daysofreact.com][1])

---

## References

* [30 Days of React – States Lesson](https://www.30daysofreact.com/30-days-of-react/64c591c568fee3b99bf644cd?utm_source=chatgpt.com)
* [30 Days of React Home](https://www.30daysofreact.com/?utm_source=chatgpt.com)
* Asabeneh Yetayeh React learning curriculum and examples.

[1]: https://www.30daysofreact.com/30-days-of-react/64c591c568fee3b99bf644cd?utm_source=chatgpt.com "30 Days Of React - Learn React in 30 Days"
