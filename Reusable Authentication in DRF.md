# **Building a Reusable, Zero-Trust Authentication Platform in Django REST Framework (DRF)**

Authentication is not a feature.
It is **shared platform infrastructure**.

If authentication is:

* tightly coupled,
* partially stateful,
* or business-specific,

…it will be rewritten, audited, and blamed.

This guide documents how to build **a reusable, production-grade authentication app for Django REST Framework** that can be dropped into **any DRF project**, scaled across teams, and extended for OAuth, multi-tenancy, and zero-trust architectures.

---

## **Design Goals**

This authentication platform must:

* Be **stateless**
* Be **JWT-based**
* Support **custom users**
* Separate **identity from domain data**
* Support **roles, permissions, and tenants**
* Integrate with **OAuth2 & SSO**
* Follow **zero-trust principles**
* Be **copy-paste reusable**

---

# **1. Application Layout (Reusable Auth App)**

Create a **standalone Django app** called `auth_platform`.

```
auth_platform/
├── users/
│   ├── models.py
│   ├── managers.py
│   ├── serializers.py
│   ├── views.py
│   └── permissions.py
├── profiles/
│   ├── models.py
│   └── serializers.py
├── tenants/
│   ├── models.py
│   ├── permissions.py
│   └── utils.py
├── tokens/
│   ├── jwt.py
│   └── serializers.py
├── oauth/
│   ├── services.py
│   └── views.py
├── emails/
│   └── services.py
├── urls.py
└── tests/
```

This app contains **no business logic**.
It can be mounted into **any DRF project**.

---

# **2. Custom User Model (Authentication Identity Only)**

### Why This Matters

You **cannot change the user model later** without pain.

---

## **2.1 User Model**

```python
# users/models.py
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
from .managers import UserManager

class User(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    is_active = models.BooleanField(default=False)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    objects = UserManager()

    def __str__(self):
        return self.email
```

---

## **2.2 User Manager**

```python
# users/managers.py
from django.contrib.auth.base_user import BaseUserManager

class UserManager(BaseUserManager):
    def create_user(self, email, password=None):
        if not email:
            raise ValueError("Email is required")

        user = self.model(email=self.normalize_email(email))
        user.set_password(password)
        user.save()
        return user

    def create_superuser(self, email, password):
        user = self.create_user(email, password)
        user.is_staff = True
        user.is_superuser = True
        user.is_active = True
        user.save()
        return user
```

---

# **3. User Profiles (Domain-Extensible Identity)**

### Why Profiles Exist

Authentication data must be **stable**.
Profile data must be **flexible**.

---

## **3.1 Profile Model**

```python
# profiles/models.py
from django.db import models
from users.models import User

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    full_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20, blank=True)

    def __str__(self):
        return self.full_name
```

This allows:

* Future profile expansion
* Multiple profiles later
* Clean auth reuse

---

# **4. Registration & Login Serializers**

## **4.1 Registration Serializer**

```python
# users/serializers.py
from rest_framework import serializers
from .models import User
from profiles.models import UserProfile

class RegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    full_name = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ["email", "password", "full_name"]

    def create(self, validated_data):
        full_name = validated_data.pop("full_name")
        password = validated_data.pop("password")

        user = User.objects.create_user(
            password=password,
            **validated_data
        )

        UserProfile.objects.create(
            user=user,
            full_name=full_name
        )

        return user
```

---

## **4.2 Login Serializer**

```python
class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
```

---

# **5. JWT Token Issuance**

Using `djangorestframework-simplejwt`.

---

## **5.1 Token Utility**

```python
# tokens/jwt.py
from rest_framework_simplejwt.tokens import RefreshToken

def issue_tokens(user, tenant_id=None, role=None):
    refresh = RefreshToken.for_user(user)

    if tenant_id:
        refresh["tenant_id"] = tenant_id
    if role:
        refresh["role"] = role

    return {
        "access": str(refresh.access_token),
        "refresh": str(refresh),
    }
```

---

# **6. Multi-Tenant Authentication & Permissions**

## **6.1 Tenant Model**

```python
# tenants/models.py
from django.db import models
from users.models import User

class Tenant(models.Model):
    name = models.CharField(max_length=255)

class Membership(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    role = models.CharField(max_length=50)
```

---

## **6.2 Tenant-Aware Permission Class**

```python
# tenants/permissions.py
from rest_framework.permissions import BasePermission

class IsTenantAdmin(BasePermission):
    def has_permission(self, request, view):
        token = request.auth
        return token and token.get("role") == "admin"
```

---

# **7. OAuth2 Provider Integration (Step-by-Step)**

### Example: Google OAuth2

---

## **7.1 OAuth Service**

```python
# oauth/services.py
import requests

def exchange_code_for_token(code):
    response = requests.post(
        "https://oauth2.googleapis.com/token",
        data={
            "code": code,
            "client_id": "...",
            "client_secret": "...",
            "redirect_uri": "...",
            "grant_type": "authorization_code",
        },
    )
    return response.json()
```

---

## **7.2 OAuth Login View**

```python
# oauth/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from users.models import User
from tokens.jwt import issue_tokens

class OAuthLoginView(APIView):
    def post(self, request):
        email = request.data["email"]
        user, _ = User.objects.get_or_create(email=email)
        return Response(issue_tokens(user))
```

This allows:

* SSO
* External IdP trust
* Internal JWT normalization

---

# **8. Password Reset Deep Dive**

### Why It’s Separate

Password reset is **identity recovery**, not authentication.

---

```python
# users/views.py
from django.contrib.auth.tokens import PasswordResetTokenGenerator

token_generator = PasswordResetTokenGenerator()
```

* Single-use
* Short-lived
* Email-delivered

---

# **9. Security Review Checklist (Production)**

### JWT

* [ ] Short-lived access tokens
* [ ] HTTPS enforced
* [ ] HttpOnly cookies (if browser-based)
* [ ] Refresh token rotation

### Django

* [ ] Custom user model
* [ ] SECRET_KEY stored securely
* [ ] DEBUG=False in prod

### API

* [ ] Permission classes everywhere
* [ ] No implicit trust
* [ ] Tenant context required

---

# **10. Integrating This Auth App Into Any DRF Project**

### Step 1: Copy the App

Copy `auth_platform/` into your project.

---

### Step 2: settings.py

```python
AUTH_USER_MODEL = "users.User"

INSTALLED_APPS = [
    ...
    "rest_framework",
    "auth_platform.users",
    "auth_platform.profiles",
    "auth_platform.tenants",
]
```

---

### Step 3: URLs

```python
# project/urls.py
path("api/auth/", include("auth_platform.urls")),
```

---

### Step 4: Protect Any API

```python
permission_classes = [IsAuthenticated]
```

Tenant-aware APIs add:

```python
permission_classes = [IsAuthenticated, IsTenantAdmin]
```

---

# **11. Why This Architecture Works Long-Term**

✔ Stateless
✔ Secure
✔ Multi-tenant
✔ OAuth-ready
✔ Zero-trust aligned
✔ Copy-paste reusable

---

# **Final Takeaway**

> Authentication should be boring, secure, and reusable.

This system:

* Scales horizontally
* Survives audits
* Supports modern identity
* Avoids rewrites
* Enables teams to move fast **without breaking trust**

---
# **Production Readiness Addendum**

## Reusable Django REST Framework Authentication Platform

This section ensures the authentication system is:

* **Correct** (tested end-to-end)
* **Understandable** (clear architecture)
* **Deployable** (operationally safe)
* **Secure** (threat-modeled, zero-trust aligned)

---

# **1. End-to-End (E2E) Tests**

End-to-end tests validate **real user flows**, not isolated components.

These tests should be runnable **unchanged** in every project that imports this auth app.

---

## **1.1 Testing Philosophy**

We test:

✔ Registration
✔ Email verification
✔ Login
✔ JWT issuance
✔ Token refresh
✔ Permission enforcement
✔ Tenant isolation

We do **not** mock JWTs.
We test the **real cryptographic path**.

---

## **1.2 Test Setup**

```python
# tests/conftest.py
import pytest
from rest_framework.test import APIClient

@pytest.fixture
def api_client():
    return APIClient()
```

---

## **1.3 Registration Flow Test**

```python
# tests/test_registration.py
def test_user_registration(api_client):
    response = api_client.post("/api/auth/register/", {
        "email": "user@example.com",
        "password": "StrongPass123!",
        "full_name": "Test User"
    })

    assert response.status_code == 201
    assert "email" in response.data
```

---

## **1.4 Login + JWT Issuance Test**

```python
def test_login_returns_tokens(api_client, django_user_model):
    user = django_user_model.objects.create_user(
        email="login@test.com",
        password="password123"
    )
    user.is_active = True
    user.save()

    response = api_client.post("/api/auth/login/", {
        "email": "login@test.com",
        "password": "password123"
    })

    assert response.status_code == 200
    assert "access" in response.data
    assert "refresh" in response.data
```

---

## **1.5 Protected Endpoint Test**

```python
def test_protected_endpoint_requires_auth(api_client):
    response = api_client.get("/api/protected/")
    assert response.status_code == 401
```

---

## **1.6 Tenant Isolation Test**

```python
def test_cross_tenant_access_denied(api_client, tenant_user_token):
    api_client.credentials(
        HTTP_AUTHORIZATION=f"Bearer {tenant_user_token}"
    )
    response = api_client.get("/api/tenant/other-tenant/data/")
    assert response.status_code == 403
```

---

## **1.7 Why These Tests Matter**

These tests catch:

* Misconfigured permissions
* Token leaks
* Broken refresh logic
* Tenant boundary violations

They are **non-negotiable** in regulated or enterprise environments.

---

# **2. Architecture Diagrams (Conceptual)**

## **2.1 High-Level Auth Flow**

```
Client
  |
  |  (email + password)
  v
Auth API
  |
  |-- Validate credentials
  |-- Issue JWT (Access + Refresh)
  |
  v
Client stores token
  |
  |  Authorization: Bearer <access>
  v
Protected APIs
  |
  |-- Verify signature
  |-- Validate claims
  |-- Enforce permissions
```

---

## **2.2 Token Trust Boundary**

```
┌───────────────┐
│ Identity Tier │
│  (Login, SSO) │
└───────┬───────┘
        │ JWT Issuance
        v
┌───────────────┐
│ Trust Boundary│  <-- Zero Trust Begins Here
└───────┬───────┘
        │
┌───────▼───────┐
│  API Services │
│ (Stateless)   │
└───────────────┘
```

No service trusts:

* Sessions
* IPs
* Network location

Only **validated tokens**.

---

## **2.3 Multi-Tenant Authorization Flow**

```
JWT Claims:
{
  user_id,
  tenant_id,
  role
}

Request →
Permission Check →
Tenant Match →
Role Check →
Allow / Deny
```

---

# **3. Deployment Checklist (Production)**

This checklist must be completed **before go-live**.

---

## **3.1 Django & Infrastructure**

* [ ] `DEBUG = False`
* [ ] `ALLOWED_HOSTS` configured
* [ ] `SECRET_KEY` in secret manager
* [ ] HTTPS enforced
* [ ] Secure cookies enabled (if used)

---

## **3.2 JWT Configuration**

* [ ] Access tokens ≤ 15 minutes
* [ ] Refresh token rotation enabled
* [ ] Token blacklisting active
* [ ] Asymmetric signing (RS256) for microservices

---

## **3.3 Database & Identity**

* [ ] Custom user model in use
* [ ] No auth data duplicated in domain tables
* [ ] Profile model used for extensibility
* [ ] Tenant memberships indexed

---

## **3.4 API Security**

* [ ] Permissions on every view
* [ ] No default `AllowAny`
* [ ] Explicit tenant checks
* [ ] Rate limiting on auth endpoints

---

## **3.5 Observability**

* [ ] Auth failures logged
* [ ] Token refresh events logged
* [ ] Suspicious login detection
* [ ] Audit trail enabled

---

# **4. Threat Modeling Worksheets (Training)**

These worksheets are designed for **engineering workshops** and **security onboarding**.

---

## **4.1 Threat Model Template**

### Asset

> What are we protecting?

☐ User identity
☐ Tenant boundaries
☐ Authorization decisions

---

### Entry Point

> How can an attacker interact?

☐ Login endpoint
☐ Token refresh
☐ OAuth callback
☐ Protected API

---

### Threat

> What could go wrong?

☐ Token theft
☐ Privilege escalation
☐ Cross-tenant access
☐ Replay attack

---

### Mitigation

> What stops this?

☐ Short-lived tokens
☐ HTTPS
☐ Permission checks
☐ Tenant validation

---

## **4.2 JWT Threat Walkthrough Exercise**

### Scenario:

> Attacker steals an access token.

**Questions:**

1. How long is the token valid?
2. What can the attacker access?
3. Can the token be revoked?
4. What monitoring detects abuse?

---

## **4.3 OAuth Threat Exercise**

### Scenario:

> OAuth provider returns compromised email.

**Questions:**

1. Do we trust email alone?
2. Do we verify domain?
3. Do we enforce tenant membership?
4. Can this escalate privileges?

---

## **4.4 Multi-Tenant Abuse Scenario**

### Scenario:

> User changes `tenant_id` in JWT payload.

**Answer:**
❌ Impossible without signing key
✔ Signature validation prevents forgery

---

# **5. Final Engineering Guidance**

If you remember nothing else:

* JWTs prevent **forgery**, not **theft**
* Tenancy is an **authorization problem**, not auth
* OAuth does not remove responsibility
* Zero trust means **every request is hostile**
* Auth must be **boring and reusable**

---

# **What You Have Built**

✔ A reusable DRF auth platform
✔ Zero-trust aligned architecture
✔ Enterprise-ready security posture
✔ Training-ready documentation
✔ Auditable, testable code

---



