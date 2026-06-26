# Part IV — Building the Panel User Interface

# Lesson 4.6 — Styling, Templates, and Themes: Building Professional-Looking Panel Applications

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand the difference between functionality and presentation.
> * Learn how Panel controls the appearance of components.
> * Understand sizing modes.
> * Learn about margins, padding, and alignment.
> * Understand responsive layouts.
> * Learn how themes work.
> * Explore Panel templates.
> * Build a professional dashboard layout for our SGX Stock Monitor.
> * Understand when custom CSS is appropriate.

---

# Introduction

At this point, our SGX Stock Monitor is becoming a real application.

We have learned:

* Panes
* Widgets
* Event handling
* Layouts

Technically,

our application works.

However,

working software isn't necessarily good software.

Consider these two dashboards.

Dashboard A

```text
------------------------------------------------

SGX Dashboard

Search

Button

Price

Chart

Table

News

------------------------------------------------
```

Dashboard B

```text
------------------------------------------------

        SGX Stock Monitor

[D05___________] [ Search ]

--------------------------------------------

Current Price

--------------------------------------------

Interactive Price Chart

--------------------------------------------

Recent Trading Activity

--------------------------------------------

Latest News

------------------------------------------------
```

Both dashboards display exactly the same information.

Yet one appears much more professional.

Today's lesson focuses on transforming functional applications into polished applications.

---

# What Is Styling?

**Styling** refers to

> **how an application looks.**

Styling controls things such as:

* colors
* fonts
* spacing
* alignment
* sizing
* borders
* themes

Notice that styling changes appearance,

not functionality.

---

# Separating Logic from Presentation

Throughout this tutorial,

we've separated responsibilities.

```text
Business Logic

↓

MarketDataService

----------------------

Presentation

↓

Panel
```

Styling belongs entirely to the presentation layer.

Changing the appearance of a button should never require modifying business logic.

---

# Why Appearance Matters

Imagine using two websites.

Website A

* cluttered
* inconsistent
* difficult to read

Website B

* organized
* clean
* consistent

Which would you trust with your financial data?

Good visual design increases:

* usability
* readability
* confidence
* professionalism

---

# Responsive Design Revisited

Earlier,

we briefly introduced responsive design.

Let's explore it further.

Suppose our dashboard is viewed on:

* a laptop
* a widescreen monitor
* a tablet

Should users have three completely different applications?

No.

Instead,

the layout should adapt automatically.

---

# Understanding Sizing Modes

Panel provides

```python
sizing_mode=
```

This controls how components resize.

Common values include:

| Mode               | Description                           |
| ------------------ | ------------------------------------- |
| `"fixed"`          | Fixed width and height                |
| `"stretch_width"`  | Expands horizontally                  |
| `"stretch_height"` | Expands vertically                    |
| `"stretch_both"`   | Expands in both directions            |
| `"scale_width"`    | Scales while maintaining proportions  |
| `"scale_both"`     | Scales both dimensions proportionally |

One of the strengths of Panel is that many layouts become responsive simply by choosing an appropriate sizing mode.

---

# Fixed vs Responsive

Suppose we create

```text
Width = 400 pixels
```

On a large monitor,

it may appear very small.

Now suppose we use

```text
stretch_width
```

The component expands automatically.

```text
Large Screen

+--------------------------------------------+

Search Box

+--------------------------------------------+
```

On a smaller screen,

it shrinks appropriately.

---

# Why Responsive Layouts Matter

Imagine a search box that is only 80 pixels wide.

```text
[D0]
```

Typing stock symbols becomes frustrating.

Now imagine

```text
[D05____________________________]
```

Much easier.

Responsive sizing improves usability.

---

# Width and Height

Individual components may specify

```python
width=
```

or

```python
height=
```

Example

```python
pn.widgets.Button(

    width=150

)
```

This gives the button a preferred width.

---

# Should We Always Set Widths?

Usually,

no.

Allowing layouts to manage sizing often produces more flexible applications.

Explicit widths are useful only when specific dimensions are required.

---

# Margins

A margin controls

the space **outside** a component.

Imagine placing a picture frame on a wall.

The empty wall surrounding the frame is similar to a margin.

---

# Visualizing Margins

Without margins

```text
+------------------+
Button
Price
Chart
+------------------+
```

With margins

```text
+------------------+

Button

Price

Chart

+------------------+
```

The content becomes easier to read.

---

# Padding

Padding controls the space

**inside** a component.

Imagine a box.

The object inside the box should not touch the edges.

Padding provides breathing room.

---

# Margin vs Padding

A common beginner confusion.

```text
Outside Space

↓

Margin

+-------------------------+

Padding

↓

Content

+-------------------------+
```

Remember:

Margin

↓

Outside

Padding

↓

Inside

---

# Alignment

Components may also be aligned.

Examples include:

* left
* center
* right

For example,

our dashboard title should probably appear centered,

while stock information may be left-aligned.

Alignment helps establish visual hierarchy.

---

# Visual Hierarchy

Users naturally read pages from top to bottom.

Important information should therefore appear:

* near the top
* larger
* visually separated

For example,

our stock price deserves more emphasis than the timestamp of the latest update.

---

# Introducing Themes

Changing every color manually would be tedious.

Instead,

Panel provides

**Themes**.

A theme defines the overall appearance of an application.

Think of it as a design package.

---

# What Does a Theme Control?

A theme may define:

* colors
* fonts
* borders
* spacing
* widget appearance
* backgrounds

Changing one theme updates the appearance of the entire dashboard.

---

# Light Theme

A light theme generally contains:

```text
Background

↓

White

Text

↓

Dark
```

This resembles most websites.

---

# Dark Theme

A dark theme generally contains:

```text
Background

↓

Dark Gray

Text

↓

Light
```

Dark themes are popular for:

* monitoring dashboards
* financial trading platforms
* software development tools

---

# Why Traders Often Prefer Dark Themes

Many trading platforms use dark themes because they reduce glare,

especially when monitoring markets for extended periods.

Since our SGX dashboard monitors live market information,

a dark theme can be an attractive option.

---

# Introducing Templates

So far,

we've manually built layouts.

Panel also provides

**Templates**.

A template is a pre-designed application structure.

Think of it as an architectural blueprint.

---

# Why Templates Exist

Without templates,

every application starts with a blank page.

Templates provide:

* navigation
* headers
* sidebars
* content areas
* responsive behaviour

This allows developers to focus on application logic.

---

# Common Panel Templates

Panel includes several built-in templates.

Examples include:

* FastListTemplate
* FastGridTemplate
* BootstrapTemplate
* MaterialTemplate
* VanillaTemplate

Each has a different appearance and layout philosophy.

---

# Which Template Will We Use?

Throughout this tutorial,

we'll primarily use

**FastListTemplate**

Why?

Because it provides:

* clean appearance
* responsive layout
* modern styling
* beginner-friendly structure

It's an excellent starting point for dashboard applications.

---

# Understanding the Template Structure

Conceptually,

our application becomes

```text
Template

├── Header

├── Sidebar

└── Main Content
```

Instead of designing every section ourselves,

the template already provides the framework.

---

# Our SGX Dashboard Layout

Our application might eventually resemble this.

```text
+-----------------------------------------------------------+

                 SGX Stock Monitor

===========================================================

Sidebar

Stock Symbol

[D05________]

[ Search ]

----------------------------------

Main Area

Current Price

Chart

Company Information

Trading Volume

News

-----------------------------------------------------------+
```

Notice how the sidebar separates controls from information.

This is a common dashboard pattern.

---

# Custom CSS

Sometimes,

Panel's built-in styling isn't enough.

Developers may add

**CSS**

to customize appearance.

CSS stands for

> **Cascading Style Sheets**

It is the language used to style webpages.

---

# Should Beginners Learn CSS Now?

Not yet.

Panel already provides excellent defaults.

As beginners,

our goal is to learn application development,

not frontend design.

Later,

if you need:

* custom colors
* animations
* branding
* company-specific themes

CSS becomes valuable.

---

# Styling Best Practices

Professional dashboards generally follow these principles.

* Use consistent spacing.
* Avoid overcrowding.
* Limit the number of colors.
* Group related information.
* Highlight only important values.
* Use responsive layouts.
* Prefer templates over manually designing every page.

Good styling supports usability rather than distracting from it.

---

# Thinking Like a UI Designer

Imagine a dashboard displaying:

* stock prices
* charts
* news
* financial ratios
* historical data

Users should immediately understand:

* where to search
* where to find prices
* where charts appear
* where company information is displayed

Good styling guides the user's attention.

---

# Teacher's Notes

> Styling is often viewed as "making things pretty," but that description is misleading. Good styling improves communication. Proper spacing, alignment, typography, and color choices help users locate information more quickly and reduce cognitive load. In professional software engineering, visual design is considered part of usability, not merely decoration.
>
> Another important recommendation is to adopt a template early rather than attempting to build every page from scratch. Templates encapsulate years of user interface design experience and provide consistent layouts across applications. This allows developers to focus on solving business problems instead of repeatedly designing common interface structures.

---

# Common Mistakes

## ❌ Mistake 1

Using fixed widths for every component.

Responsive layouts are usually more flexible.

---

## ❌ Mistake 2

Adding too many colors.

A small, consistent color palette is easier to understand.

---

## ❌ Mistake 3

Crowding components together.

White space improves readability.

---

## ❌ Mistake 4

Ignoring templates.

Templates provide professional layouts with minimal effort.

---

## ❌ Mistake 5

Mixing presentation logic with business logic.

Styling belongs in the presentation layer.

---

# Summary

In this lesson, you learned:

* Styling controls the appearance of an application without affecting its functionality.
* Responsive design helps applications adapt to different screen sizes.
* `sizing_mode` determines how components resize.
* Margins, padding, and alignment improve readability and visual hierarchy.
* Themes provide consistent colors and visual styling across an application.
* Templates offer pre-built dashboard structures with headers, sidebars, and responsive layouts.
* Custom CSS is available for advanced customization but is not required for most Panel applications.
* Good styling improves usability by making information easier to locate and understand.

Our SGX Stock Monitor is now conceptually complete from a user interface perspective. We understand how to display information, collect input, respond to user actions, organize components, and present them in a polished, professional layout.

---

# Exercises

## Exercise 1 — Fixed or Responsive?

For each of the following components, decide whether you would use a fixed size or a responsive sizing mode:

* Search button
* Dashboard title
* Stock price chart
* Company logo
* News table

Explain your reasoning.

---

## Exercise 2 — Design a Professional Dashboard

Sketch the layout of the SGX Stock Monitor using a template with:

* Header
* Sidebar
* Main content area

Label where each component belongs and explain why.

---

## Exercise 3 — Critique the Design

Suppose a dashboard uses:

* ten different colors
* inconsistent spacing
* multiple font styles
* no alignment
* no visual grouping

Discuss how these design choices affect usability and propose improvements based on the principles introduced in this lesson.

---

# Coming Up Next

In **Lesson 4.7 — Building the SGX Stock Monitor Interface: Bringing Everything Together**, we'll assemble everything we've learned in Part IV into our first complete Panel application. You'll create a professional dashboard using a Panel template, arrange widgets and panes into a responsive layout, wire the Search button to the `MarketDataService`, and display live SGX stock information. This lesson is a major milestone: it transforms our individual building blocks into a fully functional stock monitoring dashboard.
