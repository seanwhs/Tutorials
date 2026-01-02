# 🐍 **Key Django CRUDL Concepts – FBV**

CRUDL stands for:

* **C**reate → Add new data
* **R**ead → View a single record
* **U**pdate → Edit existing data
* **D**elete → Remove data
* **L**ist → Display multiple records

---

## 1. Setup

Assume a simple model:

```python
# models.py
from django.db import models

class Author(models.Model):
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    birth_date = models.DateField()

    def __str__(self):
        return f"{self.first_name} {self.last_name}"
```

---

## 2. Forms

```python
# forms.py
from django import forms
from .models import Author

class AuthorForm(forms.ModelForm):
    class Meta:
        model = Author
        fields = ['first_name', 'last_name', 'birth_date']
```

---

## 3. Views (Function-Based)

### **Create**

```python
# views.py
from django.shortcuts import render, redirect, get_object_or_404
from .models import Author
from .forms import AuthorForm

def author_create(request):
    if request.method == "POST":
        form = AuthorForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect("author_list")
    else:
        form = AuthorForm()
    return render(request, "author_form.html", {"form": form})
```

---

### **Read / Detail**

```python
def author_detail(request, pk):
    author = get_object_or_404(Author, pk=pk)
    return render(request, "author_detail.html", {"author": author})
```

---

### **Update**

```python
def author_update(request, pk):
    author = get_object_or_404(Author, pk=pk)
    if request.method == "POST":
        form = AuthorForm(request.POST, instance=author)
        if form.is_valid():
            form.save()
            return redirect("author_detail", pk=author.pk)
    else:
        form = AuthorForm(instance=author)
    return render(request, "author_form.html", {"form": form})
```

---

### **Delete**

```python
def author_delete(request, pk):
    author = get_object_or_404(Author, pk=pk)
    if request.method == "POST":
        author.delete()
        return redirect("author_list")
    return render(request, "author_confirm_delete.html", {"author": author})
```

---

### **List**

```python
def author_list(request):
    authors = Author.objects.all()
    return render(request, "author_list.html", {"authors": authors})
```

---

## 4. URLs

```python
# urls.py
from django.urls import path
from . import views

urlpatterns = [
    path("authors/", views.author_list, name="author_list"),
    path("authors/new/", views.author_create, name="author_create"),
    path("authors/<int:pk>/", views.author_detail, name="author_detail"),
    path("authors/<int:pk>/edit/", views.author_update, name="author_update"),
    path("authors/<int:pk>/delete/", views.author_delete, name="author_delete"),
]
```

---

## 5. Templates (Minimal Example)

* **author_form.html**

```html
<form method="post">
  {% csrf_token %}
  {{ form.as_p }}
  <button type="submit">Submit</button>
</form>
```

* **author_list.html**

```html
<ul>
  {% for author in authors %}
    <li><a href="{% url 'author_detail' author.pk %}">{{ author }}</a></li>
  {% endfor %}
</ul>
<a href="{% url 'author_create' %}">Add New Author</a>
```

* **author_detail.html**

```html
<h1>{{ author }}</h1>
<p>Birth Date: {{ author.birth_date }}</p>
<a href="{% url 'author_update' author.pk %}">Edit</a>
<form action="{% url 'author_delete' author.pk %}" method="post">
  {% csrf_token %}
  <button type="submit">Delete</button>
</form>
<a href="{% url 'author_list' %}">Back to list</a>
```

---

## 6. Notes & Best Practices

* Always use `get_object_or_404()` to avoid errors for missing objects
* `POST` for create, update, and delete actions; `GET` for read/list
* `redirect()` after successful create/update/delete to follow **Post/Redirect/Get pattern**
* Use **ModelForm** to reduce boilerplate code

---

## 7. ASCII “Django CRUDL FBV Power Map”

```
                     ┌──────────────────┐
                     │    Author Model   │
                     └─────────┬────────┘
                               │
               ┌───────────────┼───────────────┐
               │               │               │
         ┌─────────┐     ┌─────────┐     ┌─────────┐
         │ Create  │     │ Read    │     │ Update  │
         │ author_create()│ author_detail()│ author_update() │
         └─────┬─────┘     └─────┬─────┘     └─────┬─────┘
               │               │               │
               ▼               ▼               ▼
         Form Submission     Object Fetch   Form Submission
         + Validation       + Render       + Validation
         + save()           + Template     + save()
               │               │               │
               └───────────────┼───────────────┘
                               ▼
                        ┌─────────────┐
                        │ Delete      │
                        │ author_delete() │
                        └─────┬───────┘
                              │
                              ▼
                        Confirm & POST
                              │
                              ▼
                        ┌─────────────┐
                        │ List        │
                        │ author_list() │
                        └─────────────┘
                              │
                              ▼
                        Render all objects
```

✅ **Highlights**

* **Create / Update** → Form handling & validation
* **Read / List** → Object retrieval & template rendering
* **Delete** → Confirm & POST
* **URLs** → Map FBVs to actions
* **Templates** → Form rendering and object listing

---
```
                        ┌──────────────────────┐
                        │       URLs           │
                        └─────────┬────────────┘
                                  │
        ┌───────────────┬─────────┼───────────────┬───────────────┐
        │               │         │               │               │
   /authors/new/   /authors/<pk>/  /authors/<pk>/edit/  /authors/<pk>/delete/  /authors/
   (Create)         (Read)          (Update)           (Delete)               (List)
        │               │             │                 │                     │
        ▼               ▼             ▼                 ▼                     ▼
┌─────────────────┐┌──────────────┐┌────────────────┐┌────────────────┐┌───────────────┐
│ author_create() ││ author_detail()││ author_update()││ author_delete()││ author_list() │
└───────┬─────────┘└───────┬──────┘└───────┬────────┘└───────┬────────┘└───────┬───────┘
        │                  │                │                  │                     │
        │ Form / Validation│                │ Form / Validation│                     │
        │   + ModelForm    │                │   + ModelForm    │                     │
        │   + is_valid()   │                │   + is_valid()   │                     │
        ▼                  ▼                ▼                  ▼                     ▼
 ┌───────────────┐    ┌────────────┐   ┌───────────────┐   ┌──────────────┐   ┌─────────────┐
 │ ORM: .save()  │    │ ORM: .get()│   │ ORM: .save()  │   │ ORM: .delete()│   │ ORM: .all() │
 │ (Create)      │    │ (Read)     │   │ (Update)      │   │ (Delete)      │   │ (List)      │
 └───────────────┘    └────────────┘   └───────────────┘   └──────────────┘   └─────────────┘
        │                  │                │                  │                     │
        ▼                  ▼                ▼                  ▼                     ▼
 ┌───────────────┐    ┌────────────┐   ┌───────────────┐   ┌──────────────┐   ┌─────────────┐
 │ Redirect /    │    │ Render      │   │ Redirect /    │   │ Redirect      │   │ Render      │
 │ Response      │    │ Template    │   │ Response      │   │ Response      │   │ Template    │
 └───────────────┘    └────────────┘   └───────────────┘   └──────────────┘   └─────────────┘
        │                  │                │                  │                     │
        ▼                  ▼                ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                            Templates / HTML Forms                                        │
│ - author_form.html  → used by create/update forms                                         │
│ - author_detail.html → used by read/detail view                                          │
│ - author_confirm_delete.html → used by delete confirmation                               │
│ - author_list.html → used by list view                                                  │
│ - Includes CSRF token {% csrf_token %} and {{ form.as_p }}                                │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### ✅ **Master Map Highlights**

1. **URLs** → map HTTP endpoints to FBVs
2. **Views (FBVs)** → handle form instantiation, validation, ORM operations
3. **Forms / ModelForms** → create, update, validate input
4. **ORM Operations** → `.save()`, `.get()`, `.all()`, `.delete()`
5. **Redirect / Render** → Post/Redirect/Get for create/update/delete, render templates for read/list
6. **Templates** → form rendering, CSRF protection, listing and detail pages

---


