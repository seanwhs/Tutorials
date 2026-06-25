# Part I — Foundations

# Lesson 1.6 — Installing Panel and Setting Up Your Development Environment

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what a development environment is.
> * Install Python correctly.
> * Understand what `pip` is.
> * Understand what a virtual environment is.
> * Create your first Panel project.
> * Install Panel and its dependencies.
> * Verify that your installation is working correctly.
> * Understand the purpose of every command you execute.

---

# Introduction

Until now, we've focused on **understanding** Panel.

Now it's time to start **building**.

But before we can create our SGX Stock Monitor, we need to prepare our development environment.

Many beginners try to skip this step.

Unfortunately, that often leads to mysterious errors later.

Taking the time to understand your development environment now will save you many hours of troubleshooting in the future.

---

# What Is a Development Environment?

## What?

A **development environment** is the collection of software and tools you use to write, run, test, and debug your programs.

Think of it as your programming workspace.

A carpenter has:

* a workbench
* a saw
* a drill
* measuring tools

A Python developer has:

* Python
* an editor or IDE
* libraries
* a terminal
* package management tools

Together, these form your development environment.

---

# Our Development Environment

Throughout this tutorial, we'll use the following tools.

| Tool                | Purpose                        |
| ------------------- | ------------------------------ |
| Python              | Programming language           |
| Visual Studio Code  | Code editor                    |
| Terminal            | Running commands               |
| pip                 | Installing Python packages     |
| Virtual Environment | Isolating project dependencies |
| Panel               | Building web applications      |

Later, we'll add:

* Pandas
* Plotly
* SQLite
* aiohttp

But for now, we'll keep things simple.

---

# Understanding Python

Before installing Panel, let's briefly discuss Python itself.

Panel is **not** a standalone application.

It is a **Python library**.

This means Panel cannot run by itself.

It runs **inside Python**.

Conceptually:

```text
Your Computer

│

├── Python

│     │

│     ├── Panel

│     ├── Pandas

│     ├── Plotly

│     └── Other Libraries
```

Think of Python as the operating system for your Python libraries.

Without Python, Panel has nowhere to run.

---

# Step 1 — Installing Python

If Python is not already installed, download the latest stable version from the official Python website.

During installation, ensure that the installer adds Python to your system's PATH. This allows you to run Python from the terminal without specifying its full installation path.

> **Teacher's Note**
>
> Always download Python from the official Python website. Third-party installers may include outdated versions or additional software you don't need.

---

# Verifying the Installation

Open a terminal.

Run:

```bash
python --version
```

or on some systems:

```bash
python3 --version
```

Expected output:

```text
Python 3.13.x
```

The exact version number may differ.

---

# What Is a Terminal?

Many beginners fear the terminal.

There's no need.

A terminal is simply a program that allows you to communicate directly with your computer using text commands.

Examples include:

* Windows Terminal
* PowerShell
* Command Prompt
* macOS Terminal
* Linux Terminal

Think of it as a conversation.

You type a command.

Your computer executes it.

Then it responds.

Example:

```text
You

↓

python --version

↓

Computer

↓

Python 3.13.4
```

---

# What Is `pip`?

Once Python is installed, another important tool becomes available.

`pip`

---

## What?

`pip` is Python's package manager.

---

## What Is a Package Manager?

Suppose you want to install software on your phone.

You open an app store.

Search.

Click Install.

Done.

`pip` performs a similar role.

Instead of installing phone apps,

it installs Python libraries.

Examples include:

* Panel
* Pandas
* Plotly
* NumPy
* Requests

---

# Verifying pip

Run:

```bash
pip --version
```

Example:

```text
pip 25.x
```

Again, your version may differ.

---

# Why Don't We Just Install Everything Globally?

This is one of the most important concepts in Python development.

Imagine working on two projects.

Project A requires:

```text
Pandas 2.3
```

Project B requires:

```text
Pandas 1.5
```

If you install everything globally,

the projects begin to interfere with one another.

One update might accidentally break another project.

Professional developers avoid this problem using **virtual environments**.

---

# What Is a Virtual Environment?

A virtual environment is an isolated Python environment created specifically for one project.

Instead of sharing libraries with every other Python project on your computer,

each project has its own private collection of packages.

Imagine living in an apartment building.

Each apartment has its own:

* furniture
* decorations
* appliances

Even though everyone lives in the same building,

each apartment is independent.

Virtual environments work the same way.

```text
Computer

├── Project A
│     ├── Python
│     └── Libraries
│
├── Project B
│     ├── Python
│     └── Libraries
│
└── Project C
      ├── Python
      └── Libraries
```

Each project manages its own dependencies.

---

# Why Are Virtual Environments Important?

Without virtual environments:

```text
Computer

↓

One Python

↓

One Giant Collection of Libraries

↓

Version Conflicts
```

With virtual environments:

```text
Project A

↓

Own Libraries

---------------------

Project B

↓

Own Libraries

---------------------

Project C

↓

Own Libraries
```

Everything remains isolated.

---

# Creating Our Project

Create a new folder.

```text
sgx-stock-monitor
```

Open a terminal inside that folder.

---

# Creating a Virtual Environment

Run:

```bash
python -m venv .venv
```

Let's understand every part.

---

## `python`

Run the Python interpreter.

---

## `-m`

This tells Python:

> Run a module.

Instead of executing a Python file,

Python executes one of its built-in modules.

---

## `venv`

`venv` is Python's built-in virtual environment module.

It creates isolated environments.

---

## `.venv`

This is simply the name of the folder that will contain the virtual environment.

Many developers use:

```text
.venv
```

because editors like Visual Studio Code automatically recognize it.

---

# What Happens Internally?

Running

```bash
python -m venv .venv
```

creates something like:

```text
sgx-stock-monitor/

├── .venv/
│
│   ├── Scripts/        (Windows)
│   ├── bin/            (Linux/macOS)
│   ├── Lib/
│   └── pyvenv.cfg
│
└──
```

Don't worry about every file.

Python created a miniature environment for this project.

---

# Activating the Virtual Environment

Creating the environment is only the first step.

We must now activate it.

### Windows (PowerShell)

```powershell
.venv\Scripts\Activate.ps1
```

### Windows (Command Prompt)

```cmd
.venv\Scripts\activate.bat
```

### macOS / Linux

```bash
source .venv/bin/activate
```

---

# How Do You Know It's Active?

Most terminals display the environment name.

Example:

```text
(.venv)

C:\Projects\sgx-stock-monitor>
```

The

```text
(.venv)
```

indicates that every package you install now belongs only to this project.

---

# Installing Panel

Now we're finally ready.

Run:

```bash
pip install panel
```

What happens?

```text
pip

↓

Downloads Panel

↓

Downloads Dependencies

↓

Installs Everything

↓

Ready
```

---

# What Are Dependencies?

Panel depends on many other Python libraries.

Rather than forcing you to install each one manually,

`pip` installs them automatically.

Conceptually:

```text
Panel

│

├── Bokeh

├── Param

├── Markdown

├── Tornado

└── Other Libraries
```

This process is called **dependency resolution**.

---

# Verifying the Installation

Run:

```bash
python
```

The Python interpreter starts.

Now type:

```python
import panel as pn
```

If nothing happens,

that's good!

No error means Python successfully found the Panel library.

Exit Python by typing:

```python
exit()
```

---

# Installing Future Libraries

Later in this tutorial, we'll install additional packages.

Eventually, our project will use:

```bash
pip install panel pandas plotly aiohttp
```

For now, however, we only need Panel.

Keeping the environment simple makes it easier to understand what each library contributes.

---

# Understanding `requirements.txt`

Professional Python projects often include a file named:

```text
requirements.txt
```

This file lists the project's dependencies.

Example:

```text
panel
pandas
plotly
aiohttp
```

Anyone who downloads the project can install everything with:

```bash
pip install -r requirements.txt
```

We'll create this file later as our project grows.

---

# Project Structure

At the end of this lesson, your project should look like this:

```text
sgx-stock-monitor/

├── .venv/
│
└──
```

It doesn't look like much yet.

That's perfectly normal.

We'll begin adding Python files in the next lesson.

---

# Teacher's Notes

> Beginners often rush through installation by copying commands from the internet without understanding them. While that may work initially, it becomes difficult to diagnose problems later.
>
> Throughout this tutorial, every command is explained before you execute it. Understanding *why* a command exists is just as important as knowing *what* to type.
>
> Another good habit is to create a new virtual environment for every project, even small experiments. This keeps projects isolated and makes them much easier to share with others.

---

# Common Mistakes

### ❌ Mistake 1

Installing packages without activating the virtual environment.

The packages may be installed globally instead of inside your project.

---

### ❌ Mistake 2

Deleting the `.venv` folder accidentally.

The virtual environment contains all of your installed packages. If it is deleted, you'll need to recreate it and reinstall the dependencies.

---

### ❌ Mistake 3

Trying to activate a virtual environment created for a different project.

Each project should have its own environment.

---

### ❌ Mistake 4

Assuming `pip` installs applications.

`pip` installs **Python libraries**, not standalone desktop programs.

---

# Summary

In this lesson, you learned:

* What a development environment is.
* Why Python must be installed before using Panel.
* How `pip` installs Python packages.
* Why virtual environments are important for dependency isolation.
* How to create and activate a virtual environment.
* How to install Panel.
* How to verify that the installation was successful.
* Why professional projects use a `requirements.txt` file.

Your development environment is now ready.

In the next lesson, we'll write our **first Panel program**, examine every line of code in detail, and learn how to run a Panel application for the first time. From that point onward, our SGX Stock Monitor will begin to take shape.
