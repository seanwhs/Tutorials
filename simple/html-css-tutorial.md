# 📘 HTML & CSS Mastery Tutorial — Textbook Style

---

## 🎯 Learning Objectives

By the end of this tutorial, you will be able to:

1. Understand the **structure of HTML documents** and semantic tags.
2. Use **text, links, images, and multimedia** effectively.
3. Style content using **CSS selectors, properties, and units**.
4. Apply **layouts**: box model, flexbox, CSS grid.
5. Make **responsive designs** for multiple devices.
6. Add **animations, transitions, and hover effects**.
7. Build **projects** combining HTML & CSS.
8. Use **mental models** and **ASCII diagrams** to reason about page structure and layout.

---

# 🧠 Section 1 — Introduction to HTML

HTML (**HyperText Markup Language**) is the **skeleton of the web**. It defines **content and structure**, not style.

### Basic HTML Document Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Page</title>
</head>
<body>
    <h1>Hello, World!</h1>
    <p>This is my first HTML page.</p>
</body>
</html>
```

**Mental Model: Document Tree**

```
<html>
 ├── <head> -> Metadata, title, links
 └── <body> -> Content (text, images, links, etc.)
```

---

# 🧠 Section 2 — HTML Elements & Semantic Tags

HTML elements can be **block-level** or **inline**. Semantic tags give meaning to content.

### Common Semantic Tags:

* `<header>`: Page header
* `<footer>`: Page footer
* `<nav>`: Navigation links
* `<main>`: Main content
* `<section>`: Thematic grouping
* `<article>`: Standalone content

**Example:**

```html
<header>
    <h1>My Blog</h1>
    <nav>
        <a href="#home">Home</a>
        <a href="#about">About</a>
    </nav>
</header>
<main>
    <article>
        <h2>Post Title</h2>
        <p>Post content goes here.</p>
    </article>
</main>
<footer>
    <p>© 2026 My Blog</p>
</footer>
```

ASCII Tree:

```
<html>
 ├─ <header>
 │    ├─ <h1>
 │    └─ <nav>
 │         ├─ <a>
 │         └─ <a>
 ├─ <main>
 │    └─ <article>
 │         ├─ <h2>
 │         └─ <p>
 └─ <footer>
      └─ <p>
```

---

# 🧠 Section 3 — HTML Text & Links

```html
<p>This is <strong>bold</strong> and <em>italic</em> text.</p>
<a href="https://example.com" target="_blank">Visit Example</a>
```

**Mental Model:**

* `<p>` → paragraph container
* `<strong>` → emphasizes importance
* `<em>` → emphasizes semantics
* `<a>` → navigation or hyperlink

---

# 🧠 Section 4 — Images, Lists & Multimedia

```html
<!-- Images -->
<img src="image.jpg" alt="Descriptive text" width="300">

<!-- Ordered List -->
<ol>
    <li>First item</li>
    <li>Second item</li>
</ol>

<!-- Unordered List -->
<ul>
    <li>Item A</li>
    <li>Item B</li>
</ul>

<!-- Video -->
<video controls>
    <source src="video.mp4" type="video/mp4">
</video>
```

---

# 🧠 Section 5 — Introduction to CSS

CSS (**Cascading Style Sheets**) controls the **appearance** of HTML. It is a **layer of styling** applied to your content.

### Inline, Internal, External

```html
<!-- Inline -->
<p style="color: red;">Red text</p>

<!-- Internal -->
<style>
p { color: blue; }
</style>

<!-- External -->
<link rel="stylesheet" href="styles.css">
```

---

# 🧠 Section 6 — Selectors

### Types of CSS Selectors

* **Element selector:** `p { color: blue; }`
* **Class selector:** `.highlight { background: yellow; }`
* **ID selector:** `#main-title { font-size: 2rem; }`
* **Attribute selector:** `[type="text"] { border: 1px solid gray; }`
* **Pseudo-classes:** `a:hover { color: red; }`

**Mental Model:** Selectors **target elements in the DOM tree** for styling.

---

# 🧠 Section 7 — Box Model

Every element is a **rectangle**:

```
+-----------------------------+
|          Margin             |
|  +-----------------------+  |
|  |       Border          |  |
|  |  +----------------+  |  |
|  |  |   Padding      |  |  |
|  |  |  +----------+  |  |  |
|  |  |  | Content  |  |  |  |
|  |  |  +----------+  |  |  |
|  |  +----------------+  |  |
|  +-----------------------+  |
+-----------------------------+
```

CSS Example:

```css
p {
    margin: 10px;
    padding: 5px;
    border: 2px solid black;
}
```

---

# 🧠 Section 8 — Layout: Flexbox

Flexbox allows **responsive, one-dimensional layouts**.

```css
.container {
    display: flex;
    justify-content: space-between; /* horizontal alignment */
    align-items: center;           /* vertical alignment */
}
```

HTML:

```html
<div class="container">
    <div>Item 1</div>
    <div>Item 2</div>
</div>
```

ASCII:

```
[Item 1]       [Item 2]
```

---

# 🧠 Section 9 — Layout: Grid

CSS Grid allows **two-dimensional layouts**.

```css
.grid-container {
    display: grid;
    grid-template-columns: 1fr 2fr;
    gap: 10px;
}
```

HTML:

```html
<div class="grid-container">
    <div>Sidebar</div>
    <div>Main content</div>
</div>
```

ASCII:

```
+---------+----------------+
| Sidebar | Main content   |
+---------+----------------+
```

---

# 🧠 Section 10 — Responsive Design

Use **media queries**:

```css
body {
    font-size: 16px;
}

@media (max-width: 600px) {
    body {
        font-size: 14px;
    }
}
```

* FB Mental Model: Adapt **style transformations** based on device characteristics.

---

# 🧠 Section 11 — Colors, Fonts, and Units

```css
body {
    color: #333;          /* hex color */
    background-color: rgb(240,240,240);
    font-family: Arial, sans-serif;
    font-size: 1rem;
    line-height: 1.5;
}
```

Units: `px`, `em`, `rem`, `%`, `vw`, `vh`.

---

# 🧠 Section 12 — Transitions & Animations

### CSS Transition

```css
button {
    background-color: blue;
    transition: background-color 0.3s ease;
}

button:hover {
    background-color: green;
}
```

### CSS Animation

```css
@keyframes move {
    0% { transform: translateX(0); }
    100% { transform: translateX(100px); }
}

.box {
    width: 50px;
    height: 50px;
    background: red;
    animation: move 2s infinite alternate;
}
```

---

# 🏁 Section 13 — Mini Project: Personal Profile Card

```html
<div class="card">
    <img src="avatar.png" alt="Avatar">
    <h2>Alice</h2>
    <p>Frontend Developer</p>
</div>
```

```css
.card {
    width: 200px;
    padding: 20px;
    border: 2px solid #ccc;
    border-radius: 10px;
    text-align: center;
    box-shadow: 2px 2px 5px rgba(0,0,0,0.2);
}

.card img {
    width: 100px;
    border-radius: 50%;
}
```

**ASCII Layout:**

```
+--------------------+
|       Avatar       |
|       Alice        |
| Frontend Developer |
+--------------------+
```

---

# 🧾 Addendum A — Full Project Structure

```
html_css_project/
├── index.html
├── styles.css
├── images/
└── README.md
```

---

# 🧾 Addendum B — Visual Cheat Sheet

```
HTML -> Structure & Semantics
    <header>, <footer>, <main>, <article>, <section>, <p>, <a>, <img>, <ul>/<ol>

CSS -> Styling & Layout
    Selectors: element, class, ID, pseudo-classes
    Box Model: margin, border, padding, content
    Layout: Flexbox, Grid
    Responsive: media queries
    Fonts, colors, units
    Transitions / Animations
```

---

# 🧾 Addendum C — Advanced Layout & Responsive Example

**HTML:**

```html
<div class="grid">
    <div class="sidebar">Sidebar</div>
    <div class="main">Main Content</div>
    <div class="footer">Footer</div>
</div>
```

**CSS (Responsive Grid):**

```css
.grid {
    display: grid;
    grid-template-columns: 1fr 3fr;
    gap: 10px;
}

@media(max-width: 600px) {
    .grid {
        grid-template-columns: 1fr;
    }
}
```

**ASCII Diagram:**

```
Desktop:     +---------+----------------+
             | Sidebar | Main Content   |
             +---------+----------------+
             | Footer  | Footer         |
Mobile:      +------------------------+
             | Sidebar                |
             | Main Content           |
             | Footer                 |
             +------------------------+
```

---

# 🧾 Addendum D — HTML & CSS Full Visual Flow Map

This addendum gives a **bird’s-eye view of how HTML elements and CSS styles flow together**, helping you **reason about page structure, styling, and layout visually**.

---

## 1️⃣ DOM Tree Flow

```
<html lang="en">
 ├── <head>
 │    ├── <meta charset="UTF-8">
 │    ├── <meta name="viewport">
 │    ├── <title>Page Title</title>
 │    └── <link rel="stylesheet" href="styles.css">
 └── <body>
      ├── <header>
      │     ├── <h1>Title</h1>
      │     └── <nav>
      │          ├── <a href="#">Home</a>
      │          └── <a href="#">About</a>
      ├── <main>
      │     ├── <section>
      │     │     ├── <h2>Section Title</h2>
      │     │     └── <p>Paragraph</p>
      │     └── <article>
      │           ├── <h2>Article Title</h2>
      │           └── <p>Article content</p>
      └── <footer>
            └── <p>Footer content</p>
```

**Mental Model:**

* Each HTML tag is a **node in the DOM tree**.
* Nested elements inherit some styles unless overridden.

---

## 2️⃣ CSS Cascade Flow

```
Inline style > Internal <style> > External stylesheet
           |
           v
      Applied to element
           |
           v
   Properties cascade down
           |
           v
Specificity & !important resolve conflicts
```

**Example:**

```html
<p style="color:red;">Text</p>
<p class="highlight">Text</p>
```

```css
p { color: blue; }
.highlight { color: green; }
```

**Result:**

* Inline style (`red`) > class (`green`) > element (`blue`) → Text is **red**.

---

## 3️⃣ Box Model Flow

```
+-----------------------------+
|          Margin             |
|  +-----------------------+  |
|  |       Border          |  |
|  |  +----------------+  |  |
|  |  |   Padding      |  |  |
|  |  |  +----------+  |  |  |
|  |  |  | Content  |  |  |  |
|  |  |  +----------+  |  |  |
|  |  +----------------+  |  |
|  +-----------------------+  |
+-----------------------------+
```

* Every element occupies **content → padding → border → margin** space.
* Layout tools like **flex/grid** position boxes relative to each other.

---

## 4️⃣ Flexbox Flow

```
Container: display: flex;
 ├─ justify-content → horizontal alignment
 ├─ align-items → vertical alignment
 └─ flex-direction → row / column
```

ASCII:

```
Row layout: [Item1][Item2][Item3]
Column layout:
[Item1]
[Item2]
[Item3]
```

**Mental Model:** Treat the container as a **1D data pipeline** arranging items along a line.

---

## 5️⃣ CSS Grid Flow

```
Container: display: grid;
 ├─ grid-template-columns / rows
 ├─ gap → spacing
 └─ grid-area → placement
```

ASCII:

```
+---------+----------------+
| Sidebar | Main Content   |
+---------+----------------+
| Footer  | Footer         |
+---------+----------------+
```

* Grid allows **2D layout**: rows + columns simultaneously.

---

## 6️⃣ Responsive Design Flow

```
Device width -> Media query -> Adjust layout & font sizes -> Rendered result
```

ASCII:

```
Desktop (>600px):
+---------+----------------+
| Sidebar | Main Content   |
+---------+----------------+
| Footer  | Footer         |

Mobile (<600px):
+------------------------+
| Sidebar                |
| Main Content           |
| Footer                 |
+------------------------+
```

* **Mental Model:** Think of breakpoints as **conditional pipelines** transforming the layout based on viewport width.

---

## 7️⃣ Styling Pipeline Flow

```
Selector targets element
       |
       v
Styles applied (color, font, background)
       |
       v
Box model calculated (padding, border, margin)
       |
       v
Positioning applied (normal flow, flex, grid)
       |
       v
Transformations (translate, rotate, scale)
       |
       v
Transitions & Animations
       |
       v
Rendering on screen
```

**Example Pipeline:**

```
<p class="highlight">Hello</p>
   |
Class .highlight -> background yellow
   |
Padding + Margin + Border calculated
   |
Flex container adjusts position
   |
Hover -> transition changes background to green
```

---

## 8️⃣ Transitions & Animations Flow

```
Event triggers -> CSS property changes -> Browser interpolates values -> Frame-by-frame rendering -> Smooth visual effect
```

ASCII:

```
Hover button
   |
transition: background 0.3s
   |
Start: blue
   |
Intermediate: gradient colors
   |
End: green
```

* FB Mental Model: **Input event → pure transformation → output frame**.

---

## 9️⃣ Full Page Layout Map (ASCII)

```
<html>
 ├── <head>
 │    └── <meta>, <title>, <link>
 └── <body>
      ├── <header>
      │     ├── Logo
      │     └── Navigation
      ├── <main>
      │     ├── Sidebar (grid/flex)
      │     └── Content (grid/flex)
      └── <footer>
```

**CSS Flow:**

```
Global styles -> Element / Class / ID selectors -> Box model -> Layout (flex/grid) -> Media queries -> Transitions / Animations
```

**Mental Model:** Think of HTML as **data nodes** and CSS as **transformations applied step-by-step** to produce the final rendered screen.

---

# 🧾 Addendum E — HTML & CSS FB Functional Flow Map

This addendum shows **how data flows from HTML → CSS → browser rendering** using **functional thinking**: pure transformations, composable pipelines, and event-driven changes.

---

## 1️⃣ Core FB Flow for HTML & CSS

```
Input: User / Data / Browser event
         |
         v
HTML Nodes (DOM tree)
         |
         v
CSS Transformations (pure functions on nodes)
         |
         v
Box Model Calculations
         |
         v
Layout Engine (Flex/Grid / Positioning)
         |
         v
Responsive Adjustments (Media Queries)
         |
         v
Transitions / Animations (Event-driven pipeline)
         |
         v
Output: Rendered page on screen
```

**Mental Model:**

* Each stage is a **pure function** (except events/IO).
* **DOM nodes** are immutable references — CSS transforms create **rendered output**, not original structure.
* **Events** trigger functional pipelines (hover, click, resize).

---

## 2️⃣ DOM & CSS Flow Pipeline (ASCII)

```
<html>
 ├── <head> -> metadata, links -> CSS
 └── <body>
      ├── <header> -> Logo + Nav
      ├── <main>
      │     ├── Sidebar
      │     └── Content
      └── <footer>
```

CSS Pipeline:

```
Selector targets node
       |
       v
Apply properties (color, font, background)
       |
       v
Compute Box Model (padding, border, margin)
       |
       v
Position via Flex/Grid / normal flow
       |
       v
Media queries adjust properties dynamically
       |
       v
Transitions / Animations applied
       |
       v
Rendered visually in browser
```

---

## 3️⃣ Event-Driven Pipeline

```
User Event (click/hover/resize)
         |
         v
Event Listener / JS Handler
         |
         v
Update CSS class / inline style / DOM property
         |
         v
Pipeline: Recalculate Box Model → Reflow → Repaint → Composite
         |
         v
Screen updates smoothly
```

**Example: Hover button with transition**

```
<button>Hover Me</button>
   |
:hover event triggers
   |
transition: background 0.3s
   |
Start: blue
   |
Intermediate: gradient / blended frames
   |
End: green
```

---

## 4️⃣ Flexbox Functional Flow

```
Container -> display: flex
     |
     v
Flex items evaluated → main-axis alignment
     |
     v
Cross-axis alignment
     |
     v
Gap / spacing applied
     |
     v
Final positions rendered
```

ASCII:

```
Horizontal row layout:
[Item1] [Item2] [Item3]

Vertical column layout:
[Item1]
[Item2]
[Item3]
```

---

## 5️⃣ Grid Functional Flow

```
Container -> display: grid
     |
     v
Grid-template-columns/rows define slots
     |
     v
Items assigned to grid-areas
     |
     v
Gap / alignment applied
     |
     v
Final positions rendered
```

ASCII:

```
Desktop:       +---------+----------------+
               | Sidebar | Main Content   |
               +---------+----------------+
               | Footer  | Footer         |

Mobile (<600px):
+------------------------+
| Sidebar                |
| Main Content           |
| Footer                 |
+------------------------+
```

---

## 6️⃣ Composed Layout + Event Pipeline

```
Input HTML Nodes
        |
CSS Transformations (FB style)
        |
Layout Calculation (Box Model + Flex/Grid)
        |
Media Query Adjustments (Responsive)
        |
Event Trigger (click/hover)
        |
Dynamic Update (CSS class / JS style change)
        |
Reflow & Repaint
        |
Browser Render
```

**Mental Model:**

* Think of **CSS transformations as pure functions** applied to nodes.
* **Events trigger new pipelines**, which are **isolated and predictable**.
* **Responsive design** is a conditional functional branch.

---

## 7️⃣ Transitions & Animations Functional Pipeline

```
State Change (hover/click)
      |
      v
CSS Transition / Animation -> intermediate frames
      |
      v
Frame-by-frame interpolation (linear / ease-in / cubic)
      |
      v
Repaint each frame
      |
      v
Final rendered visual state
```

**Example: Card hover effect**

```
.card { transform: scale(1); transition: transform 0.3s; }
.card:hover -> scale(1.1)
Intermediate frames -> smooth scaling
Final -> 1.1
```

---

## 8️⃣ Full Page Functional Flow Diagram (ASCII)

```
User Input / Event
       |
       v
HTML DOM Nodes (immutable)
       |
       v
CSS Transformations (pure, composable)
       |
       v
Box Model & Layout Engine
       |
       v
Flex/Grid / Normal Flow
       |
       v
Media Query Adjustments (Responsive)
       |
       v
Transitions / Animations
       |
       v
Browser Render -> Visual Output
```

**Notes:**

* FB Mental Model: **Input → Transform → Output**
* **Immutable nodes** + **pure style functions** = predictable rendering
* **Events** = triggers for new functional pipelines

---

✅ **Addendum E Summary**

* Combines **HTML structure, CSS styling, layout, responsive design, events, and transitions** in a **single functional pipeline view**.
* Acts as a **drop-in reference** to visualize **how content flows from code to rendered page**.
* Complements **Addendums A–D**, completing the **mental model stack** for mastering HTML & CSS with **functional thinking**.

---



