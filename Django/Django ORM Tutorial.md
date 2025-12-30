# 📘 Django ORM & Multi-Tenant SaaS Platform — Full Tutorial

**Edition:** 1.5
**Audience:** Beginner → Intermediate → Advanced Django Developers
**Goal:** Master Django ORM and multi-tenant SaaS identity & authorization
**Prerequisites:** Python 3.12+, Django 5.x (`pip install django`), basic Python knowledge

---

# 🏗️ Step 1: Create Django Project & Apps

```bash
django-admin startproject mysaasproject
cd mysaasproject
python manage.py startapp accounts
python manage.py startapp library
```

**Project Structure**

```
mysaasproject/
├── manage.py
├── mysaasproject/
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── accounts/
│   ├── models.py
│   ├── managers.py
│   ├── views.py
│   └── migrations/
└── library/
    ├── models.py
    ├── views.py
    └── migrations/
```

> **Mental Model:** Each app is a **domain boundary**. `accounts` = identity & tenancy; `library` = example domain models (Author, Book).

---

# ⚡ Step 2: Configure Installed Apps

```python
# settings.py
INSTALLED_APPS = [
    ...
    'accounts',
    'library',
]
```

---

# 🧩 Step 3: SaaS Identity & Tenancy Overview

**ASCII Mega Architecture Diagram — Full SaaS Flow**

```
User (Global Identity)
 │
 ▼
UserProfile (Business Context)
 │
 ▼
Membership (Tenant Scoped Role)
 │
 ▼
Tenant (Security Boundary)
 │
 ▼
Author / Book / Domain Models (Tenant Data)
 │
 ▼
Django ORM
 │
 ▼
SQL Queries
 │
 ▼
Database (MySQL / PostgreSQL / SQLite)
 │
 ▼
QuerySet / Python Objects
 │
 ▼
Frontend / API Layer
```

> **Mental Model:**
> Identity = who you are
> Tenancy = where you can act
> Membership = what you can do in that context
> Domain models = tenant-scoped data
> ORM = safe mapping Python ↔ SQL

---

# ⚡ Step 4: Custom User Model & Manager

**`accounts/managers.py`**

```python
from django.contrib.auth.base_user import BaseUserManager

class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("Email is required")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self.create_user(email, password, **extra_fields)
```

**`accounts/models.py`**

```python
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
from .managers import UserManager

class User(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    objects = UserManager()
```

```python
# settings.py
AUTH_USER_MODEL = "accounts.User"
```

> Identity creation is **tenant-agnostic**, membership controls access per tenant.

---

# ⚡ Step 5: UserProfile, Tenant & Membership

**`accounts/models.py`**

```python
class UserProfile(models.Model):
    user = models.OneToOneField(
        "User", on_delete=models.CASCADE, related_name="profile"
    )
    full_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=50)
    locale = models.CharField(max_length=20, default="en")

class Tenant(models.Model):
    name = models.CharField(max_length=255)
    subdomain = models.CharField(max_length=50, unique=True)
    is_active = models.BooleanField(default=True)

class Role(models.Model):
    name = models.CharField(max_length=50)

class Membership(models.Model):
    user = models.ForeignKey("User", on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    role = models.ForeignKey(Role, on_delete=models.PROTECT)
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ("user", "tenant")
```

**ASCII ORM Diagram**

```
User 1──1 UserProfile
User 1──* Membership *──1 Tenant
Membership *──1 Role
```

> **Principle:** All access is **tenant-scoped**. No global permissions leak.

---

# ⚡ Step 6: Tenant-Aware Middleware

```python
from django.http import Http404
from accounts.models import Tenant

class TenantMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        host = request.get_host()
        subdomain = host.split(".")[0]

        try:
            tenant = Tenant.objects.get(subdomain=subdomain, is_active=True)
        except Tenant.DoesNotExist:
            raise Http404("Tenant not found")

        request.tenant = tenant
        return self.get_response(request)
```

> `request.tenant` is globally available, used in queries, views, and decorators.

---

# ⚡ Step 7: Tenant-Scoped Role Decorator

```python
from functools import wraps
from django.core.exceptions import PermissionDenied
from accounts.models import Membership

def tenant_role_required(role_name):
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            tenant = getattr(request, "tenant", None)
            user = getattr(request, "user", None)
            if not tenant or not user or not user.is_authenticated:
                raise PermissionDenied("Tenant or user context missing")
            if not Membership.objects.filter(user=user, tenant=tenant, role__name=role_name, is_active=True).exists():
                raise PermissionDenied("User lacks required role")
            return view_func(request, *args, **kwargs)
        return _wrapped_view
    return decorator
```

**Usage Example**

```python
@tenant_role_required("Admin")
def dashboard(request):
    return render(request, "dashboard.html")
```

---

# 🏗️ Step 8: Django ORM — Domain Models Example (Library App)

```python
from django.db import models
from accounts.models import Tenant

class Author(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)

class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.ForeignKey(Author, on_delete=models.CASCADE, related_name='books')
    published_date = models.DateField()
    price = models.DecimalField(max_digits=6, decimal_places=2)
```

**Multi-Tenant Data Flow Diagram**

```
Tenant
 ├── id
 └── name
        │
        v
Author
 ├── id
 ├── name
 ├── email
 ├── tenant_id
        │
        v
Book
 ├── id
 ├── title
 ├── author_id
 ├── published_date
 └── price
```

---

# ⚡ Step 9: Tenant-Scoped Queries

```python
tenant = request.tenant
authors = Author.objects.filter(tenant=tenant)
books = Book.objects.filter(author__tenant=tenant)
```

**Query Flow Diagram**

```
Python ORM Query
       │
       v
Django ORM
       │
       v
SQL WHERE tenant_id=?
       │
       v
Tenant-specific results
```

---

# ⚡ Step 10: Advanced ORM Techniques

* `select_related` / `prefetch_related` for performance
* Chain filters: `Book.objects.filter(price__lt=30).order_by('-published_date')[:5]`
* Always scope queries to `tenant`
* Use `related_name` for clarity
* Avoid mixing identity & tenant logic in User model

**QuerySet Flow Diagram**

```
Book.objects.filter(price__lt=30)
        │
        v
QuerySet1
        │
.order_by('-published_date')
        │
        v
QuerySet2
        │
[:5]
        │
        v
Final Python List
```

---

# ✅ Step 11: Full SaaS Data Flow

```
User (Global Identity)
 │
 ▼
UserProfile (Business Context)
 │
 ▼
Membership (Tenant Scoped Role)
 │
 ▼
Tenant (Security Boundary)
 │
 ▼
Author / Book (Tenant Data)
 │
 ▼
ORM Queries --> SQL --> Database Rows
 │
 ▼
QuerySet / Python Object
 │
 ▼
Frontend / API Layer
```

> **Mental Model:**
> Identity = global, Tenancy = security boundary, Membership = scoped authority, ORM = Python ↔ SQL mapping.

---

# ⚡ Step 12: Key Takeaways

* Identity is **tenant-agnostic**
* Membership defines **what a user can do in each tenant**
* Tenant is the **security boundary**
* Django ORM provides **Pythonic, lazy, safe queries**
* Middleware & decorators enforce **tenant isolation**
* ASCII diagrams visualize **boundaries, data flow, and queries**

---

✅ **Complete end-to-end, multi-tenant SaaS Django tutorial** with:

* ASCII diagrams for **identity, tenancy, membership, domain, and ORM flow**
* Step-by-step guidance
* Mental models for **security boundaries & ORM mapping**
* Teaching commentary for **best practices and SaaS architecture**

---

