# 🌐 **Key HTML & CSS Concepts**

<img width="1024" height="1536" alt="image" src="https://github.com/user-attachments/assets/93cdfc1c-542b-4789-85d8-eab0a1fc32b7" />

HTML + CSS form the **foundation of web development**. HTML defines structure, while CSS defines presentation and layout.

---

## 1. HTML: Structure & Semantics

HTML provides **semantic tags** to describe content meaning:

| Element            | Purpose / Example                        |
| ------------------ | ---------------------------------------- |
| `<header>`         | Site header, usually contains logo & nav |
| `<nav>`            | Navigation links                         |
| `<main>`           | Main content area                        |
| `<section>`        | Logical section                          |
| `<article>`        | Independent piece of content             |
| `<aside>`          | Sidebar or complementary content         |
| `<footer>`         | Footer info                              |
| `<h1> - <h6>`      | Headings hierarchy                       |
| `<p>`              | Paragraph                                |
| `<a>`              | Link, `href` attribute                   |
| `<img>`            | Images, `src` and `alt`                  |
| `<form>`           | Forms for input                          |
| `<input>`          | User input fields                        |
| `<button>`         | Clickable buttons                        |
| `<ul>` / `<ol>`    | Lists (unordered / ordered)              |
| `<div>` / `<span>` | Generic container elements               |

**Example: Semantic Layout**

```html
<header>
  <h1>My Website</h1>
  <nav>
    <ul>
      <li><a href="/">Home</a></li>
      <li><a href="/about">About</a></li>
    </ul>
  </nav>
</header>

<main>
  <section>
    <h2>Introduction</h2>
    <p>Welcome to my site.</p>
  </section>
  <aside>Related links</aside>
</main>

<footer>
  <p>&copy; 2026 My Website</p>
</footer>
```

---

## 2. CSS: Styling Basics

CSS controls **colors, fonts, spacing, and layout**:

```css
body {
  font-family: Arial, sans-serif;
  line-height: 1.6;
  background-color: #f5f5f5;
}

header {
  background-color: #333;
  color: white;
  padding: 1rem;
}

a {
  color: #007bff;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}
```

---

## 3. Box Model

Every element is a **rectangle** with 4 layers:

```
margin → border → padding → content
```

```css
div {
  width: 200px;
  padding: 10px;
  border: 5px solid black;
  margin: 20px;
}
```

* **content** → text or image
* **padding** → space inside border
* **border** → edge around padding
* **margin** → space outside the border

---

## 4. Layouts

### **4.1 Display Property**

| Display        | Description                      |
| -------------- | -------------------------------- |
| `block`        | Full width, starts on new line   |
| `inline`       | Fits content, no line break      |
| `inline-block` | Inline but respects width/height |
| `flex`         | Flexible layout container        |
| `grid`         | Two-dimensional layout           |
| `none`         | Hides element                    |

---

### **4.2 Flexbox**

```css
.container {
  display: flex;
  justify-content: space-between; /* main axis */
  align-items: center;            /* cross axis */
}

.item {
  flex: 1; /* grow/shrink */
}
```

* `justify-content` → horizontal alignment
* `align-items` → vertical alignment
* `flex-direction: row | column` → layout direction
* `flex-wrap` → wrap items if needed

---

### **4.3 Grid**

```css
.container {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-gap: 10px;
}
```

* `1fr` → fraction of available space
* `grid-template-rows` → row sizes
* `grid-gap` → spacing between items

---

## 5. Positioning

| Property   | Effect                                             |
| ---------- | -------------------------------------------------- |
| `static`   | Default                                            |
| `relative` | Offset relative to original position               |
| `absolute` | Positioned relative to nearest positioned ancestor |
| `fixed`    | Stays in viewport                                  |
| `sticky`   | Switches between relative & fixed                  |

```css
.sticky-header {
  position: sticky;
  top: 0;
  background: #fff;
}
```

---

## 6. Pseudo-Classes & Pseudo-Elements

* `:hover`, `:focus`, `:active` → element states
* `::before`, `::after` → insert content

```css
button:hover {
  background-color: #007bff;
}

p::first-letter {
  font-size: 2rem;
}
```

---

## 7. Responsive Design

* **Media Queries** → adapt to screen size

```css
@media (max-width: 768px) {
  .container {
    flex-direction: column;
  }
}
```

* Use `%`, `em`, `rem`, `vw`, `vh` for flexible sizing
* **Mobile-first** → start with small screens and expand

---

## 8. CSS Variables

```css
:root {
  --primary-color: #007bff;
  --secondary-color: #6c757d;
}

button {
  background-color: var(--primary-color);
  color: white;
}
```

* Variables help **maintain theme consistency**

---

## 9. Transitions & Animations

```css
button {
  transition: background 0.3s ease;
}

button:hover {
  background-color: #0056b3;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.fade {
  animation: fadeIn 2s forwards;
}
```

* `transition` → smooth state changes
* `animation` → keyframe-based animations

---

## 10. Real-World Example: Card Layout

```html
<div class="card">
  <img src="book.jpg" alt="Book">
  <h3>Book Title</h3>
  <p>Author: Alice</p>
  <button>Buy Now</button>
</div>
```

```css
.card {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 1rem;
  width: 250px;
  box-shadow: 0 2px 6px rgba(0,0,0,0.1);
  transition: transform 0.3s;
}

.card:hover {
  transform: translateY(-5px);
}

.card img {
  width: 100%;
  border-radius: 5px;
}
```

* Demonstrates **box model, hover effects, border-radius, shadow, and transitions**

---

## ✅ Key HTML & CSS Concepts Cheat Sheet

| Concept             | Example / Property                       | Use Case               |
| ------------------- | ---------------------------------------- | ---------------------- |
| Semantic HTML       | `<header>`, `<section>`, `<footer>`      | Accessibility & SEO    |
| Box Model           | `margin`, `padding`, `border`, `content` | Layout calculation     |
| Display & Layout    | `flex`, `grid`                           | Responsive layout      |
| Positioning         | `relative`, `absolute`, `sticky`         | Fine-tuned positioning |
| Typography & Colors | `font-family`, `color`, `line-height`    | Styling text           |
| Pseudo-classes      | `:hover`, `:focus`                       | Interactive states     |
| Pseudo-elements     | `::before`, `::after`                    | Decorative content     |
| Media Queries       | `@media (max-width: 768px)`              | Responsive design      |
| Variables           | `--primary-color`                        | Theme consistency      |
| Transitions / Anim  | `transition`, `@keyframes`               | Smooth animations      |

---

# 🖼️ **HTML & CSS Power Map – Diagram Layout**

---

### **1. Top-Level Structure**

```
[HTML Document]
       |
       v
[Head] ----> [Meta, Title, Link to CSS / JS]
       |
       v
[Body]
       |
   --------------------------
   |           |            |
[Header]     [Main]       [Footer]
   |           |            |
[Nav, Logo] [Sections, Articles, Aside] [Copyright, Links]
```

* **Head** → Metadata, CSS links, fonts
* **Body** → Visible content, semantic structure
* **Semantic elements** → `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<aside>`, `<footer>`

**Optional icons:** page icon for document, gears for meta, text boxes for sections

---

### **2. Box Model Layer**

```
[Content]
   ↑
[Padding]
   ↑
[Border]
   ↑
[Margin]
```

* Shows **content spacing & layout principles**
* Can have a side note with CSS properties: `padding`, `border`, `margin`, `width`, `height`

**Color coding:**

* Content → light green
* Padding → light blue
* Border → dark blue
* Margin → light yellow

---

### **3. Layout Techniques**

* **Flexbox** → 1D layout
* **Grid** → 2D layout

**Diagram arrows:**

```
[Container: display:flex]
    ├─ justify-content → horizontal alignment
    └─ align-items → vertical alignment
[Flex Items] → grow/shrink/flex
```

```
[Container: display:grid]
    ├─ grid-template-columns → column layout
    ├─ grid-template-rows → row layout
    └─ grid-gap → spacing
[Grid Items] → positioned in cells
```

---

### **4. Positioning Layer**

```
[Element]
   |
   +-- static (default)
   +-- relative (offset from normal position)
   +-- absolute (positioned relative to nearest ancestor)
   +-- fixed (stays in viewport)
   +-- sticky (switches relative ↔ fixed)
```

* Include arrow to **example usage**: sticky header at top

---

### **5. Styling & Visuals**

* **Typography:** font-family, font-size, font-weight, line-height
* **Colors:** color, background-color, border-color
* **Decorative:** border-radius, box-shadow, gradients

**Icons / side notes:** paintbrush icon for styling

---

### **6. Pseudo-classes & Elements**

```
[Element]
   ├─ :hover → state on mouse over
   ├─ :focus → state on focus
   ├─ :active → state on click
   ├─ ::before → insert content before element
   └─ ::after → insert content after element
```

---

### **7. Responsive Design**

```
[CSS @media Queries]
   ├─ max-width: 768px → mobile
   ├─ max-width: 1024px → tablet
   └─ default → desktop
```

* Arrows to **container / layout** showing change in flex direction or grid columns
* Note: Use `%`, `em`, `rem`, `vw`, `vh` for flexible sizing

---

### **8. Transitions & Animations**

```
[Element]
   ├─ transition → smooth state change
   └─ @keyframes → animation over time
```

* Example: hover button color change
* Example: fade-in card on load

---

### **9. Color Coding (Recommended)**

* **HTML Structure** → Blue
* **Box Model / Layout** → Green
* **Positioning** → Orange
* **Styling (Typography, Colors, Shadows)** → Purple
* **Responsive / Media Queries** → Yellow
* **Transitions / Animations** → Pink

---

### **10. Suggested Layout for Diagram**

```
          [HTML Document]
                 |
        ---------------------
        |                   |
      [Head]               [Body]
                             |
           ---------------------------------
           |               |               |
        [Header]         [Main]          [Footer]
           |               |               |
         Nav/Logo   Sections / Article    Links / Info
           |
       [Box Model Layer] → Padding/Border/Margin
           |
       [Layout Layer] → Flex/Grid
           |
       [Positioning Layer] → static/relative/absolute/sticky
           |
       [Styling Layer] → Typography / Colors / Shadows
           |
       [Pseudo-classes / Elements]
           |
       [Responsive Media Queries]
           |
       [Transitions / Animations]
```

---

