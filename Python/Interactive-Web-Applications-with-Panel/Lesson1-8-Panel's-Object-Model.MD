# Part I — Foundations

# Lesson 1.8 — Understanding Panel's Object Model

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand why everything in Panel is an object.
> * Explain what an object is.
> * Understand the concept of a `Viewable`.
> * Understand the relationship between Panes, Widgets, Layouts, and Templates.
> * Explain how Panel applications are constructed from objects.
> * Understand why the object model makes Panel flexible and extensible.
> * Build a mental model that will be used throughout the rest of this tutorial.

---

# Introduction

In the previous lesson, we wrote this simple application.

```python
import panel as pn

pn.extension()

pn.pane.Markdown("# SGX Stock Monitor")
```

It displayed a heading.

Simple enough.

But something much more important happened behind the scenes.

We created our **first Panel object.**

Everything in Panel is an object.

This is perhaps the single most important concept you will learn in this entire tutorial.

Once you understand it,

Panel suddenly becomes much easier to understand.

---

# What Is an Object?

Before discussing Panel,

let's first understand what an object is.

Many beginners hear terms like:

* Object
* Class
* Instance

and immediately become intimidated.

Don't be.

The underlying idea is actually very simple.

---

## Think About the Real World

Look around your room.

You probably see things like:

* a chair
* a table
* a laptop
* a phone
* a coffee mug

Each of these is an object.

Objects have two things.

---

## Objects Have Properties

A chair has:

* colour
* height
* material
* weight

A phone has:

* screen size
* battery level
* storage
* operating system

These characteristics are called **properties** (or **attributes**).

---

## Objects Have Behaviors

Objects also do things.

A chair can:

* support someone sitting

A phone can:

* make calls
* display apps
* play music

These actions are called **behaviors** (or **methods**).

---

# Software Objects

Programming uses exactly the same idea.

Instead of physical objects,

we create software objects.

For example,

our Markdown pane.

```python
pn.pane.Markdown("# SGX Stock Monitor")
```

is an object.

It has:

Properties

* text
* width
* height
* styles

Behaviors

* display itself
* update its content
* resize itself

---

# Why Does Panel Use Objects?

Imagine if Panel didn't use objects.

Instead,

suppose we had separate functions for everything.

```python
create_button()

resize_button()

style_button()

move_button()

show_button()

hide_button()
```

As applications become larger,

this quickly becomes difficult to manage.

Instead,

Panel groups related information together.

```text
Button Object

├── Text
├── Width
├── Height
├── Colour
├── Disabled

+

Methods

├── Show()
├── Hide()
├── Update()
```

Everything related to the button lives together.

This is much easier to understand.

---

# Every Visible Thing Is an Object

One of Panel's design principles is:

> **If you can see it, it's probably an object.**

For example,

all of these are objects.

```text
Markdown

Button

Slider

Image

Table

Chart

Column

Row

Sidebar

Template
```

Everything you place on the screen is represented by an object.

---

# Our First Object

Let's revisit our code.

```python
pn.pane.Markdown("# SGX Stock Monitor")
```

Many beginners think this simply "prints text."

That's not what happens.

Instead,

Panel creates a **Markdown object**.

Conceptually,

this happens.

```text
Python Code

↓

Create Markdown Object

↓

Panel Stores Object

↓

Browser Displays Object
```

The object continues to exist even after it has been displayed.

---

# Introducing Viewables

Now we can introduce one of Panel's most important concepts.

A **Viewable**.

---

## What Is a Viewable?

A Viewable is

> **Anything that Panel knows how to display.**

Think about that definition carefully.

Anything that can appear on the screen

is a Viewable.

---

# Examples of Viewables

These are all Viewables.

```text
Markdown

HTML

Button

Slider

Checkbox

Image

DataFrame

Plot

Column

Row

Template
```

Different objects.

Same idea.

Panel knows how to display each one.

---

# Why Is It Called "Viewable"?

Because it can be viewed.

If an object can appear inside your application,

it is a Viewable.

Simple.

---

# A Hierarchy of Objects

Now let's look at Panel's architecture.

```text
                Viewable

                    │

     ┌──────────────┼──────────────┐

   Pane          Widget         Layout

                                      │

                                  Template
```

This diagram is extremely important.

Almost everything you'll build belongs somewhere in this hierarchy.

Let's examine each category.

---

# Panes

We've already met one.

```python
pn.pane.Markdown()
```

A Pane displays information.

Examples include:

* Markdown
* HTML
* Images
* DataFrames
* Plotly figures
* Matplotlib figures

Think of Panes as:

> Things you look at.

---

# Widgets

Widgets are different.

They collect information from the user.

Examples:

```text
Button

Slider

Checkbox

TextInput

Select

DatePicker
```

Unlike Panes,

Widgets are interactive.

The user can change them.

---

For example,

a stock search box.

```text
Search

[ DBS________ ]
```

The user types.

The Widget remembers what was entered.

---

# Layouts

Suppose we have three objects.

```text
Button

Chart

Table
```

Where should they appear?

Panel needs a way to arrange them.

That's the job of Layouts.

Examples:

```python
pn.Column()

pn.Row()

pn.GridBox()
```

Layouts answer questions like:

* Above?
* Below?
* Side by side?
* Grid?

---

Imagine building with LEGO.

The individual bricks are objects.

The Layout decides where each brick goes.

---

# Templates

Templates are the largest objects.

They define the overall structure of an application.

For example,

our future SGX Stock Monitor might look like:

```text
+------------------------------------------------+

Sidebar

Search

Watchlist

Portfolio

----------------------

Main Area

Charts

Tables

News

+------------------------------------------------+
```

The Template provides this overall structure.

Later,

we'll use professional templates built into Panel.

---

# How Objects Combine

One object is interesting.

Many objects become an application.

Imagine building our dashboard.

```text
Markdown

+

Button

+

Search Box

+

Chart

+

Table
```

Each one is an object.

Panel combines them.

Eventually we get:

```text
SGX Stock Monitor
```

This is why Panel applications scale so well.

Large applications are simply collections of smaller objects.

---

# Objects Can Contain Other Objects

Here's another powerful idea.

Objects can contain other objects.

For example,

a Column.

```python
pn.Column(
    object1,
    object2,
    object3
)
```

The Column itself is an object.

But it also contains other objects.

Conceptually:

```text
Column

├── Markdown

├── Button

└── Chart
```

This idea appears everywhere in Panel.

---

# A Real Example

Imagine our future application.

```text
Template

│

├── Sidebar

│      ├── Search Box

│      ├── Watchlist

│      └── Buttons

│

└── Main Area

       ├── Price Chart

       ├── Company Information

       └── Historical Data
```

Every box above

is an object.

The entire application is simply

objects containing other objects.

---

# Why This Design Is Powerful

Suppose we decide later to replace

```text
Chart A
```

with

```text
Chart B
```

Everything else stays the same.

Or perhaps we add:

```text
News Panel
```

We don't rewrite the application.

We simply add another object.

Object-oriented design encourages building software from reusable, composable pieces.

---

# Thinking in Objects

One of the biggest mindset shifts you'll make is this.

Don't think:

> "How do I draw a dashboard?"

Instead think:

> "What objects make up my dashboard?"

For example:

```text
Dashboard

↓

Template

↓

Sidebar

↓

Search Widget

↓

Chart Pane

↓

Table Pane

↓

Footer
```

Large applications become much less intimidating when you break them into objects.

---

# Teacher's Notes

> Many beginners think that a Panel application is a single large object. In reality, it is more like a tree.
>
> At the top might be a Template. Inside the Template are Layouts. Inside those Layouts are Widgets and Panes. Some of those objects may themselves contain additional objects.
>
> Keeping this mental model in mind will make it much easier to understand how Panel applications are assembled and why they are so flexible. As our SGX Stock Monitor grows over the coming lessons, you'll see this object tree expand naturally.

---

# Common Mistakes

### ❌ Mistake 1

Thinking a Markdown pane is "just text."

It isn't.

It is an object that displays text.

---

### ❌ Mistake 2

Thinking Layouts display data.

Layouts arrange objects.

The objects themselves display the data.

---

### ❌ Mistake 3

Thinking Widgets and Panes are interchangeable.

Widgets collect input.

Panes display output.

They serve different purposes.

---

### ❌ Mistake 4

Trying to build an entire application as one large block of code.

Panel encourages building many small, reusable objects that are composed into larger structures.

---

# Summary

In this lesson, you learned:

* Everything visible in a Panel application is represented as an object.
* Objects have properties (attributes) and behaviors (methods).
* A **Viewable** is anything that Panel knows how to display.
* The major categories of Viewables include Panes, Widgets, Layouts, and Templates.
* Panel applications are built by composing many smaller objects into larger ones.
* Thinking in terms of objects makes it easier to design, understand, and maintain complex applications.

This object-oriented approach is one of the foundations of Panel and will appear repeatedly throughout the rest of this tutorial.

---

# Exercises

## Exercise 1 — Identify the Objects

Consider the following interface:

```text
--------------------------------------

SGX Stock Monitor

Search: [__________]

[ Refresh ]

📈 Price Chart

📊 Historical Prices

--------------------------------------
```

Identify which parts are likely to be:

* Panes
* Widgets
* Layouts

---

## Exercise 2 — Break It Down

Imagine you want to build an application that displays:

* A title
* A stock search box
* A chart
* A table
* A footer

Draw a simple object hierarchy showing how these components might be organized inside a Panel application.

---

## Exercise 3 — Reflection

Explain, in your own words:

> Why is building an application from many small objects generally easier than building one giant object?

Consider aspects such as readability, maintenance, testing, and adding new features.

---

## Coming Up Next

In **Lesson 1.9 — Your First Real Dashboard**, we'll move beyond displaying a single heading. You'll learn about **Layouts**, beginning with `pn.Column` and `pn.Row`, and build the first recognizable version of our SGX Stock Monitor by arranging multiple components on the page. This marks the transition from learning individual Panel concepts to constructing complete user interfaces.
