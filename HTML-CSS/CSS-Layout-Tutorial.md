# 🎨 FlexGrid Studio — Incremental Layout Builder

We are going to build a **mini SaaS dashboard UI** step by step. We will *slowly evolve it* into a real layout system using **Flexbox** for alignment and **Grid** for structure.

---

# 🧰 Base Setup (Start Here)

## 📄 index.html

*(Use the base HTML provided in the initial setup)*

## 📄 style.css (Step 0)

```css
body { margin: 0; font-family: system-ui; }

```

👉 **The Reality:** Without layout engines, HTML behaves like a document—everything flows from top to bottom (the "Normal Flow").

---

# 🧭 STEP 1 — Make the layout visible

```css
.app { min-height: 100vh; }
.sidebar { background: #111827; color: white; padding: 16px; }
.main { padding: 16px; }
.card { background: #f3f4f6; padding: 16px; margin: 8px 0; }

```

### 🧠 The Logic

We are giving every block a "bounding box." **Pro-Tip:** If you ever feel lost, add `outline: 2px solid red;` to your elements to see their borders clearly.

---

# 🧭 STEP 2 — The Layout Shift (Flexbox)

```css
.app { display: flex; min-height: 100vh; }
.sidebar { width: 220px; }

```

### 🧠 Pro-Tip

By default, `display: flex` turns the `main` element into a "flex item." Flexbox is about **distributing space along a single axis.**

---

# 🧭 STEP 3 — Vertical Systems

```css
.sidebar { display: flex; flex-direction: column; gap: 12px; }

```

### 🧠 Pro-Tip

`flex-direction: column` tells the browser: "Return to vertical flow, but keep the power of `gap` and alignment tools."

---

# 🧭 STEP 4 — The Header Pattern

```css
.topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
}

```

---

# 🧭 STEP 5 — Entering Grid

```css
.cards { display: grid; gap: 12px; grid-template-columns: 1fr; }

```

### 🧠 Pro-Tip

Think of `1fr` as "one fraction of the available space." If you have one column, `1fr` is 100% of the container.

---

# 🧭 STEP 6 — Expanding the Grid

```css
.cards { grid-template-columns: repeat(2, 1fr); }

```

---

# 🧭 STEP 7 — The "Smart" Grid

```css
.cards {
  display: grid;
  gap: 12px;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
}

```

### 🧠 Why this is powerful

`auto-fit` + `minmax` is the secret to responsive design. The browser calculates how many items fit in the row and automatically wraps them when space is tight.

---

# 🧭 STEP 8 & 9 — Visual Polish

Apply styles for `border-radius: 10px`, `box-shadow`, and `:hover` states to make the UI feel production-ready.

---

# 🧠 The "Hybrid" Architecture

You have built a professional-grade layout strategy:

* **Flexbox (The Framework):** Handles the "macro" layout (Sidebar/Main shell).
* **Grid (The Content):** Handles the "micro" layout (Dashboard cards).

---

# 🚀 Level 2: The Interactive Sidebar

### 1. Update your HTML

```html
<header class="topbar">
  <button id="toggle-btn">Toggle Sidebar</button>
  <h1>Dashboard</h1>
</header>

```

### 2. Add the "Collapsed" CSS

```css
.sidebar { transition: width 0.3s ease; overflow: hidden; }
.sidebar.collapsed { width: 0; padding-left: 0; padding-right: 0; }

```

### 3. Add the "Brain" (JavaScript)

```javascript
const btn = document.getElementById('toggle-btn');
const sidebar = document.querySelector('.sidebar');

btn.addEventListener('click', () => {
  sidebar.classList.toggle('collapsed');
});

```

### 🧠 Why this is a "Level 2" skill

You’ve moved from **declarative styling** (static CSS) to **imperative control** (DOM manipulation). The CSS defines the *possibility* (the animation), and the JavaScript defines the *logic* (when to trigger it).

---

**How does this flow feel for your learners?** Are you ready to dive into **Dark Mode** using CSS variables, or would you like to see how we could convert this layout into a **Reusable Component**?
