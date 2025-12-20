# 🧩 Django Custom User Model — Identity, Tenancy & Security Boundaries

**From “User Table” to “Multi-Tenant Security Platform”**

In modern systems, **identity without tenancy is incomplete**.
A user is never just *who* they are — they are always:

* **Who** they are (identity)
* **Where** they are acting (tenant)
* **What** they are allowed to do (role + permission)

This architecture elevates **tenancy to a first-class security boundary**, alongside identity and credentials.

**Core principle:**

> Authentication answers *who you are*
> Authorization answers *what you can do*
> **Tenancy answers *where you are allowed to act***

---

## 1️⃣ Identity as a Security Boundary

A critical mental model correction:

> ❌ “The User model stores user data”
> ✅ “The User model defines a cryptographic authentication boundary”

In a multi-tenant system:

* Identity **must be globally unique**
* Identity is **tenant-agnostic**
* Tenant-specific access is resolved elsewhere

### Responsibilities of the User Model

1. **Identity** – Global, tenant-agnostic identifier (email, UUID, external IdP subject)
2. **Credential Verification** – Password hashes, MFA challenges, WebAuthn assertions
3. **Account State** – Active, disabled, locked, staff, superuser
4. **Permission Interface** – Capability to be authorized, not tenant-scoped

> 🚨 The User model **must not** contain tenant-specific authorization.

---

## 2️⃣ Why Django’s Default User Breaks in Multi-Tenant Systems

Django’s default `auth.User` assumes:

* One global authority
* One permission namespace
* One application boundary

These assumptions **collapse** in SaaS / multi-tenant platforms.

| Default Field  | Why It Breaks                              |
| -------------- | ------------------------------------------ |
| `username`     | Artificial, not identity-safe              |
| `is_staff`     | Global flag, cannot represent tenant roles |
| `groups`       | Global permissions leak across tenants     |
| Mixed concerns | Identity + authorization tightly coupled   |

> 🔥 Once tenant logic leaks into `auth_user`, **security debt is permanent**.

---

## 3️⃣ Designing Identity, Profile & Tenant

### Separation by Rate of Change

| Layer             | Change Frequency | Security Sensitivity |
| ----------------- | ---------------- | -------------------- |
| User              | Rare             | Extremely High       |
| Profile           | Frequent         | Medium               |
| Tenant Membership | Dynamic          | High                 |

### Canonical Data Model

```
┌────────────┐
│   User     │  ← Global Identity Boundary
├────────────┤
│ email      │
│ password   │
│ is_active  │
│ is_staff   │
└────────────┘
       │
       ▼
┌──────────────┐
│ UserProfile  │  ← Human / Business Context
├──────────────┤
│ full_name    │
│ phone        │
│ locale       │
└──────────────┘
       │
       ▼
┌──────────────┐
│ Membership   │  ← Tenant Security Boundary
├──────────────┤
│ tenant       │
│ role         │
│ is_active    │
└──────────────┘
```

> Tenancy is **not a field**, it is a **boundary**.

---

## 4️⃣ Custom User Manager — Enforcing Global Identity

The manager ensures **global invariants**, independent of tenants.

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

> Tenancy is **never** handled here — identity creation remains **tenant-agnostic**.

---

## 5️⃣ Custom User Model — Identity Only

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

**Key Points:**

* Email = global identity key
* No tenant or business logic
* PermissionsMixin gives global auth primitives only

---

## 6️⃣ AUTH_USER_MODEL — Point of No Return

```python
AUTH_USER_MODEL = "accounts.User"
```

**Implications:**

* All FKs must reference `User`
* Tenants can rotate / merge without touching the identity
* Authorization remains **contextual**

> Changing this later **breaks everything**.

---

## 7️⃣ UserProfile — Context Without Authority

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

**Benefits:**

* Safe to change often
* Tenant-agnostic
* Contains **business-relevant** information

---

## 8️⃣ Tenant Model — Authorization Container

```python
class Tenant(models.Model):
    name = models.CharField(max_length=255)
    subdomain = models.CharField(max_length=50, unique=True)
    is_active = models.BooleanField(default=True)
```

> Tenants = organizations, workspaces, accounts, or customers.

---

## 9️⃣ Membership — Scoped Authorization

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

**Purpose:**

* Defines **what a user can do in a tenant**
* Supports **multi-tenant SaaS**
* Enables **tenant-scoped permissions**

---

## 🔐 Tenant-Scoped Permissions & Decorators

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

            if not Membership.objects.filter(user=user, tenant=tenant, role__name=role_name, is_active=True).exists():
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

## 🔑 Tenant-Aware Middleware

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

* `request.tenant` is globally available
* Can be used with JWT or session-based authentication

---

## 🔐 Security Guarantees

* No global admin leakage
* No implicit trust
* Tenant isolation by design
* Auditable permission decisions
* Zero-trust compatible

---

## 🧠 Mental Model

| Layer      | Responsibility         |
| ---------- | ---------------------- |
| User       | Global identity        |
| Profile    | Human context          |
| Tenant     | Authorization boundary |
| Membership | Scoped authority       |
| Role       | Business intent        |
| Permission | Enforcement primitive  |

---

## 🚀 Production Advantages

* Multi-tenant SaaS readiness
* Zero-trust APIs
* OAuth2 / SSO / MFA support
* SOC2 / ISO compliance ready
* Flexible for future auth migrations

---

✅ This is a **full, classic Django multi-tenant identity & authorization platform**.

