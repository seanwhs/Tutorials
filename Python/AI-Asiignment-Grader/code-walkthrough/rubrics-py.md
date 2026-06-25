# Python Primer: `rubrics.py` — Subject Grading Rules

This primer teaches core Python concepts using a rubric configuration file. Each section shows the original code, explains the Python idea simply, gives a short mini-demo, and connects it back to the module.

***

## Module Deep Dive: `rubrics.py`

This file is the **policy layer** of the grading system. It stores the rules for how each subject should be evaluated, so the AI can grade more consistently instead of inventing criteria from scratch each time.

***

## 1. What this file does

```python
RUBRICS = {  # Map subject names to rubric text
    ...
}
```

**Python Concept: Dictionaries as Configuration**  
A dictionary is a natural way to map subject names to rubric text. Here, the file acts like a config module: it keeps the grading rules separate from the logic that applies them, which makes the system easier to maintain. [cs.stanford](https://cs.stanford.edu/people/nick/py/python-style-basics.html)

**Mini Demo**:
```python
RUBRICS = {
    "Math": "Check accuracy and method",  # Short rule summary for Math
    "English": "Check grammar and clarity",  # Short rule summary for English
}

print(RUBRICS["Math"])  # Look up the Math rubric
```

**In `rubrics.py`**: This file stores grading rules in one place so the rest of the app can look them up by subject name.

***

## 2. Mathematics rubric

```python
"Mathematics": """  # Subject key with a multiline rubric
1. Calculation Accuracy (5 points)
   - Correctness of numerical computation and results

2. Correct Methodology (3 points)
   - Use of appropriate formulas, steps, and logical approach

3. Final Answer Correctness (2 points)
   - Accuracy of final stated result with proper form
""",
```

**Python Concept: Multiline Strings as Data**  
Triple-quoted strings are useful when you want to store long text blocks in a readable way. In this case, the rubric is just data, not executable code, and the total adds up to 10 points for easy grading. [peps.python](https://peps.python.org/pep-0008/)

**Mini Demo**:
```python
rubric = """  # Store rubric text as one readable block
1. Accuracy (5)
2. Method (3)
3. Presentation (2)
"""
print(rubric.strip())  # Remove extra leading/trailing whitespace
```

**In `rubrics.py`**: This rubric emphasizes correct computation first, then the method, then the final form of the answer.

***

## 3. English rubric

```python
"English": """  # Subject key for language-based grading
1. Grammar & Syntax (4 points)
   - Sentence structure, spelling, and grammatical correctness

2. Clarity & Flow (3 points)
   - Logical progression of ideas and readability

3. Argument Strength (3 points)
   - Quality of reasoning, evidence, and coherence of argument
""",
```

**Python Concept: Structured Text in a Dictionary Value**  
Dictionary values can hold long multiline text, which makes them suitable for detailed human-readable policies. This rubric balances language mechanics with clarity and argument quality. [peps.python](https://peps.python.org/pep-0008/)

**Mini Demo**:
```python
rubric = {  # Store a subject rubric in a dictionary
    "English": """
Grammar: 4
Clarity: 3
Argument: 3
"""
}
print("English" in rubric)  # Check that the key exists
```

**In `rubrics.py`**: This rubric focuses on communication quality, not just spelling or grammar.

***

## 4. Science rubric

```python
"Science": """  # Subject key for science grading
1. Conceptual Understanding (4 points)
   - Correctness of scientific principles and explanations

2. Application of Knowledge (3 points)
   - Ability to apply concepts to given scenarios or experiments

3. Scientific Reasoning (3 points)
   - Logical interpretation of results and cause-effect relationships
""",
```

**Python Concept: Data-Driven Rules**  
The rubric is stored as data rather than hardcoded into grading logic. That means you can revise the criteria without changing the program’s control flow. [peps.python](https://peps.python.org/pep-0008/)

**Mini Demo**:
```python
science = """  # Keep science criteria as text data
Understanding: 4
Application: 3
Reasoning: 3
"""
print(science.count("3"))  # Count how many 3-point categories appear
```

**In `rubrics.py`**: This rubric checks whether the student understands the science, can apply it, and can explain reasoning clearly.

***

## 5. Programming rubric

```python
"Programming": """  # Subject key for coding assignments
1. Correctness (4 points)
   - Code produces correct output and meets requirements

2. Code Quality & Readability (3 points)
   - Clean structure, naming conventions, and maintainability

3. Efficiency & Optimization (2 points)
   - Appropriate use of algorithms and performance considerations

4. Design & Structure (1 point)
   - Use of functions, modularity, and good software design principles
"""
```

**Python Concept: Categorized Configuration**  
A dictionary value can contain detailed rules for a whole subject area. This rubric covers both function and quality, which is important for software work where readable and maintainable code matters. [kinsta](https://kinsta.com/blog/python-comments/)

**Mini Demo**:
```python
rubric = """  # Store detailed programming criteria as text
Correctness: 4
Readability: 3
Efficiency: 2
Design: 1
"""
lines = rubric.strip().splitlines()  # Split rubric into individual lines
print(lines[0])  # Show the first criterion
```

**In `rubrics.py`**: This rubric evaluates code from several angles: correctness, readability, efficiency, and structure.

***

## Big-picture reading of the module

This file is a simple but important source of truth for grading policy. It does not run grading logic itself; it tells the rest of the app what to value for each subject. That separation makes the project easier to expand because you can improve grading behavior by editing rubric text instead of rewriting the grading engine. [stackoverflow](https://stackoverflow.com/questions/46381904/proper-use-of-comments)

The key idea is that each rubric is:
- subject-specific.
- weighted.
- human-readable.
- easy for the AI to consume as prompt context.

## Practice suggestions

- Change the Mathematics weights and see how that shifts scoring emphasis.
- Add a `"History"` rubric and decide what the three most important criteria should be.
- Reformat one rubric so it is shorter and compare how easy it is to read.

***

## References

- PEP 8 style guidance on comments, docstrings, and readability. [peps.python](https://peps.python.org/pep-0008/)
- Python style discussions on using comments only when they clarify non-obvious code. [interactivetextbooks.tudelft](https://interactivetextbooks.tudelft.nl/programming-foundations/content/chapter5/pep-8.html)
