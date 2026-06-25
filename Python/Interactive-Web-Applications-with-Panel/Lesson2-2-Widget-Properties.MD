# Part II — Widgets: Building Interactive User Interfaces

# Lesson 2.2 — Understanding Widget Properties

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what a property is.
> * Learn how widgets store information.
> * Understand the most important widget properties.
> * Read and modify widget properties.
> * Understand widget state.
> * Learn why properties are the foundation of interactive applications.
> * Build a richer SGX Stock Monitor interface using widget properties.

---

# Introduction

In the previous lesson, we built our first interactive widget.

```python
search = pn.widgets.TextInput(
    name="Search Stock",
    placeholder="Enter SGX stock symbol"
)
```

It looked something like this.

```text
----------------------------------------

Search Stock

Enter SGX stock symbol

----------------------------------------
```

It looked simple.

But behind this simple textbox is a surprisingly sophisticated Python object.

Just like every object you've learned about previously,

widgets contain information.

That information is stored inside **properties**.

Understanding properties is one of the most important skills in Panel.

Nearly every interactive application is built by reading and changing widget properties.

---

# Revisiting Objects

Earlier we learned that objects have two things:

* Properties
* Methods

Let's review.

Imagine a real car.

Its properties include:

```text
Colour

Speed

Fuel Level

Engine Status

Number of Doors
```

Its methods include:

```text
Start Engine()

Stop Engine()

Accelerate()

Brake()

Turn()
```

Properties describe an object.

Methods perform actions.

Widgets work exactly the same way.

---

# Widget Properties

A TextInput widget contains many properties.

For example:

```text
TextInput

├── name

├── value

├── placeholder

├── disabled

├── visible

├── width

├── height

└── styles
```

Each property stores one piece of information.

---

# What Is a Property?

A property is simply a value stored inside an object.

Think of a filing cabinet.

Each drawer stores one type of information.

```text
Widget

↓

Drawer

↓

Property

↓

Value
```

For example:

```text
Name

↓

Search Stock
```

or

```text
Placeholder

↓

Enter SGX stock symbol
```

The widget remembers these values.

---

# Creating a Widget

Let's create one.

```python
import panel as pn

pn.extension()

search = pn.widgets.TextInput(
    name="Search Stock",
    placeholder="Enter SGX stock symbol"
)
```

Now let's explore what the widget contains.

---

# Property 1 — `name`

The first property is

```python
name
```

This is the label displayed above the widget.

```python
search.name
```

returns

```text
Search Stock
```

---

# What Does `search.name` Mean?

This syntax appears throughout Python.

```python
object.property
```

It means:

> "Retrieve the value stored in this property."

Here,

```python
search
```

is the object.

```python
name
```

is the property.

Together they become

```python
search.name
```

---

Think of it like a person's name.

```text
Person

↓

Name

↓

Alice
```

Similarly,

```text
Search Widget

↓

Name

↓

Search Stock
```

---

# Property 2 — `placeholder`

We also created this property.

```python
placeholder
```

We assigned:

```python
placeholder="Enter SGX stock symbol"
```

Later,

we can retrieve it.

```python
search.placeholder
```

Result:

```text
Enter SGX stock symbol
```

The widget remembers everything we gave it.

---

# Property 3 — `value`

This is perhaps the most important property of every widget.

Initially,

our widget looks like this.

```text
Search Stock

__________________
```

Nothing has been typed.

What is its value?

```python
search.value
```

The answer is:

```text
```

An empty string.

No text has been entered yet.

---

# What Happens When the User Types?

Suppose the user enters

```text
DBS
```

The widget changes internally.

```text
Widget

↓

Value

↓

DBS
```

Now

```python
search.value
```

returns

```text
DBS
```

The widget always remembers the current user input.

---

# Visualizing `value`

Imagine a storage box.

Initially,

it's empty.

```text
Value

↓

(empty)
```

The user types

```text
UOB
```

The storage box now becomes

```text
Value

↓

UOB
```

Nothing magical happened.

The widget simply updated one of its properties.

---

# Why Is `value` So Important?

Think about our future application.

The user searches for:

```text
DBS
```

How does the application know what they typed?

It doesn't read the screen.

Instead,

it asks the widget.

```python
search.value
```

The widget replies:

```text
DBS
```

Almost every interactive Panel application depends on reading widget values.

---

# Property 4 — `disabled`

Sometimes,

we don't want users to interact with a widget.

For example,

while data is loading.

Panel provides

```python
disabled
```

Example:

```python
search = pn.widgets.TextInput(
    name="Search Stock",
    disabled=True
)
```

The textbox now appears greyed out.

Users cannot type into it.

---

Later,

we can enable it again.

```python
search.disabled = False
```

The widget immediately becomes usable again.

---

# Understanding Assignment

Notice this syntax.

```python
search.disabled = False
```

We're changing a property.

Earlier we read properties.

```python
search.name
```

Now we're writing to one.

This is ordinary Python assignment.

```python
object.property = value
```

---

# Property 5 — `visible`

Sometimes,

we don't want to remove a widget.

We simply want to hide it.

```python
search.visible = False
```

The widget disappears.

Later,

we can show it again.

```python
search.visible = True
```

This is much faster than destroying and recreating widgets.

---

# Property 6 — `width`

Widgets have sizes.

Example:

```python
search.width = 400
```

The textbox becomes wider.

Likewise,

```python
search.height = 60
```

changes its height.

Panel gives us fine-grained control over appearance.

---

# Reading vs Writing Properties

There are two common operations.

Reading

```python
search.value
```

Writing

```python
search.value = "DBS"
```

Notice the difference.

The first retrieves information.

The second changes information.

---

# Updating a Property

Suppose we write

```python
search.name = "Search SGX Company"
```

The label immediately changes.

Originally

```text
Search Stock
```

becomes

```text
Search SGX Company
```

The widget updates itself automatically.

---

# Widget State

Collectively,

all property values are called the widget's

**state**.

For example,

consider this widget.

```text
Name

↓

Search Stock

-------------------

Value

↓

DBS

-------------------

Visible

↓

True

-------------------

Disabled

↓

False
```

These values completely describe the widget at one moment in time.

If any property changes,

the widget's state changes.

---

# Why State Matters

Modern applications constantly change state.

Imagine using an online banking app.

Initially,

the login button might be disabled.

```text
Username

Password

[ Login ]
```

After entering both fields,

the Login button becomes enabled.

Nothing magical happened.

The application simply changed one property.

```text
disabled

↓

False
```

Interactive software is largely about managing state.

---

# Building a Better Search Box

Let's improve our application.

```python
import panel as pn

pn.extension()

title = pn.pane.Markdown("# SGX Stock Monitor")

search = pn.widgets.TextInput(
    name="Search SGX Stock",
    placeholder="Example: DBS",
    width=350
)

dashboard = pn.Column(
    title,
    search
)

dashboard.servable()
```

The interface now communicates more clearly with the user.

---

# Teacher's Notes

> A useful way to think about widgets is as tiny databases.
>
> Each widget stores information about itself: its label, its current value, whether it is visible, whether it is enabled, and many other properties. Your application doesn't need to inspect what the user sees on the screen—it simply reads the widget's properties.
>
> As we move into reactive programming later in Part II, you'll discover that nearly every callback begins by reading one or more widget properties, performing some logic, and then updating the properties of other widgets or panes.

---

# Common Mistakes

### ❌ Mistake 1

Confusing the widget with its value.

```python
search
```

is the widget object.

```python
search.value
```

is the text stored inside the widget.

They are not the same thing.

---

### ❌ Mistake 2

Thinking properties are fixed.

Most properties can be changed while the application is running.

This allows your interface to respond dynamically to user actions.

---

### ❌ Mistake 3

Using vague labels.

Instead of:

```text
Input
```

prefer:

```text
Search SGX Stock
```

Clear labels improve usability.

---

### ❌ Mistake 4

Ignoring widget state.

Before performing an action, consider questions such as:

* Is the widget visible?
* Is it enabled?
* Does it contain a valid value?

Checking state helps create more robust applications.

---

# Summary

In this lesson, you learned:

* Widgets store information inside properties.
* Properties describe the current state of a widget.
* The `name` property labels a widget.
* The `placeholder` property provides example input.
* The `value` property stores the user's input and is one of the most important properties in Panel.
* Properties such as `disabled`, `visible`, `width`, and `height` control a widget's behavior and appearance.
* Properties can be read and modified at runtime, allowing applications to adapt dynamically.

Understanding widget properties is a major milestone. Almost every interactive Panel application reads widget values and updates widget properties in response to user actions.

---

# Exercises

## Exercise 1 — Explore Widget Properties

Create a `TextInput` widget with:

* `name`
* `placeholder`
* `width`

Experiment by changing each property and observing how the interface changes.

---

## Exercise 2 — Read vs Write

For each statement below, identify whether it **reads** a property or **writes** a property.

```python
search.value
```

```python
search.value = "DBS"
```

```python
search.visible
```

```python
search.visible = False
```

---

## Exercise 3 — Design a Widget State

Imagine the user has searched for **Singtel**.

Describe what the following properties might contain:

| Property      | Value |
| ------------- | ----- |
| `name`        | ?     |
| `value`       | ?     |
| `placeholder` | ?     |
| `disabled`    | ?     |
| `visible`     | ?     |

---

## Coming Up Next

In **Lesson 2.3 — Survey of Panel Widgets**, we'll take a comprehensive tour of the Panel widget library. You'll learn when to use `Button`, `Checkbox`, `Select`, `Slider`, `DatePicker`, `FileInput`, `RadioButtonGroup`, and many more. Rather than diving deeply into one widget at a time, you'll build a mental map of the entire widget ecosystem so you'll know which tool to choose as we continue developing the SGX Stock Monitor.
