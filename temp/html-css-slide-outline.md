# HTML & CSS Fundamentals

## Slide Deck Outline (Based on Smoljames HTML & CSS Notes)

**Source:** [Smoljames HTML & CSS Notes](https://smoljames.com/notes/html_css?utm_source=chatgpt.com)
**Companion Course:** [HTML & CSS Full Course](https://smoljames.com/courses/html-css-course?utm_source=chatgpt.com)

---

# Slide 1 — Course Introduction

## HTML & CSS: The Foundation of the Web

### Key Message

* Every website is built upon HTML and CSS
* HTML provides structure
* CSS provides presentation and styling
* Together they form the foundation of frontend development

### Learning Objectives

* Understand HTML document structure
* Create multi-page websites
* Style pages using CSS
* Build responsive and visually appealing interfaces

### Quote

> "HTML defines what exists. CSS defines how it looks."

*Speaker Notes: Emphasize that HTML and CSS are the entry point into all web development.* ([smoljames.com][1])

---

# Slide 2 — Understanding HTML

## What is HTML?

### HTML = HyperText Markup Language

### Important Distinction

HTML is:

* A markup language
* Not a programming language

### HTML Describes:

* Text
* Images
* Links
* Forms
* Sections
* Pages

### Analogy

Think of HTML as:

> A structured digital document that browsers understand.

### Core Responsibility

Create the content and structure of a webpage. ([smoljames.com][1])

---

# Slide 3 — Creating Your First HTML File

## HTML Document Creation

### File Extension

```text
index.html
```

### Project Structure

```text
project/
├── index.html
├── about.html
└── contact.html
```

### Key Rule

* `index.html` is the default page
* Additional HTML files become subpages

### Discussion

How browsers locate and render HTML files. ([smoljames.com][1])

---

# Slide 4 — HTML Document Anatomy

## Basic HTML Boilerplate

### Core Elements

```html
<!DOCTYPE html>
<html>
<head>
    <title>My Website</title>
</head>
<body>
</body>
</html>
```

### Purpose of Each Tag

| Tag     | Purpose           |
| ------- | ----------------- |
| DOCTYPE | HTML5 declaration |
| html    | Root element      |
| head    | Metadata          |
| title   | Browser tab title |
| body    | Visible content   |

### Learning Outcome

Every webpage follows this foundational structure. ([smoljames.com][1])

---

# Slide 5 — Common HTML Tags

## Essential HTML Elements

### Content Tags

* `<h1>` to `<h6>`
* `<p>`
* `<span>`
* `<div>`

### Media Tags

* `<img>`

### Navigation Tags

* `<a>`

### Form Tags

* `<form>`
* `<input>`
* `<button>`
* `<label>`

### Semantic Layout Tags

* `<header>`
* `<main>`
* `<section>`
* `<footer>`

### Principle

Choose tags based on meaning, not appearance. ([smoljames.com][1])

---

# Slide 6 — HTML Attributes

## Adding Behavior and Metadata

### Examples

```html
<input type="email">
```

```html
<img src="profile.png">
```

```html
<a href="about.html">
```

### Common Attributes

* id
* class
* href
* src
* type
* placeholder

### Key Idea

Attributes provide additional information about an element. ([smoljames.com][1])

---

# Slide 7 — IDs vs Classes

## Organizing HTML Elements

### Class

```html
<div class="card">
```

* Reusable
* Shared across many elements

### ID

```html
<input id="userInput">
```

* Unique
* Used once per page

### Rule of Thumb

* Classes for groups
* IDs for individual elements

### Multiple Classes

```html
<form class="sectionForm section">
```

One element can belong to multiple classes. ([smoljames.com][1])

---

# Slide 8 — HTML Comments

## Documenting Your Code

### Syntax

```html
<!-- This is a comment -->
```

### Why Use Comments?

* Explain logic
* Leave notes
* Improve maintainability

### Best Practice

Comment intent, not obvious code. ([smoljames.com][1])

---

# Slide 9 — Building a Single Page Website

## Putting HTML Together

### Example Components

* Header
* Form
* Input fields
* Button
* Content section
* Footer

### Architectural Thinking

```text
Page
├── Header
├── Main
│   ├── Form
│   └── Content
└── Footer
```

### Key Lesson

Pages are compositions of semantic sections. ([smoljames.com][1])

---

# Slide 10 — Multi-Page Websites

## Navigation with Anchor Tags

### Example

```html
<a href="/about.html">About Me</a>
```

### Browser Behavior

* Loads another HTML file
* Creates website navigation
* Enables application structure

### Typical Website

```text
Home
About
Contact
Products
Services
```

### Concept

HTML alone can build complete multi-page websites. ([smoljames.com][1])

---

# Slide 11 — Introducing CSS

## What is CSS?

### CSS = Cascading Style Sheets

### Responsibility

Controls:

* Colors
* Typography
* Layout
* Spacing
* Visual appearance

### Why CSS Exists

Without CSS:

```html
<h1 style="color:red">
```

With CSS:

```css
h1 {
  color:red;
}
```

### Benefit

Separation of structure and presentation. ([smoljames.com][1])

---

# Slide 12 — Creating a CSS File

## External Stylesheets

### File Structure

```text
project/
├── index.html
└── styles.css
```

### Benefits

* Reusable
* Organized
* Maintainable

### Industry Standard

Separate HTML and CSS into dedicated files. ([smoljames.com][1])

---

# Slide 13 — Linking CSS to HTML

## Connecting the Files

### Inside `<head>`

```html
<link rel="stylesheet" href="styles.css">
```

### Browser Process

1. Load HTML
2. Discover stylesheet
3. Download CSS
4. Apply styles

### Result

HTML gains visual presentation. ([smoljames.com][1])

---

# Slide 14 — CSS Selectors

## Selecting Elements

### Tag Selector

```css
h1 {
  color: green;
}
```

### Class Selector

```css
.sectionContainer {
}
```

### ID Selector

```css
#userInput {
}
```

### Selector Hierarchy

```text
Tag
  ↓
Class
  ↓
ID
```

More specific selectors take precedence. ([smoljames.com][1])

---

# Slide 15 — CSS Specificity

## Which Style Wins?

### Example

```css
h1 {
 color: blue;
}

.title {
 color: red;
}

#mainTitle {
 color: green;
}
```

### Specificity Order

1. ID Selector
2. Class Selector
3. Tag Selector

### Key Principle

More specific rules override less specific rules. ([smoljames.com][1])

---

# Slide 16 — Multiple Selectors

## Reusing Styles Efficiently

### Example

```css
.headerText,
h3,
#firstInput {
  color: green;
}
```

### Benefit

* Less duplication
* Easier maintenance
* Consistent design

### Principle

DRY (Don't Repeat Yourself). ([smoljames.com][1])

---

# Slide 17 — CSS Comments

## Documenting Styles

### Syntax

```css
/* This is a CSS comment */
```

### Uses

* Explain design choices
* Group sections
* Improve readability

### Best Practice

Comment sections, not individual properties. ([smoljames.com][1])

---

# Slide 18 — CSS Categories

## Three Major Style Categories

### 1. Dimensional Styles

Size and spacing

### 2. Design Styles

Visual appearance

### 3. Placement Styles

Layout and positioning

### Mental Model

```text
What size?
↓
How should it look?
↓
Where should it go?
```

([smoljames.com][1])

---

# Slide 19 — Dimensional Styles

## Size and Spacing

### Common Properties

```css
width
height
max-width
max-height
padding
margin
```

### Important Concept

Padding:

```text
Inside Space
```

Margin:

```text
Outside Space
```

### Responsive Principle

Prefer relative sizing where possible. ([smoljames.com][1])

---

# Slide 20 — Design Styles

## Making Interfaces Beautiful

### Typography

```css
font-family
font-size
font-weight
color
text-align
```

### Containers

```css
background
border
border-radius
box-shadow
opacity
transition
transform
```

### Goal

Improve readability and user experience. ([smoljames.com][1])

---

# Slide 21 — Placement Styles

## Positioning Elements

### Position

```css
relative
absolute
fixed
```

### Display

```css
flex
grid
none
```

### Layering

```css
z-index
```

### Question

Where should content appear on the screen? ([smoljames.com][1])

---

# Slide 22 — Flexbox Fundamentals

## Modern Layout System

### Flex Container

```css
display: flex;
```

### Common Properties

```css
flex-direction
justify-content
align-items
gap
```

### Mental Model

```text
1-D Layout System
```

Arrange items:

* Horizontally
* Vertically

### Industry Importance

Flexbox is the most commonly used layout system. ([smoljames.com][1])

---

# Slide 23 — Grid Layout Fundamentals

## Two-Dimensional Layouts

### Enable Grid

```css
display: grid;
```

### Best For

* Dashboards
* Galleries
* Complex layouts
* Structured interfaces

### Comparison

| Flexbox    | Grid          |
| ---------- | ------------- |
| 1D         | 2D            |
| Row/Column | Full Layout   |
| Simpler    | More Powerful |

([smoljames.com][1])

---

# Slide 24 — Mini Project Architecture

## Build a Personal Portfolio

### Features

* Header
* Navigation
* About Section
* Skills Section
* Contact Form
* Footer

### Skills Applied

✓ HTML Structure
✓ Semantic Tags
✓ CSS Styling
✓ Flexbox Layout
✓ Navigation Links

### Deliverable

A professional developer portfolio. ([smoljames.com][2])

---

# Slide 25 — Final Summary

## HTML + CSS Mastery Roadmap

### HTML

* Structure
* Content
* Semantics

### CSS

* Styling
* Layout
* Responsiveness

### Core Concepts

```text
HTML → Structure
CSS → Presentation
JavaScript → Behavior
```

### Key Takeaway

> Learn HTML and CSS thoroughly before moving into JavaScript frameworks such as React.

### Next Steps

* Responsive Design
* Flexbox & Grid Mastery
* JavaScript Fundamentals
* Modern Frontend Development ([smoljames.com][1])

---

## References

* [Smoljames HTML & CSS Notes](https://smoljames.com/notes/html_css?utm_source=chatgpt.com)
* [Smoljames HTML & CSS Full Course](https://smoljames.com/courses/html-css-course?utm_source=chatgpt.com)
* [Smoljames Developer Roadmap](https://roadmap.smoljames.com/?utm_source=chatgpt.com)

[1]: https://smoljames.com/notes/html_css?utm_source=chatgpt.com "Smoljames ⋅ Notes"
[2]: https://smoljames.com/courses/html-css-course?utm_source=chatgpt.com "Smoljames ⋅ Courses"
