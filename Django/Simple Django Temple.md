# 🐍 Simple Django CRUDL Template

This template demonstrates how to implement **CRUDL operations** for a simple model (`Book`) using **Django’s class-based views**.

---

## **1. Project Setup**

```bash
# Create Django project
django-admin startproject myproject
cd myproject

# Create Django app
python manage.py startapp books

# Make migrations and run server
python manage.py migrate
python manage.py runserver
```

---

## **2. App Structure**

```
myproject/
├── manage.py
├── myproject/
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
└── books/
    ├── models.py
    ├── views.py
    ├── urls.py
    ├── forms.py
    ├── templates/
    │   └── books/
    │       ├── book_list.html
    │       ├── book_detail.html
    │       ├── book_form.html
    │       └── book_confirm_delete.html
    └── admin.py
```

---

## **3. Models (`books/models.py`)**

```python
from django.db import models
from django.urls import reverse

class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.CharField(max_length=100)
    published_date = models.DateField()

    def __str__(self):
        return self.title

    # URL for 'detail' view
    def get_absolute_url(self):
        return reverse('book-detail', kwargs={'pk': self.pk})
```

---

## **4. Forms (`books/forms.py`)**

```python
from django import forms
from .models import Book

class BookForm(forms.ModelForm):
    class Meta:
        model = Book
        fields = ['title', 'author', 'published_date']
```

---

## **5. Views (`books/views.py`)**

Using **Django’s generic class-based views**:

```python
from django.views.generic import ListView, DetailView, CreateView, UpdateView, DeleteView
from django.urls import reverse_lazy
from .models import Book
from .forms import BookForm

# List all books
class BookListView(ListView):
    model = Book
    template_name = 'books/book_list.html'
    context_object_name = 'books'

# View book details
class BookDetailView(DetailView):
    model = Book
    template_name = 'books/book_detail.html'
    context_object_name = 'book'

# Create a new book
class BookCreateView(CreateView):
    model = Book
    form_class = BookForm
    template_name = 'books/book_form.html'

# Update an existing book
class BookUpdateView(UpdateView):
    model = Book
    form_class = BookForm
    template_name = 'books/book_form.html'

# Delete a book
class BookDeleteView(DeleteView):
    model = Book
    template_name = 'books/book_confirm_delete.html'
    success_url = reverse_lazy('book-list')
```

---

## **6. URLs (`books/urls.py`)**

```python
from django.urls import path
from .views import (
    BookListView, BookDetailView,
    BookCreateView, BookUpdateView, BookDeleteView
)

urlpatterns = [
    path('', BookListView.as_view(), name='book-list'),
    path('<int:pk>/', BookDetailView.as_view(), name='book-detail'),
    path('create/', BookCreateView.as_view(), name='book-create'),
    path('<int:pk>/update/', BookUpdateView.as_view(), name='book-update'),
    path('<int:pk>/delete/', BookDeleteView.as_view(), name='book-delete'),
]
```

Include the app URLs in the **project `urls.py`**:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('books/', include('books.urls')),
]
```

---

## **7. Templates**

**1. `book_list.html`**

```html
<h1>Books</h1>
<a href="{% url 'book-create' %}">Add New Book</a>
<ul>
    {% for book in books %}
        <li>
            <a href="{{ book.get_absolute_url }}">{{ book.title }}</a>
            - <a href="{% url 'book-update' book.pk %}">Edit</a>
            - <a href="{% url 'book-delete' book.pk %}">Delete</a>
        </li>
    {% endfor %}
</ul>
```

**2. `book_detail.html`**

```html
<h1>{{ book.title }}</h1>
<p>Author: {{ book.author }}</p>
<p>Published: {{ book.published_date }}</p>
<a href="{% url 'book-update' book.pk %}">Edit</a>
<a href="{% url 'book-delete' book.pk %}">Delete</a>
<a href="{% url 'book-list' %}">Back to list</a>
```

**3. `book_form.html`**

```html
<h1>{% if book %}Edit{% else %}Add{% endif %} Book</h1>
<form method="post">
    {% csrf_token %}
    {{ form.as_p }}
    <button type="submit">Save</button>
</form>
<a href="{% url 'book-list' %}">Back to list</a>
```

**4. `book_confirm_delete.html`**

```html
<h1>Delete Book</h1>
<p>Are you sure you want to delete "{{ book.title }}"?</p>
<form method="post">
    {% csrf_token %}
    <button type="submit">Confirm</button>
</form>
<a href="{% url 'book-list' %}">Cancel</a>
```

---

## **8. Admin Integration (Optional)**

```python
# books/admin.py
from django.contrib import admin
from .models import Book

@admin.register(Book)
class BookAdmin(admin.ModelAdmin):
    list_display = ('title', 'author', 'published_date')
    search_fields = ('title', 'author')
```

---

## ✅ **9. Summary**

This **CRUDL template** gives you:

* **Create, Read, Update, Delete, List** functionality for `Book`.
* **Class-based views** for concise and maintainable code.
* Templates that follow a clear pattern.
* Ready-to-expand structure for more complex models and features.
