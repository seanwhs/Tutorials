# Design Patterns in Python 

## Series Structure

| Part | Section | Patterns |
|------|---------|----------|
| 1 | **Creational Patterns** | Singleton, Factory Method, Abstract Factory, Builder, Prototype |
| 2 | **Structural Patterns** | Adapter, Decorator, Facade, Composite, Proxy |
| 3 | **Behavioral Patterns** | Strategy, Observer, Command, State, Template Method, Iterator |
| 4 | **Pythonic Notes** | Where language idioms replace classic GoF patterns |

## Detailed Pattern Index

### Creational
| Pattern | Problem It Solves | Key Python Mechanism |
|---|---|---|
| Singleton | Ensure only one instance exists globally | `__new__` override / module-level state |
| Factory Method | Decouple object creation from usage | Dict-dispatch function returning abstract type |
| Abstract Factory | Create families of related objects | Factory classes implementing a shared interface |
| Builder | Construct complex objects step-by-step | Fluent method chaining (`return self`) |
| Prototype | Clone expensive-to-construct objects | `copy.deepcopy` |

### Structural
| Pattern | Problem It Solves | Key Python Mechanism |
|---|---|---|
| Adapter | Bridge incompatible interfaces | Wrapper class translating method calls |
| Decorator | Add behavior without subclassing | Composition + `@property`/`@decorator` syntax |
| Facade | Simplify a complex subsystem | Single class exposing a minimal API |
| Composite | Treat individual objects & groups uniformly | Recursive tree structure w/ shared interface |
| Proxy | Control access to another object | `__getattr__` delegation / lazy loading |

### Behavioral
| Pattern | Problem It Solves | Key Python Mechanism |
|---|---|---|
| Strategy | Swap algorithms at runtime | Functions/callables passed as parameters |
| Observer | Notify dependents of state changes | Subject maintains list of subscriber callbacks |
| Command | Encapsulate a request as an object | Callable objects with `execute()`/`undo()` |
| State | Change behavior based on internal state | State objects swapped on the context |
| Template Method | Define algorithm skeleton, defer steps | `abc` base class with abstract hook methods |
| Iterator | Traverse collections uniformly | `__iter__` / `__next__` / generators |

### Pythonic Notes (Part 4)
- Singleton → modules
- Strategy → first-class functions
- Iterator → generators/`yield`
- Observer → `contextlib`, event libraries, or `Blinker`
- Decorator (structural) → native `@decorator` syntax vs. GoF class-based version
