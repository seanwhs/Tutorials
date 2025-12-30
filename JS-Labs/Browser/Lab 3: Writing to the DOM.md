# 🧪 Lab 3: Writing to the DOM with a Button Click

**Objective:** Learn how to use a button to trigger JavaScript prompts and update the webpage dynamically.

---

## Part 1: HTML – Adding a Button

```html
<!-- index.html -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Interactive DOM Example</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <!-- Header that will be updated -->
    <h1 id="title">Manipulate DOM with JS</h1>

    <!-- Placeholder for user content -->
    <div id="output-area"></div>

    <!-- Button to trigger prompts -->
    <button id="start-btn">Start Personalization</button>

    <script src="main.js"></script>
</body>
</html>
```

**Explanation:**

* `button#start-btn` → User clicks this to start prompts.
* `div#output-area` → Area to show dynamic content.
* `h1#title` → Updated greeting.

---

## Part 2: CSS – Styling the Page and Button

```css
/* styles.css */

body {
    background-color: burlywood;
    text-align: center;
    font-family: Arial, sans-serif;
    padding: 20px;
}

h1 {
    font-size: 40px;
    color: blue;
    text-shadow: 2px 2px;
    letter-spacing: 8px;
}

button {
    font-size: 18px;
    padding: 10px 20px;
    margin-top: 20px;
    cursor: pointer;
    border: none;
    border-radius: 8px;
    background-color: darkblue;
    color: white;
    transition: background-color 0.3s;
}

button:hover {
    background-color: navy;
}

#output-area h2, #output-area h3 {
    color: darkgreen;
}
```

---

## Part 3: JavaScript – Button Click Triggers Everything

```javascript
// main.js

// 1️⃣ Select the button
const startBtn = document.getElementById('start-btn');

// 2️⃣ Add a click event listener
startBtn.addEventListener('click', () => {

    // 3️⃣ Capture User Input
    let firstName = prompt('Please enter your first name:');
    let favoriteColor = prompt('What is your favorite color?');

    // 4️⃣ Update the main heading
    document.getElementById('title').innerText = `Hello, ${firstName}!`;

    // 5️⃣ Select the output div
    const displayBox = document.getElementById('output-area');

    // 6️⃣ Display basic profile
    displayBox.innerHTML = `
        <h2>User Profile</h2>
        <p><strong>Name:</strong> ${firstName}</p>
        <p><strong>Favorite Color:</strong> <span style="color:${favoriteColor}">${favoriteColor}</span></p>
    `;

    // 7️⃣ Extra: Change page background color
    document.body.style.backgroundColor = favoriteColor;

    // 8️⃣ Ask for job details
    let job = prompt('What is your Job Title?');
    let company = prompt('Which Company do you work for?');

    // 9️⃣ Add professional info
    displayBox.innerHTML += `
        <h3>Professional Info</h3>
        <p><strong>Job:</strong> ${job}</p>
        <p><strong>Company:</strong> ${company}</p>
    `;

    // 🔟 Ask for two numbers and display sum
    let num1 = Number(prompt('Enter the first number:'));
    let num2 = Number(prompt('Enter the second number:'));
    let sum = num1 + num2;

    displayBox.innerHTML += `<p>The sum of ${num1} and ${num2} is <strong>${sum}</strong></p>`;
});
```

---

## ✅ Key Features in This Version

1. **Button-controlled interaction** – Prompts no longer pop up automatically.
2. **Dynamic DOM updates** – Updates the heading, profile, professional info, and math results.
3. **Dynamic styling** – Page background and text colors change based on user input.
4. **Input casting** – `Number(prompt())` ensures math operations work correctly.

---

## Part 4: Optional Practice

1. Add a **reset button** to revert background and clear the content.
2. Use **`confirm()`** to ask if the user wants to continue before each new prompt.
3. Add **emoji reactions** dynamically based on favorite color or name length.


