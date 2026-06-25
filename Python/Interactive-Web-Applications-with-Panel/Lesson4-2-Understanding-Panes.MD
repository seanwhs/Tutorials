# Part IV — Building the Panel User Interface

# Lesson 4.2 — Understanding Panes: Displaying Information in Panel

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what a Panel Pane is.
> * Learn why panes exist.
> * Understand how Panel displays Python objects.
> * Learn the difference between automatic and explicit panes.
> * Explore the most common pane types.
> * Display text, Markdown, HTML, images, DataFrames, and charts.
> * Learn how panes fit into the overall architecture of Panel.
> * Understand when to use each pane.
> * Build the foundation for displaying SGX market information.

---

# Introduction

In our previous lesson,

we built our first Panel application.

```python
import panel as pn

pn.extension()

pn.panel("Hello, Panel!").servable()
```

Although it was simple,

something important happened.

We created our first **Pane**.

You may not have realized it,

because Panel created it automatically.

Today's lesson explores one of the most important concepts in the entire Panel framework.

> **Everything displayed on the screen is displayed through a Pane.**

Understanding panes is essential before learning layouts, widgets, or dashboards.

---

# What Is a Pane?

A **Pane** is a Panel object whose primary job is

> **displaying something.**

Think of a pane as a translator.

It takes an ordinary Python object

and converts it into something a web browser can display.

---

# Thinking About Translation

Python understands objects like

```python
"Hello"
```

or

```python
df
```

or

```python
plt.figure(...)
```

A web browser doesn't.

Browsers understand

* HTML
* CSS
* JavaScript

Panel acts as the translator.

```text
Python Object

↓

Panel Pane

↓

HTML

↓

Browser
```

Without panes,

the browser wouldn't know how to display Python objects.

---

# Why Doesn't Python Display Everything Automatically?

Suppose we create

```python
price = 41.35
```

Python knows

this is a floating-point number.

But how should it appear on a webpage?

Should it be

```text
41.35
```

or

```text
$41.35
```

or

a large heading?

Python doesn't know.

Panel panes solve this problem.

---

# Every Dashboard Is Built from Panes

Consider a stock dashboard.

```text
+------------------------------------+

DBS Group Holdings

Price: $41.35

Volume: 3,250,000

Chart

News

+------------------------------------+
```

Everything you see is actually displayed using panes.

---

# The Simplest Pane

Earlier,

we wrote

```python
pn.panel("Hello Panel!")
```

This automatically creates a pane.

Internally,

Panel notices

```python
"Hello Panel!"
```

is text.

It automatically chooses the appropriate pane.

---

# Automatic Pane Selection

One of Panel's nicest features is

automatic pane selection.

Suppose we write

```python
pn.panel("Hello")
```

Panel automatically chooses

```text
Markdown Pane
```

If we pass

```python
df
```

Panel automatically chooses

```text
DataFrame Pane
```

If we pass

a Plotly figure,

Panel chooses

the appropriate Plotly pane.

---

# Visualizing Automatic Selection

```text
Python Object

↓

Panel inspects object

↓

Chooses appropriate Pane

↓

Displays object
```

Most of the time,

you don't need to think about this.

Panel does the work for you.

---

# Common Pane Types

Panel includes many pane classes.

Some of the most common are:

| Pane         | Displays           |
| ------------ | ------------------ |
| `Markdown`   | Markdown text      |
| `HTML`       | HTML               |
| `Str`        | Plain text         |
| `DataFrame`  | Pandas DataFrames  |
| `Image`      | Images             |
| `Plotly`     | Plotly figures     |
| `Matplotlib` | Matplotlib figures |
| `Bokeh`      | Bokeh plots        |
| `JSON`       | JSON data          |

There are many more,

but these cover most applications.

---

# Why So Many Pane Types?

Different Python objects require different rendering techniques.

For example,

displaying

```python
"This is text"
```

is very different from displaying

```python
DataFrame
```

or

```python
PNG Image
```

Each pane specializes in rendering one category of object.

---

# The Markdown Pane

One of the most useful panes is

```python
pn.pane.Markdown()
```

Example

```python
pn.pane.Markdown("""

# SGX Dashboard

Monitor Singapore stocks.

""")
```

This displays formatted Markdown.

---

# Why Markdown?

Markdown lets us write

* headings
* bullet lists
* tables
* bold text
* italic text
* hyperlinks

without writing HTML.

This makes it ideal for dashboards.

---

# Markdown vs Plain Text

Consider these two examples.

Plain text

```text
# SGX Dashboard
```

Markdown

```markdown
# SGX Dashboard
```

The browser displays them differently.

Markdown interprets formatting.

Plain text does not.

---

# The String Pane

Sometimes,

we simply want to display text exactly as written.

Panel provides

```python
pn.pane.Str()
```

Unlike Markdown,

it doesn't interpret formatting symbols.

Everything is displayed literally.

---

# The HTML Pane

Sometimes Markdown isn't enough.

We may want complete control over formatting.

Panel provides

```python
pn.pane.HTML()
```

Example

```python
pn.pane.HTML(
    "<h2>SGX Dashboard</h2>"
)
```

This displays HTML directly.

---

# Should Beginners Use HTML?

Usually,

no.

Markdown is:

* easier
* safer
* cleaner

Most dashboards can be built entirely with Markdown.

Use HTML only when necessary.

---

# Displaying DataFrames

Our stock monitor will eventually retrieve market data.

Suppose we have

```python
df
```

where

`df`

is a Pandas DataFrame.

Displaying it is as simple as

```python
pn.panel(df)
```

or

```python
pn.pane.DataFrame(df)
```

Panel automatically creates an interactive table.

No HTML tables required.

---

# Why This Is Powerful

Imagine building a webpage manually.

You would need to generate

```html
<table>

<tr>

<td>

...

```

Panel does all of this automatically.

This saves hundreds of lines of code.

---

# Displaying Images

Suppose we have a company logo.

Panel can display images using

```python
pn.pane.Image(...)
```

Supported formats include:

* PNG
* JPEG
* GIF
* SVG

Later,

our dashboard may display company logos alongside stock information.

---

# Displaying Charts

Panel works beautifully with visualization libraries.

Examples include:

* Matplotlib
* Plotly
* Bokeh
* Altair

You create the chart exactly as usual.

Panel displays it.

This is one reason Panel is popular among data scientists.

---

# Understanding Explicit Panes

Earlier,

we wrote

```python
pn.panel(df)
```

This is called

**automatic pane selection**.

Sometimes,

however,

we want to choose the pane ourselves.

Example

```python
pn.pane.Markdown(...)
```

This is called an

**explicit pane**.

---

# Automatic vs Explicit

Automatic

```python
pn.panel(object)
```

Panel chooses.

---

Explicit

```python
pn.pane.Markdown(...)

pn.pane.HTML(...)

pn.pane.DataFrame(...)
```

You choose.

---

# Which Should You Use?

For beginners,

automatic panes are usually sufficient.

As your applications become larger,

explicit panes provide greater control.

Professional applications often mix both approaches.

---

# Panes Are Display Components

Notice something important.

Panes only display information.

They do **not**:

* accept user input
* respond to button clicks
* collect text

Those jobs belong to another Panel concept:

**Widgets**

We'll learn about widgets in the next lessons.

---

# Panes in Our SGX Dashboard

Soon,

our dashboard might look like this.

```text
+--------------------------------------+

Markdown Pane

↓

"DBS Group Holdings"

---------------------------------------

String Pane

↓

Price: SGD 41.35

---------------------------------------

DataFrame Pane

↓

Recent Transactions

---------------------------------------

Plotly Pane

↓

Price Chart

+--------------------------------------+
```

Each section is a different pane.

---

# The Architecture of a Panel Application

We can now extend our understanding.

```text
Python Objects

↓

Panes

↓

Layouts

↓

Panel Dashboard

↓

Browser
```

Notice the hierarchy.

Panes are one of the fundamental building blocks.

---

# Thinking Like a Panel Developer

When building a dashboard,

ask yourself:

> "What kind of object am I displaying?"

If it's:

* text → Markdown or String
* table → DataFrame
* chart → Plotly
* image → Image

Choosing the correct pane keeps your code clean and readable.

---

# Teacher's Notes

> Beginners often think of Panel as a collection of widgets, but panes are equally important. In fact, most dashboards display far more information than they collect from users. Panes provide a consistent mechanism for rendering almost any Python object, allowing developers to focus on their data rather than the underlying HTML and JavaScript.
>
> It's also useful to distinguish between **data objects** and **display objects**. A Pandas DataFrame stores data. A `DataFrame` pane knows how to display that data in a browser. Keeping this distinction clear will make the rest of the tutorial much easier to understand.

---

# Common Mistakes

## ❌ Mistake 1

Thinking `pn.panel()` only displays text.

It can display many different Python objects.

---

## ❌ Mistake 2

Using HTML when Markdown is sufficient.

Markdown is usually simpler and easier to maintain.

---

## ❌ Mistake 3

Confusing panes with widgets.

Panes display information.

Widgets collect user input.

---

## ❌ Mistake 4

Assuming every object needs its own display code.

Panel automatically selects an appropriate pane for many common object types.

---

## ❌ Mistake 5

Believing panes contain application logic.

Panes are responsible only for presentation.

Business logic belongs elsewhere.

---

# Summary

In this lesson, you learned:

* A **Pane** is responsible for displaying Python objects in a web browser.
* Panel automatically selects an appropriate pane for many common object types.
* Explicit panes provide greater control over rendering.
* Common pane types include Markdown, HTML, String, DataFrame, Image, and various chart panes.
* Markdown is usually the preferred way to display formatted text.
* DataFrames and charts can be displayed with minimal code.
* Panes focus solely on presentation and do not handle user input.
* Panes form one of the core building blocks of every Panel application.

Our SGX Stock Monitor can now display information. The next step is allowing users to interact with the application.

---

# Exercises

## Exercise 1 — Classify the Pane

For each of the following, identify the most appropriate Panel pane:

* A company description
* A stock price chart
* A Pandas DataFrame of recent trades
* A company logo
* A JSON response from an API
* A formatted dashboard title

Explain your choices.

---

## Exercise 2 — Automatic or Explicit?

Determine whether you would use:

```python
pn.panel(...)
```

or a specific pane class for each scenario.

Discuss the advantages and disadvantages of each approach.

---

## Exercise 3 — Architecture Review

Complete the following diagram by explaining the responsibility of each layer:

```text
Python Objects

↓

Panes

↓

Layouts

↓

Browser
```

Why is each layer necessary?

---

# Coming Up Next

In **Lesson 4.3 — Understanding Widgets: Collecting User Input**, we'll explore the second major building block of Panel applications: **widgets**. You'll learn how users interact with dashboards through text boxes, buttons, dropdowns, sliders, checkboxes, and selectors. We'll explain the purpose of each widget, how widgets store values, how to read user input from Python code, and begin building the interactive controls for our SGX Stock Monitor.
