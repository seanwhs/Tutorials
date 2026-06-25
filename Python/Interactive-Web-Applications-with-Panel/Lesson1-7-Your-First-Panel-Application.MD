# Part I — Foundations

# Lesson 1.7 — Your First Panel Application

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Write your first Panel application.
> * Understand every line of a basic Panel program.
> * Learn how to start the Panel server.
> * Understand what happens when a Panel application starts.
> * Understand the purpose of `pn.extension()`.
> * Learn how Panel converts Python code into a web application.
> * Build the first version of our SGX Stock Monitor.

---

# Introduction

Everything we've learned so far has been preparing us for this moment.

This is the first lesson where we'll actually build something.

Don't worry if the application seems very simple.

Professional software is **always** built incrementally.

Today we'll build this.

```text
+--------------------------------------+

SGX Stock Monitor

Welcome to Panel!

+--------------------------------------+
```

That's it.

No charts.

No buttons.

No stock prices.

No watchlists.

Just a title and some text.

Although it looks simple, this tiny application introduces nearly every concept that we'll build upon throughout the rest of this book.

---

# Before Writing Code

Let's create our first Python file.

Inside your project folder, create:

```text
sgx-stock-monitor/

├── .venv/

└── app.py
```

Our entire application will initially live inside this file.

Later, as our project grows, we'll reorganize it into multiple modules.

---

# Why Is It Called `app.py`?

There is nothing magical about the name.

You could call it:

```text
stocks.py
```

or

```text
dashboard.py
```

or

```text
main.py
```

However,

many Panel projects use

```text
app.py
```

because it clearly communicates:

> This file contains the application.

Throughout this tutorial we'll follow that convention.

---

# Writing Our First Program

Open

```text
app.py
```

and type:

```python
import panel as pn

pn.extension()

pn.pane.Markdown("# SGX Stock Monitor")
```

Congratulations.

You have written your first Panel application.

But...

we're not going to run it yet.

Instead,

we'll understand every line first.

---

# Line 1

```python
import panel as pn
```

Let's examine this carefully.

---

## What Is `import`?

Python itself is intentionally small.

Most useful functionality lives inside libraries.

If we want to use a library,

we first have to import it.

Think of a library as a toolbox.

Before using a hammer,

you must first open the toolbox.

```text
Python

↓

Import Panel

↓

Panel Functions Become Available
```

Without importing Panel,

Python has no idea what Panel is.

---

## What Is `panel`?

`panel` is the name of the library.

Remember:

We installed it earlier using

```bash
pip install panel
```

Now Python knows where that library is located.

---

## What Does `as pn` Mean?

This is one of Python's most common conventions.

Instead of writing

```python
panel.extension()
```

we create a shorter name.

```python
import panel as pn
```

Now we can write

```python
pn.extension()
```

instead.

Both are equivalent.

```python
panel.extension()
```

and

```python
pn.extension()
```

The second is simply shorter.

Nearly every Panel developer uses

```python
pn
```

as the alias.

---

# Teacher's Notes

> Python libraries often have widely accepted aliases.
>
> Examples include:
>
> ```python
> import numpy as np
> import pandas as pd
> import matplotlib.pyplot as plt
> import panel as pn
> ```
>
> Using these conventions makes your code easier for other Python developers to read.

---

# Line 2

```python
pn.extension()
```

This is arguably the most important line in every Panel application.

Let's understand why.

---

# What Is `extension()`?

Panel applications require certain resources before they can display anything.

These include:

* JavaScript files
* CSS styles
* browser resources
* communication components

Calling

```python
pn.extension()
```

initializes Panel.

Think of it as turning the engine on before driving a car.

```text
Without extension()

↓

Panel isn't initialized.

↓

Nothing appears correctly.

------------------------

With extension()

↓

Panel prepares itself.

↓

Application is ready.
```

---

# Why Must We Call It?

Imagine buying a new smartphone.

Before using it,

you press the power button.

The phone starts.

Memory is initialized.

Applications load.

The operating system starts.

Only then can you use it.

`pn.extension()` serves a similar purpose.

It prepares Panel for use.

---

# Does It Create the User Interface?

No.

This is another common misunderstanding.

It only prepares the environment.

The actual interface comes later.

---

# What Happens Internally?

Although we don't need to understand every detail,

Panel roughly performs the following steps.

```text
pn.extension()

↓

Load Panel Resources

↓

Load CSS

↓

Load JavaScript

↓

Initialize Communication

↓

Ready
```

Notice that no user interface exists yet.

---

# Line 3

```python
pn.pane.Markdown("# SGX Stock Monitor")
```

This line actually creates something.

Let's examine it piece by piece.

---

# What Is `pane`?

One of the biggest ideas in Panel is that

**everything displayed on the screen is an object.**

Some objects display:

* text
* images
* tables
* charts
* videos
* HTML

These display objects are called **Panes**.

Think of a Pane as a container that knows how to display a particular kind of content.

---

# Why Are They Called Panes?

Imagine hanging different objects on a wall.

You might hang:

* a painting
* a photograph
* a map
* a whiteboard

Each object is different,

but each occupies space on the wall.

A Pane behaves similarly.

It occupies space in the application.

---

# What Is a Markdown Pane?

Our Pane is specifically

```python
pn.pane.Markdown()
```

This Pane displays

Markdown.

---

# What Is Markdown?

Markdown is a lightweight language used for formatting text.

Examples:

```text
Heading

Paragraph

Bullet Lists

Bold

Italic

Tables

Links
```

Many websites use Markdown.

Examples include:

* GitHub
* Reddit
* Stack Overflow
* Documentation websites

Even this tutorial could be written in Markdown.

---

# Our Markdown

We passed

```python
"# SGX Stock Monitor"
```

into the Markdown Pane.

Notice the

```text
#
```

at the beginning.

In Markdown,

this means

> Heading Level 1

For example

```markdown
# SGX Stock Monitor
```

becomes

# SGX Stock Monitor

A single symbol changes ordinary text into a heading.

---

# What Is Happening Here?

Let's trace the execution.

```text
Python Starts

↓

Import Panel

↓

Initialize Panel

↓

Create Markdown Pane

↓

Display Heading
```

Although only three lines long,

quite a lot happens behind the scenes.

---

# Our Complete Program

```python
import panel as pn

pn.extension()

pn.pane.Markdown("# SGX Stock Monitor")
```

Everything in this program now has a purpose.

---

# Running the Application

Save

```text
app.py
```

Open a terminal inside the project folder.

Run:

```bash
panel serve app.py
```

Let's understand this command.

---

# What Is `panel`?

Earlier,

we used

```bash
pip
```

to install libraries.

Now,

we're using

```bash
panel
```

This is a command-line tool installed alongside the Panel library.

It allows us to:

* run applications
* start servers
* manage Panel projects

---

# What Does `serve` Mean?

Panel applications run on a web server.

The

```text
serve
```

command starts that server.

Conceptually:

```text
panel serve app.py

↓

Start Panel Server

↓

Run app.py

↓

Wait For Browser Connections
```

---

# What Is `app.py`?

This tells Panel

which Python file should become the application.

You can think of it as saying:

> "Run this file as a Panel application."

---

# What Happens Next?

After a few seconds,

you'll see output similar to:

```text
Starting Bokeh server...

Application running at:

http://localhost:5006/app
```

The exact wording may differ slightly depending on your Panel version.

---

# What Is `localhost`?

Many beginners find this mysterious.

Let's break it down.

```text
localhost
```

means

> This computer.

Not another computer.

Not the Internet.

Your own machine.

---

# What Is Port 5006?

A computer can run many network applications simultaneously.

Ports help distinguish between them.

Imagine an apartment building.

The address is:

```text
123 Main Street
```

But each apartment has its own number.

```text
Apartment 1

Apartment 2

Apartment 3
```

The street address identifies the building.

The apartment number identifies the specific resident.

Similarly:

```text
localhost
```

identifies your computer.

```text
5006
```

identifies the Panel application running on it.

---

# Opening the Application

Open your browser.

Navigate to:

```text
http://localhost:5006/app
```

You should see something like:

```text
+----------------------------------+

SGX Stock Monitor

+----------------------------------+
```

Congratulations!

You have built and run your first Panel application.

---

# How Does This Actually Work?

Let's connect everything we've learned.

```text
Terminal

↓

panel serve app.py

↓

Python Starts

↓

Imports Panel

↓

Initializes Panel

↓

Creates Markdown Pane

↓

Starts Web Server

↓

Browser Connects

↓

Heading Appears
```

Everything we've discussed over the previous lessons now comes together.

---

# Teacher's Notes

> Many beginners expect `app.py` to "draw" the interface directly onto the screen like a desktop application.
>
> That's not what happens.
>
> Your Python code creates a tree of Panel objects. The Panel server then translates those objects into a web page that your browser can display.
>
> This separation between your Python code and the browser is one of Panel's greatest strengths. It allows you to build rich interfaces without writing HTML or JavaScript directly.

---

# Common Mistakes

### ❌ Mistake 1

Forgetting to call:

```python
pn.extension()
```

Some features may not initialize correctly because Panel hasn't prepared the required resources.

---

### ❌ Mistake 2

Running:

```bash
python app.py
```

instead of

```bash
panel serve app.py
```

At this stage of the tutorial, we're building a Panel application, so we use the Panel server to run it.

---

### ❌ Mistake 3

Closing the terminal.

The terminal is running the Panel server.

If you close it,

your application stops.

---

### ❌ Mistake 4

Thinking the browser is running your Python code.

It isn't.

The Python code runs in the Panel server.

The browser displays the interface and communicates with the server behind the scenes.

---

# Summary

In this lesson, you learned:

* How to create your first Panel application.
* Why every Panel program begins with `import panel as pn`.
* The purpose of `pn.extension()` and why it initializes the framework.
* What a Pane is and how `Markdown` displays formatted text.
* How to run a Panel application using `panel serve`.
* What `localhost` and port `5006` represent.
* How the Panel server transforms Python objects into an interactive web application displayed in the browser.

Our SGX Stock Monitor currently displays only a title, but it is now a functioning web application. Every feature we add from this point onward will build upon this foundation.

---

## Exercises

### Exercise 1

Modify the Markdown heading so it displays your own title instead of **"SGX Stock Monitor."**

---

### Exercise 2

Experiment with different Markdown headings:

```markdown
# Heading 1
## Heading 2
### Heading 3
```

Observe how the appearance changes.

---

### Exercise 3

Stop the Panel server and restart it. Practice the complete workflow until you're comfortable with:

1. Activating the virtual environment.
2. Navigating to the project folder.
3. Running `panel serve app.py`.
4. Opening the application in your browser.

These are the commands you'll use throughout the remainder of this tutorial.

---

## Coming Up Next

In **Lesson 1.8 — Understanding Panel's Object Model**, we'll take a deeper look at what you've already created. You'll learn that **everything in Panel is an object**, explore the concept of `Viewable`, and begin to understand the architecture that makes widgets, panes, layouts, and templates all work together. This lesson lays the conceptual foundation for building increasingly sophisticated Panel applications.
