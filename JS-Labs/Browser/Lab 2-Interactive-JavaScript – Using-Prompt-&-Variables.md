## Lab 2: Interactive JavaScript – Using Prompt & Variables

**Objective:** Learn how to make your JavaScript code interactive by capturing user input, performing basic calculations, and displaying results dynamically in the console.

---

### Part 1: Setup HTML

Create an `index.html` file for this lab:

```html
<!-- index.html -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JS Interactive Lab</title>
</head>
<body>
    <h1>Let's Explore Prompts & Variables</h1>
    <!-- Link to our JavaScript file -->
    <script src="main.js"></script>
</body>
</html>
```

> 🔑 **Key Point:** `<script src="main.js"></script>` ensures your JavaScript runs **in the browser**, and you can interact with the user via `prompt()`.

---

### Part 2: Capturing Input

Open `main.js` and enter the following:

```javascript
// 1. Capturing User Input

// prompt() always returns a string, even if the user enters numbers
let firstName = prompt('Please enter your first name:');
let lastName = prompt('Please enter your last name:');
let ageInput = prompt('Please enter your age:');  // user enters "25" for example

// 2. Casting input to number using parseInt()
// Why we need parseInt:
//  - prompt() returns text (string) by default
//  - JavaScript can behave unexpectedly if we perform math on strings
//      e.g., "25" + 2 → "252" (concatenation) instead of 27
//  - parseInt() converts a string to an integer, so math works correctly
let age = parseInt(ageInput);

// 3. Processing Input
age += 2; // Calculate the age in 2 years

// 4. Output to Console
console.log("First Name:", firstName);
console.log("Last Name:", lastName);
console.log("Age in 2 years:", age);
```

**Explanation of `parseInt()`:**

* `parseInt("25")` → `25` (number)
* `parseInt("25abc")` → `25` (stops at first invalid character)
* `parseInt("abc25")` → `NaN` (not a number)

> ✅ **Key Concept:** Always **cast user inputs** to the correct type before doing math, because `prompt()` always returns a string.

---

### Part 3: Enhancing Interaction

Add more interactive questions:

```javascript
// Capture hobby and birth year
const hobby = prompt("What is your favorite hobby?");
const birthYearInput = prompt("What year were you born?");
const birthYear = parseInt(birthYearInput); // Cast string to number

// Processing
const currentYear = 2025;
const calculatedAge = currentYear - birthYear;

// Output formatted profile
console.log(`--- User Profile ---`);
console.log(`Hello, ${firstName} ${lastName}!`);
console.log(`It's cool that you like ${hobby}.`);
console.log(`Since you were born in ${birthYear}, you are approximately ${calculatedAge} years old.`);

// Edge Case: Age cannot be negative
if (calculatedAge < 0) {
    console.error("Error: You haven't been born yet!");
}
```

> 💡 **Tip:** Whenever you perform arithmetic with user input, cast it to a **number** (`parseInt()` for integers or `parseFloat()` for decimals). Otherwise, JavaScript might **concatenate strings instead of adding numbers**.

---

### Part 4: Practical Exercises

#### Exercise A – Lucky Number Multiplier

```javascript
// Ask for a lucky number
const luckyInput = prompt("Enter your lucky number:");
const luckyNumber = parseInt(luckyInput); // Cast to integer

console.log(`If we triple your lucky number, we get: ${luckyNumber * 3}`);
```

> This demonstrates **input → process → output** with arithmetic.

---

#### Exercise B – Input Validator

```javascript
if (!firstName) { // Checks if input is empty or null
    console.warn("You didn't enter a first name!");
}
```

> Validation ensures users don’t break your program with empty inputs.

---

#### Exercise C – Console Styling

```javascript
console.log(`%cWelcome ${firstName}!`, "color: blue; font-size: 20px; font-weight: bold;");
```

> Shows how to **apply CSS styles in console logs** for a better visual effect.

---

### Part 5: Understanding the IPO Model

All interactive programs follow **Input → Process → Output (IPO)**:

* **Input:** `prompt()` to collect data
* **Process:** Arithmetic, logic, or transformation (`age += 2`, `currentYear - birthYear`)
* **Output:** `console.log()` to show results

```
User Input
   |
   v
Process / Calculation
   |
   v
Console Output
```

---

### Part 6: Key Takeaways

1. **`prompt()` always returns a string**; always cast numbers before arithmetic.
2. `parseInt()` converts string input to integer safely.
3. Use **template literals (`backticks`)** for dynamic string interpolation.
4. Validate input to handle edge cases.
5. Console styling (`%c`) can improve readability and engagement.

---

### ✅ Optional Extensions

* Display results on the webpage using `document.write()` or DOM manipulation.
* Add multiple hobbies using arrays (`prompt()` in a loop).
* Add conditional logic to give **personalized messages** based on age or hobby.
