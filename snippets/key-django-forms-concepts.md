# 🐍 **Key Django Forms Concepts**

Django Forms allow you to **handle user input, validate data, and render HTML forms** seamlessly.

---

## 1. Basic Forms

```python
from django import forms

class ContactForm(forms.Form):
    name = forms.CharField(max_length=50)
    email = forms.EmailField()
    message = forms.CharField(widget=forms.Textarea)
```

* Each field → HTML input element
* `widget` → customize HTML element
* `initial` → default value
* `required` → True/False

**Rendering in template:**

```html
<form method="post">
  {% csrf_token %}
  {{ form.as_p }}
  <button type="submit">Submit</button>
</form>
```

---

## 2. Field Types

| Field Type            | HTML Input Type / Widget            |
| --------------------- | ----------------------------------- |
| `CharField`           | `<input type="text">`               |
| `EmailField`          | `<input type="email">`              |
| `IntegerField`        | `<input type="number">`             |
| `BooleanField`        | `<input type="checkbox">`           |
| `DateField`           | `<input type="date">`               |
| `ChoiceField`         | `<select>`                          |
| `MultipleChoiceField` | `<select multiple>`                 |
| `DecimalField`        | `<input type="number" step="0.01">` |
| `URLField`            | `<input type="url">`                |
| `FileField`           | `<input type="file">`               |
| `ImageField`          | `<input type="file">`               |

---

## 3. Widgets

Widgets define **HTML rendering and behavior**:

```python
forms.TextInput(attrs={"class": "form-control", "placeholder": "Enter your name"})
forms.PasswordInput()
forms.EmailInput(attrs={"class": "email-field"})
forms.Textarea(attrs={"rows": 5, "cols": 40})
```

* `attrs` → HTML attributes
* Common for Bootstrap styling

---

## 4. Validation

### Built-in validation:

* Required fields: `required=True`
* Field-specific validators: `min_length`, `max_length`, `max_value`, `min_value`, `EmailValidator`, `URLValidator`

### Custom validation:

```python
from django.core.exceptions import ValidationError

class ContactForm(forms.Form):
    email = forms.EmailField()

    def clean_email(self):
        email = self.cleaned_data['email']
        if not email.endswith("@example.com"):
            raise ValidationError("Email must be from example.com")
        return email
```

* `clean_<fieldname>` → field-specific validation
* `clean()` → form-wide validation

---

## 5. Model Forms

Model Forms automatically map a **Django model** to a form:

```python
from django.forms import ModelForm
from myapp.models import Author

class AuthorForm(ModelForm):
    class Meta:
        model = Author
        fields = ['first_name', 'last_name', 'birth_date']
        widgets = {
            'birth_date': forms.DateInput(attrs={'type': 'date'})
        }
```

* `fields` → include specific model fields
* `exclude` → exclude specific fields
* `widgets` → customize field rendering

**Save to DB:**

```python
form = AuthorForm(request.POST)
if form.is_valid():
    form.save()
```

---

## 6. Formsets

Formsets manage **multiple forms on a page**:

```python
from django.forms import formset_factory

AuthorFormSet = formset_factory(AuthorForm, extra=3)
formset = AuthorFormSet()
```

* `extra` → number of empty forms to display
* Useful for bulk input

---

## 7. Advanced Patterns

* **Custom Widgets** → integrate JS plugins like datepicker, select2
* **Dynamic fields** → modify fields in `__init__`
* **Bootstrap integration** → add `class="form-control"` via widgets or `crispy-forms`
* **AJAX forms** → submit and validate without page reload
* **CSRF protection** → `{% csrf_token %}`

---

## 8. Example: Contact Form with Validation

```python
from django import forms
from django.core.exceptions import ValidationError

class ContactForm(forms.Form):
    name = forms.CharField(max_length=50, widget=forms.TextInput(attrs={"class": "form-control"}))
    email = forms.EmailField(widget=forms.EmailInput(attrs={"class": "form-control"}))
    message = forms.CharField(widget=forms.Textarea(attrs={"class": "form-control", "rows": 5}))

    def clean_email(self):
        email = self.cleaned_data['email']
        if not email.endswith("@example.com"):
            raise ValidationError("Email must be from example.com")
        return email
```

---

## ✅ Django Forms Cheat Sheet

| Concept         | Example / Class / Method         | Use Case                        |
| --------------- | -------------------------------- | ------------------------------- |
| Basic Form      | `forms.Form`                     | Custom input forms              |
| Model Form      | `forms.ModelForm`                | Map model to form automatically |
| Fields          | `CharField`, `EmailField`        | Different input types           |
| Widgets         | `TextInput`, `Textarea`          | Customize HTML rendering        |
| Validation      | `clean_<field>`, `clean()`       | Field & form validation         |
| Formsets        | `formset_factory`                | Multiple forms on one page      |
| Saving Data     | `form.save()`                    | Save ModelForm to DB            |
| Styling         | `attrs={'class':'form-control'}` | Bootstrap integration           |
| AJAX / JS       | Custom JS + widgets              | Dynamic user interaction        |
| CSRF Protection | `{% csrf_token %}`               | Security for POST forms         |

---

```
                          ┌─────────────────────┐
                          │    Django Forms     │
                          └─────────┬───────────┘
                                    │
         ┌──────────────────────────┼──────────────────────────┐
         │                          │                          │
   ┌─────────────┐           ┌─────────────┐            ┌─────────────┐
   │ Basic Forms │           │ Model Forms │            │ Formsets     │
   └─────┬───────┘           └─────┬───────┘            └─────┬───────┘
         │                          │                          │
 ┌───────┴────────┐         ┌───────┴────────┐       ┌─────────┴────────┐
 │ fields         │         │ model mapping  │       │ multiple forms     │
 │ - CharField    │         │ fields/exclude │       │ extra forms        │
 │ - EmailField   │         │ widgets        │       │ validation        │
 │ - BooleanField │         │ save() method  │       │ dynamic forms      │
 │ - DateField    │         └────────────────┘       └───────────────────┘
 │ - ChoiceField  │
 │ - Textarea     │
 └───────┬────────┘
         │
         ▼
 ┌───────────────┐
 │ Widgets       │
 │ - TextInput   │
 │ - Textarea    │
 │ - PasswordInput│
 │ - DateInput   │
 │ - FileInput   │
 └───────┬───────┘
         │
         ▼
 ┌───────────────┐
 │ Validation    │
 │ - required    │
 │ - min_length  │
 │ - max_length  │
 │ - clean_<field>│
 │ - clean()     │
 │ - custom validators │
 └───────┬───────┘
         │
         ▼
 ┌───────────────┐
 │ Form Rendering│
 │ - as_p        │
 │ - as_table    │
 │ - as_ul       │
 │ - CSRF token  │
 └───────┬───────┘
         │
         ▼
 ┌───────────────┐
 │ Submission    │
 │ - is_valid()  │
 │ - cleaned_data│
 │ - save()      │
 └───────────────┘
```

### ✅ **Diagram Highlights**

1. **Forms Types:** `Basic Forms` vs `Model Forms` vs `Formsets`
2. **Fields:** Mapping to HTML input types
3. **Widgets:** Customize rendering and attributes
4. **Validation:** Built-in and custom field/form validation
5. **Rendering:** `.as_p`, `.as_table`, `.as_ul`
6. **Submission:** `is_valid()`, `cleaned_data`, `save()` for ModelForms
7. **CSRF Protection:** `{% csrf_token %}`

---

