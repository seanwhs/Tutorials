# Part 1e — Prototype

Creates new objects by **cloning** an existing instance instead of instantiating from scratch — useful when construction is expensive.

```python
import copy
from dataclasses import dataclass, field

@dataclass
class GameCharacter:
    name: str
    inventory: list = field(default_factory=list)

    def clone(self) -> "GameCharacter":
        # deepcopy ensures nested mutable objects (like inventory) aren't shared by reference
        return copy.deepcopy(self)


# Usage
base_warrior = GameCharacter(name="Warrior Template", inventory=["Sword", "Shield"])

player1 = base_warrior.clone()
player1.name = "Player 1"
player1.inventory.append("Health Potion")

print(base_warrior.inventory)  # ['Sword', 'Shield'] -- untouched
print(player1.inventory)       # ['Sword', 'Shield', 'Health Potion']
```

**Expected output:**
```
['Sword', 'Shield']
['Sword', 'Shield', 'Health Potion']
```

---

# Part 1 — Recap Table

| Pattern | Analogy | When to Reach For It |
|---|---|---|
| Singleton | The one and only president's office | Global shared state — use sparingly, prefer modules |
| Factory Method | A restaurant kitchen taking one order type | Client needs an object but shouldn't know the concrete class |
| Abstract Factory | A furniture showroom with matching style sets | Creating families of related objects that must stay consistent |
| Builder | Ordering a custom sandwich, step by step | Complex objects with many optional parameters |
| Prototype | Photocopying a signed contract | Cloning is cheaper/safer than re-constructing from scratch |

**Part 1 is now complete** across sub-parts 1a–1e (Singleton, Factory Method, Abstract Factory, Builder, Prototype), each individually verified and clean.

