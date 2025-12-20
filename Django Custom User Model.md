# 🧩 Django Custom User Model — Identity, Tenancy & Security Boundaries

**From “User Table” to “Multi-Tenant Security Platform”**

In modern systems, **identity without tenancy is incomplete**.

A user is never just *who* — they are always:

* **Who** they are (identity)
* **Where** they are acting (tenant)
* **What** they are allowed to do (role + permission)

This architecture elevates **tenancy to a first-class security boundary**, alongside identity and credentials.

**Core principle:**

> Authentication answers *who you are*
> Authorization answers *what you can do*
> **Tenancy answers *where you are allowed to act***

---

## 1️⃣ Identity Is a Security Boundary (Not Just a Table)

A critical mental model correction:

> ❌ “The User model stores user data”
> ✅ “The User model defines a cryptographic authentication boundary”

In a multi-tenant system, identity **must be globally unique**, but **never globally authoritative**.

### What the User Model Is Responsible For

The User model handles **only security-critical concerns**:

1. **Identity**
   Global, tenant-agnostic identifier
   (email, UUID, external IdP subject)

2. **Credential Verification**
   Password hashes, MFA challenges, WebAuthn assertions

3. **Account State**
   Active, disabled, locked, staff, superuser

4. **Permission Interface (Not Scope)**
   Capability to be authorized — *never tenant context*

> 🚨 The User model **must not** contain tenant-specific authorization.

---

## 2️⃣ Why Django’s Default User Breaks in Multi-Tenant Systems

Django’s default `auth.User` assumes:

* One global authority
* One namespace of permissions
* One application boundary

These assumptions **collapse** in SaaS systems.

### Structural Failures at Scale

| Default Field  | Why It Breaks                          |
| -------------- | -------------------------------------- |
| `username`     | Artificial, not identity-safe          |
| `is_staff`     | Global flag in tenant world            |
| `groups`       | Global permissions leak across tenants |
| Mixed concerns | Identity + authorization coupled       |

> 🔥 Once tenant logic leaks into `auth_user`, **security debt becomes permanent**.

---

## 3️⃣ Designing Identity, Profile & Tenant (Before Coding)

### Three Different Rates of Change

| Layer             | Change Frequency | Security Sensitivity |
| ----------------- | ---------------- | -------------------- |
| User              | Rare             | Extremely High       |
| Profile           | Frequent         | Medium               |
| Tenant Membership | Dynamic          | High                 |

### Canonical Separation

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

> Tenancy is **not a field** — it is a **boundary**.

---

## 4️⃣ Custom User Manager — Enforcing Global Identity Invariants

The user manager ensures **global correctness** across tenants.

```python
class UserManager(BaseUserManager):
```

### Why This Matters in Multi-Tenant Systems

* Email must be globally unique
* Password hashing must be consistent
* Superuser creation must be explicit and auditable

```python
def create_user(self, email, password=None, **extra_fields):
    if not email:
        raise ValueError("Email is required")

    email = self.normalize_email(email)
    user = self.model(email=email, **extra_fields)
    user.set_password(password)
    user.save(using=self._db)
    return user
```

> Tenancy is **never** handled here.
> Identity creation must remain tenant-agnostic.

---

## 5️⃣ Custom User Model — Identity Without Authorization Scope

```python
class User(AbstractBaseUser, PermissionsMixin):
```

This gives:

| Capability       | Provided By      |
| ---------------- | ---------------- |
| Password hashing | AbstractBaseUser |
| Global perms     | PermissionsMixin |

But **tenant-scoped permissions are intentionally excluded**.

```python
email = models.EmailField(unique=True)
USERNAME_FIELD = "email"
objects = UserManager()
```

✔ Email = global identity
✔ No tenant logic
✔ No business fields

---

## 6️⃣ AUTH_USER_MODEL — The Point of No Return

```python
AUTH_USER_MODEL = "accounts.User"
```

In a multi-tenant platform, this ensures:

* Every FK points to a global identity
* Tenants can be rotated or merged
* Authorization remains contextual

> Changing this later breaks **everything**.

---

## 7️⃣ User Profile — Context Without Authority

Profiles answer:

> “Who is this human?”

They **never** answer:

> “What are they allowed to do?”

```python
class UserProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="profile"
    )
    full_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=50)
```

✔ Safe to change
✔ Tenant-agnostic
✔ Business-friendly

---

## 8️⃣ Tenant Model — Authorization Container

```python
class Tenant(models.Model):
    name = models.CharField(max_length=255)
    is_active = models.BooleanField(default=True)
```

Tenants represent:

* Organizations
* Workspaces
* Accounts
* Customers

---

## 9️⃣ Membership — The True Authorization Boundary

```python
class Membership(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    role = models.ForeignKey("Role", on_delete=models.PROTECT)
    is_active = models.BooleanField(default=True)
```

This answers:

> “What can this user do **inside this tenant**?”

---

## 🔐 Roles vs Permissions (Tenant-Scoped)

### Why Global Permissions Are Dangerous

Django permissions are global:

```
change_user
delete_invoice
```

But authority must be tenant-scoped.

### Role Abstraction

```python
class Role(models.Model):
    name = models.CharField(max_length=50)
    permissions = models.ManyToManyField(Permission)
```

Final evaluation:

```
(User, Tenant, Role) → Permissions
```

✔ No cross-tenant leakage
✔ Auditable
✔ Zero-trust compatible

---

## 🧠 Zero-Trust Authorization Flow

Every request must prove:

1. **Who** you are → User
2. **Where** you are acting → Tenant
3. **What** you can do → Role + Permission

JWT claims are **hints**, never authority.

---

## 🔐 Security Guarantees This Architecture Provides

✔ No global admin leakage
✔ No implicit trust
✔ Tenant isolation by design
✔ Auditable permission decisions
✔ Ready for JWT, OAuth, MFA, SSO

---

## 🧠 Mental Model Summary

| Layer      | Responsibility         |
| ---------- | ---------------------- |
| User       | Global identity        |
| Profile    | Human context          |
| Tenant     | Authorization boundary |
| Membership | Scoped authority       |
| Role       | Business intent        |
| Permission | Enforcement primitive  |

---

## 🚀 Why This Works in Production

This design enables:

* Multi-tenant SaaS
* Zero-trust APIs
* OAuth2 / SSO
* MFA / WebAuthn
* SOC2 / ISO audits
* Future auth migrations without rewrites

---

## 🏁 Final Takeaway

> **Identity answers who. Tenancy answers where. Roles answer what.**

If any of these are mixed, **security fails quietly**.

Designed correctly, Django becomes a **multi-tenant identity platform**, not just a framework.

---

# 🏛 Multi-Tenant Authentication & Permissions in Classic Django

This guide demonstrates:

1. Resolving **tenant context** per request.
2. JWT or session-based **authentication with tenant-awareness**.
3. **Role- and tenant-scoped permissions** via decorators.
4. Ready-to-use in **any classic Django project**.

---

## 1️⃣ Tenant-Aware Middleware

**Purpose:** Inject tenant context into each request.

```python
# tenants/middleware.py
from django.http import Http404
from tenants.models import Tenant

class TenantMiddleware:
    """
    Resolves the tenant based on subdomain or request header
    and attaches it to request.tenant.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        host = request.get_host()  # e.g., 'acme.example.com'
        subdomain = host.split('.')[0]

        try:
            tenant = Tenant.objects.get(subdomain=subdomain, is_active=True)
        except Tenant.DoesNotExist:
            raise Http404("Tenant not found")

        request.tenant = tenant
        return self.get_response(request)
```

### Explanation:

* `request.tenant` is globally available for **views, decorators, templates**.
* Protects against **unauthorized access**.
* Could be extended to **resolve tenant from JWT** instead of subdomain.

---

## 2️⃣ JWT + Tenant Resolution for Web Requests

For classic Django, JWTs are often stored in **cookies**. Each JWT includes:

```json
{
    "user_id": 42,
    "tenant_id": 1,
    "exp": 1680000000
}
```

### Middleware for JWT Resolution

```python
import jwt
from django.conf import settings
from django.contrib.auth import get_user_model
from django.http import HttpResponseForbidden
from tenants.models import Membership

class JWTTenantMiddleware:
    """
    Authenticate user from JWT stored in HttpOnly cookie
    and validate tenant membership.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        token = request.COOKIES.get("jwt_access")
        if token:
            try:
                payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
                user_model = get_user_model()
                user = user_model.objects.get(id=payload["user_id"])
                tenant_id = payload.get("tenant_id")
                from tenants.models import Tenant
                tenant = Tenant.objects.get(id=tenant_id)

                # Verify membership
                if not Membership.objects.filter(user=user, tenant=tenant, is_active=True).exists():
                    return HttpResponseForbidden("User not authorized for this tenant")

                request.user = user
                request.tenant = tenant

            except (jwt.ExpiredSignatureError, jwt.DecodeError, user_model.DoesNotExist):
                request.user = None
                request.tenant = None
        return self.get_response(request)
```

**Key Points:**

* JWT stored in **HttpOnly cookie** → reduces XSS risk.
* `request.tenant` + `request.user` are **always synchronized**.
* Can be extended for **Refresh Tokens**.

---

## 3️⃣ Tenant-Scoped Permission Decorators

Classic Django uses **function-based view decorators**.

```python
# tenants/decorators.py
from functools import wraps
from django.core.exceptions import PermissionDenied
from tenants.models import Membership

def tenant_role_required(role_name):
    """
    Ensures the logged-in user has a specific role in the current tenant.
    """
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            tenant = getattr(request, 'tenant', None)
            user = getattr(request, 'user', None)

            if not tenant or not user or not user.is_authenticated:
                raise PermissionDenied("Tenant or user context missing")

            if not Membership.objects.filter(user=user, tenant=tenant, role__name=role_name, is_active=True).exists():
                raise PermissionDenied("User lacks required role")
            
            return view_func(request, *args, **kwargs)
        return _wrapped_view
    return decorator
```

### Usage in Views

```python
from django.shortcuts import render
from tenants.decorators import tenant_role_required

@tenant_role_required("Admin")
def dashboard(request):
    return render(request, "dashboard.html")
```

**Explanation:**

* Protects **views** on a per-tenant basis.
* Works with **classic Django sessions or JWT-based auth**.

---

## 4️⃣ User Membership & Role Model

```python
# tenants/models.py
from django.db import models
from django.conf import settings

class Tenant(models.Model):
    name = models.CharField(max_length=255)
    subdomain = models.CharField(max_length=50, unique=True)
    is_active = models.BooleanField(default=True)

class Role(models.Model):
    name = models.CharField(max_length=50)

class Membership(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    role = models.ForeignKey(Role, on_delete=models.CASCADE)
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ("user", "tenant")
```

* Each **user can belong to multiple tenants**.
* Each membership has a **role** for **tenant-scoped authorization**.

---

## 5️⃣ Admin Integration

* Use `TabularInline` for Membership in Tenant admin.
* Admin can **assign roles to users per tenant**.

```python
from django.contrib import admin
from tenants.models import Tenant, Membership, Role

class MembershipInline(admin.TabularInline):
    model = Membership
    extra = 1

@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    inlines = [MembershipInline]

admin.site.register(Role)
```

---

## ✅ Summary

This setup enables:

1. **Tenant-aware requests** → `request.tenant`.
2. **JWT authentication or session support** → `request.user`.
3. **Tenant-scoped roles and decorators** → clean access control.
4. **Multi-tenant SaaS readiness** → users belong to multiple tenants, roles per tenant.
5. **Zero-trust philosophy** → every request validates **identity + tenant + role**.

---

Next steps for production:

* Add **multi-factor authentication (MFA)** per tenant.
* Implement **JWT refresh token rotation**.
* Extend **audit logging per tenant**.
* Harden middleware and decorators for **rate limiting and brute-force protection**.
* Visual architecture diagram: Tenant → User → Membership → Role → Request context.

---




---


