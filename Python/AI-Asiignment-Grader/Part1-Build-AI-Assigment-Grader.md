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

If successful, your terminal prompt should change.

```
(venv)
```

This indicates that any libraries you install will be placed inside this project's environment rather than globally on your computer.

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
```

Alternatively, install everything at once.

```bash
pip install \
panel \
openai \
python-dotx \
python-dotenv \
pymupdf \
python-docx \
pillow \
reportlab
```

Once installation finishes, verify everything works.

```bash
pip list
```

You should see the newly installed packages.

---

## Step 1.5 Create the Project Structure

Inside your project folder, create the following files.

```
markly/

│
├── app.py
├── engine.py
├── personas.py
├── utils.py
├── .env
├── requirements.txt
└── assets/
```

Let's briefly understand the purpose of each file.

### app.py

This file contains the application's user interface.

Everything the teacher sees—including buttons, upload widgets, and grading results—will be built here.

Think of this as the "front desk" of the application.

---

### engine.py

This file communicates with the language model.

Instead of mixing AI code into the interface, we'll isolate it inside its own module.

This separation makes our application much easier to maintain.

---

### personas.py

One of Markly's unique features is that it behaves differently depending on the subject.

All of those prompts will live inside this file.

For example,

* Mathematics Teacher
* English Teacher
* Science Teacher
* Programming Instructor

Each persona instructs the AI how to evaluate assignments from that discipline.

---

### utils.py

Many tasks don't belong in the user interface or AI engine.

For example,

* Reading PDF files
* Reading DOCX files
* Converting images
* Extracting text
* Helper functions

These utility functions will be stored here.

---

### assets/

This folder stores resources used by the application.

Examples include:

* logos
* icons
* screenshots
* sample assignments

Keeping these separate helps organize the project.

---

# Step 1.6 Save Your API Key

We'll communicate with language models using OpenRouter.

Create a file named

```
.env
```

Add the following.

```text
OPENROUTER_API_KEY=your_api_key_here
```

Never hardcode API keys inside your Python source code.

Using environment variables keeps sensitive information out of your repository and makes it much safer to share your project with others.

---

# Step 1.7 Create requirements.txt

To make your project easy to install on another computer—or deploy to a cloud platform—we'll record all dependencies in a `requirements.txt` file.

Run the following command:

```bash
pip freeze > requirements.txt
```

This captures the exact versions of every installed package.

Later, anyone can recreate your environment by running:

```bash
pip install -r requirements.txt
```

This simple step is considered a best practice for Python development and is essential when deploying to services like Hugging Face Spaces.

---

# What We've Accomplished

Although we haven't written any application code yet, we've completed several important setup tasks:

* Created an isolated Python environment
* Installed all required libraries
* Organized our project into logical modules
* Secured our API key using environment variables
* Generated a `requirements.txt` file for reproducibility

Having a clean project structure from the beginning makes it much easier to expand the application as new features are added.

In the next part, we'll build our first **Panel** application, explore how Panel creates interactive web interfaces using pure Python, and create the foundation of the Markly user interface before adding file uploads and AI-powered grading.



