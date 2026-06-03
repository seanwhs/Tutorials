# 🎨 FlexGrid Studio — Incremental Layout Builder

We are going to build a **mini SaaS dashboard UI** step by step. We will *slowly evolve it* into a real layout system using **Flexbox** for alignment and **Grid** for structure.

---

# 🧰 Base Setup (Start Here)

## 📄 index.html

```html
<!DOCTYPE html>
<html>
<head>
  <title>FlexGrid Dashboard</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <div class="app">
    <aside class="sidebar">
      <h2>FlexGrid</h2>
      <a href="#">Overview</a>
      <a href="#">Stats</a>
      <a href="#">Settings</a>
    </aside>
    <main class="main">
      <header class="topbar">
        <button id="toggle-btn">Toggle Sidebar</button>
        <h1>Dashboard</h1>
      </header>
      <section class="cards">
        <div class="card">Revenue</div>
        <div class="card">Users</div>
        <div class="card">Orders</div>
        <div class="card">Growth</div>
      </section>
    </main>
  </div>
  <script src="script.js"></script>
</body>
</html>

```

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

---

# 🧭 STEP 2 — The Layout Shift (Flexbox)

```css
.app { display: flex; min-height: 100vh; }
.sidebar { width: 220px; }

```

---

# 🧭 STEP 3 — Vertical Systems

```css
.sidebar { display: flex; flex-direction: column; gap: 12px; }

```

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

---

# 🧭 STEP 8 & 9 — Visual Polish

```css
.card {
  background: white;
  padding: 16px;
  border-radius: 10px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
}
.sidebar a { color: #cbd5e1; text-decoration: none; }
.sidebar a:hover { color: white; }

```

---

# 🚀 Level 2: The Interactive Sidebar

### 📄 script.js (The Brain)

```javascript
const btn = document.getElementById('toggle-btn');
const sidebar = document.querySelector('.sidebar');

btn.addEventListener('click', () => {
  sidebar.classList.toggle('collapsed');
});

```

### 📄 style.css (The Animation)

```css
.sidebar { transition: width 0.3s ease; overflow: hidden; }
.sidebar.collapsed { width: 0; padding-left: 0; padding-right: 0; }

```

---

**How does this flow feel for your learners?** Are you ready to dive into **Dark Mode** using CSS variables, or would you like to see how we could convert this layout into a **Reusable Component**?
