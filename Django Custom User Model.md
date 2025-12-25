# 🧩 Django Multi-Tenant Identity & Authorization — Full Blueprint

**From “User Table” to “Tenant-Safe SaaS Platform”**

Modern SaaS systems require **identity, tenancy, and scoped authorization** as first-class concepts. A user is never just *who* they are — they are always:

* **Who** they are (identity)
* **Where** they act (tenant)
* **What** they can do (role + permission)

This tutorial **teaches you to design, implement, and reason** about a multi-tenant, zero-trust Django identity system.

---

## 🧠 Mental Model: Layered Security Boundaries

```
+-----------------+
|      User       |  ← Global Identity Boundary
|-----------------|
| email           |
| password        |
| is_active       |
| is_staff        |
+-----------------+
          │
          ▼
+-----------------+
|    Profile      |  ← Business/Human Context
|-----------------|
| full_name       |
| phone           |
| locale          |
+-----------------+
          │
          ▼
+-----------------+
| Membership      |  ← Tenant-Scoped Authority
|-----------------|
| tenant          |
| role            |
| is_active       |
+-----------------+
          │
          ▼
+-----------------+
| Role / Permission|  ← Enforcement Primitives
+-----------------+
```

> **Insight:** Identity, business context, and tenant authorization are **decoupled**. Tenancy is **a boundary, not a field**.

---

## 1️⃣ Why Django Default User Fails for SaaS

Django’s `auth.User` assumes:

* Single global authority
* Single permission namespace
* One application boundary

| Field          | Problem in Multi-Tenant SaaS             |
| -------------- | ---------------------------------------- |
| `username`     | Not globally unique                      |
| `is_staff`     | Cannot represent tenant roles            |
| `groups`       | Permissions leak across tenants          |
| Mixed concerns | Identity + authorization tightly coupled |

> 🔥 Tenant logic in `auth_user` = permanent security debt.

---

## 2️⃣ Custom User Manager & Model

### Manager: Enforces Global Identity

```python
# accounts/managers.py
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

> **Key:** Tenancy is never handled here; identity creation is **tenant-agnostic**.

---

### Custom User Model: Identity Only

```python
# accounts/models.py
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

---

### AUTH_USER_MODEL

```python
AUTH_USER_MODEL = "accounts.User"
```

> **Implication:** All FKs reference User. Changing later breaks everything. Tenancy remains **contextual**, not baked into identity.

---

## 3️⃣ UserProfile — Business Context

```python
# accounts/models.py
from django.conf import settings

class UserProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="profile"
    )
    full_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=50)
    locale = models.CharField(max_length=20, default="en")
```

* Safe to change often
* Tenant-agnostic
* Contains **business-relevant info**

---

## 4️⃣ Tenant & Membership

### Tenant Model

```python
class Tenant(models.Model):
    name = models.CharField(max_length=255)
    subdomain = models.CharField(max_length=50, unique=True)
    is_active = models.BooleanField(default=True)
```

### Membership + Role

```python
class Role(models.Model):
    name = models.CharField(max_length=50)

class Membership(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    role = models.ForeignKey(Role, on_delete=models.PROTECT)
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ("user", "tenant")
```

* Defines **what a user can do per tenant**
* Enables **tenant-scoped permissions**

---

## 5️⃣ Tenant-Aware Middleware

```python
# tenants/middleware.py
from django.http import Http404
from tenants.models import Tenant

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

> `request.tenant` becomes globally available and can be used with JWT/session authentication.

---

## 6️⃣ Tenant-Scoped Permissions Decorator

```python
# tenants/decorators.py
from functools import wraps
from django.core.exceptions import PermissionDenied
from tenants.models import Membership

def tenant_role_required(role_name):
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            tenant = getattr(request, "tenant", None)
            user = getattr(request, "user", None)
            if not tenant or not user or not user.is_authenticated:
                raise PermissionDenied("Tenant or user context missing")

            if not Membership.objects.filter(
                user=user, tenant=tenant, role__name=role_name, is_active=True
            ).exists():
                raise PermissionDenied("User lacks required role")
            
            return view_func(request, *args, **kwargs)
        return _wrapped_view
    return decorator
```

**Usage in Views:**

```python
@tenant_role_required("Admin")
def dashboard(request):
    return render(request, "dashboard.html")
```

---

## 7️⃣ Full Multi-Tenant Request Flow (ASCII Diagram)

```
Client Request
      │
      ▼
+-------------------+
| TenantMiddleware  |  ← Resolves tenant from subdomain
+-------------------+
      │
      ▼
+-------------------+
| Authentication    |  ← Verifies global User identity
+-------------------+
      │
      ▼
+-------------------+
| Membership Check  |  ← Tenant-scoped Role/Permission enforcement
+-------------------+
      │
      ▼
+-------------------+
| View / Business   |  ← Tenant-aware execution
+-------------------+
      │
      ▼
Response
```

> ✅ This **diagram shows the complete enforcement path**: identity → tenant → membership → role → view → response.

---

## 8️⃣ Layered Mental Model

| Layer      | Responsibility         |
| ---------- | ---------------------- |
| User       | Global identity        |
| Profile    | Business/human context |
| Tenant     | Authorization boundary |
| Membership | Scoped authority       |
| Role       | Business intent        |
| Permission | Enforcement primitive  |

---

## 9️⃣ Security Guarantees

* Tenant isolation **by design**
* No global admin leakage
* No implicit trust
* Auditable permission decisions
* Zero-trust compatible

---

## 10️⃣ Production Advantages

* Multi-tenant SaaS readiness
* Zero-trust APIs
* OAuth2 / SSO / MFA support
* SOC2 / ISO compliance ready
* Flexible for future auth migrations

---
