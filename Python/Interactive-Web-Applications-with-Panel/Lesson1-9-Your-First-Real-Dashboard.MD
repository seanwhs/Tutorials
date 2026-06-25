# Part I — Foundations

# Lesson 1.9 — Your First Real Dashboard

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what a Layout is.
> * Explain why layouts are fundamental to every Panel application.
> * Understand the purpose of `pn.Column()`.
> * Understand the purpose of `pn.Row()`.
> * Arrange multiple objects on the screen.
> * Understand how nested layouts work.
> * Build the first recognizable version of the SGX Stock Monitor.

---

# Introduction

Until now, our application has been extremely simple.

```text
SGX Stock Monitor
```

It only contains a single object.

That means we haven't yet answered an important question.

> **What happens when we have many objects?**

Imagine our future application.

```text
SGX Stock Monitor

Search Box

Stock Information

Price Chart

Historical Data

News

Watchlist
```

How does Panel know where everything should appear?

The answer is:

**Layouts.**

Layouts are one of the most important concepts in Panel.

---

# What Is a Layout?

A Layout is an object that arranges other objects.

Think of it as a container.

Instead of displaying information itself,

it organizes information.

Imagine moving into a new house.

You have:

* a sofa
* a television
* a dining table
* a bookshelf

You don't throw everything into one pile.

Instead,

you decide where each item belongs.

Layouts perform the same job.

---

# Why Do We Need Layouts?

Suppose Panel didn't have layouts.

You created:

* a title
* a button
* a chart
* a table

Where should they appear?

Nobody knows.

The application needs rules for arranging objects.

Layouts provide those rules.

---

# Meet `pn.Column()`

The simplest layout in Panel is

```python
pn.Column()
```

A Column arranges objects

**vertically**.

Imagine stacking books.

```text
Book

↓

Book

↓

Book

↓

Book
```

Everything is placed one below another.

---

# Our First Column

Let's update our application.

```python
import panel as pn

pn.extension()

dashboard = pn.Column(
    pn.pane.Markdown("# SGX Stock Monitor"),
    pn.pane.Markdown("Welcome to our first dashboard!")
)

dashboard
```

Our application now contains two objects instead of one.

---

# Understanding the Code

Let's examine the new parts.

---

## Creating a Variable

```python
dashboard =
```

This stores the layout inside a variable.

Why?

Because later,

we'll continue adding objects to it.

Think of it as giving our dashboard a name.

---

# What Is `pn.Column()`?

This creates a Column object.

Remember:

Layouts are objects too.

Our application now looks like this.

```text
Column

├── Markdown

└── Markdown
```

The Column doesn't display text.

The Markdown panes do.

The Column only arranges them.

---

# What Does the Screen Look Like?

The browser displays:

```text
---------------------------------

SGX Stock Monitor

Welcome to our first dashboard!

---------------------------------
```

Notice that the objects appear

one below another.

Exactly as a Column should.

---

# Adding More Objects

Let's keep adding.

```python
import panel as pn

pn.extension()

dashboard = pn.Column(
    pn.pane.Markdown("# SGX Stock Monitor"),
    pn.pane.Markdown("Welcome to our first dashboard."),
    pn.pane.Markdown("Today's Market Status"),
    pn.pane.Markdown("No stock selected.")
)

dashboard
```

The hierarchy now becomes:

```text
Column

├── Markdown

├── Markdown

├── Markdown

└── Markdown
```

The Column doesn't care what it contains.

It simply stacks everything vertically.

---

# Meet `pn.Row()`

Sometimes,

we don't want objects stacked vertically.

Instead,

we want them beside one another.

For that,

we use

```python
pn.Row()
```

A Row arranges objects

**horizontally**.

Imagine people standing in a queue.

```text
Person   Person   Person   Person
```

Everything is placed side by side.

---

# Our First Row

```python
import panel as pn

pn.extension()

dashboard = pn.Row(
    pn.pane.Markdown("DBS"),
    pn.pane.Markdown("OCBC"),
    pn.pane.Markdown("UOB")
)

dashboard
```

The browser displays something similar to:

```text
DBS     OCBC     UOB
```

Instead of appearing vertically,

they appear horizontally.

---

# Column vs Row

Think of them like arrows.

Column

```text
↓

↓

↓

↓
```

Row

```text
→ → → →
```

That's really the only difference.

---

# Comparing Them

## Column

```python
pn.Column(
    object1,
    object2,
    object3
)
```

Produces

```text
Object 1

Object 2

Object 3
```

---

## Row

```python
pn.Row(
    object1,
    object2,
    object3
)
```

Produces

```text
Object 1    Object 2    Object 3
```

---

# Nesting Layouts

Things become much more interesting when layouts contain other layouts.

Remember:

Layouts are objects.

That means one layout can contain another.

Example:

```python
pn.Column(
    pn.Row(
        object1,
        object2
    ),
    object3
)
```

Notice something.

The Column contains

a Row.

---

# Visualizing the Hierarchy

```text
Column

├── Row
│
│   ├── Object
│
│   └── Object
│
└── Object
```

This is called

**nesting**.

Nesting is one of the most powerful ideas in Panel.

---

# Building Our First Dashboard

Let's build something that actually resembles an application.

```python
import panel as pn

pn.extension()

title = pn.pane.Markdown("# SGX Stock Monitor")

search = pn.pane.Markdown("🔍 Search Box (coming soon)")

market = pn.pane.Markdown("📈 Market Overview")

watchlist = pn.pane.Markdown("⭐ Watchlist")

dashboard = pn.Column(
    title,
    search,
    pn.Row(
        market,
        watchlist
    )
)

dashboard
```

---

# Understanding the Hierarchy

Our application now looks like this.

```text
Column

├── Title

├── Search

└── Row

    ├── Market

    └── Watchlist
```

The browser might display something like:

```text
--------------------------------------------

SGX Stock Monitor

Search Box

Market Overview      Watchlist

--------------------------------------------
```

We're beginning to create a real dashboard.

---

# Why Variables Are Useful

Notice this code.

```python
title = pn.pane.Markdown(...)
```

instead of

```python
pn.pane.Markdown(...)
```

Why?

Because variables make our code easier to read.

Imagine having twenty widgets.

Without variables,

the code quickly becomes difficult to understand.

Variables allow us to refer to objects by meaningful names.

Examples:

```python
search_box

price_chart

portfolio_table

news_panel
```

Much easier to read.

---

# Building Applications Like LEGO

Think about LEGO bricks.

One brick isn't very exciting.

But many bricks together create:

* houses
* cars
* castles
* cities

Panel works the same way.

Small objects become larger objects.

Larger objects become applications.

```text
Markdown

↓

Column

↓

Dashboard

↓

Complete Application
```

---

# Thinking Hierarchically

Whenever you build a Panel application,

don't think about the screen.

Think about the object tree.

Instead of asking:

> "Where do I put the chart?"

Ask:

> "Which layout should contain the chart?"

This shift in thinking makes complex interfaces much easier to design.

---

# Our Application So Far

Although simple,

our SGX Stock Monitor now has recognizable sections.

```text
---------------------------------------------------

SGX Stock Monitor

Search Box (Coming Soon)

Market Overview      Watchlist

---------------------------------------------------
```

We're still using placeholder text.

In future lessons,

these placeholders will become real widgets,

real charts,

and real market data.

---

# Teacher's Notes

> Beginners often underestimate the importance of layouts because they seem simple at first. In reality, layouts determine the structure of your entire application.
>
> As your dashboard grows, you'll spend far more time organizing components than creating them. A clear layout hierarchy makes your application easier to understand, easier to modify, and easier to extend.
>
> A useful habit is to sketch your application's layout on paper before writing code. Once you're comfortable thinking in terms of Columns and Rows, translating the sketch into Panel code becomes straightforward.

---

# Common Mistakes

### ❌ Mistake 1

Putting every object into one enormous `pn.Column()`.

Large applications should be broken into smaller nested layouts.

---

### ❌ Mistake 2

Confusing a Layout with a Pane.

Layouts arrange objects.

Panes display content.

---

### ❌ Mistake 3

Writing deeply nested layouts without using variables.

Meaningful variable names make large interfaces much easier to understand and maintain.

---

### ❌ Mistake 4

Thinking the screen layout first.

Instead, think about the object hierarchy. Once the hierarchy is clear, the visual layout naturally follows.

---

# Summary

In this lesson, you learned:

* A Layout arranges other Panel objects.
* `pn.Column()` stacks objects vertically.
* `pn.Row()` places objects horizontally.
* Layouts are themselves objects and can contain other layouts.
* Nested layouts allow you to build sophisticated user interfaces from simple building blocks.
* Using variables for important components improves readability and maintainability.
* Every Panel application can be viewed as a hierarchy—or tree—of nested objects.

Our SGX Stock Monitor now has its first real dashboard structure. While the content is still static, we've established the architectural foundation that we'll build upon throughout the rest of the tutorial.

---

# Exercises

## Exercise 1 — Vertical vs Horizontal

Create two small applications:

1. A `Column` containing:

   * A title
   * Three Markdown panes

2. A `Row` containing:

   * Three Markdown panes

Observe how the layouts differ.

---

## Exercise 2 — Create a Nested Layout

Build the following hierarchy:

```text
Column

├── Title

├── Row

│   ├── Left Panel

│   └── Right Panel

└── Footer
```

Use only Markdown panes as placeholders.

---

## Exercise 3 — Plan Your Dashboard

Without writing any code, sketch the object hierarchy for a stock monitoring application containing:

* Title
* Search box
* Price chart
* Company information
* Watchlist
* News section
* Footer

Try to identify which parts should be `Column`s and which should be `Row`s.

---

## Coming Up Next

In **Lesson 1.10 — Serving, Displaying, and Making Objects Visible**, we'll answer a question that puzzles many beginners:

> **Why does writing `dashboard` at the end of the file display the application?**

You'll learn how Panel decides what to render, the difference between creating an object and displaying it, how `.servable()` works, and why understanding these concepts becomes essential as your applications grow beyond a single file. This lesson will also introduce best practices that we'll use for the remainder of the SGX Stock Monitor project.
