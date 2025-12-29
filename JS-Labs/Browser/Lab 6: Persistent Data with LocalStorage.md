## Lab 6: Persistent Data with LocalStorage

**Objective:** Learn how to save user data so it survives a page refresh. You will use the **Web Storage API** to store, retrieve, and display data locally in the browser.

---

### Part 1: The "Stay-Put" HTML

We will use the same input structure as the previous lab, but we’ll add a "Clear Storage" button to help us manage our data.

1. **Update your `index.html`:**
```html
<body>
    <h1>Permanent Profile</h1>

    <input type="text" id="pref-name" placeholder="Enter your name">
    <button id="save-btn">Save Name</button>
    <button id="clear-btn">Forget Me</button>

    <h2 id="greeting">Welcome back, Guest!</h2>

    <script src="main.js"></script>
</body>

```



---

### Part 2: Saving and Loading Logic

The browser provides a `localStorage` object. It works like a tiny database inside your browser that stores data as **Key/Value pairs**.

1. **Open `main.js**` and enter the following:

```javascript
const nameInput = document.getElementById('pref-name');
const saveBtn = document.getElementById('save-btn');
const clearBtn = document.getElementById('clear-btn');
const greeting = document.getElementById('greeting');

// 1. Function to update the heading
function updateGreeting(name) {
    if (name) {
        greeting.innerText = `Welcome back, ${name}!`;
    } else {
        greeting.innerText = "Welcome, Guest!";
    }
}

// 2. Check for saved data when the page loads
const savedName = localStorage.getItem('user_name');
updateGreeting(savedName);

// 3. Save data to LocalStorage
saveBtn.addEventListener('click', () => {
    const nameToSave = nameInput.value;
    localStorage.setItem('user_name', nameToSave); // (Key, Value)
    updateGreeting(nameToSave);
    nameInput.value = ""; 
});

// 4. Clear data from LocalStorage
clearBtn.addEventListener('click', () => {
    localStorage.removeItem('user_name');
    updateGreeting(null);
});

```

---

### Part 3: How LocalStorage Works

`localStorage` stores data with no expiration date. This means even if you close the browser tab or restart your computer, the data stays there.

| Method | Purpose | Example |
| --- | --- | --- |
| **`setItem(key, value)`** | Saves data to the browser | `localStorage.setItem('theme', 'dark')` |
| **`getItem(key)`** | Retrieves saved data | `localStorage.getItem('theme')` |
| **`removeItem(key)`** | Deletes a specific item | `localStorage.removeItem('theme')` |
| **`clear()`** | Deletes EVERYTHING in storage | `localStorage.clear()` |

---

### Part 4: Practical Exercises

**Exercise A: The Inspector**
Open your browser, right-click and select **Inspect**. Go to the **Application** tab (it might be under a `>>` icon). Click on **Local Storage** in the left sidebar. Watch this area as you click your "Save" and "Forget" buttons!

**Exercise B: Theme Preference**
Create a button that toggles the page background between "Light" and "Dark" mode. Use `localStorage` to save the user's choice so that when they return, the page is already in their preferred mode.

**Exercise C: JSON Objects**
`localStorage` only stores strings. If you want to store a whole user object (name, age, and city), you must use `JSON.stringify()` to save it and `JSON.parse()` to read it. Try saving an entire object!

---

