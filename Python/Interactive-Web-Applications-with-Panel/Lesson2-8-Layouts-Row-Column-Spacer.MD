# Part II — Widgets: Building Interactive User Interfaces

# Lesson 2.8 — Building Layouts with `Row`, `Column`, `Spacer`, and `Divider`

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand why layouts are essential in GUI applications.
> * Learn how Panel arranges components on the screen.
> * Master `Column()`, `Row()`, `Spacer()`, and `Divider()`.
> * Build clean, professional dashboard layouts.
> * Understand nested layouts.
> * Learn layout design principles.
> * Build the first professional-looking SGX Stock Monitor dashboard.

---

# Introduction

Our application currently works.

Users can:

* Enter a stock symbol
* Click Search
* See the results

The interface looks something like this.

```text
-----------------------------------

Stock Symbol

____________________

[ Search ]

Searching SGX for DBS...

-----------------------------------
```

Technically...

it's correct.

But visually,

it's not very impressive.

Everything is simply stacked on top of each other.

Real dashboards look much better.

Today's lesson is about arranging components into beautiful, organized layouts.

---

# Why Layout Matters

Imagine walking into a supermarket.

Everything is randomly placed.

```text
Milk

↓

Shoes

↓

Bread

↓

Television

↓

Apples

↓

Medicine
```

Finding anything would be frustrating.

Instead,

supermarkets organize products into sections.

Applications should do exactly the same thing.

---

# Every GUI Uses Layouts

Almost every application you've ever used relies on layouts.

Microsoft Excel

```text
Toolbar

↓

Spreadsheet

↓

Status Bar
```

---

Google Maps

```text
Search Box

↓

Map

↓

Directions Panel
```

---

Banking App

```text
Account Summary

↓

Transactions

↓

Transfer Button
```

Without layouts,

applications would quickly become unusable.

---

# What Is a Layout?

A layout is simply an object that arranges other objects.

Think of it as a container.

Instead of storing files,

it stores widgets and panes.

```text
Layout

↓

Contains

↓

Widgets

↓

Panes
```

---

# Panel Layout Objects

Panel provides several layout classes.

The most commonly used are:

```python
pn.Column()

pn.Row()

pn.Spacer()

pn.layout.Divider()
```

These four alone are enough to build many professional dashboards.

---

# `Column()` — Vertical Layout

A `Column` stacks components from top to bottom.

Think of it like a vertical pile.

```text
Item 1

↓

Item 2

↓

Item 3

↓

Item 4
```

---

Creating one is easy.

```python
layout = pn.Column(
    widget1,
    widget2,
    widget3
)
```

Everything appears vertically.

---

# Our Current Dashboard

We've already been using `Column`.

```python
dashboard = pn.Column(
    title,
    search,
    button,
    results
)
```

This produces

```text
Title

↓

Search

↓

Button

↓

Results
```

Every item appears underneath the previous one.

---

# How Does `Column()` Work?

Think of a filing cabinet.

Every new file goes into the next drawer.

```text
Drawer 1

↓

Drawer 2

↓

Drawer 3
```

Panel simply places each component underneath the previous one.

---

# `Row()` — Horizontal Layout

Sometimes,

we want components side-by-side.

That's where

```python
pn.Row()
```

comes in.

---

Example:

```python
layout = pn.Row(
    widget1,
    widget2,
    widget3
)
```

Produces

```text
Widget 1     Widget 2     Widget 3
```

Everything appears horizontally.

---

# Improving Our Search Area

Instead of

```text
Stock Symbol

________________

[ Search ]
```

we can place them beside each other.

```python
controls = pn.Row(
    search,
    button
)
```

Result

```text
____________________    [ Search ]
```

This looks far more like a real application.

---

# Combining Rows and Columns

Here's where Panel becomes powerful.

Layouts can contain other layouts.

Example:

```python
dashboard = pn.Column(

    title,

    pn.Row(
        search,
        button
    ),

    results

)
```

Notice something.

The `Column` contains a `Row`.

The `Row` contains widgets.

---

Visually,

the layout becomes

```text
Title

↓

Search      Button

↓

Results
```

This is called **layout nesting**.

---

# Nested Layouts

Imagine building with LEGO.

A small structure becomes part of a larger structure.

```text
Dashboard

├── Header

├── Search Area

│     ├── Search Box

│     └── Button

└── Results
```

This hierarchical design makes large applications manageable.

---

# `Spacer()` — Creating Empty Space

Sometimes,

components are too close together.

Panel provides

```python
pn.Spacer()
```

to create empty space.

Example:

```python
pn.Spacer(width=40)
```

This inserts

40 pixels

of horizontal space.

---

Suppose we write

```python
controls = pn.Row(

    search,

    pn.Spacer(width=20),

    button

)
```

Visually,

```text
Search Box        Button
```

instead of

```text
Search BoxButton
```

The interface becomes much easier to read.

---

Vertical spacing also works.

```python
pn.Spacer(height=30)
```

---

Example

```python
pn.Column(

    title,

    pn.Spacer(height=20),

    search

)
```

Produces

```text
Title


Search
```

Spacing improves readability.

---

# `Divider()` — Separating Sections

Large dashboards often contain sections.

Panel provides

```python
pn.layout.Divider()
```

Example

```python
dashboard = pn.Column(

    title,

    pn.layout.Divider(),

    controls,

    pn.layout.Divider(),

    results

)
```

Produces

```text
Title

------------------------

Search Area

------------------------

Results
```

Dividers help users understand the structure of an interface.

---

# Why Not Use Blank Lines?

Some beginners write

```python
pn.pane.Markdown("")
```

to create spacing.

Don't do this.

Instead,

use

```python
pn.Spacer()
```

It communicates your intention clearly.

---

# Building Our SGX Dashboard

Let's redesign our application.

```python
import panel as pn

pn.extension()

title = pn.pane.Markdown("# SGX Stock Monitor")

search = pn.widgets.TextInput(
    placeholder="Example: DBS"
)

button = pn.widgets.Button(
    name="Search",
    button_type="primary"
)

results = pn.pane.Markdown(
    "No search performed."
)

controls = pn.Row(
    search,
    pn.Spacer(width=10),
    button
)

dashboard = pn.Column(

    title,

    pn.layout.Divider(),

    controls,

    pn.Spacer(height=20),

    results

)

dashboard.servable()
```

---

The application now looks something like this.

```text
------------------------------------------------

SGX Stock Monitor

------------------------------------------------

__________________________   [ Search ]



No search performed.

------------------------------------------------
```

Already,

it feels much more professional.

---

# Thinking Like a Dashboard Designer

Rather than asking

> "Where should this widget go?"

Professional developers ask

> "Which components belong together?"

For example,

Search Box

*

Search Button

belong together.

Therefore,

they should probably be inside the same

```python
pn.Row()
```

---

Meanwhile,

Search Controls

and

Results

are different sections.

Therefore,

they belong in different

`Column` sections,

separated by spacing or dividers.

---

# Building Complex Layouts

As applications grow,

layouts become hierarchical.

Our future SGX dashboard might look like this.

```text
Dashboard

├── Header

├── Controls

│      ├── Search

│      ├── Exchange

│      └── Search Button

├── Stock Information

├── Price Chart

├── Financial Statistics

└── News Feed
```

Every section is simply another layout.

---

# Layout Trees

You can visualize Panel layouts as trees.

```text
Column

├── Markdown

├── Row

│     ├── TextInput

│     ├── Spacer

│     └── Button

├── Divider

└── Markdown
```

Large dashboards often contain dozens of nested layouts.

Fortunately,

each one follows the same simple rules.

---

# Good Layout Design Principles

Professional dashboards usually follow several principles.

### Group Related Controls

Good

```text
Search     Button
```

Poor

```text
Search

Chart

Button
```

---

### Separate Different Sections

Users should immediately recognize different parts of the interface.

Dividers and spacing help.

---

### Avoid Clutter

Too many controls packed together become overwhelming.

Whitespace is valuable.

---

### Build Hierarchically

Instead of one giant layout,

create many small layouts.

Small layouts are easier to understand,

reuse,

and maintain.

---

# Teacher's Notes

> Layout design is often underestimated by beginners. They focus entirely on functionality and forget that users spend most of their time looking at the interface.
>
> A well-designed layout improves readability, reduces cognitive load, and makes applications feel more professional. As your projects become larger, organizing widgets into small reusable layouts will become just as important as writing clean Python code.
>
> Throughout the rest of this tutorial, we'll continue refactoring our dashboard into increasingly modular layouts.

---

# Common Mistakes

### ❌ Mistake 1

Putting everything inside one giant `Column`.

Instead,

create logical sections.

---

### ❌ Mistake 2

Using many nested `Spacer()` objects to force components into position.

Layouts should organize content naturally.

Don't fight the layout system.

---

### ❌ Mistake 3

Using empty Markdown panes for spacing.

Prefer

```python
pn.Spacer()
```

because it clearly expresses your intent.

---

### ❌ Mistake 4

Creating deeply nested layouts without planning.

Sketch your interface on paper first.

Identify logical groups before writing code.

---

# Summary

In this lesson, you learned:

* Layouts organize widgets and panes into structured interfaces.
* `pn.Column()` arranges components vertically.
* `pn.Row()` arranges components horizontally.
* `pn.Spacer()` creates intentional empty space.
* `pn.layout.Divider()` visually separates sections.
* Layouts can contain other layouts, forming a hierarchical tree.
* Good layout design improves usability, readability, and maintainability.

Our SGX Stock Monitor is beginning to resemble a real dashboard. As we continue adding charts, tables, and watchlists, these layout techniques will become increasingly important.

---

# Exercises

## Exercise 1 — Horizontal Search Controls

Create a `Row` containing:

* A `TextInput`
* A `Spacer`
* A `Search` button

Observe how the appearance differs from a vertical layout.

---

## Exercise 2 — Sectioned Dashboard

Build a dashboard with the following sections:

* Title
* Divider
* Search Controls
* Spacer
* Results
* Divider
* Status Message

Use a combination of `Column`, `Row`, `Spacer`, and `Divider`.

---

## Exercise 3 — Draw the Layout Tree

Without writing any code, draw the layout hierarchy for your dashboard.

For example:

```text
Column
├── Title
├── Divider
├── Row
│   ├── TextInput
│   ├── Spacer
│   └── Button
└── Markdown
```

Understanding the layout tree before coding is a habit shared by many experienced Panel developers.

---

# Coming Up Next

In **Lesson 2.9 — Responsive Layouts and Sizing**, we'll learn how to make our dashboard adapt gracefully to different screen sizes. You'll explore sizing modes, fixed versus responsive layouts, width and height policies, stretching behavior, and best practices for creating applications that look equally good on laptops, large monitors, and tablets. By the end of the lesson, your SGX Stock Monitor will begin behaving like a modern, responsive web application rather than a fixed-size desktop interface.
