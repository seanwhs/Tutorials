## Introduction
When beginners learn JavaScript, they often master variables, functions, arrays, and objects first. The next big question is usually: how does JavaScript actually update the page in the browser?

That is where **DOM manipulation** comes in.

The DOM connects JavaScript with HTML and CSS. Without it, JavaScript would not be able to change text, update styles, add elements, remove elements, or respond to user interactions on the page. [developer.mozilla](https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector)

***
## What Is the DOM?
DOM stands for **Document Object Model**. It is the browser’s structured representation of a web page after the HTML has been parsed. [developer.mozilla](https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector)

You can think of it as a tree:

```text
Document
└── html
    ├── head
    └── body
        ├── h1
        └── p
```

That tree is what JavaScript works with. Instead of editing raw HTML directly, JavaScript manipulates the objects the browser creates from that HTML. [developer.mozilla](https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector)

***
## Why It Matters
With DOM manipulation, JavaScript can:

- change text.
- change styles.
- add elements.
- remove elements.
- react to clicks and typing.
- handle forms.
- build dynamic interfaces like modals, dropdowns, and todo lists.

This is the foundation of most interactive websites. [w3schools](https://www.w3schools.com/jsref/dom_obj_event.asp)

***
## The Big Picture
HTML provides structure.

CSS provides presentation.

JavaScript provides behavior.

A good beginner mental model is:

- HTML = what exists.
- CSS = how it looks.
- JavaScript = how it behaves.

***
## Selecting Elements
Before you can change anything, you need to find the element you want.
### `querySelector()`
`querySelector()` returns the first element that matches a CSS selector. It works with IDs, classes, tags, and more. [developer.mozilla](https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelector)

```html
<h1 id="title">Hello</h1>
```

```js
const title = document.querySelector("#title");
```
### `querySelectorAll()`
`querySelectorAll()` returns all matching elements as a list-like collection you can loop through. A common use case is selecting every item in a list. [developer.mozilla](https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelector)

```html
>Apple</li>
>Banana</li>
>Orange</li>
```

```js
const items = document.querySelectorAll("li");

items.forEach(item => {
  console.log(item.textContent);
});
```

***
## Changing Content
### `textContent`
Use `textContent` when you want to update plain text.

```html
<h1 id="title">Old Title</h1>
```

```js
title.textContent = "New Title";
```

This replaces the visible text without parsing HTML. [developer.mozilla](https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector)
### `innerHTML`
Use `innerHTML` when you want to insert HTML markup.

```js
container.innerHTML = `
  <h1>Hello</h1>
  <p>Welcome</p>
`;
```

`innerHTML` is powerful, but it should be used carefully because assigning user-provided strings can create XSS risks. MDN warns that `innerHTML` is a potential injection sink. [developer.mozilla](https://developer.mozilla.org/en-US/docs/Web/API/ShadowRoot/innerHTML)
### `textContent` vs `innerHTML`
| Property | Best for | Behavior |
| --- | --- | --- |
| `textContent` | Plain text | Inserts text only |
| `innerHTML` | HTML markup | Parses HTML tags |

Use `textContent` by default unless you specifically need HTML. [developer.mozilla](https://developer.mozilla.org/en-US/docs/Web/API/ShadowRoot/innerHTML)

***
## Changing Styles
### Inline styles with `style`
You can update individual CSS properties directly from JavaScript.

```js
title.style.color = "red";
title.style.fontSize = "20px";
```

This is useful for quick, dynamic changes, but for larger projects, CSS classes are usually cleaner.
### `classList`
`classList` is the preferred way to add, remove, or toggle styles.

```js
element.classList.add("active");
element.classList.remove("active");
element.classList.toggle("dark");
```

This keeps styling in CSS and behavior in JavaScript.

***
## Handling Events
Events are how JavaScript responds to user actions.
### Click events
```js
button.addEventListener("click", () => {
  alert("Clicked!");
});
```
### Input events
The `input` event fires when a user changes the value of an input, textarea, or select element. It fires as the value changes, not only when it is committed. [developer.mozilla](https://developer.mozilla.org/en-US/docs/Web/API/Element/input_event)

```js
input.addEventListener("input", event => {
  console.log(event.target.value);
});
```

Events are what make pages feel interactive. [w3schools](https://www.w3schools.com/jsref/dom_obj_event.asp)

***
## Creating and Removing Elements
### `createElement()`
```js
const li = document.createElement("li");
li.textContent = "Apple";
list.appendChild(li);
```

This is how you add new UI pieces dynamically.
### `remove()`
```js
element.remove();
```

This deletes an element from the page.

A simple beginner project idea is a todo app where users can add and delete items with these methods.

***
## Working With Forms
Forms usually need one extra step: preventing the browser’s default submit behavior.

```js
form.addEventListener("submit", e => {
  e.preventDefault();
});
```

After that, you can read input values, validate them, and update the page without a reload.

***
## Traversing the DOM
Sometimes you already have one element and want to move to related ones.

Common traversal properties include:

```js
element.parentElement
element.children
element.firstElementChild
```

These are useful when building components like cards, menus, and list items.

***
## Using Data Attributes
Data attributes let you store custom information in HTML.

```html
<button data-id="123">Delete</button>
```

```js
button.dataset.id;
```

This is helpful for lists, buttons, and reusable components where each element needs its own identifier.

***
## Beginner Project Ideas
These are ideal practice projects:

- Counter.
- Todo app.
- Modal popup.
- Dark mode toggle.
- Tabs component.
- Shopping cart UI.
- Image gallery.

A good learning path is to start with a counter, then build a todo app, then move to a modal or tabs system.

***
## DOM vs React
This is the most important conceptual distinction.
### Vanilla JavaScript
In plain JavaScript, you manually select elements and update them yourself.

```js
const title = document.querySelector("#title");
title.textContent = "Hello";
```

This is **imperative**: you tell the browser exactly what to do step by step.
### React
In React, you do not usually manipulate the DOM directly. Instead, you describe what the UI should look like for a given state, and React updates the DOM for you. React’s docs describe this as a declarative model, where React keeps the DOM in sync with the desired UI state. [legacy.reactjs](https://legacy.reactjs.org/docs/faq-internals.html)

```jsx
const [title, setTitle] = useState("Hello");

return <h1>{title}</h1>;
```

```js
setTitle("New Title");
```

React uses reconciliation to compare changes and update the UI efficiently. The “virtual DOM” is a concept associated with this process. [developer.mozilla](https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Frameworks_libraries/Main_features)

| Vanilla JS | React |
| --- | --- |
| Direct DOM updates | React manages DOM updates |
| Manual element selection | UI driven by state |
| Imperative style | Declarative style |
| Good for learning fundamentals | Good for scalable app UIs |
### Mental model
Vanilla JavaScript says:

> Find the element, then change it.

React says:

> Here is what the UI should look like now.

***
## Final Takeaway
DOM manipulation teaches you how the browser works.

React teaches you how to describe UI in a cleaner, state-driven way.

If you understand both, you will be much stronger as a frontend developer: vanilla DOM gives you fundamentals, and React gives you a scalable component model. [legacy.reactjs](https://legacy.reactjs.org/docs/faq-internals.html)

## Reference Repository

Reference this public repository for examples and demos:

Javascript-DOM-Manipulation Repository
