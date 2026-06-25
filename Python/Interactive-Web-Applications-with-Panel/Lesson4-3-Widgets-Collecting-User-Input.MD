# Part IV — Building the Panel User Interface

# Lesson 4.3 — Understanding Widgets: Collecting User Input

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what widgets are.
> * Learn why widgets exist.
> * Understand how users interact with Panel applications.
> * Learn the most common Panel widgets.
> * Understand widget properties and values.
> * Learn how to read widget values.
> * Understand widget state.
> * Learn how widgets fit into Panel's reactive programming model.
> * Build the first interactive components of our SGX Stock Monitor.

---

# Introduction

In the previous lesson,

we learned about **Panes**.

Panes display information.

Examples include:

* Text
* Tables
* Images
* Charts
* Markdown

But displaying information is only half of a dashboard.

Users also need a way to interact with it.

Questions like:

* Which stock should I search?
* Which market should I view?
* Which date range should I select?
* Which chart type do I prefer?

This is where **Widgets** come in.

---

# What Is a Widget?

A **Widget** is a Panel component that allows users to

> **provide input to your application.**

Think of widgets as the controls of your dashboard.

Examples include:

* Text boxes
* Buttons
* Drop-down lists
* Checkboxes
* Sliders
* Date pickers

---

# Panes vs Widgets

This is one of the most important distinctions in Panel.

| Panes               | Widgets             |
| ------------------- | ------------------- |
| Display information | Collect information |
| Output              | Input               |
| Read-only           | Interactive         |
| Show data           | Receive data        |

Think of them as opposites.

---

# A Real-World Example

Imagine using an ATM.

The screen displays information.

↓

**Pane**

The keypad lets you enter numbers.

↓

**Widget**

Every interactive application contains both.

---

# Our SGX Dashboard

Our application will eventually look something like this.

```text
+------------------------------------------------+

Stock Symbol

+-------------+

| D05         |   ← TextInput Widget

+-------------+

[ Search ]        ← Button Widget

----------------------------------

DBS Group Holdings

Price: SGD 41.35

Volume: 3,200,000

Price Chart

+------------------------------------------------+
```

Notice that:

* Widgets collect information.
* Panes display results.

---

# Widget Architecture

A Panel application now looks like this.

```text
User

↓

Widgets

↓

Python Code

↓

MarketDataService

↓

Financial API

↓

Python Objects

↓

Panes

↓

Browser
```

Widgets and panes work together.

---

# Creating Your First Widget

Let's create a text input box.

```python
import panel as pn

pn.extension()

symbol_input = pn.widgets.TextInput()
```

Congratulations!

You've just created your first widget.

---

# Understanding the Code

Let's examine it carefully.

```python
pn.widgets
```

This module contains Panel's built-in widgets.

Think of it as a toolbox.

Inside are dozens of different controls.

---

```python
TextInput()
```

creates a single-line text box.

Users can type into it.

---

# Displaying the Widget

Just like panes,

widgets can be displayed.

```python
symbol_input.servable()
```

or

```python
pn.Column(symbol_input).servable()
```

When the application starts,

the browser displays an editable text box.

---

# Widget Properties

Widgets contain information.

For example,

our text box has many properties.

Examples include:

* value
* name
* placeholder
* width
* disabled

Every widget has different properties,

but many share common ones.

---

# The Most Important Property

For nearly every widget,

the most important property is

```python
.value
```

This stores the widget's current value.

---

# Reading Widget Values

Suppose the user types

```text
D05
```

into the text box.

Python can read it.

```python
symbol = symbol_input.value
```

Now

```python
symbol
```

contains

```text
D05
```

This is how your application receives user input.

---

# Thinking About State

Widgets remember information.

This is called

> **State**

For example,

suppose the user enters

```text
O39
```

The widget remembers it.

Later,

when Python asks

```python
symbol_input.value
```

the widget returns

```text
O39
```

The widget stores its current state.

---

# Why State Matters

Without state,

your application wouldn't know

what the user typed.

Widgets act like tiny containers,

holding information until your program needs it.

---

# Adding Labels

Most widgets allow a descriptive name.

Example

```python
pn.widgets.TextInput(

    name="Stock Symbol"

)
```

The browser now displays

```text
Stock Symbol

+------------+

|            |

+------------+
```

Labels make dashboards easier to understand.

---

# Adding Placeholder Text

Instead of an empty box,

we can guide the user.

```python
pn.widgets.TextInput(

    placeholder="Enter SGX Symbol"

)
```

Initially,

the box displays

```text
Enter SGX Symbol
```

Once the user begins typing,

the placeholder disappears.

---

# Setting Default Values

Sometimes,

we want a starting value.

Example

```python
pn.widgets.TextInput(

    value="D05"

)
```

When the application opens,

the text box already contains

```text
D05
```

This is often useful for demonstrations.

---

# Common Widgets

Panel provides many widgets.

Some of the most useful include:

| Widget          | Purpose                |
| --------------- | ---------------------- |
| `TextInput`     | Enter text             |
| `Button`        | Perform an action      |
| `Select`        | Dropdown list          |
| `Checkbox`      | True / False           |
| `FloatSlider`   | Choose a decimal value |
| `IntSlider`     | Choose an integer      |
| `DatePicker`    | Select a date          |
| `PasswordInput` | Enter passwords        |

We'll learn each of these throughout the tutorial.

---

# The Button Widget

One of the most important widgets is

```python
pn.widgets.Button()
```

Unlike a text box,

buttons don't store text.

Instead,

they signal that the user wants something to happen.

Examples include:

* Search
* Refresh
* Save
* Export
* Delete

---

# Our First Search Button

For our stock monitor,

we'll create

```python
search_button = pn.widgets.Button(

    name="Search"

)
```

The browser displays

```text
[ Search ]
```

Soon,

clicking it will retrieve stock prices.

---

# Widgets Don't Perform Actions

This surprises many beginners.

Creating a button

does **not**

make it do anything.

```python
button = pn.widgets.Button()
```

creates the widget.

It does **not** define what happens when it is clicked.

We'll learn event handling in the next lesson.

---

# Thinking Like an Application

Imagine our dashboard.

The user enters

```text
D05
```

Then clicks

```text
Search
```

The workflow becomes

```text
TextInput

↓

Stores "D05"

↓

Button Click

↓

Python Reads

symbol_input.value

↓

MarketDataService

↓

Display Result
```

Notice that the widget itself doesn't retrieve stock prices.

It simply provides information.

---

# Widgets and the MVC Pattern

Although you don't need to master software architecture yet,

it's helpful to know where widgets fit.

```text
User

↓

Widgets

↓

Controller Logic

↓

MarketDataService

↓

Panes

↓

User
```

Widgets belong to the application's input layer.

---

# Looking Ahead

Our dashboard now contains two important components.

```text
Widgets

↓

Python

↓

Panes
```

Soon,

we'll connect them together.

Typing

```text
D05
```

and clicking

```text
Search
```

will retrieve live market data.

---

# Teacher's Notes

> Beginners sometimes think widgets are "smart" objects that automatically perform actions. They are not. Widgets collect information and notify the application when something changes. The application itself decides what to do with that information. This separation keeps the user interface flexible and prevents presentation code from becoming tightly coupled with business logic.
>
> Another important concept introduced in this lesson is **state**. Widgets remember their current value, allowing the application to retrieve user input whenever it is needed. This idea appears throughout modern user interface frameworks, including React, Vue, Flutter, and Panel.

---

# Common Mistakes

## ❌ Mistake 1

Confusing panes and widgets.

Panes display information.

Widgets collect information.

---

## ❌ Mistake 2

Expecting a button to perform an action automatically.

Buttons require event handlers, which we'll learn next.

---

## ❌ Mistake 3

Reading a widget object instead of its value.

Use:

```python
symbol_input.value
```

instead of

```python
symbol_input
```

---

## ❌ Mistake 4

Forgetting to provide descriptive labels.

Well-labeled widgets make dashboards much easier to use.

---

## ❌ Mistake 5

Thinking placeholder text is the widget's value.

The placeholder is only a visual hint.

The actual value remains empty until the user enters something.

---

# Summary

In this lesson, you learned:

* Widgets allow users to provide input to Panel applications.
* Widgets complement panes by collecting information instead of displaying it.
* `TextInput` creates editable text boxes for user input.
* Widgets store their current value in the `.value` property.
* Widgets maintain state, allowing your application to retrieve user input at any time.
* Buttons signal user intent but do not perform actions by themselves.
* Labels and placeholders improve usability.
* Widgets form the input layer of our SGX Stock Monitor.

We now have the ability to collect information from users. The final missing piece is responding to their actions.

---

# Exercises

## Exercise 1 — Identify the Widget

Choose the most appropriate widget for each situation:

* Enter a stock symbol
* Select a market sector from a list
* Enable or disable dark mode
* Choose a date
* Refresh market prices
* Select the number of stocks to display

Explain why each widget is appropriate.

---

## Exercise 2 — Understanding Widget State

Suppose the following widget exists:

```python
symbol_input = pn.widgets.TextInput(
    value="D05"
)
```

Answer the following:

* What is the initial state of the widget?
* What happens if the user changes the value to `U11`?
* What does `symbol_input.value` contain afterward?

---

## Exercise 3 — Design the Dashboard Inputs

Sketch the input section of the SGX Stock Monitor.

Include:

* A text box for the stock symbol
* A Search button
* One additional widget of your choice (for example, a market selector or refresh interval)

Explain the purpose of each widget.

---

# Coming Up Next

In **Lesson 4.4 — Event Handling: Making Widgets Respond to User Actions**, you'll learn how to make your Panel application interactive. We'll explore callbacks, button click events, widget change events, and Panel's event-driven programming model. By the end of the lesson, clicking the **Search** button will trigger the `MarketDataService`, retrieve live SGX stock data, and update the dashboard automatically—the first fully interactive version of our application.
