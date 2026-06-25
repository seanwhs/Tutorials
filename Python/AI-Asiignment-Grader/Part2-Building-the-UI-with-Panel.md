# Part 2 — Building the User Interface with Panel

## Creating the Teacher Dashboard

In Part 1, we designed the architecture of Markly.

We learned that grading an assignment involves many stages:

```text
Upload Assignment
        │
        ▼
Subject Detection
        │
        ▼
Content Extraction
        │
        ▼
Rubric Selection
        │
        ▼
Teacher Persona
        │
        ▼
AI Evaluation
        │
        ▼
Annotation Generation
        │
        ▼
Student Memory
        │
        ▼
PDF Report
```

Before we can implement any of those systems, we need something much simpler:

A user interface.

After all, teachers need a way to:

* upload assignments
* select grading options
* start grading
* review feedback
* download reports

In this chapter, we'll build the first version of the Markly Teacher Dashboard.

Although it won't perform grading yet, it will establish the structure that every future feature will plug into.

---

# What Is A User Interface?

A user interface (UI) is the part of a system that people interact with.

Without a UI, our application would only exist as Python code.

The teacher would have no way to:

* upload files
* click buttons
* view results

Consider the difference.

Without a UI:

```python
grade_assignment("essay.docx")
```

Only programmers can use the system.

With a UI:

```text
+--------------------------------+
| Upload Assignment              |
| [Choose File]                  |
|                                |
| Subject                        |
| [Mathematics ▼]                |
|                                |
| [ Grade Assignment ]           |
+--------------------------------+
```

Anyone can use it.

The UI acts as the bridge between humans and software.

---

# Why Are We Using Panel?

Traditionally, web applications require multiple technologies:

| Responsibility | Technology |
| -------------- | ---------- |
| Structure      | HTML       |
| Styling        | CSS        |
| Interactivity  | JavaScript |
| Backend Logic  | Python     |

This means developers often need to learn several programming languages before they can build a web application.

Panel simplifies this dramatically.

With Panel, we can build the entire interface using Python.

Instead of:

```html
<button>
Grade Assignment
</button>
```

we write:

```python
pn.widgets.Button(
    name="Grade Assignment"
)
```

Panel automatically converts Python objects into web components.

This makes it an excellent choice for:

* educators
* analysts
* scientists
* AI developers
* Python beginners

who want to build applications without becoming frontend engineers.

Official documentation:

[Panel Documentation](https://panel.holoviz.org?utm_source=chatgpt.com)

---

# Understanding How Panel Works

Everything in Panel is an object.

A button is an object.

A text area is an object.

A file upload widget is an object.

A layout is an object.

You create objects and combine them together to build an interface.

Think of it like building with LEGO bricks.

```text
Button
+
Upload Widget
+
Dropdown
+
Text Area
=
Application
```

---

# The Teacher Workflow

Before creating widgets, let's design the workflow.

What does a teacher actually do?

Typically:

### Step 1

Upload an assignment.

```text
homework.pdf
```

### Step 2

Choose grading options.

```text
Mathematics
```

or

```text
Auto Detect Subject
```

### Step 3

Start grading.

```text
Grade Assignment
```

### Step 4

Review results.

```text
Grade: 82%

Strengths:
...

Areas for Improvement:
...
```

### Step 5

Download reports.

```text
Download PDF
Download Marked Assignment
```

Our interface should mirror this workflow.

---

# Designing The Dashboard

The finished dashboard will eventually contain:

```text
+--------------------------------------------------+
|                  MARKLY                          |
| AI-Powered Context-Aware Grading Assistant       |
+--------------------------------------------------+

 Assignment Upload

 [ Choose File ]

 Subject

 [ Auto Detect ▼ ]

 Student Name

 [________________]

 [ Grade Assignment ]

 --------------------------------------------------

 Feedback

 --------------------------------------------------

 Grade: ...

 Strengths:
 ...

 Weaknesses:
 ...

 --------------------------------------------------

 [ Download Report ]

 [ Download Marked Assignment ]

+--------------------------------------------------+
```

We won't build everything today.

We'll start with the foundation.

---

# Creating Our First Panel Application

Open:

```text
app.py
```

Add:

```python
import panel as pn

pn.extension()

pn.pane.Markdown("# 🎓 Markly").servable()
```

---

# Understanding Each Line

## Import Panel

```python
import panel as pn
```

This imports the Panel library.

The alias:

```python
pn
```

is simply shorthand.

Instead of:

```python
panel.widgets.Button(...)
```

we can write:

```python
pn.widgets.Button(...)
```

which is much shorter.

---

## Initialize Panel

```python
pn.extension()
```

This loads Panel's frontend resources.

Think of it as starting the engine.

Without it, widgets may not display correctly.

You will almost always see:

```python
pn.extension()
```

near the top of a Panel application.

---

## Create A Display Component

```python
pn.pane.Markdown("# 🎓 Markly")
```

A Pane displays information.

Panel provides many pane types:

| Pane       | Purpose      |
| ---------- | ------------ |
| Markdown   | Text         |
| HTML       | HTML Content |
| Image      | Images       |
| DataFrame  | Tables       |
| Plotly     | Charts       |
| Matplotlib | Graphs       |

We are using Markdown because it's simple and readable.

---

## Make It Visible

```python
.servable()
```

This tells Panel:

> Render this object in the web application.

Without:

```python
.servable()
```

nothing appears.

---

# Running The Application

Open a terminal.

Navigate to your project folder.

Run:

```bash
panel serve app.py --show --autoreload
```

Let's understand each part.

### panel serve

Starts the web server.

### app.py

The file Panel should execute.

### --show

Automatically opens a browser window.

### --autoreload

Restarts the application whenever you save changes.

This is extremely useful during development.

---

# Understanding Widgets

A widget is an interactive component.

Examples:

| Widget           | Purpose            |
| ---------------- | ------------------ |
| Button           | Trigger actions    |
| TextInput        | Enter text         |
| FileInput        | Upload files       |
| Select           | Dropdown selection |
| Checkbox         | Toggle options     |
| RadioButtonGroup | Choose one option  |
| TextAreaInput    | Multi-line text    |

Widgets allow users to communicate with your application.

---

# Building The Upload Section

The first thing teachers need is a file upload area.

Create:

```python
upload = pn.widgets.FileInput(
    accept=".pdf,.docx,.png,.jpg,.jpeg"
)
```

---

# Understanding FileInput

This widget allows users to select a file.

When a file is chosen:

```python
upload.value
```

will contain the file contents.

Later we will use this data to:

* read PDFs
* read DOCX files
* process images
* perform OCR
* send content to AI

For now, we only need the upload control itself.

---

# Building The Subject Selector

Although Markly will eventually support automatic subject detection, it is useful to allow manual selection.

Create:

```python
subject = pn.widgets.Select(
    name="Subject",
    options=[
        "Auto Detect",
        "Mathematics",
        "English",
        "Science",
        "Programming"
    ]
)
```

Notice we added:

```text
Auto Detect
```

because future versions of Markly will classify assignments automatically.

---

# Building The Student Field

Future versions of Markly will support student memory and progress tracking.

To prepare for that feature, add:

```python
student_name = pn.widgets.TextInput(
    name="Student Name"
)
```

This will later allow us to:

* identify students
* retrieve grading history
* generate progress reports

---

# Building The Grade Button

Create:

```python
grade_button = pn.widgets.Button(
    name="Grade Assignment",
    button_type="primary"
)
```

This button will eventually trigger the entire grading pipeline.

```text
Upload
↓
Extract
↓
Classify
↓
Grade
↓
Generate Feedback
↓
Generate Report
```

Right now it does nothing.

That's perfectly fine.

Professional software is built incrementally.

---

# Creating The Feedback Area

We need somewhere to display results.

Create:

```python
feedback = pn.pane.Markdown("""
## Feedback

Waiting for assignment...
""")
```

Later, this panel will display:

```text
Grade: 85%

Strengths:
• Good understanding of algebra

Areas For Improvement:
• Show more working

Recommendations:
• Practice solving equations
```

---

# Assembling The Dashboard

Now combine everything:

```python
import panel as pn

pn.extension()

title = pn.pane.Markdown("""
# 🎓 Markly

### AI-Powered Context-Aware Grading Assistant
""")

description = pn.pane.Markdown("""
Upload assignments and generate
AI-assisted grading reports.
""")

upload = pn.widgets.FileInput(
    accept=".pdf,.docx,.png,.jpg,.jpeg"
)

subject = pn.widgets.Select(
    name="Subject",
    options=[
        "Auto Detect",
        "Mathematics",
        "English",
        "Science",
        "Programming"
    ]
)

student_name = pn.widgets.TextInput(
    name="Student Name"
)

grade_button = pn.widgets.Button(
    name="Grade Assignment",
    button_type="primary"
)

feedback = pn.pane.Markdown("""
## Feedback

Waiting for assignment...
""")

app = pn.Column(
    title,
    description,
    upload,
    student_name,
    subject,
    grade_button,
    feedback,
    width=800
)

app.servable()
```

---

# What We've Built

We now have the first version of the Markly Teacher Dashboard.

Although no grading occurs yet, we've already created the user-facing shell of the application.

The dashboard now supports:

✓ Assignment uploads

✓ Student identification

✓ Subject selection

✓ Feedback display

✓ Future AI integration points

Most importantly, every component we've created corresponds directly to a stage in the architecture we designed in Part 1.

---

# Architecture Connection

Notice how the interface maps to the system design:

| UI Component     | Future Responsibility      |
| ---------------- | -------------------------- |
| FileInput        | Assignment Upload          |
| Subject Selector | Subject Detection Override |
| Student Name     | Student Memory Lookup      |
| Grade Button     | Start Grading Pipeline     |
| Feedback Area    | Display AI Evaluation      |

This alignment between UI and architecture is one of the hallmarks of well-designed software systems.

---

# What's Next?

In **Part 3 — Uploading and Understanding Assignments**, we'll make the upload widget functional.

You'll learn:

* how uploaded files are represented in memory
* how to access uploaded file contents
* how to inspect file metadata
* how Markly determines what type of assignment was uploaded

For the first time, the application will begin processing real teacher submissions rather than simply displaying interface components.
