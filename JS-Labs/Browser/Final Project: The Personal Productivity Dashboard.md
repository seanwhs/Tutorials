## Final Project: The Personal Productivity Dashboard

**Objective:** Combine everything you’ve learned—DOM manipulation, Template Literals, Event Listeners, LocalStorage, and the Fetch API—into a single, functional "Start Page" for your browser.

---

### Part 1: The Dashboard Structure (HTML)

We need a layout that includes a clock, a greeting section, and a place for our external data.

1. **Update your `index.html`:**
```html
<body>
    <div id="dashboard">
        <h1 id="clock">00:00:00</h1>
        <h2 id="greeting">Loading...</h2>

        <div id="settings">
            <input type="text" id="name-input" placeholder="Change Name">
            <button id="save-btn">Update</button>
        </div>

        <div id="quote-box">
            <p id="quote-text">"Fetching inspiration..."</p>
            <p id="quote-author"></p>
        </div>
    </div>

    <script src="main.js"></script>
</body>

```



---

### Part 2: The Logic (JavaScript)

This script manages three separate "systems" at once.

1. **Open `main.js**` and enter the following:

```javascript
// --- 1. CLOCK SYSTEM ---
function updateTime() {
    const now = new Date();
    const timeString = now.toLocaleTimeString();
    document.getElementById('clock').innerText = timeString;
}
setInterval(updateTime, 1000); // Run every second
updateTime(); // Run immediately on load

// --- 2. USER SYSTEM (LocalStorage) ---
const nameInput = document.getElementById('name-input');
const saveBtn = document.getElementById('save-btn');
const greeting = document.getElementById('greeting');

function loadName() {
    const savedName = localStorage.getItem('dashboard_name') || 'Guest';
    greeting.innerText = `Good Day, ${savedName}`;
}

saveBtn.addEventListener('click', () => {
    localStorage.setItem('dashboard_name', nameInput.value);
    loadName();
    nameInput.value = "";
});
loadName();

// --- 3. QUOTE SYSTEM (Fetch API) ---
async function getQuote() {
    try {
        const response = await fetch('https://api.quotable.io/random');
        const data = await response.json();
        
        document.getElementById('quote-text').innerText = `"${data.content}"`;
        document.getElementById('quote-author').innerText = `- ${data.author}`;
    } catch (error) {
        document.getElementById('quote-text').innerText = "Stay positive!";
    }
}
getQuote();

```

---

### Part 3: How it Works Together

This project uses the **Event Loop** and **Asynchronous Programming** concepts to keep the page alive.

* **`setInterval`**: This is a timer that keeps the clock ticking without you having to refresh the page.
* **Persistent State**: Even if you close the tab, the `dashboard_name` stays in your browser's memory.
* **External Integration**: Your dashboard reaches out to a global server to grab a new quote every time it loads.

---

### Part 4: Final Challenges (Make it Yours!)

**Challenge A: The Background Personalizer**
Add a new input field where the user can type a URL of an image. Save that URL to `localStorage` and set it as the `document.body.style.backgroundImage`.

**Challenge B: The Greeting Logic**
Modify the `updateTime` function to check the hour.

* If it's before 12pm, show "Good Morning".
* If it's between 12pm and 6pm, show "Good Afternoon".
* Otherwise, show "Good Evening".

**Challenge C: CSS Styling**
Center everything on the page and use a modern font.

```css
/* Add this to a <style> tag in your HTML head */
body {
    background: #2c3e50;
    color: white;
    font-family: 'Segoe UI', sans-serif;
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100vh;
    text-align: center;
}

```

---

### Graduation Summary

You have successfully progressed through:

1. **Debugging** with the Console.
2. **Dynamic Strings** with Template Literals.
3. **User Input** via Prompts and HTML Fields.
4. **The DOM** to change the webpage live.
5. **LocalStorage** to keep data forever.
6. **Fetch API** to talk to the internet.

**Congratulations! You've built your first modern web application.** Would you like to explore how to host this website online for free using a service like **GitHub Pages** so you can share the link with others?
