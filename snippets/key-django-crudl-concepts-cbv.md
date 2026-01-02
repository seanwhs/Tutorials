# 🐍 **Django CRUDL Concepts – CBV (Class-Based Views)**

**CRUDL** = **Create, Read, Update, Delete, List** – the core resource operations.

---

## 1. **Model Setup**

```python
from django.db import models

class Author(models.Model):
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    birth_date = models.DateField()

    def __str__(self):
        return f"{self.first_name} {self.last_name}"
```

---

## 2. **Forms**

```python
from django import forms
from .models import Author

class AuthorForm(forms.ModelForm):
    class Meta:
        model = Author
        fields = ['first_name', 'last_name', 'birth_date']
```

* CBVs often use `ModelForm` automatically with generic views.

---

## 3. **Class-Based Views (CBV)**

Django provides **generic CBVs** for CRUDL operations:

| CRUDL  | Generic CBV  | Notes                                |
| ------ | ------------ | ------------------------------------ |
| Create | `CreateView` | Handles form rendering and `.save()` |
| Read   | `DetailView` | Fetch single object, `pk` or `slug`  |
| Update | `UpdateView` | Handles form + instance updates      |
| Delete | `DeleteView` | Confirm deletion + redirect          |
| List   | `ListView`   | Display multiple objects             |

---

### **Example CBVs**

```python
from django.urls import reverse_lazy
from django.views.generic import ListView, DetailView, CreateView, UpdateView, DeleteView
from .models import Author
from .forms import AuthorForm

# List
class AuthorListView(ListView):
    model = Author
    template_name = "author_list.html"
    context_object_name = "authors"

# Detail
class AuthorDetailView(DetailView):
    model = Author
    template_name = "author_detail.html"
    context_object_name = "author"

# Create
class AuthorCreateView(CreateView):
    model = Author
    form_class = AuthorForm
    template_name = "author_form.html"
    success_url = reverse_lazy("author_list")

# Update
class AuthorUpdateView(UpdateView):
    model = Author
    form_class = AuthorForm
    template_name = "author_form.html"
    success_url = reverse_lazy("author_list")

# Delete
class AuthorDeleteView(DeleteView):
    model = Author
    template_name = "author_confirm_delete.html"
    success_url = reverse_lazy("author_list")
```

---

## 4. **URLs**

```python
from django.urls import path
from .views import (
    AuthorListView,
    AuthorDetailView,
    AuthorCreateView,
    AuthorUpdateView,
    AuthorDeleteView,
)

urlpatterns = [
    path("authors/", AuthorListView.as_view(), name="author_list"),
    path("authors/new/", AuthorCreateView.as_view(), name="author_create"),
    path("authors/<int:pk>/", AuthorDetailView.as_view(), name="author_detail"),
    path("authors/<int:pk>/edit/", AuthorUpdateView.as_view(), name="author_update"),
    path("authors/<int:pk>/delete/", AuthorDeleteView.as_view(), name="author_delete"),
]
```

* CBVs use `.as_view()` to convert class to callable view
* `pk` is default lookup; can also use `slug_field`

---

## 5. **Templates**

* CBVs render templates like FBVs but automatically pass context:

  * `ListView` → `object_list` (or `context_object_name`)
  * `DetailView` → `object` (or `context_object_name`)
  * `CreateView` / `UpdateView` → `form`
  * `DeleteView` → `object`

```html
<!-- author_list.html -->
<ul>
  {% for author in authors %}
    <li><a href="{% url 'author_detail' author.pk %}">{{ author }}</a></li>
  {% endfor %}
</ul>
<a href="{% url 'author_create' %}">Add New Author</a>
```

---

## 6. **CBV Advantages**

* Less boilerplate (no explicit form handling or `.save()`)
* Built-in `get_context_data()` for extra template context
* Easy mixins (`LoginRequiredMixin`, `PermissionRequiredMixin`)
* Reusable and extendable

---

## 7. **ASCII “Django CRUDL CBV Power Map”**

```
                         ┌───────────────┐
                         │      URLs     │
                         └──────┬────────┘
                                │
        ┌─────────┬─────────────┼─────────────┬─────────────┐
        │         │             │             │             │
    /new/      /<pk>/        /<pk>/edit/   /<pk>/delete/  / (list)
   Create      Read           Update        Delete          List
        │         │             │             │             │
        ▼         ▼             ▼             ▼             ▼
┌─────────────┐┌────────────┐┌──────────────┐┌─────────────┐┌─────────────┐
│ CreateView  ││ DetailView ││ UpdateView   ││ DeleteView  ││ ListView    │
└──────┬──────┘└──────┬─────┘└───────┬──────┘└─────┬───────┘└──────┬──────┘
       │                │              │               │               │
       ▼                ▼              ▼               ▼               ▼
   ModelForm / ORM   ORM: get()    ModelForm / ORM   ORM: delete()   ORM: all()
       │                │              │               │               │
       ▼                ▼              ▼               ▼               ▼
  Save / Redirect   Render Template  Save / Redirect  Redirect / Render Render Template
       │                │              │               │               │
       ▼                ▼              ▼               ▼               ▼
  ┌────────────────────────────────────────────────────────────────────────┐
  │                        Templates / HTML Forms                           │
  │ - author_form.html  → create/update forms                                 │
  │ - author_detail.html → display single object                              │
  │ - author_list.html → list objects                                         │
  │ - author_confirm_delete.html → confirm deletion                           │
  │ - Includes CSRF token {% csrf_token %}                                    │
  └────────────────────────────────────────────────────────────────────────┘
```

✅ **Highlights**

* CBVs reduce boilerplate by handling form validation, ORM `.save()` automatically
* `as_view()` converts class to callable
* Supports mixins for authentication, permissions, and reusable logic
* CBVs map neatly to CRUDL operations

---
