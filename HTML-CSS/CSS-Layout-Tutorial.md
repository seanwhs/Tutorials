# 🎨 FlexGrid Studio — Hands-On Layout Mastery 

A practical, step-by-step training system to help you *think in layouts*, not just memorize CSS properties.

You will build real UI components while learning:

* how Flexbox distributes space
* how Grid defines structure
* how both systems work together in real apps

No passive reading. Every module is a build.

---

# 🧰 Getting Set Up

You can use either:

* 🟡 CodePen → create a new pen for each module
* 🟢 Local project → `index.html` + `style.css`

### Rule of learning

You must:

* type everything manually
* avoid copy-pasting full solutions
* experiment after every step

Each module assumes:

* 1 HTML file
* 1 CSS file

---

# 🧭 Module 1 — Flexbox Basics: Navbar Layout

## 🎯 Goal

Build a professional navbar:

* logo on the left
* navigation links on the right
* vertically centered alignment

---

## 🧱 Step 1 — HTML Structure

Create your layout skeleton:

```html
<body>
  <header class="navbar">
    <div class="logo">FlexGrid</div>

    <nav class="nav-links">
      <a href="#">Home</a>
      <a href="#">Courses</a>
      <a href="#">Pricing</a>
      <a href="#">Login</a>
    </nav>
  </header>
</body>
```

### 🧠 Think about it

Before adding CSS:

> How will these elements behave by default?
> Will they line up or stack vertically?

---

## 🎯 Step 2 — Turn Header into a Flex Container

```css
body {
  margin: 0;
  font-family: system-ui, -apple-system, sans-serif;
}

.navbar {
  display: flex;
  justify-content: space-between;
  align-items: center;

  padding: 0 1.5rem;
  height: 64px;

  background: #111827;
  color: white;
}
```

### 🧠 What changed?

You just transformed layout flow:

* `display: flex` → activates Flexbox
* `space-between` → pushes items apart
* `center` → vertical alignment

### 🔍 Experiment prompt

Change:

* `space-between → center`
* `space-between → flex-start`

> What happens to the spacing logic?

---

## 🎯 Step 3 — Make Nav Links Horizontal

```css
.nav-links {
  display: flex;
  gap: 1.5rem;
}

.nav-links a {
  color: #e5e7eb;
  text-decoration: none;
}

.nav-links a:hover {
  color: #38bdf8;
}
```

### 🧠 Key idea

Flexbox is now working *inside* the navbar too.

You are nesting layout systems.

---

## 🧪 Step 4 — Break to Understand

Try these intentionally:

* `flex-direction: column` on `.navbar`
* increase `gap` to `3rem`
* add `border: 1px solid red`

### 🧠 Reflection

> What is the difference between `justify-content` and `align-items` in this layout?

---

## 🚀 Extension Challenge

Add:

* a “Sign Up” button
* a media query that stacks layout on mobile

---

# 🧭 Module 2 — CSS Grid: Product Layout System

## 🎯 Goal

Build a responsive product grid that:

* automatically adjusts columns
* scales without fixed widths
* adapts to screen size

---

## 🧱 Step 1 — HTML Structure

```html
<section class="product-section">
  <h2>Featured Products</h2>

  <div class="product-grid">
    <article class="product-card">Product 1</article>
    <article class="product-card">Product 2</article>
    <article class="product-card">Product 3</article>
    <article class="product-card">Product 4</article>
    <article class="product-card">Product 5</article>
    <article class="product-card">Product 6</article>
  </div>
</section>
```

### 🧠 Think about it

> How are these elements displayed before CSS Grid?

---

## 🎯 Step 2 — Basic Grid Layout

```css
.product-grid {
  display: grid;
  gap: 1.5rem;

  grid-template-columns: repeat(3, 1fr);
}
```

### 🧠 Core concept

* `1fr` = fraction of available space
* Grid divides the container into equal columns

---

## 🧪 Experiment

Change:

* `repeat(3, 1fr)` → `repeat(4, 1fr)`

> What happens to the layout density?

---

## 🎯 Step 3 — Responsive Grid with minmax()

```css
.product-grid {
  display: grid;
  gap: 1.5rem;

  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
}
```

### 🧠 What this means

* auto-fit → creates as many columns as possible
* minmax → defines flexible boundaries

So each card:

* never shrinks below 180px
* grows when space is available

---

## 🧪 Experiment

Try:

* `180px → 250px`
* `auto-fit → auto-fill`

> What changes in empty space behavior?

---

## 🚀 Extension Challenge

Inside each card, add:

* title
* price
* button

Then use Flexbox inside cards for alignment (preview of Module 3).

---

# 🧭 Module 3 — Hybrid Layout: SaaS Dashboard

## 🎯 Goal

Build a real UI layout combining:

* Grid → page structure
* Flexbox → internal alignment

---

## 🧱 Step 1 — App Shell

```html
<div class="dashboard">
  <aside class="sidebar">
    <h1>FlexGrid SaaS</h1>
    <nav>
      <a href="#">Overview</a>
      <a href="#">Analytics</a>
      <a href="#">Billing</a>
      <a href="#">Settings</a>
    </nav>
  </aside>

  <header class="topbar">
    <div>Dashboard</div>

    <div class="topbar-right">
      <button>New Report</button>
      <div class="avatar">SW</div>
    </div>
  </header>

  <main class="main">
    <section class="cards-grid">
      <article class="card">Revenue</article>
      <article class="card">Users</article>
      <article class="card">Churn</article>
      <article class="card">MRR</article>
    </section>
  </main>
</div>
```

---

## 🧠 Layout Thinking Prompt

> Which parts define structure (Grid)?
> Which parts define alignment (Flexbox)?

---

## 🎯 Step 2 — Grid Layout System

```css
.dashboard {
  min-height: 100vh;
  display: grid;

  grid-template-columns: 240px 1fr;
  grid-template-rows: 64px 1fr;

  grid-template-areas:
    "sidebar topbar"
    "sidebar main";
}

.sidebar { grid-area: sidebar; }
.topbar  { grid-area: topbar; }
.main    { grid-area: main; }
```

### 🧠 Key idea

Grid defines the *app skeleton*.

---

## 🧪 Experiment

Change:

* `240px 1fr → 1fr 3fr`

> What happens to sidebar dominance?

---

## 🎯 Step 3 — Flexbox Inside Components

```css
.topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;

  padding: 0 1.5rem;
}

.topbar-right {
  display: flex;
  gap: 1rem;
  align-items: center;
}

.sidebar {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}
```

### 🧠 Core insight

* Grid = page layout
* Flex = component layout

---

## 🎯 Step 4 — Cards Grid

```css
.cards-grid {
  display: grid;
  gap: 1.5rem;

  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
}
```

---

## 🧠 Final Concept

You now have:

* Grid controlling structure
* Flexbox controlling alignment
* Nested systems working together

---

# 🔁 Daily Learning Loop

For every module:

### 1. Build

Type everything manually.

### 2. Observe

Don’t rush—watch layout changes.

### 3. Experiment

Change one property at a time.

### 4. Break

Intentionally distort layout.

### 5. Extend

Add one feature beyond instructions.

---

# 🧠 Final Thinking Check

If you were designing the dashboard from scratch:

> How would you describe (in plain language) what Grid handles vs what Flexbox handles in your system design?

* a **Notion-style curriculum**
* or a **frontend “bootcamp progression system” with exercises + grading checkpoints**
