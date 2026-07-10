# Part 1c — Abstract Factory

Produces **families of related objects** without specifying their concrete classes — useful for theming, cross-platform UI kits, or multi-provider integrations.

```python
from abc import ABC, abstractmethod

# --- Abstract Products ---
class Button(ABC):
    @abstractmethod
    def render(self) -> str: ...

class Checkbox(ABC):
    @abstractmethod
    def render(self) -> str: ...

# --- Concrete Product Family: Dark Theme ---
class DarkButton(Button):
    def render(self) -> str:
        return "<button class='dark'>Click</button>"

class DarkCheckbox(Checkbox):
    def render(self) -> str:
        return "<input type='checkbox' class='dark'>"

# --- Concrete Product Family: Light Theme ---
class LightButton(Button):
    def render(self) -> str:
        return "<button class='light'>Click</button>"

class LightCheckbox(Checkbox):
    def render(self) -> str:
        return "<input type='checkbox' class='light'>"

# --- Abstract Factory ---
class UIFactory(ABC):
    @abstractmethod
    def create_button(self) -> Button: ...
    @abstractmethod
    def create_checkbox(self) -> Checkbox: ...

class DarkUIFactory(UIFactory):
    def create_button(self) -> Button:
        return DarkButton()
    def create_checkbox(self) -> Checkbox:
        return DarkCheckbox()

class LightUIFactory(UIFactory):
    def create_button(self) -> Button:
        return LightButton()
    def create_checkbox(self) -> Checkbox:
        return LightCheckbox()


def render_ui(factory: UIFactory) -> None:
    # This function works with ANY factory -- swapping themes requires zero changes here.
    print(factory.create_button().render())
    print(factory.create_checkbox().render())


# Usage
render_ui(DarkUIFactory())
render_ui(LightUIFactory())
```

**Expected output:**
```
<button class='dark'>Click</button>
<input type='checkbox' class='dark'>
<button class='light'>Click</button>
<input type='checkbox' class='light'>
```

---

