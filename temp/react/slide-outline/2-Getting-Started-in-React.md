# 📘 Slide Outline: Getting Started with React

---

## Slide 1: Title

**Getting Started with React**

* Introduction to React fundamentals
* JSX, rendering, and UI building basics

---

## Slide 2: Prerequisites

Before learning React, you should know:

* HTML (structure of web pages)
* CSS (styling)
* JavaScript (logic & interactivity)

---

## Slide 3: What is React?

* React is a **JavaScript library for building user interfaces**
* Created by Facebook (2013)
* Used for building **single-page applications (SPA)**
* Focuses on **reusable UI components**

---

## Slide 4: Key Features of React

* Fast and efficient UI updates
* Component-based architecture
* Reusable components
* Large ecosystem and community
* Open-source
* High demand in job market

---

## Slide 5: What is a Single Page Application (SPA)?

* Only one HTML page
* Content updates dynamically without full page reload
* React manages UI updates efficiently

---

## Slide 6: React and the DOM

* Traditional web apps manipulate the DOM directly
* React uses a **Virtual DOM**
* Only updates the parts of the UI that change
* Improves performance and efficiency

---

## Slide 7: Introduction to JSX

* JSX = JavaScript XML
* Allows writing HTML-like syntax in JavaScript
* Makes UI structure easier to read and write
* Example:

```js
const element = <h1>Hello React</h1>
```

---

## Slide 8: JSX is Not HTML

* JSX is a mix of JavaScript + HTML-like syntax
* It is not valid HTML or pure JavaScript
* Must be compiled before browser execution

---

## Slide 9: Babel (JSX Transpiler)

* JSX is converted into JavaScript using Babel
* Babel supports modern JS → older JS conversion
* Runs in the browser (for CDN setup) or build tools

---

## Slide 10: JSX Element Structure

* JSX must return a **single parent element**
* Valid:

```js
const header = (
  <header>
    <h1>Title</h1>
    <p>Subtitle</p>
  </header>
)
```

---

## Slide 11: Rendering JSX

* React uses `ReactDOM.render()`
* Takes:

  * JSX element
  * Root DOM element

```js
ReactDOM.render(element, root)
```

---

## Slide 12: Setting Up React with CDN

* Include:

  * React
  * ReactDOM
  * Babel

```html
<script src="react"></script>
<script src="react-dom"></script>
<script src="babel"></script>
```

---

## Slide 13: Root Element

* React app attaches to a single root div:

```html
<div class="root"></div>
```

* This is the only direct DOM interaction point

---

## Slide 14: Building Multiple JSX Elements

* UI can be split into:

  * Header
  * Main
  * Footer
* Each is a JSX element

---

## Slide 15: Combining JSX Elements

* Wrap multiple elements inside a parent:

```js
const app = (
  <div>
    {header}
    {main}
    {footer}
  </div>
)
```

---

## Slide 16: Injecting Data into JSX

* Use `{}` to inject dynamic values
* Supports:

  * Strings
  * Numbers
  * Arrays
  * Objects (via properties)

```js
<h1>{title}</h1>
```

---

## Slide 17: String & Number Injection

* Strings:

```js
<h1>{name}</h1>
```

* Numbers:

```js
<p>{2 + 3}</p>
```

---

## Slide 18: Objects in JSX

* Cannot inject objects directly
* Must access properties:

```js
<p>{user.firstName}</p>
```

---

## Slide 19: Arrays in JSX

* Arrays must be transformed using `map`

```js
const list = techs.map(tech => <li>{tech}</li>)
```

---

## Slide 20: Rendering Lists in JSX

* Use `<ul>` with mapped items
* Example:

```js
<ul>{techsFormatted}</ul>
```

---

## Slide 21: Keys in Lists

* Each list item needs a unique `key`
* Prevents rendering warnings

```js
<li key={tech}>{tech}</li>
```

---

## Slide 22: Styling in JSX (Inline Styles)

* Use JavaScript objects
* CSS becomes camelCase

```js
const style = {
  backgroundColor: 'blue',
  fontSize: '18px'
}
```

---

## Slide 23: className in JSX

* Use `className` instead of `class`
* Use `htmlFor` instead of `for`

```js
<div className="header"></div>
```

---

## Slide 24: Internal CSS vs Inline CSS

* Inline styles → quick, dynamic
* Internal CSS → scalable, structured
* External CSS → best for large apps

---

## Slide 25: Putting It All Together

* React app structure:

  * Header
  * Main
  * Footer
  * App wrapper
* Rendered via ReactDOM

---

## Slide 26: Summary

* React builds UI using components
* JSX simplifies UI creation
* Virtual DOM improves performance
* Data can be dynamically injected
* Styling can be inline or external

---

## Slide 27: Exercises

* What is React?
* Why use React?
* What is JSX?
* What is Babel?
* Render dynamic data using JSX
* Create styled components

* Or turn it into a **teaching script with speaker notes**
* Or split it into a **multi-day lesson plan (React Day 1–3 style)**
