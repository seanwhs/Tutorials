# Markly: Build an AI-Powered Context-Aware Grading Assistant with Python

## Introduction

Grading assignments is one of the most time-consuming responsibilities for educators. Whether it's marking programming exercises, mathematics worksheets, English essays, or science reports, teachers spend countless hours reading submissions, identifying mistakes, assigning marks, and writing meaningful feedback.

Large Language Models (LLMs) provide an opportunity to assist with this process. Rather than replacing teachers, they can act as intelligent assistants that review student work, identify strengths and weaknesses, and generate detailed feedback that teachers can review before assigning a final grade.

In this tutorial, we'll build **Markly**, an AI-powered grading assistant capable of reading student assignments, understanding different subjects, and producing teacher-style feedback.

Unlike a generic chatbot, Markly adapts its behaviour depending on the subject being assessed. A mathematics teacher evaluates step-by-step calculations, while an English teacher focuses on grammar, structure, and argument quality. Throughout this tutorial, you'll learn how to teach an AI to think like different kinds of educators using carefully designed prompts.

By the end of this tutorial, you'll have built a complete application that can:

* Upload student assignments
* Read PDF documents
* Read Microsoft Word documents
* Understand scanned assignments and handwritten work using AI vision models
* Grade assignments using different teacher personas
* Generate constructive feedback
* Produce professional PDF grading reports
* Deploy the application online using Hugging Face Spaces

More importantly, you'll learn how to build a real-world AI application that combines document processing, prompt engineering, multimodal AI, and a modern Python web interface.

This tutorial assumes that you are comfortable with basic Python programming, but no prior AI experience is required.

---

# What You'll Build

Our finished application will provide teachers with a simple workflow.

1. Upload a student's assignment.
2. Choose the subject.
3. Click **Grade Assignment**.
4. Review the AI-generated feedback.
5. Export the grading report as a PDF.

Although the user interface is simple, several components work together behind the scenes.

```
                 Student Assignment
                        │
                        ▼
                 Upload to Markly
                        │
                        ▼
            Detect Assignment File Type
                        │
      ┌─────────────────┼──────────────────┐
      ▼                 ▼                  ▼
    PDF              DOCX               Image
      │                 │                  │
      └─────────────────┼──────────────────┘
                        ▼
                Extract Assignment
                        │
                        ▼
             Apply Teacher Persona
                        │
                        ▼
               Large Language Model
                        │
                        ▼
          Teacher Feedback + Grade
                        │
         ┌──────────────┴─────────────┐
         ▼                            ▼
     Display Feedback          Export PDF
```

Instead of building everything at once, we'll construct this pipeline one piece at a time.

---

# How This Tutorial Is Organized

The tutorial is divided into small milestones.

Each milestone introduces one new feature while building on the previous one.

| Part    | What You'll Build        |
| ------- | ------------------------ |
| Part 1  | Project setup            |
| Part 2  | User interface           |
| Part 3  | Uploading assignments    |
| Part 4  | Reading PDF files        |
| Part 5  | Reading DOCX files       |
| Part 6  | Reading images           |
| Part 7  | Connecting to OpenRouter |
| Part 8  | Teacher personas         |
| Part 9  | AI grading               |
| Part 10 | PDF report generation    |
| Part 11 | Deployment               |

At the end of every section, your application should still run successfully.

This incremental approach makes debugging much easier because you always know which new feature caused a problem if something stops working.

---

# Part 1 — Setting Up the Project

Before we can build Markly, we need to prepare our development environment.

## Step 1.1 Create the Project Folder

Create a new directory called **markly**.

```
markly/
```

Open this directory using your favourite code editor.

We recommend Visual Studio Code because it provides excellent Python support, integrated terminals, and Git integration.

---

## Step 1.2 Create a Virtual Environment

Python projects often depend on different library versions.

To prevent conflicts between projects, we'll create a virtual environment.

On Windows:

```bash
python -m venv venv
```

On macOS or Linux:

```bash
python3 -m venv venv
```

This creates a new folder named **venv** containing an isolated Python installation.

---

## Step 1.3 Activate the Environment

Windows

```bash
venv\Scripts\activate
```

macOS/Linux

```bash
source venv/bin/activate
```

If successful, your terminal prompt should change:

```
(venv)
```

This indicates that any libraries you install will be isolated to this project.

---

## Step 1.4 Install the Required Libraries

We'll install all the libraries needed throughout the tutorial.

```bash
pip install panel
pip install openai
pip install python-dotenv
pip install pymupdf
pip install python-docx
pip install pillow
pip install reportlab
pip install pytesseract
```

Alternatively, install everything at once:

```bash
pip install \
panel \
openai \
python-dotenv \
pymupdf \
python-docx \
pillow \
pytesseract \
reportlab
```

Once installation finishes, verify everything works:

```bash
pip list
```

You should see all installed packages listed.

---

## Step 1.5 Create the Project Structure

Inside your project folder, create the following files:

```
markly/

├── app.py
├── engine.py
├── personas.py
├── utils.py
├── .env
├── requirements.txt
└── assets/
```

### app.py

This file contains the application's user interface.

---

### engine.py

Handles communication with the language model.

---

### personas.py

Stores teacher-style grading prompts (Math, English, Science, etc.).

---

### utils.py

Handles file processing:

* PDF reading
* DOCX reading
* Image OCR
* Text extraction

---

### assets/

Stores images, icons, and sample files.

---

# Step 1.6 Save Your API Key

Create a `.env` file:

```text
OPENROUTER_API_KEY=your_api_key_here
```

Never hardcode API keys in Python files.

---

# Step 1.7 Create requirements.txt

Generate dependency list:

```bash
pip freeze > requirements.txt
```

To reinstall later:

```bash
pip install -r requirements.txt
```

---

# What We've Accomplished

Although we haven't written application logic yet, we've already:

* Created a clean project structure
* Set up a virtual environment
* Installed all required dependencies (including OCR support via `pytesseract`)
* Secured API keys properly
* Prepared reproducible deployment setup

---

In the next part, we'll build the **Panel-based user interface**, where users can upload assignments, select subjects, and trigger the grading pipeline.
