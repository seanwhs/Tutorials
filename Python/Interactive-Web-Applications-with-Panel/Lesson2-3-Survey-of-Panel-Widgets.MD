# Part II — Widgets: Building Interactive User Interfaces

# Lesson 2.3 — A Comprehensive Tour of Panel Widgets

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand the major categories of Panel widgets.
> * Learn when each widget should be used.
> * Understand the strengths and limitations of each widget.
> * Develop the ability to choose the right widget for a problem.
> * Learn the common properties shared by most widgets.
> * Begin designing the user interface for our SGX Stock Monitor.
> * Build a mental map of the entire Panel widget ecosystem.

---

# Introduction

In the previous lessons, we've focused on a single widget:

```python
pn.widgets.TextInput()
```

It allows users to type text.

But Panel contains **dozens of widgets**.

Just like a carpenter has different tools for different jobs,

a Panel developer has different widgets for different kinds of user input.

Choosing the right widget is an important design skill.

Throughout this lesson, we'll explore the entire widget ecosystem—not in exhaustive detail (we'll do that later), but enough to understand:

* what each widget does
* when to use it
* why it exists
* how it fits into a professional application

---

# A Widget Is a Tool

Imagine you're building a house.

Would you use a hammer to tighten a screw?

Of course not.

Different tools solve different problems.

```text
Hammer

↓

Nails

-------------------

Screwdriver

↓

Screws

-------------------

Saw

↓

Wood

-------------------

Paint Brush

↓

Paint
```

Widgets work the same way.

There is no "best" widget.

There is only the **right widget for the job.**

---

# The Panel Widget Library

Panel includes widgets for almost every kind of user interaction.

A simplified view looks like this.

```text
Widgets

├── Text Input

├── Numeric Input

├── Selection

├── Buttons

├── Boolean

├── Date & Time

├── Files

├── Color

├── Indicators

└── Advanced Widgets
```

We'll explore each category.

---

# Category 1 — Text Input Widgets

These widgets allow users to type information.

Examples include:

```python
pn.widgets.TextInput()

pn.widgets.TextAreaInput()

pn.widgets.PasswordInput()

pn.widgets.StaticText()
```

---

## TextInput

We already know this one.

```python
pn.widgets.TextInput(
    name="Search Stock"
)
```

Example:

```text
Search Stock

____________________
```

Use it for:

* Stock symbols
* Company names
* Usernames
* Email addresses
* Search boxes

Our SGX Stock Monitor will use this extensively.

---

## TextAreaInput

Sometimes,

one line isn't enough.

Example:

```python
pn.widgets.TextAreaInput()
```

Produces:

```text
_________________________

_________________________

_________________________

_________________________
```

Useful for:

* Notes
* Comments
* Feedback
* Reports

Not useful for stock symbols.

---

## PasswordInput

Looks like a TextInput.

Except:

```text
*************
```

instead of

```text
mypassword123
```

Useful for:

* Login screens
* API keys
* Secret tokens

We'll eventually use this for financial API credentials.

---

## StaticText

Displays information

without allowing editing.

```text
Connected to SGX
```

Unlike Markdown,

it behaves like a widget.

---

# Category 2 — Numeric Widgets

Sometimes users enter numbers instead of text.

Panel provides several options.

---

## IntInput

Only allows integers.

```python
pn.widgets.IntInput()
```

Example:

```text
Shares Owned

[ 150 ]
```

Useful for:

* Number of shares
* Watchlist size
* Maximum alerts

---

## FloatInput

Allows decimal numbers.

```python
pn.widgets.FloatInput()
```

Example:

```text
Purchase Price

[ 32.75 ]
```

Useful for:

* Stock prices
* Exchange rates
* Financial ratios

---

## Spinner Inputs

These allow users to increase or decrease values.

```text
Quantity

[ 100 ▲ ]

      ▼
```

Useful when values change incrementally.

---

# Category 3 — Sliders

Sliders allow users to select values visually.

---

## IntSlider

```python
pn.widgets.IntSlider()
```

Example:

```text
1 ─────────●──────── 100
```

Useful for:

* Moving averages
* Number of trading days
* Portfolio allocation

---

## FloatSlider

Same idea,

but supports decimal values.

Example:

```text
0.0 ─────●───── 1.0
```

Useful for percentages.

---

## RangeSlider

Allows selection of a range.

```text
10 ●────────────● 100
```

Useful for:

* Price ranges
* Date ranges
* Volume filters

---

# Category 4 — Buttons

Buttons perform actions.

Unlike TextInput,

they don't collect information.

They trigger events.

---

## Button

```python
pn.widgets.Button()
```

Example:

```text
[ Search ]
```

or

```text
[ Refresh ]
```

Our SGX application will eventually include:

```text
Search

Refresh Prices

Add to Watchlist

Export Portfolio
```

---

## Toggle

Acts like an on/off switch.

```text
OFF

↓

ON
```

Useful for:

* Dark Mode
* Auto Refresh
* Notifications

---

# Category 5 — Boolean Widgets

These represent

True

or

False.

---

## Checkbox

```python
pn.widgets.Checkbox()
```

Example:

```text
☐ Auto Refresh
```

or

```text
☑ Auto Refresh
```

Useful whenever users answer

Yes

or

No.

---

## Switch

A modern version of a checkbox.

```text
OFF

ON
```

Often preferred in modern dashboards.

---

# Category 6 — Selection Widgets

Sometimes,

users must choose from predefined options.

---

## Select

Dropdown menu.

```python
pn.widgets.Select()
```

Example:

```text
Exchange

▼ SGX
```

Choices might include:

* SGX
* NYSE
* NASDAQ
* HKEX

---

## MultiSelect

Allows multiple choices.

Example:

```text
Watchlists

☑ Banks

☑ REITs

☐ Technology

☐ Healthcare
```

---

## RadioButtonGroup

Only one option may be selected.

```text
(•) Daily

( ) Weekly

( ) Monthly
```

Useful when exactly one choice is valid.

---

# Category 7 — Date Widgets

Financial applications frequently work with dates.

Panel provides dedicated widgets.

---

## DatePicker

```python
pn.widgets.DatePicker()
```

Example:

```text
Choose Date

2026-06-26
```

Useful for:

* Historical prices
* Dividend history
* Financial reports

---

## DateRangeSlider

Allows selection of

both

start

and

end

dates.

Very useful for charts.

---

# Category 8 — File Widgets

Applications often need files.

---

## FileInput

Allows users to upload files.

Useful for:

* Portfolio CSV files
* Transaction history
* Company reports

Eventually,

our users will import portfolios using CSV.

---

## FileDownload

Allows generated files to be downloaded.

Examples:

* Portfolio Report
* Watchlist CSV
* Historical Prices

---

# Category 9 — Color Widgets

These let users choose colours.

Useful for:

* Chart customization
* Themes
* Branding

Example:

```python
pn.widgets.ColorPicker()
```

---

# Category 10 — Indicators

Unlike ordinary widgets,

Indicators usually display status.

Examples include:

Progress Bars

Loading Spinners

Status Indicators

Success Messages

These improve user experience while data loads.

---

# Common Widget Properties

Most widgets share similar properties.

```text
name

value

visible

disabled

width

height

styles
```

This consistency makes Panel easier to learn.

Once you've mastered one widget,

many others feel familiar.

---

# How Do We Choose the Right Widget?

Ask yourself:

**Question 1**

What information is being entered?

Text?

Number?

Date?

Choice?

File?

---

**Question 2**

Can users type anything?

Or

must they choose from predefined values?

---

**Question 3**

Is the user entering data?

Or

triggering an action?

---

# Example — Choosing Widgets

Suppose we're designing our stock monitor.

---

Searching for a stock.

Best widget?

```text
TextInput
```

because users type symbols.

---

Choosing a market.

Best widget?

```text
Select
```

because markets come from a fixed list.

---

Refreshing prices.

Best widget?

```text
Button
```

because the user triggers an action.

---

Enabling automatic updates.

Best widget?

```text
Checkbox

or

Switch
```

because it's either enabled

or

disabled.

---

Selecting a historical period.

Best widget?

```text
DatePicker

or

DateRangeSlider
```

because dates are involved.

---

# Designing Our SGX Stock Monitor

Based on everything we've learned,

our application might use:

| Feature          | Widget             |
| ---------------- | ------------------ |
| Search Stock     | `TextInput`        |
| Exchange         | `Select`           |
| Refresh Prices   | `Button`           |
| Auto Refresh     | `Checkbox`         |
| Historical Date  | `DatePicker`       |
| Portfolio Import | `FileInput`        |
| Chart Period     | `RadioButtonGroup` |
| Theme            | `Toggle`           |

Notice something.

We're making engineering decisions.

We're not randomly choosing widgets.

We're selecting the widget

that best matches the problem.

---

# Widget Selection Is a Design Skill

Professional developers don't memorize widgets.

Instead,

they ask:

> What information am I collecting?

Once they answer that question,

the correct widget often becomes obvious.

---

# Teacher's Notes

> Beginners often overuse `TextInput` because it seems flexible—you can type almost anything into it. However, free-form text is not always the best choice. If there are only a handful of valid options, use a `Select`. If the answer is simply yes or no, use a `Checkbox` or `Switch`. If the user is entering a date, use a `DatePicker`.
>
> Choosing the most appropriate widget reduces user errors, simplifies validation, and makes your application more intuitive. Good user interface design begins with selecting the right input controls.

---

# Common Mistakes

### ❌ Mistake 1

Using `TextInput` for everything.

Whenever possible,

choose a widget that naturally matches the type of data being entered.

---

### ❌ Mistake 2

Using a `Checkbox`

when users should only choose one option.

Use `RadioButtonGroup`

or

`Select` instead.

---

### ❌ Mistake 3

Using a `Button`

to store information.

Buttons trigger actions.

They do not retain user input.

---

### ❌ Mistake 4

Providing users with unrestricted input

when only a few values are valid.

Restricting choices often improves usability and reduces mistakes.

---

# Summary

In this lesson, you learned:

* Panel provides a rich collection of widgets for different kinds of user interaction.
* Widgets can be grouped into categories such as text input, numeric input, selection, buttons, boolean controls, date controls, file handling, colour selection, and indicators.
* Each widget is designed to solve a particular type of user interaction problem.
* Many widgets share common properties such as `name`, `value`, `visible`, and `disabled`.
* Choosing the appropriate widget is an important software design decision that improves both usability and maintainability.

You now have a broad understanding of the Panel widget ecosystem. In the following lessons, we'll begin exploring the most important widgets in depth, starting with the workhorse of many applications: the **Button**.

---

# Exercises

## Exercise 1 — Match the Widget

Choose the most appropriate widget for each task:

| Task                 | Widget |
| -------------------- | ------ |
| Enter stock symbol   | ?      |
| Choose exchange      | ?      |
| Upload portfolio CSV | ?      |
| Enable dark mode     | ?      |
| Select chart period  | ?      |
| Refresh market data  | ?      |
| Enter purchase price | ?      |

---

## Exercise 2 — Design a Settings Panel

Imagine adding a **Settings** page to the SGX Stock Monitor.

List at least six settings and choose the most appropriate widget for each.

Example:

| Setting          | Widget    |
| ---------------- | --------- |
| Theme            | Toggle    |
| Refresh Interval | IntSlider |

---

## Exercise 3 — Justify Your Choices

Choose three widgets from this lesson.

For each one, explain:

* What type of information it collects.
* Why it is better than a generic `TextInput`.
* Where it might be used in the SGX Stock Monitor.

---

## Coming Up Next

In **Lesson 2.4 — The Button Widget**, we'll begin our detailed exploration of individual widgets. You'll learn everything about `pn.widgets.Button`: how buttons work, why they don't store data, how they generate events, how to customize their appearance, and how they'll become the primary way users interact with our SGX Stock Monitor. This lesson marks the beginning of truly event-driven applications.
