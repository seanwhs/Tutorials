# 📘 Django Serializers Tutorial — Step-by-Step Guide

**Edition:** 1.1
**Audience:** Beginners → Intermediate Django Developers
**Goal:** Learn Django REST Framework (DRF) serializers to expose and consume data via APIs
**Prerequisites:** Python 3.12+, Django 5.x, basic Django ORM knowledge

---

## 🏗️ Step 1: Install Django REST Framework

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

## ⚡ Step 2: Define Models

Using **Author** and **Book** models:

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

**Diagram — Models & Relationships:**

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

## 🏗️ Step 3: Create Serializers

**`library/serializers.py`**

```python
from rest_framework import serializers
from .models import Author, Book

class AuthorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Author
        fields = ['id', 'name', 'email']

class BookSerializer(serializers.ModelSerializer):
    author = AuthorSerializer(read_only=True)  # nested representation

    class Meta:
        model = Book
        fields = ['id', 'title', 'author', 'published_date', 'price']
```

**Diagram — Serializer Data Flow:**

```
Python Object (Book instance)
        |
        v
BookSerializer
        |
        v
JSON Response
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

## ⚡ Step 4: Create API Views

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

## 🏗️ Step 5: Configure URLs

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
from django.urls import path, include

urlpatterns = [
    path('api/', include('library.urls')),
]
```

**Diagram — Request Flow:**

```
Client (Browser / App)
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

## ⚡ Step 6: Test API

```bash
python manage.py runserver
```

* Visit: `http://127.0.0.1:8000/api/authors/` or `/api/books/`
* Expected JSON output for `/api/books/`:

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

---

## 🏗️ Step 7: Serializer for Create / Update

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

**Diagram — POST Flow:**

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

## ⚡ Step 8: Nested / Related Serializers

* Nested serializers allow **read-only nested views**
* For write operations, use `PrimaryKeyRelatedField` or `SlugRelatedField`

---

## 🏗️ Step 9: Serializer Best Practices

* Prefer `ModelSerializer` for simplicity
* Use `read_only=True` for fields clients shouldn’t modify
* Use nested serializers for related models
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

## ✅ Key Takeaways

* Serializers convert **Python objects ↔ JSON**
* `ModelSerializer` automates mapping from Django models
* Nested serializers handle **relationships cleanly**
* Validation and data integrity can be enforced in serializers
* Core for building **REST APIs** in Django

**Full API Flow Overview:**

```
Client (Browser / App)
        |
        v
HTTP Request (GET / POST)
        |
        v
Django View (function/class-based)
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
