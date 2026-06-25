# Part II — Widgets: Building Interactive User Interfaces

# Lesson 2.1 — Introduction to Widgets

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what a widget is.
> * Explain the role of widgets in interactive applications.
> * Distinguish between Panes and Widgets.
> * Understand how widgets fit into the Panel object hierarchy.
> * Learn why nearly every modern application is built around user input.
> * Build your first interactive Panel widget.
> * Prepare the SGX Stock Monitor for user interaction.

---

# Introduction

At the end of Part I, we built this application.

```text
--------------------------------------------------

SGX Stock Monitor

Welcome!

Search Box (Coming Soon)

Market Overview     Watchlist

--------------------------------------------------
```

It looked like a dashboard.

But there was one problem.

You couldn't actually do anything.

You couldn't:

* type
* click
* select
* search
* scroll
* change values

Our application was completely static.

In other words...

It behaved more like a webpage than an application.

Today that changes.

---

# Static vs Interactive Applications

Let's compare two websites.

Website A

```text
Weather Today

Temperature: 30°C

Humidity: 82%

Sunny
```

You simply read the information.

Nothing changes.

---

Website B

```text
Search City

[____________]

[ Search ]
```

Now the user participates.

They can:

* type
* click
* search
* receive new results

This is an interactive application.

---

# What Makes Software Interactive?

Almost every modern application asks users to provide information.

Think about applications you use every day.

Google

```text
Search

[________________]
```

---

YouTube

```text
Search Videos

[________________]
```

---

Banking App

```text
Username

[______________]

Password

[______________]
```

---

Shopping Website

```text
Search Products

[______________]

Category ▼

Price ▼
```

All of these applications have something in common.

They ask the user for input.

---

# What Is User Input?

User input is any information entered or selected by the user.

Examples include:

* typing text
* clicking buttons
* selecting checkboxes
* moving sliders
* choosing dates
* uploading files
* selecting colours

Without user input,

applications would never change.

---

# Meet the Widget

A **Widget** is an object that collects information from the user.

Earlier we learned about Panes.

Panes display information.

Widgets collect information.

This distinction is extremely important.

---

# Comparing Panes and Widgets

Think of a classroom.

The projector screen displays information.

Students look at it.

The projector doesn't ask questions.

It only presents information.

A projector is similar to a Pane.

---

Now think about a worksheet.

Students write answers.

The worksheet receives information.

A worksheet behaves more like a Widget.

---

# Pane vs Widget

| Pane                 | Widget               |
| -------------------- | -------------------- |
| Displays information | Collects information |
| Usually read-only    | Usually interactive  |
| Output               | Input                |
| User observes        | User interacts       |

---

# Examples of Panes

We have already used one.

```python
pn.pane.Markdown()
```

Other Panes include:

```python
pn.pane.HTML()

pn.pane.Image()

pn.pane.DataFrame()

pn.pane.Str()
```

These display information.

---

# Examples of Widgets

Panel provides many widgets.

Examples include:

```python
pn.widgets.Button()

pn.widgets.TextInput()

pn.widgets.FloatSlider()

pn.widgets.Checkbox()

pn.widgets.Select()

pn.widgets.DatePicker()

pn.widgets.FileInput()
```

Unlike Panes,

these allow the user to interact with the application.

---

# The Widget Library

Panel contains dozens of widgets.

Some of the most common are:

```text
Text Input

Text Area

Password

Button

Toggle

Checkbox

Radio Buttons

Dropdown

Slider

Date Picker

File Upload

Color Picker

Progress Bar

Spinner
```

Throughout Part II,

we'll study every major widget in detail.

---

# Widgets Are Objects Too

Remember the object model from Part I.

Widgets are simply another type of object.

```text
Viewable

│

├── Pane

├── Widget

├── Layout

└── Template
```

This means widgets can:

* be stored in variables
* be placed inside layouts
* have properties
* have methods

Everything you've learned about objects still applies.

---

# Our First Widget

Let's create one.

```python
import panel as pn

pn.extension()

search = pn.widgets.TextInput()

search.servable()
```

Run the application.

You should see something similar to:

```text
+--------------------------------+

_________________________

+--------------------------------+
```

Congratulations.

You've created your first widget.

---

# Understanding the Code

Let's examine it.

```python
search = pn.widgets.TextInput()
```

Notice the pattern.

Earlier we wrote:

```python
pn.pane.Markdown()
```

Now we're writing:

```python
pn.widgets.TextInput()
```

The structure is almost identical.

Only the category changes.

---

# Breaking It Down

Let's examine each part.

```python
pn
```

The Panel library.

---

```python
widgets
```

The widgets module.

---

```python
TextInput
```

The specific widget class.

---

```python
()
```

Create a new object.

---

Everything follows the same object-oriented pattern we've already learned.

---

# What Happens Internally?

Conceptually,

this occurs.

```text
Python

↓

Create TextInput Object

↓

Store Object

↓

Register Object

↓

Browser Displays Text Box
```

Again,

the browser is displaying an object,

not drawing directly from Python.

---

# Why Doesn't It Say "Search"?

Notice something.

Our widget is blank.

```text
______________________
```

How does the user know what it's for?

They don't.

We'll improve this shortly.

---

# Using the `name` Property

Most widgets have a property called

```python
name
```

It provides a label.

Example:

```python
search = pn.widgets.TextInput(
    name="Search Stock"
)
```

Now the application becomes:

```text
Search Stock

_____________________
```

Much clearer.

---

# Understanding Keyword Arguments

Notice this syntax.

```python
TextInput(
    name="Search Stock"
)
```

This is called a **keyword argument**.

Instead of passing values by position,

we pass them using names.

Python then knows exactly what each value means.

---

For example,

this is much clearer than

```python
TextInput("Search Stock")
```

because we immediately know

that the text is the widget's name.

---

# Adding a Placeholder

Most search boxes contain hint text.

For example:

```text
Search Stock

DBS
```

The grey text disappears

when the user begins typing.

This is called a

**placeholder**.

---

We can create one.

```python
search = pn.widgets.TextInput(
    name="Search Stock",
    placeholder="Enter SGX stock symbol"
)
```

The browser now displays something like:

```text
Search Stock

Enter SGX stock symbol
```

until the user types.

---

# Why Use Placeholders?

Placeholders provide examples.

Instead of forcing users to guess,

they communicate expectations.

Good placeholders answer questions like:

* What should I type?
* What format should I use?
* Is this field optional?

They improve usability without adding clutter to the interface.

---

# Our First Useful Interface

Let's combine a heading with our widget.

```python
import panel as pn

pn.extension()

title = pn.pane.Markdown("# SGX Stock Monitor")

search = pn.widgets.TextInput(
    name="Search Stock",
    placeholder="Enter SGX stock symbol"
)

dashboard = pn.Column(
    title,
    search
)

dashboard.servable()
```

Now our application looks like this.

```text
----------------------------------------

SGX Stock Monitor

Search Stock

Enter SGX stock symbol

----------------------------------------
```

For the first time,

our application accepts user input.

---

# But Nothing Happens...

Try typing.

You'll notice something.

The text changes.

But...

nothing else changes.

That's perfectly normal.

Right now,

the widget simply stores information.

Nothing is listening to it yet.

Think of a doorbell that isn't connected to a bell.

You can press the button,

but nothing happens.

In later lessons,

we'll connect widgets to callbacks and reactive functions.

Then typing into the search box will trigger actions.

---

# The Life Cycle of a Widget

Let's trace what happens when the application starts.

```text
Application Starts

↓

Create TextInput Widget

↓

Display Widget

↓

User Types

↓

Widget Stores Value

↓

Wait For Instructions
```

Notice the last step.

The widget stores the user's input,

but it doesn't know what to do with it.

That responsibility belongs to our application logic.

---

# Teacher's Notes

> Many beginners expect widgets to "do something" automatically. They don't.
>
> A widget's primary responsibility is to collect and store user input. It does not decide how that input should be used. This separation is intentional and follows the principle of Separation of Concerns introduced in Part I.
>
> In the next few lessons, you'll learn how to retrieve a widget's value, respond to changes, and connect multiple widgets together to create interactive behavior.

---

# Common Mistakes

### ❌ Mistake 1

Confusing Panes with Widgets.

Remember:

* Panes display output.
* Widgets collect input.

---

### ❌ Mistake 2

Expecting a widget to perform actions automatically.

Widgets collect information.

Your code decides what happens next.

---

### ❌ Mistake 3

Creating widgets without labels.

Users should understand the purpose of every input field.

The `name` property usually provides that context.

---

### ❌ Mistake 4

Using vague placeholders.

Instead of:

```text
Enter text...
```

prefer:

```text
Enter SGX stock symbol
```

Specific guidance reduces user confusion.

---

# Summary

In this lesson, you learned:

* Widgets are interactive objects that collect user input.
* Widgets differ from Panes, which display information.
* Panel includes a rich library of widgets for many types of input.
* A `TextInput` widget allows users to enter text.
* The `name` property labels a widget.
* The `placeholder` property provides example input.
* Widgets store user input but do not act on it automatically.

Our SGX Stock Monitor has taken its first step toward becoming a truly interactive application.

---

# Exercises

## Exercise 1 — Build a Search Box

Create a `TextInput` widget with:

* Name: **Search SGX Stock**
* Placeholder: **Example: DBS**

Display it beneath a Markdown heading.

---

## Exercise 2 — Compare a Pane and a Widget

Create an application containing:

* A Markdown pane displaying **"Search"**
* A `TextInput` widget labelled **"Search Stock"**

Observe how the Pane displays information while the Widget collects information.

---

## Exercise 3 — Design Future Inputs

Think about the SGX Stock Monitor you'll build throughout this tutorial.

List five pieces of information the user might need to enter.

For each, identify the type of widget you think would be appropriate.

Example:

| Information        | Possible Widget |
| ------------------ | --------------- |
| Stock Symbol       | TextInput       |
| Refresh Interval   | Slider          |
| Watchlist Category | Select          |

---

## Coming Up Next

In **Lesson 2.2 — Understanding Widget Properties**, we'll dive much deeper into widgets. You'll learn how widgets store information, explore essential properties such as `name`, `value`, `disabled`, and `visible`, and discover that widgets are much more than visual controls—they are Python objects with state that your application can read and modify. This understanding will form the foundation for every interactive feature we build in the SGX Stock Monitor.
