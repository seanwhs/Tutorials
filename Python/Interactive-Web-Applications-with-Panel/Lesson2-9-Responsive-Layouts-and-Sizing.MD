# Part II — Widgets: Building Interactive User Interfaces

# Lesson 2.9 — Responsive Layouts and Sizing

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand responsive web design.
> * Learn why responsive layouts are important.
> * Master Panel's sizing system.
> * Understand `width`, `height`, `min_width`, and `max_width`.
> * Learn Panel's `sizing_mode` options.
> * Build layouts that adapt to different screen sizes.
> * Create a responsive SGX Stock Monitor dashboard.

---

# Introduction

In the previous lesson, we learned how to organize our application using layouts.

Our dashboard now looks something like this.

```text
------------------------------------------------

SGX Stock Monitor

------------------------------------------------

__________________________   [ Search ]



No search performed.

------------------------------------------------
```

Everything is neatly arranged.

But there's a new problem.

What happens if someone opens the application on:

* a laptop?
* a large monitor?
* a tablet?
* a mobile phone?

Will everything still fit nicely?

Not necessarily.

Today's lesson is about making our application adapt to different screen sizes.

This is called **responsive design**.

---

# What Is Responsive Design?

Responsive design means that an application's layout automatically adjusts to fit the available screen space.

Instead of creating separate applications for:

* Desktop
* Tablet
* Mobile

we create **one application** that adapts itself.

---

# Why Is Responsive Design Important?

Imagine designing a webpage that is exactly

```text
1200 pixels
```

wide.

It might look great on your desktop.

Now imagine viewing it on a phone.

```text
Desktop

--------------------------------------------------
|                                                |
|                 Application                    |
|                                                |
--------------------------------------------------

↓

Phone

-------------
|Applicati...|
-------------
```

Parts of the interface disappear.

Users must scroll horizontally.

Buttons become difficult to press.

The application becomes frustrating to use.

---

# Modern Web Applications Are Responsive

Think about websites you use every day.

YouTube

Facebook

Google

GitHub

Amazon

They all adjust automatically depending on your screen size.

Panel applications should do the same.

---

# Fixed Size vs Responsive Size

There are two broad approaches.

## Fixed Size

```python
width = 600
```

The component is always

600 pixels wide.

No more.

No less.

---

## Responsive Size

```python
sizing_mode="stretch_width"
```

The component expands or shrinks depending on available space.

---

# Understanding Pixels

Most widget sizes are measured in

**pixels**.

A pixel is the smallest unit displayed on a screen.

For example,

```python
width = 300
```

means

```text
□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□
300 pixels
□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□□
```

---

# Setting Width

Every widget supports

```python
width
```

Example

```python
search = pn.widgets.TextInput(

    name="Stock Symbol",

    width=300

)
```

The widget will always remain

300 pixels wide.

---

# Setting Height

Likewise,

```python
height
```

controls vertical size.

```python
button = pn.widgets.Button(

    name="Search",

    height=60

)
```

Large buttons are often easier to click.

---

# Minimum Width

Sometimes,

we don't want widgets becoming too small.

Panel provides

```python
min_width
```

Example

```python
search.min_width = 250
```

Even if the browser becomes tiny,

the widget won't shrink below

250 pixels.

---

# Maximum Width

Similarly,

```python
max_width
```

prevents widgets becoming excessively large.

```python
results.max_width = 800
```

Useful when displaying text.

Very long lines become difficult to read.

---

# Why Width Constraints Matter

Imagine a

40-inch monitor.

Without constraints,

your search box might become

1500 pixels wide.

```text
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________
```

Typing into such a textbox would feel awkward.

Setting

```python
max_width
```

keeps the interface comfortable.

---

# Enter `sizing_mode`

Panel's most powerful sizing feature is

```python
sizing_mode
```

Instead of specifying exact pixel sizes,

we describe how components should behave.

---

# Common Sizing Modes

The most useful options are:

| Mode               | Behaviour                               |
| ------------------ | --------------------------------------- |
| `"fixed"`          | Fixed size                              |
| `"stretch_width"`  | Expand horizontally                     |
| `"stretch_height"` | Expand vertically                       |
| `"stretch_both"`   | Expand in both directions               |
| `"scale_width"`    | Scale while maintaining proportions     |
| `"scale_both"`     | Scale proportionally in both directions |

We'll use the first four most frequently.

---

# Fixed Mode

```python
pn.widgets.TextInput(

    width=300,

    sizing_mode="fixed"

)
```

The widget always remains

300 pixels.

Useful for small controls.

---

# Stretch Width

This is probably the most commonly used mode.

```python
search = pn.widgets.TextInput(

    sizing_mode="stretch_width"

)
```

Now,

the widget automatically fills the available horizontal space.

```text
Large Screen

____________________________________________

Small Screen

____________________
```

No code changes required.

---

# Stretch Height

Less common,

but useful for

large tables,

text areas,

or charts.

```python
pn.pane.Markdown(

    sizing_mode="stretch_height"

)
```

---

# Stretch Both

```python
sizing_mode="stretch_both"
```

Allows the component to expand

both horizontally

and vertically.

Often used for:

* charts
* maps
* dashboards

---

# Applying Sizing to Layouts

Layouts also support

```python
sizing_mode
```

Example

```python
dashboard = pn.Column(

    title,

    controls,

    results,

    sizing_mode="stretch_width"

)
```

Now,

the entire dashboard adapts to browser size.

---

# Responsive Search Controls

Let's improve our application.

```python
controls = pn.Row(

    search,

    button,

    sizing_mode="stretch_width"

)
```

Now,

the search box expands,

while the button keeps a reasonable size.

---

# Updating the Widgets

```python
search = pn.widgets.TextInput(

    placeholder="Example: DBS",

    sizing_mode="stretch_width"

)
```

```python
button = pn.widgets.Button(

    name="Search",

    width=120
)
```

Notice the design.

The search box grows.

The button stays fixed.

This creates a pleasant interface.

---

# Building a Responsive Dashboard

```python
import panel as pn

pn.extension()

title = pn.pane.Markdown("# SGX Stock Monitor")

search = pn.widgets.TextInput(

    placeholder="Example: DBS",

    sizing_mode="stretch_width"

)

button = pn.widgets.Button(

    name="Search",

    button_type="primary",

    width=120

)

results = pn.pane.Markdown(

    "No search performed.",

    sizing_mode="stretch_width"

)

controls = pn.Row(

    search,

    button,

    sizing_mode="stretch_width"

)

dashboard = pn.Column(

    title,

    pn.layout.Divider(),

    controls,

    pn.Spacer(height=20),

    results,

    sizing_mode="stretch_width"

)

dashboard.servable()
```

---

# What Happens When the Browser Changes Size?

Imagine resizing the browser window.

Large screen

```text
___________________________________________________________

Search Box____________________________________ [ Search ]
```

Medium screen

```text
_____________________________________

Search Box__________________ [ Search ]
```

Small screen

```text
________________________

Search Box_______ [ Search ]
```

The interface automatically adjusts.

---

# Choosing Fixed vs Responsive

A useful guideline is:

| Component    | Recommended   |
| ------------ | ------------- |
| Buttons      | Fixed Width   |
| Search Boxes | Stretch Width |
| Tables       | Stretch Width |
| Charts       | Stretch Both  |
| Images       | Scale Width   |
| Dashboard    | Stretch Width |

These aren't strict rules,

but they're good starting points.

---

# Responsive Thinking

Instead of asking

> "How wide should this widget be?"

Professional developers ask

> "How should this widget behave if the browser changes size?"

That's a very different mindset.

---

# Responsive Dashboards

Our future SGX dashboard might contain:

```text
----------------------------------------------------

Header

----------------------------------------------------

Search___________________________ [Search]

----------------------------------------------------

Price Chart

██████████████████████████████████

----------------------------------------------------

Market Statistics

----------------------------------------------------
```

As the browser grows,

every section grows naturally.

---

# Layout + Responsive Design

Notice how today's lesson builds upon the previous one.

Last lesson

```text
Where should components go?
```

Today's lesson

```text
How should components resize?
```

Together,

layouts

and

responsive sizing

create professional interfaces.

---

# Performance Considerations

Responsive layouts are generally inexpensive.

However,

very large dashboards containing:

* hundreds of widgets
* dozens of charts
* massive tables

may require careful layout planning.

Fortunately,

our SGX dashboard is still relatively simple.

---

# Teacher's Notes

> One of the biggest differences between desktop GUI development and web development is that web pages are expected to adapt to different devices. Avoid hard-coding widths unless there is a clear reason to do so.
>
> In most dashboards, a combination of fixed-size buttons and stretchable content areas produces an interface that feels both stable and flexible. As your applications become more sophisticated, responsive design should become your default approach rather than an afterthought.

---

# Common Mistakes

## ❌ Mistake 1

Giving every widget a fixed width.

The interface may look fine on your computer but break on smaller screens.

---

## ❌ Mistake 2

Allowing buttons to stretch across the entire page.

Buttons usually work better with a fixed width.

---

## ❌ Mistake 3

Ignoring `min_width`.

Some widgets become unusable if they shrink too much.

Use sensible minimum sizes.

---

## ❌ Mistake 4

Using pixel values everywhere.

Whenever appropriate,

let Panel manage sizing automatically using `sizing_mode`.

---

# Summary

In this lesson, you learned:

* Responsive applications automatically adapt to different screen sizes.
* Widgets support properties such as `width`, `height`, `min_width`, and `max_width`.
* `sizing_mode` controls how components resize within available space.
* Common sizing modes include `"fixed"`, `"stretch_width"`, `"stretch_height"`, and `"stretch_both"`.
* Responsive layouts provide a better experience across desktops, laptops, tablets, and other devices.
* Combining good layouts with responsive sizing results in professional-looking applications.

Our SGX Stock Monitor is now becoming both **functional** and **responsive**. It can accept user input, display results, organize components into logical sections, and adapt gracefully to different screen sizes.

---

# Exercises

## Exercise 1 — Compare Fixed and Responsive

Create two `TextInput` widgets:

* One using:

```python
width=300
```

* One using:

```python
sizing_mode="stretch_width"
```

Resize your browser and observe the difference.

---

## Exercise 2 — Improve Your Dashboard

Update your SGX dashboard so that:

* The search box stretches horizontally.
* The Search button remains fixed.
* The entire dashboard stretches to fill the browser width.

Test the layout by resizing your browser window.

---

## Exercise 3 — Design a Responsive Stock Dashboard

Sketch a dashboard containing:

* Search controls
* Company information
* Price chart
* News section
* Watchlist

For each section, decide whether it should use:

* Fixed sizing
* Stretch width
* Stretch height
* Stretch both

Explain your choices.

---

# Coming Up Next

In **Lesson 2.10 — Templates: Building Professional Dashboards**, we'll introduce one of Panel's most powerful features: **Templates**. Instead of manually arranging every element on the page, you'll learn how Panel provides complete application layouts with built-in headers, sidebars, navigation areas, and responsive styling. We'll migrate our SGX Stock Monitor into a professional dashboard template, making it look much closer to a real financial web application. This lesson marks the transition from building individual interfaces to building polished, production-style applications.
