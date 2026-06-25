# Part I — Foundations

# Lesson 1.10 — Serving, Displaying, and Making Objects Visible

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand the difference between creating an object and displaying it.
> * Explain why writing an object name at the end of a Panel script displays it.
> * Understand how `panel serve` finds your application.
> * Learn what `.servable()` does.
> * Understand why `.servable()` is the preferred approach for real-world applications.
> * Learn the difference between notebooks and standalone Panel applications.
> * Prepare your project for future expansion.

---

# Introduction

So far, our application looks like this.

```python
import panel as pn

pn.extension()

dashboard = pn.Column(
    pn.pane.Markdown("# SGX Stock Monitor"),
    pn.pane.Markdown("Welcome!")
)

dashboard
```

Notice the final line.

```python
dashboard
```

It seems almost magical.

There is no

```python
display(dashboard)
```

There is no

```python
show(dashboard)
```

There isn't even a

```python
print(dashboard)
```

Yet somehow...

the dashboard appears in the browser.

Why?

This lesson answers that question.

---

# Creating an Object Is NOT Displaying It

This is one of the biggest misunderstandings beginners have.

Consider this code.

```python
button = pn.widgets.Button(name="Refresh")
```

What happened?

Many beginners think:

> "The button appeared."

Actually...

Nothing appeared.

We simply created an object.

---

Imagine buying a television.

After purchasing it,

where is it?

Probably still inside the box.

Buying the television

doesn't automatically place it inside your living room.

Similarly,

creating a Panel object

doesn't automatically display it.

---

# Creating Objects

Suppose we write:

```python
chart = pn.pane.Markdown("Chart")
```

Panel creates an object.

Conceptually:

```text
Python

↓

Create Object

↓

Store In Memory
```

Notice what is missing.

Nothing is displayed.

---

# Displaying Objects

To display something,

Panel must know

which object should become the application.

Conceptually:

```text
Create Object

↓

Choose Object

↓

Display Object
```

These are two different steps.

---

# Why Does Writing the Variable Work?

Let's revisit our example.

```python
dashboard
```

This looks strange.

It's just a variable name.

Why does it work?

The answer depends on **where the code is running.**

---

# Interactive Python

Suppose you start Python.

```bash
python
```

You type:

```python
2 + 2
```

Python immediately responds.

```text
4
```

Why?

Because interactive Python automatically displays

the value of the last expression.

---

The same thing happens here.

```python
dashboard
```

The object becomes

the final expression.

Interactive environments automatically display it.

---

# Jupyter Notebook Behavior

Inside a notebook,

this works beautifully.

```python
dashboard
```

The notebook automatically renders the object.

You don't need anything else.

---

Conceptually:

```text
Notebook

↓

Last Expression

↓

Display Automatically
```

---

# But We're Not Using a Notebook

We're building a standalone application.

We run

```bash
panel serve app.py
```

not

```text
Jupyter Notebook
```

So how does Panel know what to display?

---

# What Happens During `panel serve`

Let's follow the entire process.

```text
panel serve app.py

↓

Start Panel Server

↓

Execute app.py

↓

Look For Displayable Objects

↓

Serve Application

↓

Browser Connects
```

Panel examines the script.

It needs to determine

which object represents the application.

---

# A Small Problem

Suppose our application becomes larger.

```python
title = pn.pane.Markdown(...)

search = pn.widgets.TextInput(...)

chart = pn.pane.Markdown(...)

table = pn.pane.Markdown(...)

dashboard = pn.Column(...)
```

Which object should Panel display?

There are many objects.

Should it display:

* title?
* chart?
* search?
* table?
* dashboard?

How can Panel know?

---

# Enter `.servable()`

Panel provides a very clear answer.

```python
dashboard.servable()
```

This explicitly tells Panel:

> **This is the object that should become the application.**

No guessing.

No ambiguity.

---

# Updating Our Application

Instead of

```python
dashboard
```

write

```python
dashboard.servable()
```

Our application now becomes:

```python
import panel as pn

pn.extension()

dashboard = pn.Column(
    pn.pane.Markdown("# SGX Stock Monitor"),
    pn.pane.Markdown("Welcome!")
)

dashboard.servable()
```

This is the style we'll use throughout the rest of this tutorial.

---

# Understanding `.servable()`

Let's examine it.

```python
dashboard.servable()
```

Remember.

`dashboard`

is an object.

Objects have methods.

`.servable()`

is one of those methods.

---

Conceptually:

```text
Dashboard Object

↓

servable()

↓

Register As Application

↓

Panel Displays It
```

---

# What Does "Register" Mean?

Imagine organizing a conference.

Many people arrive.

But only some are speakers.

How do organizers know?

Each speaker registers.

Only registered speakers appear in the schedule.

`.servable()`

works similarly.

Many objects may exist.

Only registered objects become applications.

---

# Why Is This Better?

Imagine a large application.

```python
title

sidebar

chart

news

watchlist

portfolio

footer

dashboard
```

Without `.servable()`

Panel must guess.

With

```python
dashboard.servable()
```

there is no confusion.

---

# Can We Have Multiple Servable Objects?

Yes.

For example:

```python
dashboard.servable()

settings.servable()
```

Each becomes a separate view.

Later,

we'll explore multi-page applications.

For now,

our application only needs one.

---

# `servable()` Does NOT Display Immediately

Another common misunderstanding.

Many beginners think

```python
dashboard.servable()
```

immediately opens a browser.

It doesn't.

Instead,

it registers the object.

The browser displays it later,

when someone connects.

---

Conceptually:

```text
Create Dashboard

↓

Register Dashboard

↓

Start Server

↓

Browser Connects

↓

Display Dashboard
```

---

# The Life Cycle of a Panel Application

Let's connect everything we've learned.

```text
Run

panel serve app.py

↓

Python Starts

↓

Import Panel

↓

Initialize Panel

↓

Create Objects

↓

Register Dashboard

↓

Start Web Server

↓

Browser Connects

↓

Render Dashboard

↓

Wait For User Interaction
```

Notice how many steps happen before anything appears.

---

# Why Not Use `print()`?

Some beginners try this.

```python
print(dashboard)
```

What happens?

You won't see the dashboard.

Instead,

you'll see something like:

```text
Column(...)
```

Why?

Because `print()` displays the **text representation**

of the object.

Not the object itself.

---

Think about a car.

```text
Toyota Corolla
```

isn't the car.

It's only the name.

Similarly,

```text
Column(...)
```

is only Python describing the object.

The browser still needs Panel to render it.

---

# Notebook vs Panel Server

This distinction is very important.

| Jupyter Notebook                           | Panel Server                                   |
| ------------------------------------------ | ---------------------------------------------- |
| Displays the last expression automatically | Displays objects registered with `.servable()` |
| Interactive exploration                    | Full web application                           |
| Ideal for experimentation                  | Ideal for deployment                           |
| One notebook cell at a time                | Entire application                             |

Throughout this tutorial,

we're building a **Panel Server application**.

---

# Best Practice

From now on,

every application we build will follow this pattern.

```python
import panel as pn

pn.extension()

# Create objects

...

# Build layouts

...

# Register application

dashboard.servable()
```

Professional Panel projects almost always use this structure.

It scales well as applications become larger.

---

# Looking Ahead

As our SGX Stock Monitor grows,

our code will eventually look something like this.

```python
title = ...

search = ...

chart = ...

news = ...

portfolio = ...

sidebar = ...

main = ...

dashboard = ...

dashboard.servable()
```

Everything builds toward one final application object.

---

# Teacher's Notes

> One of the strengths of Panel is that the same objects can be displayed in different environments.
>
> During experimentation, you might display a layout directly in a Jupyter notebook by making it the last expression in a cell.
>
> For production applications, however, `.servable()` is preferred because it explicitly identifies the application's entry point. This makes your code easier to understand, easier to maintain, and less dependent on the execution environment.

---

# Common Mistakes

### ❌ Mistake 1

Assuming creating an object automatically displays it.

Creating and displaying are separate operations.

---

### ❌ Mistake 2

Using `print()` to display a Panel object.

`print()` shows the object's text representation, not its rendered interface.

---

### ❌ Mistake 3

Forgetting to call `.servable()` in larger applications.

While simple examples may work without it in some contexts, explicitly registering your application is clearer and more maintainable.

---

### ❌ Mistake 4

Confusing notebook behavior with Panel server behavior.

Notebooks automatically display the last expression in a cell. Panel server applications rely on registered servable objects.

---

# Summary

In this lesson, you learned:

* Creating a Panel object and displaying it are two separate operations.
* Interactive environments like Jupyter automatically render the last expression.
* `panel serve` executes your Python script and serves registered Panel objects.
* `.servable()` explicitly marks an object as part of the web application.
* Using `.servable()` removes ambiguity and is considered a best practice for standalone Panel applications.
* The Panel server renders your application only after a browser connects.

You now understand the complete journey from writing Python objects to seeing a live web application in your browser.

---

# Exercises

## Exercise 1 — Replace the Final Line

Modify your current application by replacing:

```python
dashboard
```

with:

```python
dashboard.servable()
```

Run the application again.

Does it still behave as expected?

---

## Exercise 2 — Multiple Objects

Create several Panel objects:

* A title
* A button
* A Markdown pane

Then combine them into a single `pn.Column()` named `dashboard`.

Register only the `dashboard` object using `.servable()`.

Think about why registering the individual components would not be the best design.

---

## Exercise 3 — Explain the Lifecycle

Without looking back at the lesson, write down the sequence of events that occurs after running:

```bash
panel serve app.py
```

Try to include:

* Python starting
* Object creation
* Registration
* The server
* The browser
* Rendering

---

## Coming Up Next

In **Lesson 1.11 — Planning the SGX Stock Monitor**, we'll step back from individual Panel components and begin designing our application as software engineers. We'll identify the features we want to build, break the application into reusable modules, discuss separation of concerns, and design the architecture that will guide the rest of this multipart tutorial. Before writing more code, we'll learn an important engineering principle:

> **Good software is designed before it is implemented.**
