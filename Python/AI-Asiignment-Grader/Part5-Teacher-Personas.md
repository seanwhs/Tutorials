# Part 5 — Teaching the AI How to Grade: Building Teacher Personas

At the end of the previous chapter, Markly could successfully grade assignments using a Large Language Model.

While this is exciting, you'll probably notice something important after grading a few different assignments.

Whether you upload:

* a mathematics worksheet,
* a history essay,
* a Python programming exercise, or
* a science report,

the AI produces feedback that feels... almost identical.

It might say things like:

> "Good work overall."

or

> "Consider improving clarity."

These comments are not necessarily wrong, but they aren't how real teachers grade.

A mathematics teacher rarely comments on "writing style."

An English teacher usually doesn't discuss "algorithmic efficiency."

A programming instructor isn't interested in the poetic flow of your essay.

Different subjects require different ways of thinking.

One of the biggest strengths of Large Language Models is that we can **change their behavior simply by changing the instructions we give them.**

In this chapter, we'll teach our AI how to think like different teachers.

This is one of the defining features of Markly.

---

# What is a Persona?

A **persona** is simply a set of instructions that tells the AI who it should pretend to be.

Instead of asking:

> Grade this assignment.

we'll ask:

> You are a senior mathematics teacher with twenty years of classroom experience. Carefully evaluate each mathematical step, identify conceptual errors, and provide constructive feedback.

Those two prompts produce dramatically different responses.

Think of the persona as giving the AI a role to play.

```text
Without Persona

AI
│
▼
General Chatbot

-------------------------

With Persona

AI
│
▼
Experienced Mathematics Teacher
```

The underlying language model hasn't changed.

Only the instructions have changed.

This technique is known as **prompt engineering**, and it is one of the most powerful ways to customize AI behavior.

---

# Why Separate Personas Into Their Own File?

Currently, our grading prompt is hardcoded inside `engine.py`.

```python
prompt = f"""
Please grade this assignment...
"""
```

This works, but it becomes difficult to maintain.

Imagine supporting ten different school subjects.

Your AI engine would quickly become cluttered with hundreds of lines of prompts.

Instead, we'll create a dedicated file called

```text
personas.py
```

This keeps our project organized.

```
markly/

app.py
engine.py
utils.py
personas.py
```

Each module now has one clear responsibility.

| File        | Responsibility   |
| ----------- | ---------------- |
| app.py      | User Interface   |
| utils.py    | File Processing  |
| engine.py   | AI Communication |
| personas.py | Teacher Personas |

This is another example of good software engineering.

---

# Creating Our First Persona

Open

```text
personas.py
```

Let's begin with a Mathematics teacher.

```python
MATHEMATICS_PERSONA = """
You are an experienced secondary school mathematics teacher.

Your responsibilities are:

- Carefully examine every calculation.
- Check each working step.
- Identify arithmetic mistakes.
- Identify conceptual misunderstandings.
- Reward correct mathematical reasoning.
- Suggest how incorrect solutions can be improved.

Your feedback should contain:

## Strengths

## Mistakes

## Suggestions

## Final Grade
"""
```

Notice something important.

We're **not** telling the AI what the student's assignment is.

We're only describing **how the AI should think**.

Later, we'll combine this persona with the student's work.

---

# Why Is This Better?

Compare the following prompts.

Poor prompt:

```text
Grade this assignment.
```

Better prompt:

```text
You are an experienced mathematics teacher.

Evaluate every working step.

Check mathematical accuracy.

Reward correct reasoning.

Identify conceptual errors.

Provide constructive feedback.
```

The second prompt gives the model significantly more context.

The more context we provide, the more consistent the responses become.

---

# Building an English Teacher Persona

English teachers evaluate completely different skills.

Instead of checking calculations, they examine writing.

Add another persona.

```python
ENGLISH_PERSONA = """
You are an experienced English language teacher.

Evaluate:

- grammar
- spelling
- punctuation
- sentence structure
- vocabulary
- clarity
- organization
- strength of argument

Do not simply list grammar mistakes.

Provide constructive feedback that helps the student become a better writer.

Your report should include:

## Strengths

## Areas for Improvement

## Suggestions

## Final Grade
"""
```

Notice how different this prompt is.

The AI is now evaluating language instead of mathematics.

---

# Building a Programming Instructor Persona

Programming assignments require yet another mindset.

```python
PROGRAMMING_PERSONA = """
You are an experienced software engineering instructor.

Evaluate the student's program according to:

- correctness
- readability
- naming conventions
- modularity
- code duplication
- algorithm choice
- efficiency
- maintainability

If bugs exist,
explain why they occur.

Suggest improvements using software engineering best practices.

Do not rewrite the entire solution unless necessary.

Provide:

## Strengths

## Bugs

## Code Quality

## Suggestions

## Final Grade
"""
```

Notice that this prompt asks the AI to behave more like a code reviewer than a traditional teacher.

---

# Building a Science Teacher Persona

Science assignments focus on scientific reasoning rather than calculations alone.

```python
SCIENCE_PERSONA = """
You are an experienced science teacher.

Evaluate:

- scientific accuracy
- understanding of concepts
- explanations
- use of scientific terminology
- logical reasoning

Correct misconceptions.

Encourage curiosity while maintaining scientific accuracy.

Provide:

## Strengths

## Misconceptions

## Suggestions

## Final Grade
"""
```

Again, the grading philosophy changes.

---

# Organizing the Personas

Rather than importing each persona individually, we'll store them inside a dictionary.

At the bottom of `personas.py`, add:

```python
PERSONAS = {

    "Mathematics": MATHEMATICS_PERSONA,

    "English": ENGLISH_PERSONA,

    "Science": SCIENCE_PERSONA,

    "Programming": PROGRAMMING_PERSONA

}
```

Now retrieving a persona becomes very simple.

```python
PERSONAS["English"]
```

returns the English grading prompt.

Likewise,

```python
PERSONAS["Programming"]
```

returns the programming instructor prompt.

This design also makes it easy to add new subjects in the future.

---

# Updating the AI Engine

Now let's modify `engine.py`.

Import the personas.

```python
from personas import PERSONAS
```

Instead of hardcoding the prompt, we'll accept the subject as a parameter.

```python
def grade_assignment(
    assignment,
    subject
):
```

Next, retrieve the appropriate persona.

```python
persona = PERSONAS[subject]
```

Now update the request.

```python
messages=[

    {
        "role":"system",
        "content":persona
    },

    {
        "role":"user",
        "content":assignment
    }

]
```

This small change completely transforms how the AI behaves.

Instead of receiving generic instructions,

the model now receives subject-specific guidance.

---

# Updating the User Interface

Return to `app.py`.

Previously we ignored the dropdown menu.

Now we'll use it.

Locate this line.

```python
result = grade_assignment(
    assignment
)
```

Replace it with

```python
result = grade_assignment(

    assignment,

    subject.value

)
```

Remember,

`subject.value`

contains whatever the teacher selected.

For example,

```
Mathematics
```

or

```
Programming
```

That value is now passed directly into the grading engine.

---

# Testing Different Subjects

Let's see how dramatically personas affect the output.

Suppose we upload the exact same Python program.

If we accidentally choose **English**, the AI might produce comments like

```
Sentence structure could be improved.

Grammar is generally good.

Paragraph transitions are clear.
```

Clearly that's nonsense for source code.

Now choose **Programming**.

The response becomes

```
Variable names are descriptive.

The program correctly handles invalid input.

The nested loops could be simplified.

Consider extracting repeated logic into functions.
```

Same model.

Same assignment.

Different persona.

Completely different feedback.

This illustrates one of the most important ideas in prompt engineering:

> **The quality of the instructions often matters more than the choice of model.**

---

# Making Personas Easy to Extend

Imagine a school wants additional subjects.

Adding them is now trivial.

Simply create another persona.

```python
HISTORY_PERSONA = """
...
"""
```

Then register it.

```python
PERSONAS["History"] = HISTORY_PERSONA
```

Finally, update the dropdown.

```python
options=[

    "Mathematics",

    "English",

    "Science",

    "Programming",

    "History"

]
```

No other code changes are required.

This is one of the advantages of designing software with modular components.

---

# Improving the User Experience

At this point, teachers can accidentally choose the wrong subject.

For example,

* uploading a Python program while selecting English
* uploading a mathematics worksheet while selecting Programming

Later in this tutorial, we'll improve Markly even further by allowing the AI to automatically detect the subject before grading. However, keeping the subject selection manual at this stage helps us understand how personas influence the AI's behavior and makes debugging much easier.

---

# Current Architecture

Our application has become significantly more sophisticated.

```text
                    Teacher
                       │
                       ▼
             Upload Assignment
                       │
                       ▼
              Extract Assignment
                       │
                       ▼
             Choose Subject
                       │
                       ▼
             Load Teacher Persona
                       │
                       ▼
               Large Language Model
                       │
                       ▼
         Subject-Specific Feedback
                       │
                       ▼
             Display Results
```

The overall workflow hasn't changed, but the quality of the AI's feedback has improved dramatically. By separating grading logic into reusable personas, we've made Markly easier to maintain, easier to extend, and far more effective at producing authentic, subject-aware evaluations.

In the next instalment, we'll tackle another major capability: **multimodal grading**. So far, Markly has only worked with text extracted from PDFs and Word documents. Many real-world assignments, however, are submitted as scanned worksheets, handwritten solutions, photographs, or diagrams. We'll learn how to send images directly to a vision-capable language model, enabling Markly to understand and grade visual content just as effectively as text documents.
