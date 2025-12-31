## Lab 9: Fetching Real-World Data from APIs

**Objective:** Learn how to connect your website to the rest of the world. You will use the **Fetch API** to request data from a public server and display it on your page.

---

### Part 1: The "Live Data" HTML

We need a button to trigger the request and a container to hold the information we receive.

1. **Update your `index.html`:**
```html
<body>
    <h1>Daily Dog Fact</h1>

    <button id="fact-btn">Get New Fact</button>

    <div id="fact-container" style="margin-top: 20px; font-style: italic; color: #444;">
        Click the button to load a fact...
    </div>

    <script src="main.js"></script>
</body>

```



---

### Part 2: Using the Fetch API

Fetching data is an **asynchronous** process, meaning the browser starts the request and carries on with other tasks until the data "comes back" from the internet.

1. **Open `main.js**` and enter the following:

```javascript
const factBtn = document.getElementById('fact-btn');
const factContainer = document.getElementById('fact-container');

// 1. Define the Fetch Function
async function getDogFact() {
    factContainer.innerText = "Loading...";

    try {
        // 2. Make the request to a public API
        const response = await fetch('https://dogapi.dog/api/v2/facts');
        
        // 3. Convert the raw response into a JSON object
        const data = await response.json();

        // 4. Dig into the data to find the fact string
        // (Note: The structure depends on the specific API you use)
        const fact = data.data[0].attributes.body;

        // 5. Display it!
        factContainer.innerText = fact;

    } catch (error) {
        // Handle errors (like no internet or server down)
        console.error("Fetch failed:", error);
        factContainer.innerText = "Oops! Could not load a fact.";
    }
}

// 6. Hook it up to the button
factBtn.addEventListener('click', getDogFact);

```

---

### Part 3: How the "Fetch" Flow Works

The Fetch API uses a "Promise" system. Using `async` and `await` makes the code look cleaner and read like a regular list of instructions.

1. **`fetch(url)`**: Sends a "GET" request to the server.
2. **`response.json()`**: The server sends back a massive block of text. This method parses it into a JavaScript **Object** that we can easily read.
3. **Data Extraction**: We use "dot notation" (like `data.data[0]...`) to navigate the complex folders of information the API provides.

---

### Part 4: Practical Exercises

**Exercise A: The Visual Fetch**
There is an API for random dog **images** as well: `https://dog.ceo/api/breeds/image/random`.
Try creating a second button that fetches a random image URL and sets it as the `src` of an `<img>` tag on your page.

**Exercise B: The Weather Watcher**
Many APIs (like OpenWeather) require an "API Key" for security. Research a "No-Key" weather API or use the [JSONPlaceholder API](https://jsonplaceholder.typicode.com/) to practice fetching a list of "To-Do" items and displaying them in a `<ul>`.

**Exercise C: Error Simulation**
Purposely misspell the URL in your `fetch()` call (e.g., change `dogapi` to `dog-api-wrong`). Refresh your page and check your **Console**. You should see your `console.error` message appearing!

---

### Summary of Fetch Methods

| Command | Purpose |
| --- | --- |
| **`fetch(url)`** | Starts the network request. |
| **`await`** | Tells JS to wait for the server before moving to the next line. |
| **`response.json()`** | Turns the server's message into a readable JS Object. |
| **`try { ... } catch`** | Safety net that handles errors if the internet fails. |

---

**Next Step:** You've built a full "Input-Process-Output-Store-Fetch" flow! Would you like to wrap all these skills together into a **Final Project: A Personal Dashboard** that shows the time, a saved username, and a daily quote?

[How to fetch data from an API using JavaScript](https://www.youtube.com/watch?v=37vxWr0WgQk)

This video provides a great visual walkthrough of using the Fetch API to retrieve data from a server and display it dynamically on a webpage.
