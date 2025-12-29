## Lab 4: Event Listeners & Interactive Buttons

**Objective:** Learn how to prevent JavaScript from running automatically on page load. Instead, you will use a **Button** and an **Event Listener** to trigger your code only when the user is ready.

---

### Part 1: Setting Up the HTML Button

We need a way for the user to "trigger" the interaction. We will add a `<button>` element and a place to display the results.

1. **Update your `index.html**` to include these elements:
```html
<body>
    <h1>Interactive Profile Generator</h1>

    <button id="start-btn">Create Profile</button>

    <div id="display"></div>

    <script src="main.js"></script>
</body>

```



---

### Part 2: The JavaScript "Event Listener"

Instead of running the `prompt()` immediately, we wrap our code inside a **Function** and "listen" for a click on the button.

1. **Open `main.js**` and enter the following:

```javascript
// 1. Select our elements
const myButton = document.getElementById('start-btn');
const displayArea = document.getElementById('display');

// 2. Define the action (Function)
function generateProfile() {
    const name = prompt("Enter your name:");
    const job = prompt("Enter your job title:");
    
    // Logic to ensure name isn't empty
    if (name) {
        displayArea.innerHTML = `
            <div style="border: 2px solid black; padding: 10px; margin-top: 20px;">
                <h3>User: ${name}</h3>
                <p>Occupation: ${job}</p>
            </div>
        `;
        console.log("Profile successfully created.");
    } else {
        console.warn("User cancelled the prompt.");
    }
}

// 3. Attach the listener (The Trigger)
myButton.addEventListener('click', generateProfile);

```

---

### Part 3: How Event Listeners Work

In JavaScript, an **Event Listener** sits and waits for a specific action to happen (like a click, a keypress, or a mouse move).

* **The Target:** `myButton` (The element being watched).
* **The Event:** `'click'` (What we are waiting for).
* **The Function:** `generateProfile` (The code that runs when the event happens).

---

### Part 4: Practical Exercises

**Exercise A: The Reset Button**
Add a second button to your HTML with `id="reset-btn"`. In your JavaScript, add a listener to it that clears the `displayArea.innerHTML` when clicked.
*Hint:* `displayArea.innerHTML = "";`

**Exercise B: Hover Effects**
Try changing the event from `'click'` to `'mouseover'`. What happens when you just move your mouse over the button?

**Exercise C: Multi-Click Counter**
Create a variable `let count = 0;`. Every time the button is clicked, increase the count (`count++`) and display in the console: *"You have created ${count} profiles."*

---

### Summary of Interaction Methods

| Method | Timing | Best Use Case |
| --- | --- | --- |
| **Immediate Script** | Runs as soon as page loads | Initial setup, loading data |
| **Event Listener** | Runs on user action | Buttons, forms, menus |
| **Functions** | Runs only when called | Reusable logic, organization |

---

**Next Step:** Currently, we are using `prompt()` which is a bit old-fashioned. Would you like to learn how to use an **HTML Input Field** (a text box on the page) so the user doesn't have to deal with pop-up windows?
