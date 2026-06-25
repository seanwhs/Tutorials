# Part II — Widgets: Building Interactive User Interfaces

# Lesson 2.10 — Templates: Building Professional Dashboards

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what a Panel Template is.
> * Learn why templates exist.
> * Understand the difference between layouts and templates.
> * Explore the built-in templates provided by Panel.
> * Learn how templates organize complete applications.
> * Build the first professional version of our SGX Stock Monitor.
> * Understand when to choose different templates.

---

# Introduction

Our application has come a long way.

It now has:

* A title
* A search box
* A Search button
* A results area
* Responsive layouts

It looks something like this.

```text
------------------------------------------------

SGX Stock Monitor

------------------------------------------------

Search______________________ [ Search ]

------------------------------------------------

No search performed.

------------------------------------------------
```

This works well.

But...

compare it with a professional financial application.

Bloomberg

TradingView

Yahoo Finance

Most professional dashboards have:

* Navigation
* Sidebars
* Headers
* Branding
* Multiple panels
* Consistent spacing
* Professional styling

Can we build all of that ourselves?

Yes.

Should we?

Usually not.

Panel already provides it.

---

# What Is a Template?

A **Template** is a pre-built application layout.

Instead of manually creating the structure of an entire application,

Panel provides one for you.

Think of a template as the frame of a house.

```text
House

↓

Foundation

↓

Walls

↓

Rooms
```

You don't start by pouring concrete every time.

You begin with an existing structure.

Templates do the same thing.

---

# Layout vs Template

Many beginners confuse these two ideas.

Let's compare them.

| Layout            | Template                         |
| ----------------- | -------------------------------- |
| Organizes widgets | Organizes the entire application |
| `Row()`           | Complete webpage                 |
| `Column()`        | Header                           |
| Small sections    | Sidebar                          |
| Local arrangement | Overall structure                |

---

Think of building a shopping mall.

Layouts arrange the furniture inside one shop.

Templates arrange the entire shopping mall.

Both are important,

but they solve different problems.

---

# Why Use Templates?

Without templates,

you must create:

* Header
* Logo
* Navigation
* Sidebar
* Main content area
* Responsive behavior
* Styling

for every application.

Templates provide these automatically.

---

# The Evolution of Our Dashboard

So far,

our application looks roughly like this.

```text
Column

├── Title

├── Search Controls

└── Results
```

After using a template,

the application becomes

```text
Header

Sidebar

Main Area

Footer
```

Notice that the template sits **outside** our layouts.

---

# Panel's Built-in Templates

Panel includes several ready-to-use templates.

Some of the most popular are:

```python
pn.template.FastListTemplate

pn.template.FastGridTemplate

pn.template.MaterialTemplate

pn.template.BootstrapTemplate

pn.template.VanillaTemplate
```

Each has a different appearance and purpose.

---

# Which Template Should Beginners Learn?

For this tutorial,

we'll use

```python
pn.template.FastListTemplate
```

Why?

Because it is:

* Modern
* Responsive
* Simple
* Clean
* Easy to understand
* Excellent for dashboards

Later,

we'll explore the others.

---

# Understanding FastListTemplate

Conceptually,

it provides

```text
----------------------------------------

Header

----------------------------------------

Main Content

----------------------------------------
```

You simply place your components into the template.

---

# Creating Our First Template

Instead of creating a dashboard using only

```python
pn.Column()
```

we create a template.

```python
template = pn.template.FastListTemplate(

    title="SGX Stock Monitor"

)
```

Notice something.

We aren't adding widgets yet.

We've only created the application shell.

---

# What Does the Title Do?

The

```python
title=
```

parameter controls the application's title.

```python
template = pn.template.FastListTemplate(

    title="SGX Stock Monitor"

)
```

Produces something like

```text
----------------------------------------

SGX Stock Monitor

----------------------------------------
```

The title appears in the header,

not inside the page content.

---

# Adding Content

Templates contain areas where content can be placed.

For a `FastListTemplate`,

the primary area is

```python
template.main
```

Think of it as the application's main workspace.

---

Adding components is simple.

```python
template.main.append(search)

template.main.append(button)

template.main.append(results)
```

Each component is added to the main content area.

---

# Visualizing the Structure

```text
FastListTemplate

├── Header

├── Main

│     ├── Search Box

│     ├── Button

│     └── Results
```

Notice that

our widgets haven't changed.

Only the container has changed.

---

# The Complete Example

```python
import panel as pn

pn.extension()

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

template = pn.template.FastListTemplate(

    title="SGX Stock Monitor"

)

template.main.append(search)

template.main.append(button)

template.main.append(results)

template.servable()
```

Notice how little code changed.

---

# Improving the Layout

Rather than adding every widget separately,

we can still use layouts.

```python
controls = pn.Row(

    search,

    button
)

dashboard = pn.Column(

    controls,

    results
)

template.main.append(dashboard)
```

This is the recommended approach.

Templates organize the application.

Layouts organize sections within the application.

---

# The Relationship

Think of it like this.

```text
Template

↓

Contains

↓

Layouts

↓

Contain

↓

Widgets

↓

Display

↓

Information
```

Everything we've learned remains useful.

Templates don't replace layouts.

They use them.

---

# Sidebar Support

Many templates include a sidebar.

Imagine our future stock dashboard.

```text
-----------------------------------------

Header

-----------------------------------------

Sidebar        Main Content

Portfolio      Price Chart

Watchlist      Company Info

News           Statistics

Settings

-----------------------------------------
```

Sidebars are excellent for:

* Navigation
* Settings
* Filters
* Watchlists
* Menus

---

# Adding Sidebar Content

Many templates support

```python
template.sidebar.append(...)
```

For example,

```python
template.sidebar.append(

    pn.widgets.Select(

        name="Market",

        options=["SGX", "NYSE", "NASDAQ"]

    )

)
```

Now,

the market selector appears in the sidebar.

---

# Why Not Put Everything in the Sidebar?

Sidebars should contain

controls,

not primary content.

Good sidebar items include:

* Search filters
* Settings
* Navigation
* Watchlists

Poor sidebar items include:

* Large charts
* Huge tables
* Long reports

These belong in the main area.

---

# Thinking Like an Application Designer

Professional developers think in layers.

```text
Application

↓

Template

↓

Layouts

↓

Widgets

↓

User
```

Each layer has a specific responsibility.

---

# Our Future SGX Dashboard

Later in this tutorial,

our application may look like this.

```text
-----------------------------------------------------

SGX Stock Monitor

-----------------------------------------------------

Sidebar

• Watchlist

• Markets

• Portfolio

-----------------------------------------------------

Main

Search ____________________ [Search]

--------------------------------------

Price Chart

--------------------------------------

Company Information

--------------------------------------

Financial Ratios

--------------------------------------

Recent News

-----------------------------------------------------
```

Notice how much more professional this feels.

---

# Other Templates

Although we're focusing on

`FastListTemplate`,

it's worth knowing that Panel offers alternatives.

### `FastGridTemplate`

Ideal for dashboards containing many charts.

```text
Chart     Chart

Table     News
```

---

### `MaterialTemplate`

Inspired by Google's Material Design.

Suitable for business applications.

---

### `BootstrapTemplate`

Based on the Bootstrap CSS framework.

Familiar to many web developers.

---

### `VanillaTemplate`

Minimal styling.

Good when you want complete control over appearance.

---

# Which Template Should I Choose?

A general guideline is:

| Application          | Template          |
| -------------------- | ----------------- |
| Learning Panel       | FastListTemplate  |
| Analytics Dashboard  | FastGridTemplate  |
| Business Application | MaterialTemplate  |
| Bootstrap Website    | BootstrapTemplate |
| Custom Design        | VanillaTemplate   |

As you gain experience,

you'll learn to choose the template that best matches your project's needs.

---

# Teacher's Notes

> Templates are one of Panel's biggest productivity features. They allow you to focus on your application's functionality instead of spending time recreating common interface elements like headers, sidebars, and responsive page structures.
>
> Notice that templates don't replace everything we've learned. Instead, they sit at the top of the application's hierarchy. Inside a template, you'll continue using `Row`, `Column`, `Tabs`, `Markdown`, widgets, charts, and every other Panel component exactly as before.

---

# Common Mistakes

## ❌ Mistake 1

Thinking templates replace layouts.

They don't.

Templates contain layouts.

---

## ❌ Mistake 2

Adding every widget individually.

Instead,

group related widgets into layouts first.

---

## ❌ Mistake 3

Putting all application content into the sidebar.

The sidebar should mainly contain controls and navigation.

---

## ❌ Mistake 4

Choosing a complex template too early.

Start with

```python
FastListTemplate
```

It is simple,

clean,

and excellent for learning.

---

# Summary

In this lesson, you learned:

* A Template organizes an entire Panel application.
* Layouts organize sections inside a template.
* `FastListTemplate` is an excellent starting point for beginners.
* Templates provide built-in headers, responsive behavior, and professional styling.
* Content is typically added using `template.main.append(...)`.
* Many templates also provide a `sidebar` for navigation and controls.
* Templates and layouts work together to create maintainable, professional dashboards.

Our SGX Stock Monitor has now evolved from a simple collection of widgets into a structured web application with a professional foundation.

---

# Exercises

## Exercise 1 — Your First Template

Create a `FastListTemplate` with the title:

```text
My First Panel Dashboard
```

Add a Markdown pane saying:

```text
Welcome to my dashboard!
```

Display the template in your browser.

---

## Exercise 2 — Migrate Your SGX Dashboard

Take your existing SGX Stock Monitor and move it into a `FastListTemplate`.

Keep using your existing `Row` and `Column` layouts inside the template.

Observe how the overall appearance changes.

---

## Exercise 3 — Design a Professional Stock Dashboard

Without writing code, sketch a dashboard that uses:

* A header
* A sidebar
* A main content area

Place the following components where you think they belong:

* Search controls
* Watchlist
* Price chart
* Company information
* Financial ratios
* Market news
* Portfolio summary

Explain why you placed each component in its chosen location.

---

# Coming Up Next

In **Lesson 2.11 — Serving and Running Panel Applications**, we'll learn how to transform our Python script into a real web application. You'll understand what happens when you run `panel serve`, how the Bokeh server powers Panel behind the scenes, how browser sessions are created, and how to organize your project for development. This is the lesson where your SGX Stock Monitor stops being "just a Python script" and becomes a genuine web application that users can access through their browser.
