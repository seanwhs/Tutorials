# Part 8 — Building a Professional User Experience

At this point, Markly is a functional AI grading assistant.

A teacher can:

* Upload an assignment
* Choose a subject
* Grade the assignment with AI
* Download a PDF report

From a technical perspective, the application works.

However, from a user's perspective, the experience can still be improved.

Imagine clicking **Grade Assignment** on a 20-page assignment.

Nothing appears to happen.

After several seconds, the feedback suddenly appears.

During that time, the teacher might wonder:

* Did I click the button?
* Is the application still working?
* Has it frozen?
* Should I click the button again?

Professional applications constantly communicate with their users.

They explain what they're doing.

They show progress.

They handle errors gracefully.

They prevent accidental mistakes.

In this chapter, we'll transform Markly from a working prototype into a polished application suitable for everyday classroom use.

We'll add:

* Status messages
* Progress indicators
* Loading spinners
* Button disabling
* Better validation
* Error handling
* Cleaner layouts
* Better feedback presentation

None of these improvements change the AI itself.

Instead, they make the application feel significantly more professional.

---

# Thinking Like a User

When developers test their own software, they already know what's happening behind the scenes.

Users don't.

Consider this sequence.

```text
Teacher
    │
Clicks Grade
    │
Nothing Happens
    │
Waits...
    │
Still Nothing...
```

Eventually,

```text
Feedback Appears
```

Technically everything worked.

Psychologically it feels broken.

Instead, the application should constantly communicate.

```text
Teacher
    │
Clicks Grade
    │
▼

Reading Assignment...

▼

Sending to AI...

▼

Generating Feedback...

▼

Creating PDF...

▼

Done!
```

Notice how much more reassuring this feels.

---

# Adding a Status Area

Let's create a dedicated status message.

Near the top of `app.py`, add:

```python
status = pn.pane.Alert(

    "Ready.",

    alert_type="primary"

)
```

Unlike a Markdown pane,

an **Alert** is designed to communicate status.

Panel supports several alert types.

| Alert   | Meaning                   |
| ------- | ------------------------- |
| primary | General information       |
| success | Completed successfully    |
| warning | Something needs attention |
| danger  | Error                     |

This gives us a simple way to keep teachers informed.

---

# Updating Status Throughout the Workflow

Instead of only updating the feedback area,

we'll also update the status.

For example,

```python
status.object = "Reading assignment..."
```

After extraction,

```python
status.object = "Sending assignment to AI..."
```

When the AI finishes,

```python
status.object = "Generating report..."
```

Finally,

```python
status.object = "Completed."
status.alert_type = "success"
```

Now the teacher always knows what's happening.

---

# Preventing Multiple Clicks

One common problem with AI applications is repeated button presses.

Imagine a teacher clicking

```text
Grade Assignment
```

five times.

The application might accidentally send five identical requests.

That wastes:

* API credits
* processing time
* bandwidth

Instead,

disable the button while grading.

```python
grade_button.disabled = True
```

When everything finishes,

```python
grade_button.disabled = False
```

The workflow becomes

```text
Click Button

↓

Button Disabled

↓

AI Processing

↓

Button Enabled
```

Simple,

but extremely effective.

---

# Showing a Loading Spinner

Status messages are useful,

but a visual indicator is even better.

Panel includes a loading spinner.

Create one.

```python
spinner = pn.indicators.LoadingSpinner(

    value=False,

    width=40,

    height=40
)
```

Initially,

the spinner isn't visible.

When grading begins,

```python
spinner.value = True
```

When grading finishes,

```python
spinner.value = False
```

Now teachers immediately know that work is in progress.

---

# Handling Missing Uploads

Currently,

our application checks whether a file exists.

```python
if upload.value is None:
```

Let's make the error message more helpful.

Instead of

```text
Please upload a file.
```

display

```python
feedback.object = """
## No Assignment Uploaded

Please upload a PDF, Word document,
or image before clicking
**Grade Assignment**.
"""

status.object = "No assignment uploaded."

status.alert_type = "warning"
```

Small improvements like this reduce user frustration.

---

# Handling Unsupported File Types

Suppose someone uploads

```text
music.mp3
```

or

```text
video.mp4
```

Our helper already raises

```python
ValueError
```

Let's catch it.

```python
try:

    assignment = extract_text_from_file(...)

except ValueError as e:

    feedback.object = str(e)

    status.object = "Unsupported file."

    status.alert_type = "danger"

    return
```

Now the application fails gracefully instead of crashing.

---

# Handling API Errors

Network problems happen.

API services occasionally become unavailable.

Users may accidentally enter an invalid API key.

Instead of showing a stack trace,

display a friendly message.

```python
try:

    result = grade_assignment(...)

except Exception as e:

    feedback.object = f"""
## AI Error

Unable to contact the AI service.

Details:

{e}
"""

    status.object = "AI request failed."

    status.alert_type = "danger"

    return
```

Professional software always anticipates failure.

---

# Always Clean Up

Notice something.

Our grading function now has many places where it can return early.

If we're not careful,

the spinner might continue spinning forever.

Or

the button might remain disabled.

Instead,

use

```python
finally:
```

```python
try:

    ...

finally:

    spinner.value = False

    grade_button.disabled = False
```

The `finally` block always executes,

whether the operation succeeds or fails.

This is an important programming technique whenever resources need to be cleaned up.

---

# Improving the Feedback Display

At the moment,

the AI returns one long Markdown document.

We can improve readability by placing the feedback inside a scrollable container.

```python
feedback = pn.pane.Markdown(

    "",

    height=500,

    sizing_mode="stretch_width"
)
```

Long reports no longer make the page grow indefinitely.

---

# Organizing the Layout

Our interface currently places everything in one long column.

Instead,

let's separate controls from results.

```python
controls = pn.Column(

    upload,

    subject,

    grade_button,

    download
)
```

```python
results = pn.Column(

    status,

    spinner,

    feedback
)
```

Finally,

combine them.

```python
app = pn.Row(

    controls,

    results
)
```

The application now resembles professional desktop software.

```text
+------------------------------------------------------+

Upload Assignment        Feedback

Subject                  ------------------

Grade Button             AI Response

Download PDF

                         ...

+------------------------------------------------------+
```

The controls remain visible while teachers read the feedback.

---

# Displaying Assignment Information

Teachers often forget which assignment they uploaded.

Let's display some metadata.

```python
details = pn.pane.Markdown("")
```

After uploading,

update it.

```python
details.object = f"""
### Assignment

**Filename**

{upload.filename}

**Subject**

{subject.value}
"""
```

Now the interface provides useful context throughout the grading process.

---

# Improving Visual Hierarchy

People naturally scan pages from top to bottom.

Organize the interface accordingly.

```text
Application Title

Application Description

----------------------------

Upload Assignment

Choose Subject

Grade Assignment

Download PDF

----------------------------

Status

----------------------------

Feedback
```

A clean visual hierarchy makes software feel much easier to use, even when the functionality hasn't changed.

---

# Bringing Everything Together

At this point, your grading callback might follow a structure like this:

```python
def grade(event):

    grade_button.disabled = True
    spinner.value = True

    status.object = "Reading assignment..."
    status.alert_type = "primary"

    try:

        # Read assignment

        # Send to AI

        # Generate report

        # Update feedback

        status.object = "Grading complete."
        status.alert_type = "success"

    except Exception as e:

        status.object = "An error occurred."
        status.alert_type = "danger"

        feedback.object = str(e)

    finally:

        spinner.value = False
        grade_button.disabled = False
```

Notice how much easier this is to follow.

The application's state changes are clearly communicated at every stage.

---

# Current Architecture

Although we haven't added any new AI capabilities, the application's overall workflow has become much more robust.

```text
                    Teacher
                       │
                       ▼
              Upload Assignment
                       │
                       ▼
            Validate Assignment
                       │
                       ▼
           Display Status Updates
                       │
                       ▼
         Disable Controls & Show Spinner
                       │
                       ▼
              AI Grading Pipeline
                       │
                       ▼
          Generate PDF Report
                       │
                       ▼
        Enable Controls & Show Results
```

These user experience improvements are often overlooked in AI tutorials, but they make a substantial difference in real-world use. A responsive interface that communicates clearly and handles errors gracefully builds confidence and reduces frustration.

In the next instalment, we'll tackle one of the most interesting enhancements to Markly: **automatic subject detection**. Instead of asking teachers to manually select "Mathematics," "English," or "Programming," we'll use AI to analyze the uploaded assignment and determine the most appropriate teacher persona automatically. This will make the grading workflow even smoother while introducing another practical application of LLMs: classification.
