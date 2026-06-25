# Part II — Widgets: Building Interactive User Interfaces

# Lesson 2.4 — The Button Widget

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what a Button widget is.
> * Learn why buttons differ from every other widget.
> * Understand events and event-driven programming.
> * Learn the major properties of a Button.
> * Create and customize buttons.
> * Learn how users interact with buttons.
> * Prepare for callbacks in the next lesson.

---

# Introduction

In the previous lesson, we surveyed the entire Panel widget library.

Today, we'll begin studying each widget in depth.

Our first widget is one of the most important:

```python
pn.widgets.Button()
```

Almost every application contains buttons.

Think about applications you use every day.

A banking app has:

* Login
* Transfer
* Pay Now

An online shopping site has:

* Add to Cart
* Buy Now
* Checkout

Google has:

* Search

Our future SGX Stock Monitor will have buttons like:

* Search
* Refresh Prices
* Add to Watchlist
* Export Portfolio
* Clear Portfolio

Buttons are everywhere.

But surprisingly...

they work very differently from other widgets.

---

# What Is a Button?

A Button represents an **action**.

Unlike a TextInput,

a Button does **not** store useful user data.

Instead,

it allows the user to say:

> "Do something now."

---

Imagine an elevator.

The floor buttons don't store information forever.

Instead,

pressing one sends a request.

```text
User

↓

Press Button

↓

Elevator Moves
```

The button's purpose is to trigger an action.

Panel buttons work exactly the same way.

---

# Buttons vs Input Widgets

Compare these two widgets.

TextInput

```text
Search

DBS
```

The important information is

```text
DBS
```

The widget stores the user's input.

---

Now consider a button.

```text
[ Search ]
```

What information is stored?

None.

The important part isn't the button itself.

The important part is **the click**.

---

# Buttons Represent Events

Buttons introduce an important programming concept.

An **event**.

An event is something that happens.

Examples include:

* Mouse click
* Keyboard press
* File upload
* Slider moved
* Checkbox changed
* Window resized

Applications spend most of their lives waiting for events.

---

# Event-Driven Programming

Earlier,

our programs executed from top to bottom.

```text
Start

↓

Line 1

↓

Line 2

↓

Line 3

↓

End
```

Interactive applications work differently.

```text
Application Starts

↓

Wait...

↓

User Clicks

↓

Do Something

↓

Wait...

↓

User Types

↓

Do Something

↓

Wait...
```

This style is called

**event-driven programming**.

Almost every GUI application works this way.

---

# Creating Our First Button

Let's create one.

```python
import panel as pn

pn.extension()

button = pn.widgets.Button(
    name="Search"
)

button.servable()
```

Run the application.

You'll see something like this.

```text
+----------------------+

[ Search ]

+----------------------+
```

Congratulations.

You've created your first Button widget.

---

# Understanding the Code

Let's examine it carefully.

```python
button = pn.widgets.Button(
    name="Search"
)
```

We're creating an object.

Just like:

```python
search = pn.widgets.TextInput()
```

Buttons are simply another widget class.

---

# The `name` Property

The text displayed on the button comes from

```python
name
```

Example:

```python
button = pn.widgets.Button(
    name="Refresh Prices"
)
```

Produces

```text
[ Refresh Prices ]
```

Changing

```python
button.name
```

changes the button label.

---

# The `button_type` Property

Buttons can communicate meaning through colour.

Panel provides several predefined button types.

```python
button = pn.widgets.Button(
    name="Search",
    button_type="primary"
)
```

The appearance changes to indicate that this is the primary action.

Panel supports several common button types.

| Button Type | Typical Meaning         |
| ----------- | ----------------------- |
| `"default"` | Normal action           |
| `"primary"` | Main action             |
| `"success"` | Successful operation    |
| `"warning"` | Use caution             |
| `"danger"`  | Potentially destructive |

---

# Choosing Button Types

Imagine our stock monitor.

```text
Search
```

Best choice:

```python
button_type="primary"
```

because searching is the main task.

---

```text
Export Portfolio
```

could use

```python
button_type="success"
```

because it completes a useful task.

---

```text
Delete Portfolio
```

should probably use

```python
button_type="danger"
```

to warn the user.

Good interfaces communicate intent visually.

---

# The `disabled` Property

Sometimes,

we don't want users clicking a button.

Example:

```python
button.disabled = True
```

The button becomes unavailable.

Users cannot click it.

Later,

we can enable it.

```python
button.disabled = False
```

---

# Why Disable Buttons?

Imagine our application is downloading market data.

We probably don't want users repeatedly clicking

```text
Refresh Prices
```

during the download.

Instead,

we temporarily disable the button.

```text
Loading...

[ Refresh Prices ]
```

Once loading finishes,

the button becomes active again.

---

# The `visible` Property

Buttons can also be hidden.

```python
button.visible = False
```

The button disappears.

Later,

```python
button.visible = True
```

makes it reappear.

---

# The `icon` Property

Many modern applications use icons.

For example,

instead of

```text
Refresh
```

we might display

```text
🔄 Refresh
```

Panel supports icons depending on the configured icon library.

Example:

```python
button = pn.widgets.Button(
    name="Refresh",
    icon="refresh"
)
```

Icons make interfaces easier to scan.

---

# Button Size

Like other widgets,

buttons support sizing.

```python
button.width = 200
```

or

```python
button.height = 60
```

Large buttons are often easier to click,

especially on touch devices.

---

# Building Our Interface

Let's combine our search box and button.

```python
import panel as pn

pn.extension()

title = pn.pane.Markdown("# SGX Stock Monitor")

search = pn.widgets.TextInput(
    name="Stock Symbol",
    placeholder="Example: DBS"
)

button = pn.widgets.Button(
    name="Search",
    button_type="primary"
)

dashboard = pn.Column(
    title,
    search,
    button
)

dashboard.servable()
```

Our application now looks something like this.

```text
----------------------------------------

SGX Stock Monitor

Stock Symbol

Example: DBS

[ Search ]

----------------------------------------
```

It feels much more like a real application.

---

# Clicking the Button

Try clicking it.

What happens?

Nothing.

That is expected.

The button exists.

The click is detected.

But no instructions have been attached.

Imagine installing a doorbell button without connecting any wires.

You can press it all day,

but no sound will be produced.

---

# Buttons Need Instructions

Think about a vending machine.

```text
Button

↓

Dispense Drink
```

Someone had to tell the machine:

> "When Button A is pressed,
> release a can of Coke."

Without those instructions,

nothing happens.

Panel works the same way.

We'll soon tell Panel:

> "When this button is clicked,
> search for the requested stock."

---

# Events Are Messages

You can think of a click as a message.

```text
User

↓

Click

↓

Button

↓

Application

↓

Respond
```

The button says,

> "The user clicked me."

The application then decides what to do.

---

# Separating Responsibilities

Notice the design.

The button is responsible for:

* Displaying itself
* Detecting clicks

The application is responsible for:

* Searching stocks
* Downloading data
* Updating charts
* Displaying results

The button never performs business logic itself.

This is another example of **Separation of Concerns**.

---

# Looking Ahead

Very soon,

our button will perform actions like this.

```text
User Types DBS

↓

Clicks Search

↓

Download Stock Data

↓

Update Chart

↓

Display Company Information

↓

Show Latest Price
```

Everything begins with one button click.

---

# Teacher's Notes

> Beginners sometimes think a Button "contains" an action. It doesn't. A Button only generates an event when the user clicks it.
>
> The application is responsible for deciding how to respond to that event. This separation makes Panel applications flexible. The same Button widget can perform completely different tasks depending on which callback function it is connected to.
>
> Understanding this distinction is essential before learning callbacks and reactive programming.

---

# Common Mistakes

### ❌ Mistake 1

Expecting a Button to remember information.

Buttons represent actions.

They do not store user input like a `TextInput`.

---

### ❌ Mistake 2

Using the wrong `button_type`.

Reserve `"danger"` for destructive actions and `"primary"` for the application's main action.

Visual consistency helps users understand your interface.

---

### ❌ Mistake 3

Leaving buttons enabled during long-running operations.

Temporarily disabling buttons can prevent duplicate requests and accidental repeated clicks.

---

### ❌ Mistake 4

Assuming a Button performs work automatically.

Without application logic attached to it, clicking a Button has no visible effect.

---

# Summary

In this lesson, you learned:

* A Button represents an action rather than user input.
* Buttons generate **events**, especially click events.
* Interactive applications are typically **event-driven**.
* The `name` property controls the button's label.
* The `button_type` property communicates the importance or nature of an action.
* Properties such as `disabled`, `visible`, `width`, and `height` behave similarly to other widgets.
* Buttons detect clicks, but your application decides how to respond.

You now understand the role of Buttons in a Panel application. The next step is teaching the application what to do when those Buttons are clicked.

---

# Exercises

## Exercise 1 — Build a Search Panel

Create a small application containing:

* A Markdown title
* A `TextInput` labelled **Stock Symbol**
* A `Button` labelled **Search**

Arrange them vertically using `pn.Column()`.

---

## Exercise 2 — Experiment with Button Types

Create five buttons using the same label but different `button_type` values:

* `"default"`
* `"primary"`
* `"success"`
* `"warning"`
* `"danger"`

Observe how each one communicates a different purpose.

---

## Exercise 3 — Design Your Dashboard Actions

List five actions your future SGX Stock Monitor should perform.

For each action:

* Choose a suitable button label.
* Choose an appropriate `button_type`.
* Explain why you selected that type.

Example:

| Action           | Label  | Button Type | Reason                    |
| ---------------- | ------ | ----------- | ------------------------- |
| Search for stock | Search | `primary`   | Main action users perform |

---

## Coming Up Next

In **Lesson 2.5 — Callbacks: Responding to User Actions**, we'll connect our first Button to Python code. You'll learn what callbacks are, how Panel executes functions in response to events, why callback functions are fundamental to interactive applications, and how clicking **Search** will finally begin triggering real behavior in our SGX Stock Monitor. This is where the application truly comes to life.
