# Lab 7: JavaScript Conditionals & Decision Making

This lab explores how JavaScript handles logic using `if...else` blocks and the concise **Ternary Operator**. We will move from basic input validation to professional conditional patterns.

---

## 🛠 Prerequisites

Ensure your project files are ready:

* **`index.html`**: The structure for your logic.
* **`main.js`**: Where the conditional logic lives.
* **Console/Alerts**: Used for user feedback.

---

## Part 1: The `if...else if...else` Chain

The `if` statement is the foundation of decision-making. It executes a block of code only if a specified condition is **truthy**.

### Task 1.1: Multi-tier Grade Logic

Update your `main.js` to handle grade categorization and input validation:

```javascript
// main.js
let grade = Number(prompt('Please enter your grade (0-100): '));

if (grade < 0) {
    alert('Error: Enter a number 0 or greater.');
} 
else if (grade > 100) {
    alert('Error: Enter a number 100 or less.');
} 
else if (grade >= 90) {
    alert('Your grade is A');
} 
else if (grade >= 80) {
    alert('Your grade is B');
}
else if (grade >= 70) {
    alert('Your grade is C');
}
else if (grade >= 60) {
    alert('Your grade is D');
}
else {
    alert('Your grade is F');
}

```

### 🧠 Architectural Insight: Truthy vs. Falsy

In JavaScript, conditions don't always have to be `true` or `false`.

* **Falsy values**: `false`, `0`, `""` (empty string), `null`, `undefined`, and `NaN`.
* **Truthy values**: Everything else (including `[]` and `{}`).

---

## Part 2: The Ternary Operator `(condition ? expr1 : expr2)`

The ternary operator is a shortcut for a simple `if...else`. It is widely used in modern frameworks for "conditional rendering."

### Task 2.1: Simplified Pass/Fail

Instead of a full `if` block, determine if a student passed in a single line:

```javascript
// Syntax: condition ? value_if_true : value_if_false;

let result = (grade >= 60) ? "Pass" : "Fail";
alert(`Result: ${result}`);

```

### Task 2.2: Conditional Styling Logic

Imagine you want to change a UI color based on the grade. Ternaries are perfect for assigning variables:

```javascript
const statusColor = (grade >= 60) ? "green" : "red";
console.log(`The UI status color should be: ${statusColor}`);

```

---

## Part 3: Advanced Logic (Logical Operators)

Sometimes a single condition isn't enough. We use Logical Operators to combine them.

* **`&&` (AND)**: True only if both sides are true.
* **`||` (OR)**: True if at least one side is true.
* **`!` (NOT)**: Inverts the truthiness.

### Task 3.1: Range Validation

```javascript
// Using AND to check if a grade is valid in one line
if (grade >= 0 && grade <= 100) {
    console.log("Grade is within valid range.");
} else {
    console.log("Invalid grade entered.");
}

```

---

## 🧪 Challenge Lab: The "Scholarship Eligibility" Checker

Write a script that asks for two inputs: `grade` and `attendancePercentage`.

1. If the `grade` is **90 or higher** **AND** `attendancePercentage` is **80 or higher**, alert "Eligible for full scholarship".
2. Else if the `grade` is **80 or higher** **OR** `attendancePercentage` is **95 or higher**, alert "Eligible for partial scholarship".
3. Use a **ternary operator** to create a message: "Application Status: [Accepted/Review Required]" based on whether they qualify for any scholarship.

---

## 🚨 Best Practices Review

* **Strict Equality**: Always use `===` and `!==` instead of `==` to avoid unexpected type coercion.
* **Refactoring**: If you have more than 5 `else if` statements, consider using a `switch` statement or an Object Lookup for better performance.
* **Security**: Sanitize inputs from `prompt()` using `Number()` or `parseInt()` to prevent logic errors from string-based inputs.
