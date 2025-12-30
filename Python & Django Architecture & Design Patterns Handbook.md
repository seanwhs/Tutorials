# 🐍 Python & Django Architecture & Design Patterns Tutorial 

---

## **Part 1: Python Architecture & Design Patterns**

### **1. Python Architectural Overview**

Python applications can adopt different architectures depending on scale, requirements, and maintainability.

```
+-------------------------+
|   Python Architecture   |
+-------------------------+
           |
  +--------+--------+
  |        |        |
Layered  Microservices Event-Driven
```

**Explanation of Styles:**

* **Layered Architecture:**

  * Presentation Layer → Business Logic Layer → Data Access Layer
  * Clear separation of responsibilities.

* **Microservices Architecture:**

  * Independent services communicate via REST, gRPC, or message queues.
  * Ideal for large-scale distributed systems.

* **Event-Driven Architecture:**

  * Components react asynchronously to events (via message brokers).
  * Decouples producers and consumers for scalability.

---

### **2. Python Design Patterns Overview**

```
Design Patterns
       |
+------+--------+-------+
| Creational | Structural | Behavioral |
+------------+------------+-----------+
```

* **Creational Patterns:** Manage object creation.

  * **Singleton:** Single instance (logging, config).
  * **Factory:** Dynamic object creation.
  * **Builder:** Complex object assembly.

* **Structural Patterns:** Organize class/object relationships.

  * **Adapter:** Integrate legacy systems.
  * **Decorator:** Add dynamic behavior (logging, caching).
  * **Facade:** Simplify complex subsystems.
  * **Composite:** Tree-like structures (GUI, filesystem).

* **Behavioral Patterns:** Govern interactions and communication.

  * **Observer:** Event-driven notifications.
  * **Strategy:** Dynamic behavior (e.g., sorting, filtering).
  * **Command:** Encapsulate actions (undo/redo, queues).
  * **Template:** Standardized workflows.
  * **Chain of Responsibility:** Sequential processing (validation, middleware).

**Pattern Use Cases Table**

| Pattern Type | Recommended Use Cases                        |
| ------------ | -------------------------------------------- |
| Singleton    | Logging, configuration, connection pool      |
| Factory      | Plugin systems, dynamic object creation      |
| Builder      | Complex object construction                  |
| Adapter      | Legacy code integration                      |
| Decorator    | Logging, caching, validation                 |
| Facade       | Simplified interface to complex subsystems   |
| Composite    | Tree structures, GUI elements, file systems  |
| Observer     | Event-driven UI, notifications               |
| Strategy     | Dynamic algorithm selection, payment methods |
| Command      | Undo/redo, macros, request queues            |
| Template     | Standardized workflows, game engines         |
| Chain        | Sequential validation, request pipelines     |

---

## **Part 2: Django Architecture & Design Patterns**

### **1. Django Architecture Overview**

Django uses **MTV (Model-Template-View)** architecture, similar to MVC:

```
+---------------------+
|        View         | <- Handles HTTP requests, calls models, returns responses
+---------------------+
|       Template      | <- HTML/CSS/JS presentation layer
+---------------------+
|        Model        | <- Database representation via ORM
+---------------------+
```

**Request Flow:**

```
User Request -> URL Dispatcher -> View -> Model -> Template -> Response
```

---

### **2. Django Project Structure**

```
myproject/
├── manage.py
├── myproject/
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── app1/
│   ├── models.py
│   ├── views.py
│   ├── urls.py
│   ├── templates/
│   └── static/
└── app2/
    └── ...
```

**Layered View of Django Components:**

```
+---------------------+
|  Presentation Layer | <- Templates, JS, CSS
+---------------------+
|  View Layer         | <- FBV / CBV
+---------------------+
|  Business Logic     | <- Service Layer, Model methods
+---------------------+
|  Data Access Layer  | <- ORM
+---------------------+
|  Database           | <- PostgreSQL / MySQL / SQLite
+---------------------+
```

---

### **3. Function-Based Views (FBV)**

FBVs are **Python functions** that handle HTTP requests explicitly.

```python
# views.py
from django.shortcuts import render, get_object_or_404
from .models import Post

def post_list(request):
    posts = Post.objects.all()
    return render(request, 'blog/post_list.html', {'posts': posts})

def post_detail(request, pk):
    post = get_object_or_404(Post, pk=pk)
    return render(request, 'blog/post_detail.html', {'post': post})
```

**URL Mapping:**

```python
from django.urls import path
from . import views

urlpatterns = [
    path('', views.post_list, name='post_list'),
    path('<int:pk>/', views.post_detail, name='post_detail'),
]
```

**Pros:** Simple, readable, direct control.
**Cons:** Limited reuse, can become cluttered in complex apps.

---

### **4. Class-Based Views (CBV)**

CBVs use **OOP principles** to provide reusable and extensible views.

```python
from django.views.generic import ListView, DetailView
from .models import Post

class PostListView(ListView):
    model = Post
    template_name = 'blog/post_list.html'
    context_object_name = 'posts'

class PostDetailView(DetailView):
    model = Post
    template_name = 'blog/post_detail.html'
```

**URL Mapping:**

```python
from django.urls import path
from .views import PostListView, PostDetailView

urlpatterns = [
    path('', PostListView.as_view(), name='post_list'),
    path('<int:pk>/', PostDetailView.as_view(), name='post_detail'),
]
```

**Pros:** Reusable, extensible with mixins, clean for CRUD-heavy apps.
**Cons:** More abstract, requires understanding OOP and CBV patterns.

---

### **5. Django Design Patterns**

#### **5.1 Architectural Patterns**

* **Layered Architecture:** Views → Services → Models
* **Service Layer:** Centralizes business logic to keep views thin.

```python
# services.py
def get_recent_posts(limit=5):
    return Post.objects.order_by('-created_at')[:limit]
```

#### **5.2 Structural Patterns**

* **Decorator Pattern:** `@login_required` adds functionality to views dynamically.
* **Mixin Pattern (CBV):** Reusable behavior via inheritance.

```python
from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import CreateView
from .models import Post

class PostCreateView(LoginRequiredMixin, CreateView):
    model = Post
    fields = ['title', 'content']
    template_name = 'blog/post_form.html'
```

* **Adapter / Facade Pattern:** Wrap external APIs or complex model interactions.

```python
class WeatherAPIAdapter:
    def __init__(self, client):
        self.client = client

    def get_temperature(self, city):
        data = self.client.fetch(city)
        return data['temp']
```

#### **5.3 Behavioral Patterns**

* **Observer Pattern:** Signals in Django (`pre_save`, `post_save`).

```python
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Post

@receiver(post_save, sender=Post)
def notify_new_post(sender, instance, created, **kwargs):
    if created:
        print(f"New post created: {instance.title}")
```

* **Strategy Pattern:** Dynamic behavior in CBV using mixins.

```python
class SortingMixin:
    sort_field = 'created_at'

    def get_queryset(self):
        qs = super().get_queryset()
        return qs.order_by(self.sort_field)

class PostListView(SortingMixin, ListView):
    model = Post
```

* **Command Pattern:** Management commands for automation.

```bash
python manage.py my_custom_command
```

```python
from django.core.management.base import BaseCommand

class Command(BaseCommand):
    help = 'Custom command example'

    def handle(self, *args, **options):
        self.stdout.write("Command executed successfully!")
```

---

### **6. FBV vs CBV Comparison**

```
+------------------+----------------------+----------------------+
| Feature          | FBV                  | CBV                  |
+------------------+----------------------+----------------------+
| Syntax           | Function             | Class                |
| Extensibility    | Low                  | High (Mixins/Inherit)|
| Reusability      | Low                  | High                 |
| Readability      | Explicit, simple     | Abstract, structured |
| Ideal Use Case   | Simple pages         | CRUD-heavy apps      |
+------------------+----------------------+----------------------+
```

---

### **7. Django Full Architecture & Flow**

```
User Request
     |
     v
+------------------+
| URL Dispatcher   |
+------------------+
     |
     v
+------------------+
| View Layer       | <- FBV / CBV (Thin)
+------------------+
     |
     v
+------------------+
| Service Layer    | <- Facade / Business Logic
+------------------+
     |
     v
+------------------+
| Repository Layer | <- Optional ORM wrapper
+------------------+
     |
     v
+------------------+
| Model / ORM      |
+------------------+
     |
     v
+------------------+
| Database         |
+------------------+
     ^
     |
+------------------+
| Signals / Observer|
+------------------+
     |
     v
+------------------+
| Template Rendering|
+------------------+
     |
     v
User Receives HTTP Response
```

---

### **8. Django Best Practices**

1. Use **CBVs** for CRUD-heavy apps; **FBVs** for simple or highly customized views.
2. Implement **Service Layer** to centralize business logic.
3. Use **Mixins & Decorators** for reusable, modular behavior.
4. Apply **Signals / Observer** for decoupled reactions to model events.
5. Encapsulate administrative tasks in **Command Pattern**.
6. Keep **Templates clean**, logic-free, and separate from Python code.
7. Separate **static assets** from views and templates.
8. Use **Middleware / Chain of Responsibility** for sequential processing.

---

### **9. Mind Map: Django Architecture & Patterns**

```
                    +----------------------------+
                    |     Django Architecture     |
                    +----------------------------+
                               |
      +------------------------+------------------------+
      |                        |                        |
+-------------+         +----------------+        +----------------+
| FBV         |         | CBV            |        | Service Layer  |
+-------------+         +----------------+        +----------------+
| Function    |         | Class-based    |        | Business Logic |
| Explicit    |         | Inheritance    |        | Reusable Logic |
| Simple      |         | Mixins         |        | Thin Views     |
+-------------+         +----------------+        +----------------+
        |                       |                       |
        |                       |                       |
        |                       +-----------------------+
        |                               |
        |                          +------------------+
        |                          | Mixins / Decorators|
        |                          +------------------+
        |                          | Authentication   |
        |                          | Pagination       |
        |                          | Filtering        |
        |                          +------------------+
        |
        +--------------------------------+
        |                                |
+----------------+                +----------------+
| URL Dispatcher |                | Templates      |
+----------------+                +----------------+
| Maps URLs      |                | Render HTML    |
| to Views       |                | JS / CSS       |
+----------------+                +----------------+
        |
        v
+----------------+
| Models / ORM   |
+----------------+
| DB Abstraction |
| Query Methods  |
+----------------+
        |
        v
+----------------+
| Database       |
+----------------+
```

---

This tutorial covers:

* **Python architecture & design patterns**
* **Django FBV & CBV**
* **Service layer, repository, mixins, decorators**
* **Signals / Observer, Strategy, Command patterns**
* **End-to-end request flow and best practices**
* **ASCII mind maps and tables for clarity**
