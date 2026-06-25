## 1. What this file does

```python
RUBRICS = {
    ...
}
```

### Why this block exists
This file stores the grading rules for each subject in one place. The AI uses these rules to judge student work in a more consistent way, instead of improvising from scratch each time.

### Python concepts used
- A dictionary maps subject names to rubric text.
- Triple-quoted strings hold multiline rubric descriptions.
- Comments explain the intent of each rubric.

### Pattern analysis
This is a **configuration module**. It keeps evaluation criteria separate from the grading logic, which makes the system easier to maintain.

### What if
Change the Mathematics rubric weights and see how that would shift the scoring emphasis.

## 2. Mathematics rubric

```python
"Mathematics": """
1. Calculation Accuracy (5 points)
   - Correctness of numerical computation and results

2. Correct Methodology (3 points)
   - Use of appropriate formulas, steps, and logical approach

3. Final Answer Correctness (2 points)
   - Accuracy of final stated result with proper form
""",
```

### Why this block exists
This rubric prioritizes getting the answer right, then using the right method, and finally presenting the final result correctly. That matches how math is usually graded: process matters, but correctness matters most.

### Python concepts used
- Dictionary values can be long text blocks.
- The rubric is just data, not code.

### Pattern analysis
This is a **weighted scoring scheme**. The total adds up to 10 points, which makes it easy to convert into an `X/10` grade.

### What if
Swap the weights for methodology and final answer, and think about how that would change the behavior of the AI grader.

## 3. English rubric

```python
"English": """
1. Grammar & Syntax (4 points)
   - Sentence structure, spelling, and grammatical correctness

2. Clarity & Flow (3 points)
   - Logical progression of ideas and readability

3. Argument Strength (3 points)
   - Quality of reasoning, evidence, and coherence of argument
""",
```

### Why this block exists
This rubric checks how clearly the student communicates ideas. In English work, correctness is important, but readability, structure, and argument quality also matter a lot.

### Python concepts used
- Multiline strings are convenient for readable rubric text.
- The rubric remains easy to edit without changing the program flow.

### Pattern analysis
This is a **communication-focused rubric**. It balances language mechanics with the quality of thought.

### What if
Reduce the grammar weight and increase argument strength to see how the grading priorities shift toward writing quality over mechanics.

## 4. Science rubric

```python
"Science": """
1. Conceptual Understanding (4 points)
   - Correctness of scientific principles and explanations

2. Application of Knowledge (3 points)
   - Ability to apply concepts to given scenarios or experiments

3. Scientific Reasoning (3 points)
   - Logical interpretation of results and cause-effect relationships
""",
```

### Why this block exists
This rubric checks whether the student understands the science correctly, can apply it, and can reason from evidence. Science is not just about memorizing facts; it is also about using those facts properly.

### Python concepts used
- The rubric is data-driven rather than hardcoded into logic.

### Pattern analysis
This is a **conceptual understanding rubric**. It evaluates both knowledge and reasoning.

### What if
Add a fourth category for experimental design and consider how that would better suit lab-based science work.

## 5. Programming rubric

```python
"Programming": """
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

### Why this block exists
This rubric evaluates code from multiple angles: does it work, is it readable, is it efficient, and is it well-structured. That reflects how programming is often judged in real projects.

### Python concepts used
- Dictionary values can hold any string content, including detailed rules.
- The rubric’s categories are ordered by importance.

### Pattern analysis
This is a **software-quality rubric**. It goes beyond correctness and includes maintainability and design.

### What if
Increase the design score and reduce efficiency to see how the rubric would favor cleaner architecture over performance.

## Big-picture reading of the module

This file is a simple but important source of truth for grading policy. It does not run logic itself; it tells the rest of the app what to value for each subject. That separation makes the project easier to expand, because you can improve grading behavior by editing the rubric text instead of rewriting the whole grading engine.

The key idea is that each rubric is:
- **subject-specific**,
- **weighted**,
- **human-readable**, and
- **easy for the AI to consume as prompt context**.

If you want, the next good step would be to turn these rubrics into a more beginner-friendly explanation of how prompt-based grading uses them at runtime.
