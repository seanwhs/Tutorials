## Lab 3: Writing to the DOM (Document Object Model)

**Objective:** Move your output from the hidden Developer Tools console onto the actual webpage using JavaScript to manipulate HTML elements.

---

### Part 1: Setting Up the HTML Structure

To put text on a page professionally, we need a "placeholder" in our HTML. We use an **ID** so JavaScript can find exactly where the text should go.

1. **Update your `index.html**` body to look like this:
```html
<body>
    <h1 id="title">Welcome to my Site</h1>

    <div id="output-area"></div>

    <script src="main.js"></script>
</body>

```



---

### Part 2: The JavaScript Logic

We will use `document.getElementById()` to "grab" that empty div and fill it with our user data.

1. **Open `main.js**` and enter the following:

```javascript
// 1. Capture Data
const name = prompt("What is your name?");
const color = prompt("What is your favorite color?");

// 2. Select the HTML Element
// We store the 'div' in a variable called displayBox
const displayBox = document.getElementById('output-area');

// 3. Inject Content using innerHTML and Backticks
displayBox.innerHTML = `
    <h2>User Profile</h2>
    <p><strong>Name:</strong> ${name}</p>
    <p><strong>Favorite Color:</strong> <span style="color: ${color}">${color}</span></p>
`;

// 4. Change an existing element
document.getElementById('title').innerText = `Hello, ${name}!`;

```

---

### Part 3: Key Concepts

#### 1. The DOM (Document Object Model)

Think of your HTML as a tree. JavaScript uses the "DOM" to climb that tree and change the leaves (text) or the branches (tags).

#### 2. `.innerText` vs `.innerHTML`

* **`.innerText`**: Use this when you only want to change plain text. It is safer for simple names or numbers.
* **`.innerHTML`**: Use this when you want to inject **new HTML tags** (like `<h2>` or `<strong>`) into the page.

#### 3. Dynamic Styling

Notice in the code above how we used `${color}` inside a style attribute. This allows the user to actually change the look of the website just by typing a color name!

---

### Part 4: Practical Exercises

**Exercise A: The Background Changer**
You can change the style of the entire page! Try adding this line to your script:
`document.body.style.backgroundColor = color;`

**Exercise B: The "About Me" Section**
Ask the user for their "Job Title" and "Company." Create a new `prompt` for each and use `.innerHTML` to display a professional-looking business card on the screen.

**Exercise C: Math Results**
Ask for two numbers. Use `innerHTML` to display a sentence like:
*"The sum of [Num1] and [Num2] is **[Result]**"*

---

### Comparison: Console vs. Webpage

| Feature | `console.log()` | `innerHTML` / `innerText` |
| --- | --- | --- |
| **Visibility** | Hidden (Developer Tools) | Visible to every user |
| **Formatting** | Plain text / limited CSS | Full HTML & CSS capabilities |
| **Purpose** | Debugging and testing | Building the User Interface (UI) |

---

**Next Step:** Your page currently runs once and then stops. Would you like to learn how to use a **Button** so that these prompts only happen when a user clicks something?
