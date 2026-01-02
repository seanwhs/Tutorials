# 📘 Bootstrap 5 Tutorial

---

## 🎯 Learning Objectives

By the end of this tutorial, you will be able to:

1. Understand **what Bootstrap is** and why it’s widely used.
2. Use the **grid system** to create responsive layouts.
3. Apply **Bootstrap components** like buttons, navbars, cards, and modals.
4. Utilize **utility classes** for spacing, typography, colors, and visibility.
5. Integrate **Bootstrap with custom CSS**.
6. Build **responsive web pages quickly**.
7. Use **mental models and ASCII diagrams** to reason about layout and components.

---

# 🧠 Section 1 — What is Bootstrap?

**Bootstrap** is a **front-end CSS framework** for building responsive, mobile-first websites. It provides:

* **CSS** for typography, layout, buttons, forms, and utilities.
* **JS** for interactive components like modals, dropdowns, carousels.
* **Grid system** for responsive layouts.

**Mental Model:** Think of Bootstrap as a **toolkit** or **lego set** for web design: you don’t build from scratch, you assemble pre-built, standardized components.

**ASCII Diagram:**

```
Bootstrap Toolkit
 ├─ CSS -> Typography, Buttons, Forms
 ├─ JS  -> Modals, Carousels, Dropdowns
 └─ Grid -> Rows, Columns, Responsive Layout
```

---

# 🧠 Section 2 — Getting Started

### 2.1 Include Bootstrap

**Option 1: CDN (Quick Start)**

```html
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
```

**Option 2: Download**

* Download from [https://getbootstrap.com](https://getbootstrap.com)
* Include `bootstrap.min.css` and `bootstrap.bundle.min.js` in your project.

---

# 🧠 Section 3 — Grid System

Bootstrap uses a **12-column responsive grid**:

```
Container
 └─ Row
     ├─ Column (col-*)
     ├─ Column (col-*)
     └─ Column (col-*)
```

**Example: Three equal columns**

```html
<div class="container">
  <div class="row">
    <div class="col">Column 1</div>
    <div class="col">Column 2</div>
    <div class="col">Column 3</div>
  </div>
</div>
```

**ASCII Layout:**

```
+---------+---------+---------+
| Column1 | Column2 | Column3 |
+---------+---------+---------+
```

**Responsive Classes:**

| Class       | Breakpoint | Description       |
| ----------- | ---------- | ----------------- |
| `.col-sm-6` | ≥576px     | Half width        |
| `.col-md-4` | ≥768px     | One-third width   |
| `.col-lg-3` | ≥992px     | One-quarter width |
| `.col-xl-2` | ≥1200px    | One-sixth width   |

---

# 🧠 Section 4 — Containers

**Types of Containers:**

1. `.container` → fixed width at breakpoints
2. `.container-fluid` → full-width, spans entire viewport
3. `.container-{breakpoint}` → responsive container

**Mental Model:** Think of containers as **“boxes” that hold rows and columns**.

```
Viewport
 └─ Container
     └─ Rows
         └─ Columns
```

---

# 🧠 Section 5 — Typography & Text Utilities

```html
<h1 class="display-1">Heading 1</h1>
<p class="lead">This is a lead paragraph.</p>
<p class="text-primary">Blue text</p>
<p class="text-center">Centered text</p>
```

**ASCII Mental Model:**

```
<h1> -> Large font, bold
<p> -> Normal font
.lead -> Slightly bigger, muted
.text-* -> Color
.text-center -> Alignment
```

---

# 🧠 Section 6 — Buttons

```html
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary">Secondary</button>
<button class="btn btn-success">Success</button>
<button class="btn btn-danger">Danger</button>
```

* **Classes:** `.btn` + contextual class (`btn-primary`, `btn-secondary`)
* Can be **rounded, outlined, small, large** with additional classes: `.btn-lg`, `.btn-sm`, `.btn-outline-primary`.

---

# 🧠 Section 7 — Alerts & Cards

### Alerts

```html
<div class="alert alert-warning" role="alert">
  This is a warning alert!
</div>
```

### Cards

```html
<div class="card" style="width: 18rem;">
  <img src="avatar.png" class="card-img-top" alt="...">
  <div class="card-body">
    <h5 class="card-title">Alice</h5>
    <p class="card-text">Frontend Developer</p>
    <a href="#" class="btn btn-primary">Contact</a>
  </div>
</div>
```

**Mental Model:** Think of **cards as self-contained UI modules**.

ASCII:

```
+-------------------+
|      Image        |
|-------------------|
| Title             |
| Text              |
| [Button]          |
+-------------------+
```

---

# 🧠 Section 8 — Forms

```html
<form>
  <div class="mb-3">
    <label for="email" class="form-label">Email</label>
    <input type="email" class="form-control" id="email">
  </div>
  <div class="mb-3">
    <label for="password" class="form-label">Password</label>
    <input type="password" class="form-control" id="password">
  </div>
  <button type="submit" class="btn btn-primary">Submit</button>
</form>
```

**Key Classes:** `.form-control`, `.form-label`, `.mb-3` for spacing

---

# 🧠 Section 9 — Navbar

```html
<nav class="navbar navbar-expand-lg navbar-light bg-light">
  <a class="navbar-brand" href="#">Logo</a>
  <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navContent">
    <span class="navbar-toggler-icon"></span>
  </button>
  <div class="collapse navbar-collapse" id="navContent">
    <ul class="navbar-nav">
      <li class="nav-item"><a class="nav-link" href="#">Home</a></li>
      <li class="nav-item"><a class="nav-link" href="#">About</a></li>
      <li class="nav-item"><a class="nav-link" href="#">Contact</a></li>
    </ul>
  </div>
</nav>
```

**Mental Model:** Responsive navbar uses **collapse + toggler** → mobile-first behavior.

---

# 🧠 Section 10 — Modals & Components

### Modal

```html
<!-- Button trigger -->
<button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#myModal">Open Modal</button>

<!-- Modal -->
<div class="modal fade" id="myModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title">Modal title</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        Modal content here.
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>
```

**Mental Model:** Components encapsulate **function + style + behavior**, reusable across pages.

---

# 🧠 Section 11 — Utilities

Bootstrap has **helper classes**:

* **Spacing:** `.m-3` → margin, `.p-2` → padding
* **Display:** `.d-flex`, `.d-none`
* **Text:** `.text-center`, `.text-muted`, `.text-primary`
* **Background:** `.bg-light`, `.bg-success`
* **Borders:** `.rounded`, `.border`, `.border-primary`

---

# 🏁 Section 12 — Mini Project: Responsive Profile Page

**HTML:**

```html
<div class="container mt-5">
  <div class="row">
    <div class="col-md-4">
      <div class="card">
        <img src="avatar.png" class="card-img-top" alt="Avatar">
        <div class="card-body">
          <h5 class="card-title">Alice</h5>
          <p class="card-text">Frontend Developer</p>
          <a href="#" class="btn btn-primary">Contact</a>
        </div>
      </div>
    </div>
    <div class="col-md-8">
      <h2>About Me</h2>
      <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit...</p>
    </div>
  </div>
</div>
```

**ASCII Layout (Desktop):**

```
+----------------+--------------------------------+
|   Profile Card | About Me Content               |
|   Image+Text  | Paragraph + details            |
+----------------+--------------------------------+
```

**Mobile (<768px):**

```
+----------------+
| Profile Card   |
+----------------+
| About Me       |
| Content        |
+----------------+
```

---

# 🧾 Addendum A — Full Project Structure

```
bootstrap_project/
├── index.html
├── css/
│   └── custom.css
├── js/
│   └── custom.js
├── images/
└── README.md
```

---

# 🧾 Addendum B — Visual Cheat Sheet

```
Grid: .container > .row > .col-*
Typography: .display-*, .lead, .text-*
Buttons: .btn + contextual classes
Forms: .form-control, .form-label, .mb-3
Navbar: .navbar, .navbar-expand-lg
Utilities: .m-*, .p-*, .d-*, .bg-*, .text-*, .rounded
Components: .card, .alert, .modal
```

---


Perfect! Here’s **Addendum C — Bootstrap Functional Flow Map**. This is a **drop-in visual guide** that shows how **Bootstrap HTML, CSS, grid, components, utilities, and events** flow together using a **functional/FB pipeline mental model**.

---

# 🧾 Addendum C — Bootstrap Functional Flow Map (FB Model)

This addendum helps you **reason about Bootstrap layouts, components, and utilities** as a **step-by-step functional pipeline**, showing **input → transform → output** at every stage.

---

## 1️⃣ Core FB Flow for Bootstrap

```
User / Data / Event
         |
         v
HTML Nodes (DOM)
         |
         v
Bootstrap CSS Classes -> Pure Transformations
         |
         v
Box Model Calculation (padding, border, margin)
         |
         v
Grid / Flex / Responsive Layout
         |
         v
Components Render (Cards, Navbars, Buttons)
         |
         v
Utility Classes Applied (Spacing, Color, Text, Display)
         |
         v
JS Interactions Trigger (Modals, Dropdowns, Carousels)
         |
         v
Transitions / Animations
         |
         v
Browser Render → Screen Output
```

**Mental Model:**

* Each stage is a **pure transformation function**.
* DOM nodes remain **immutable**; CSS + JS produce the **rendered output**.
* Events trigger **new functional pipelines**, updating only necessary nodes.

---

## 2️⃣ HTML DOM Node Flow

```
<html>
 ├── <head>
 │    └── <link rel="stylesheet" href="bootstrap.min.css">
 └── <body>
      ├── <header> (Navbar)
      ├── <main> (Grid & Cards)
      └── <footer> (Text / Links)
```

**Mental Model:** DOM nodes are **data structures**, CSS classes are **functions that transform them**, and JS events are **conditional pipelines**.

---

## 3️⃣ Grid & Container Pipeline

```
Container (.container / .container-fluid)
         |
         v
Row (.row) -> defines horizontal flex
         |
         v
Columns (.col-*, .col-md-4) -> width function
         |
         v
Responsive adjustments (media query functions)
         |
         v
Final column positions → Rendered layout
```

**ASCII:**

```
Desktop:
+---------+---------+---------+
| Col 1   | Col 2   | Col 3   |
+---------+---------+---------+

Mobile (<768px):
+---------+
| Col 1   |
+---------+
| Col 2   |
+---------+
| Col 3   |
+---------+
```

---

## 4️⃣ Components Functional Pipeline

```
Component Tag (card, alert, button)
         |
         v
CSS Class Functions Applied (color, padding, border)
         |
         v
JS Interaction Binding (optional)
         |
         v
State Change -> Triggers new rendering pipeline
         |
         v
Output on screen
```

**Example: Card**

```
<div class="card">
  Image -> .card-img-top
  Body -> .card-body
    Title -> .card-title
    Text -> .card-text
    Button -> .btn
```

**Mental Model:** **Card = Pure Function**: inputs (HTML structure + classes) → output (styled box with content).

---

## 5️⃣ Utilities Functional Flow

* Spacing: `.m-3`, `.p-2`
* Text: `.text-center`, `.text-primary`
* Background: `.bg-light`, `.bg-success`
* Display: `.d-flex`, `.d-none`

**Pipeline:**

```
Node + Utility Class -> Transformation Function
          |
          v
Computed CSS property -> Applied in Box Model
          |
          v
Reflow → Repaint → Rendered Output
```

**Mental Model:** Utility classes are **pure functions applied per node**, composable with other classes.

---

## 6️⃣ JS Component & Event Pipeline

```
Event Trigger (click, hover)
         |
         v
Bootstrap JS Plugin (Modal, Carousel, Dropdown)
         |
         v
DOM Manipulation (add/remove classes, toggle attributes)
         |
         v
Transitions / Animations (frame-by-frame)
         |
         v
Final Visual State
```

**ASCII Example: Modal**

```
Click button
   |
toggle .show
   |
fade-in animation
   |
modal visible
```

---

## 7️⃣ Responsive & Media Query Pipeline

```
Viewport Width
     |
     v
Media Query Function (.col-md-*, .d-lg-block)
     |
     v
Override previous styles if breakpoint active
     |
     v
Recompute layout -> Reflow -> Browser Render
```

**Mental Model:** Think of breakpoints as **conditional functional branches** in your layout pipeline.

---

## 8️⃣ Full Bootstrap FB Flow (ASCII)

```
User/Data/Event
         |
         v
HTML DOM Nodes
         |
         v
Bootstrap CSS Classes (transform)
         |
         v
Box Model Calculation
         |
         v
Grid/Flex Layout
         |
         v
Components (Cards, Buttons, Alerts)
         |
         v
Utilities Applied (Spacing, Colors, Typography)
         |
         v
JS Components (Modals, Carousels)
         |
         v
Transitions & Animations
         |
         v
Browser Render -> Screen Output
```

**Mental Model:**

* **Input → Transform → Output** is a pure pipeline.
* Events trigger **new pipelines**, keeping rendering predictable.
* Bootstrap classes are **modular, composable functions** applied to DOM nodes.

---

## ✅ Summary

* **Addendum C** is a **drop-in functional/FB mental model map** for Bootstrap.
* Integrates **HTML, CSS, Grid, Components, Utilities, JS, Events, Responsive Design**.
* Helps you **reason visually and functionally** about **page rendering pipelines**.
* Complements **Addendums A–B (Projects & Cheat Sheets)** and **D–E (HTML/CSS FB maps)**.

---

If you want, I can create a **Mega “Full Web App Functional Flow Map”**, combining **Bootstrap, React Functional Components, DRF FB pipelines, JS events, and CSS flows** into **one single reference diagram**.

Do you want me to make that?
