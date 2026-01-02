# 🐍 **Key Django ORM Concepts**

Django ORM maps **Python classes (Models)** to **database tables**, letting you interact with your DB **without writing raw SQL**.

---

## 1. Models: Python Classes Represent Tables

```python
from django.db import models

class Author(models.Model):
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    birth_date = models.DateField()

    def __str__(self):
        return f"{self.first_name} {self.last_name}"
```

* Each class → database table
* Each field → database column
* Common fields:

  * `CharField`, `TextField`, `IntegerField`, `FloatField`, `BooleanField`, `DateField`, `DateTimeField`, `EmailField`

---

## 2. Relationships

| Type         | Field             | Example / Usage                                                  |
| ------------ | ----------------- | ---------------------------------------------------------------- |
| One-to-Many  | `ForeignKey`      | `book = models.ForeignKey(Author, on_delete=models.CASCADE)`     |
| Many-to-Many | `ManyToManyField` | `categories = models.ManyToManyField(Category)`                  |
| One-to-One   | `OneToOneField`   | `profile = models.OneToOneField(User, on_delete=models.CASCADE)` |

* `on_delete` options: `CASCADE`, `PROTECT`, `SET_NULL`, `DO_NOTHING`

---

## 3. Querying Data

```python
# Retrieve all authors
authors = Author.objects.all()

# Filter by last name
smiths = Author.objects.filter(last_name="Smith")

# Get a single object (raises DoesNotExist if none)
author = Author.objects.get(id=1)

# Exclude
non_smiths = Author.objects.exclude(last_name="Smith")

# Ordering
authors = Author.objects.order_by("birth_date")  # ascending
authors = Author.objects.order_by("-birth_date") # descending
```

---

## 4. Field Lookups

| Lookup                   | Example                         | SQL Equivalent         |
| ------------------------ | ------------------------------- | ---------------------- |
| exact                    | `.filter(name__exact="Alice")`  | `WHERE name='Alice'`   |
| iexact                   | `.filter(name__iexact="alice")` | case-insensitive match |
| contains                 | `.filter(name__contains="Al")`  | `LIKE '%Al%'`          |
| icontains                | `.filter(name__icontains="al")` | case-insensitive LIKE  |
| gt / gte                 | `.filter(age__gt=20)`           | greater than           |
| lt / lte                 | `.filter(age__lte=30)`          | less than or equal     |
| in                       | `.filter(id__in=[1,2,3])`       | IN clause              |
| startswith / istartswith | `.filter(name__startswith="A")` | LIKE 'A%'              |
| endswith / iendswith     | `.filter(name__endswith="e")`   | LIKE '%e'              |

---

## 5. Aggregations & Annotations

```python
from django.db.models import Count, Avg, Sum, Max, Min

# Count books per author
authors = Author.objects.annotate(num_books=Count("book"))

# Average book price
avg_price = Book.objects.aggregate(Avg("price"))

# Maximum birth year
max_birth = Author.objects.aggregate(Max("birth_date"))
```

* `.annotate()` → adds extra fields to each object
* `.aggregate()` → single summary value

---

## 6. Related Queries (Reverse Relationships)

```python
author = Author.objects.get(id=1)

# All books by this author
books = author.book_set.all()

# Filtering reverse relationships
authors_with_books = Author.objects.filter(book__title__icontains="Python")
```

* Use `related_name` in models to customize reverse access:

```python
book = models.ForeignKey(Author, on_delete=models.CASCADE, related_name="books")
author.books.all()
```

---

## 7. Create / Update / Delete

```python
# Create
author = Author.objects.create(first_name="Alice", last_name="Smith", birth_date="1990-01-01")

# Update
author.last_name = "Johnson"
author.save()

# Bulk Update
Author.objects.filter(last_name="Smith").update(last_name="Doe")

# Delete
author.delete()
```

---

## 8. Query Optimization

* **Select related** → fetch foreign key relations in a single query:

```python
books = Book.objects.select_related("author").all()
```

* **Prefetch related** → for Many-to-Many relationships:

```python
books = Book.objects.prefetch_related("categories").all()
```

* **Values / Values_list** → fetch only specific columns:

```python
Book.objects.values("title", "price")
Book.objects.values_list("title", flat=True)
```

* **Defer / Only** → load only required fields to save memory:

```python
Book.objects.only("title", "author")
Book.objects.defer("description")
```

---

## 9. Advanced Features

* **Q Objects** → complex queries with OR / AND:

```python
from django.db.models import Q
Book.objects.filter(Q(price__gt=50) | Q(title__icontains="Python"))
```

* **F Objects** → reference model fields for updates:

```python
from django.db.models import F
Book.objects.update(price=F("price") * 1.1)
```

* **Transactions** → atomic operations:

```python
from django.db import transaction

with transaction.atomic():
    author = Author.objects.create(first_name="Bob", last_name="Lee")
    Book.objects.create(title="Django Mastery", author=author)
```

---

## ✅ Django ORM Cheat Sheet Summary

| Concept                  | Example / Class / Method                         | Use Case                            |
| ------------------------ | ------------------------------------------------ | ----------------------------------- |
| Models & Fields          | `CharField`, `DateField`                         | Define tables & columns             |
| Relationships            | `ForeignKey`, `ManyToManyField`                  | Model associations                  |
| Querying                 | `.filter()`, `.get()`, `.exclude()`              | Retrieve & filter data              |
| Lookups                  | `__contains`, `__gt`, `__in`                     | Flexible conditions                 |
| Aggregations             | `Count()`, `Avg()`, `Sum()`                      | Statistics & summaries              |
| Related Queries          | `book_set.all()`, `related_name`                 | Reverse relations                   |
| Create / Update / Delete | `.create()`, `.save()`, `.delete()`              | CRUD operations                     |
| Optimizations            | `select_related`, `prefetch_related`, `values()` | Reduce queries, improve performance |
| Q / F Objects            | `Q(price__gt=50)`, `F("price")*1.1`              | Complex queries & updates           |
| Transactions             | `transaction.atomic()`                           | Atomic operations, rollback safety  |

---

                         ┌───────────────────┐
                         │   Django ORM      │
                         └────────┬──────────┘
                                  │
            ┌─────────────────────┼─────────────────────┐
            │                     │                     │
      ┌────────────┐        ┌────────────┐        ┌────────────┐
      │   Models   │        │  Relationships │    │   Fields   │
      └─────┬──────┘        └──────┬───────┘     └──────┬─────┘
            │                     │                     │
 ┌──────────┴─────────┐   ┌───────┴────────┐   ┌────────┴────────┐
 │ Author             │   │ One-to-Many     │   │ CharField        │
 │ - first_name       │   │ ForeignKey      │   │ TextField        │
 │ - last_name        │   │ Many-to-Many    │   │ IntegerField     │
 │ - birth_date       │   │ One-to-One      │   │ FloatField       │
 └──────────┬─────────┘   └────────┬───────┘   └────────┬────────┘
            │                      │                     │
            │                      │                     │
            ▼                      ▼                     ▼
   ┌───────────────────┐   ┌─────────────────┐   ┌───────────────────┐
   │   Querying Data    │   │ Reverse Queries │   │ Aggregations      │
   ├───────────────────┤   ├─────────────────┤   ├───────────────────┤
   │ .all()             │   │ author.book_set │   │ Count(), Avg()    │
   │ .filter()          │   │ related_name    │   │ Sum(), Max(), Min()│
   │ .get()             │   └─────────────────┘   └───────────────────┘
   │ .exclude()         │
   │ .order_by()        │
   └──────────┬─────────┘
              │
              ▼
      ┌─────────────────┐
      │ Advanced Queries│
      ├─────────────────┤
      │ Q Objects       │
      │ F Objects       │
      │ select_related  │
      │ prefetch_related│
      │ values()        │
      │ defer()/only()  │
      └──────────┬──────┘
                 │
                 ▼
         ┌──────────────┐
         │ Transactions │
         │ transaction. │
         │ atomic()     │
         └──────────────┘
```

### ✅ **Key Points in Diagram**

1. **Models & Fields** → map to DB tables and columns
2. **Relationships** → One-to-Many, Many-to-Many, One-to-One
3. **Querying** → `.all()`, `.filter()`, `.get()`, `.exclude()`, `.order_by()`
4. **Reverse Queries** → `related_name` / `_set` access
5. **Aggregations** → `Count`, `Avg`, `Sum`, `Max`, `Min`
6. **Advanced Queries** → `Q`, `F`, `select_related`, `prefetch_related`, `values()`, `defer()/only()`
7. **Transactions** → atomic operations for safe DB updates

---

