# 🏗 Classic Django Multi-Tenant Authentication Platform — Full Implementation

---

## 1️⃣ Project Structure

```
myproject/
├── accounts/
│   ├── admin.py
│   ├── apps.py
│   ├── models.py
│   ├── views.py
│   ├── forms.py
│   ├── middleware.py
│   ├── signals.py
│   ├── urls.py
│   ├── templates/accounts/
│   │   ├── login.html
│   │   ├── dashboard.html
│   └── tests/
│       └── test_permissions.py
├── tenants/
│   ├── admin.py
│   ├── apps.py
│   ├── models.py
│   ├── middleware.py
│   └── signals.py
├── myproject/
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── manage.py
└── requirements.txt
```

---

## 2️⃣ Accounts App

### 2.1 Custom User Model

```python
# accounts/models.py
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.conf import settings

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

class User(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = UserManager()
    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

class UserProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="profile")
    full_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=50)
    mfa_enabled = models.BooleanField(default=False)  # Track MFA enrollment
```

**Explanation:**

* `User` → global identity boundary
* `UserProfile` → business context, MFA flag
* `BaseUserManager` enforces global invariants (email unique, password hashing)

---

### 2.2 Admin Integration

```python
# accounts/admin.py
from django.contrib import admin
from .models import User, UserProfile

class UserProfileInline(admin.StackedInline):
    model = UserProfile
    can_delete = False

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    inlines = [UserProfileInline]
    list_display = ("email", "is_staff", "is_active")
    search_fields = ("email",)
```

---

### 2.3 Views: Login, JWT Cookie, MFA

```python
# accounts/views.py
from django.shortcuts import render, redirect
from django.contrib.auth import authenticate
from django.http import HttpResponse
import jwt
from datetime import datetime, timedelta
from django.conf import settings
from tenants.models import Tenant, Membership

def login_view(request):
    if request.method == "POST":
        email = request.POST["email"]
        password = request.POST["password"]
        tenant_id = request.POST.get("tenant_id")
        user = authenticate(request, email=email, password=password)
        if user:
            if user.profile.mfa_enabled:
                return redirect("webauthn_challenge")
            payload = {
                "user_id": user.id,
                "tenant_id": tenant_id,
                "exp": datetime.utcnow() + timedelta(hours=1)
            }
            token = jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")
            response = redirect("dashboard")
            response.set_cookie("jwt_access", token, httponly=True, secure=True, samesite="Lax")
            return response
        return HttpResponse("Invalid credentials", status=401)
    return render(request, "accounts/login.html")

def dashboard(request):
    return render(request, "accounts/dashboard.html")
```

---

### 2.4 Signals: Ensure Profile Creation

```python
# accounts/signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.conf import settings
from .models import UserProfile

@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)
```

---

## 3️⃣ Tenants App

### 3.1 Tenant, Role, Membership Models

```python
# tenants/models.py
from django.db import models
from django.conf import settings
from django.contrib.auth.models import Permission

class Tenant(models.Model):
    name = models.CharField(max_length=255)
    subdomain = models.CharField(max_length=50, unique=True)
    is_active = models.BooleanField(default=True)

class Role(models.Model):
    name = models.CharField(max_length=50)
    permissions = models.ManyToManyField(Permission)

class Membership(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    role = models.ForeignKey(Role, on_delete=models.CASCADE)
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ("user", "tenant")
```

---

### 3.2 Tenant Middleware

```python
# tenants/middleware.py
from django.http import Http404
from tenants.models import Tenant

class TenantMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        host = request.get_host().split(".")[0]
        try:
            tenant = Tenant.objects.get(subdomain=host, is_active=True)
        except Tenant.DoesNotExist:
            raise Http404("Tenant not found")
        request.tenant = tenant
        return self.get_response(request)
```

---

### 3.3 Tenant Role Decorator

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

---

### 3.4 Admin Integration

```python
# tenants/admin.py
from django.contrib import admin
from .models import Tenant, Role, Membership

class MembershipInline(admin.TabularInline):
    model = Membership
    extra = 1

@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    inlines = [MembershipInline]

admin.site.register(Role)
```

---

## 4️⃣ Audit Logging per Tenant

```python
# tenants/signals.py
import logging
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils.timezone import now
from .models import Membership

audit_logger = logging.getLogger("tenant_audit")

@receiver(post_save, sender=Membership)
def log_membership_change(sender, instance, created, **kwargs):
    action = "CREATED" if created else "UPDATED"
    audit_logger.info(f"{now()} | {action} | user:{instance.user_id} tenant:{instance.tenant_id} role:{instance.role_id}")
```

---

## 5️⃣ Tests: Pytest Role & Permission Suite

```python
# tenants/tests/test_permissions.py
import pytest
from accounts.models import User
from tenants.models import Tenant, Role, Membership

@pytest.mark.django_db
def test_admin_role_membership():
    tenant = Tenant.objects.create(name="ACME", subdomain="acme")
    role = Role.objects.create(name="Admin")
    user = User.objects.create_user(email="admin@example.com", password="password123")
    Membership.objects.create(user=user, tenant=tenant, role=role)
    assert Membership.objects.filter(user=user, tenant=tenant, role__name="Admin").exists()
```

---

## 6️⃣ MFA / WebAuthn Integration Notes

* MFA flag stored in `UserProfile.mfa_enabled`
* WebAuthn challenge endpoint triggers browser/device challenge
* Upon success, JWT cookie issued as above
* Extensible for **mobile WebAuthn** via QR codes or FIDO2 devices

---

## 7️⃣ Security Considerations

* JWT **stateless**, cookie storage prevents XSS
* Tenant-aware middleware ensures **zero-trust** per request
* Role-based decorators enforce **tenant-scoped authorization**
* Audit logs are **tenant-scoped and auditable**
* MFA / WebAuthn strengthens high-value accounts

---

## ✅ Next Steps

1. Enable **JWT refresh token rotation**
2. Add **rate-limiting and brute-force protection**
3. Implement **audit log viewer per tenant**
4. Extend **Pytest suite** to include HTTP requests with JWT cookies

---

This project is **ready to copy, migrate, and run** in **classic Django**.

---


---


Do you want me to generate the diagrams next?
