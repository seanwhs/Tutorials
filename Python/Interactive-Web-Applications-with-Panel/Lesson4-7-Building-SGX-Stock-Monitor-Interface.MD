# Part IV — Building the Panel User Interface

# Lesson 4.7 — Building the SGX Stock Monitor Dashboard

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Combine everything learned in Part IV into a complete application.
> * Build a professional Panel dashboard from scratch.
> * Organize the application into logical sections.
> * Connect widgets, layouts, panes, and callbacks.
> * Understand the complete execution flow of a Panel application.
> * Apply software engineering principles while building a dashboard.
> * Prepare the application for integration with live SGX market data in Part V.

---

# Introduction

Congratulations!

This is one of the biggest milestones in the entire tutorial.

So far, we've learned many individual concepts.

We learned about

* Panes
* Widgets
* Event Handling
* Layouts
* Templates
* Styling

Individually,

each concept seems simple.

Today's lesson is where everything comes together.

Instead of learning another Panel component,

we'll assemble all the building blocks into our first real application.

Think of it like building a house.

Earlier lessons taught us about:

* bricks
* windows
* doors
* roofing
* plumbing

Today,

we finally build the house.

---

# Looking Back

Let's review what we have learned.

## Panes

Responsible for displaying information.

```text
Price

Charts

Tables

Markdown

Images
```

---

## Widgets

Responsible for collecting user input.

```text
Textbox

Button

Dropdown

Checkbox

Slider
```

---

## Event Handling

Responsible for responding to users.

```text
User Clicks

↓

Callback Executes
```

---

## Layouts

Responsible for organizing components.

```text
Column

↓

Row

↓

Tabs

↓

Grid
```

---

## Templates

Responsible for providing professional page structure.

```text
Header

Sidebar

Main Area
```

---

# Building a Real Dashboard

Let's begin by imagining the finished application.

```text
+------------------------------------------------------------------+

                    SGX Stock Monitor

===================================================================

Sidebar

Stock Symbol

+----------------+

| D05            |

+----------------+

[ Search ]

[ Refresh ]

===================================================================

Main Area

---------------------------------------------------

Current Stock Information

---------------------------------------------------

Current Price

---------------------------------------------------

Interactive Chart

---------------------------------------------------

Trading Volume

---------------------------------------------------

Company News

+------------------------------------------------------------------+
```

Everything you've learned contributes to this interface.

---

# Step 1 — Identify the Components

Before writing any code,

professional developers identify the application's components.

For our dashboard,

we need

| Component                | Purpose                       |
| ------------------------ | ----------------------------- |
| Title                    | Application heading           |
| Stock Symbol TextInput   | User enters SGX symbol        |
| Search Button            | Retrieve market data          |
| Refresh Button           | Refresh displayed information |
| Company Information Pane | Display company details       |
| Price Pane               | Display latest stock price    |
| Chart Pane               | Display price history         |
| News Pane                | Display recent company news   |

Planning first reduces mistakes later.

---

# Step 2 — Separate Responsibilities

Instead of writing everything inside one file,

we continue following good software engineering practices.

Our application responsibilities become

```text
Panel Interface

↓

Callbacks

↓

MarketDataService

↓

Financial API

↓

Processed Data

↓

Panel Panes
```

Notice how each layer has only one responsibility.

---

# Step 3 — Create the Widgets

Our interface begins with user input.

Conceptually,

we create

```python
TextInput

↓

Button

↓

Button
```

These widgets will allow users to

* enter stock symbols
* search
* refresh market information

At this point,

they still don't perform any actions.

---

# Step 4 — Create Display Areas

Next,

we prepare places where information will appear.

Conceptually,

our dashboard contains empty panes.

```text
Current Price

-------------------

Waiting...

-------------------

Chart

-------------------

Waiting...

-------------------

News

-------------------

Waiting...
```

Initially,

these panes display placeholder information.

Later,

callbacks will update them.

---

# Why Create Empty Panes?

Suppose the application starts.

No stock has been searched yet.

What should users see?

Certainly not an error.

Instead,

professional dashboards display messages such as

```text
Please search for a stock.
```

or

```text
Waiting for market data...
```

This improves the user experience.

---

# Step 5 — Arrange the Layout

Now we organize everything.

Our layout becomes

```text
Dashboard

↓

Column

↓

Title

↓

Row

↓

TextInput

Button

Refresh

↓

Price Pane

↓

Chart Pane

↓

News Pane
```

Notice how rows and columns work together.

---

# Visualizing the Layout Tree

```text
Dashboard

├── Title

├── Search Row

│     ├── Symbol Input

│     ├── Search Button

│     └── Refresh Button

├── Company Information

├── Price Display

├── Price Chart

└── News Display
```

This tree is much easier to understand than a long list of components.

---

# Step 6 — Connect the Search Button

The Search button now receives a callback.

Conceptually,

the callback performs three tasks.

```text
Read Symbol

↓

Retrieve Data

↓

Update Dashboard
```

Nothing more.

This keeps the callback simple.

---

# Step 7 — Reading User Input

When the callback executes,

it asks

```text
What stock symbol did the user enter?
```

The answer comes from

```python
symbol_input.value
```

Suppose the user typed

```text
D05
```

The callback now knows which stock to retrieve.

---

# Step 8 — Calling the Service Layer

Instead of downloading market data itself,

the callback delegates responsibility.

```text
Callback

↓

MarketDataService

↓

Financial API

↓

Dictionary
```

This separation keeps the user interface independent of the data source.

---

# Step 9 — Updating the Dashboard

Once the service returns information,

the callback updates each pane.

```text
Price Pane

↓

Current Price

------------------

Chart Pane

↓

Price Chart

------------------

News Pane

↓

Company News
```

Notice that no new panes are created.

Instead,

the existing panes are updated.

---

# Why Update Instead of Rebuilding?

Imagine rebuilding the entire dashboard every time the user searches.

That would be inefficient.

Instead,

Panel updates only the components that changed.

Modern UI frameworks—including Panel, React, Flutter, and SwiftUI—follow this principle.

---

# Understanding the Complete Execution Flow

Let's follow a search from beginning to end.

```text
Application Starts

↓

Dashboard Appears

↓

User Types D05

↓

Clicks Search

↓

Button Event

↓

Callback Executes

↓

Read Widget Value

↓

Call MarketDataService

↓

Retrieve Data

↓

Update Panes

↓

Dashboard Refreshes
```

This sequence represents the complete life cycle of a user interaction.

---

# Understanding Component Collaboration

Notice how every component contributes.

```text
Widgets

↓

Collect Input

↓

Callbacks

↓

Coordinate Work

↓

MarketDataService

↓

Retrieve Data

↓

Panes

↓

Display Results

↓

Layouts

↓

Organize Screen

↓

Template

↓

Provide Overall Structure
```

No component tries to perform another component's job.

This is excellent software architecture.

---

# Thinking Like a Professional Developer

Professional developers rarely begin by writing code.

Instead,

they ask questions such as

* What information should users enter?
* What information should be displayed?
* Which components need updating?
* Where should business logic reside?
* Which classes should communicate?

Good software begins with good design.

---

# Preparing for Live Data

At the moment,

our dashboard architecture is complete.

However,

our market data may still be simulated.

In Part V,

we'll replace placeholder data with real SGX market information retrieved from external financial APIs.

The user interface won't need to change.

Only the service layer changes.

This demonstrates one of the greatest benefits of separating responsibilities.

---

# The Complete Architecture

At this point,

our application looks like this.

```text
                         User

                           │

                           ▼

                Panel Widgets

                           │

                           ▼

                 Event Callbacks

                           │

                           ▼

               MarketDataService

                           │

                           ▼

                Financial Data API

                           │

                           ▼

               Normalized Data Model

                           │

                           ▼

                  Panel Panes

                           │

                           ▼

                 Panel Layouts

                           │

                           ▼

              FastListTemplate

                           │

                           ▼

                      Browser
```

Everything we learned throughout Part IV appears in this diagram.

---

# Software Engineering Principles We've Applied

Without introducing complex terminology,

we've already applied several important engineering principles.

## Separation of Concerns

Each component has one responsibility.

---

## Single Responsibility Principle

Widgets collect input.

Services retrieve data.

Panes display information.

---

## Composition

Large dashboards are built by combining smaller components.

---

## Loose Coupling

The user interface doesn't know how market data is retrieved.

It only knows that the service provides it.

---

## High Cohesion

Related responsibilities remain together.

Presentation code stays inside Panel.

Business logic stays inside service classes.

---

# Teacher's Notes

> Many beginners assume the hardest part of software engineering is writing code. In reality, architecture is often more important than syntax. This lesson demonstrates that well-designed applications emerge by composing small, focused components rather than creating large monolithic classes. Notice how each lesson in Part IV introduced one building block, and today's lesson simply assembled them. This mirrors how professional software systems are developed.
>
> Another important observation is that the dashboard remains largely unchanged when switching from simulated data to live market data. Because the user interface communicates only with the `MarketDataService`, replacing the underlying data source requires minimal changes. This flexibility is one of the primary goals of layered software architecture.

---

# Common Mistakes

## ❌ Mistake 1

Putting every component inside one callback.

Callbacks should coordinate, not contain all application logic.

---

## ❌ Mistake 2

Mixing API code with Panel layout code.

Presentation and business logic should remain separate.

---

## ❌ Mistake 3

Creating new panes after every search.

Reuse existing panes and update their contents.

---

## ❌ Mistake 4

Designing the interface while writing code.

Plan the dashboard structure before implementation.

---

## ❌ Mistake 5

Thinking the dashboard is the application.

The dashboard is only the presentation layer of a larger software system.

---

# Summary

In this lesson, you learned:

* How to assemble all Panel concepts into a complete dashboard.
* How widgets, callbacks, services, panes, layouts, and templates collaborate.
* Why professional applications separate responsibilities into distinct layers.
* How to organize a Panel application before writing code.
* Why updating existing components is preferable to rebuilding the interface.
* How our SGX Stock Monitor prepares for live market data integration.

With this lesson, **Part IV is complete**. You now understand the complete user interface architecture of a professional Panel application.

---

# Exercises

## Exercise 1 — Trace the Complete Application Flow

Draw a flowchart beginning with:

```
User launches the application
```

and ending with:

```
Stock information appears on the dashboard.
```

Include every major component introduced in Part IV.

---

## Exercise 2 — Component Responsibilities

Create a table with the following columns:

| Component | Responsibility | Should It Know About the API? |
| --------- | -------------- | ----------------------------- |

Complete the table for:

* TextInput
* Button
* Callback
* MarketDataService
* Price Pane
* Layout
* Template

---

## Exercise 3 — Architecture Reflection

Suppose your financial API changes from Provider A to Provider B.

Explain:

* Which classes should change?
* Which classes should remain unchanged?
* Why does the layered architecture make this transition easier?

---

# End of Part IV

Congratulations!

You have completed **Part IV — Building the Panel User Interface**.

At this stage, you have learned the complete foundation of Panel application development:

* ✅ Panes
* ✅ Widgets
* ✅ Event-driven programming
* ✅ Callbacks
* ✅ Layouts
* ✅ Responsive design
* ✅ Templates and themes
* ✅ Professional dashboard architecture

In **Part V — Working with Live SGX Market Data**, we will shift our focus from the user interface to the **data layer**. You'll learn how to connect your application to real financial data providers, perform HTTP requests, consume REST APIs, parse JSON responses, normalize market data into a consistent format, handle network failures gracefully, and display live SGX stock information in the dashboard you have just built. This is where your application evolves from a well-designed interface into a fully functional, real-time stock monitoring system.
