# Lab 10: JavaScript `for` Loops & Dynamic Collections

This lab explores how to use loops to automate data collection and populate arrays dynamically. We will move from basic counting to building a user-driven data list.

---

## 🛠 Prerequisites

Ensure your project files are ready:

* **`index.html`**: The UI entry point.
* **`main.js`**: Where the iteration logic lives.
* **Browser Console/Alerts**: To interact with the data.

---

## Part 1: Anatomy of a `for` Loop

A `for` loop is used when you know exactly how many times you want to run a block of code.

### Task 1.1: The 3-Step Header

In your `main.js`, implement the following structure:

```javascript
// Initialization; Condition; Final Expression
for (let i = 1; i <= 3; i++) {
    console.log(`Iteration number: ${i}`);
}

```

1. **Initialization (`let i = 1`)**: Sets the starting point.
2. **Condition (`i <= 3`)**: As long as this is true, the loop continues.
3. **Final Expression (`i++`)**: Increments the counter after each loop.

---

## Part 2: Dynamic Array Population

Loops are frequently used to fill arrays with data provided by a user or an API.

### Task 2.1: Collecting User Input

Update your `main.js` to collect a list of colors:

```javascript
let colorList = []; // Initialize an empty heap-allocated array

for (let i = 1; i <= 3; i++) {
    // Prompt the user and store the result in a local variable
    let color = prompt(`Enter favorite color #${i}:`);
    
    // Use the .push() method to add the color to the array
    colorList.push(color);
}

// Display the final collection
alert(`Your favourite colors are: ${colorList.join(", ")}`);

```

### 🧠 Architectural Insight: Memory & The Heap

When `colorList.push(color)` is called:

* The `colorList` variable in the **Stack** stays the same (it still points to the same memory address).
* The actual object in the **Memory Heap** grows in size to accommodate the new string.

---

## Part 3: Iterating Over the Result

Once data is collected, we often need to "walk through" the array to perform operations on each item.

### Task 3.1: The `for...of` Pattern

Modern JavaScript uses `for...of` for cleaner array traversal. Add this to your script:

```javascript
console.log("Processing your colors...");

for (const col of colorList) {
    console.log(`Color found: ${col.toUpperCase()}`);
}

```

---

## 🧪 Challenge Lab: The Shopping List

Write a script that:

1. Asks the user how many items they want to add to their shopping list (store this in a variable `numItems`).
2. Uses a `for` loop to prompt the user for each item name.
3. Adds each item to an array called `shoppingCart`.
4. After the loop, use a **ternary operator** to check if the cart has more than 5 items. If so, alert "Bulk Discount Applied!"; otherwise, alert "Standard Checkout."

---

## 🚨 Best Practices Review

* **Zero-Indexing**: While the lab uses `i = 1` for human readability in prompts, professional code usually starts at `i = 0` to match array indexes.
* **Infinite Loops**: Always ensure your condition (`i <= 3`) will eventually become false. If you forget `i++`, the loop will run forever and crash the **Call Stack**.
* **Clean UI**: Use `.join(", ")` in your alerts to format arrays nicely for the user, rather than showing raw commas.
