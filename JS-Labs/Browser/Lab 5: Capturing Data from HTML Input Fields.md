## Lab 5: Capturing Data from HTML Input Fields

**Objective:** Replace annoying pop-up windows (`prompt`) with professional **HTML Input Fields**. You will learn how to "grab" values directly from the page when a user types into a text box.

---

### Part 1: Designing the Form in HTML

Instead of using pop-ups, we will create a structured area for the user to type.

1. **Update your `index.html**` with this form-like structure:
```html
<body>
    <h1>Member Registration</h1>

    <div id="form-container">
        <input type="text" id="user-name" placeholder="Full Name">
        <input type="text" id="user-city" placeholder="City">
        <button id="submit-btn">Register</button>
    </div>

    <div id="output"></div>

    <script src="main.js"></script>
</body>

```



---

### Part 2: Grabbing Values with JavaScript

When using an `<input>`, we don't just need the element; we need its **`.value`** property.

1. **Open `main.js**` and enter the following code:

```javascript
// 1. Select the elements
const nameInput = document.getElementById('user-name');
const cityInput = document.getElementById('user-city');
const submitBtn = document.getElementById('submit-btn');
const outputDiv = document.getElementById('output');

// 2. Define the Registration Function
function registerUser() {
    // 3. Extract the VALUES from the inputs
    const nameValue = nameInput.value;
    const cityValue = cityInput.value;

    if (nameValue === "" || cityValue === "") {
        alert("Please fill out all fields!");
        return; // Stops the function here
    }

    // 4. Display the result on the page
    outputDiv.innerHTML = `
        <div style="margin-top:20px; color: navy;">
            <h3>Registration Complete!</h3>
            <p>Welcome, <strong>${nameValue}</strong> from <strong>${cityValue}</strong>.</p>
        </div>
    `;

    // 5. Clear the inputs for the next entry
    nameInput.value = "";
    cityInput.value = "";
}

// 6. Set up the trigger
submitBtn.addEventListener('click', registerUser);

```

---

### Part 3: Why `.value` is Critical

When you select an input element using `getElementById`, you are grabbing the **entire HTML tag**. To get what the user actually typed inside that tag, you must add `.value`.

* **`nameInput`** = The actual text box (an object).
* **`nameInput.value`** = The text currently sitting inside that box (e.g., "Sean").

---

### Part 4: Practical Exercises

**Exercise A: The Character Counter**
Add a small `<span>` under your Name input. Use an event listener called `'input'` on the text box so that as the user types, the span updates to show how many characters they have used.
*Hint:* `nameInput.value.length;`

**Exercise B: Dynamic Color Picker**
Add an `<input type="color" id="color-picker">` to your HTML. In your JavaScript, make it so that whenever the color changes, the `document.body.style.backgroundColor` updates to that color.

**Exercise C: Number Cruncher**
Add two inputs for numbers and a "Calculate" button. Create a function that adds the two values together and displays them in the `outputDiv`.
*Warning:* Remember that `.value` is a string! You may need to use `Number(input.value)` to do math.

---

### Summary Table

| Input Type | HTML Tag | How to get data in JS |
| --- | --- | --- |
| **Text** | `<input type="text">` | `element.value` |
| **Color** | `<input type="color">` | `element.value` (Hex code) |
| **Checkbox** | `<input type="checkbox">` | `element.checked` (True/False) |

---

