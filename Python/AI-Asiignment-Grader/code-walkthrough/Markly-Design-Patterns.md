I'll create a comprehensive, beginner-friendly primer on the design patterns used in Markly. Let me first review the uploaded source files to identify all the patterns in play, then craft the primer.
Now I have a thorough understanding of Markly's architecture and the design patterns literature. Let me craft a comprehensive, beginner-friendly primer.

---

# Markly Design Patterns Primer

## A Beginner's Guide to the Architectural Patterns That Make Markly Tick

---

### What This Primer Is About

This is a standalone guide to the design patterns used in Markly — the AI-powered assignment grading system. You don't need to be an expert. We'll start from first principles, explain *why* each pattern exists, show how Markly uses it, and give you clean code examples you can actually run.

By the end, you'll understand not just *what* Markly does, but *why* it's built the way it is — and you'll be able to recognize these patterns in other projects.

---

## Table of Contents

1. [What Are Design Patterns?](#1-what-are-design-patterns)
2. [The Factory Pattern — Creating the Right Tool for the Job](#2-the-factory-pattern--creating-the-right-tool-for-the-job)
3. [The Strategy Pattern — Swapping Algorithms on the Fly](#3-the-strategy-pattern--swapping-algorithms-on-the-fly)
4. [The Singleton Pattern — One Database to Rule Them All](#4-the-singleton-pattern--one-database-to-rule-them-all)
5. [The Template Method Pattern — Following a Recipe](#5-the-template-method-pattern--following-a-recipe)
6. [The Decorator Pattern — Adding Behavior Without Changing Code](#6-the-decorator-pattern--adding-behavior-without-changing-code)
7. [The Facade Pattern — Hiding Complexity Behind a Simple Interface](#7-the-facade-pattern--hiding-complexity-behind-a-simple-interface)
8. [The Pipeline Pattern — Assembly Line for Data](#8-the-pipeline-pattern--assembly-line-for-data)
9. [The Circuit Breaker Pattern — Graceful Degradation](#9-the-circuit-breaker-pattern--graceful-degradation)
10. [How Patterns Work Together in Markly](#10-how-patterns-work-together-in-markly)
11. [Key Takeaways](#11-key-takeaways)

---

## 1. What Are Design Patterns?

Imagine you're building a house. You could figure out everything from scratch — how thick the walls should be, how to frame a door, how to run electricity. Or you could use **proven blueprints** that architects have refined over decades.

Design patterns are those blueprints for software. They're reusable solutions to problems that come up again and again. They don't give you copy-paste code — they give you a *way of thinking* about structure.

### Why Should You Care?

| Without Patterns | With Patterns |
|---|---|
| Spaghetti code that's hard to change | Clean, modular code that's easy to extend |
| "How do I add a new file format?" → Rewrite everything | "How do I add a new file format?" → Add one function |
| One bug breaks the whole system | Bugs are isolated to one component |
| Only the original author understands the code | New team members can read the architecture |

### The Three Families of Patterns

Patterns are grouped by what they solve:

- **Creational** — How objects are created (Factory, Singleton)
- **Structural** — How objects are organized (Facade, Decorator)
- **Behavioral** — How objects communicate and behave (Strategy, Template Method, Pipeline)

Markly uses patterns from all three families. Let's dive in.

---

## 2. The Factory Pattern — Creating the Right Tool for the Job

### The Problem

Markly accepts assignments in three formats: **PDF**, **DOCX**, and **images**. Each format needs a different library to extract text:

- PDF → PyMuPDF (`fitz`)
- DOCX → `python-docx`
- Images → `pytesseract` (OCR)

Without a pattern, you'd write something like this:

```python
# BAD: Tightly coupled, hard to extend
def process_file(file_bytes, filename):
    ext = filename.split('.')[-1]
    if ext == "pdf":
        import fitz
        doc = fitz.open(stream=file_bytes, filetype="pdf")
        return "\n".join([page.get_text() for page in doc])
    elif ext == "docx":
        from docx import Document
        doc = Document(io.BytesIO(file_bytes))
        return "\n".join([p.text for p in doc.paragraphs])
    elif ext in ("png", "jpg", "jpeg"):
        from PIL import Image
        import pytesseract
        img = Image.open(io.BytesIO(file_bytes))
        return pytesseract.image_to_string(img)
    else:
        raise ValueError("Unsupported file type")
```

**Problems with this approach:**
- Every new file format means editing this function
- Imports happen inside the function (slow, messy)
- The caller knows too much about implementation details
- Testing is hard — you can't swap out a PDF extractor for a mock

### The Factory Pattern Solution

The Factory Pattern says: **"Don't create objects directly. Ask a factory to create them for you."**

Here's how Markly does it:

```python
import io
import fitz
from docx import Document
from PIL import Image
import pytesseract

# ============================================
# STEP 1: Define the common interface
# ============================================
# Every extractor must implement this contract
class TextExtractor:
    """Abstract base for all file extractors."""
    
    def extract(self, file_bytes: bytes) -> str:
        raise NotImplementedError("Subclasses must implement extract()")


# ============================================
# STEP 2: Create concrete implementations
# ============================================
class PDFExtractor(TextExtractor):
    """Extracts text from PDF files using PyMuPDF."""
    
    def extract(self, file_bytes: bytes) -> str:
        document = fitz.open(stream=file_bytes, filetype="pdf")
        return "\n".join([page.get_text() for page in document])


class DOCXExtractor(TextExtractor):
    """Extracts text from Word documents."""
    
    def extract(self, file_bytes: bytes) -> str:
        document = Document(io.BytesIO(file_bytes))
        return "\n".join([p.text for p in document.paragraphs])


class ImageExtractor(TextExtractor):
    """Extracts text from images using OCR."""
    
    def extract(self, file_bytes: bytes) -> str:
        image = Image.open(io.BytesIO(file_bytes))
        return pytesseract.image_to_string(image)


# ============================================
# STEP 3: Create the Factory
# ============================================
class ExtractorFactory:
    """Creates the right extractor based on file extension."""
    
    # Registry mapping extensions to extractor classes
    _registry = {
        "pdf": PDFExtractor,
        "docx": DOCXExtractor,
        "png": ImageExtractor,
        "jpg": ImageExtractor,
        "jpeg": ImageExtractor,
    }
    
    @classmethod
    def create(cls, filename: str) -> TextExtractor:
        """Factory method: returns the right extractor instance."""
        ext = filename.lower().split('.')[-1]
        
        extractor_class = cls._registry.get(ext)
        if not extractor_class:
            raise ValueError(f"Unsupported file type: .{ext}")
        
        return extractor_class()  # Create and return the instance
    
    @classmethod
    def register(cls, extension: str, extractor_class: type):
        """Register a new extractor without modifying existing code."""
        cls._registry[extension] = extractor_class


# ============================================
# STEP 4: Use it — clean and simple
# ============================================
def extract_text_from_file(file_bytes: bytes, filename: str) -> str:
    """The caller doesn't care HOW extraction works."""
    extractor = ExtractorFactory.create(filename)
    return extractor.extract(file_bytes)


# ============================================
# EXAMPLE USAGE
# ============================================
if __name__ == "__main__":
    # The caller just passes a filename — the factory handles the rest
    with open("essay.pdf", "rb") as f:
        text = extract_text_from_file(f.read(), "essay.pdf")
        print(text[:200])
```

### Why This Is Better

| Aspect | Before (No Pattern) | After (Factory Pattern) |
|---|---|---|
| **Adding a new format** | Edit the big `if/else` block | Register one line: `ExtractorFactory.register("txt", TXTExtractor)` |
| **Testing** | Hard to mock | Easy: `ExtractorFactory.register("pdf", MockExtractor)` |
| **Readability** | One giant function | Small, focused classes with single responsibilities |
| **Reusability** | Tied to one function | Extractors can be used anywhere |

### The Pattern in One Sentence

> **The Factory Pattern centralizes object creation so the rest of your code doesn't need to know *how* objects are built — only *what* they can do.**

---

## 3. The Strategy Pattern — Swapping Algorithms on the Fly

### The Problem

Markly grades assignments differently depending on the **subject**:
- **Math** → Check formulas, step-by-step logic, numerical accuracy
- **English** → Check grammar, structure, argument quality, creativity
- **Science** → Check hypothesis, methodology, data analysis
- **Programming** → Check code correctness, style, efficiency

Without a pattern, you'd have one massive grading function:

```python
# BAD: One function doing everything
def grade_assignment(text, subject):
    if subject == "Math":
        prompt = f"You are a strict math teacher. Grade this: {text}"
        # ... math-specific rubric
    elif subject == "English":
        prompt = f"You are an English teacher. Grade this: {text}"
        # ... English-specific rubric
    elif subject == "Science":
        prompt = f"You are a science teacher. Grade this: {text}"
        # ... science-specific rubric
    # ... and so on
    
    return call_ai_api(prompt)
```

**Problems:**
- Adding a new subject means editing this function (violates Open/Closed Principle)
- Rubrics are mixed with API calling logic
- Can't swap grading strategies at runtime (e.g., strict vs. lenient)

### The Strategy Pattern Solution

The Strategy Pattern says: **"Define a family of algorithms, encapsulate each one, and make them interchangeable."**

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass

# ============================================
# STEP 1: Define the Strategy Interface
# ============================================
class GradingStrategy(ABC):
    """Every grading strategy must implement this."""
    
    @abstractmethod
    def build_prompt(self, student_text: str) -> str:
        """Returns the complete prompt for the AI."""
        pass
    
    @abstractmethod
    def parse_response(self, ai_text: str) -> dict:
        """Extracts structured data from AI's free-text response."""
        pass
    
    @property
    @abstractmethod
    def model_temperature(self) -> float:
        """How creative vs. deterministic the AI should be."""
        pass


# ============================================
# STEP 2: Concrete Strategies
# ============================================
class MathGradingStrategy(GradingStrategy):
    """Strategy for grading math assignments."""
    
    model_temperature = 0.1  # Low = very deterministic for math
    
    def build_prompt(self, student_text: str) -> str:
        return f"""You are a strict mathematics teacher grading a high school algebra assignment.
        
        GRADING RUBRIC:
        - Correctness of final answer (40%)
        - Step-by-step working shown (35%)
        - Proper notation and formatting (15%)
        - Organization and clarity (10%)
        
        Provide:
        1. A grade out of 100
        2. Specific corrections for any errors
        3. Overall feedback
        
        STUDENT WORK:
        {student_text}
        """
    
    def parse_response(self, ai_text: str) -> dict:
        # Math-specific parsing: look for numerical grades
        import re
        grade_match = re.search(r'(\\d{1,3})/100', ai_text)
        grade = grade_match.group(1) if grade_match else "N/A"
        
        return {
            "grade": grade,
            "feedback": ai_text,
            "subject": "Math"
        }


class EnglishGradingStrategy(GradingStrategy):
    """Strategy for grading English essays."""
    
    model_temperature = 0.4  # Slightly creative for nuanced feedback
    
    def build_prompt(self, student_text: str) -> str:
        return f"""You are an English literature teacher grading a student essay.
        
        GRADING RUBRIC:
        - Thesis clarity and argument strength (30%)
        - Evidence and textual support (25%)
        - Grammar and mechanics (20%)
        - Structure and flow (15%)
        - Creativity and voice (10%)
        
        Provide:
        1. A letter grade (A-F with +/-)
        2. Line-by-line corrections
        3. Strengths and areas for improvement
        
        STUDENT ESSAY:
        {student_text}
        """
    
    def parse_response(self, ai_text: str) -> dict:
        import re
        grade_match = re.search(r'Grade:\\s*([A-F][+-]?)', ai_text, re.I)
        grade = grade_match.group(1) if grade_match else "N/A"
        
        return {
            "grade": grade,
            "feedback": ai_text,
            "subject": "English"
        }


class ScienceGradingStrategy(GradingStrategy):
    """Strategy for grading science lab reports."""
    
    model_temperature = 0.2
    
    def build_prompt(self, student_text: str) -> str:
        return f"""You are a science teacher grading a lab report.
        
        GRADING RUBRIC:
        - Hypothesis formulation (20%)
        - Methodology description (25%)
        - Data presentation and analysis (30%)
        - Conclusion quality (15%)
        - Scientific writing (10%)
        
        STUDENT LAB REPORT:
        {student_text}
        """
    
    def parse_response(self, ai_text: str) -> dict:
        # Science might use different grade formats
        import re
        grade_match = re.search(r'(\\d{1,2}(?:\\.\\d+)?)/100', ai_text)
        grade = grade_match.group(0) if grade_match else "N/A"
        
        return {
            "grade": grade,
            "feedback": ai_text,
            "subject": "Science"
        }


# ============================================
# STEP 3: The Context — Uses a Strategy
# ============================================
class AssignmentGrader:
    """
    The 'Context' in Strategy Pattern terminology.
    It doesn't know WHICH strategy it's using — it just knows
    the strategy follows the GradingStrategy interface.
    """
    
    def __init__(self, strategy: GradingStrategy):
        self.strategy = strategy
    
    def grade(self, student_text: str) -> dict:
        """Delegates to the strategy — no if/else needed."""
        prompt = self.strategy.build_prompt(student_text)
        
        # Call AI API (simplified)
        ai_response = self._call_ai(prompt, self.strategy.model_temperature)
        
        # Parse using the strategy's parser
        return self.strategy.parse_response(ai_response)
    
    def _call_ai(self, prompt: str, temperature: float) -> str:
        """Simulated AI call."""
        # In real Markly, this calls openai.AsyncOpenAI
        return f"[AI response for temp={temperature}]\\nGrade: 85/100\\nFeedback: Good work!"


# ============================================
# STEP 4: Strategy Selection (can be dynamic!)
# ============================================
def get_strategy(subject: str) -> GradingStrategy:
    """Factory + Strategy working together."""
    strategies = {
        "Math": MathGradingStrategy,
        "English": EnglishGradingStrategy,
        "Science": ScienceGradingStrategy,
    }
    
    strategy_class = strategies.get(subject)
    if not strategy_class:
        raise ValueError(f"No grading strategy for subject: {subject}")
    
    return strategy_class()


# ============================================
# EXAMPLE USAGE
# ============================================
if __name__ == "__main__":
    # User selects subject in the UI
    selected_subject = "Math"
    
    # Get the right strategy
    strategy = get_strategy(selected_subject)
    
    # Create grader with that strategy
    grader = AssignmentGrader(strategy)
    
    # Grade — the grader doesn't know or care it's math vs. English
    result = grader.grade("2x + 5 = 15, therefore x = 5")
    print(f"Grade: {result['grade']}")
    print(f"Subject: {result['subject']}")
```

### Why This Is Powerful

Notice how `AssignmentGrader.grade()` has **zero conditionals** about subjects. It just calls `self.strategy.build_prompt()` and trusts the strategy to do the right thing.

| Scenario | How Strategy Pattern Helps |
|---|---|
| **Add a new subject** | Create one new class. Zero changes to `AssignmentGrader`. |
| **Change rubric for Math** | Edit only `MathGradingStrategy`. Nothing else breaks. |
| **Add strict/lenient modes** | Create `StrictMathStrategy` and `LenientMathStrategy`. Swap at runtime. |
| **Test grading logic** | Pass a `MockGradingStrategy` that returns predictable results. |

### The Pattern in One Sentence

> **The Strategy Pattern lets you define a family of algorithms, put each one in its own class, and make them interchangeable at runtime.**

---

## 4. The Singleton Pattern — One Database to Rule Them All

### The Problem

Markly stores student history in a JSON file (`students.json`). Multiple parts of the app might try to read/write this file simultaneously:
- The grading engine saves a new record
- The UI displays a student's history
- A background process archives old data

If each module opens its own file handle, you get **race conditions** — data corruption, lost records, inconsistent state.

### The Singleton Pattern Solution

The Singleton Pattern ensures a class has **only one instance** and provides a global access point to it.

```python
import os
import json
import threading
from typing import Dict, Any, Optional

# ============================================
# THE SINGLETON: One database connection
# ============================================
class StudentDatabase:
    """
    Singleton pattern: ensures only ONE database instance exists.
    All modules share the same connection, preventing race conditions.
    """
    
    _instance: Optional['StudentDatabase'] = None
    _lock = threading.Lock()  # Thread safety for concurrent access
    
    def __new__(cls, db_file: str = "students.json"):
        """
        __new__ controls object creation.
        If an instance exists, return it. If not, create one.
        """
        if cls._instance is None:
            with cls._lock:  # Thread-safe check
                if cls._instance is None:  # Double-checked locking
                    cls._instance = super().__new__(cls)
                    cls._instance._initialized = False
        return cls._instance
    
    def __init__(self, db_file: str = "students.json"):
        """Initialize only once, even if __init__ is called multiple times."""
        if self._initialized:
            return
        
        self.db_file = db_file
        self._data: Dict[str, Any] = {}
        self._file_lock = threading.Lock()
        self._load()
        self._initialized = True
    
    # ============================================
    # Core operations
    # ============================================
    def _load(self):
        """Load data from disk."""
        if os.path.exists(self.db_file):
            try:
                with open(self.db_file, 'r', encoding='utf-8') as f:
                    self._data = json.load(f)
            except (json.JSONDecodeError, OSError):
                self._data = {}
        else:
            self._data = {}
    
    def _save(self):
        """Atomic save to disk."""
        with self._file_lock:
            with open(self.db_file, 'w', encoding='utf-8') as f:
                json.dump(self._data, f, indent=2)
    
    def add_record(self, student: str, subject: str, grade: str, feedback: str):
        """Thread-safe record addition."""
        with self._file_lock:
            if student not in self._data:
                self._data[student] = {"history": []}
            
            self._data[student]["history"].append({
                "subject": subject,
                "grade": grade,
                "feedback": feedback
            })
            self._save()
    
    def get_history(self, student: str) -> list:
        """Retrieve a student's grading history."""
        with self._file_lock:
            return self._data.get(student, {}).get("history", [])
    
    def get_all_students(self) -> list:
        """List all students in the database."""
        with self._file_lock:
            return list(self._data.keys())


# ============================================
# EXAMPLE: Multiple modules using the SAME database
# ============================================
def grading_module():
    """Simulates the grading engine saving results."""
    db = StudentDatabase()  # Gets the SAME instance
    db.add_record("Alice", "Math", "85/100", "Good algebra skills")
    print(f"[Grading Module] Saved record for Alice")


def ui_module():
    """Simulates the UI reading history."""
    db = StudentDatabase()  # Gets the SAME instance
    history = db.get_history("Alice")
    print(f"[UI Module] Alice has {len(history)} records")


def analytics_module():
    """Simulates background analytics."""
    db = StudentDatabase()  # Gets the SAME instance
    students = db.get_all_students()
    print(f"[Analytics] Total students: {len(students)}")


if __name__ == "__main__":
    import threading
    
    # All three modules run concurrently
    t1 = threading.Thread(target=grading_module)
    t2 = threading.Thread(target=ui_module)
    t3 = threading.Thread(target=analytics_module)
    
    t1.start()
    t1.join()  # Wait for save to complete
    
    t2.start()
    t3.start()
    t2.join()
    t3.join()
    
    # Verify they're the same object
    db1 = StudentDatabase()
    db2 = StudentDatabase()
    print(f"\\nSame object? {db1 is db2}")  # True!
```

### Why Singleton Matters for Markly

| Without Singleton | With Singleton |
|---|---|
| 3 modules open 3 file handles | 1 shared file handle |
| Race conditions corrupt JSON | Thread-safe with locks |
| In-memory cache is inconsistent | One cache, always in sync |
| Hard to track who's writing when | Centralized access point |

### ⚠️ Important Caveat

Singletons are powerful but can be overused. They make testing harder (global state) and create hidden dependencies. In Markly, the Singleton is justified because:
- The JSON file is a true singleton resource
- Multiple writers *will* conflict without coordination
- The database is a cross-cutting concern, not business logic

### The Pattern in One Sentence

> **The Singleton Pattern ensures a class has exactly one instance and provides a global point of access to it.**

---

## 5. The Template Method Pattern — Following a Recipe

### The Problem

Markly generates PDF reports. All reports follow the same basic structure:
1. Create a PDF document
2. Add a header with student info
3. Add the main content (varies by report type)
4. Add a footer
5. Save to buffer

But the *content* differs:
- **Image report**: Annotated assignment image + feedback text
- **Text report**: Just structured text feedback
- **Summary report**: Charts and statistics

Without a pattern, you'd duplicate the boilerplate:

```python
# BAD: Duplicated structure in every report function
def create_image_report(student, subject, image, feedback):
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4)
    # ... setup styles ...
    # ... add header ...
    # ... add image ...
    # ... add feedback ...
    # ... add footer ...
    doc.build(story)
    return buffer

def create_text_report(student, subject, feedback):
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4)
    # ... SAME setup styles ...
    # ... SAME header ...
    # ... add text feedback (different) ...
    # ... SAME footer ...
    doc.build(story)
    return buffer
```

### The Template Method Pattern Solution

The Template Method Pattern defines the **skeleton of an algorithm** in a base class, letting subclasses override specific steps without changing the overall structure.

```python
from abc import ABC, abstractmethod
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import mm
import io

# ============================================
# STEP 1: Abstract Base Class with the Template
# ============================================
class ReportTemplate(ABC):
    """
    Template Method Pattern: defines the algorithm skeleton.
    Subclasses customize specific steps without changing the flow.
    """
    
    def __init__(self, student: str, subject: str):
        self.student = student
        self.subject = subject
        self.styles = getSampleStyleSheet()
        self.buffer = io.BytesIO()
        self.doc = SimpleDocTemplate(self.buffer, pagesize=A4)
        self.story = []
    
    # ============================================
    # THE TEMPLATE METHOD — defines the algorithm
    # ============================================
    def generate(self) -> io.BytesIO:
        """
        The 'Template Method' — calls steps in a fixed order.
        Subclasses CANNOT override this (well, they shouldn't).
        """
        self._add_header()
        self._add_metadata()
        self._add_content()      # <-- This is the customizable step
        self._add_footer()
        self._build()
        return self._get_result()
    
    # ============================================
    # Common steps (implemented here)
    # ============================================
    def _add_header(self):
        """Standard header for all reports."""
        title = Paragraph(
            f"<b>Markly Grading Report</b>",
            self.styles["Title"]
        )
        self.story.append(title)
        self.story.append(Spacer(1, 12))
    
    def _add_metadata(self):
        """Student and subject info — same for all reports."""
        data = [
            ["Student:", self.student],
            ["Subject:", self.subject],
            ["Date:", "2026-06-25"],
        ]
        table = Table(data, colWidths=[30*mm, None])
        self.story.append(table)
        self.story.append(Spacer(1, 20))
    
    def _add_footer(self):
        """Standard footer."""
        footer = Paragraph(
            "<i>Generated by Markly AI Grading System</i>",
            self.styles["Normal"]
        )
        self.story.append(Spacer(1, 30))
        self.story.append(footer)
    
    def _build(self):
        """Assemble the PDF."""
        self.doc.build(self.story)
    
    def _get_result(self) -> io.BytesIO:
        """Return the completed buffer."""
        self.buffer.seek(0)
        return self.buffer
    
    # ============================================
    # Abstract step — MUST be implemented by subclasses
    # ============================================
    @abstractmethod
    def _add_content(self):
        """
        The 'hook' — subclasses define WHAT goes in the middle.
        This is the only step that changes between report types.
        """
        pass


# ============================================
# STEP 2: Concrete Reports — customize only the content
# ============================================
class ImageReport(ReportTemplate):
    """Report with annotated assignment image."""
    
    def __init__(self, student: str, subject: str, image_buffer: io.BytesIO, feedback: str):
        super().__init__(student, subject)
        self.image_buffer = image_buffer
        self.feedback = feedback
    
    def _add_content(self):
        """Add the annotated image and feedback text."""
        from reportlab.platypus import Image as RLImage
        
        # Add the annotated image
        img = RLImage(self.image_buffer, width=400, height=300)
        self.story.append(img)
        self.story.append(Spacer(1, 20))
        
        # Add feedback
        self.story.append(Paragraph("<b>Teacher Feedback:</b>", self.styles["Heading2"]))
        self.story.append(Paragraph(self.feedback, self.styles["Normal"]))


class TextReport(ReportTemplate):
    """Text-only feedback report."""
    
    def __init__(self, student: str, subject: str, feedback: str, grade: str):
        super().__init__(student, subject)
        self.feedback = feedback
        self.grade = grade
    
    def _add_content(self):
        """Add structured text feedback."""
        # Grade display
        grade_para = Paragraph(
            f"<b>Overall Grade:</b> {self.grade}",
            self.styles["Heading1"]
        )
        self.story.append(grade_para)
        self.story.append(Spacer(1, 20))
        
        # Detailed feedback
        self.story.append(Paragraph("<b>Detailed Feedback:</b>", self.styles["Heading2"]))
        self.story.append(Paragraph(self.feedback, self.styles["Normal"]))


class SummaryReport(ReportTemplate):
    """Report with statistics and charts."""
    
    def __init__(self, student: str, subject: str, stats: dict):
        super().__init__(student, subject)
        self.stats = stats
    
    def _add_content(self):
        """Add statistics table."""
        self.story.append(Paragraph("<b>Performance Summary:</b>", self.styles["Heading2"]))
        
        data = [["Metric", "Value"]]
        for key, value in self.stats.items():
            data.append([key, str(value)])
        
        table = Table(data, colWidths=[50*mm, 30*mm])
        self.story.append(table)


# ============================================
# EXAMPLE USAGE
# ============================================
if __name__ == "__main__":
    # Create different reports using the SAME algorithm structure
    image_report = ImageReport(
        "Alice Johnson", "Math",
        io.BytesIO(b"fake_image_data"),
        "Excellent work on the quadratic equations!"
    )
    
    text_report = TextReport(
        "Bob Smith", "English",
        "Strong thesis, but needs more textual evidence.",
        "B+"
    )
    
    summary_report = SummaryReport(
        "Carol White", "Science",
        {"Average Grade": "87%", "Assignments Completed": "12/15"}
    )
    
    # All use the same .generate() method
    pdf1 = image_report.generate()
    pdf2 = text_report.generate()
    pdf3 = summary_report.generate()
    
    print(f"Image report: {len(pdf1.read())} bytes")
    print(f"Text report: {len(pdf2.read())} bytes")
    print(f"Summary report: {len(pdf3.read())} bytes")
```

### The Power of the Template

Notice: `generate()` is defined **once** in the base class. All reports follow the exact same flow. Subclasses only override `_add_content()`.

| Report Type | Customizes | Reuses |
|---|---|---|
| ImageReport | `_add_content()` | Header, metadata, footer, build logic |
| TextReport | `_add_content()` | Header, metadata, footer, build logic |
| SummaryReport | `_add_content()` | Header, metadata, footer, build logic |

### The Pattern in One Sentence

> **The Template Method Pattern defines the skeleton of an algorithm in a base class, letting subclasses customize specific steps without changing the overall structure.**

---

## 6. The Decorator Pattern — Adding Behavior Without Changing Code

### The Problem

Markly's annotation engine (`markup.py`) draws teacher-style markings on student assignments. Different assignments need different combinations of annotations:
- Some need ticks (✓) for correct answers
- Some need crosses (✗) for wrong answers
- Some need correction boxes around errors
- Some need margin notes
- Some need summary blocks at the bottom

You could create a class for every combination:
- `TickAnnotator`
- `TickCrossAnnotator`
- `TickCrossBoxAnnotator`
- `TickCrossBoxMarginAnnotator`
- ... explosion of classes!

### The Decorator Pattern Solution

The Decorator Pattern lets you **wrap objects** to add behavior dynamically, without modifying the original class.

```python
from abc import ABC, abstractmethod
from PIL import Image, ImageDraw
import io
import random

# ============================================
# STEP 1: Component Interface
# ============================================
class ImageAnnotator(ABC):
    """Base interface for all annotators."""
    
    @abstractmethod
    def annotate(self, image_bytes: bytes) -> bytes:
        """Takes image bytes, returns annotated image bytes."""
        pass


# ============================================
# STEP 2: Concrete Component — the base image
# ============================================
class BaseImage(ImageAnnotator):
    """The 'raw' image — no annotations yet."""
    
    def annotate(self, image_bytes: bytes) -> bytes:
        # Just return as-is — this is our starting point
        return image_bytes


# ============================================
# STEP 3: Abstract Decorator — wraps another annotator
# ============================================
class AnnotationDecorator(ImageAnnotator):
    """
    Base class for all decorators.
    Each decorator wraps another annotator and adds its own behavior.
    """
    
    def __init__(self, wrapped: ImageAnnotator):
        self._wrapped = wrapped
    
    def annotate(self, image_bytes: bytes) -> bytes:
        # First, let the wrapped annotator do its thing
        image_bytes = self._wrapped.annotate(image_bytes)
        # Then add our own annotations
        return self._add_annotations(image_bytes)
    
    @abstractmethod
    def _add_annotations(self, image_bytes: bytes) -> bytes:
        """Each decorator implements its own markings."""
        pass


# ============================================
# STEP 4: Concrete Decorators — each adds one type of marking
# ============================================
class TickDecorator(AnnotationDecorator):
    """Adds check marks for correct answers."""
    
    def _add_annotations(self, image_bytes: bytes) -> bytes:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
        draw = ImageDraw.Draw(img)
        
        # Draw a tick mark at a position
        cx, cy = 100, 100
        size = 20
        # Simple tick drawing
        draw.line([(cx-size, cy), (cx, cy+size)], fill="green", width=3)
        draw.line([(cx, cy+size), (cx+size, cy-size)], fill="green", width=3)
        
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")
        return buffer.getvalue()


class CrossDecorator(AnnotationDecorator):
    """Adds cross marks for wrong answers."""
    
    def _add_annotations(self, image_bytes: bytes) -> bytes:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
        draw = ImageDraw.Draw(img)
        
        cx, cy = 200, 100
        size = 15
        draw.line([(cx-size, cy-size), (cx+size, cy+size)], fill="red", width=3)
        draw.line([(cx+size, cy-size), (cx-size, cy+size)], fill="red", width=3)
        
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")
        return buffer.getvalue()


class CorrectionBoxDecorator(AnnotationDecorator):
    """Adds rounded boxes around errors."""
    
    def _add_annotations(self, image_bytes: bytes) -> bytes:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
        draw = ImageDraw.Draw(img)
        
        # Draw rounded rectangle around an error area
        draw.rounded_rectangle([50, 150, 300, 200], radius=10, outline="orange", width=3)
        
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")
        return buffer.getvalue()


class MarginNoteDecorator(AnnotationDecorator):
    """Adds a note in the margin."""
    
    def __init__(self, wrapped: ImageAnnotator, note_text: str):
        super().__init__(wrapped)
        self.note_text = note_text
    
    def _add_annotations(self, image_bytes: bytes) -> bytes:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
        draw = ImageDraw.Draw(img)
        
        # Draw margin note background
        w, h = img.size
        draw.rectangle([w-200, 50, w-20, 150], fill=(255, 255, 200, 180), outline="black")
        draw.text((w-190, 60), self.note_text, fill="black")
        
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")
        return buffer.getvalue()


class SummaryBlockDecorator(AnnotationDecorator):
    """Adds a summary feedback block at the bottom."""
    
    def __init__(self, wrapped: ImageAnnotator, summary: str):
        super().__init__(wrapped)
        self.summary = summary
    
    def _add_annotations(self, image_bytes: bytes) -> bytes:
        img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
        draw = ImageDraw.Draw(img)
        
        w, h = img.size
        # Yellow summary box at bottom
        draw.rectangle([20, h-120, w-20, h-20], fill=(255, 255, 150, 200), outline="black")
        draw.text((30, h-110), "Summary:", fill="black")
        draw.text((30, h-90), self.summary[:50], fill="black")
        
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")
        return buffer.getvalue()


# ============================================
# EXAMPLE: Compose annotations like LEGO blocks
# ============================================
if __name__ == "__main__":
    # Create a blank white image for demo
    base_img = Image.new("RGBA", (400, 300), "white")
    img_buffer = io.BytesIO()
    base_img.save(img_buffer, format="PNG")
    image_bytes = img_buffer.getvalue()
    
    # ============================================
    # Compose different annotation combinations!
    # ============================================
    
    # Simple: just ticks and crosses
    simple_annotator = CrossDecorator(TickDecorator(BaseImage()))
    result1 = simple_annotator.annotate(image_bytes)
    print(f"Simple annotated: {len(result1)} bytes")
    
    # Full: ticks + crosses + boxes + margin note + summary
    full_annotator = SummaryBlockDecorator(
        MarginNoteDecorator(
            CorrectionBoxDecorator(
                CrossDecorator(
                    TickDecorator(BaseImage())
                )
            ),
            "Check your algebra!"
        ),
        "Good effort overall. Focus on showing your work."
    )
    result2 = full_annotator.annotate(image_bytes)
    print(f"Full annotated: {len(result2)} bytes")
    
    # Another combination: only margin note and summary (no ticks/crosses)
    feedback_only = SummaryBlockDecorator(
        MarginNoteDecorator(BaseImage(), "See me after class"),
        "Needs improvement in all areas."
    )
    result3 = feedback_only.annotate(image_bytes)
    print(f"Feedback only: {len(result3)} bytes")
```

### Why Decorators Are Perfect for Markup

| Without Decorator | With Decorator |
|---|---|
| 2⁵ = 32 classes for all combinations | 5 decorator classes + compose at runtime |
| Adding a new annotation type → edit all combinations | Add one new decorator class |
| Can't mix and match per assignment | Compose exactly what's needed for each assignment |

### The Pattern in One Sentence

> **The Decorator Pattern lets you add new behavior to objects by wrapping them, without changing their original code.**

---

## 7. The Facade Pattern — Hiding Complexity Behind a Simple Interface

### The Problem

Markly's grading pipeline is complex:
1. Extract text from file (PDF/DOCX/image)
2. Build AI prompt with subject-specific rubric
3. Call AI API with retries and fallbacks
4. Parse the response to extract grade and feedback
5. Generate annotations on the assignment image
6. Create a PDF report
7. Save to student database
8. Update the UI

Exposing all this to the UI layer would be a nightmare. The UI shouldn't know about PyMuPDF, OpenAI API details, or ReportLab.

### The Facade Pattern Solution

The Facade Pattern provides a **simple, unified interface** to a complex subsystem.

```python
import io
from typing import Optional

# ============================================
# The Complex Subsystems (simplified)
# ============================================
class FileExtractor:
    """Subsystem 1: Extracts text from files."""
    def extract(self, file_bytes: bytes, filename: str) -> str:
        # Would use ExtractorFactory in real Markly
        return f"Extracted text from {filename}"

class AIGrader:
    """Subsystem 2: Calls AI APIs."""
    def grade(self, text: str, subject: str) -> dict:
        return {
            "grade": "85/100",
            "feedback": "Good work! Improve step-by-step explanations.",
            "raw_response": "...",
        }

class ImageMarker:
    """Subsystem 3: Draws annotations."""
    def annotate(self, image_bytes: bytes, feedback: str) -> bytes:
        return image_bytes  # Simplified

class ReportBuilder:
    """Subsystem 4: Generates PDFs."""
    def build(self, student: str, subject: str, image: bytes, feedback: str) -> io.BytesIO:
        return io.BytesIO(b"pdf_data")

class StudentDB:
    """Subsystem 5: Persists records."""
    def save(self, student: str, subject: str, grade: str, feedback: str):
        print(f"Saved record for {student}")

class NotificationService:
    """Subsystem 6: Sends notifications."""
    def notify(self, student: str, message: str):
        print(f"Notification sent to {student}")


# ============================================
# THE FACADE: One simple method for the UI
# ============================================
class MarklyFacade:
    """
    Facade Pattern: Hides the entire grading pipeline complexity.
    The UI calls ONE method: grade_assignment().
    """
    
    def __init__(self):
        # Initialize all subsystems
        self.extractor = FileExtractor()
        self.grader = AIGrader()
        self.marker = ImageMarker()
        self.reporter = ReportBuilder()
        self.database = StudentDB()
        self.notifier = NotificationService()
    
    def grade_assignment(
        self,
        student: str,
        subject: str,
        file_bytes: bytes,
        filename: str,
        image_bytes: Optional[bytes] = None
    ) -> dict:
        """
        The ONE method the UI needs to know about.
        Everything else happens behind the scenes.
        """
        try:
            # Step 1: Extract text
            extracted_text = self.extractor.extract(file_bytes, filename)
            
            # Step 2: Grade with AI
            ai_result = self.grader.grade(extracted_text, subject)
            
            # Step 3: Annotate image (if provided)
            annotated_image = None
            if image_bytes:
                annotated_image = self.marker.annotate(
                    image_bytes, 
                    ai_result["feedback"]
                )
            
            # Step 4: Generate report
            report = self.reporter.build(
                student, subject,
                annotated_image or io.BytesIO(),
                ai_result["feedback"]
            )
            
            # Step 5: Save to database
            self.database.save(
                student, subject,
                ai_result["grade"],
                ai_result["feedback"]
            )
            
            # Step 6: Notify student
            self.notifier.notify(
                student,
                f"Your {subject} assignment has been graded: {ai_result['grade']}"
            )
            
            # Return a clean result object
            return {
                "success": True,
                "grade": ai_result["grade"],
                "feedback": ai_result["feedback"],
                "report": report,
                "annotated_image": annotated_image,
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
            }


# ============================================
# EXAMPLE: The UI just calls one method
# ============================================
if __name__ == "__main__":
    # Initialize the facade once
    markly = MarklyFacade()
    
    # UI code — incredibly simple!
    result = markly.grade_assignment(
        student="Alice Johnson",
        subject="Math",
        file_bytes=b"pdf_content_here",
        filename="homework.pdf",
        image_bytes=b"optional_image_data"
    )
    
    if result["success"]:
        print(f"✅ Grade: {result['grade']}")
        print(f"📝 Feedback: {result['feedback']}")
        print(f"📄 Report: {len(result['report'].read())} bytes")
    else:
        print(f"❌ Error: {result['error']}")
```

### What the Facade Hides

| Complexity | Hidden Behind |
|---|---|
| File format detection and extraction | `self.extractor.extract()` |
| AI prompt construction and API calls | `self.grader.grade()` |
| Pillow image manipulation | `self.marker.annotate()` |
| ReportLab PDF generation | `self.reporter.build()` |
| JSON file I/O and locking | `self.database.save()` |
| Error handling and retries | The `try/except` block |

### The Pattern in One Sentence

> **The Facade Pattern provides a simple, unified interface to a complex subsystem, hiding implementation details from the client.**

---

## 8. The Pipeline Pattern — Assembly Line for Data

### The Problem

Data in Markly flows through a series of transformations:
```
Raw File → Extracted Text → AI Prompt → AI Response → Parsed Result → Annotated Image → PDF Report
```

Each step depends on the previous. Errors at any stage should stop the pipeline. Some stages can run in parallel. Without a pattern, this becomes a tangled mess of function calls.

### The Pipeline Pattern Solution

The Pipeline Pattern chains processing stages where **the output of one stage is the input of the next**.

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, List, Optional
import io

# ============================================
# STEP 1: Define the data that flows through the pipeline
# ============================================
@dataclass
class GradingContext:
    """
    The 'payload' that moves through the pipeline.
    Each stage adds to or modifies this object.
    """
    student: str
    subject: str
    filename: str
    file_bytes: bytes
    
    # These get filled in as the pipeline runs
    extracted_text: Optional[str] = None
    ai_prompt: Optional[str] = None
    ai_response: Optional[str] = None
    grade: Optional[str] = None
    feedback: Optional[str] = None
    annotated_image: Optional[bytes] = None
    pdf_report: Optional[io.BytesIO] = None
    errors: List[str] = field(default_factory=list)


# ============================================
# STEP 2: Define the Pipeline Stage Interface
# ============================================
class PipelineStage(ABC):
    """Each stage in the pipeline implements this."""
    
    @abstractmethod
    def process(self, context: GradingContext) -> GradingContext:
        """
        Takes a context, does work, returns the (possibly modified) context.
        If a stage fails, it should add to context.errors and return.
        """
        pass
    
    @property
    @abstractmethod
    def name(self) -> str:
        """Human-readable name for logging."""
        pass


# ============================================
# STEP 3: Concrete Pipeline Stages
# ============================================
class ExtractionStage(PipelineStage):
    """Stage 1: Extract text from the uploaded file."""
    
    name = "Text Extraction"
    
    def process(self, context: GradingContext) -> GradingContext:
        # Would use ExtractorFactory in real Markly
        ext = context.filename.split('.')[-1].lower()
        
        if ext == "pdf":
            context.extracted_text = "[PDF text extracted]"
        elif ext == "docx":
            context.extracted_text = "[DOCX text extracted]"
        elif ext in ("png", "jpg", "jpeg"):
            context.extracted_text = "[OCR text extracted]"
        else:
            context.errors.append(f"Unsupported file type: .{ext}")
        
        return context


class PromptBuildingStage(PipelineStage):
    """Stage 2: Build the AI prompt with subject rubric."""
    
    name = "Prompt Building"
    
    def process(self, context: GradingContext) -> GradingContext:
        if context.errors:
            return context  # Skip if previous stage failed
        
        rubrics = {
            "Math": "Focus on correctness and step-by-step working.",
            "English": "Focus on thesis, evidence, and grammar.",
            "Science": "Focus on hypothesis, methodology, and analysis.",
        }
        
        rubric = rubrics.get(context.subject, "General grading.")
        
        context.ai_prompt = f"""You are a {context.subject} teacher.
        
        RUBRIC: {rubric}
        
        STUDENT WORK:
        {context.extracted_text}
        
        Provide grade and detailed feedback.
        """
        
        return context


class AIGradingStage(PipelineStage):
    """Stage 3: Call the AI API."""
    
    name = "AI Grading"
    
    def process(self, context: GradingContext) -> GradingContext:
        if context.errors:
            return context
        
        # Simulated API call
        import re
        
        # In real Markly, this calls openai.AsyncOpenAI
        context.ai_response = f"""
        Grade: 85/100
        Feedback: Good work on this {context.subject.lower()} assignment!
        Some areas for improvement noted.
        """
        
        # Extract grade
        grade_match = re.search(r'(\\d{1,3})/100', context.ai_response)
        context.grade = grade_match.group(0) if grade_match else "N/A"
        context.feedback = context.ai_response
        
        return context


class AnnotationStage(PipelineStage):
    """Stage 4: Draw annotations on the assignment image."""
    
    name = "Image Annotation"
    
    def process(self, context: GradingContext) -> GradingContext:
        if context.errors:
            return context
        
        # Only annotate if we have an image file
        if context.filename.split('.')[-1].lower() in ("png", "jpg", "jpeg"):
            # Would use decorators in real Markly
            context.annotated_image = b"[annotated_image_data]"
        
        return context


class ReportGenerationStage(PipelineStage):
    """Stage 5: Generate the PDF report."""
    
    name = "Report Generation"
    
    def process(self, context: GradingContext) -> GradingContext:
        if context.errors:
            return context
        
        # Would use ReportTemplate in real Markly
        context.pdf_report = io.BytesIO(b"[pdf_report_data]")
        
        return context


class PersistenceStage(PipelineStage):
    """Stage 6: Save to database."""
    
    name = "Persistence"
    
    def process(self, context: GradingContext) -> GradingContext:
        if context.errors:
            return context
        
        # Would use StudentDatabase singleton
        print(f"💾 Saved: {context.student} - {context.subject} - {context.grade}")
        
        return context


# ============================================
# STEP 4: The Pipeline — orchestrates all stages
# ============================================
class GradingPipeline:
    """
    Pipeline Pattern: Chains stages together.
    Each stage's output becomes the next stage's input.
    """
    
    def __init__(self):
        self.stages: List[PipelineStage] = []
    
    def add_stage(self, stage: PipelineStage):
        """Add a stage to the pipeline."""
        self.stages.append(stage)
        return self  # Fluent interface
    
    def execute(self, context: GradingContext) -> GradingContext:
        """
        Run all stages in order.
        If any stage adds errors, subsequent stages skip gracefully.
        """
        print(f"🚀 Starting pipeline for {context.student}'s {context.subject} assignment")
        print("=" * 60)
        
        for stage in self.stages:
            print(f"  ▶️ {stage.name}...")
            context = stage.process(context)
            
            if context.errors:
                print(f"  ❌ {stage.name} failed: {context.errors[-1]}")
                break
            else:
                print(f"  ✅ {stage.name} complete")
        
        print("=" * 60)
        return context


# ============================================
# EXAMPLE USAGE
# ============================================
if __name__ == "__main__":
    # Build the pipeline
    pipeline = GradingPipeline()
    pipeline.add_stage(ExtractionStage())
    pipeline.add_stage(PromptBuildingStage())
    pipeline.add_stage(AIGradingStage())
    pipeline.add_stage(AnnotationStage())
    pipeline.add_stage(ReportGenerationStage())
    pipeline.add_stage(PersistenceStage())
    
    # Run it
    context = GradingContext(
        student="Alice Johnson",
        subject="Math",
        filename="homework.pdf",
        file_bytes=b"pdf_data"
    )
    
    result = pipeline.execute(context)
    
    print(f"\\n📊 FINAL RESULT:")
    print(f"   Grade: {result.grade}")
    print(f"   Feedback: {result.feedback[:50]}..." if result.feedback else "   No feedback")
    print(f"   Errors: {result.errors}" if result.errors else "   No errors")
    
    # Try with an unsupported file
    print("\\n" + "=" * 60)
    bad_context = GradingContext(
        student="Bob Smith",
        subject="English",
        filename="homework.xyz",  # Unsupported!
        file_bytes=b"unknown_data"
    )
    
    bad_result = pipeline.execute(bad_context)
    print(f"\\n📊 FINAL RESULT:")
    print(f"   Errors: {bad_result.errors}")
```

### Why Pipelines Are Powerful

| Feature | How Pipeline Delivers |
|---|---|
| **Visibility** | Each stage has a name — easy to log and monitor |
| **Error handling** | One failure stops the line; no partial states |
| **Extensibility** | Add a new stage without touching existing ones |
| **Testability** | Test each stage in isolation |
| **Reusability** | Same pipeline, different configurations |

### The Pattern in One Sentence

> **The Pipeline Pattern chains processing stages where each stage transforms data and passes it to the next, creating a clear, linear flow.**

---

## 9. The Circuit Breaker Pattern — Graceful Degradation

### The Problem

Markly calls external AI APIs (OpenAI, OpenRouter). These fail:
- **Rate limits** (429 Too Many Requests)
- **Server errors** (500, 502, 503)
- **Network timeouts**
- **API keys expired**

Without protection, Markly would:
- Hang the UI waiting for a dead API
- Waste time retrying a service that's down
- Crash with unhandled exceptions

### The Circuit Breaker Pattern Solution

The Circuit Breaker Pattern prevents an application from repeatedly trying to execute an operation that's likely to fail. It has three states:

```
┌─────────────┐     failures > threshold     ┌─────────────┐
│   CLOSED    │ ───────────────────────────► │    OPEN     │
│  (normal)   │                              │  (failing)  │
└─────────────┘                              └─────────────┘
       ▲                                            │
       │         timeout expires                    │
       └────────────────────────────────────────────┘
       
       During OPEN state: fast-fail, use fallback
```

```python
import time
import asyncio
from enum import Enum, auto
from dataclasses import dataclass
from typing import Callable, Optional, Any

# ============================================
# STEP 1: Circuit Breaker States
# ============================================
class CircuitState(Enum):
    CLOSED = auto()      # Normal operation — requests pass through
    OPEN = auto()        # Failing fast — requests immediately rejected
    HALF_OPEN = auto()   # Testing if service recovered


# ============================================
# STEP 2: The Circuit Breaker
# ============================================
@dataclass
class CircuitBreakerConfig:
    """Configuration for circuit breaker behavior."""
    failure_threshold: int = 3        # Failures before opening
    recovery_timeout: float = 30.0    # Seconds before trying again
    half_open_max_calls: int = 1      # Test calls in half-open state


class CircuitBreaker:
    """
    Circuit Breaker Pattern: Prevents cascade failures.
    
    CLOSED:  Requests go through normally.
    OPEN:    Requests immediately fail — use fallback.
    HALF_OPEN: Allow limited test calls to check recovery.
    """
    
    def __init__(self, name: str, config: CircuitBreakerConfig = None):
        self.name = name
        self.config = config or CircuitBreakerConfig()
        
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.last_failure_time: Optional[float] = None
        self.half_open_calls = 0
    
    async def call(self, operation: Callable, fallback: Callable, *args, **kwargs) -> Any:
        """
        Execute an operation through the circuit breaker.
        If circuit is OPEN, use fallback immediately.
        """
        if self.state == CircuitState.OPEN:
            if self._should_attempt_reset():
                self.state = CircuitState.HALF_OPEN
                self.half_open_calls = 0
                print(f"🔶 [{self.name}] Circuit entering HALF_OPEN state")
            else:
                print(f"🔴 [{self.name}] Circuit OPEN — using fallback")
                return await fallback(*args, **kwargs)
        
        if self.state == CircuitState.HALF_OPEN:
            if self.half_open_calls >= self.config.half_open_max_calls:
                print(f"🔴 [{self.name}] Circuit HALF_OPEN limit reached — using fallback")
                return await fallback(*args, **kwargs)
            self.half_open_calls += 1
        
        # Attempt the operation
        try:
            result = await operation(*args, **kwargs)
            self._on_success()
            return result
            
        except Exception as e:
            self._on_failure()
            # If circuit is now open, use fallback
            if self.state == CircuitState.OPEN:
                return await fallback(*args, **kwargs)
            raise  # Re-raise if circuit is still closed
    
    def _on_success(self):
        """Reset on successful call."""
        if self.state == CircuitState.HALF_OPEN:
            print(f"🟢 [{self.name}] Recovery confirmed — circuit CLOSED")
            self.state = CircuitState.CLOSED
        
        self.failure_count = 0
        self.last_failure_time = None
    
    def _on_failure(self):
        """Record failure and potentially open circuit."""
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.failure_count >= self.config.failure_threshold:
            self.state = CircuitState.OPEN
            print(f"🔴 [{self.name}] Circuit OPENED after {self.failure_count} failures")
    
    def _should_attempt_reset(self) -> bool:
        """Check if enough time has passed to try recovery."""
        if self.last_failure_time is None:
            return True
        return (time.time() - self.last_failure_time) >= self.config.recovery_timeout


# ============================================
# STEP 3: Markly's AI Service with Circuit Breaker
# ============================================
class AIGradingService:
    """
    Markly's AI service with circuit breaker protection.
    Falls back to OpenRouter if OpenAI is failing.
    """
    
    def __init__(self):
        # Separate circuit breakers for each provider
        self.openai_breaker = CircuitBreaker("OpenAI", CircuitBreakerConfig(
            failure_threshold=2,
            recovery_timeout=60.0
        ))
        self.openrouter_breaker = CircuitBreaker("OpenRouter", CircuitBreakerConfig(
            failure_threshold=3,
            recovery_timeout=45.0
        ))
    
    async def grade(self, prompt: str, subject: str) -> dict:
        """
        Grade with AI, protected by circuit breakers.
        Tries OpenAI first, falls back to OpenRouter.
        """
        # Try OpenAI first
        try:
            result = await self.openai_breaker.call(
                self._call_openai,
                self._fallback_openrouter,  # Fallback if OpenAI circuit opens
                prompt
            )
            return result
        except Exception:
            # If OpenAI completely fails, try OpenRouter directly
            return await self.openrouter_breaker.call(
                self._call_openrouter,
                self._fallback_local,  # Ultimate fallback
                prompt, subject
            )
    
    async def _call_openai(self, prompt: str) -> dict:
        """Call OpenAI API."""
        # Simulate occasional failures
        import random
        if random.random() < 0.6:  # 60% failure rate for demo
            raise Exception("OpenAI rate limit exceeded (429)")
        
        print("   ✅ OpenAI responded successfully")
        return {"grade": "A", "feedback": "Excellent work!", "source": "OpenAI"}
    
    async def _call_openrouter(self, prompt: str) -> dict:
        """Call OpenRouter API."""
        import random
        if random.random() < 0.3:  # 30% failure rate
            raise Exception("OpenRouter timeout")
        
        print("   ✅ OpenRouter responded successfully")
        return {"grade": "A-", "feedback": "Very good!", "source": "OpenRouter"}
    
    async def _fallback_local(self, prompt: str, subject: str) -> dict:
        """Ultimate fallback: local heuristic grading."""
        print("   ⚠️ Using local fallback grading")
        return {
            "grade": "Pending",
            "feedback": "AI services unavailable. Manual review required.",
            "source": "Local Fallback"
        }
    
    async def _fallback_openrouter(self, prompt: str) -> dict:
        """Called when OpenAI circuit is open."""
        print("   🔄 OpenAI circuit open — trying OpenRouter")
        return await self._call_openrouter(prompt)


# ============================================
# EXAMPLE: Circuit breaker in action
# ============================================
async def demo():
    service = AIGradingService()
    
    print("=" * 60)
    print("DEMO: Circuit Breaker with simulated failures")
    print("=" * 60)
    
    # Run multiple grading requests
    for i in range(8):
        print(f"\\n📋 Request {i+1}:")
        result = await service.grade("Grade this essay", "English")
        print(f"   Result: {result['grade']} from {result['source']}")
        await asyncio.sleep(0.5)  # Small delay between requests
    
    print("\\n" + "=" * 60)
    print("Waiting for circuit to reset...")
    print("=" * 60)
    await asyncio.sleep(3)  # Wait less than recovery timeout
    
    # This should still use fallback (circuit still open)
    print("\\n📋 Request after short wait:")
    result = await service.grade("Grade this essay", "English")
    print(f"   Result: {result['grade']} from {result['source']}")
    
    # Wait for full recovery
    print("\\nWaiting 60 seconds for circuit recovery...")
    await asyncio.sleep(2)  # In real demo, wait 60s
    
    # Reset for demo purposes
    service.openai_breaker.state = CircuitState.CLOSED
    service.openai_breaker.failure_count = 0
    
    print("\\n📋 Request after circuit reset:")
    result = await service.grade("Grade this essay", "English")
    print(f"   Result: {result['grade']} from {result['source']}")


if __name__ == "__main__":
    asyncio.run(demo())
```

### Circuit Breaker States Explained

| State | What Happens | When It Transitions |
|---|---|---|
| **CLOSED** | Requests pass through normally | Default state; after successful HALF_OPEN call |
| **OPEN** | Requests immediately rejected; fallback used | After `failure_threshold` failures |
| **HALF_OPEN** | Limited test calls allowed to check recovery | After `recovery_timeout` seconds in OPEN |

### Why This Saves Markly

| Scenario | Without Circuit Breaker | With Circuit Breaker |
|---|---|---|
| OpenAI rate-limits | UI hangs for 30s, then crashes | Immediate fallback to OpenRouter |
| Both APIs down | Complete system failure | Graceful degradation to local fallback |
| Network blip | Retries forever, wastes resources | Fast-fail after threshold |
| API recovers | Manual restart required | Automatic recovery testing |

### The Pattern in One Sentence

> **The Circuit Breaker Pattern prevents an application from repeatedly trying operations that are likely to fail, providing fast failure and graceful fallback instead.**

---

## 10. How Patterns Work Together in Markly

No pattern exists in isolation. Markly is a **composition** of patterns working together:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MARKLY ARCHITECTURE                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────┐     Factory Pattern     ┌─────────────────────┐  │
│  │  File Upload │ ───────────────────────► │ PDFExtractor        │  │
│  │   (UI Layer) │                          │ DOCXExtractor       │  │
│  └─────────────┘                          │ ImageExtractor      │  │
│       │                                     └─────────────────────┘  │
│       │                                              │               │
│       │     Pipeline Pattern                         │               │
│       ▼                                              ▼               │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  EXTRACTION → PROMPT BUILDING → AI GRADING → ANNOTATION     │    │
│  │  (Each stage is a PipelineStage that transforms GradingContext)│ │
│  └─────────────────────────────────────────────────────────────┘    │
│       │                                                              │
│       │     Strategy Pattern                                         │
│       ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  MathGradingStrategy │ EnglishGradingStrategy │ Science...   │    │
│  │  (Each builds different prompts, parses differently)       │    │
│  └─────────────────────────────────────────────────────────────┘    │
│       │                                                              │
│       │     Circuit Breaker Pattern                                  │
│       ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  OpenAI API ◄──Circuit Breaker──► OpenRouter API             │    │
│  │  (Falls back automatically if primary fails)                 │    │
│  └─────────────────────────────────────────────────────────────┘    │
│       │                                                              │
│       │     Decorator Pattern                                        │
│       ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  BaseImage → TickDecorator → CrossDecorator → BoxDecorator  │    │
│  │  → MarginNoteDecorator → SummaryBlockDecorator              │    │
│  │  (Composable annotations for each assignment)                │    │
│  └─────────────────────────────────────────────────────────────┘    │
│       │                                                              │
│       │     Template Method Pattern                                  │
│       ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  ReportTemplate (base)                                        │    │
│  │  ├── ImageReport (customizes _add_content)                  │    │
│  │  ├── TextReport (customizes _add_content)                    │    │
│  │  └── SummaryReport (customizes _add_content)                │    │
│  └─────────────────────────────────────────────────────────────┘    │
│       │                                                              │
│       │     Singleton Pattern                                        │
│       ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  StudentDatabase (Singleton)                                  │    │
│  │  (One shared instance, thread-safe JSON persistence)        │    │
│  └─────────────────────────────────────────────────────────────┘    │
│       │                                                              │
│       │     Facade Pattern                                           │
│       ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  MarklyFacade.grade_assignment()                            │    │
│  │  (One method the UI calls — everything else is hidden)      │    │
│  └─────────────────────────────────────────────────────────────┘    │
│       │                                                              │
│       ▼                                                              │
│  ┌─────────────┐                                                     │
│  │   UI Layer  │  ← User sees: "Grade: A | Feedback: Great work!"   │
│  │   (Panel)   │                                                     │
│  └─────────────┘                                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Pattern Interactions

| Pattern Pair | How They Work Together |
|---|---|
| **Factory + Strategy** | Factory creates the right `GradingStrategy` based on subject |
| **Pipeline + Circuit Breaker** | Pipeline's AI stage is protected by circuit breaker |
| **Template Method + Decorator** | Report template uses decorator-composed images |
| **Facade + Singleton** | Facade provides the single entry point; Singleton ensures one database |
| **Strategy + Template Method** | Strategy determines rubric; Template Method structures the report |

---

## 11. Key Takeaways

### For Beginners: Start Here

1. **Patterns are tools, not rules.** Don't force a pattern where a simple function works. Markly uses patterns because it solves real complexity — not for show.

2. **Learn the "why" before the "how."** Each pattern solves a specific problem:
   - **Factory** → "I need to create different objects based on input"
   - **Strategy** → "I need to swap algorithms at runtime"
   - **Singleton** → "I need exactly one instance of something"
   - **Template Method** → "I have an algorithm with some fixed and some variable steps"
   - **Decorator** → "I need to add behavior without changing existing code"
   - **Facade** → "I need to hide complexity behind a simple interface"
   - **Pipeline** → "I have data that flows through multiple transformations"
   - **Circuit Breaker** → "I need to handle external service failures gracefully"

3. **Patterns compose.** Real systems use multiple patterns together. Understanding how they interact is more valuable than memorizing individual patterns.

4. **Python makes patterns elegant.** Dynamic typing, first-class functions, and decorators make Python implementations cleaner than Java or C++ equivalents.

5. **Testability is a hidden benefit.** Every pattern in this primer makes Markly easier to test. Factories let you inject mocks. Strategies let you test grading logic without calling APIs. Pipelines let you test stages in isolation.

### Markly's Pattern Cheat Sheet

| If Markly needs to... | It uses... | Found in... |
|---|---|---|
| Create the right file extractor | **Factory Pattern** | `utils.py` — `extract_text_from_file()` |
| Grade differently per subject | **Strategy Pattern** | `personas.py` / `rubrics.py` |
| Ensure one database connection | **Singleton Pattern** | `storage.py` — `StudentDatabase` |
| Generate reports with shared structure | **Template Method Pattern** | `report.py` — `create_marked_pdf()` |
| Draw different annotation combinations | **Decorator Pattern** | `markup.py` — annotation functions |
| Hide grading complexity from UI | **Facade Pattern** | `app.py` — `grade_assignment()` |
| Process assignments step-by-step | **Pipeline Pattern** | `engine.py` — grading flow |
| Handle AI API failures gracefully | **Circuit Breaker Pattern** | `engine.py` — fallback logic |

---

### Final Thought

> **"Design patterns are not about writing code that looks impressive. They're about writing code that others can understand, extend, and maintain — including your future self."**

Markly isn't just a collection of libraries stitched together. It's a thoughtfully architected system where each pattern solves a real problem. When you understand these patterns, you don't just understand Markly — you understand how to build systems that last.

---

*Happy coding. Build things that make sense.*
