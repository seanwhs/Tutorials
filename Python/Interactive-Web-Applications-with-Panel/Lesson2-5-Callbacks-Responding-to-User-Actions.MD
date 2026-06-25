# Part II — Widgets: Building Interactive User Interfaces

# Lesson 2.5 — Callbacks: Responding to User Actions

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what a callback is.
> * Learn why callbacks are the foundation of interactive applications.
> * Understand functions as reusable blocks of code.
> * Learn how Panel connects widgets to Python functions.
> * Understand event-driven execution.
> * Build your first callback.
> * Prepare the SGX Stock Monitor to respond to user actions.

---

# Introduction

At the end of the previous lesson, our application looked something like this.

```text
--------------------------------------------

SGX Stock Monitor

Stock Symbol

Example: DBS

[ Search ]

--------------------------------------------
```

It looks like a real application.

The user can:

* type

* click

* interact

But...

nothing actually happens.

Clicking the button does absolutely nothing.

Why?

Because the button doesn't know what it's supposed to do.

Today we're going to fix that.

---

# Buttons Need Instructions

Imagine buying a remote control.

It has buttons.

```text
Power

Volume +

Volume –

Channel +

Channel –
```

Suppose the batteries are missing.

What happens?

Nothing.

The buttons exist.

You can press them.

But pressing them produces no result.

Panel buttons are exactly the same.

---

# The Missing Piece

Currently we have

```python
button = pn.widgets.Button(
    name="Search"
)
```

This creates the button.

But nowhere have we written:

> "When the user clicks this button,
> perform a stock search."

That missing instruction is called a **callback**.

---

# What Is a Callback?

A callback is simply a Python function that is executed when an event occurs.

Another way to think about it is:

> **A callback tells the application what to do after something happens.**

---

Imagine a receptionist.

```text
Visitor Arrives

↓

Receptionist Calls Employee

↓

Employee Comes Down
```

The employee doesn't constantly watch the front door.

Instead,

the receptionist calls them only when needed.

The employee is acting like a callback.

---

# What Is an Event?

Recall the previous lesson.

An event is something that happens.

Examples include:

* clicking a button

* typing text

* moving a slider

* selecting a date

* uploading a file

Every event can trigger a callback.

---

# Understanding Functions

Before we discuss callbacks,

let's briefly review Python functions.

Suppose we write

```python
def say_hello():
    print("Hello")
```

What happened?

We created a function.

Did Python print

```text
Hello
```

No.

Nothing happened.

---

# Defining vs Executing

Many beginners confuse these two ideas.

Writing

```python
def say_hello():
    print("Hello")
```

creates the function.

Executing it requires

```python
say_hello()
```

Only then does Python print

```text
Hello
```

Callbacks work exactly the same way.

---

# Visualizing a Function

Think of a function as a machine.

```text
Function

↓

Wait

↓

Called

↓

Execute
```

Until someone calls it,

the function simply waits.

---

# Creating Our First Callback

Let's create a function.

```python
def search_stock(event):
    print("Searching...")
```

Notice something unusual.

Our function has a parameter.

```python
event
```

Why?

Because Panel provides information about the event that occurred.

We'll explore that later.

For now,

just remember that Button callbacks usually receive an event object.

---

# What Happens Now?

Still...

nothing happens.

Why?

Because we've only created the function.

We haven't connected it to the button.

---

# Connecting the Button

Panel provides the method

```python
button.on_click()
```

Example:

```python
button.on_click(search_stock)
```

This tells Panel:

> "Whenever this button is clicked,
> execute the function
> `search_stock`."

---

# Understanding the Syntax

Let's examine this carefully.

```python
button.on_click(search_stock)
```

Notice something.

We wrote

```python
search_stock
```

NOT

```python
search_stock()
```

This difference is extremely important.

---

# Why No Parentheses?

Suppose we write

```python
button.on_click(search_stock())
```

What happens?

Python immediately executes

```python
search_stock()
```

while the application starts.

That isn't what we want.

We want Panel to execute it

later,

after the user clicks.

Therefore,

we pass the function itself,

not the result of calling it.

---

Think of it this way.

Suppose a friend says

> "Call Alice tomorrow."

You write down

```text
Alice
```

You don't immediately phone her.

Similarly,

Panel stores the function,

then calls it later.

---

# The Complete Program

```python
import panel as pn

pn.extension()

def search_stock(event):
    print("Searching...")

button = pn.widgets.Button(
    name="Search"
)

button.on_click(search_stock)

button.servable()
```

---

# What Happens When We Run It?

When the application starts,

this happens.

```text
Create Button

↓

Create Function

↓

Connect Button

↓

Wait
```

Nothing else happens.

---

Now the user clicks.

```text
User Clicks

↓

Button Detects Click

↓

Panel Calls Function

↓

Searching...
```

The callback finally executes.

---

# Understanding the Flow

Let's visualize the entire process.

```text
Application Starts

↓

Button Created

↓

Callback Registered

↓

Application Waits

↓

User Clicks Button

↓

Panel Receives Event

↓

Callback Executes

↓

Application Waits Again
```

Notice something.

The application spends most of its life waiting.

Interactive programs don't continuously execute code.

They respond to events.

---

# What Is the Event Object?

Earlier we wrote

```python
def search_stock(event):
```

Where does

```python
event
```

come from?

Panel automatically creates it.

Conceptually,

something like this happens.

```text
Mouse Click

↓

Panel Creates Event

↓

Send Event To Callback
```

The event contains useful information,

such as:

* which widget generated the event

* what changed

* when it happened

Most of the time,

you won't need all this information,

but it's available.

---

# Ignoring the Event

If we don't need the event,

we still include the parameter.

```python
def search_stock(event):
    print("Searching...")
```

We simply choose not to use it.

This is perfectly normal.

---

# Our First Real SGX Example

Let's make the callback a little more interesting.

```python
import panel as pn

pn.extension()

search = pn.widgets.TextInput(
    name="Stock Symbol",
    placeholder="Example: DBS"
)

button = pn.widgets.Button(
    name="Search",
    button_type="primary"
)

def search_stock(event):
    print("Searching for stock...")

dashboard = pn.Column(
    search,
    button
)

button.on_click(search_stock)

dashboard.servable()
```

Now,

when the button is clicked,

our callback executes.

---

# But It Still Doesn't Search

The callback currently prints

```text
Searching for stock...
```

It doesn't actually search SGX.

Why?

Because we haven't learned how to read

```python
search.value
```

yet.

That comes next.

Today,

our goal is understanding the connection between:

Button

↓

Callback

↓

Function

---

# Multiple Buttons

Each button can have its own callback.

```python
search_button.on_click(search_stock)

refresh_button.on_click(refresh_prices)

export_button.on_click(export_portfolio)
```

Each performs a different job.

The buttons don't know what the functions do.

They simply trigger them.

---

# One Callback, Many Buttons

Interestingly,

multiple buttons can share the same callback.

```python
button1.on_click(update_data)

button2.on_click(update_data)
```

This avoids duplicate code.

The callback becomes reusable.

---

# Why Callbacks Matter

Without callbacks,

applications would never respond to users.

Imagine Microsoft Word.

Click

```text
Save
```

Nothing happens.

Click

```text
Print
```

Nothing happens.

Click

```text
Bold
```

Nothing happens.

Every modern GUI application depends on callbacks.

---

# Separation of Responsibilities

Notice how clean this design is.

The Button is responsible for:

* displaying itself

* detecting clicks

Panel is responsible for:

* calling the callback

The callback is responsible for:

* performing the application's work

Each part has one responsibility.

This follows the **Separation of Concerns** principle we introduced in Part I.

---

# Teacher's Notes

> Understanding callbacks is one of the biggest milestones in learning GUI programming.
>
> Many beginners are accustomed to writing programs that execute from top to bottom and then terminate. Interactive applications are different—they spend most of their time waiting.
>
> Rather than controlling the execution order directly, you write small functions and register them with widgets. Panel then decides *when* those functions should execute based on user interaction.
>
> This event-driven model is used by nearly every modern GUI framework, including Panel, Qt, Tkinter, JavaFX, SwiftUI, Flutter, React, and many others.

---

# Common Mistakes

### ❌ Mistake 1

Calling the callback immediately.

Incorrect:

```python
button.on_click(search_stock())
```

Correct:

```python
button.on_click(search_stock)
```

Pass the function itself,

not the result of executing it.

---

### ❌ Mistake 2

Forgetting the `event` parameter.

Panel Button callbacks are normally defined as:

```python
def callback(event):
```

even if the event isn't used.

---

### ❌ Mistake 3

Expecting the callback to execute immediately.

Callbacks execute **only when the associated event occurs**.

---

### ❌ Mistake 4

Putting too much code inside a callback.

A callback should coordinate work, not perform every task itself.

As applications grow, callbacks should call other functions that handle searching, downloading data, updating charts, and so on.

---

# Summary

In this lesson, you learned:

* A callback is a Python function that executes when an event occurs.
* Buttons generate click events.
* `button.on_click()` connects a Button to a callback function.
* Functions should be passed without parentheses when registering callbacks.
* Panel automatically supplies an `event` object to Button callbacks.
* Interactive applications spend most of their time waiting for user events.
* Event-driven programming is the foundation of modern GUI applications.

Our SGX Stock Monitor can now respond to button clicks. In the next lesson, we'll make those clicks meaningful by reading the text entered into our search box.

---

# Exercises

## Exercise 1 — Your First Callback

Create a Button labelled **Refresh Prices**.

Write a callback that prints:

```text
Refreshing market data...
```

Connect the callback using `on_click()`.

---

## Exercise 2 — Multiple Buttons

Create three buttons:

* Search
* Refresh
* Export

Give each button its own callback that prints a different message.

Observe how each button triggers a different function.

---

## Exercise 3 — Draw the Event Flow

Without looking back at the lesson, draw a diagram showing what happens after the user clicks a Button.

Try to include:

* User
* Button
* Event
* Panel
* Callback
* Python Function
---
## Callbacks in Python and Javascript

While the term "callback" refers to the same fundamental concept in both languages—passing a function as an argument to another function to be executed later—the **implementation and architectural reasons** for using them differ significantly.

---

### 1. The Core Context: Synchronous vs. Asynchronous

The most significant difference lies in the JavaScript event loop versus Python's primary execution model.

* **JavaScript (Event-Driven/Non-blocking):** JavaScript is single-threaded and non-blocking by design. Callbacks are the **primary mechanism** for handling asynchronous operations (like network requests, timers, or file I/O). Because the engine cannot stop execution while waiting for a network response, it relies on callbacks (and later, Promises/Async-Await) to handle the data once it eventually arrives.
* **Python (Procedural/Synchronous):** Standard Python execution is synchronous and blocking. Callbacks in Python are typically used for **functional programming patterns** (like `map`, `filter`, or `sort`) or **event-driven frameworks** (like GUI libraries or socket servers). They are rarely used as a primary solution for asynchronous I/O in standard synchronous code.

---

### 2. Implementation Comparison

#### JavaScript: The "Continuation" Model

In JS, a callback is often used to continue execution after an asynchronous task completes.

```javascript
// JavaScript: Handling an async task with a callback
function fetchData(callback) {
  setTimeout(() => {
    callback("Data received");
  }, 1000);
}

fetchData((result) => console.log(result));

```

#### Python: The "Functional/Event" Model

In Python, callbacks are often passed to higher-order functions or registration systems.

```python
# Python: Using a callback for sorting (Functional style)
names = ["Alice", "Bob", "Charlie"]
# The function 'len' acts as the callback for the key parameter
sorted_names = sorted(names, key=len) 
print(sorted_names)

```

---

### 3. Key Differences at a Glance

| Feature | JavaScript | Python |
| --- | --- | --- |
| **Primary Use Case** | Asynchronous control flow (I/O, timers). | Functional operations, event handling, or plugin hooks. |
| **Execution Flow** | Heavily relies on the Event Loop to trigger callbacks. | Typically executed in a linear, synchronous stack. |
| **"Callback Hell"** | Common issue when nesting multiple async operations. | Rare; avoided by synchronous design or `asyncio`. |
| **Evolution** | Moved from Callbacks $\rightarrow$ Promises $\rightarrow$ Async/Await. | Historically procedural; now uses `asyncio` (coroutines) for async. |

---

### 4. Evolution: The Shift Away from Callbacks

Both languages have matured to move away from "pure" callback structures:

* **JavaScript:** Explicitly moved to **Promises and Async/Await** to flatten the "Callback Hell" (the pyramid of doom where code moves horizontally instead of vertically).
* **Python:** Introduced the **`asyncio` library**. Instead of using callbacks for I/O, Python uses `async/await` syntax, which allows developers to write asynchronous code that looks and behaves like synchronous, procedural code.

Would you like to explore how to convert a callback-based pattern into the `async/await` syntax for either language?

---

# Coming Up Next

In **Lesson 2.6 — Reading User Input with `value`**, we'll connect our search box and our callback together. You'll learn how to access the text entered by the user through the widget's `value` property, validate that input, and display it back to the user. By the end of the lesson, clicking **Search** will no longer just print a generic message—it will retrieve the actual SGX stock symbol entered by the user, marking the first real interaction between multiple widgets in our application.
