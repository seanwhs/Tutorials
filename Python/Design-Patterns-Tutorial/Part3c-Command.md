# Part 3c — Command

Encapsulates a request as a standalone object, letting you parameterize actions, queue them, log them, and support undo/redo.

```python
from abc import ABC, abstractmethod

class Command(ABC):
    @abstractmethod
    def execute(self) -> None: ...
    @abstractmethod
    def undo(self) -> None: ...

class TextDocument:
    """The 'receiver' -- the object that commands actually operate on."""
    def __init__(self):
        self.content = ""

    def insert(self, text: str) -> None:
        self.content += text

    def delete(self, length: int) -> None:
        self.content = self.content[:-length]


class InsertTextCommand(Command):
    def __init__(self, document: TextDocument, text: str):
        self._document = document
        self._text = text

    def execute(self) -> None:
        self._document.insert(self._text)

    def undo(self) -> None:
        # Undo is symmetric: remove exactly what we inserted
        self._document.delete(len(self._text))


class CommandHistory:
    """Keeps a stack of executed commands so we can undo them in reverse order."""
    def __init__(self):
        self._history: list[Command] = []

    def execute(self, command: Command) -> None:
        command.execute()
        self._history.append(command)

    def undo_last(self) -> None:
        if self._history:
            command = self._history.pop()
            command.undo()


# Usage -- client code never directly calls document.insert(); it goes through Commands
doc = TextDocument()
history = CommandHistory()

history.execute(InsertTextCommand(doc, "Hello, "))
history.execute(InsertTextCommand(doc, "World!"))
print(doc.content)   # "Hello, World!"

history.undo_last()
print(doc.content)   # "Hello, "
```

**Expected output:**
```
Hello, World!
Hello, 
```

**Pythonic alternative:** for stateless one-shot actions (no undo needed), a `Command` object is often overkill — a plain function or `functools.partial` does the job:

```python
from functools import partial

def send_email(to: str, subject: str) -> None:
    print(f"Sending email to {to}: {subject}")

# The "command" is just a pre-bound function call, queued for later execution
queued_command = partial(send_email, "user@example.com", "Welcome!")

# ... later, whenever ready ...
queued_command()
```

**Expected output:**
```
Sending email to user@example.com: Welcome!
```

---

