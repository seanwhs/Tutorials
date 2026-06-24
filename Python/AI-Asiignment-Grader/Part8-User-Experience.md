# Part 8 — Building a Professional User Experience

At this point, Markly is a functional AI grading assistant.

A teacher can:

* Upload an assignment
* Choose a subject
* Grade the assignment with AI
* Download a PDF report

From a technical perspective, the application works.

However, from a user's perspective, the experience can still be improved.

And now there is an important addition:

> The grading result is no longer just text on a screen — it becomes a downloadable PDF report.

This changes how users interact with the system.

---

# Why This Matters Now

Imagine clicking **Grade Assignment** on a 20-page submission.

Previously:

* You waited
* Feedback appeared in the browser

Now:

* You wait
* Feedback appears in the browser
* A **Download Report** button becomes available

This introduces a new UX concept:

> The system produces a tangible output artifact.

That means the interface must clearly communicate:

* When the report is ready
* When it can be downloaded
* What state the system is currently in

Without this clarity, users may still feel uncertain:

* “Did the PDF generate correctly?”
* “Can I download it yet?”
* “Is it still processing?”

Professional applications eliminate this ambiguity.

---

# Thinking Like a User (Revisited)

When developers test software, they see internal state changes.

Users only see the interface.

Consider the difference:

### Developer view

```text
extract → grade → generate PDF → return object
```

### Teacher view

```text
Click button → ??? → result appears
```

Now with PDF generation added, the “???” step includes more uncertainty.

We must explicitly communicate progress:

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
Creating PDF Report...

▼
Making Download Available...

▼
Done!
```

This last step is new and important:

> “Making Download Available” is a first-class UX event.

---

# Adding a Status Area (Enhanced Meaning)

We already introduced a status component.

Now we extend its meaning beyond grading into **artifact generation**.

```python
status = pn.pane.Alert(
    "Ready.",
    alert_type="primary"
)
```

During workflow, we now explicitly reflect the PDF lifecycle:

```python
status.object = "Generating PDF report..."
status.alert_type = "primary"
```

When the file is ready:

```python
status.object = "Report ready for download."
status.alert_type = "success"
```

This subtle change is important.

We are no longer just grading.

We are producing a deliverable.

---

# Updating Status Throughout the Full Workflow

The updated pipeline now looks like this:

```python
status.object = "Reading assignment..."
```

```python
status.object = "Sending assignment to AI..."
```

```python
status.object = "Generating feedback..."
```

```python
status.object = "Creating PDF report..."
```

```python
status.object = "Preparing download..."
```

```python
status.object = "Ready."
status.alert_type = "success"
```

Each stage reduces uncertainty.

Each stage builds trust.

---

# Introducing the Download State (New UX Concept)

We now add a key interface element:

```python
download = pn.widgets.FileDownload(
    file=None,
    filename="markly_report.pdf",
    button_type="success"
)
```

But more importantly, this widget is **state-dependent**.

It should only become active when:

> The PDF report has been successfully generated.

---

# Enabling the Download Button

Before grading:

```python
download.file = None
download.disabled = True
```

After PDF generation:

```python
download.file = pdf_bytes
download.disabled = False
```

Now the user flow becomes explicit:

```text
Before grading:
[ Download Report ] ❌ disabled

After grading:
[ Download Report ] ✅ enabled
```

This removes guesswork completely.

---

# Preventing User Confusion

Without proper UX design, this problem appears:

* Feedback is visible
* But download is not yet ready
* User clicks download too early

So we reinforce clarity with status + button state sync:

```python
status.object = "Preparing downloadable report..."
download.disabled = True
```

Only when everything is complete:

```python
status.object = "Report ready."
download.disabled = False
status.alert_type = "success"
```

---

# Spinner Behavior (Now Covers PDF Generation)

The spinner now represents the entire pipeline, not just AI grading.

```python
spinner = pn.indicators.LoadingSpinner(
    value=False,
    width=40,
    height=40
)
```

Workflow:

```python
spinner.value = True
```

Stops only after:

* AI response complete
* PDF generated
* Download ready

```python
spinner.value = False
```

This ensures users never see a “half-finished” state.

---

# Handling Missing or Partial Outputs

We now have two outputs:

1. Feedback (text)
2. PDF (file)

So failure handling must distinguish between them.

### Missing upload

```python
status.object = "No assignment uploaded."
status.alert_type = "warning"
```

### AI failure

```python
status.object = "AI processing failed."
status.alert_type = "danger"
download.disabled = True
```

### PDF generation failure

```python
status.object = "Failed to generate PDF report."
status.alert_type = "danger"
download.disabled = True
```

This separation is important:

> Not all failures are equal anymore.

---

# Updated Error Handling Pattern

The grading function now becomes more structured:

```python
def grade(event):

    grade_button.disabled = True
    spinner.value = True
    download.disabled = True

    status.object = "Processing..."
    status.alert_type = "primary"

    try:

        # 1. Read assignment
        # 2. Send to AI
        # 3. Generate feedback
        # 4. Create PDF report

        status.object = "Finalizing report..."
        status.alert_type = "primary"

        # Enable download
        download.file = pdf_bytes

        status.object = "Report ready for download."
        status.alert_type = "success"

    except Exception as e:

        status.object = "An error occurred."
        status.alert_type = "danger"

        feedback.object = str(e)

    finally:

        spinner.value = False
        grade_button.disabled = False
```

Notice the key improvement:

> The download state is now part of the lifecycle.

---

# Improving Feedback + Download Relationship

The feedback pane and PDF are now two representations of the same data:

| Output              | Purpose               |
| ------------------- | --------------------- |
| Feedback (Markdown) | Immediate readability |
| PDF Report          | Persistent document   |

So we structure UI expectations clearly:

* Feedback = instant view
* PDF = shareable artifact

This distinction should be communicated in the UI or documentation.

---

# Organizing the Layout (Updated)

The layout now reflects a complete workflow:

```python
controls = pn.Column(
    upload,
    subject,
    grade_button,
    download
)

results = pn.Column(
    status,
    spinner,
    feedback
)

app = pn.Row(
    controls,
    results
)
```

Now the download button logically belongs with input controls:

> Because it is part of the action lifecycle, not the result display.

---

# Visual UX Flow (Updated)

```text
Application Start
       │
       ▼
Upload Assignment
       │
       ▼
Select Subject
       │
       ▼
Click Grade
       │
       ▼
Status Updates + Spinner
       │
       ▼
AI Processing
       │
       ▼
PDF Generated
       │
       ▼
Download Button Enabled
       │
       ▼
Teacher Downloads Report
```

This is now a complete end-to-end system.

---

# Key UX Principle Introduced in This Part

With the addition of PDF export, Markly now demonstrates a core principle:

> A good AI application does not just generate output — it delivers usable artifacts with clear lifecycle states.

This includes:

* Progress communication
* State transitions
* Action gating (disabled buttons)
* Artifact availability (download readiness)

---

# Bringing It All Together

The system is no longer just:

```text
Upload → AI → Feedback
```

It is now:

```text
Upload → Validate → AI Grade → Generate Feedback → Create PDF → Enable Download → Deliver Report
```

Each stage has:

* A visible status
* A clear transition
* A predictable outcome

---

In the next part, we’ll make Markly even more intelligent by introducing **automatic subject detection**, allowing the system to infer whether an assignment is Mathematics, English, or Programming without manual selection — using the LLM itself as a classifier.
