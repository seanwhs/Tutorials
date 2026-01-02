# 🐍 **Key Django Concepts**

Django is a **batteries-included web framework** for Python. To master it professionally, you must understand **MTV architecture, ORM, request lifecycle, middleware, and reusable apps**.

---

## 1. Project & App Structure

* **Project**: The entire Django installation (settings, URLs, WSGI/ASGI).
* **App**: Modular component of a project (e.g., blog, users).
* **Settings**: Central configuration (`settings.py`).

```
myproject/
├─ manage.py
├─ myproject/
│  ├─ settings.py
│  ├─ urls.py
│  └─ wsgi.py
└─ blog/
   ├─ models.py
   ├─ views.py
   ├─ urls.py
   └─ templates/
```

---

## 2. Models & ORM

Django’s **ORM** maps Python classes to database tables.

```python
from django.db import models

class Author(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)

class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.ForeignKey(Author, on_delete=models.CASCADE)
    published = models.DateField()
    price = models.DecimalField(max_digits=6, decimal_places=2)
```

* `ForeignKey` → one-to-many
* `ManyToManyField` → many-to-many
* `on_delete` → handles cascade/delete behavior

**Query examples:**

```python
# Get all books by author
books = Book.objects.filter(author__name="Alice")

# Create a new book
Book.objects.create(title="Django Mastery", author=author, price=29.99)
```

---

## 3. Views & URLs

Django separates logic (`views`) from routing (`urls.py`):

```python
# blog/views.py
from django.shortcuts import render
from .models import Book

def book_list(request):
    books = Book.objects.all()
    return render(request, "blog/book_list.html", {"books": books})

# blog/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path("books/", views.book_list, name="book-list"),
]
```

---

## 4. Templates & Template Tags

Templates handle **HTML rendering** with context data:

```html
<!-- blog/templates/blog/book_list.html -->
<h1>Books</h1>
<ul>
  {% for book in books %}
    <li>{{ book.title }} by {{ book.author.name }} - ${{ book.price }}</li>
  {% empty %}
    <li>No books available.</li>
  {% endfor %}
</ul>
```

* `{% for %}`, `{% if %}` → control structures
* `{{ variable }}` → output context variables
* `{% block %}/{% extends %}` → template inheritance

---

## 5. Forms & Validation

Django handles forms **server-side validation** seamlessly:

```python
from django import forms
from .models import Book

class BookForm(forms.ModelForm):
    class Meta:
        model = Book
        fields = ["title", "author", "published", "price"]
```

**View for form submission:**

```python
def add_book(request):
    if request.method == "POST":
        form = BookForm(request.POST)
        if form.is_valid():
            form.save()
    else:
        form = BookForm()
    return render(request, "blog/add_book.html", {"form": form})
```

---

## 6. Middleware & Request Lifecycle

Middleware hooks into the **request-response cycle**:

* Logging, authentication, security, headers.

```python
# myproject/middleware.py
class SimpleMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        print("Before view")
        response = self.get_response(request)
        print("After view")
        return response
```

---

## 7. Class-Based Views (CBVs)

CBVs encapsulate common patterns (ListView, DetailView, CreateView):

```python
from django.views.generic import ListView
from .models import Book

class BookListView(ListView):
    model = Book
    template_name = "blog/book_list.html"
    context_object_name = "books"
```

---

## 8. Admin Interface

Django comes with a **built-in admin**:

```python
from django.contrib import admin
from .models import Book, Author

@admin.register(Book)
class BookAdmin(admin.ModelAdmin):
    list_display = ("title", "author", "published", "price")
    search_fields = ("title", "author__name")
```

* Quickly manage data without writing extra views.

---

## 9. Advanced Features

* **Signals** → Hook into model events (`post_save`, `pre_delete`)
* **Custom Managers** → Encapsulate complex queries
* **Caching** → Optimize performance (`cache_page`)
* **Async Views** → `async def view(request)` for high throughput
* **REST API** → Django REST Framework (DRF) for JSON endpoints

---

## 10. Real-World Example: Blog App

```python
# models.py
class Post(models.Model):
    title = models.CharField(max_length=200)
    content = models.TextField()
    published = models.DateTimeField(auto_now_add=True)

# views.py
from django.shortcuts import render
from .models import Post

def home(request):
    posts = Post.objects.all()
    return render(request, "blog/home.html", {"posts": posts})

# home.html
{% for post in posts %}
<h2>{{ post.title }}</h2>
<p>{{ post.content|truncatechars:100 }}</p>
{% endfor %}
```

This simple app demonstrates:

* Models → Database
* Views → Business logic
* Templates → Presentation

---

## ✅ Key Django Concepts Cheat Sheet

| Concept           | Example                       | Use Case                    |
| ----------------- | ----------------------------- | --------------------------- |
| Project & App     | `manage.py startapp blog`     | Modular architecture        |
| Models / ORM      | `class Book(models.Model)`    | Database mapping            |
| Views             | `def book_list(request)`      | Request logic               |
| Templates         | `{% for book in books %}`     | HTML rendering              |
| Forms             | `BookForm`                    | Validation & input          |
| Class-Based Views | `ListView`, `DetailView`      | Reusable view patterns      |
| Middleware        | `__call__` hook               | Request/response processing |
| Admin             | `admin.site.register(Book)`   | Rapid CRUD interface        |
| Signals           | `post_save.connect(...)`      | Event handling              |
| DRF / REST API    | `serializers.ModelSerializer` | JSON endpoints              |
| Async Views       | `async def view(request)`     | High concurrency            |

---

