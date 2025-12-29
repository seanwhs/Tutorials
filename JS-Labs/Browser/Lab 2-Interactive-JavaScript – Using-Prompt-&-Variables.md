## Lab 2: Interactive JavaScript – Using Prompt & Variables

**Objective:** Learn how to make your code interactive by capturing user input, performing basic calculations, and displaying results dynamically in the console.

---

### Part 1: The Setup

Ensure you have your `index.html` file from the previous lab. We will be working entirely inside `main.js`.

1. **Open `main.js**` and clear out any previous code.
2. **Enter the following code:**

```javascript
// 1. Capturing Input
const userName = prompt("Enter your name:");
const hobby = prompt("What is your favorite hobby?");
const birthYear = prompt("What year were you born?");

// 2. Processing Data
const currentYear = 2025;
const age = currentYear - birthYear;

// 3. Outputting the Interaction
console.log(`--- User Profile ---`);
console.log(`Hello, ${userName}!`);
console.log(`It's cool that you like ${hobby}.`);
console.log(`Since you were born in ${birthYear}, you are approximately ${age} years old.`);

// 4. Using Logic with the Input
if (age < 0) {
    console.error("Error: You haven't been born yet!");
}

```

---

### Part 2: Understanding the "IPO" Model

Every interactive program follows a specific flow called the **IPO model**. This lab demonstrates exactly how that works in JavaScript:

* **Input:** The `prompt()` function opens a dialog box. The program **pauses** until the user types something and hits "OK."
* **Process:** The line `currentYear - birthYear` takes the raw input and creates a new piece of information.
* **Output:** The `console.log` sends the final result back to the user.

---

### Part 3: Essential Rules for Inputs

1. **Strings vs. Numbers:** Even if a user types `1968`, the `prompt()` function captures it as a **String** (text). JavaScript is clever enough to let you subtract strings in math, but for addition, it might just stick the numbers together (e.g., "57" + "5" might become "575").
2. **Storage:** We use `const` (constant) to store the inputs. Since the user's name won't change while the script is running, `const` is the safest choice.
3. **The Backtick Requirement:** Notice the final logs use **backticks ( ` )**. If you use regular quotes, the console will literally print `${userName}` instead of the person's name.

---

### Part 4: Practical Exercises

**Exercise A: The Multiplier**
Add code to ask the user for a "Lucky Number." Then, log a message saying: *"If we triple your lucky number, we get: [Result]."*

**Exercise B: The Validator**
Add an `if` statement that checks if the `userName` is empty.
*Hint:* `if (userName === "") { console.warn("You didn't enter a name!"); }`

**Exercise C: Visual Styling**
Try to "CSS style" your final output by adding `%c` at the start of your string.

```javascript
console.log(`%cWelcome ${userName}`, "color: blue; font-size: 20px; font-weight: bold;");

```

---

