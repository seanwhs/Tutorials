## Conditional Rendering

### Slide 1 — Title
**Mastering Conditional Rendering in React**  
*Building Dynamic User Interfaces*

**Subtitle:** From JavaScript Conditions to React Fiber Architecture

**Presenter:** [Your Name]  
**Level:** Intermediate React Developers  
**Duration:** 45-60 minutes

***

### Slide 2 — Learning Objectives
By the end of this session, you will understand:

- **Why** conditional rendering exists and when to use it
- React's **declarative** vs imperative rendering model
- **All 6 conditional rendering techniques** with best-use scenarios
- How React builds and updates **component trees**
- **Mounting vs Unmounting** and their state implications
- **React Fiber's** role in reconciliation
- **Performance tradeoffs** and architectural decisions
- **Modern patterns**: Suspense, Transitions, React 19 APIs

***

### Slide 3 — Why Conditional Rendering?
**Modern applications are constantly changing:**

| Scenario | UI Change Needed |
|----------|------------------|
| User logs in | Login → Dashboard |
| Data loading | Content → Spinner |
| API fails | Form → Error message |
| Empty cart | Items → "Empty" message |
| User becomes admin | + Admin controls |
| Notifications appear | + Badge/alert |
| Feature flags | Show/hide features |

**Core Question:** How should the UI respond to state changes? [dev](https://dev.to/tene/mastering-conditional-rendering-in-react-4980)

***

### Slide 4 — Traditional DOM Manipulation (Imperative)

```javascript
// ❌ Imperative JavaScript
login.style.display = "none";
dashboard.style.display = "block";
spinner.remove();
```

**Problems:**
- Developer controls every DOM change, event, and update
- Difficult to maintain
- State scattered across code
- UI easily becomes inconsistent [dev](https://dev.to/tene/mastering-conditional-rendering-in-react-4980)

***

### Slide 5 — React's Declarative Philosophy

**Instead of asking:**
> "How do I update the UI?"

**React asks:**
> "What should the UI look like *now*?"

**Key principle:** The application describes the *desired UI*. React determines *how* to reach it. [reactdevelopers](https://reactdevelopers.org/docs/react-fundamentals/conditional-rendering/)

***

### Slide 6 — The Core Equation

**Large center text:**
```
UI = f(State)
```

**Flow:**
```
Component
  ↓ Receives State
  ↓ Returns JSX
  ↓ React renders UI
Every state change
  ↓ Component executes again
```

***

### Slide 7 — Components are Functions

```javascript
function Greeting({ loggedIn }) {
  return <h1>Hello!</h1>;
}
```

**React's execution flow:**
```
Greeting() → JSX → React Elements → DOM
```

***

### Slide 8 — Static vs Dynamic Components

| Static | Dynamic |
|--------|---------|
| `return <Welcome />;` | `if (loggedIn) return <Dashboard />;`<br>`return <Login />;` |

**Key idea:** The returned UI *depends on state* [nerdleveltech](https://www.nerdleveltech.com/react-conditional-rendering-2025)

***

### Slide 9 — React Doesn't "Hide" Components

**Common misconception:** `display: none`

**Reality:** React *changes the tree*

```
Old Tree          New Tree
App               App
├── Header        ├── Header
└── Footer        ├── Dashboard  ← NEW
                  └── Footer
```

***

### Slide 10 — Component Tree Visualization

```
When !loggedIn        When loggedIn
App                   App
├── Header            ├── Header
└── Footer            ├── Dashboard  ← new subtree
                      └── Footer

Discuss: reconciliation → mounting → effects
```

***

### Slide 11 — Conditional Rendering Techniques (Overview)

| Technique | Best Use | Code Example |
|-----------|----------|--------------|
| **Early Return** | Large branches, guard clauses | `if (loading) return <Spinner />;`  [dev](https://dev.to/tene/mastering-conditional-rendering-in-react-4980) |
| **Element Variable** | Partial UI, separated logic | `let action = isAdmin && <DeleteButton />;`  [nerdleveltech](https://www.nerdleveltech.com/react-conditional-rendering-2025) |
| **Ternary (`? :`)** | Exactly two choices | `{loggedIn ? <Dashboard /> : <Login />}`  [nerdleveltech](https://www.nerdleveltech.com/react-conditional-rendering-2025) |
| **Logical AND (`&&`)** | Optional UI, badges | `{isAdmin && <DeleteButton />}`  [nerdleveltech](https://www.nerdleveltech.com/react-conditional-rendering-2025) |
| **Return `null`** | Component renders nothing | `if (!visible) return null;`  [dev](https://dev.to/tene/mastering-conditional-rendering-in-react-4980) |
| **Switch/Object Map** | Multiple conditions | `const views = { admin: <Admin />, user: <User /> };`  [julesblom](https://julesblom.com/writing/lazy-component-maps) |

**Add:** Switch statements / Object maps for 3+ conditions [julesblom](https://julesblom.com/writing/lazy-component-maps)

***

### Slide 12 — Technique 1: Early Returns

```javascript
function Dashboard() {
  if (loading) return <Spinner />;
  if (error) return <Error />;
  if (!isLoggedIn) return <Login />;
  
  return <MainContent />;
}
```

**Advantages:**
- ✅ Readable and scalable
- ✅ Preferred by most developers [reactdevelopers](https://reactdevelopers.org/docs/react-fundamentals/conditional-rendering/)
- ✅ Avoids nested conditionals

***

### Slide 13 — Technique 2: Element Variables

```javascript
function Profile({ isAdmin }) {
  let action = null;
  
  if (isAdmin) {
    action = <DeleteButton />;
  }
  
  return (
    <>
      <Profile />
      {action}
    </>
  );
}
```

**Benefits:**
- Separates logic from JSX
- Cleaner, more readable output [nerdleveltech](https://www.nerdleveltech.com/react-conditional-rendering-2025)

***

### Slide 14 — Technique 3: Ternary Operator

```javascript
{loggedIn ? <Dashboard /> : <Login />}
```

**Use for:**
- ✅ Exactly two choices [jsinterview](https://jsinterview.dev/concepts/react/conditional-rendering)

**Avoid:**
- ❌ Nested ternaries (extract to functions) [dev](https://dev.to/tene/mastering-conditional-rendering-in-react-4980)

***

### Slide 15 — Technique 4: Logical AND

```javascript
{isAdmin && <DeleteButton />}
```

**Perfect for:**
- Badges
- Notifications
- Admin controls [jsinterview](https://jsinterview.dev/concepts/react/conditional-rendering)

***

### Slide 16 — The Famous "0" Bug

**❌ Bad:**
```javascript
{items.length && <ItemList />}
// If items.length = 0, React renders "0"
```

**✅ Correct:**
```javascript
{items.length > 0 && <ItemList />}
// OR
{Boolean(items.length) && <ItemList />}
// OR
{items.length ? <ItemList /> : null}
```

**Fix options:** Explicit comparison, `Boolean()`, double `!!`, or ternary [linkedin](https://www.linkedin.com/posts/rahul-verma-4a47a01a4_reactjs-javascript-frontenddevelopment-activity-7333071660184477696-nBYD)

***

### Slide 17 — Technique 5: Returning `null`

```javascript
function Banner({ visible }) {
  if (!visible) return null;
  
  return <div>New feature!</div>;
}
```

**Explain:**
- Component executes, but no DOM created
- Useful for optional banners, dialogs, notifications [jsinterview](https://jsinterview.dev/concepts/react/conditional-rendering)

***

### Slide 18 — Conditional Rendering in Lists

**❌ Less readable:**
```javascript
items.map(item => {
  if (item.active) return <Item />;
  return null;
})
```

**✅ Preferred:**
```javascript
items
  .filter(item => item.active)
  .map(item => <Item key={item.id} />)
```

**Benefits:** Cleaner, easier debugging, separation of concerns [nerdleveltech](https://www.nerdleveltech.com/react-conditional-rendering-2025)

***

### Slide 19 — Thinking Like React

**Developers imagine:**
- "Hide Spinner"
- "Show Dashboard"

**React sees:**
```
Spinner  ↓  Dashboard
Tree changes completely
```

***

### Slide 20 — React Fiber Overview

```
Component
  ↓ Render
  ↓ React Elements
  ↓ Fiber Tree
  ↓ Reconciliation
  ↓ Commit
  ↓ DOM
```

**Fiber = React's execution engine** [youtube](https://www.youtube.com/watch?v=au1jDScQQvc)

***

### Slide 21 — Render Phase

**Responsibilities:**
- Execute components
- Evaluate conditions
- Build React Elements
- Build work-in-progress Fiber tree

**No DOM updates yet** [youtube](https://www.youtube.com/watch?v=au1jDScQQvc)

***

### Slide 22 — Commit Phase

**React now:**
- Inserts DOM
- Removes DOM
- Updates DOM
- Attaches refs
- Runs effects

**Everything visible happens here** [youtube](https://www.youtube.com/watch?v=au1jDScQQvc)

***

### Slide 23 — Mounting

```
false → true (component appears)

React:
- Creates Fiber
- Initializes hooks
- Inserts DOM
- Runs effects
```

***

### Slide 24 — Unmounting

```
true → false (component disappears)

React:
- Cleanup
- Remove DOM
- Destroy state
- Delete Fiber subtree
```

***

### Slide 25 — `useEffect` Cleanup

```javascript
useEffect(() => {
  const timer = setInterval(() => {}, 1000);
  
  return () => {
    clearInterval(timer);
  };
}, []);
```

**Without cleanup:** Leaks, orphan timers, subscriptions [legacy.reactjs](https://legacy.reactjs.org/docs/reconciliation.html)

***

### Slide 26 — Why State Disappears

```
Editor → Unmount → State Destroyed → Mount Again → Fresh State
```

**State belongs to the component instance** [blog.csdn](https://blog.csdn.net/JaneLittle/article/details/155987510)

***

### Slide 27 — Preserving State (Critical Comparison)

| Approach | Code | State Preserved? | DOM Changed? |
|----------|------|------------------|--------------|
| **Conditional** | `{show && <Component />}` | ❌ No | ✅ Yes (mount/unmount) |
| **Hidden** | `<div hidden={!show}><Component /></div>` | ✅ Yes | ❌ No |

**Key insight:** `hidden` keeps the component mounted [blog.csdn](https://blog.csdn.net/JaneLittle/article/details/155987510)

***

### Slide 28 — Performance Tradeoffs

**Mounting costs:**
- Rendering
- Hooks initialization
- Effects execution
- DOM creation

**Ask:** Should this component really be *destroyed*? [medium](https://medium.com/@pravinshingade199777/blog-6-mastering-conditional-rendering-in-react-display-what-matters-4dad778790b8)

***

### Slide 29 — Decision Guide (Flowchart)

```
Need component?
  ↓ Yes
Need to preserve state?
  ↓ Yes → Hide (use hidden/style)
  ↓ No  → Unmount (conditional)
```

***

### Slide 30 — Common Mistakes

| ❌ Mistake | ✅ Fix |
|------------|--------|
| Nested ternaries | Extract to functions/early returns  [dev](https://dev.to/tene/mastering-conditional-rendering-in-react-4980) |
| Truthy length checks (`items.length &&`) | Use explicit comparison (`items.length > 0 &&`)  [dev](https://dev.to/tene/mastering-conditional-rendering-in-react-4980) |
| Missing cleanup in `useEffect` | Always return cleanup function  [legacy.reactjs](https://legacy.reactjs.org/docs/reconciliation.html) |
| Rendering logic inside `map` | Filter before map  [nerdleveltech](https://www.nerdleveltech.com/react-conditional-rendering-2025) |
| Assuming `hidden == unmounted` | They're fundamentally different  [blog.csdn](https://blog.csdn.net/JaneLittle/article/details/155987510) |
| Multiple conditions in JSX | Use switch/object map  [julesblom](https://julesblom.com/writing/lazy-component-maps) |

***

### Slide 31 — Best Practices

| ✅ Practice | Why |
|-------------|-----|
| Prefer early returns | Readable, scalable  [dev](https://dev.to/tene/mastering-conditional-rendering-in-react-4980) |
| Keep JSX readable | Extract complex logic  [dev](https://dev.to/tene/mastering-conditional-rendering-in-react-4980) |
| Filter before map | Cleaner, debuggable  [nerdleveltech](https://www.nerdleveltech.com/react-conditional-rendering-2025) |
| Use explicit booleans | Avoid "0" bug  [jsinterview](https://jsinterview.dev/concepts/react/conditional-rendering) |
| Understand lifecycle | Mount/unmount implications  [legacy.reactjs](https://legacy.reactjs.org/docs/reconciliation.html) |
| Think in trees | Not DOM visibility  [blog.csdn](https://blog.csdn.net/JaneLittle/article/details/155987510) |
| Extract complex conditions | Helper functions/components  [dev](https://dev.to/tene/mastering-conditional-rendering-in-react-4980) |
| Handle default cases | Error boundaries, fallbacks  [medium](https://medium.com/@tucecifcii/mastering-conditional-rendering-in-react-a-comprehensive-guide-9dc1b12b8502) |

***

### Slide 32 — Putting It All Together

```
State Changes
  ↓
Component Executes
  ↓
New React Elements
  ↓
Fiber Reconciliation
  ↓
Tree Changes
  ↓
Mount / Update / Unmount
  ↓
Commit
  ↓
DOM Updated
```

***

### Slide 33 — Key Takeaways

1. Components return **different trees**, not just hidden elements
2. Conditional rendering **changes application structure**
3. Fiber reconciles **trees**, not HTML
4. Mounting **creates** component instances
5. Unmounting **destroys** state [legacy.reactjs](https://legacy.reactjs.org/docs/reconciliation.html)
6. `useEffect` cleanup prevents **resource leaks**
7. Performance depends on **architectural choices**
8. Think in **component trees**, not DOM visibility [blog.csdn](https://blog.csdn.net/JaneLittle/article/details/155987510)

***

### Slide 34 — Modern React Patterns (NEW)

**Add coverage of React 18/19:**

| Pattern | Use Case |
|---------|----------|
| **Suspense** | Async data loading with fallbacks  [dev](https://dev.to/tmns/creating-better-user-experiences-with-react-18-suspense-and-transitions-3oje) |
| **Transitions (`useTransition`)** | Mark non-urgent updates  [dev](https://dev.to/tmns/creating-better-user-experiences-with-react-18-suspense-and-transitions-3oje) |
| **`use()` hook** | Consume async resources (React 19)  [blog.openreplay](https://blog.openreplay.com/react-19-async-rendering/) |
| **`useActionState`** | Form action state (React 19)  [blog.openreplay](https://blog.openreplay.com/react-19-async-rendering/) |
| **`useOptimistic`** | Responsive UI during mutations  [blog.openreplay](https://blog.openreplay.com/react-19-async-rendering/) |

***

### Slide 35 — Next Topics (Enhanced)

Where conditional rendering leads:

- React Reconciliation Algorithm (deep dive)
- React Fiber Architecture internals
- Component Identity & Keys (preserving state in lists) [blog.csdn](https://blog.csdn.net/JaneLittle/article/details/155987510)
- **Suspense** for data fetching [dev](https://dev.to/tmns/creating-better-user-experiences-with-react-18-suspense-and-transitions-3oje)
- **Concurrent Rendering** & lane-based scheduling [youtube](https://www.youtube.com/watch?v=au1jDScQQvc)
- **Transitions** & `startTransition` [blog.openreplay](https://blog.openreplay.com/react-19-async-rendering/)
- React 19: `use()`, `useActionState`, `useOptimistic` [blog.openreplay](https://blog.openreplay.com/react-19-async-rendering/)
- Performance Optimization: `memo`, ` useMemo`, `useCallback`
- Error Boundaries for graceful failure handling

***

### Slide 36 — Interactive Exercise (NEW)

**Hands-on challenge:**

```javascript
// Fix this component:
function UserPage({ user, loading, error, isAdmin }) {
  return (
    <div>
      {loading ? <Spinner /> : null}
      {error ? <Error /> : null}
      {user ? <Profile user={user} /> : null}
      {isAdmin && user && <DeleteButton />}
    </div>
  );
}
```

**Tasks:**
1. Refactor using early returns
2. Fix the双重 `user` check
3. Add proper error handling

***

### Slide 37 — Q&A + Resources

**Recommended resources:**
- React Docs: Conditional Rendering [reactdevelopers](https://reactdevelopers.org/docs/react-fundamentals/conditional-rendering/)
- "React 18 Suspense and Transitions" [dev](https://dev.to/tmns/creating-better-user-experiences-with-react-18-suspense-and-transitions-3oje)
- "React 19 and Suspense" [tkdodo](https://tkdodo.eu/blog/react-19-and-suspense-a-drama-in-3-acts)
- Your tutorial notes on React Fiber

**Questions?**

10. **Consolidated common mistakes** into table format for clarity

The outline now better serves your audience of intermediate React developers while maintaining your strong conceptual flow from JavaScript conditions → Fiber architecture.
