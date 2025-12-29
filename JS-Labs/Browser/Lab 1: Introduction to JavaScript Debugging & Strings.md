## Lab 1: Introduction to JavaScript Debugging & Strings

**Objective:** Understand how to link JavaScript to HTML and utilize the Browser Console for debugging and dynamic string output.

---

### Part 1: Setting Up the Environment

1. **Create your folder:** Create a new folder on your computer named `js-basics`.
2. **The HTML File:** Create a file named `index.html` and paste the following code:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JS Console Lab</title>
</head>
<body>
    <h1>Open the Console to See the Magic!</h1>
    <script src="main.js"></script>
</body>
</html>

```


3. **The JavaScript File:** Create a file named `main.js` in the **same folder** and add the following:
```javascript
console.log('My name is Sean.');
console.log("I'm 57 years old.");
console.error("Logging an error.");
console.warn("Logging a warning.");

const name = 'John';
const profession = 'Engineer';

// Note the use of backticks below
console.log(`Hey ${name}, are you the ${profession}?`);

```



---

### Part 2: Viewing the Output

To see your work, you must use the **Browser Developer Tools**:

1. Open `index.html` in your browser (Chrome or Edge recommended).
2. Right-click anywhere on the page and select **Inspect**.
3. Click on the **Console** tab at the top of the pane that opens.

**Observations:**

* **Standard Logs:** Your first two lines appear as normal text.
* **Color Coding:** Notice that `console.error` appears in **red** and `console.warn` appears in **yellow**.
* **Template Literals:** Look at the final line. Does it say `${name}` or does it say `John`?

---

### Part 3: Key Concepts to Remember

#### 1. The Power of Backticks (`)

In JavaScript, there is a big difference between `'` (quotes) and ``` (backticks).

* **Quotes:** Treat everything inside as literal text.
* **Backticks:** Allow for **Template Literals**. This lets you "inject" variables directly into a string using the `${variableName}` syntax.

> **Challenge:** Try changing the backticks in the last line of `main.js` back to single quotes. Save and refresh the browser. What happens to the output?

#### 2. Console Levels

Using the correct console method helps developers filter through messages. In a large project, you can hide "Logs" and only show "Errors" to find bugs faster.

---

### Part 4: Exercises for You

1. **Expression Injection:** Inside a `console.log` using backticks, try to perform math. Example: `console.log(`In five years, I will be ${57 + 5}`);`
2. **Create your own:** Create two new constants, `city` and `favoriteColor`. Log a sentence using backticks that says: *"I live in [city] and I love the color [favoriteColor]."*

---
