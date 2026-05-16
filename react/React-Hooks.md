# The Complete React 19 Hooks Masterclass

## Massive Beginner-Friendly Deep Dive Into Every React 19 Hook, Async Rendering, Mental Models, and Modern Patterns

## Beginner-Friendly Mental Models, Deep Explanations, and Real-World Examples

---

# Table of Contents

1. Introduction to Hooks
2. The Mental Model of React Rendering
3. Rules of Hooks
4. useState
5. useEffect
6. useContext
7. useRef
8. useMemo
9. useCallback
10. useReducer
11. useLayoutEffect
12. useImperativeHandle
13. useDebugValue
14. useId
15. useTransition
16. useDeferredValue
17. useSyncExternalStore
18. useInsertionEffect
19. useOptimistic
20. useActionState
21. use
22. Custom Hooks
23. Hook Composition Patterns
24. Common Mistakes and Anti-Patterns
25. Performance Mental Models
26. Building Real Applications with Hooks
27. Advanced React 19 Patterns
28. Hook Decision Matrix
29. Final Mental Models

---

# 1. Introduction to Hooks

## What Changed in React 19?

React 19 is not just a small feature release.

It represents a major philosophical shift toward:

* Async-first rendering
* Server-integrated UI
* Built-in form orchestration
* Optimistic user experiences
* Concurrent rendering by default
* Reduced boilerplate
* Smarter rendering pipelines

Historically, React developers manually coordinated:

* Loading states
* Error states
* Form submission states
* Optimistic UI
* Promise handling
* Context reading
* Rendering priority

React 19 increasingly absorbs those responsibilities into the framework itself.

This is extremely important.

Modern React is evolving from:

```txt
"React as a rendering library"
```

into:

```txt
"React as a UI orchestration runtime"
```

That is why hooks in React 19 feel dramatically more powerful.

---

## The Two Eras of React Hooks

### Classic Hooks Era

Focused mainly on:

* State
* Effects
* Memoization
* Refs
* Context

Examples:

* useState
* useEffect
* useMemo
* useRef

---

### React 19 Async Hooks Era

Focused on:

* Async orchestration
* Actions
* Optimistic rendering
* Suspense integration
* Concurrent prioritization
* Promise-driven rendering

Examples:

* useActionState
* useOptimistic
* use
* useTransition

---

## The New Core Concept: Actions

One of the biggest React 19 ideas is the concept of an Action.

An Action is typically:

```jsx
async function action(formData) {
  // async work
}
```

Then connected directly into forms:

```jsx
<form action={action}>
```

React automatically tracks:

* Pending states
* Promise lifecycle
* Errors
* UI synchronization

This eliminates huge amounts of manual state management.

---

## Historical React Form Complexity

Before React 19:

```jsx
const [loading, setLoading] = useState(false)
const [error, setError] = useState(null)
const [success, setSuccess] = useState(false)
```

Then:

```jsx
try {
  setLoading(true)
  await apiCall()
  setSuccess(true)
} catch (err) {
  setError(err)
} finally {
  setLoading(false)
}
```

React 19 increasingly replaces this with:

```jsx
useActionState()
```

which is significantly cleaner.

---

# 1. Introduction to Hooks

Before React Hooks existed, React applications were primarily written using class components.

Example:

```jsx
class Counter extends React.Component {
  state = {
    count: 0
  }

  increment = () => {
    this.setState({ count: this.state.count + 1 })
  }

  render() {
    return (
      <button onClick={this.increment}>
        Count: {this.state.count}
      </button>
    )
  }
}
```

This worked.

But large applications became difficult to manage because logic was scattered across lifecycle methods:

* componentDidMount
* componentDidUpdate
* componentWillUnmount
* constructors
* class fields
* binding methods

Hooks solved this problem.

Hooks allow function components to:

* Store state
* Run side effects
* Share reusable logic
* Access lifecycle behavior
* Coordinate asynchronous UI
* Manage performance

All without classes.

---

# The Core Philosophy of Hooks

Hooks are NOT just APIs.

Hooks are React's way of expressing:

> “How should this component behave over time?”

Every hook represents a specific type of behavior.

Examples:

| Hook          | Behavior                                   |
| ------------- | ------------------------------------------ |
| useState      | Remember values                            |
| useEffect     | Synchronize with outside world             |
| useMemo       | Cache expensive computations               |
| useRef        | Persist mutable values without rerenders   |
| useTransition | Mark updates as non-urgent                 |
| useOptimistic | Pretend success before server confirmation |

---

# 2. The Mental Model of React Rendering

Before learning hooks deeply, you must understand rendering.

This is the single most important concept.

---

# React Components Are Re-Executed Functions

This surprises beginners.

A React component is NOT an object living forever.

It is a function React repeatedly executes.

```jsx
function Greeting({ name }) {
  console.log("Component rendering")

  return <h1>Hello {name}</h1>
}
```

Every render:

* React calls the function again
* Variables are recreated
* Event handlers are recreated
* Closures are recreated

Hooks help React preserve data BETWEEN renders.

---

# Rendering vs Committing

React operates in phases.

## Phase 1: Render Phase

React calculates:

* What changed?
* What should the UI look like?

This phase:

* Must stay pure
* Must not mutate DOM
* Must not perform side effects

---

## Phase 2: Commit Phase

React applies changes to the DOM.

This is when:

* Effects run
* DOM updates happen
* Browser painting occurs

---

# Mental Model: React as a Spreadsheet

Think of React like Excel.

In Excel:

* Cells contain data
* Formulas depend on other cells
* When one value changes, dependent cells recompute

React works similarly:

* State changes
* Components rerender
* Derived values recompute
* UI updates automatically

Hooks define relationships between values.

---

# 3. Rules of Hooks

Hooks have strict rules.

These rules allow React to track hook order correctly.

---

# Rule #1 — Only Call Hooks at the Top Level

GOOD:

```jsx
function App() {
  const [count, setCount] = useState(0)

  return <div>{count}</div>
}
```

BAD:

```jsx
function App() {
  if (true) {
    useState(0)
  }
}
```

Why?

React identifies hooks by their call order.

Example:

```jsx
useState()
useEffect()
useMemo()
```

React internally tracks:

```txt
Hook #1
Hook #2
Hook #3
```

If order changes, React becomes confused.

---

# Rule #2 — Only Call Hooks from React Functions

Allowed:

* React components
* Custom hooks

Not allowed:

* Regular utility functions
* Event handlers
* Conditions

---

# Rule #3 — Custom Hooks Must Start with use

GOOD:

```jsx
function useFetchData() {}
```

BAD:

```jsx
function fetchDataHook() {}
```

The naming convention allows linting tools to verify hook usage.

---

# 4. useState

`useState` allows components to remember values.

---

# Basic Example

```jsx
import { useState } from 'react'

function Counter() {
  const [count, setCount] = useState(0)

  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  )
}
```

---

# Mental Model: Component Memory Slot

Imagine React storing state in invisible memory slots.

```txt
Component Render:

Slot 1 → count = 0
```

After update:

```txt
Slot 1 → count = 1
```

React preserves this between renders.

---

# State Updates Trigger Rerenders

This is critical.

```jsx
setCount(5)
```

does NOT immediately change the screen.

Instead:

1. React schedules an update
2. Component rerenders
3. UI recalculates
4. React updates DOM

---

# Functional Updates

Very important.

BAD:

```jsx
setCount(count + 1)
setCount(count + 1)
```

You might expect +2.

But React batches updates.

Correct:

```jsx
setCount(c => c + 1)
setCount(c => c + 1)
```

Now React processes sequentially.

---

# Lazy Initialization

Expensive initialization should only happen once.

BAD:

```jsx
const [data] = useState(expensiveFunction())
```

GOOD:

```jsx
const [data] = useState(() => expensiveFunction())
```

React calls initializer only during first render.

---

# Multiple State Variables

```jsx
const [name, setName] = useState('')
const [email, setEmail] = useState('')
const [age, setAge] = useState(0)
```

This is often better than:

```jsx
const [form, setForm] = useState({
  name: '',
  email: '',
  age: 0
})
```

Why?

Smaller independent state pieces reduce accidental complexity.

---

# Common Beginner Mistake

BAD:

```jsx
count = 5
```

Never mutate state directly.

React only rerenders when setter functions are used.

Correct:

```jsx
setCount(5)
```

---

# Real Example — Form Input

```jsx
function SignupForm() {
  const [email, setEmail] = useState('')

  return (
    <input
      value={email}
      onChange={(e) => setEmail(e.target.value)}
    />
  )
}
```

---

# 5. useEffect

`useEffect` synchronizes React with the outside world.

This is one of the hardest hooks for beginners.

---

# The Biggest Mental Shift

Beginners think:

> “useEffect runs after render.”

Technically true.

But the deeper truth is:

> “useEffect synchronizes external systems with React state.”

External systems include:

* APIs
* Timers
* DOM APIs
* Browser storage
* WebSockets
* Event listeners
* Analytics
* Third-party libraries

---

# Basic Example

```jsx
import { useEffect } from 'react'

function App() {
  useEffect(() => {
    console.log('Component mounted')
  }, [])

  return <div>Hello</div>
}
```

---

# Dependency Array Explained

```jsx
useEffect(() => {
  console.log(count)
}, [count])
```

This means:

> “Run this effect whenever count changes.”

---

# Three Dependency Modes

## No Dependency Array

```jsx
useEffect(() => {
  console.log('every render')
})
```

Runs after EVERY render.

---

## Empty Dependency Array

```jsx
useEffect(() => {
  console.log('once')
}, [])
```

Runs once after initial mount.

---

## Specific Dependencies

```jsx
useEffect(() => {
  console.log('count changed')
}, [count])
```

Runs when count changes.

---

# Cleanup Functions

Effects can return cleanup functions.

```jsx
useEffect(() => {
  const interval = setInterval(() => {
    console.log('tick')
  }, 1000)

  return () => {
    clearInterval(interval)
  }
}, [])
```

---

# Mental Model: Subscription Lifecycle

```txt
Mount:
  Subscribe

Update:
  Cleanup old subscription
  Subscribe again

Unmount:
  Cleanup final subscription
```

---

# Fetching Data Example

```jsx
function UserProfile({ userId }) {
  const [user, setUser] = useState(null)

  useEffect(() => {
    async function fetchUser() {
      const response = await fetch(`/api/users/${userId}`)
      const data = await response.json()

      setUser(data)
    }

    fetchUser()
  }, [userId])

  if (!user) return <p>Loading...</p>

  return <h1>{user.name}</h1>
}
```

---

# Common Infinite Loop Mistake

BAD:

```jsx
useEffect(() => {
  setCount(count + 1)
}, [count])
```

This causes:

```txt
count changes
→ effect runs
→ setCount
→ rerender
→ count changes
→ repeat forever
```

---

# You Might Not Need an Effect

One of React's most important lessons.

BAD:

```jsx
const [fullName, setFullName] = useState('')

useEffect(() => {
  setFullName(first + ' ' + last)
}, [first, last])
```

GOOD:

```jsx
const fullName = first + ' ' + last
```

Derived data should usually be computed during render.

---

# 6. useContext

`useContext` allows data sharing without prop drilling.

---

# The Problem: Prop Drilling

```txt
App
 └── Layout
      └── Sidebar
           └── Profile
                └── Avatar
```

Passing props through every layer becomes annoying.

---

# Creating Context

```jsx
import { createContext } from 'react'

const ThemeContext = createContext('light')
```

---

# Providing Context

```jsx
function App() {
  return (
    <ThemeContext.Provider value="dark">
      <Dashboard />
    </ThemeContext.Provider>
  )
}
```

---

# Consuming Context

```jsx
import { useContext } from 'react'

function Header() {
  const theme = useContext(ThemeContext)

  return <div>{theme}</div>
}
```

---

# Mental Model: Global Data Tunnel

Context creates a hidden tunnel through the component tree.

Instead of:

```txt
App → Layout → Sidebar → Profile → Avatar
```

Data flows directly:

```txt
App → Avatar
```

---

# Common Context Use Cases

* Authentication
* Theme
* Language
* User preferences
* Global app state

---

# Context Performance Warning

Every context change rerenders ALL consumers.

BAD:

```jsx
<AuthContext.Provider value={{ user, login, logout }}>
```

This object recreates every render.

Better:

```jsx
const value = useMemo(() => ({
  user,
  login,
  logout
}), [user])
```

---

# 7. useRef

`useRef` stores mutable values that do NOT trigger rerenders.

---

# Basic Example

```jsx
function App() {
  const inputRef = useRef(null)

  function focusInput() {
    inputRef.current.focus()
  }

  return (
    <>
      <input ref={inputRef} />
      <button onClick={focusInput}>Focus</button>
    </>
  )
}
```

---

# Mental Model: Secret Persistent Box

```txt
ref.current
```

is a box React preserves forever.

Changing it does NOT rerender.

---

# Ref vs State

| useState        | useRef              |
| --------------- | ------------------- |
| Causes rerender | Does not rerender   |
| For UI data     | For mutable storage |
| Reactive        | Non-reactive        |

---

# Tracking Previous Values

```jsx
function Counter() {
  const [count, setCount] = useState(0)
  const previous = useRef(0)

  useEffect(() => {
    previous.current = count
  }, [count])

  return (
    <div>
      Current: {count}
      Previous: {previous.current}
    </div>
  )
}
```

---

# Storing Timers

```jsx
const timerRef = useRef(null)
```

Useful because timer IDs don't belong in UI state.

---

# 8. useMemo

`useMemo` caches expensive calculations.

---

# Basic Example

```jsx
const expensiveValue = useMemo(() => {
  return heavyCalculation(data)
}, [data])
```

---

# Mental Model: Computation Cache

Without useMemo:

```txt
Render
→ recalculate everything
```

With useMemo:

```txt
Dependencies unchanged?
→ reuse cached value
```

---

# Example — Filtering Large Lists

```jsx
function Products({ products, search }) {
  const filtered = useMemo(() => {
    return products.filter(product =>
      product.name.includes(search)
    )
  }, [products, search])

  return (
    <ul>
      {filtered.map(product => (
        <li key={product.id}>{product.name}</li>
      ))}
    </ul>
  )
}
```

---

# Important Warning

`useMemo` is a performance optimization.

Do NOT use it everywhere.

Bad:

```jsx
const doubled = useMemo(() => count * 2, [count])
```

This calculation is trivial.

Memoization itself has overhead.

---

# Referential Equality

One major reason to useMemo:

```jsx
const config = useMemo(() => ({
  theme,
  locale
}), [theme, locale])
```

Without useMemo, object identity changes every render.

---

# 9. useCallback

`useCallback` memoizes functions.

---

# Basic Example

```jsx
const handleClick = useCallback(() => {
  console.log('clicked')
}, [])
```

---

# Why Functions Matter

Functions are recreated every render.

```jsx
function App() {
  const fn = () => {}
}
```

Every render:

```txt
new function instance
```

---

# Common Use Case — React.memo

```jsx
const Child = React.memo(function Child({ onClick }) {
  return <button onClick={onClick}>Click</button>
})
```

Without useCallback:

```jsx
<Child onClick={() => doSomething()} />
```

Child rerenders every time.

With useCallback:

```jsx
const handleClick = useCallback(() => {
  doSomething()
}, [])
```

Now function identity remains stable.

---

# useCallback vs useMemo

```jsx
useMemo(() => value)
```

Caches VALUES.

```jsx
useCallback(() => fn)
```

Caches FUNCTIONS.

Internally:

```jsx
useCallback(fn, deps)
```

is basically:

```jsx
useMemo(() => fn, deps)
```

---

# 10. useReducer

`useReducer` manages complex state logic.

---

# Mental Model: State Machine

Instead of directly setting state:

```jsx
setCount(count + 1)
```

You dispatch actions:

```jsx
dispatch({ type: 'increment' })
```

Reducer decides transitions.

---

# Basic Example

```jsx
function reducer(state, action) {
  switch (action.type) {
    case 'increment':
      return { count: state.count + 1 }

    case 'decrement':
      return { count: state.count - 1 }

    default:
      return state
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, {
    count: 0
  })

  return (
    <>
      <button onClick={() => dispatch({ type: 'decrement' })}>
        -
      </button>

      <span>{state.count}</span>

      <button onClick={() => dispatch({ type: 'increment' })}>
        +
      </button>
    </>
  )
}
```

---

# Why useReducer Exists

Great for:

* Complex forms
* State transitions
* Multiple related updates
* Predictable logic
* Reducer architecture

---

# Reducer Benefits

## Centralized Logic

All state changes live in one place.

---

## Predictability

Actions describe WHAT happened.

Reducers decide HOW state changes.

---

## Easier Debugging

```txt
increment
add_todo
delete_todo
submit_form
```

Actions become an event history.

---

# Real Example — Todo App

```jsx
function todoReducer(state, action) {
  switch (action.type) {
    case 'add':
      return [
        ...state,
        {
          id: Date.now(),
          text: action.text
        }
      ]

    case 'remove':
      return state.filter(todo => todo.id !== action.id)

    default:
      return state
  }
}
```

---

# 11. useLayoutEffect

`useLayoutEffect` runs synchronously BEFORE browser painting.

---

# Difference Between useEffect and useLayoutEffect

## useEffect

```txt
Render
→ Paint screen
→ Run effect
```

## useLayoutEffect

```txt
Render
→ Run effect
→ Paint screen
```

---

# Use Case — Measuring DOM

```jsx
function Tooltip() {
  const ref = useRef(null)

  useLayoutEffect(() => {
    const rect = ref.current.getBoundingClientRect()

    console.log(rect.height)
  }, [])

  return <div ref={ref}>Tooltip</div>
}
```

---

# Why Not Always Use It?

Because it blocks painting.

Too many layout effects can hurt performance.

Prefer useEffect unless you specifically need synchronous DOM measurement.

---

# 12. useImperativeHandle

This hook customizes what parent refs can access.

---

# Basic Example

```jsx
import {
  forwardRef,
  useImperativeHandle,
  useRef
} from 'react'

const Input = forwardRef(function Input(props, ref) {
  const inputRef = useRef()

  useImperativeHandle(ref, () => ({
    focus() {
      inputRef.current.focus()
    }
  }))

  return <input ref={inputRef} />
})
```

Parent:

```jsx
const ref = useRef()

ref.current.focus()
```

---

# Mental Model: Controlled Public API

Instead of exposing entire DOM node:

```txt
Expose only approved methods
```

Like:

* focus
* scrollToTop
* clear

---

# 13. useDebugValue

Used mainly inside custom hooks.

Helps React DevTools display useful labels.

---

# Example

```jsx
function useOnlineStatus() {
  const [online, setOnline] = useState(true)

  useDebugValue(online ? 'Online' : 'Offline')

  return online
}
```

---

# 14. useId

Generates stable unique IDs.

---

# Example

```jsx
function LoginForm() {
  const id = useId()

  return (
    <>
      <label htmlFor={id}>Email</label>
      <input id={id} />
    </>
  )
}
```

---

# Why useId Exists

Server rendering and hydration can create ID mismatches.

`useId` guarantees consistency.

---

# 15. useTransition

One of the most important concurrent React hooks.

---

# The Problem

Some updates are urgent.

Others are expensive.

Typing should feel instant.

Huge filtering operations can wait slightly.

---

# Basic Example

```jsx
const [isPending, startTransition] = useTransition()
```

---

# Example — Search UI

```jsx
function Search() {
  const [input, setInput] = useState('')
  const [query, setQuery] = useState('')

  const [isPending, startTransition] = useTransition()

  function handleChange(e) {
    const value = e.target.value

    setInput(value)

    startTransition(() => {
      setQuery(value)
    })
  }

  return (
    <>
      <input value={input} onChange={handleChange} />

      {isPending && <p>Loading...</p>}

      <SearchResults query={query} />
    </>
  )
}
```

---

# Mental Model: Priority Lanes

React internally prioritizes updates.

Urgent:

* Typing
* Clicking
* Animations

Non-urgent:

* Heavy filtering
* Big rerenders
* Expensive calculations

Transitions mark updates as lower priority.

---

# 16. useDeferredValue

Defers updating a value.

---

# Example

```jsx
const deferredSearch = useDeferredValue(search)
```

---

# Mental Model

Imagine React saying:

> “Keep showing the old value temporarily while new work finishes.”

---

# Example — Large Search Results

```jsx
function App() {
  const [search, setSearch] = useState('')

  const deferredSearch = useDeferredValue(search)

  return (
    <>
      <input
        value={search}
        onChange={(e) => setSearch(e.target.value)}
      />

      <BigList search={deferredSearch} />
    </>
  )
}
```

Typing stays responsive.

---

# useDeferredValue vs useTransition

| useTransition        | useDeferredValue  |
| -------------------- | ----------------- |
| Defers state updates | Defers values     |
| More control         | Simpler           |
| Manual transition    | Automatic lagging |

---

# 17. useSyncExternalStore

Used for subscribing to external stores.

Examples:

* Redux
* Zustand
* Browser APIs
* External caches

---

# Example

```jsx
const state = useSyncExternalStore(
  store.subscribe,
  store.getSnapshot
)
```

---

# Why It Exists

Concurrent rendering introduced consistency challenges.

React needed a standard way to safely read external stores.

---

# Mental Model

```txt
React asks:

“What is the latest snapshot?”
```

Store responds consistently.

---

# 18. useInsertionEffect

Very specialized hook.

Mostly for CSS-in-JS libraries.

Runs before layout effects.

---

# Why It Exists

Libraries like Emotion or Styled Components need to inject styles before layout calculations.

---

# You Probably Won't Use This Directly

Most application developers never need it.

---

# 19. useOptimistic

One of React 19's most exciting hooks.

Allows optimistic UI updates.

---

# What is Optimistic UI?

Instead of waiting for server confirmation:

```txt
User clicks Like
→ UI instantly updates
→ Server request happens
→ Rollback if failed
```

---

# Example

```jsx
const [optimisticMessages, addOptimisticMessage] = useOptimistic(
  messages,
  (state, newMessage) => [
    ...state,
    {
      text: newMessage,
      sending: true
    }
  ]
)
```

---

# Full Chat Example

```jsx
function Chat({ messages, sendMessage }) {
  const [optimisticMessages, addOptimisticMessage] = useOptimistic(
    messages,
    (state, text) => [
      ...state,
      {
        id: Math.random(),
        text,
        sending: true
      }
    ]
  )

  async function formAction(formData) {
    const text = formData.get('message')

    addOptimisticMessage(text)

    await sendMessage(text)
  }

  return (
    <>
      {optimisticMessages.map(message => (
        <div key={message.id}>
          {message.text}
          {message.sending && ' Sending...'}
        </div>
      ))}

      <form action={formAction}>
        <input name="message" />
      </form>
    </>
  )
}
```

---

# Mental Model: Pretend Success

React temporarily pretends the operation succeeded.

If server fails:

```txt
Rollback to real state
```

---

# 20. useActionState

One of the most important React 19 hooks.

This hook deeply integrates forms, async actions, pending states, and server coordination.

---

# Mental Model: A Built-In Form Workflow Engine

Imagine hiring a small assistant whose only job is:

* Track submission state
* Handle loading indicators
* Store result state
* Coordinate async form execution
* Trigger rerenders automatically

That assistant is `useActionState`.

---

# Why React Created This Hook

Traditional React forms often required:

```jsx
const [loading, setLoading] = useState(false)
const [error, setError] = useState(null)
const [success, setSuccess] = useState(false)
```

Plus:

* try/catch blocks
* duplicate pending logic
* repetitive state handling
* manual synchronization

React 19 centralizes this workflow.

---

# Basic Example

```jsx
const [state, formAction, pending] = useActionState(
  async (previousState, formData) => {
    const email = formData.get('email')

    await register(email)

    return {
      success: true
    }
  },
  {
    success: false
  }
)
```

---

# Understanding the Three Returned Values

```jsx
const [state, formAction, pending]
```

## state

Contains:

* success data
* validation errors
* API responses
* derived action state

---

## formAction

The function attached directly to:

```jsx
<form action={formAction}>
```

React wires this automatically.

---

## pending

Automatically becomes:

```txt
true during async execution
false when complete
```

No manual loading state required.

---

# Complete Profile Form Example

```jsx
import { useActionState } from 'react'

async function updateProfile(prevState, formData) {
  try {
    const username = formData.get('username')

    await new Promise(resolve =>
      setTimeout(resolve, 1500)
    )

    if (!username) {
      return {
        error: 'Username required'
      }
    }

    return {
      success: true,
      message: `Updated to ${username}`
    }
  } catch {
    return {
      error: 'Network error'
    }
  }
}

function ProfileForm() {
  const [state, formAction, pending] = useActionState(
    updateProfile,
    {
      success: false,
      error: null
    }
  )

  return (
    <form action={formAction}>
      <input name="username" />

      <button disabled={pending}>
        {pending ? 'Saving...' : 'Save'}
      </button>

      {state.error && <p>{state.error}</p>}
      {state.success && <p>Success!</p>}
    </form>
  )
}
```

---

# Why This Is Powerful

React now understands:

```txt
"This form is performing async work"
```

instead of developers manually coordinating every state variable.

---

# Relationship to Server Actions

`useActionState` becomes even more powerful in frameworks like:

* Next.js App Router
* Remix
* React Server Components environments

because actions may execute directly on servers.

---

# Common Pattern

```txt
User submits form
→ pending automatically tracked
→ async work runs
→ state updates
→ UI rerenders
```

Minimal boilerplate.

---

# Common Beginner Mistake

Trying to combine excessive manual loading state:

BAD:

```jsx
const [loading, setLoading] = useState(false)
```

while already using:

```jsx
useActionState()
```

Usually unnecessary.

---

# Relationship to useFormStatus

Think of them as teammates.

```txt
useActionState
→ manages form workflow

useFormStatus
→ lets deeply nested children observe form status
```

---

# 20.5 useFormStatus

This hook allows nested form components to inspect the status of a parent form.

---

# Mental Model: A Status Spy Camera

Imagine a deeply nested button component secretly peeking upward at its parent form.

It can see:

* pending state
* form data
* method
* action info

without prop drilling.

---

# Why This Hook Exists

Historically:

```txt
Parent form
→ passes loading prop
→ intermediate layouts
→ child button
```

This becomes painful in large applications.

`useFormStatus` removes that plumbing.

---

# Example

```jsx
import { useFormStatus } from 'react-dom'

function SubmitButton() {
  const { pending } = useFormStatus()

  return (
    <button disabled={pending}>
      {pending ? 'Submitting...' : 'Submit'}
    </button>
  )
}
```

---

# Important Rule

This ONLY works inside the form tree.

GOOD:

```jsx
<form>
  <SubmitButton />
</form>
```

BAD:

```jsx
function SameComponent() {
  const status = useFormStatus()

  return <form></form>
}
```

The hook cannot inspect a form defined in the same component level.

---

# Advanced Example

```jsx
function UploadButton() {
  const { pending, data } = useFormStatus()

  return (
    <button disabled={pending}>
      {pending
        ? `Uploading ${data?.get('file')}`
        : 'Upload'}
    </button>
  )
}
```

---

# Why React 19 Forms Feel Better

These hooks collectively eliminate huge amounts of:

* prop drilling
* duplicated loading state
* repetitive async orchestration
* brittle form architecture

---

# 20. useActionState

React 19 hook for managing async actions and forms.

---

# Basic Example

```jsx
const [state, formAction, pending] = useActionState(
  async (previousState, formData) => {
    const email = formData.get('email')

    await saveEmail(email)

    return {
      success: true
    }
  },
  {
    success: false
  }
)
```

---

# Using in a Form

```jsx
function SignupForm() {
  const [state, action, pending] = useActionState(
    async (_, formData) => {
      const email = formData.get('email')

      await register(email)

      return { success: true }
    },
    { success: false }
  )

  return (
    <form action={action}>
      <input name="email" />

      <button disabled={pending}>
        {pending ? 'Submitting...' : 'Submit'}
      </button>

      {state.success && <p>Success!</p>}
    </form>
  )
}
```

---

# Mental Model

React helps coordinate:

* Form state
* Pending state
* Async results
* Server actions

All together.

---

# 21. use

The `use` hook is one of the most revolutionary React APIs ever introduced.

It fundamentally changes how React handles async rendering.

---

# Why use() Is So Important

Historically React had strict rules:

```txt
Hooks cannot be conditional
Hooks cannot run in loops
Hooks cannot unwrap promises directly
```

`use()` changes this.

---

# Mental Model: Runtime Value Extraction

`use()` acts like a runtime portal.

It can dynamically extract values from:

* Promises
* Contexts
* Async resources

while rendering.

---

# The Most Important Difference

Unlike traditional hooks:

```jsx
if (condition) {
  const value = use(resource)
}
```

is VALID.

This is historically groundbreaking for React.

---

# Promise Example

```jsx
function ProductPage({ productPromise }) {
  const product = use(productPromise)

  return <h1>{product.name}</h1>
}
```

---

# What React Does Internally

If promise is unresolved:

```txt
Pause rendering
→ Suspend component
→ Show Suspense fallback
→ Resume when resolved
```

This is dramatically cleaner than manual loading state management.

---

# Suspense Integration

```jsx
<Suspense fallback={<p>Loading...</p>}>
  <ProductPage productPromise={promise} />
</Suspense>
```

---

# Traditional Fetching Mental Model

Old React:

```txt
Render
→ useEffect
→ fetch
→ loading state
→ rerender
```

Modern React 19:

```txt
Start async resource
→ suspend rendering
→ resume when ready
```

Much more declarative.

---

# Conditional Context Example

```jsx
const ThemeContext = createContext('light')

function Settings({ enabled }) {
  if (!enabled) {
    return null
  }

  const theme = use(ThemeContext)

  return <div>{theme}</div>
}
```

Historically impossible with traditional hooks.

---

# use() vs useContext()

Traditional:

```jsx
useContext(ThemeContext)
```

Modern alternative:

```jsx
use(ThemeContext)
```

The newer model is more flexible.

---

# Important Mental Shift

React is increasingly moving toward:

```txt
Render can wait for data
```

instead of:

```txt
Render first
Fetch later
```

This is a major architectural evolution.

---

# Server Components + use()

`use()` becomes especially powerful with:

* React Server Components
* Streaming SSR
* Next.js App Router
* Suspense-driven architectures

---

# Common Beginner Confusion

`use()` does NOT replace all hooks.

It specifically excels at:

* Promise unwrapping
* Context reading
* Suspense integration
* Async rendering coordination

---

# 21. use

The `use` hook is one of React 19's most revolutionary additions.

---

# What Does use Do?

It unwraps:

* Promises
* Contexts
* Async resources

---

# Promise Example

```jsx
function ProductPage({ productPromise }) {
  const product = use(productPromise)

  return <h1>{product.name}</h1>
}
```

---

# Mental Model

Instead of:

```txt
Loading state management manually
```

React suspends rendering automatically until promise resolves.

---

# Suspense Integration

```jsx
<Suspense fallback={<p>Loading...</p>}>
  <ProductPage productPromise={promise} />
</Suspense>
```

---

# Why This Matters

Traditional fetching:

```txt
Render
→ useEffect
→ fetch
→ loading state
→ rerender
```

React 19 async rendering:

```txt
Start fetching
→ suspend rendering
→ resume when ready
```

Much cleaner mental model.

---

# Context with use

```jsx
const theme = use(ThemeContext)
```

Alternative to:

```jsx
useContext(ThemeContext)
```

---

# 22. Custom Hooks

Custom hooks allow reusable logic.

This is where hooks become truly powerful.

---

# Example — Online Status Hook

```jsx
function useOnlineStatus() {
  const [online, setOnline] = useState(navigator.onLine)

  useEffect(() => {
    function handleOnline() {
      setOnline(true)
    }

    function handleOffline() {
      setOnline(false)
    }

    window.addEventListener('online', handleOnline)
    window.addEventListener('offline', handleOffline)

    return () => {
      window.removeEventListener('online', handleOnline)
      window.removeEventListener('offline', handleOffline)
    }
  }, [])

  return online
}
```

Usage:

```jsx
function Status() {
  const online = useOnlineStatus()

  return <p>{online ? 'Online' : 'Offline'}</p>
}
```

---

# Mental Model: Logic Extraction

Custom hooks are NOT special state containers.

Each component calling a hook gets independent state.

---

# Example — useLocalStorage

```jsx
function useLocalStorage(key, initialValue) {
  const [value, setValue] = useState(() => {
    const stored = localStorage.getItem(key)

    return stored ? JSON.parse(stored) : initialValue
  })

  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value))
  }, [key, value])

  return [value, setValue]
}
```

---

# 23. Hook Composition Patterns

Hooks compose beautifully.

---

# Combining Hooks

```jsx
function SearchApp() {
  const [query, setQuery] = useState('')

  const deferredQuery = useDeferredValue(query)

  const filtered = useMemo(() => {
    return expensiveSearch(deferredQuery)
  }, [deferredQuery])

  return (
    <>
      <SearchInput onChange={setQuery} />
      <Results items={filtered} />
    </>
  )
}
```

---

# Layered Responsibilities

Each hook solves ONE problem.

```txt
useState
→ stores data

useEffect
→ syncs side effects

useMemo
→ optimizes calculations
```

Hooks work best when responsibilities remain clear.

---

# 24. Common Mistakes and Anti-Patterns

---

# Mistake #1 — Using Effects for Everything

BAD:

```jsx
useEffect(() => {
  setFiltered(items.filter(i => i.active))
}, [items])
```

GOOD:

```jsx
const filtered = items.filter(i => i.active)
```

---

# Mistake #2 — Missing Dependencies

BAD:

```jsx
useEffect(() => {
  console.log(user)
}, [])
```

This creates stale closures.

---

# Mistake #3 — Overusing useMemo

Memoization is not free.

Don't optimize prematurely.

---

# Mistake #4 — Giant Context Objects

Large contexts cause massive rerenders.

Split contexts by responsibility.

---

# Mistake #5 — Mutating State

BAD:

```jsx
state.items.push(newItem)
```

React expects immutable updates.

GOOD:

```jsx
setItems([...items, newItem])
```

---

# 25. Performance Mental Models

---

# React is Usually Fast Enough

Beginners over-optimize.

Most apps don't need aggressive memoization.

---

# Expensive Things in React

Usually:

* Huge rerenders
* Massive lists
* Expensive calculations
* DOM-heavy updates
* Repeated object recreation

NOT:

* Small functions
* Tiny calculations
* Normal renders

---

# Measure Before Optimizing

Use:

* React DevTools Profiler
* Browser Performance tab
* Flame charts

---

# 26. Building Real Applications with Hooks

---

# Example — Auth Provider

```jsx
const AuthContext = createContext(null)

function AuthProvider({ children }) {
  const [user, setUser] = useState(null)

  async function login(credentials) {
    const response = await api.login(credentials)

    setUser(response.user)
  }

  function logout() {
    setUser(null)
  }

  return (
    <AuthContext.Provider
      value={{ user, login, logout }}
    >
      {children}
    </AuthContext.Provider>
  )
}
```

---

# Example — Debounced Search Hook

```jsx
function useDebounce(value, delay) {
  const [debounced, setDebounced] = useState(value)

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebounced(value)
    }, delay)

    return () => clearTimeout(timer)
  }, [value, delay])

  return debounced
}
```

---

# Example — Infinite Scroll

```jsx
function useInfiniteScroll(callback) {
  useEffect(() => {
    function handleScroll() {
      const nearBottom =
        window.innerHeight + window.scrollY >=
        document.body.offsetHeight - 500

      if (nearBottom) {
        callback()
      }
    }

    window.addEventListener('scroll', handleScroll)

    return () => {
      window.removeEventListener('scroll', handleScroll)
    }
  }, [callback])
}
```

---

# 27. Advanced React 19 Patterns

---

# React 19's Bigger Architectural Shift

React 19 is gradually merging several concepts together:

```txt
Rendering
Async orchestration
Server communication
Form handling
Concurrency
Streaming
```

Historically developers manually glued these systems together.

React increasingly coordinates them natively.

---

# The New Async React Stack

Modern React applications increasingly combine:

* Suspense
* use
* useActionState
* useOptimistic
* useTransition
* Server Actions
* Streaming SSR

Together.

---

# The Future Rendering Pipeline

Traditional frontend model:

```txt
Browser loads JS
→ app mounts
→ fetch data
→ loading states
→ rerender
```

Modern React model:

```txt
Server streams UI
→ promises suspend rendering
→ React coordinates async boundaries
→ optimistic updates happen immediately
→ transitions prioritize important work
```

This creates dramatically smoother applications.

---

# Async Rendering Mental Model

React 19 increasingly treats rendering like a scheduler.

Not:

```txt
Render everything immediately
```

Instead:

```txt
Urgent work first
Background work later
Pause when necessary
Resume intelligently
```

---

# Three Major React 19 Themes

## 1. Actions

Hooks:

* useActionState
* useFormStatus

React now deeply understands form submissions.

---

## 2. Optimistic Interfaces

Hooks:

* useOptimistic
* useTransition

React now helps applications feel instant.

---

## 3. Async Rendering

Hooks:

* use
* Suspense
* useDeferredValue

React now coordinates asynchronous rendering directly.

---

# React Compiler and Memoization

A very important ecosystem development.

Historically developers manually optimized:

* useMemo
* useCallback
* React.memo

Future React Compiler pipelines increasingly automate portions of these optimizations.

However:

Understanding these hooks remains critically important because:

* many applications won't use compiler pipelines immediately
* dependency modeling still matters
* architectural understanding remains essential
* performance debugging still requires mental models

---

# Modern React Architecture Direction

The React ecosystem is moving toward:

```txt
Less manual state orchestration
More declarative async coordination
```

This is why React 19 hooks feel more framework-like than earlier React versions.

---

# Full Mental Model of Modern React

React today is effectively:

```txt
A prioritized async UI runtime
```

not merely:

```txt
A component library
```

That shift explains:

* concurrent rendering
* transitions
* Suspense
* actions
* optimistic rendering
* streaming
* server components

They are all parts of one larger architecture.

---

# 27. Advanced React 19 Patterns

---

# Suspense-Driven Data Fetching

React 19 pushes React toward async-first rendering.

Traditional approach:

```txt
Component mounts
→ fetch data
→ loading state
→ render
```

React 19 approach:

```txt
Start fetching immediately
→ suspend rendering
→ stream UI progressively
```

---

# Optimistic UI + Server Actions

Modern React apps increasingly use:

* useOptimistic
* useActionState
* Server Actions
* Suspense
* use

Together.

This creates:

```txt
Near-instant interfaces
```

Even with slow networks.

---

# Concurrent Rendering Mental Model

React no longer thinks:

```txt
Render everything immediately
```

Instead:

```txt
Prioritize important work
Interrupt unnecessary work
Resume later
```

Hooks like:

* useTransition
* useDeferredValue

help coordinate this.

---

# 28. Hook Decision Matrix

| Problem                          | Hook                 |
| -------------------------------- | -------------------- |
| Need component memory            | useState             |
| Complex state logic              | useReducer           |
| Need side effects                | useEffect            |
| Need DOM access                  | useRef               |
| Need shared state                | useContext           |
| Need cached calculation          | useMemo              |
| Need stable function             | useCallback          |
| Need optimistic updates          | useOptimistic        |
| Need async form handling         | useActionState       |
| Need async resource reading      | use                  |
| Need low-priority updates        | useTransition        |
| Need deferred values             | useDeferredValue     |
| Need external store subscription | useSyncExternalStore |

---

# 29. Final Mental Models

---

# The Most Important Hook Insight

Hooks are NOT random APIs.

Each hook represents a category of behavior.

---

# Core React Philosophy

React is fundamentally:

```txt
UI = f(state)
```

Hooks define:

* How state changes
* How effects synchronize
* How rendering prioritizes work
* How async flows coordinate

---

# The Three Most Important Beginner Lessons

## 1. Components Re-Render Constantly

This is normal.

Do not fear rerenders.

---

## 2. Effects Are Synchronization

Effects are NOT “lifecycle methods.”

They synchronize external systems.

---

## 3. Most Complexity Comes from State

Design state carefully.

Bad state architecture creates difficult applications.

---

# Recommended Learning Order

Master these first:

1. useState
2. useEffect
3. useRef
4. useContext
5. useMemo
6. useCallback
7. useReducer

Then learn:

8. useTransition
9. useDeferredValue
10. useOptimistic
11. useActionState
12. use

---

# Final Advice

The best way to learn hooks is NOT memorization.

Build things.

Create:

* Todo apps
* Chat apps
* Search interfaces
* Dashboards
* Kanban systems
* Real-time applications

Hooks become intuitive through repetition.

Over time, you stop asking:

> “Which hook should I use?”

And start asking:

> “What kind of behavior am I modeling?”

That is when React finally clicks.
