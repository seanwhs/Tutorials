# Part IV — Building the Panel User Interface

# Lesson 4.5 — Layouts: Organizing Your Dashboard with Rows, Columns, and Containers

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand why layouts are essential in every Panel application.
> * Learn what a layout container is.
> * Understand how Panel organizes components on the screen.
> * Learn about `Row`, `Column`, `Tabs`, `Accordion`, `Spacer`, and `GridSpec`.
> * Understand nesting layouts.
> * Learn responsive dashboard design.
> * Organize our SGX Stock Monitor into a professional dashboard.
> * Understand layout best practices.

---

# Introduction

So far, we've learned about two important Panel concepts.

**Panes**

↓

Display information.

**Widgets**

↓

Collect information.

But imagine displaying every component without organizing them.

Our dashboard might look like this.

```text
Search Button

Price

Chart

Text Box

Volume

Company Name

Refresh Button

News

Table
```

Everything exists,

but nothing is organized.

A good dashboard isn't just functional.

It should also be easy to understand.

Today's lesson introduces the third major building block of Panel:

> **Layouts**

---

# What Is a Layout?

A **layout** determines

> **where components appear on the screen.**

Think of a layout as the floor plan of a house.

A house contains

* bedrooms
* kitchen
* living room
* bathroom

The layout determines where each room goes.

Similarly,

a Panel layout determines where each widget and pane appears.

---

# Understanding the Three Building Blocks

At this point,

we know three fundamental concepts.

```text
Widgets

↓

Collect Input

-----------------

Business Logic

↓

Processes Data

-----------------

Panes

↓

Display Output
```

Layouts organize everything.

```text
Layouts

↓

Arrange Widgets

Arrange Panes

Arrange Other Layouts
```

---

# Everything Is a Component

One elegant feature of Panel is that almost everything is a component.

For example,

these are all components:

* Markdown Pane
* Button
* TextInput
* DataFrame
* Plotly Figure
* Row
* Column

This consistency makes Panel easy to learn.

---

# The Simplest Layout

The simplest layout is

```python
pn.Column()
```

It stacks components vertically.

Imagine

```text
A

↓

B

↓

C
```

This is exactly what a column does.

---

# Visualizing a Column

```text
+----------------------+

Title

------------------------

Search Box

------------------------

Search Button

------------------------

Results

------------------------

Chart

+----------------------+
```

Each component appears beneath the previous one.

---

# Creating a Column

```python
pn.Column(

    title,

    symbol_input,

    search_button,

    results

)
```

Panel displays each component vertically.

Notice how simple the syntax is.

---

# Understanding the Constructor

Let's examine

```python
pn.Column(...)
```

carefully.

Everything passed inside the parentheses becomes a child of the layout.

```python
pn.Column(

    component1,

    component2,

    component3

)
```

Panel automatically arranges them vertically.

---

# The Row Layout

Sometimes,

we don't want components stacked vertically.

Instead,

we want them side-by-side.

Panel provides

```python
pn.Row()
```

---

# Visualizing a Row

```text
+----------------------------------+

Search Box     Search Button

+----------------------------------+
```

Instead of

```text
Search Box

Search Button
```

everything appears horizontally.

---

# Creating a Row

```python
pn.Row(

    symbol_input,

    search_button

)
```

This is much more compact.

---

# Why Rows Matter

Imagine entering a stock symbol.

Having the Search button immediately beside the textbox feels natural.

```text
+--------------------------------------+

[D05____________] [ Search ]

+--------------------------------------+
```

Users don't need to move their eyes far.

This improves usability.

---

# Combining Rows and Columns

Layouts become powerful when we combine them.

For example,

```text
Dashboard

↓

Column

↓

    Row

        Text Box

        Search Button

↓

Results

↓

Chart
```

Rows can exist inside columns.

Columns can exist inside rows.

---

# Visualizing Nested Layouts

```text
+--------------------------------------+

SGX Dashboard

----------------------------------------

[D05_________] [ Search ]

----------------------------------------

Company Information

----------------------------------------

Price Chart

----------------------------------------

Recent Transactions

+--------------------------------------+
```

Notice that the search controls are inside a row,

while everything else is inside a column.

---

# Building the Search Area

Our search section might look like this.

```python
search_area = pn.Row(

    symbol_input,

    search_button

)
```

Later,

we'll place

```python
search_area
```

inside a larger dashboard.

---

# Building the Dashboard

Conceptually,

our dashboard becomes

```python
dashboard = pn.Column(

    title,

    search_area,

    stock_info,

    chart,

    table

)
```

This simple design already looks much more professional.

---

# Thinking Hierarchically

Large Panel applications are built like trees.

```text
Dashboard

├── Header

├── Search Area

│     ├── Text Box

│     └── Button

├── Company Information

├── Chart

└── Table
```

Each layout contains smaller layouts.

---

# The Spacer Component

Sometimes,

components appear too close together.

Panel provides

```python
pn.Spacer()
```

A spacer inserts empty space.

Think of it as an invisible component.

---

# Why Use Spacers?

Without spacing,

a dashboard may feel cramped.

```text
Search Box
Button
Price
Chart
```

With spacing,

the interface becomes easier to read.

Good design is not only about adding elements,

but also about leaving empty space.

---

# Understanding White Space

Professional dashboards deliberately leave empty areas.

This is called

> **White Space**

White space helps users focus on important information.

Crowded dashboards often feel confusing,

even when they contain the same information.

---

# Tabs

Large dashboards sometimes contain many sections.

Instead of displaying everything simultaneously,

Panel provides

```python
pn.Tabs()
```

---

# Visualizing Tabs

```text
+--------------------------------+

Overview | Chart | News | History

----------------------------------

Selected Page Appears Here

+--------------------------------+
```

Only one section is visible at a time.

---

# When Should You Use Tabs?

Tabs work well for:

* Company Overview
* Price Charts
* Historical Data
* News
* Financial Statements

Instead of creating a very long page,

users switch between sections.

---

# Accordion Layouts

Another useful container is

```python
pn.Accordion()
```

---

# Visualizing an Accordion

```text
▼ Company Information

--------------------------------

▼ Financial Ratios

--------------------------------

► Historical Prices
```

Users expand only the sections they want.

This saves screen space.

---

# Grid Layouts

Rows and columns are sufficient for many applications.

However,

complex dashboards often require grids.

Panel provides

```python
pn.GridSpec()
```

---

# Visualizing a Grid

```text
+-------------------------------+

Chart        Price

Chart        Volume

Table        News

+-------------------------------+
```

Each component occupies a cell.

This resembles spreadsheet layouts.

---

# When Should You Use GridSpec?

GridSpec is ideal when:

* multiple charts appear simultaneously
* dashboards contain many panels
* precise positioning is required

We'll use it later when our dashboard becomes more sophisticated.

---

# Responsive Design

Users may open our dashboard on:

* laptops
* desktop computers
* tablets
* large monitors

A good layout adapts to different screen sizes.

This is called

> **Responsive Design**

---

# Why Responsive Design Matters

Imagine a dashboard designed only for large monitors.

On a laptop,

everything may overlap.

Responsive layouts automatically adjust,

making applications easier to use.

---

# Designing Our SGX Dashboard

Our finished dashboard will resemble this.

```text
+------------------------------------------------+

        SGX Stock Monitor

--------------------------------------------------

[D05_____________] [ Search ] [ Refresh ]

--------------------------------------------------

Company Information

--------------------------------------------------

Current Price

--------------------------------------------------

Interactive Chart

--------------------------------------------------

Recent Trading Activity

--------------------------------------------------

Latest Company News

+------------------------------------------------+
```

Notice the clear visual structure.

---

# Layouts Don't Store Data

An important observation.

Rows,

Columns,

Tabs,

and GridSpec

don't store business data.

Their only responsibility is arranging components.

This follows the same design philosophy we've used throughout this tutorial.

---

# The Complete Panel Hierarchy

We now understand almost the entire Panel architecture.

```text
Application

↓

Layouts

↓

Widgets

Panes

↓

Browser
```

Layouts organize.

Widgets collect input.

Panes display output.

---

# Thinking Like a UI Designer

Professional dashboards rarely appear by accident.

Developers think carefully about:

* alignment
* grouping
* spacing
* hierarchy
* readability

A well-designed layout helps users find information quickly.

---

# Teacher's Notes

> Beginners often underestimate the importance of layouts because they focus primarily on functionality. However, usability is a critical part of software engineering. A poorly organized dashboard can make even a technically correct application difficult to use. Investing time in thoughtful layouts significantly improves the user experience.
>
> Another concept worth emphasizing is **composition**. Notice how a `Column` can contain a `Row`, and that `Row` can contain widgets. This recursive composition is one of Panel's greatest strengths. Rather than learning dozens of specialized dashboard classes, you build complex interfaces by combining a few simple building blocks.

---

# Common Mistakes

## ❌ Mistake 1

Putting every component into a single column.

Use rows and nested layouts to improve organization.

---

## ❌ Mistake 2

Creating overcrowded dashboards.

Use spacing and grouping to improve readability.

---

## ❌ Mistake 3

Trying to position every component manually.

Let layout containers perform the positioning.

---

## ❌ Mistake 4

Using `GridSpec` for simple dashboards.

Rows and columns are often easier to understand and maintain.

---

## ❌ Mistake 5

Confusing layouts with panes or widgets.

Layouts organize components—they do not display data or collect user input.

---

# Summary

In this lesson, you learned:

* Layouts determine where components appear on the screen.
* `Column` arranges components vertically.
* `Row` arranges components horizontally.
* Layouts can be nested to create complex interfaces.
* `Spacer` helps improve readability by introducing white space.
* `Tabs` and `Accordion` organize large amounts of information into manageable sections.
* `GridSpec` supports sophisticated dashboard layouts with precise positioning.
* Responsive design helps dashboards adapt to different screen sizes.
* Layouts are responsible only for organization, keeping presentation and business logic separate.

With panes, widgets, events, and layouts now understood, we have all the fundamental building blocks required to construct a professional Panel application.

---

# Exercises

## Exercise 1 — Choose the Best Layout

For each situation, select the most appropriate layout:

* A search box beside a Search button
* A dashboard title above all other components
* Three charts displayed side-by-side
* Company information hidden until requested
* Multiple dashboard sections that users switch between

Explain your reasoning.

---

## Exercise 2 — Draw the Layout Tree

Design a layout tree for the SGX Stock Monitor using the following components:

* Dashboard Title
* Search Area
* Company Information
* Price Chart
* Recent Transactions
* Company News

Use a tree diagram to show how rows and columns are nested.

---

## Exercise 3 — Critique a Dashboard

Suppose a beginner places every widget, chart, and table into a single `Column`.

Discuss:

* What usability problems might arise?
* How could rows, spacing, tabs, or accordions improve the design?
* Which sections should be grouped together?

---

# Coming Up Next

In **Lesson 4.6 — Styling and Theming: Making Your Dashboard Look Professional**, we'll learn how to improve the appearance of our SGX Stock Monitor. You'll explore sizing modes, alignment, margins, colors, themes, templates, CSS integration, and responsive design techniques. By the end of the lesson, our application will evolve from a functional prototype into a polished dashboard suitable for real-world use.
