# Lab 12: Integrated JavaScript Logic (Conditionals & Loops)

This lab focuses on combining **Conditionals (`if/else`)**, **`for` loops**, and **`while` loops** into a single, cohesive program. You will build a "Smart Grade & Attendance Tracker" that processes multiple students and validates data in real-time.

---

## 🛠 Project Setup

1. Create a folder named `js-logic-lab`.
2. Inside, create `index.html` and `main.js`.
3. Link your script in the HTML file: `<script src="main.js"></script>`.

---

## 🧠 Architectural Overview: The Logic Flow

In professional software, logic is often "nested." We use loops to iterate over collections and conditionals inside those loops to make decisions about specific data points.

---

## Part 1: The Integrated Code

Copy the following code into your `main.js`. This script demonstrates all three concepts working together.

```javascript
// main.js

// 1. Array to store processed data
let studentClassroom = [];

// 2. WHILE Loop: Used for indeterminate iteration (runs until user stops)
let continueInput = true;
while (continueInput) {
    let name = prompt("Enter student name (or type 'exit' to stop):");
    
    if (name.toLowerCase() === 'exit') {
        continueInput = false; // Breaking the while loop
    } else {
        let grade = Number(prompt(`Enter grade for ${name} (0-100):`));
        let attendance = Number(prompt(`Enter attendance % for ${name}:`));

        // 3. IF/ELSE: Conditionals used for data validation & categorization
        if (isNaN(grade) || grade < 0 || grade > 100) {
            alert("Invalid grade. Student not added.");
        } else {
            // Determine status using a Ternary Operator
            let status = (grade >= 60 && attendance >= 75) ? "Passing" : "Failing";
            
            // Adding student object to our heap-allocated array
            studentClassroom.push({ name, grade, attendance, status });
        }
    }
}

// 4. FOR Loop: Used for determinate iteration (iterating through the results)
console.log("--- Final Classroom Report ---");
for (let i = 0; i < studentClassroom.length; i++) {
    let student = studentClassroom[i];
    
    // Nested conditional to highlight high achievers
    let award = "";
    if (student.grade >= 90) {
        award = "⭐ Honors List";
    }

    console.log(`${i + 1}. ${student.name}: ${student.status} (${student.grade}%) ${award}`);
}

```

---

## Part 2: Understanding the Interaction

### 1. The `while` Loop (User Control)

The `while` loop is used because we don't know if the teacher has 2 students or 200. It keeps the "Stack" busy until the condition `continueInput` is toggled to `false`.

### 2. The `if/else` (Decision Points)

We use conditionals to check for two things:

* **Validation**: Is the data a real number between 0-100?
* **Logic**: Is the student "Passing"? (Uses both `grade` **AND** `attendance`).

### 3. The `for` Loop (Data Processing)

Once the data is safely stored in the **Memory Heap** (the array), we use a `for` loop to step through every item and generate a report.

---

## 🧪 Challenge Lab: The "Attendance Bonus"

Modify the code above to include the following logic:

1. **Add a variable**: Inside the `for` loop, check if a student has **100% attendance**.
2. **Conditional logic**: If they have 100% attendance, add **2 bonus points** to their `grade` before the final report is printed.
3. **Validation**: Ensure the grade does not exceed 100 even after the bonus is added (Hint: use an `if` statement or `Math.min()`).
4. **Ternary**: Use a ternary operator to log "Excellent Attendance" next to their name if they hit 100%.

---

## 🚨 Best Practices Review

* **Memory Management**: Arrays like `studentClassroom` are stored in the **Heap**. If you expect thousands of entries, consider "clearing" the array or nullifying it when done to assist **Garbage Collection**.
* **Logical Operators**: Use `&&` (AND) when both conditions must be true, and `||` (OR) when only one is required.
* **Safety**: Always use `Number()` when taking inputs from `prompt()` to avoid string concatenation bugs in your math logic.
