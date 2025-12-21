# 📘 Django ORM Tutorial: Step-by-Step Guide

**Edition:** 1.0
**Audience:** Beginners → Intermediate Django Developers
**Goal:** Learn Django ORM to interact with databases effectively
**Prerequisites:**

* Python 3.12+ installed
* Django 5.x installed (`pip install django`)
* Basic knowledge of Python

---

# 🏗️ Step 1: Create Django Project

```bash
django-admin startproject myormproject
cd myormproject
python manage.py startapp library
```

**Project Structure:**

```
myormproject/
├── manage.py
├── myormproject/
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
└── library/
    ├── models.py
    ├── views.py
    ├── urls.py
    └── migrations/
```

---

# ⚡ Step 2: Configure App

**`settings.py`**

```python
INSTALLED_APPS = [
    ...
    'library',
]
```

---

# 🏗️ Step 3: Define Models

**`library/models.py`**

```python
from django.db import models

class Author(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)

    def __str__(self):
        return self.name

class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.ForeignKey(Author, on_delete=models.CASCADE, related_name='books')
    published_date = models.DateField()
    price = models.DecimalField(max_digits=6, decimal_places=2)

    def __str__(self):
        return self.title
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

# ⚡ Step 4: Migrate Models

```bash
python manage.py makemigrations
python manage.py migrate
```

---

# 🏗️ Step 5: Django Shell & ORM Basics

```bash
python manage.py shell
```

**Create records:**

```python
from library.models import Author, Book
from datetime import date

# Create an author
author1 = Author.objects.create(name="Jane Austen", email="jane@example.com")

# Create a book
book1 = Book.objects.create(title="Pride and Prejudice", author=author1, published_date=date(1813,1,28), price=19.99)
```

**Diagram (Data Flow):**

```
Python Object --> ORM --> SQL INSERT --> Database
```

---

# ⚡ Step 6: Querying Data

```python
# Get all authors
authors = Author.objects.all()

# Filter authors by name
austen = Author.objects.filter(name="Jane Austen")

# Get a single object
jane = Author.objects.get(email="jane@example.com")

# Get books by author
books_by_jane = jane.books.all()  # via related_name
```

**Diagram (Query Example):**

```
Author.objects.get(email="jane@example.com")
        |
        v
SQL: SELECT * FROM library_author WHERE email='jane@example.com';
        |
        v
Python Author Object
```

---

# 🏗️ Step 7: Update & Delete Records

```python
# Update
jane.name = "Jane A."
jane.save()

# Delete
book1.delete()
```

**Diagram:**

```
Python Object Update
   jane.name = "Jane A."
        |
        v
ORM generates SQL: UPDATE library_author SET name='Jane A.' WHERE id=1
```

---

# ⚡ Step 8: Advanced Queries

**Filtering & Lookups:**

```python
# Books cheaper than 20
cheap_books = Book.objects.filter(price__lt=20)

# Books published after 2000
modern_books = Book.objects.filter(published_date__year__gte=2000)

# Get first/last
first_book = Book.objects.first()
last_book = Book.objects.last()
```

**Aggregations:**

```python
from django.db.models import Avg, Count, Max

avg_price = Book.objects.aggregate(Avg('price'))
total_books = Book.objects.count()
most_expensive = Book.objects.aggregate(Max('price'))
```

---

# 🏗️ Step 9: Relationships

**One-to-Many (Author → Book)**

```python
author = Author.objects.get(name="Jane Austen")
books = author.books.all()  # related_name='books'
```

**Many-to-Many Example:**

```python
class Category(models.Model):
    name = models.CharField(max_length=50)

class Book(models.Model):
    title = models.CharField(max_length=200)
    categories = models.ManyToManyField(Category, related_name='books')
```

**Diagram (Many-to-Many Table):**

```
Book
 └── id

Category
 └── id

Book_categories (junction table)
 ├── id
 ├── book_id
 └── category_id
```

---

# ⚡ Step 10: Query Related Objects

```python
# Many-to-Many
fiction = Category.objects.get(name="Fiction")
books_in_fiction = fiction.books.all()
```

---

# 🏗️ Step 11: QuerySets & Chaining

```python
books = Book.objects.filter(price__lt=30).order_by('-published_date')[:5]
```

**Diagram (QuerySet Chaining):**

```
Book.objects.filter(price__lt=30) --> queryset1
        .order_by('-published_date') --> queryset2
        [:5] --> final queryset (Python list)
```

---

# ⚡ Step 12: Best Practices

* Use `related_name` for reverse relationships
* Avoid `get()` for queries that may return zero results → use `filter().first()`
* Use `select_related` & `prefetch_related` for optimizing DB hits
* Always migrate after model changes

---

# ✅ Key Takeaways

* Django ORM maps **Python classes to database tables**
* CRUD operations are **object-oriented**
* Supports **One-to-Many**, **Many-to-Many**, **aggregations**, and **advanced queries**
* QuerySets are **lazy** until evaluated
* Efficient ORM usage improves performance and maintainability

---

**Full Text-Based Data Flow Overview:**

```
Python Model Object
        |
        v
Django ORM
        |
        v
SQL Query
        |
        v
Database (MySQL / SQLite / Postgres)
        |
        v
QuerySet / Python Object
```

---

