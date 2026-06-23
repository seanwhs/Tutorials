# Part 2 — Building the User Interface with Panel

Now that our project is set up, it's time to build something we can actually see.

Before we add AI, upload assignments, or generate grading reports, we need a user interface. This is where teachers will interact with Markly.

One of the goals of this tutorial is to build the entire application using **Python only**. We won't write HTML, CSS, or JavaScript. Instead, we'll use **Panel**, a powerful Python library that lets us build modern web applications entirely in Python.

By the end of this chapter, you'll have a working web application with:

* A professional-looking title
* A short description
* A file upload widget
* A subject selector
* A **Grade Assignment** button
* An area to display grading feedback

Although the application won't perform any grading yet, we'll have laid the foundation for everything that follows.

---

# What is Panel?

Panel is an open-source Python library for building interactive web applications.

Normally, web applications require several technologies:

* HTML for the page structure
* CSS for styling
* JavaScript for interactivity
* Python for backend logic

Panel removes much of this complexity.

Instead of writing code in four different languages, you build everything using Python objects.

For example, instead of writing HTML like this:

```html
<button>Grade Assignment</button>
```

you simply write:

```python
pn.widgets.Button(name="Grade Assignment")
```

Panel automatically converts your Python code into a modern web application.

This makes it an excellent choice for educators, researchers, and data scientists who are comfortable with Python but don't necessarily want to learn front-end web development.

---

# Understanding Widgets

Every interactive element in Panel is called a **widget**.

A widget is simply a graphical component that allows users to interact with your application.

Some common widgets include:

| Widget           | Purpose                         |
| ---------------- | ------------------------------- |
| Button           | Performs an action when clicked |
| TextInput        | Allows users to type text       |
| FileInput        | Upload files                    |
| Select           | Choose from a dropdown list     |
| RadioButtonGroup | Select one option               |
| Checkbox         | Toggle an option on or off      |
| StaticText       | Display information             |
| Markdown         | Display formatted text          |

We'll use several of these throughout Markly.

---

# Our First Panel Application

Create or open **app.py**.

We'll begin with the simplest possible Panel application.

```python
import panel as pn

pn.extension()

pn.pane.Markdown("# Hello Markly!").servable()
```

Let's understand each line.

---

## Importing Panel

```python
import panel as pn
```

This imports the Panel library.

Using the alias `pn` makes the code shorter and follows the convention used throughout the Panel documentation.

---

## Initializing Panel

```python
pn.extension()
```

This line loads Panel's JavaScript and CSS resources.

Think of it as turning the Panel engine on.

Without this line, many widgets will not function correctly.

For most applications, `pn.extension()` is one of the very first lines you'll write.

---

## Creating Markdown

```python
pn.pane.Markdown("# Hello Markly!")
```

Panel includes different kinds of "panes."

A pane is simply something that displays information.

Examples include:

* Markdown
* Images
* HTML
* DataFrames
* Matplotlib figures

Here we're using a Markdown pane.

Because Markdown understands headings, the `#` creates a large title.

---

## Making the Component Visible

```python
.servable()
```

Creating a widget isn't enough.

We also need to tell Panel to display it.

That's exactly what `.servable()` does.

---

# Running the Application

Open your terminal.

Navigate to your project directory.

Run:

```bash
panel serve app.py --autoreload
```

Let's understand the command.

| Option       | Meaning                                         |
| ------------ | ----------------------------------------------- |
| panel serve  | Starts a web server                             |
| app.py       | Runs your application                           |
| --autoreload | Automatically reloads whenever you save changes |

After a few seconds, you'll see something similar to:

```
Launching server at:

http://localhost:5006
```

Open your browser and visit:

```
http://localhost:5006
```

Congratulations!

You've just created your first Panel web application.

---

# Designing the Main Interface

Let's replace our "Hello Markly" page with something more professional.

Update **app.py**.

```python
import panel as pn

pn.extension()

title = pn.pane.Markdown("""
# 🎓 Markly

### AI-Powered Context-Aware Grading Assistant
""")

description = pn.pane.Markdown("""
Upload a student assignment, choose a subject,
and let AI generate detailed teacher-style feedback.
""")

app = pn.Column(
    title,
    description
)

app.servable()
```

Run the application again.

The page now looks much more like the beginning of a real application.

Notice that we're using a **Column**.

---

# Understanding Layouts

A user interface is simply a collection of components arranged on the screen.

Panel provides several layout containers.

The most common are:

| Layout    | Description            |
| --------- | ---------------------- |
| Column    | Vertical arrangement   |
| Row       | Horizontal arrangement |
| Tabs      | Multiple pages         |
| GridBox   | Grid layout            |
| Accordion | Expandable sections    |

Our application currently uses:

```python
pn.Column(...)
```

which stacks components vertically.

```
Title

Description

Next Widget

Next Widget

Next Widget
```

Later we'll combine Columns and Rows to build more sophisticated layouts.

---

# Adding a File Upload Widget

Teachers need a way to upload assignments.

Panel provides the **FileInput** widget.

Add the following code.

```python
upload = pn.widgets.FileInput(
    accept=".pdf,.docx,.png,.jpg,.jpeg"
)
```

Let's understand the parameter.

```python
accept=".pdf,.docx,.png,.jpg,.jpeg"
```

This limits which files the user can select.

Instead of uploading anything, the file picker now accepts only supported assignment formats.

At this stage, uploading a file doesn't actually do anything.

We'll process uploaded files in the next chapter.

---

# Adding a Subject Selector

Different subjects require different grading strategies.

Let's allow the teacher to choose one.

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

Unlike a normal HTML dropdown, this is simply another Python object.

Later we'll use

```python
subject.value
```

to determine which grading prompt should be sent to the AI.

---

# Adding the Grade Button

Next, create a button.

```python
grade_button = pn.widgets.Button(
    name="Grade Assignment",
    button_type="primary"
)
```

The parameter

```python
button_type="primary"
```

gives the button a more prominent appearance.

Users naturally recognize it as the main action on the page.

Currently, clicking the button won't do anything.

We'll connect it to our grading engine later.

---

# Creating an Output Area

Eventually, the AI will generate detailed feedback.

We need somewhere to display it.

Create a Markdown pane.

```python
feedback = pn.pane.Markdown("""
## Feedback

Waiting for assignment...
""")
```

For now, it simply displays placeholder text.

Later we'll replace this with AI-generated grading comments.

---

# Assembling the Interface

Now combine everything into a single layout.

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

Run the application again.

You should now see:

* A title
* A description
* A file upload button
* A subject dropdown
* A grading button
* A feedback section

Although none of these components interact yet, we've created the complete skeleton of our application.

---

# Understanding the Current Architecture

At this point, our application consists only of user interface components.

```
Teacher
    │
    ▼
Uploads Assignment
    │
    ▼
Selects Subject
    │
    ▼
Clicks Grade
    │
    ▼
Nothing Happens Yet 🙂
```

That's perfectly fine.

Professional software is almost always built incrementally. We first create the interface, then connect the logic behind each component.

In the next instalment, we'll bring the application to life by handling uploaded files. We'll learn how the `FileInput` widget stores uploaded data, extract useful information from PDF and Word documents, and prepare that content for submission to the AI grading engine. By the end of the next section, Markly will be able to read the contents of student assignments instead of simply accepting file uploads.
