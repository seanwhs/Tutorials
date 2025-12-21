# 📘 Django Serializers Tutorial: Step-by-Step Guide

**Edition:** 1.0
**Audience:** Beginners → Intermediate Django Developers
**Goal:** Learn to use Django REST Framework (DRF) serializers to expose data via APIs
**Prerequisites:**

* Python 3.12+ installed
* Django 5.x installed (`pip install django`)
* Basic knowledge of Django ORM

---

# 🏗️ Step 1: Install Django REST Framework

```bash
pip install djangorestframework
```

**Add to `settings.py`:**

```python
INSTALLED_APPS = [
    ...
    'rest_framework',
    'library',  # our app
]
```

---

# ⚡ Step 2: Define Models

We’ll use **Author** and **Book** models from ORM tutorial:

**`library/models.py`**

```python
from django.db import models

class Author(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)

class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.ForeignKey(Author, on_delete=models.CASCADE, related_name='books')
    published_date = models.DateField()
    price = models.DecimalField(max_digits=6, decimal_places=2)
```

**Diagram (Models & Relationships):**

```
Author
 ├── id
 ├── name
 └── email
        |
        v
Book
 ├── id
 ├── title
 ├── author_id (FK)
 ├── published_date
 └── price
```

---

# 🏗️ Step 3: Create Serializers

**`library/serializers.py`**

```python
from rest_framework import serializers
from .models import Author, Book

# Simple serializer
class AuthorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Author
        fields = ['id', 'name', 'email']

# Nested serializer for related books
class BookSerializer(serializers.ModelSerializer):
    author = AuthorSerializer(read_only=True)  # nested

    class Meta:
        model = Book
        fields = ['id', 'title', 'author', 'published_date', 'price']
```

**Diagram (Serializer Data Flow):**

```
Python Object (Book instance)
        |
        v
BookSerializer
        |
        v
JSON
{
  "id": 1,
  "title": "Pride and Prejudice",
  "author": {
    "id": 1,
    "name": "Jane Austen",
    "email": "jane@example.com"
  },
  "published_date": "1813-01-28",
  "price": "19.99"
}
```

---

# ⚡ Step 4: Create API Views

**`library/views.py`**

```python
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Author, Book
from .serializers import AuthorSerializer, BookSerializer

@api_view(['GET'])
def authors_list(request):
    authors = Author.objects.all()
    serializer = AuthorSerializer(authors, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def books_list(request):
    books = Book.objects.all()
    serializer = BookSerializer(books, many=True)
    return Response(serializer.data)
```

---

# 🏗️ Step 5: Configure URLs

**`library/urls.py`**

```python
from django.urls import path
from . import views

urlpatterns = [
    path('authors/', views.authors_list, name='authors-list'),
    path('books/', views.books_list, name='books-list'),
]
```

Include in **project `urls.py`**:

```python
path('api/', include('library.urls')),
```

---

# ⚡ Step 6: Test API in Browser / Postman

* Run Django server:

```bash
python manage.py runserver
```

* Visit:

```
http://127.0.0.1:8000/api/authors/
http://127.0.0.1:8000/api/books/
```

**Expected JSON output for `/api/books/`:**

```json
[
  {
    "id": 1,
    "title": "Pride and Prejudice",
    "author": {
      "id": 1,
      "name": "Jane Austen",
      "email": "jane@example.com"
    },
    "published_date": "1813-01-28",
    "price": "19.99"
  }
]
```

**Diagram (API Flow):**

```
Browser / Client
        |
        v
HTTP GET /api/books/
        |
        v
Django View (books_list)
        |
        v
BookSerializer --> JSON
        |
        v
Response to Client
```

---

# 🏗️ Step 7: Serializer for Create / Update

**`library/serializers.py`**

```python
class BookCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Book
        fields = ['title', 'author', 'published_date', 'price']
```

**`views.py`**

```python
@api_view(['POST'])
def create_book(request):
    serializer = BookCreateSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=201)
    return Response(serializer.errors, status=400)
```

**Diagram (POST Flow):**

```
Client POST JSON --> /api/books/create/
        |
        v
BookCreateSerializer(data=request.data)
        |
        v
Validation & ORM save --> Database
        |
        v
JSON Response
```

---

# ⚡ Step 8: Nested / Related Serializers

* Already demonstrated: `BookSerializer` includes nested `AuthorSerializer`
* Supports **read-only nested views** or **write nested relationships** using `PrimaryKeyRelatedField` or `SlugRelatedField`

---

# 🏗️ Step 9: Serializer Best Practices

* Use `ModelSerializer` whenever possible
* Use `read_only` for fields you don’t want clients to modify
* Use `nested serializers` for related models
* Use `SerializerMethodField` for custom computed fields

**Example:**

```python
class BookSerializer(serializers.ModelSerializer):
    author_name = serializers.SerializerMethodField()

    def get_author_name(self, obj):
        return obj.author.name

    class Meta:
        model = Book
        fields = ['id', 'title', 'author_name', 'published_date', 'price']
```

---

# ✅ Key Takeaways

* **Serializers** convert Python objects → JSON and JSON → Python objects
* `ModelSerializer` automates mapping from Django models
* Nested serializers handle **relationships**
* Validation can be handled in serializer
* Serializers are **core for API development** in Django REST Framework

---

**Text-Based API Flow Overview:**

```
Client (Browser / App)
        |
        v
HTTP Request (GET/POST)
        |
        v
Django View (function or class-based)
        |
        v
Serializer
 ├─ Python object -> JSON (GET)
 └─ JSON -> Python object (POST)
        |
        v
Database ORM
        |
        v
Response JSON to Client
```

---


Do you want me to create that full project next?
