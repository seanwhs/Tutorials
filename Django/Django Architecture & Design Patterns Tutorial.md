# 🐍 Django Architecture & Design Patterns Tutorial 

---

## **1. Introduction to Django Architecture**

Django is a **high-level Python web framework** that follows the **MTV (Model-Template-View) architecture**, similar to **MVC (Model-View-Controller)**. Understanding its structure is key for writing **maintainable, scalable applications**.

```
+---------------------+
|        View         |  <- Handles requests, interacts with models, returns responses
+---------------------+
|       Template      |  <- HTML, CSS, JS, renders data to users
+---------------------+
|        Model        |  <- Database layer, ORM mappings
+---------------------+
```

**Request Flow in Django:**

```
User Request -> URL Dispatcher -> View -> Model (DB) -> Template -> Response
```

**Components:**

* **URL Dispatcher:** Maps URLs to the appropriate view.
* **View:** Contains logic to process requests.
* **Model:** Defines database structure and ORM methods.
* **Template:** Renders HTML with dynamic data.

---

## **2. Django Project Architecture**

A typical Django project structure:

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

**Layered View in Django:**

```
+---------------------+
|  Presentation Layer | <- Templates, static files
+---------------------+
|  View Layer         | <- FBV or CBV
+---------------------+
|  Business Logic     | <- Services, model methods
+---------------------+
|  Data Access Layer  | <- ORM, queries
+---------------------+
|  Database           | <- SQLite/Postgres/MySQL
+---------------------+
```

---

## **3. Function-Based Views (FBV)**

FBVs are **Python functions** receiving an HTTP request and returning a response.

**Example: Blog Post FBV**

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
# urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('', views.post_list, name='post_list'),
    path('<int:pk>/', views.post_detail, name='post_detail'),
]
```

**FBV Advantages:**

* Simple, explicit, easy to understand.
* Direct control over request/response flow.

**FBV Disadvantages:**

* Harder to extend or reuse code.
* Can become cluttered for complex views.

---

## **4. Class-Based Views (CBV)**

CBVs offer **object-oriented views**, enabling **inheritance, reuse, and mixins**.

**Example: Blog Post CBV**

```python
# views.py
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
# urls.py
from django.urls import path
from .views import PostListView, PostDetailView

urlpatterns = [
    path('', PostListView.as_view(), name='post_list'),
    path('<int:pk>/', PostDetailView.as_view(), name='post_detail'),
]
```

**CBV Advantages:**

* Reusable via inheritance.
* Extensible with mixins (authentication, pagination, filtering).
* Cleaner organization for large projects.

**CBV Disadvantages:**

* More abstract than FBV.
* Can be initially harder for beginners.

---

## **5. Django Design Patterns**

### **5.1 Architectural Patterns in Django**

1. **Layered Pattern:** Models, Views, Templates.
2. **MVC/MTV Pattern:** Django’s standard.
3. **Service Layer Pattern:** Separate business logic from views.

```
+-------------------+
|  View (FBV/CBV)   |
+-------------------+
| Service Layer      |
+-------------------+
| Model / ORM       |
+-------------------+
| Database          |
+-------------------+
```

**Example Service Layer:**

```python
# services.py
from .models import Post

def get_recent_posts(limit=5):
    return Post.objects.order_by('-created_at')[:limit]

# views.py (FBV)
from .services import get_recent_posts

def post_list(request):
    posts = get_recent_posts()
    return render(request, 'blog/post_list.html', {'posts': posts})
```

**Benefit:** Thin views, centralized business logic.

---

### **5.2 Structural Patterns**

**Decorator Pattern:** Add functionality dynamically.

```python
from django.contrib.auth.decorators import login_required

@login_required
def post_create(request):
    ...
```

**Mixin Pattern (CBV):** Reusable behavior via inheritance.

```python
from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import CreateView
from .models import Post

class PostCreateView(LoginRequiredMixin, CreateView):
    model = Post
    fields = ['title', 'content']
    template_name = 'blog/post_form.html'
```

**Adapter / Facade:** Integrate external APIs.

```python
class WeatherAPIAdapter:
    def __init__(self, client):
        self.client = client

    def get_temperature(self, city):
        data = self.client.fetch(city)
        return data['temp']
```

---

### **5.3 Behavioral Patterns**

**Observer Pattern:** Django signals.

```python
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Post

@receiver(post_save, sender=Post)
def notify_new_post(sender, instance, created, **kwargs):
    if created:
        print(f"New post created: {instance.title}")
```

**Strategy Pattern:** Dynamic behavior with CBV.

```python
class SortingMixin:
    sort_field = 'created_at'

    def get_queryset(self):
        qs = super().get_queryset()
        return qs.order_by(self.sort_field)

class PostListView(SortingMixin, ListView):
    model = Post
```

**Command Pattern:** Management commands.

```python
# management/commands/my_custom_command.py
from django.core.management.base import BaseCommand

class Command(BaseCommand):
    help = 'Custom command example'

    def handle(self, *args, **options):
        self.stdout.write("Command executed successfully!")
```

---

## **6. FBV vs CBV Comparative Diagram**

```
+------------------+--------------------+
| Feature          | FBV                | CBV                      |
+------------------+--------------------+--------------------------+
| Syntax           | Python function    | Python class             |
| Extensibility    | Low                | High (Mixins/Inherit)    |
| Reusability      | Low                | High                     |
| Readability      | Simple for small  | Abstract for beginners   |
| Ideal Use Case   | Simple pages      | CRUD-heavy apps          |
+------------------+--------------------+--------------------------+
```

---

## **7. Recommended Django Architecture Patterns**

```
+---------------------------------------------------+
|                  View Layer (FBV / CBV)          |
+---------------------------------------------------+
|                  Service Layer                   |
+---------------------------------------------------+
|                  Repository Layer (optional)     |
+---------------------------------------------------+
|                  Model Layer                     |
+---------------------------------------------------+
|                  Database                        |
+---------------------------------------------------+
```

**Guidelines:**

* Thin views for request handling.
* Service Layer centralizes business logic.
* Repository Layer wraps ORM for abstraction.
* Models define tables; database persists data.

---

## **8. Django Best Practices**

1. CBVs for CRUD-heavy apps; FBVs for simple/custom views.
2. Centralize business logic in service layers.
3. Use mixins for reusable behavior (auth, pagination, filtering).
4. Use signals (Observer) for model events.
5. Management commands (Command Pattern) for automation.
6. Keep templates clean; avoid logic in templates.
7. Separate static assets (JS/CSS) from views and templates.

---

## **9. Django Architecture & Design Patterns Mind Map**

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

* Django architecture (MTV/layered).
* FBV & CBV with examples, pros/cons.
* Service layer, mixins, adapters, facades.
* Behavioral patterns: Observer, Strategy, Command.
* Mind map of views, layers, and patterns.
* Best practices and recommended project layout.


