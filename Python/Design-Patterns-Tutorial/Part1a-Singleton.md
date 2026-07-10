# Part 1a — Singleton

Ensures a class has only **one instance** and provides a global access point (e.g., a config manager or connection pool).

```python
from typing import Optional

class ConfigManager:
    """A Singleton using dunder-new override -- the most explicit Python approach."""

    _instance: Optional["ConfigManager"] = None

    def __new__(cls, *args, **kwargs):
        # dunder-new controls object creation itself, before dunder-init runs.
        # By checking a class-level attribute, we guarantee only one instance ever exists.
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._settings = {}  # init state only once
        return cls._instance

    def set(self, key: str, value: str) -> None:
        self._settings[key] = value

    def get(self, key: str) -> str:
        return self._settings.get(key, "")


# Usage
config1 = ConfigManager()
config2 = ConfigManager()
config1.set("env", "production")

print(config2.get("env"))       # "production" -- same instance!
print(config1 is config2)       # True
```

**Pythonic alternative:** a simple **module** (Python caches modules on import) is usually cleaner than a Singleton class:

```python
# settings.py
settings = {"env": "production"}
```

