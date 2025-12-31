# Lab 11: JavaScript `while` and `do...while` Loops

This lab explores **indeterminate iteration**—loops that run as long as a condition is met, rather than for a fixed number of times. This is essential for handling user input, polling for data, or building game loops.

---

## 🛠 Prerequisites

Ensure your project files are set up:

* **`index.html`**: The UI entry point.
* **`main.js`**: Where the logic will be written.
* **Developer Tools**: Keep your browser console open.

---

## Part 1: The `while` Loop

A `while` loop checks its condition **before** executing the code block. If the condition is false from the start, the loop never runs.

### Task 1.1: Basic Counter

Add the following to your `main.js`:

```javascript
let i = 1;

while (i <= 5) {
    console.log(`Counting: ${i}`);
    // Critical: Update the counter to avoid an infinite loop
    i++; 
}

```

### 🧠 Architectural Insight: Blocking the Call Stack

JavaScript is single-threaded. If you create an **Infinite Loop** (e.g., forgetting `i++`), the **Call Stack** will never clear. This prevents the **Event Loop** from processing renders or clicks, causing the browser tab to "freeze."

---

## Part 2: The `do...while` Loop

The `do...while` loop is a variant that checks the condition **after** executing the block. This guarantees the code runs **at least once**.

### Task 2.1: Guaranteed Execution

```javascript
let password = "";

do {
    password = prompt("Enter the secret password to stop this loop:");
} while (password !== "1234");

alert("Access Granted!");

```

---

## Part 3: Loop Control (`break` and `continue`)

Sometimes you need to exit a loop early or skip specific iterations based on logic.

### Task 3.1: Searching with `break`

```javascript
let target = 7;
let found = false;
let attempts = 0;

while (attempts < 100) {
    attempts++;
    let guess = Math.floor(Math.random() * 10) + 1;
    
    if (guess === target) {
        console.log(`Found ${target} on attempt ${attempts}!`);
        found = true;
        break; // Stop the loop immediately
    }
}

```

---

## 🧪 Challenge Lab: The "Number Accumulator"

Write a script that performs the following:

1. Initialize a variable `sum = 0`.
2. Use a `while` loop to repeatedly prompt the user for a number.
3. If the user enters a negative number, the loop should stop.
4. If the user enters a positive number, add it to the `sum`.
5. After the loop stops, use a **ternary operator** to check if the total sum is greater than 100.
* If yes, alert "Goal Reached! Total: [sum]".
* If no, alert "Goal Missed. Total: [sum]".



---

## 🚨 Best Practices Review

* **Avoid Infinite Loops**: Always ensure the variable in your condition is being updated within the loop body.
* **Memory Management**: When using loops to populate arrays, be mindful of the **Memory Heap**. Large arrays created in loops should be cleared or nullified when no longer needed to assist **Garbage Collection**.
* **Validation**: Always wrap `prompt()` inputs in `Number()` or `parseInt()` to ensure you are performing mathematical operations rather than string concatenation.
