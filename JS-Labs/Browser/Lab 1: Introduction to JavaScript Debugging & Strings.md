## Lab 1: Introduction to JavaScript Debugging & Strings

**Objective:** Understand how to link JavaScript to HTML, use the Browser Console for debugging, and compare **String Concatenation** with **Template Literals**.

---

### Part 1: Setting Up the Environment

1. **Create your folder:** Create a folder named `js-basics`.
2. **The HTML File:** Create `index.html` in that folder:

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

3. **The JavaScript File:** Create `main.js` in the **same folder** and add the following:

```javascript
// Basic Logging
console.log('My name is Sean.');
console.log("I'm 57 years old.");
console.error("Logging an error.");
console.warn("Logging a warning.");

// Using Template Literals (Modern Way)
const name = 'John';
const profession = 'Engineer';
console.log(`Hey ${name}, are you the ${profession}?`); 

// Using String Concatenation (Older Way)
let firstName = 'James';
let lastName = 'Cameron';
let age = 108;

console.log('Hi ' + firstName + ' ' + lastName + '. ' + 'You are ' + age + ' years old.');

// Reassigning Variables
firstName = 'Donald';
lastName = 'Trump';
console.log('Hi ' + firstName + ' ' + lastName + '. ' + 'You are ' + age + ' years old.');

```

---

### Part 2: Viewing the Output

To see your work, you must use the **Browser Developer Tools**:

1. Open `index.html` in your browser.
2. Right-click and select **Inspect**, then click the **Console** tab.

**Observations:**

* **Visual Hierarchy:** Notice how `console.error` (red) and `console.warn` (yellow) stand out compared to standard logs.
* **Variable Updates:** In the last two logs, notice how the text changed even though the `console.log` formula looked similar. This is because we updated the values of `firstName` and `lastName`.

---

### Part 3: Key Concepts

#### 1. Concatenation vs. Template Literals

In this lab, you used two ways to join text and variables:

* **Concatenation (`+`):** The "old" way. You must manually add spaces between quotes (e.g., `' '`). It can get messy with many variables.
* **Template Literals (Backticks):** The modern way. Use `${variable}` inside backticks. It respects the spaces you type naturally.

#### 2. `const` vs `let`

* **`const`**: Used for variables that **should not change** (like `profession`).
* **`let`**: Used for variables that **can be updated** (like `firstName`). Notice we didn't use `let` again when changing James to Donald—we just reassigned the value.

---

### Part 4: Exercises for You

1. **The Fixer:** Refactor the "James Cameron" log to use **Template Literals** (backticks) instead of the `+` symbols.
2. **Math in Strings:** We know the `age` is 108. Use a template literal to log: `"In 10 years, James will be 118."` by doing the math `${age + 10}` inside the string.
3. **Experimental Logging:** Use `console.info("Your message here")`. Does it look different from `console.log` in your specific browser?

---

