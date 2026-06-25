## 1. Panel imports and setup

```python
import panel as pn
import json
```

### Why this block exists
This block brings in the UI framework and the JSON parser. `panel` builds the interactive web app, while `json` is needed later to decode the AI’s structured markup response.

### Python concepts used
- `import` loads modules.
- `panel as pn` gives the library a short alias.
- `json` is the standard library module for working with JSON strings and dictionaries.

### Pattern analysis
This is the **application front-end setup**. It prepares the tools needed to build the UI and process structured AI output.

### What if
Remove `json` and the markup parsing step later will fail, because the app will no longer be able to decode the model’s JSON response.

***

## 2. Project module imports

```python
from utils import extract_text_from_file, image_to_base64
from engine import (
    detect_subject,
    extract_grade,
    grade_image_with_markup,
    judge_assignment,
)
from personas import PERSONAS
from report import create_pdf_report, create_marked_pdf
from storage import add_record, get_student_history
from rubrics import RUBRICS
from markup import draw_teacher_markup
```

### Why this block exists
These imports connect the UI to the rest of the Markly system. The app does not do file parsing, grading, report generation, or image annotation itself; it delegates those jobs to specialized modules.

### Python concepts used
- `from module import ...` pulls in specific functions or objects.
- Parentheses allow multiline imports for readability.
- This is a modular design, where each file has one responsibility.

### Pattern analysis
This is a **layered architecture**. The UI layer sits on top, and the heavy logic lives in supporting modules.

### What if
Remove `create_marked_pdf` and the image workflow would still grade assignments, but it would lose the final PDF export step.

***

## 3. Panel extension

```python
pn.extension(sizing_mode="stretch_width")
```

### Why this block exists
This initializes Panel so the widgets and layouts render correctly in the browser. The `sizing_mode="stretch_width"` setting makes components fill the available horizontal space more naturally.

### Python concepts used
- Function call with a keyword argument.
- Panel initialization usually happens once at startup.

### Pattern analysis
This is a **framework bootstrap** step. It configures the UI library before building the app layout.

### What if
Change the sizing mode or remove it and compare how the layout behaves on different screen sizes.

***

## 4. Custom CSS styling

```python
pn.config.raw_css.append("""
...
""")
```

### Why this block exists
This adds custom styling so the app looks like a polished grading interface rather than a plain default Panel page. It defines the paper-like left pane, control pane, grade style, and status messages.

### Python concepts used
- Triple-quoted string holds raw CSS.
- `.append(...)` adds new CSS to Panel’s config list.

### Pattern analysis
This is **presentation-layer customization**. The logic stays in Python, while the look and feel are controlled with CSS.

### What if
Remove the CSS and the app will still work, but it will look much less polished and less teacher-like.

***

## 5. Title pane

```python
title = pn.pane.Markdown(
    "## 🔴 Markly\n*AI-powered red-pen grading*",
    styles={"margin-bottom": "0"},
)
```

### Why this block exists
This creates the app title shown in the right panel. It gives the interface a clear identity and tells the user what the app does.

### Python concepts used
- `pn.pane.Markdown` renders Markdown as formatted text.
- `styles={...}` applies inline style rules.

### Pattern analysis
This is a **UI content component**. It is not interactive; it just presents information.

### What if
Change the text to a simpler title and observe how the app’s tone changes.

***

## 6. Input widgets

```python
student_name = pn.widgets.TextInput(...)
upload = pn.widgets.FileInput(...)
subject_select = pn.widgets.Select(...)
grade_button = pn.widgets.Button(...)
```

### Why this block exists
These widgets collect the user’s input: student name, assignment file, subject choice, and the button to start grading. They are the app’s main control surface.

### Python concepts used
- Object construction with keyword arguments.
- Widgets are stateful UI objects.
- `options=list(PERSONAS.keys())` uses a dictionary’s keys to populate the subject list.

### Pattern analysis
This is a **form interface** pattern. The app gathers input first, then processes it when the button is clicked.

### What if
Add another widget, such as a rubric selector, and see how the workflow becomes more flexible.

***

## 7. Preview pane components

```python
paper_heading = pn.pane.Markdown(...)
paper_preview = pn.pane.PNG(...)
paper_placeholder = pn.pane.Markdown(...)
```

### Why this block exists
These pieces control the left-side “paper” area. Before grading, the placeholder is shown. After grading an image, the annotated preview replaces it.

### Python concepts used
- `visible=True/False` controls whether something is shown.
- `pn.pane.PNG` displays image bytes in the browser.
- Markdown panes are used for headings and placeholder text.

### Pattern analysis
This is a **conditional display** pattern. The visible component changes depending on the workflow state.

### What if
Set `paper_placeholder.visible = False` at startup and see how the left pane changes from informative to blank.

***

## 8. Left pane layout

```python
left_pane = pn.Column(
    paper_heading,
    paper_placeholder,
    paper_preview,
    css_classes=["markly-paper-pane"],
    width=570,
    scroll=True,
)
```

### Why this block exists
This combines the paper heading, placeholder, and image preview into one vertical column. It forms the visual output side of the app.

### Python concepts used
- `pn.Column(...)` stacks components vertically.
- `css_classes=[...]` attaches a custom CSS class.
- `scroll=True` allows overflow content to scroll.

### Pattern analysis
This is a **layout composition** pattern. Smaller UI elements are assembled into one coherent panel.

### What if
Change `width=570` and see how it affects balance between the left and right panes.

***

## 9. Status, feedback, and download

```python
status = pn.pane.Markdown(...)
feedback = pn.pane.Markdown(...)
download = pn.widgets.FileDownload(...)
```

### Why this block exists
This section manages the app’s output feedback. `status` shows short operational updates, `feedback` shows the AI’s response, and `download` gives the user a file to save.

### Python concepts used
- Markdown panes for text output.
- `FileDownload` is a widget that serves a file to the browser.
- `disabled=True` and `visible=False` keep the download hidden until ready.

### Pattern analysis
This is a **progressive disclosure** pattern. The download option appears only after the system has generated a result.

### What if
Make `download.visible = True` from the start and notice that the UI becomes less guided.

***

## 10. Right pane layout

```python
right_pane = pn.Column(
    title,
    pn.layout.Divider(),
    pn.pane.Markdown("**Student**"),
    student_name,
    pn.pane.Markdown("**Assignment**"),
    upload,
    pn.pane.Markdown("**Subject**"),
    subject_select,
    pn.Spacer(height=8),
    grade_button,
    status,
    pn.layout.Divider(),
    feedback,
    pn.Spacer(height=12),
    download,
    css_classes=["markly-controls-pane"],
    width=380,
    scroll=True,
)
```

### Why this block exists
This assembles the input form and output area into one control column. The order of elements matches the user’s workflow: identify student, upload assignment, select subject, then grade.

### Python concepts used
- `pn.Spacer` adds spacing.
- `pn.layout.Divider()` inserts a horizontal separator.
- `pn.Column` stacks everything vertically in order.

### Pattern analysis
This is a **step-by-step form flow**. The layout mirrors the expected sequence of user actions.

### What if
Move the button above the upload field and see how that affects usability.

***

## 11. Grading callback: input validation

```python
async def grade_assignment(event):
    if upload.value is None or not student_name.value.strip():
        feedback.object = (
            "### ⚠️ Missing input\n"
            "Please upload an assignment **and** enter a student name."
        )
        return
```

### Why this block exists
This function runs when the user clicks the grading button. The first job is to make sure the required data exists before doing any expensive AI work.

### Python concepts used
- `async def` defines an async callback.
- `if ... return` is early validation.
- `.strip()` removes whitespace from the student name.

### Pattern analysis
This is a **guard clause**. The function stops immediately if required inputs are missing.

### What if
Remove this check and try clicking the button with empty input. You’ll see why validation protects the rest of the workflow.

***

## 12. UI reset before processing

```python
    paper_preview.visible = False
    paper_preview.object = None
    paper_placeholder.visible = True
    paper_heading.object = "### 📄 Marked Assignment\n⏳ Processing…"
    download.disabled = True
    download.visible = False
    status.object = ""
    feedback.object = "### Feedback\n⏳ Grading in progress…"
```

### Why this block exists
Before starting a new grading run, the app clears the old preview and shows a processing state. This prevents stale results from confusing the user.

### Python concepts used
- Widget state is updated by assigning to `.object`, `.visible`, and `.disabled`.
- These are reactive UI properties.

### Pattern analysis
This is a **state reset** pattern. The app moves into a clean “working” state before doing async work.

### What if
Leave the old preview visible during processing and see how much harder it becomes to tell whether the current assignment is done.

***

## 13. File type detection and extraction

```python
    try:
        filename = upload.filename.lower()
        is_image = filename.endswith((".png", ".jpg", ".jpeg"))

        if is_image:
            image_base64 = image_to_base64(upload.value)
            content = "[IMAGE_ASSIGNMENT]"
        else:
            content = extract_text_from_file(upload.value, upload.filename)
```

### Why this block exists
The app needs different handling for image files and text-based files. Images go through the vision pipeline, while PDFs and DOCX files are converted to text.

### Python concepts used
- `.lower()` normalizes file names.
- `.endswith(tuple)` checks multiple extensions at once.
- Function calls delegate file parsing and encoding.

### Pattern analysis
This is a **branching input pipeline**. Different file types take different routes through the system.

### What if
Treat a `.png` file as text on purpose and see why that would break the downstream grading logic.

***

## 14. Subject detection and fallback

```python
        predicted_subject = await detect_subject(content)
        if predicted_subject not in PERSONAS:
            predicted_subject = subject_select.value

        rubric = RUBRICS.get(predicted_subject, "1. Overall Quality (10 points)")
        status.object = (
            f'<div class="markly-status">Detected subject: <b>{predicted_subject}</b></div>'
        )
```

### Why this block exists
The app asks the AI to identify the subject automatically. If the model returns something unexpected, it falls back to the subject chosen by the user.

### Python concepts used
- `await` waits for the async subject detector.
- `if predicted_subject not in PERSONAS` checks validity.
- `.get(..., default)` safely fetches a rubric.

### Pattern analysis
This is a **prediction plus fallback** pattern. The AI makes a guess, but the UI still keeps a manual override in reserve.

### What if
Change the fallback to a fixed subject and compare how that affects reliability.

***

## 15. Image workflow

```python
        if is_image:
            paper_heading.object = "### 📄 Marked Assignment\n⏳ Annotating paper…"
            markup_json_str = await grade_image_with_markup(image_base64, predicted_subject)
```

### Why this block exists
Image assignments need visual annotations, not just text feedback. This step asks the vision model for detailed markup instructions.

### Python concepts used
- Another async API call.
- A JSON string is expected back from the model.

### Pattern analysis
This is the **vision grading branch** of the workflow.

### What if
Replace `grade_image_with_markup(...)` with `grade_image(...)` and see the difference between annotated output and plain feedback.

***

## 16. JSON parsing

```python
            try:
                markup_data = json.loads(markup_json_str)
            except json.JSONDecodeError:
                markup_data = {}
```

### Why this block exists
AI output may not always be valid JSON, even when asked. This code tries to parse it and falls back to an empty dictionary if parsing fails.

### Python concepts used
- `json.loads()` converts JSON text into a Python dictionary.
- `try/except` handles malformed output gracefully.

### Pattern analysis
This is **defensive parsing**. The app expects the model to make mistakes sometimes.

### What if
Remove the `except` block and a bad JSON response would crash the whole grading run.

***

## 17. Pulling markup fields

```python
            overall_feedback_text = markup_data.get("overall_feedback", "")
            grade_val = markup_data.get("grade", "N/A")
            marks = markup_data.get("marks", [])
```

### Why this block exists
The parsed JSON may contain feedback, a grade, and a list of annotations. This extracts those fields with safe defaults.

### Python concepts used
- Dictionary `.get(...)` with default values.
- Empty string and empty list are used as fallback values.

### Pattern analysis
This is **safe data extraction** from semi-structured AI output.

### What if
Change the default `marks` from `[]` to `None` and notice that later list processing would need extra checks.

***

## 18. Drawing teacher markup

```python
            marked_buf = draw_teacher_markup(upload.value, markup_json_str)

            marked_buf.seek(0)
            paper_preview.object = marked_buf.read()
            paper_preview.visible = True
            paper_placeholder.visible = False
            paper_heading.object = f"### 📄 Marked Assignment   `{grade_val}`"
```

### Why this block exists
The app converts the JSON markup into actual visible teacher-style annotations on the image. Then it updates the preview pane so the user can see the marked paper.

### Python concepts used
- `seek(0)` resets the file pointer before reading.
- `read()` gets the binary image data.
- `.object` on the PNG pane accepts raw image bytes.

### Pattern analysis
This is the **rendering step**. The annotation instructions become a visual result.

### What if
Skip `seek(0)` and the preview may appear blank or incomplete because the buffer pointer is already at the end.

***

## 19. Building the PDF for images

```python
            corrections = [m for m in marks if m.get("type") == "correction"]
            marked_buf.seek(0)
            pdf_buf = create_marked_pdf(
                student=student_name.value,
                subject=predicted_subject,
                filename=upload.filename,
                marked_image_buffer=marked_buf,
                overall_feedback=overall_feedback_text,
                grade=grade_val,
                corrections=corrections,
            )
```

### Why this block exists
The app also creates a downloadable PDF report. It includes the marked image, summary feedback, grade, and corrections.

### Python concepts used
- List comprehension filters correction marks.
- Keyword arguments make the PDF builder call readable.

### Pattern analysis
This is a **report generation** step, separate from the live preview.

### What if
Include all mark types instead of only corrections and see how the PDF report becomes denser.

***

## 20. Preparing download output

```python
            download.file = pdf_buf
            download.filename = f"marked_{upload.filename.rsplit('.', 1)[0]}.pdf"
            download.label = "⬇ Download Marked Assignment (PDF)"
```

### Why this block exists
This connects the generated PDF to the download widget and gives the file a meaningful name.

### Python concepts used
- f-strings build filenames dynamically.
- `rsplit('.', 1)` removes the file extension safely.

### Pattern analysis
This is a **dynamic output binding** pattern.

### What if
Change the filename format and see how that affects the user’s downloaded file name.

***

## 21. Human-readable result text

```python
            lines = [f"**Grade: {grade_val}**"]
            if overall_feedback_text:
                lines += ["", overall_feedback_text]
            if corrections:
                lines += ["", "**Corrections:**"]
                for m in corrections:
                    if m.get("text"):
                        lines.append(f"- {m['text']}")
            result = "\n".join(lines)
```

### Why this block exists
This builds the visible feedback text for the UI. It formats the grade, overall feedback, and correction notes into a readable block.

### Python concepts used
- Lists are used as text buffers.
- `.join(...)` combines lines into a single Markdown string.
- `if` checks prevent empty content from being added.

### Pattern analysis
This is a **presentation formatting** step. It turns structured data into readable text.

### What if
Add a section for “Praise” and compare how the tone changes.

***

## 22. Text assignment branch

```python
        else:
            feedback.object = "### Feedback\n⏳ Evaluating assignment…"
            result = await judge_assignment(content, rubric)
            grade_val = extract_grade(result)
```

### Why this block exists
Non-image files are handled as plain text. The app sends the extracted content and rubric to the text grader, then tries to pull a grade from the response.

### Python concepts used
- Branching with `else`.
- Async call to the judge function.
- Regex-based grade extraction.

### Pattern analysis
This is the **text grading branch** of the same workflow.

### What if
Use a different rubric and observe how the feedback changes.

***

## 23. PDF report for text assignments

```python
            pdf_buf = create_pdf_report(
                student=student_name.value,
                subject=predicted_subject,
                filename=upload.filename,
                feedback=result,
            )
```

### Why this block exists
Text assignments do not need image markup, but they still get a clean PDF report. This keeps the output consistent across file types.

### Python concepts used
- Keyword arguments.
- Buffer-based PDF output.

### Pattern analysis
This is a **shared output format** pattern. Different input paths still converge into a common reporting format.

### What if
Add the grade to the PDF title or header and see how that improves readability.

***

## 24. Text assignment display

```python
            paper_heading.object = (
                "### 📄 Assignment\n"
                "_Text assignments don't have visual annotations._"
            )
```

### Why this block exists
The app tells the user that text files will not show red-pen markup. This avoids confusion when the left pane does not display an image.

### Python concepts used
- Multiline string assignment.
- Markdown italics via underscores.

### Pattern analysis
This is a **contextual UI message**. It explains the current branch of the workflow.

### What if
Change the message to mention the PDF report and see how much clearer the UX becomes.

***

## 25. Finalization and persistence

```python
        feedback.object = f"### Feedback\n{result}"
        add_record(student_name.value, predicted_subject, grade_val, result)

        download.disabled = False
        download.visible = True
```

### Why this block exists
Once grading is complete, the app shows the final feedback, saves the record to storage, and enables the download button.

### Python concepts used
- Widget properties are updated directly.
- `add_record(...)` writes a history entry.

### Pattern analysis
This is the **completion step**. It closes the workflow by displaying results and saving them.

### What if
Comment out `add_record(...)` and the UI will still work, but you lose history tracking.

***

## 26. Error handling

```python
    except Exception:
        import traceback
        feedback.object = f"### ❌ Error\n```\n{traceback.format_exc()}\n```"
        download.disabled = True
        download.visible = False
        status.object = ""
        paper_heading.object = "### 📄 Marked Assignment"
```

### Why this block exists
If anything goes wrong, the app catches the error and displays the traceback instead of crashing silently. It also resets the UI to a safe state.

### Python concepts used
- Broad `except Exception` catches most runtime issues.
- `traceback.format_exc()` turns the exception into readable text.

### Pattern analysis
This is a **fail-safe recovery** block.

### What if
Replace the broad exception with a narrower one and see how much more specific your error handling becomes.

***

## 27. Event binding and app serving

```python
grade_button.on_click(grade_assignment)

app = pn.Row(
    left_pane,
    right_pane,
    sizing_mode="stretch_width",
)

app.servable()
```

### Why this block exists
This connects the grading function to the button click, assembles the two-column layout, and exposes the app so Panel can serve it in the browser.

### Python concepts used
- `on_click(...)` binds a callback to a widget event.
- `pn.Row(...)` arranges panes horizontally.
- `servable()` makes the app deployable.

### Pattern analysis
This is the **application wiring** stage. It connects the UI event to the workflow and publishes the final interface.

### What if
Swap `pn.Row` for `pn.Column` and see how the app becomes vertically stacked instead of side by side.

## How the design fits together

This file is the **controller layer** of the Markly app. It does not parse files, generate PDFs, or annotate images itself. Instead, it coordinates the user interface and delegates work to the other modules.

The important idea is the separation between:
- **Prompt construction**: building the instructions sent to AI.
- **Async API calling**: sending those instructions efficiently and waiting for results.
- **Orchestration functions**: combining helpers into one end-to-end workflow.

`get_ai_response_concurrently()` is especially important because it gives the system a fast, resilient way to pick the first successful AI response. In this app, it acts as the model-racing engine behind the text grading path.
