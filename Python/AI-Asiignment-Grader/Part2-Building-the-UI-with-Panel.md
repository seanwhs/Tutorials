# Part 2 — Building the User Interface with Panel

Now that the project is set up, it’s time to build something visible and interactive.

Before we introduce AI grading, file processing, or feedback generation, we need a user interface. This is the layer teachers will actually use when working with Markly.

A key goal of this tutorial is to build the entire application using **Python only**. That means no HTML, no CSS, and no JavaScript. Instead, we’ll use Panel, a powerful library that lets us build full web applications directly in Python.

By the end of this chapter, you’ll have a working interface with:

* A title and description
* A file upload widget
* A subject selector
* A “Grade Assignment” button
* A feedback display area

It won’t perform any grading yet, but it will establish the complete structure we’ll build on in later parts.

---

# What is Panel?

Panel is an open-source library for building interactive web applications using only Python.

In traditional web development, you typically work with multiple technologies:

* HTML for structure
* CSS for styling
* JavaScript for interactivity
* Python for backend logic

Panel removes this fragmentation by letting you define the entire interface using Python objects.

Instead of writing HTML like:

```html
<button>Grade Assignment</button>
```

you write:

```python
pn.widgets.Button(name="Grade Assignment")
```

Panel then renders it as a modern web UI automatically.

Official documentation:
[Panel Documentation](https://panel.holoviz.org?utm_source=chatgpt.com)

This makes Panel especially useful for educators, data scientists, and Python developers who want to build applications without learning frontend frameworks.

---

# Understanding Widgets

In Panel, every interactive element is called a **widget**.

A widget is a UI component that either captures user input or triggers an action.

Common widgets include:

| Widget           | Purpose                    |
| ---------------- | -------------------------- |
| Button           | Triggers an action         |
| TextInput        | Accepts text input         |
| FileInput        | Uploads files              |
| Select           | Dropdown selection         |
| RadioButtonGroup | Selects one option         |
| Checkbox         | Toggles a setting          |
| StaticText       | Displays plain text        |
| Markdown         | Displays formatted content |

We’ll use several of these to construct Markly’s interface.

---

# Our First Panel Application

Create or open `app.py`.

Start with the simplest possible Panel app:

```python
import panel as pn

pn.extension()

pn.pane.Markdown("# Hello Markly!").servable()
```

---

## Import Panel

```python
import panel as pn
```

This imports Panel and assigns it the alias `pn`, which is the standard convention.

---

## Initialize Panel

```python
pn.extension()
```

This activates Panel’s frontend resources (JavaScript and CSS). Without it, widgets may not render correctly.

Think of it as starting the UI runtime.

---

## Create a Markdown Pane

```python
pn.pane.Markdown("# Hello Markly!")
```

A **pane** is a display component in Panel.

It can render:

* Markdown
* Images
* HTML
* Tables
* Plots

Here, we use Markdown to create a heading using `#`.

---

## Make It Visible

```python
.servable()
```

This tells Panel: *“Render this component in the web application.”*

Without `.servable()`, nothing appears in the browser.

---

# Running the Application

To run your Panel application, open a terminal and navigate to your project directory.

Then execute:

```bash
panel serve app.py --show --autoreload
```

This command does three important things:

| Command / Flag     | Meaning                                                 |
| ------------------ | ------------------------------------------------------- |
| panel serve app.py | Starts the Panel server and runs your app               |
| --show             | Automatically opens the app in your browser             |
| --autoreload       | Reloads the app automatically whenever you save changes |

After running it, you will see output similar to:

```
Launching server at:
http://localhost:5006
```

If the browser does not open automatically, simply visit:

```
http://localhost:5006
```

At this point, your first Python-based web application is running. Any edits you make to `app.py` will be reflected instantly thanks to auto-reload.

---

# Designing the Main Interface

Now let’s replace the simple “Hello Markly” page with a structured layout.

Update `app.py`:

```python
import panel as pn

pn.extension()

title = pn.pane.Markdown("""
# 🎓 Markly
### AI-Powered Context-Aware Grading Assistant
""")

description = pn.pane.Markdown("""
Upload a student assignment, choose a subject,
and receive AI-generated feedback.
""")

app = pn.Column(
    title,
    description
)

app.servable()
```

Now the interface looks like the beginning of a real application.

---

# Understanding Layouts

A web UI is simply a structured arrangement of components.

Panel provides layout containers to organize them.

Common layouts include:

| Layout    | Description          |
| --------- | -------------------- |
| Column    | Vertical stacking    |
| Row       | Horizontal layout    |
| Tabs      | Multi-page interface |
| GridBox   | Grid-based layout    |
| Accordion | Collapsible sections |

We are currently using:

```python
pn.Column(...)
```

Which stacks elements vertically:

```
Title
↓
Description
↓
Next component
```

---

# Adding a File Upload Widget

Teachers need to upload assignments.

We use the `FileInput` widget:

```python
upload = pn.widgets.FileInput(
    accept=".pdf,.docx,.png,.jpg,.jpeg"
)
```

The `accept` parameter restricts file types to supported formats.

At this stage, the upload works visually but does not yet process files. We’ll handle that later.

---

# Adding a Subject Selector

Different subjects require different grading logic.

```python
subject = pn.widgets.Select(
    name="Subject",
    options=[
        "Mathematics",
        "English",
        "Science",
        "Programming"
    ]
)
```

Later, we’ll use:

```python
subject.value
```

to determine how the AI should evaluate the assignment.

---

# Adding the Grade Button

```python
grade_button = pn.widgets.Button(
    name="Grade Assignment",
    button_type="primary"
)
```

The `button_type="primary"` styling makes it visually prominent as the main action.

At this stage, clicking it does nothing—we’ll connect it to the grading logic later.

---

# Creating the Feedback Area

We need a place to display AI-generated feedback.

```python
feedback = pn.pane.Markdown("""
## Feedback

Waiting for assignment...
""")
```

This is placeholder content for now and will later be replaced with AI output.

---

# Assembling the Full Interface

Now combine everything:

```python
import panel as pn

pn.extension()

title = pn.pane.Markdown("""
# 🎓 Markly
### AI-Powered Context-Aware Grading Assistant
""")

description = pn.pane.Markdown("""
Upload a student assignment and receive
teacher-style AI feedback.
""")

upload = pn.widgets.FileInput(
    accept=".pdf,.docx,.png,.jpg,.jpeg"
)

subject = pn.widgets.Select(
    name="Subject",
    options=[
        "Mathematics",
        "English",
        "Science",
        "Programming"
    ]
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
    subject,
    grade_button,
    feedback,
    width=700
)

app.servable()
```

---

# What We’ve Built So Far

At this stage, Markly is a complete UI shell:

```
Teacher
  ↓
Uploads file
  ↓
Selects subject
  ↓
Clicks Grade
  ↓
(No backend logic yet)
```

This is intentional. Most real-world applications are built in layers:

1. UI first
2. Logic second
3. Intelligence (AI) last

---

# What’s Next?

In the next part, we’ll make Markly functional.

You’ll learn how to:

* Access uploaded files from `FileInput`
* Extract text from PDFs and Word documents
* Normalize assignment content for AI processing
* Prepare structured prompts for grading

Once this is done, Markly will evolve from a static interface into a working AI-powered grading system.
