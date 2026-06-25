# Part II — Widgets: Building Interactive User Interfaces

# Lesson 2.6 — Reading User Input with `value`

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand the purpose of the `value` property.
> * Learn how widgets store user input.
> * Read data entered by the user.
> * Connect multiple widgets together.
> * Build your first useful callback.
> * Understand how data flows through a Panel application.
> * Build the first working feature of our SGX Stock Monitor.

---

# Introduction

In the previous lesson, we learned how to make a Button respond to clicks.

Our callback looked like this.

```python
def search_stock(event):
    print("Searching...")
```

When the user clicked

```text
[ Search ]
```

the callback executed.

But there was one problem.

The callback had no idea **which stock** the user wanted.

Whether the user typed:

```text
DBS
```

or

```text
UOB
```

or

```text
Singtel
```

our program always printed exactly the same message.

```text
Searching...
```

Clearly,

this isn't very useful.

Today we'll learn how our callback can retrieve the information entered by the user.

---

# Remember the TextInput Widget

Earlier we created this widget.

```python
search = pn.widgets.TextInput(
    name="Stock Symbol",
    placeholder="Example: DBS"
)
```

It appears as

```text
Stock Symbol

Example: DBS
```

Earlier we learned something important.

Every widget stores information inside its properties.

One of those properties is

```python
value
```

Today,

we'll finally start using it.

---

# What Is `value`?

Recall that every widget has a state.

For a `TextInput`, one of the most important properties is

```python
value
```

This property stores whatever the user has typed.

Initially,

the widget contains nothing.

```text
Stock Symbol

________________
```

Internally,

its state looks like this.

```text
value

↓

""
```

An empty string.

---

# After the User Types

Suppose the user enters

```text
DBS
```

The screen changes.

```text
Stock Symbol

DBS
```

More importantly,

the widget changes internally.

```text
value

↓

"DBS"
```

The widget now remembers what the user typed.

---

# Reading the Value

Retrieving the text is very simple.

```python
search.value
```

If the user typed

```text
DBS
```

then

```python
print(search.value)
```

produces

```text
DBS
```

If they typed

```text
Singtel
```

then

```python
print(search.value)
```

produces

```text
Singtel
```

The callback always sees the latest value.

---

# How Does This Work?

Think of the widget as a storage box.

Initially

```text
TextInput

↓

value

↓

(empty)
```

User types

```text
DBS
```

The storage box changes.

```text
TextInput

↓

value

↓

DBS
```

Your program simply opens the box and reads the contents.

---

# Updating Our Callback

Instead of

```python
def search_stock(event):
    print("Searching...")
```

we can write

```python
def search_stock(event):
    symbol = search.value

    print(symbol)
```

Now,

clicking the button prints whatever the user typed.

---

# Understanding the Variable

Notice this line.

```python
symbol = search.value
```

Let's examine it.

First,

Panel retrieves

```python
search.value
```

Suppose it contains

```text
DBS
```

Python then performs the assignment.

```python
symbol = "DBS"
```

Now,

both

```python
search.value
```

and

```python
symbol
```

contain

```text
DBS
```

---

# Why Store It in a Variable?

You might wonder why we don't simply write

```python
print(search.value)
```

We certainly can.

However,

using a variable makes our code easier to understand.

```python
symbol = search.value
```

Later,

we can write

```python
download_stock(symbol)

display_chart(symbol)

show_company_info(symbol)
```

instead of repeatedly typing

```python
search.value
```

---

# Our First Useful Program

Let's put everything together.

```python
import panel as pn

pn.extension()

search = pn.widgets.TextInput(
    name="Stock Symbol",
    placeholder="Example: DBS"
)

button = pn.widgets.Button(
    name="Search",
    button_type="primary"
)

def search_stock(event):

    symbol = search.value

    print("Searching for:", symbol)

button.on_click(search_stock)

dashboard = pn.Column(
    search,
    button
)

dashboard.servable()
```

---

# What Happens Now?

Suppose the user types

```text
DBS
```

Then clicks

```text
Search
```

The following sequence occurs.

```text
User Types

↓

Widget Updates value

↓

User Clicks Button

↓

Callback Executes

↓

Read search.value

↓

Print Stock Symbol
```

---

# Visualizing the Data Flow

Let's follow the information.

```text
Keyboard

↓

TextInput Widget

↓

value Property

↓

Callback

↓

Python Variable

↓

Application Logic
```

This pattern appears throughout every Panel application.

---

# Trying Different Inputs

Suppose the user types

```text
UOB
```

The callback prints

```text
Searching for: UOB
```

---

User types

```text
OCBC
```

The callback prints

```text
Searching for: OCBC
```

---

User types

```text
S58
```

The callback prints

```text
Searching for: S58
```

The code never changes.

Only the widget's value changes.

---

# What If Nothing Was Entered?

Suppose the user immediately clicks Search.

The textbox still contains

```text
```

(an empty string)

The callback prints

```text
Searching for:
```

This isn't ideal.

Eventually,

we'll validate the input before searching.

---

# Understanding Empty Strings

An empty textbox doesn't contain

```python
None
```

Instead,

it contains

```python
""
```

An empty string.

This is important.

Many beginners assume the widget contains

```python
None
```

It doesn't.

---

# Checking for Empty Input

Python makes this easy.

```python
def search_stock(event):

    symbol = search.value

    if symbol == "":
        print("Please enter a stock symbol.")
        return

    print("Searching for:", symbol)
```

Now,

the application behaves more intelligently.

---

# Understanding `return`

Notice this line.

```python
return
```

It immediately stops the function.

Think of it as an emergency exit.

```text
Check Input

↓

Invalid?

↓

YES

↓

Leave Function
```

Nothing below the `return`

executes.

---

# Making the Check Shorter

Python has a convenient shortcut.

Instead of

```python
if symbol == "":
```

we can write

```python
if not symbol:
```

Why?

Because an empty string evaluates to

```text
False
```

This is common Python style.

We'll use it throughout this tutorial.

---

# Improving the Callback

A more professional version looks like this.

```python
def search_stock(event):

    symbol = search.value

    if not symbol:
        print("Please enter a stock symbol.")
        return

    print(f"Searching SGX for {symbol}")
```

Notice another new feature.

---

# Introducing f-Strings

This line

```python
print(f"Searching SGX for {symbol}")
```

uses an **f-string**.

The

```python
f
```

before the quotation marks tells Python

to insert variables into the string.

Suppose

```python
symbol = "DBS"
```

The result becomes

```text
Searching SGX for DBS
```

This is much easier to read than older formatting techniques.

---

# Why Read the Widget Inside the Callback?

Some beginners ask:

> "Why don't we read `search.value` when the application starts?"

Consider this sequence.

Application starts.

```text
Text Box

↓

(empty)
```

At startup,

the user hasn't typed anything yet.

Reading

```python
search.value
```

at that moment would return

```text
""
```

We wait until the user clicks Search because that's when we expect the input to be complete.

---

# Separation of Responsibilities

Notice how nicely the application is organized.

The TextInput is responsible for

* collecting user input

The Button is responsible for

* generating click events

The Callback is responsible for

* reading the widget
* validating the input
* deciding what to do next

Each component has one responsibility.

---

# Looking Ahead

Today,

our callback only prints the stock symbol.

Soon,

it will do much more.

```text
Read Symbol

↓

Validate Symbol

↓

Download Market Data

↓

Update Price Table

↓

Update Chart

↓

Display Company Information

↓

Refresh Dashboard
```

Everything begins with

```python
search.value
```

---

# Teacher's Notes

> One of the most important ideas in Panel is that widgets are the application's source of truth.
>
> Rather than trying to read text directly from the screen, your code always interacts with the widget objects. The widget stores the current state, and your callbacks simply read that state whenever they need it.
>
> This design makes applications predictable, testable, and much easier to maintain.

---

# Common Mistakes

### ❌ Mistake 1

Trying to read the widget before the user has entered anything.

Remember,

the widget initially contains an empty string.

---

### ❌ Mistake 2

Assuming an empty `TextInput` returns `None`.

It returns

```python
""
```

(an empty string).

---

### ❌ Mistake 3

Forgetting to validate user input.

Always check that required fields contain valid information before performing an action.

---

### ❌ Mistake 4

Reading the wrong object.

Incorrect:

```python
symbol = search
```

Correct:

```python
symbol = search.value
```

The widget object and its value are different things.

---

# Summary

In this lesson, you learned:

* The `value` property stores the user's input.
* `search.value` always contains the latest text entered into the widget.
* Callbacks can read widget properties to determine what the user entered.
* Empty `TextInput` widgets contain an empty string (`""`).
* Input should be validated before performing actions.
* f-strings provide a clean way to include variables in output.
* Interactive applications typically read widget values inside callbacks rather than during application startup.

For the first time, our SGX Stock Monitor is responding to **real user input**. We've connected a `TextInput` and a `Button` together, creating our first complete interaction.

---

# Exercises

## Exercise 1 — Display User Input

Modify the callback so that it prints:

```text
You searched for: DBS
```

where **DBS** is whatever the user entered.

Test the application using several different stock symbols.

---

## Exercise 2 — Validate Empty Input

Update your callback so that:

* If the user enters nothing, display:

```text
Please enter a stock symbol.
```

* Otherwise, display:

```text
Searching SGX for <symbol>
```

Test both cases.

---

## Exercise 3 — Trace the Data Flow

Without looking back at the lesson, draw a diagram showing how the text **DBS** travels through the application after the user clicks **Search**.

Include:

* Keyboard
* TextInput
* `value`
* Callback
* Variable
* Output

---

# Coming Up Next

In **Lesson 2.7 — Displaying Results with Markdown Panes**, we'll move beyond printing to the terminal. Instead of displaying messages in the console, we'll update the application's user interface itself. You'll learn how to modify a `Markdown` pane dynamically so that search results appear directly inside the SGX Stock Monitor dashboard. This is a major milestone: for the first time, your application will both **accept input** and **update its interface** in response, creating a true interactive web application.
