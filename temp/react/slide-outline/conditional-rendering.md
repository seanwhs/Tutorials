### **Slide 1 — Title**
**Mastering Conditional Rendering in React**  
*Building Dynamic, Performant User Interfaces*

**Subtitle:** From JavaScript Conditions to React Fiber Reconciliation and React 19 Patterns

**Presenter:** [Your Name]  
**Level:** Intermediate React Developers  
**Duration:** 45-60 minutes

*(Visual suggestion: Modern React logo with faint component tree in background)*

---

### **Slide 2 — Agenda**
- Why Conditional Rendering Matters in Modern Apps
- Declarative Philosophy vs Imperative DOM Manipulation
- The 6 Core Conditional Rendering Techniques
- Component Trees, Identity & Reconciliation
- React Fiber: Render & Commit Phases
- Mounting, Unmounting & State Lifecycle
- Performance Tradeoffs & State Preservation
- Modern Patterns (Suspense, Transitions, React 19)
- Common Pitfalls, Best Practices & Exercise
- Q&A and Next Steps

---

### **Slide 3 — Learning Objectives**
By the end of this session, you will be able to:

- Explain **why** conditional rendering exists and when to choose it
- Apply **all 6 conditional rendering techniques** with confidence
- Understand React’s **declarative** model and component identity
- Visualize how React builds and reconciles **component trees**
- Differentiate **mounting vs unmounting** and their impact on state
- Make smart **performance decisions** (conditional vs hidden)
- Leverage **React 18/19** patterns (Suspense, Transitions, `useOptimistic`, etc.)
- Avoid common bugs and apply clean architectural patterns

---

### **Slide 4 — Why Conditional Rendering?**
Modern applications are **highly dynamic**.

| Scenario                  | UI Change Needed                  |
|---------------------------|-----------------------------------|
| User logs in/out          | Login → Dashboard                 |
| Data is loading           | Placeholder → Content → Spinner   |
| API request fails         | Form → Error message              |
| Cart is empty             | Items list → “Your cart is empty” |
| User role changes         | Add/remove admin controls         |
| Notifications arrive      | Show badge or toast               |
| Feature flags toggle      | Show/hide experimental features   |

**Core Question:**  
How should the UI respond declaratively to state changes?

---

### **Slide 5 — Traditional Imperative Approach**
```javascript
// ❌ Imperative JavaScript
document.getElementById('login').style.display = 'none';
document.getElementById('dashboard').style.display = 'block';
spinnerElement.remove();
```

**Problems:**
- Manual DOM manipulation everywhere
- State logic scattered across files
- Easy to create inconsistent UIs
- Difficult to debug and maintain

---

### **Slide 6 — React’s Declarative Philosophy**
Instead of asking:  
> “How do I update the UI?”

React asks:  
> “What should the UI look like **right now**?”

**Key Principle:**  
You describe the **desired UI** based on current state. React figures out **how** to get there efficiently.

---

### **Slide 7 — The Core Equation**
**UI = f(State)**

**Flow:**
```
State Change
     ↓
Component Re-renders
     ↓
Returns New JSX
     ↓
React Elements → Fiber Tree
     ↓
Reconciliation → Commit
     ↓
Updated DOM
```

---

### **Slide 8 — Components Are Functions of State**
```javascript
function Greeting({ isLoggedIn }) {
  return <h1>{isLoggedIn ? 'Welcome back!' : 'Please sign in'}</h1>;
}
```

Every time relevant state changes, React calls the component function again and compares the returned trees.

---

### **Slide 9 — Static vs Dynamic Components**
| Static                          | Dynamic                                      |
|---------------------------------|----------------------------------------------|
| `return <Welcome />;`           | `if (isLoggedIn) return <Dashboard />;` <br>`return <Login />;` |
| Always returns the same tree    | Returns **different trees** based on state   |

**Key Insight:** Dynamic components change the **structure** of the component tree.

---

### **Slide 10 — React Doesn’t “Hide” — It Replaces Trees**
**Common Misconception:** Thinking in terms of `display: none`

**Reality:** React **replaces** subtrees when the component type changes.

**Golden Reconciliation Rule:**  
If the component type at a given position in the tree changes, React **unmounts** the old component (destroys its state and effects) and **mounts** the new one.

---

### **Slide 11 — Component Tree Visualization**
**When not logged in:**
```
App
├── Header
└── LoginForm
```

**When logged in:**
```
App
├── Header
└── Dashboard     ← New subtree
     └── MainContent
```

**Discussion Point:** This triggers mounting/unmounting and effect cleanup.

---

### **Slide 12 — 6 Conditional Rendering Techniques**
| Technique            | Best Use Case                     | Example |
|----------------------|-----------------------------------|--------|
| Early Return         | Large branches, guard clauses     | `if (loading) return <Spinner />;` |
| Element Variable     | Complex logic, partial UI         | `let action = isAdmin && <DeleteButton />;` |
| Ternary Operator     | Exactly two options               | `{isLoggedIn ? <Dashboard /> : <Login />}` |
| Logical AND (`&&`)   | Optional elements, badges         | `{isAdmin && <AdminPanel />}` |
| Return `null`        | Hide component entirely           | `if (!visible) return null;` |
| Switch / Object Map  | 3+ conditions                     | `const views = { admin: <Admin/>, ... }` |

---

### **Slide 13 — Technique 1: Early Returns**
```javascript
function Dashboard() {
  if (loading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;
  if (!isLoggedIn) return <Login />;

  return <MainContent data={data} />;
}
```

**Advantages:**  
- Extremely readable  
- Easy to scale  
- Preferred pattern by most React teams

---

### **Slide 14 — Technique 2: Element Variables**
```javascript
function Profile({ isAdmin }) {
  let actionButton = null;

  if (isAdmin) {
    actionButton = <DeleteButton onClick={handleDelete} />;
  }

  return (
    <>
      <UserInfo />
      {actionButton}
    </>
  );
}
```

**Benefit:** Keeps JSX clean and separates decision logic.

---

### **Slide 15 — Technique 3: Ternary Operator**
```javascript
{isLoggedIn ? <Dashboard /> : <Login />}
```

**Best for:** Exactly two choices.  
**Avoid:** Deeply nested ternaries → extract into helper functions or early returns.

---

### **Slide 16 — Technique 4: Logical AND**
```javascript
{isAdmin && <AdminControls />}
{notifications.length > 0 && <NotificationBadge count={notifications.length} />}
```

**Perfect for:** Optional UI elements.

---

### **Slide 17 — The Famous “0” Bug**
```javascript
// ❌ Bug
{items.length && <ItemList items={items} />}
// Renders "0" on screen when array is empty!

// ✅ Fixed
{items.length > 0 && <ItemList items={items} />}
// or
{items.length ? <ItemList items={items} /> : null}
```

**Tip:** Prefer explicit comparisons or ternaries for clarity.

---

### **Slide 18 — Technique 5: Return `null`**
```javascript
function Banner({ visible }) {
  if (!visible) return null;

  return <div className="banner">New feature launched!</div>;
}
```

Component runs but produces no DOM output.

---

### **Slide 19 — Conditional Rendering in Lists**
```javascript
// ❌ Less ideal
items.map(item => {
  if (item.active) return <Item key={item.id} item={item} />;
  return null;
});

// ✅ Preferred
items
  .filter(item => item.active)
  .map(item => <Item key={item.id} item={item} />);
```

Cleaner code + fewer elements for React to reconcile.

---

### **Slide 20 — State Preservation Rule (Golden Rule)**
| Approach                        | State Preserved? | Mount/Unmount? | Recommended For          |
|---------------------------------|------------------|----------------|--------------------------|
| `{show && <Component />}`       | No               | Yes            | Structural changes       |
| `<Component hidden={!show}>` or CSS | Yes          | No             | Frequent toggles         |

**Rule of Thumb:** Use conditional rendering for **different UI structures**. Use `hidden` / CSS for **same component, different visibility**.

---

### **Slide 21 — React Fiber Overview**
Fiber is React’s **reconciliation engine**.

**Phases:**
1. **Render Phase** – Compute what changed (no DOM mutations)
2. **Commit Phase** – Apply changes to DOM, run effects

---

### **Slide 22 — Render Phase**
- Executes components
- Evaluates all conditions
- Builds React Elements
- Constructs the work-in-progress Fiber tree
- **No side effects or DOM changes**

---

### **Slide 23 — Commit Phase**
React performs the actual work:
- Inserts / removes / updates DOM nodes
- Attaches refs
- Runs `useLayoutEffect` and `useEffect`

This is when the UI becomes visible to the user.

---

### **Slide 24 — Mounting**
When a component goes from **not present → present**:
- New Fiber node created
- Hooks initialized
- DOM inserted
- Effects run

---

### **Slide 25 — Unmounting**
When a component goes from **present → not present**:
- Cleanup functions executed
- DOM nodes removed
- State and Fibers destroyed

---

### **Slide 26 — useEffect Cleanup**
```javascript
useEffect(() => {
  const timer = setInterval(() => { ... }, 1000);

  return () => clearInterval(timer); // ← Critical!
}, []);
```

Without cleanup → memory leaks, orphan subscriptions, timers.

---

### **Slide 27 — Performance Tradeoffs**
**Mounting cost is high** (new fibers, hook init, effects, layout).

**Ask yourself:**
- Will this component toggle frequently?
- Is preserving internal state important?
- Should I use conditional rendering or CSS `hidden`?

---

### **Slide 28 — Common Mistakes**
| Mistake                        | Fix |
|--------------------------------|-----|
| Nested ternaries               | Extract to functions / early returns |
| `items.length && <List />`     | Use `items.length > 0 &&` or ternary |
| No cleanup in `useEffect`      | Always return cleanup function |
| Conditionals inside `.map()`   | Filter first |
| Assuming `hidden` = unmounted  | Understand they are different |

---

### **Slide 29 — Best Practices**
- Prefer **early returns** for complex logic
- Keep JSX **readable** — extract conditions
- **Filter before map** in lists
- Use **explicit comparisons**
- Always clean up effects
- Think in **component trees**, not CSS visibility
- Extract complex conditions into helper functions

---

### **Slide 30 — Putting It All Together**
```
State Change
     ↓
Component Function Executes
     ↓
New JSX / React Elements
     ↓
Fiber Reconciliation
     ↓
Tree Diff (Mount / Update / Unmount)
     ↓
Commit Phase
     ↓
DOM Updated
```

---

### **Slide 31 — Modern React Patterns**
| Pattern              | Purpose                                      | Benefit |
|----------------------|----------------------------------------------|--------|
| **Suspense**         | Async data loading with fallbacks            | Removes manual loading states |
| **useTransition**    | Mark non-urgent updates                      | Better perceived performance |
| **`use()` (React 19)** | Consume promises/context                 | Cleaner async code |
| **`useOptimistic`**  | Optimistic UI updates                        | Responsive mutations |
| **`useActionState`** | Form action state management                 | Simplified form handling |

---

### **Slide 32 — Next Topics**
- Deep dive into Reconciliation Algorithm
- Component Identity & Keys in lists
- Concurrent Rendering & Lanes
- Error Boundaries
- Performance optimization (`memo`, `useMemo`, `useCallback`)

---

### **Slide 33 — Interactive Exercise**
**Refactor this component:**

```javascript
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
1. Refactor using **early returns**
2. Improve error handling (consider Error Boundaries)
3. Discuss when you would use `hidden` instead

---

### **Slide 34 — Q&A + Resources**
**Recommended Resources:**
- React Docs – Conditional Rendering
- React 19 Documentation
- “React 18 Suspense and Transitions”
- Deep dives on React Fiber (YouTube / blogs)

**Thank you! Questions?**
