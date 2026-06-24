# Optimize Prompts for Better Unit Tests and More Precise Fixes  
## In Your AI-Powered Python Debugger

***

## Overview

In the previous tutorial, you built an AI-powered Python debugger that:

- Explains bugs  
- Suggests fixes  
- Generates unit test ideas  
- Supports follow-up questions  

But you may have noticed:

- Sometimes the fixes are not *perfect*  
- Sometimes the unit tests are generic or don’t cover important edge cases  
- Sometimes the output format is inconsistent  

This tutorial focuses on **prompt engineering**: improving the instructions you give the AI so it produces:

- More precise, production-quality fixes  
- More realistic and comprehensive unit tests  
- More consistent, well-structured output  

Prompt engineering is a core skill for any LLM-based tool. Once you learn these techniques, you can apply them to:

- Next.js + AI projects  
- Agentic workflows  
- Any future AI-assisted development tool  

Sources on prompt engineering techniques and structured output: [medium](https://medium.com/@mengsaylms/mastering-prompt-engineering-for-effective-llm-output-tips-techniques-and-warning-d76b09515c3)

***

## What You’ll Improve

After this tutorial, your debugger will:

| Before (Basic Prompt)                       | After (Optimized Prompt)                                          |
|--------------------------------------------|-------------------------------------------------------------------|
| Fixes may miss edge cases                  | Fixes handle empty lists, zero, negative numbers, etc.            |
| Tests are often trivial                    | Tests include boundary cases, error cases, and realistic inputs   |
| Output format varies                       | Output consistently follows exact Markdown sections               |
| Explanations can be vague                  | Explanations are step-by-step and concrete                        |
| AI sometimes adds extra text               | AI strictly follows the requested structure                       |

***

## Prerequisites

You should have:

- The working `ai-debugger` project from the previous tutorial  
- Python 3.10+  
- A virtual environment with:
  - `panel`
  - `openai`
  - `python-dotenv`
  - `pytest`  

- An OpenRouter API key in `.env`

***

# Phase 1 – Understand Why Prompts Matter

## 1.1 – The Role of the System Prompt

The system prompt is like the AI’s “job description.” It tells the model:

- What role to play (e.g., “expert Python debugging assistant”)  
- What steps to follow  
- How to format the output  

Think of it as a **product specification** for the AI’s behavior. [linkedin](https://www.linkedin.com/learning/integrating-ai-into-the-product-architecture/prompt-engineering-techniques-to-improve-llm-output)

A vague prompt:

```text
You are a Python helper. Fix bugs and write tests.
```

leads to:

- Inconsistent behavior  
- Generic fixes  
- Tests that don’t cover important cases  

A precise prompt:

```text
You are an expert Python debugging assistant.

When given Python code:
1. Identify the bug.
2. Explain the root cause step-by-step.
3. Provide fixed code that handles edge cases.
4. Suggest 2–5 unit tests with realistic inputs.
5. Mention improvements.

Return your answer using these Markdown sections:
## Error
## Explanation
## Fixed Code
## Unit Tests
## Improvements
```

leads to:

- More consistent, structured output  
- Edge-case-aware fixes  
- More meaningful tests  

***

## 1.2 – Key Prompt Engineering Techniques

We’ll use several proven techniques:

1. **Role-based prompting**  
   - Assign a clear role: “expert Python debugging assistant” [linkedin](https://www.linkedin.com/learning/integrating-ai-into-the-product-architecture/prompt-engineering-techniques-to-improve-llm-output)
2. **Clear instructions**  
   - Be specific, avoid ambiguity [medium](https://medium.com/@mengsaylms/mastering-prompt-engineering-for-effective-llm-output-tips-techniques-and-warning-d76b09515c3)
3. **Structured output format**  
   - Explicitly define Markdown sections [apxml](https://apxml.com/courses/prompt-engineering-llm-application-development/chapter-2-advanced-prompting-strategies/structuring-output-formats)
4. **Chain-of-thought (step-by-step)**  
   - Ask the model to “explain step-by-step” [huggingface](https://huggingface.co/docs/transformers/en/tasks/prompting)
5. **Few-shot prompting (examples)**  
   - Show 1–2 examples of desired output format [huggingface](https://huggingface.co/docs/transformers/en/tasks/prompting)
6. **Constraints and requirements**  
   - Specify test counts, edge cases, and styles [linkedin](https://www.linkedin.com/posts/vijay-krishna-gudavalli-a5b365235_promptengineering-testautomation-qa-activity-7375919447578099715-aqR1)
7. **Self-critique loop (optional)**  
   - Ask the model to review and refine its own output [linkedin](https://www.linkedin.com/posts/saumyashankar_ai-artificialintelligence-promptengineering-activity-7445159765342797824-5asd)

You’ll apply these gradually to your system prompt.

***

# Phase 2 – Improve Fixes and Explanations

## 2.1 – Current System Prompt (Baseline)

From the previous tutorial, your system prompt is:

```python
SYSTEM_PROMPT = """
You are an expert Python debugging assistant.

When given Python code:

1. Identify the bug.
2. Explain the root cause.
3. Provide fixed code.
4. Suggest unit tests.

Return your answer using these Markdown sections:

## Error
## Explanation
## Fixed Code
## Unit Tests
## Improvements
"""
```

This is already good, but we can make it more precise.

***

## 2.2 – Add Step-by-Step Reasoning

Ask the model to “think step-by-step” in the explanation. This improves accuracy on multi-step problems. [medium](https://medium.com/@mengsaylms/mastering-prompt-engineering-for-effective-llm-output-tips-techniques-and-warning-d76b09515c3)

Update the prompt:

```python
SYSTEM_PROMPT = """
You are an expert Python debugging assistant for Python code.

When given Python code:

1. Identify the bug.
   - Name the error type if possible (e.g., IndexError, NameError, ZeroDivisionError).

2. Explain the root cause step-by-step.
   - Describe what the code is trying to do.
   - Explain exactly where and why it fails.
   - Use clear, beginner-friendly language.

3. Provide fixed code.
   - The fixed code must be complete and runnable.
   - Handle common edge cases (e.g., empty lists, zero, negative numbers) where relevant.
   - Use safe patterns (e.g., check before accessing list indices, avoid division by zero).

4. Suggest unit tests.
   - Provide 2–5 tests using pytest style.
   - Include:
     - Normal cases
     - Edge cases (empty input, zero, negative values, maximum values)
     - Error cases (e.g., division by zero, invalid indices)
   - Tests must be import-ready and use the function names from the fixed code.

5. Mention improvements.
   - Suggest readability, performance, or safety improvements.

Return your answer using exactly these Markdown sections:

## Error
## Explanation
## Fixed Code
## Unit Tests
## Improvements
"""
```

Key improvements:

- Explicitly names error types.  
- Forces **step-by-step** explanations.  
- Requires **edge-case handling** in fixed code.  
- Defines test requirements (normal, edge, error cases).  
- Enforces **exact Markdown section names**.

***

## 2.3 – Test the Improved Prompt

Restart your app:

```bash
panel serve app.py --show
```

Test with:

```python
def divide(a, b):
    return a / b

print(divide(10, 0))
```

You should now see:

- A clear identification of `ZeroDivisionError`  
- A step-by-step explanation  
- Fixed code that safely handles division by zero  
- Unit tests that include:
  - Normal division  
  - Division by zero  
  - Negative numbers  
  - Zero as numerator  

***

# Phase 3 – Improve Unit Test Generation

## 3.1 – Make Test Requirements More Specific

Even with the improved prompt, tests can still be generic. We can make them more concrete by adding **constraints** and **examples**.

### Add Constraints

Update the “Suggest unit tests” section:

```python
"""
4. Suggest unit tests.
   - Provide 2–5 tests using pytest style.
   - Each test must:
     - Be named clearly: test_<function_name>_<scenario>
     - Use assert statements
     - Import the function from code_examples (e.g., from code_examples import divide)
   - Include:
     - At least one normal case
     - At least one edge case (e.g., empty input, zero, negative values)
     - At least one error case if the function can raise exceptions
   - Tests must be runnable with pytest without extra setup.
"""
```

### Add a Few-Shot Example

Few-shot prompting (showing examples) is very effective for format consistency. [huggingface](https://huggingface.co/docs/transformers/en/tasks/prompting)

Add an example of desired test output:

```python
"""
4. Suggest unit tests.
   - Provide 2–5 tests using pytest style.
   - Each test must:
     - Be named clearly: test_<function_name>_<scenario>
     - Use assert statements
     - Import the function from code_examples (e.g., `from code_examples import divide`)
   - Include:
     - At least one normal case
     - At least one edge case (e.g., empty input, zero, negative values)
     - At least one error case if the function can raise exceptions
   - Tests must be runnable with pytest without extra setup.

   Example of desired test style:

   ```python
   import pytest
   from code_examples import divide

   def test_divide_normal_case():
       assert divide(10, 2) == 5

   def test_divide_by_zero():
       with pytest.raises(ZeroDivisionError):
           divide(10, 0)

   def test_divide_negative_numbers():
       assert divide(-10, 2) == -5
   ```
"""
```

This gives the model a concrete pattern to follow.

***

## 3.2 – Full Optimized System Prompt

Combining everything, your final optimized system prompt is:

```python
SYSTEM_PROMPT = """
You are an expert Python debugging assistant for Python code.

When given Python code:

1. Identify the bug.
   - Name the error type if possible (e.g., IndexError, NameError, ZeroDivisionError).

2. Explain the root cause step-by-step.
   - Describe what the code is trying to do.
   - Explain exactly where and why it fails.
   - Use clear, beginner-friendly language.

3. Provide fixed code.
   - The fixed code must be complete and runnable.
   - Handle common edge cases (e.g., empty lists, zero, negative numbers) where relevant.
   - Use safe patterns (e.g., check before accessing list indices, avoid division by zero).

4. Suggest unit tests.
   - Provide 2–5 tests using pytest style.
   - Each test must:
     - Be named clearly: test_<function_name>_<scenario>
     - Use assert statements
     - Import the function from code_examples (e.g., `from code_examples import divide`)
   - Include:
     - At least one normal case
     - At least one edge case (e.g., empty input, zero, negative values)
     - At least one error case if the function can raise exceptions
   - Tests must be runnable with pytest without extra setup.

   Example of desired test style:

   ```python
   import pytest
   from code_examples import divide

   def test_divide_normal_case():
       assert divide(10, 2) == 5

   def test_divide_by_zero():
       with pytest.raises(ZeroDivisionError):
           divide(10, 0)

   def test_divide_negative_numbers():
       assert divide(-10, 2) == -5
   ```

5. Mention improvements.
   - Suggest readability, performance, or safety improvements.

Return your answer using exactly these Markdown sections:

## Error
## Explanation
## Fixed Code
## Unit Tests
## Improvements
"""
```

***

## 3.3 – Re-Test and Compare

Restart your app:

```bash
panel serve app.py --show
```

Test with the same `divide` function:

```python
def divide(a, b):
    return a / b

print(divide(10, 0))
```

Compare the output:

- **Old prompt**: tests might be simple, like `divide(10, 2) == 5`.
- **New prompt**: tests should include:
  - Normal case  
  - Division by zero  
  - Negative numbers  
  - Possibly zero as numerator  

Now run the tests:

```bash
pytest
```

You should see more comprehensive coverage and better-aligned tests.

***

# Phase 4 – Evaluate Prompt Changes

## 4.1 – How to Evaluate Prompts

To evaluate whether your prompt is better, check:

1. **Accuracy**  
   - Do fixes actually resolve the bug?  
   - Do they handle edge cases correctly?

2. **Test Quality**  
   - Do tests cover:
     - Normal cases?
     - Edge cases?
     - Error cases?  
   - Are tests runnable with `pytest`?

3. **Consistency**  
   - Is the output always in the same Markdown sections?  
   - Are function names and imports consistent?

4. **Clarity**  
   - Are explanations step-by-step and beginner-friendly?  
   - Are improvements practical?

***

## 4.2 – Iterate on the Prompt

Prompt engineering is iterative. [medium](https://medium.com/@mengsaylms/mastering-prompt-engineering-for-effective-llm-output-tips-techniques-and-warning-d76b09515c3)

If tests are still too generic:

- Add more explicit constraints (e.g., “tests must include at least one case where input is empty”).  
- Add another example with different function types (e.g., list-based function).

If fixes miss edge cases:

- Add stronger requirements:  
  “Your fixed code must explicitly handle empty lists, zero, and negative numbers where relevant.”

You can always:

- Copy your current prompt  
- Make a small change  
- Test with a few buggy examples  
- Compare results  

***

# Phase 5 – Optional: Add a Self-Critique Step

As an advanced technique, you can ask the model to **critique its own output** and refine it. [linkedin](https://www.linkedin.com/posts/saumyashankar_ai-artificialintelligence-promptengineering-activity-7445159765342797824-5asd)

This is optional and more complex, but here’s the idea.

You could add to the system prompt:

```text
After producing your answer:
- Briefly review your fixed code and tests.
- Identify any missing edge cases or weak tests.
- If needed, improve the fixed code and tests.
- Then output your final answer in the required Markdown sections.
```

Be careful:

- Self-critique can increase latency.  
- Set an exit condition (e.g., “max one review round”) to avoid infinite loops.

For beginners, the optimized prompt from Phase 3 is already strong. You can add self-critique later as an advanced feature.

***

## Summary

In this tutorial, you:

- Learned key prompt engineering techniques:
  - Role-based prompting  
  - Clear, specific instructions  
  - Structured output formats  
  - Chain-of-thought (step-by-step) reasoning  
  - Few-shot prompting with examples  
  - Constraints for test generation  
- Upgraded your system prompt to:
  - Enforce step-by-step explanations  
  - Require edge-case-aware fixes  
  - Generate more comprehensive unit tests  
  - Produce consistent Markdown output  
- Evaluated and iterated on your prompt to improve quality  

This optimized prompt makes your AI debugger:

- More precise  
- More reliable  
- More useful for real development  

***

