# Part 2d — Composite

Lets you treat **individual objects and groups of objects uniformly** via a shared interface — ideal for tree structures (file systems, UI trees, org charts).

```python
from abc import ABC, abstractmethod

class FileSystemItem(ABC):
    @abstractmethod
    def size(self) -> int: ...
    @abstractmethod
    def display(self, indent: int = 0) -> None: ...

class File(FileSystemItem):
    """A 'Leaf' node -- has no children."""
    def __init__(self, name: str, size_kb: int):
        self.name = name
        self._size = size_kb

    def size(self) -> int:
        return self._size

    def display(self, indent: int = 0) -> None:
        print(" " * indent + f"[File] {self.name} ({self._size}KB)")

class Folder(FileSystemItem):
    """A 'Composite' node -- holds children (Files or other Folders)
    and implements the SAME interface as a File."""
    def __init__(self, name: str):
        self.name = name
        self._children: list[FileSystemItem] = []

    def add(self, item: FileSystemItem) -> None:
        self._children.append(item)

    def size(self) -> int:
        # Recursively delegate to children -- works whether they're Files or Folders
        return sum(child.size() for child in self._children)

    def display(self, indent: int = 0) -> None:
        print(" " * indent + f"[Folder] {self.name}/ ({self.size()}KB total)")
        for child in self._children:
            child.display(indent + 2)


# Usage -- treats a single File and a nested Folder tree identically
root = Folder("project")
root.add(File("readme.md", 5))

src = Folder("src")
src.add(File("main.py", 12))
src.add(File("utils.py", 8))
root.add(src)

root.display()
```

**Expected output:**
```
[Folder] project/ (25KB total)
  [File] readme.md (5KB)
  [Folder] src/ (20KB total)
    [File] main.py (12KB)
    [File] utils.py (8KB)
```

---

