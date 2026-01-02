# 🐍 Django FBV vs CBV Cheat Sheet

---

## 1️⃣ URLs & Routing

In Django, **URLs map to views**. FBVs map directly to functions; CBVs map via `.as_view()`.

```
          ┌───────────────┐
          │     URLs      │
          └──────┬────────┘
                 │
  ┌───────────────┬───────────────┬───────────────┬───────────────┬───────────────┐
  │               │               │               │               │
 /new/ (Create)  /<pk>/ (Read)  /<pk>/edit/ (Update) /<pk>/delete/ (Delete) / (List)
```

**URL mapping examples:**

```python
# FBV
path('new/', author_create, name='author-create')
path('<int:pk>/', author_detail, name='author-detail')

# CBV
path('new/', AuthorCreateView.as_view(), name='author-create')
path('<int:pk>/', AuthorDetailView.as_view(), name='author-detail')
```

---

## 2️⃣ CRUDL View Patterns

| Action | FBV Function                 | CBV Class    |
| ------ | ---------------------------- | ------------ |
| Create | `author_create(request)`     | `CreateView` |
| Read   | `author_detail(request, pk)` | `DetailView` |
| Update | `author_update(request, pk)` | `UpdateView` |
| Delete | `author_delete(request, pk)` | `DeleteView` |
| List   | `author_list(request)`       | `ListView`   |

---

## 3️⃣ FBV vs CBV Comparison Table

| Feature                  | **FBV**                             | **CBV**                                                    |
| ------------------------ | ----------------------------------- | ---------------------------------------------------------- |
| Boilerplate              | More verbose, explicit logic        | Less boilerplate, generic views handle common tasks        |
| Flexibility              | Highly flexible, custom logic easy  | Customization via mixins or overriding methods             |
| Form Handling            | Manual: instantiate, validate, save | Automatic with generic views                               |
| URL Mapping              | Directly to functions               | Directly to class via `.as_view()`                         |
| Context & Templates      | Manual context dict                 | Auto-generated context with `context_object_name`          |
| Redirects / Success URLs | Manual via `redirect()`             | Handled via `success_url`                                  |
| Mixins / Reusability     | Function decorators                 | Class mixins (LoginRequiredMixin, PermissionRequiredMixin) |
| Use Case                 | Simple, small projects, very custom | Large projects, CRUD-heavy apps                            |

---

## 4️⃣ Forms / ModelForms

**FBV manual form handling:**

```python
def author_create(request):
    form = AuthorForm(request.POST or None)
    if form.is_valid():
        form.save()
        return redirect('author-list')
    return render(request, 'authors/form.html', {'form': form})
```

**CBV automatic form handling:**

```python
class AuthorCreateView(CreateView):
    model = Author
    form_class = AuthorForm
    template_name = 'authors/form.html'
    success_url = reverse_lazy('author-list')
```

**Notes:**

* CBVs handle form validation automatically.
* FBVs require manual `.is_valid()`, `.save()`, and redirect logic.

---

## 5️⃣ Templates / Context

**FBV:**

```python
def author_list(request):
    authors = Author.objects.all()
    return render(request, 'authors/list.html', {'authors': authors})
```

**CBV:**

```python
class AuthorListView(ListView):
    model = Author
    template_name = 'authors/list.html'
    context_object_name = 'authors'
```

* CBVs automatically pass **`context_object_name`** to templates.
* FBVs require building the context dict manually.

---

## 6️⃣ ORM Operations

| Operation     | FBV Example                        | CBV Behavior                  |
| ------------- | ---------------------------------- | ----------------------------- |
| Create / Save | `form.save()`                      | Auto-managed by generic views |
| Read          | `get_object_or_404(Author, pk=pk)` | Auto-managed via `DetailView` |
| Update        | `form.save()`                      | Auto-managed via `UpdateView` |
| Delete        | `obj.delete()`                     | Auto-managed via `DeleteView` |
| List          | `Author.objects.all()`             | Auto-managed via `ListView`   |

---

## 7️⃣ Post / Redirect / Get Pattern (PRG)

* **FBV:** You must manually redirect after POST to prevent resubmission.

```python
if form.is_valid():
    form.save()
    return redirect('author-list')
```

* **CBV:** Handled via `success_url`.

```python
success_url = reverse_lazy('author-list')
```

---

## 8️⃣ Mixins / Reusability

* Use **mixins** to extend CBV functionality without rewriting logic.
* Common examples:

```python
from django.contrib.auth.mixins import LoginRequiredMixin, PermissionRequiredMixin

class AuthorUpdateView(LoginRequiredMixin, UpdateView):
    model = Author
    form_class = AuthorForm
    success_url = reverse_lazy('author-list')
```

* FBVs achieve similar behavior using **decorators**:

```python
from django.contrib.auth.decorators import login_required

@login_required
def author_update(request, pk):
    ...
```

---

## 9️⃣ Small Complete FBV Example (Create + List)

```python
# views.py
def author_create(request):
    form = AuthorForm(request.POST or None)
    if form.is_valid():
        form.save()
        return redirect('author-list')
    return render(request, 'authors/form.html', {'form': form})

def author_list(request):
    authors = Author.objects.all()
    return render(request, 'authors/list.html', {'authors': authors})
```

**CBV equivalent:**

```python
class AuthorCreateView(CreateView):
    model = Author
    form_class = AuthorForm
    template_name = 'authors/form.html'
    success_url = reverse_lazy('author-list')

class AuthorListView(ListView):
    model = Author
    template_name = 'authors/list.html'
    context_object_name = 'authors'
```

---

## 10️⃣ Full Flow Visual Summary (ASCII)

```
URLs → View → Form/ORM → Template → Response
 ┌───────────────┐
 │     URLs      │
 └──────┬────────┘
        │
 ┌─────────────┐ ┌─────────────┐
 │ FBV         │ │ CBV         │
 │ def author_…│ │ CreateView… │
 └─────┬───────┘ └─────┬───────┘
       │               │
       ▼               ▼
 ┌─────────────┐ ┌─────────────┐
 │ Forms       │ │ Forms       │
 │ Manual      │ │ Auto        │
 └─────┬───────┘ └─────┬───────┘
       │               │
       ▼               ▼
 ┌─────────────┐ ┌─────────────┐
 │ ORM         │ │ ORM         │
 │ Manual      │ │ Auto        │
 └─────┬───────┘ └─────┬───────┘
       │               │
       ▼               ▼
 ┌─────────────┐ ┌─────────────┐
 │ Template    │ │ Template    │
 │ Manual      │ │ Auto        │
 └─────────────┘ └─────────────┘
```

---

### ✅ **Ultimate Cheat Sheet Takeaways**

1. **FBVs**: explicit, flexible, suitable for small/custom projects.
2. **CBVs**: reduce boilerplate, ideal for CRUD-heavy resources.
3. **Mixins + CBVs**: maximize reusability and maintainability.
4. **PRG pattern**: always redirect after POST.
5. **Forms & ORM**: FBV manual, CBV automatic.
6. **Templates**: CBV auto passes `context_object_name`, FBV manual context dict.

