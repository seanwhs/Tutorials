# Part V — Working with Live SGX Market Data

# Lesson 5.9 — Connecting Panel to Live SGX Market Data: Building Our First Real-Time SGX Dashboard

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Connect Panel widgets to backend services.
> * Understand event-driven programming.
> * Learn how Panel callbacks work.
> * Integrate `MarketDataService` with Panel.
> * Update dashboard components dynamically.
> * Display stock information in real time.
> * Handle loading states.
> * Handle API failures gracefully.
> * Understand application state management.
> * Build your first complete interactive SGX stock monitoring application.

---

# Introduction

For many lessons, our Panel dashboard has looked something like this:

```text
Textbox

↓

Button

↓

Placeholder Output
```

Today everything changes.

For the first time, our application will become:

```text
User

↓

Panel Dashboard

↓

MarketDataService

↓

Market Provider

↓

Financial API

↓

Live SGX Data

↓

Dashboard Update
```

This is the moment where our educational dashboard becomes a real application.

---

# Understanding Interactive Applications

Until now, much of our code has been:

```python
print("Hello")
print("World")
print("Done")
```

This style of programming is called:

> Sequential Programming

The computer executes instructions from top to bottom.

---

# Interactive Applications Work Differently

Panel applications operate using:

> Event-Driven Programming

Instead of:

```text
Line 1

↓

Line 2

↓

Line 3
```

we have:

```text
User Action

↓

Event

↓

Callback

↓

Application Logic

↓

UI Update
```

---

# What Is an Event?

An event is simply:

> Something that happens.

Examples:

* clicking a button
* typing text
* selecting a menu item
* moving a slider
* changing a date
* receiving new stock data

---

# Real-Life Analogy

Consider a doorbell.

```text
Visitor

↓

Press Button

↓

Bell Rings
```

The bell does not ring continuously.

It waits for an event.

Panel works exactly the same way.

---

# Our First Event Flow

Suppose our user enters:

```text
D05
```

and presses:

```text
Search
```

The workflow becomes:

```text
User

↓

Button Click

↓

Callback Function

↓

MarketDataService

↓

Provider

↓

Financial API

↓

Stock Data

↓

Dashboard Update
```

---

# Designing Our Dashboard

Let's begin with a simple dashboard.

```python
import panel as pn

pn.extension()
```

---

# Creating Widgets

We need:

* stock input
* search button
* status display
* stock display

```python
symbol_input = pn.widgets.TextInput(
    name="SGX Symbol",
    value="D05"
)

search_button = pn.widgets.Button(
    name="Search",
    button_type="primary"
)

status = pn.pane.Markdown()

stock_output = pn.pane.JSON()
```

---

# Why Separate Widgets?

Each widget should have one responsibility.

| Widget    | Responsibility  |
| --------- | --------------- |
| TextInput | User input      |
| Button    | Trigger search  |
| Status    | User feedback   |
| Output    | Display results |

This follows:

> Single Responsibility Principle

---

# Visualizing the Dashboard

```text
┌─────────────────────┐
│ Symbol: D05         │
└─────────────────────┘

┌─────────────────────┐
│ Search              │
└─────────────────────┘

Status

Stock Information
```

---

# Creating Our Service

Recall our architecture.

```python
provider = SGXProvider(
    api_key=API_KEY,
    base_url=BASE_URL
)

market_service = MarketDataService(
    provider
)
```

---

# Understanding Application State

Notice that:

```python
market_service
```

exists outside callbacks.

Why?

Because we want:

```text
One Service

↓

Many User Actions
```

rather than:

```text
New Service

↓

Every Button Click
```

---

# What Is Application State?

State refers to:

> Information that exists over time.

Examples:

* cached stock prices
* authentication
* user selections
* loaded charts

---

# Visualizing State

```text
Application

├── Market Service
├── Cache
├── User Symbol
└── Current Results
```

---

# Creating Our First Callback

Let's write a function.

```python
def search_stock(event):

    symbol = symbol_input.value

    print(symbol)
```

---

# Understanding Callback Parameters

Notice:

```python
event
```

Panel passes information about:

```text
What Happened

↓

Who Triggered It

↓

When It Happened
```

---

# Why Include Event?

Even if we don't use it now:

```python
def search_stock(event):
```

Panel expects callbacks to accept event information.

---

# Connecting the Callback

We register the callback.

```python
search_button.on_click(
    search_stock
)
```

---

# Visualizing Registration

```text
Button

↓

on_click()

↓

Callback Registered

↓

Wait For User
```

---

# What Happens Internally?

Panel builds something like:

```text
If Button Clicked:

    Execute search_stock()
```

This process is called:

> Event Registration

---

# Retrieving User Input

Inside the callback:

```python
symbol = symbol_input.value
```

Suppose the user enters:

```text
U11
```

Then:

```python
symbol
```

contains:

```python
"U11"
```

---

# Calling the Service Layer

Now we perform:

```python
stock = market_service.get_stock(
    symbol
)
```

Notice:

```text
Panel

↓

MarketDataService

↓

Provider

↓

API
```

Panel never calls the API directly.

---

# Displaying Results

Suppose we receive:

```python
{
    "symbol": "D05",
    "price": 41.35
}
```

We display:

```python
stock_output.object = stock
```

---

# Why Does This Work?

Panel widgets are reactive.

Changing:

```python
.object
```

automatically updates the screen.

---

# Visualizing Reactivity

```text
Python Object Changes

↓

Panel Detects Change

↓

Browser Updates
```

This is called:

> Reactive Programming

---

# Complete Callback

```python
def search_stock(event):

    symbol = symbol_input.value

    stock = market_service.get_stock(
        symbol
    )

    stock_output.object = stock
```

Simple.

But not yet production-ready.

---

# Adding Status Messages

Users need feedback.

Before:

```python
stock = market_service.get_stock(
    symbol
)
```

we display:

```python
status.object = "Loading..."
```

---

# Why Loading Indicators Matter

Without loading feedback:

```text
User Clicks

↓

Nothing Happens

↓

User Clicks Again

↓

Still Nothing

↓

User Frustrated
```

---

# Better Experience

```text
User Clicks

↓

Loading...

↓

Receiving Data...

↓

Success
```

---

# Example

```python
status.object = "Loading..."

stock = market_service.get_stock(
    symbol
)

status.object = "Completed"
```

---

# Handling Errors

Suppose:

```text
Internet Failure
```

occurs.

Without protection:

```text
Dashboard Crash
```

---

# Using Try/Except

Instead:

```python
try:

    stock = market_service.get_stock(
        symbol
    )

except Exception:

    status.object = "Error"
```

---

# Why Catch Exceptions?

Failures include:

* no internet
* timeout
* provider failure
* malformed JSON
* invalid symbol

All are normal.

---

# Displaying User-Friendly Errors

Bad:

```text
Traceback:
HTTPConnectionPool...
```

Good:

```text
Unable to retrieve stock data.
Please try again later.
```

Users care about solutions, not stack traces.

---

# Example Error Handler

```python
except Exception as e:

    status.object = (
        "Unable to load data."
    )
```

---

# Handling Missing Results

Suppose the symbol:

```text
ABCXYZ
```

does not exist.

Instead of crashing:

```python
if stock is None:

    status.object = (
        "Stock not found."
    )

    return
```

---

# Building the Complete Workflow

Our callback now performs:

```text
Button Click

↓

Read Input

↓

Show Loading

↓

Call Service

↓

Validate

↓

Display Result

↓

Update Status
```

---

# Visualizing the Complete System

```text
User

↓

Panel Widgets

↓

Callback

↓

MarketDataService

↓

Provider

↓

API

↓

Provider

↓

MarketDataService

↓

Panel Update
```

---

# Creating the Dashboard Layout

Now we assemble everything.

```python
dashboard = pn.Column(

    "# SGX Stock Monitor",

    symbol_input,

    search_button,

    status,

    stock_output
)
```

---

# Understanding Layout Containers

Recall that:

```python
pn.Column()
```

means:

```text
Top

↓

Bottom

↓

Bottom

↓

Bottom
```

---

# Visual Representation

```text
┌───────────────────┐
│ SGX Stock Monitor │
├───────────────────┤
│ Symbol Input      │
├───────────────────┤
│ Search Button     │
├───────────────────┤
│ Status            │
├───────────────────┤
│ Stock Results     │
└───────────────────┘
```

---

# Making the Dashboard Viewable

Finally:

```python
dashboard.servable()
```

This tells Panel:

> Make this component available to the browser.

---

# The Complete Application Flow

```text
Browser

↓

Panel Server

↓

Widgets

↓

Callback

↓

MarketDataService

↓

Provider

↓

Financial API

↓

MarketDataService

↓

Widgets

↓

Browser Update
```

---

# What We Have Built

We now have:

✅ User input

✅ Event handling

✅ Service layer integration

✅ Provider abstraction

✅ Error handling

✅ Loading states

✅ Reactive updates

✅ Dashboard rendering

This is a real application architecture.

---

# Thinking Like a Software Engineer

Beginners often think:

```text
Button

↓

API

↓

Result
```

Professional engineers think:

```text
User Experience

↓

Events

↓

State

↓

Services

↓

Providers

↓

Reliability

↓

Presentation
```

Applications are not collections of screens.

Applications are systems.

---

# Teacher's Notes

> One of the most important concepts introduced in this lesson is event-driven programming. Unlike traditional scripts, interactive applications spend most of their time waiting for events. Understanding this shift in execution model is essential for building user interfaces.
>
> Another important lesson is that user experience includes failure handling. Loading indicators, error messages, and graceful degradation are not optional features added later. They are fundamental components of professional applications.

---

# Common Mistakes

## ❌ Mistake 1

Calling APIs directly from widgets.

---

## ❌ Mistake 2

Not showing loading states.

---

## ❌ Mistake 3

Displaying raw exceptions to users.

---

## ❌ Mistake 4

Creating services inside callbacks.

---

## ❌ Mistake 5

Ignoring application state.

---

# Summary

In this lesson, you learned:

* Panel applications use event-driven programming.
* User interactions generate events.
* Callbacks respond to events.
* Services should exist outside callbacks.
* Panel widgets update reactively.
* Loading indicators improve user experience.
* Error handling prevents application crashes.
* Application state persists across interactions.
* Our SGX Stock Monitor is now a real interactive application.

We have successfully connected Panel to live market data. The next challenge is displaying that data visually using tables, indicators, charts, and financial dashboards.

---

# Exercises

## Exercise 1 — Draw the Event Flow

Draw:

```text
Button

↓

Callback

↓

MarketDataService

↓

Provider

↓

API

↓

Dashboard
```

Explain the responsibility of each component.

---

## Exercise 2 — Error Scenarios

List five possible failures that may occur after the user presses the Search button.

Explain how the dashboard should handle each one.

---

## Exercise 3 — Application State

Identify which of the following are application state:

* API key
* stock cache
* search text
* loading status
* chart data

Explain why.

---

# Coming Up Next

In **Lesson 5.10 — Building Financial Dashboards with Panel: Indicators, Tables, Charts, and Real-Time Visualization**, we'll transform our simple stock viewer into a professional-looking SGX monitoring dashboard using Panel's panes, indicators, tabulators, charts, layouts, reactive updates, and financial visualization techniques.
