# Part IV — Building the Panel User Interface

# Lesson 4.4 — Event Handling: Making Widgets Respond to User Actions

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand event-driven programming.
> * Learn what an event is.
> * Understand callbacks.
> * Learn how Panel handles widget events.
> * Respond to button clicks.
> * Respond to widget value changes.
> * Understand the relationship between widgets, callbacks, and panes.
> * Connect the Search button to our `MarketDataService`.
> * Build the first interactive version of our SGX Stock Monitor.

---

# Introduction

So far, our dashboard contains widgets.

We have:

* a text box
* a Search button

They look nice.

They can even store values.

But there is one problem.

Nothing happens.

Typing

```text
D05
```

and pressing

```text
Search
```

does absolutely nothing.

Why?

Because widgets don't automatically perform actions.

They simply wait.

Today's lesson teaches the missing piece:

> **Event Handling**

---

# What Is an Event?

An **event** is simply

> **something that happens during the execution of a program.**

Examples include:

* Clicking a button
* Typing into a textbox
* Selecting a dropdown option
* Moving a slider
* Closing a window

Each of these actions generates an event.

---

# Real-Life Analogy

Imagine a restaurant.

The waiter waits beside your table.

Nothing happens until you raise your hand.

Raising your hand is an event.

The waiter then responds.

Likewise,

our application waits until the user performs an action.

---

# Event-Driven Programming

Traditional programs execute from top to bottom.

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

Interactive applications are different.

They spend most of their lives waiting.

```text
Start

↓

Wait...

↓

User Clicks Button

↓

Run Code

↓

Wait...

↓

User Types Text

↓

Run Code

↓

Wait...
```

This programming style is called

> **Event-Driven Programming**

---

# Why Dashboards Use Event-Driven Programming

Imagine checking stock prices every second,

even if the user never asks.

That would waste:

* CPU time
* Memory
* Network bandwidth

Instead,

the application waits until the user requests information.

This is much more efficient.

---

# Understanding Callbacks

When an event occurs,

how does Python know what to do?

The answer is

> **Callbacks**

A callback is simply

> **a function that runs when an event occurs.**

---

# Visualizing a Callback

```text
Button Click

↓

Callback Function

↓

Retrieve Stock Data

↓

Update Dashboard
```

Notice that the button doesn't retrieve data.

The callback does.

---

# Thinking in Terms of Responsibility

The responsibilities are clearly separated.

```text
Button

↓

Detect Click

↓

Callback

↓

Business Logic

↓

Update UI
```

Each component has one job.

---

# Our First Callback

Suppose we define

```python
def search_stock(event):

    print("Searching...")
```

Nothing happens yet.

We've only created a function.

We still need to connect it to the button.

---

# Connecting the Callback

Panel provides

```python
button.on_click(...)
```

Example

```python
search_button.on_click(search_stock)
```

Now,

every time the button is clicked,

Panel automatically calls

```python
search_stock(...)
```

---

# What Does `on_click()` Mean?

Let's examine it.

```python
search_button.on_click(search_stock)
```

---

`search_button`

↓

The widget generating the event.

---

`on_click`

↓

Registers a callback.

Think of it as saying:

> "When someone clicks this button..."

---

`search_stock`

↓

"...run this function."

---

# Why Don't We Write Parentheses?

Beginners often write

```python
search_button.on_click(search_stock())
```

This is incorrect.

Why?

Because

```python
search_stock()
```

calls the function immediately.

We don't want that.

We want Panel to call it later.

Therefore,

we write

```python
search_stock
```

without parentheses.

---

# Understanding Function References

Consider this.

```python
def greet():

    print("Hello")
```

These are different.

```python
greet
```

↓

The function itself.

---

```python
greet()
```

↓

Execute the function.

Callbacks require the function,

not the result of calling it.

---

# The Event Object

Notice our callback.

```python
def search_stock(event):

    ...
```

Where did

```python
event
```

come from?

Panel automatically supplies it.

The event object contains information such as:

* Which widget triggered the event
* When it occurred
* Event-specific details

Many simple callbacks won't need to inspect it,

but it is available when required.

---

# Reading the Widget Value

Inside our callback,

we can read

```python
symbol_input.value
```

Suppose the user typed

```text
D05
```

Then

```python
symbol = symbol_input.value
```

contains

```text
D05
```

Now our application knows which stock to retrieve.

---

# Calling the Service

Once we know the symbol,

the callback becomes responsible for calling

```python
market_service.get_stock(symbol)
```

The workflow now becomes

```text
User

↓

Button Click

↓

Callback

↓

MarketDataService

↓

Stock Data
```

Notice how the callback connects the user interface to the backend.

---

# Updating the Dashboard

After retrieving the data,

we display it.

```text
MarketDataService

↓

Dictionary

↓

Pane

↓

Browser
```

The callback coordinates everything.

---

# Putting It All Together

Our application's workflow is now

```text
User Types

↓

TextInput

↓

User Clicks Search

↓

Button Event

↓

Callback Function

↓

Read Widget Value

↓

Call MarketDataService

↓

Receive Dictionary

↓

Update Pane

↓

Browser Refreshes
```

This is the complete interaction cycle.

---

# Responding to Text Changes

Buttons are not the only widgets that generate events.

Suppose we want to react whenever the user changes the stock symbol.

Panel allows widgets to observe property changes.

Conceptually,

```text
Text Changes

↓

Value Changes

↓

Callback Runs
```

This enables applications such as:

* live search
* automatic validation
* dynamic suggestions

---

# Button Events vs Value Events

These represent two different kinds of interaction.

| Event        | Trigger                |
| ------------ | ---------------------- |
| Button click | User clicks the button |
| Value change | Widget value changes   |

Choose the event that matches your application's behaviour.

---

# Why We Use a Search Button

A beginner might ask,

> "Why not search every time the user types a letter?"

Imagine typing

```text
D05
```

The application would search:

```text
D

↓

D0

↓

D05
```

Three API requests instead of one.

For financial APIs,

this wastes bandwidth and may exceed rate limits.

A Search button allows the user to finish typing first.

---

# Separating Responsibilities

Notice how our application is organized.

```text
TextInput

↓

Stores Symbol

↓

Button

↓

Signals Search

↓

Callback

↓

Coordinates Work

↓

MarketDataService

↓

Retrieves Data

↓

Pane

↓

Displays Data
```

Every component has exactly one responsibility.

This is excellent software engineering.

---

# The Event Loop

Interactive applications continuously repeat this cycle.

```text
Wait

↓

User Event

↓

Run Callback

↓

Update UI

↓

Wait

↓

User Event

↓

Run Callback

↓

Update UI
```

This loop continues until the application closes.

---

# Thinking Like a Software Engineer

One of the most common mistakes beginners make is putting too much code inside callbacks.

A callback should coordinate work,

not perform every task itself.

Good callbacks usually:

* read widget values
* call services
* update the interface

Business logic should remain inside service classes like

```python
MarketDataService
```

This makes the application easier to maintain and test.

---

# Our Updated Architecture

We can now see the complete design.

```text
                    User

                      │

                      ▼

              Panel Widgets

                      │

                      ▼

             Callback Function

                      │

                      ▼

          MarketDataService

                      │

                      ▼

          Financial Data API

                      │

                      ▼

           Normalized Dictionary

                      │

                      ▼

               Panel Panes

                      │

                      ▼

                  Browser
```

Everything now works together.

---

# Teacher's Notes

> Event-driven programming is one of the biggest mindset shifts for beginners. Instead of asking "What happens next?", you begin asking "What should happen when this event occurs?" Modern GUI frameworks—including Panel, Qt, Tkinter, React, Flutter, SwiftUI, and JavaFX—all rely on this event-driven model.
>
> Another architectural principle worth emphasizing is that callbacks should remain thin. Resist the temptation to place networking code, parsing logic, and business rules directly inside event handlers. Instead, callbacks should delegate those responsibilities to dedicated service classes, allowing the user interface to remain clean and focused on presentation.

---

# Common Mistakes

## ❌ Mistake 1

Calling the callback immediately.

Incorrect:

```python
button.on_click(search_stock())
```

Correct:

```python
button.on_click(search_stock)
```

---

## ❌ Mistake 2

Putting business logic inside the callback.

Callbacks should coordinate work,

not perform all the work themselves.

---

## ❌ Mistake 3

Ignoring widget state.

Always read the latest value from the widget before processing user input.

---

## ❌ Mistake 4

Searching after every keystroke when a button is more appropriate.

For API-based applications,

this can generate unnecessary requests.

---

## ❌ Mistake 5

Assuming widgets automatically communicate with services.

Widgets generate events.

Callbacks connect those events to your application's logic.

---

# Summary

In this lesson, you learned:

* An **event** is any user action that occurs while the application is running.
* Interactive applications follow an event-driven programming model rather than a simple top-to-bottom execution flow.
* **Callbacks** are functions that execute in response to events.
* `button.on_click()` connects a button to a callback function.
* Callbacks receive an event object supplied by Panel.
* Widget values can be read inside callbacks using properties such as `.value`.
* Callbacks coordinate communication between the user interface and the `MarketDataService`.
* Thin callbacks and well-defined service layers produce cleaner, more maintainable applications.

Our SGX Stock Monitor is now conceptually interactive. The user can trigger actions, and our application knows how to respond.

---

# Exercises

## Exercise 1 — Trace the Event Flow

Draw a flowchart beginning with the user clicking the **Search** button and ending with the updated stock price appearing in the browser.

Label every step.

---

## Exercise 2 — Identify Responsibilities

For each task below, identify which component should perform it:

* Store the stock symbol
* Detect a button click
* Retrieve market data
* Parse JSON
* Normalize API data
* Display the stock price

Explain why each responsibility belongs to that component.

---

## Exercise 3 — Understanding Callbacks

Explain why the following statements behave differently:

```python
search_button.on_click(search_stock)
```

and

```python
search_button.on_click(search_stock())
```

Describe what Python evaluates in each case and why the first version is the correct approach.

---

# Coming Up Next

In **Lesson 4.5 — Layouts: Organizing Your Dashboard with Rows, Columns, and Containers**, we'll learn how to arrange widgets and panes into a professional-looking interface. You'll explore `Row`, `Column`, `Tabs`, `GridSpec`, and other layout containers, understand responsive design principles, and transform our collection of individual components into a clean, organized SGX Stock Monitor dashboard. This lesson marks the transition from isolated UI elements to a cohesive application interface.
