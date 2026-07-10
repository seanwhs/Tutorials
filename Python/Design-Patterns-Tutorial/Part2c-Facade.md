# Part 2c — Facade

Provides a **simplified, unified interface** to a complex subsystem of classes — hides internal wiring behind one clean entry point.

```python
# --- Complex subsystem the client should NOT need to understand ---
class CPU:
    def freeze(self) -> None:
        print("CPU: freezing execution")
    def jump(self, position: int) -> None:
        print(f"CPU: jumping to {position}")
    def execute(self) -> None:
        print("CPU: executing instructions")

class Memory:
    def load(self, position: int, data: str) -> None:
        print(f"Memory: loading '{data}' at {position}")

class HardDrive:
    def read(self, sector: int, size: int) -> str:
        return f"boot-data-from-sector-{sector}"

class ComputerFacade:
    """A single simplified entry point over CPU, Memory, and HardDrive.
    The client calls one method instead of orchestrating 3 subsystems itself."""

    def __init__(self):
        self._cpu = CPU()
        self._memory = Memory()
        self._hard_drive = HardDrive()

    def start(self) -> None:
        self._cpu.freeze()
        boot_data = self._hard_drive.read(sector=0, size=1024)
        self._memory.load(position=0, data=boot_data)
        self._cpu.jump(position=0)
        self._cpu.execute()


# Usage -- client has zero knowledge of CPU/Memory/HardDrive internals
computer = ComputerFacade()
computer.start()
```

**Expected output:**
```
CPU: freezing execution
Memory: loading 'boot-data-from-sector-0' at 0
CPU: jumping to 0
CPU: executing instructions
```

---

