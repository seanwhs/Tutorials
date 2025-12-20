# **Building a Reusable, Zero‑Trust Authentication Platform in Django**

> A complete, security‑first authentication system for Django that supports **custom users, profiles, roles, permissions, tenants, audit logs, and reuse across projects**.

---

## 0. What This Tutorial Is (and Is Not)

### This tutorial **IS**

✅ Full working Django authentication platform
✅ Copy‑pasteable code
✅ Multi‑tenant, role‑aware, zero‑trust
✅ Production‑ready architecture
✅ Reusable across Django projects

### This tutorial **IS NOT**

❌ A quick “login form” walkthrough
❌ DRF‑specific
❌ Admin‑only authentication
❌ Minimal or toy example

---

## 1. Project Structure (IMPORTANT)

This structure is **deliberate**. Do not flatten it.

```
auth_platform/
├── manage.py
├── config/
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── accounts/
│   ├── apps.py
│   ├── admin.py
│   ├── urls.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── profile.py
│   │   ├── tenant.py
│   │   ├── membership.py
│   │   └── audit.py
│   ├── services/
│   │   ├── auth.py
│   │   └── permissions.py
│   ├── middleware/
│   │   └── tenant.py
│   ├── views/
│   │   ├── auth.py
│   │   └── dashboard.py
│   └── templates/
```

---

## 2. Zero‑Trust Design Principles (Why This Looks “Heavy”)

We assume:

* Cookies can be stolen
* Sessions can be replayed
* Users can belong to multiple organizations
* Permissions change over time
* Breaches will happen

Therefore:

> **Every request must prove who it is, where it belongs, and what it can do.**

---

## 3. Custom User Model (Identity Layer)

### Why We MUST Use a Custom User

If you use Django’s default `User`, you:

* Lock yourself into username auth
* Mix identity with business metadata
* Break reuse across projects

---

### 3.1 User Model

```python
# accounts/models/user.py
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
from .managers import UserManager

class User(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    email_verified = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    objects = UserManager()

    def __str__(self):
        return self.email
```

---

### 3.2 User Manager

```python
# accounts/models/managers.py
from django.contrib.auth.base_user import BaseUserManager

class UserManager(BaseUserManager):
    def create_user(self, email, password=None):
        if not email:
            raise ValueError("Email is required")

        user = self.model(email=self.normalize_email(email))
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password):
        user = self.create_user(email, password)
        user.is_staff = True
        user.is_superuser = True
        user.email_verified = True
        user.save()
        return user
```

---

## 4. User Profile (Why We Do NOT Stuff Everything into User)

### Design Rule

**User = identity**
**Profile = human/business metadata**

---

### 4.1 Profile Model

```python
# accounts/models/profile.py
from django.db import models
from .user import User

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    full_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20, blank=True)

    def __str__(self):
        return self.full_name
```

---

### 4.2 Auto‑Create Profile

```python
# accounts/apps.py
from django.apps import AppConfig

class AccountsConfig(AppConfig):
    name = "accounts"

    def ready(self):
        from django.db.models.signals import post_save
        from .models.user import User
        from .models.profile import UserProfile

        def create_profile(sender, instance, created, **kwargs):
            if created:
                UserProfile.objects.create(user=instance)

        post_save.connect(create_profile, sender=User)
```

---

## 5. Multi‑Tenant Core Models

### 5.1 Tenant

```python
# accounts/models/tenant.py
from django.db import models

class Tenant(models.Model):
    name = models.CharField(max_length=255)
    slug = models.SlugField(unique=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name
```

---

### 5.2 Membership (User ↔ Tenant)

```python
# accounts/models/membership.py
from django.db import models
from .user import User
from .tenant import Tenant

class Membership(models.Model):
    ROLE_CHOICES = (
        ("owner", "Owner"),
        ("admin", "Admin"),
        ("manager", "Manager"),
        ("user", "User"),
        ("viewer", "Viewer"),
    )

    user = models.ForeignKey(User, on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ("user", "tenant")
```

---

## 6. Role‑Based Permission System (FULL)

### 6.1 Permission Map

```python
# accounts/services/permissions.py
ROLE_PERMISSIONS = {
    "owner": {
        "tenant:create",
        "tenant:delete",
        "user:invite",
        "user:remove",
        "billing:manage",
    },
    "admin": {
        "user:invite",
        "user:remove",
        "report:view",
    },
    "manager": {
        "report:view",
        "data:edit",
    },
    "user": {
        "data:view",
    },
    "viewer": {
        "data:view",
    },
}
```

---

### 6.2 Permission Checker

```python
def has_permission(user, tenant, permission):
    membership = (
        Membership.objects
        .filter(user=user, tenant=tenant, is_active=True)
        .first()
    )

    if not membership:
        return False

    return permission in ROLE_PERMISSIONS.get(membership.role, set())
```

---

### 6.3 Permission Decorator

```python
from django.http import HttpResponseForbidden

def require_permission(permission):
    def decorator(view_func):
        def wrapper(request, *args, **kwargs):
            tenant = getattr(request, "tenant", None)
            if not tenant:
                return HttpResponseForbidden("No tenant context")

            if not has_permission(request.user, tenant, permission):
                return HttpResponseForbidden("Permission denied")

            return view_func(request, *args, **kwargs)
        return wrapper
    return decorator
```

---

## 7. Zero‑Trust Tenant Middleware

```python
# accounts/middleware/tenant.py
from accounts.models.membership import Membership

class TenantMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request.tenant = None

        if request.user.is_authenticated:
            membership = Membership.objects.filter(
                user=request.user,
                is_active=True
            ).first()
            if membership:
                request.tenant = membership.tenant

        return self.get_response(request)
```

---

## 8. Authentication Services (Business Logic Layer)

```python
# accounts/services/auth.py
from django.contrib.auth import authenticate, login

def authenticate_user(request, email, password):
    user = authenticate(request, email=email, password=password)
    if not user:
        return None

    if not user.is_active or not user.email_verified:
        return None

    login(request, user)
    return user
```

---

## 9. Login View (Session‑Based)

```python
# accounts/views/auth.py
from django.shortcuts import render, redirect
from accounts.services.auth import authenticate_user

def login_view(request):
    if request.method == "POST":
        user = authenticate_user(
            request,
            request.POST["email"],
            request.POST["password"]
        )
        if user:
            return redirect("dashboard")

    return render(request, "accounts/login.html")
```

---

## 10. Protected View with Role Enforcement

```python
# accounts/views/dashboard.py
from django.shortcuts import render
from accounts.services.permissions import require_permission

@require_permission("data:view")
def dashboard(request):
    return render(request, "accounts/dashboard.html")
```

---

## 11. Audit Logging (Security Requirement)

```python
# accounts/models/audit.py
from django.db import models
from .user import User

class AuditLog(models.Model):
    user = models.ForeignKey(User, null=True, on_delete=models.SET_NULL)
    action = models.CharField(max_length=100)
    ip_address = models.GenericIPAddressField()
    timestamp = models.DateTimeField(auto_now_add=True)
```

---

## 12. Password Reset & Email Verification (Conceptual + Code)

Django already provides:

* Secure token generation
* Time‑limited resets
* One‑time usage

You integrate via:

```python
from django.contrib.auth.tokens import PasswordResetTokenGenerator
```

Zero‑trust rule:

> Password reset ≠ identity verification
> Always log the event.

---

## 13. Reusing This Auth Platform Across Projects

### Option A: Internal App

Copy `accounts/` into new project.

### Option B: Private Package

```
pip install company-auth-platform
```

Update settings:

```python
AUTH_USER_MODEL = "accounts.User"
```

---

## 14. Production Security Checklist

✔ HTTPS only
✔ Secure cookies
✔ Session rotation on login
✔ Audit logs immutable
✔ Tenant isolation tests
✔ Permission coverage tests

---

## 15. Final Summary

You now have:

* A **custom identity layer**
* A **profile separation model**
* **Multi‑tenant isolation**
* **Role‑based permissions**
* **Zero‑trust request enforcement**
* A **reusable authentication platform**

This is the **foundation layer** for:

* Enterprise Django apps
* Internal tools
* Hybrid Django + API stacks

---

## 16. 🔐 Red‑Team Security Test Cases (Attack Thinking)

These are **intentional adversarial test cases**.
They should be run manually *and* automated where possible.

---

### 16.1 Authentication Attacks

| Attack               | Goal                   | Expected Defense           |
| -------------------- | ---------------------- | -------------------------- |
| Credential stuffing  | Reuse leaked passwords | Rate limiting, lockout     |
| Brute force login    | Guess passwords        | Throttling + audit logs    |
| User enumeration     | Detect valid emails    | Uniform error messages     |
| Session fixation     | Reuse session ID       | Session rotation           |
| Password reset abuse | Reset others’ accounts | Token expiration + logging |

---

### Example Test: Login Enumeration

❌ **Vulnerable**

```text
"User not found"
"Incorrect password"
```

✅ **Hardened**

```text
"Invalid credentials"
```

---

### 16.2 Tenant Boundary Attacks

| Attack              | Goal                       |
| ------------------- | -------------------------- |
| Cross‑tenant access | View another tenant’s data |
| Role escalation     | Viewer → Admin             |
| Membership spoofing | Fake tenant context        |

---

### Red‑Team Exercise

> Attempt to manually modify:

* URL parameters
* hidden form fields
* cookies
* session keys

**Expected Result:**
Every request must re‑validate:

* user
* tenant
* role
* permission

---

## 17. 🧪 Pytest Permission & Isolation Test Suite

### 17.1 Why Permission Tests Matter

Permissions are **business logic**, not configuration.

If you don’t test them:

* privilege escalation goes unnoticed
* tenants bleed into each other
* auditors fail you

---

### 17.2 Test Setup

```python
# tests/conftest.py
import pytest
from accounts.models import User, Tenant, Membership

@pytest.fixture
def tenant():
    return Tenant.objects.create(name="Acme", slug="acme")

@pytest.fixture
def user():
    return User.objects.create_user(
        email="user@test.com",
        password="pass1234"
    )
```

---

### 17.3 Role Permission Tests

```python
# tests/test_permissions.py
from accounts.services.permissions import has_permission

def test_owner_can_invite_users(user, tenant):
    Membership.objects.create(
        user=user,
        tenant=tenant,
        role="owner"
    )

    assert has_permission(
        user,
        tenant,
        "user:invite"
    )

def test_viewer_cannot_invite_users(user, tenant):
    Membership.objects.create(
        user=user,
        tenant=tenant,
        role="viewer"
    )

    assert not has_permission(
        user,
        tenant,
        "user:invite"
    )
```

---

### 17.4 Tenant Isolation Test

```python
def test_user_cannot_access_other_tenant(user):
    t1 = Tenant.objects.create(name="A", slug="a")
    t2 = Tenant.objects.create(name="B", slug="b")

    Membership.objects.create(user=user, tenant=t1, role="user")

    assert not has_permission(
        user,
        t2,
        "data:view"
    )
```

---

## 18. 🧱 Hardened Docker + Nginx Setup

This is a **production‑grade baseline**, not a demo.

---

### 18.1 Dockerfile (Hardened)

```dockerfile
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN addgroup --system app && adduser --system --group app

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

USER app

CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]
```

---

### 18.2 Nginx Zero‑Trust Config

```nginx
server {
    listen 443 ssl;
    server_name example.com;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    location / {
        proxy_pass http://django:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

---

### 18.3 Django Security Settings

```python
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
CSRF_COOKIE_HTTPONLY = True
SECURE_HSTS_SECONDS = 31536000
```

---

## 19. 🧠 Threat‑Modeling Worksheets (Training‑Ready)

These worksheets are designed for:

* security reviews
* associate training
* tabletop exercises

---

### 19.1 System Decomposition

| Component      | Trust Level  |
| -------------- | ------------ |
| Browser        | Untrusted    |
| Session Cookie | Semi‑trusted |
| Django App     | Trusted      |
| Database       | Trusted      |
| Admin User     | Dangerous    |

---

### 19.2 STRIDE Threat Matrix

| Threat          | Example        | Mitigation         |
| --------------- | -------------- | ------------------ |
| Spoofing        | Fake login     | MFA, throttling    |
| Tampering       | Modify role    | Server‑side checks |
| Repudiation     | Deny actions   | Audit logs         |
| Info Disclosure | Email leaks    | Access control     |
| DoS             | Login spam     | Rate limits        |
| Elevation       | Viewer → Admin | Permission tests   |

---

### 19.3 Attack Tree (Exercise)

**Goal:** Access another tenant’s data

```
 ├── Modify URL
 ├── Replay session
 ├── Guess tenant ID
 ├── Abuse admin endpoint
```

**Question for learners:**

> Where does our design block each path?

---

## 20. Security Review Checklist (Final Gate)

Before production:

* [ ] Custom user model enforced
* [ ] Profile separated from identity
* [ ] Tenant context middleware enabled
* [ ] Permission decorator everywhere
* [ ] Audit logging immutable
* [ ] Rate limiting enabled
* [ ] Tests passing
* [ ] HTTPS only
* [ ] Secrets externalized

---

## 21. Final Outcome

You now have:

✅ A reusable Django authentication platform
✅ Role‑based, tenant‑aware authorization
✅ Zero‑trust enforcement per request
✅ Red‑team attack scenarios
✅ Automated permission tests
✅ Hardened container + reverse proxy
✅ Threat‑modeling material for training

This is **enterprise‑grade Django security engineering**, not just authentication.

---

# 🔐 MFA & WebAuthn Integration

## Zero-Trust, Phishing-Resistant Authentication in Django

This section extends the existing **Zero-Trust Django Authentication Platform** with **Multi-Factor Authentication (MFA)** and **WebAuthn (Passkeys / Security Keys)**.

> Goal:
> Prevent account takeover **even if passwords and JWT/session cookies are stolen**.

---

## 1. Why MFA & WebAuthn Matter (Threat Perspective)

### Threats MFA/WebAuthn Defend Against

| Threat              | Password | MFA | WebAuthn |
| ------------------- | -------- | --- | -------- |
| Credential stuffing | ❌        | ⚠️  | ✅        |
| Phishing            | ❌        | ⚠️  | ✅        |
| Token replay        | ❌        | ❌   | ✅        |
| Keylogging          | ❌        | ❌   | ✅        |
| MITM                | ❌        | ⚠️  | ✅        |

**Key takeaway:**

> WebAuthn is the **only authentication mechanism that is phishing-resistant by design**.

---

## 2. MFA Strategy (Pragmatic & Incremental)

We implement MFA in **layers**, not all at once:

1. **Primary authentication**

   * Email + password
2. **Secondary factor**

   * TOTP (Authenticator apps)
3. **Strong factor**

   * WebAuthn (Passkeys, YubiKey, TouchID)
4. **Fallback**

   * Recovery codes

---

## 3. Data Model Extensions

### 3.1 MFA Configuration Model

```python
# accounts/models/mfa.py
from django.db import models
from django.conf import settings

class MFASettings(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE
    )

    mfa_enabled = models.BooleanField(default=False)
    totp_enabled = models.BooleanField(default=False)
    webauthn_enabled = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
```

---

### 3.2 TOTP Device Model

```python
class TOTPDevice(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    secret = models.CharField(max_length=64)
    confirmed = models.BooleanField(default=False)
```

---

### 3.3 WebAuthn Credential Model

```python
class WebAuthnCredential(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

    credential_id = models.BinaryField(unique=True)
    public_key = models.BinaryField()

    sign_count = models.IntegerField(default=0)
    device_name = models.CharField(max_length=255)

    created_at = models.DateTimeField(auto_now_add=True)
```

---

## 4. Login Flow with MFA (Zero-Trust)

### Step-by-Step Authentication

```
Username + Password
        ↓
Password Valid?
        ↓
MFA Enabled?
 ├── No → Login success
 └── Yes
      ↓
 MFA Challenge Required
      ↓
 ├── TOTP
 ├── WebAuthn
 └── Recovery Code
```

---

## 5. TOTP (Authenticator App) Integration

### 5.1 Generate TOTP Secret

```python
import pyotp

def generate_totp_secret():
    return pyotp.random_base32()
```

---

### 5.2 Confirm TOTP Setup

```python
def confirm_totp(device, token):
    totp = pyotp.TOTP(device.secret)
    return totp.verify(token)
```

---

### 5.3 Validate During Login

```python
def verify_totp(user, token):
    device = TOTPDevice.objects.get(user=user, confirmed=True)
    totp = pyotp.TOTP(device.secret)
    return totp.verify(token)
```

---

## 6. WebAuthn (Passkeys / Security Keys)

### 6.1 Why WebAuthn Is Special

WebAuthn:

* binds authentication to **origin**
* uses **public-key cryptography**
* never transmits secrets
* defeats phishing **by design**

---

## 6.2 Libraries

```bash
pip install webauthn
```

---

## 6.3 Registration (Credential Creation)

### Start Registration

```python
from webauthn import generate_registration_options

def start_webauthn_registration(user):
    return generate_registration_options(
        rp_id="example.com",
        rp_name="Example App",
        user_id=str(user.id).encode(),
        user_name=user.email,
    )
```

---

### Finish Registration

```python
from webauthn import verify_registration_response

def finish_webauthn_registration(user, credential, challenge):
    verification = verify_registration_response(
        credential=credential,
        expected_challenge=challenge,
        expected_origin="https://example.com",
        expected_rp_id="example.com",
    )

    WebAuthnCredential.objects.create(
        user=user,
        credential_id=verification.credential_id,
        public_key=verification.credential_public_key,
        sign_count=verification.sign_count,
        device_name="Security Key"
    )
```

---

## 7. WebAuthn Authentication

### 7.1 Start Authentication

```python
from webauthn import generate_authentication_options

def start_webauthn_auth(user):
    credentials = WebAuthnCredential.objects.filter(user=user)

    return generate_authentication_options(
        rp_id="example.com",
        allow_credentials=[
            {
                "id": c.credential_id,
                "type": "public-key"
            } for c in credentials
        ],
    )
```

---

### 7.2 Finish Authentication

```python
from webauthn import verify_authentication_response

def finish_webauthn_auth(user, credential, challenge):
    db_cred = WebAuthnCredential.objects.get(
        credential_id=credential["id"]
    )

    verification = verify_authentication_response(
        credential=credential,
        expected_challenge=challenge,
        expected_origin="https://example.com",
        expected_rp_id="example.com",
        credential_public_key=db_cred.public_key,
        credential_current_sign_count=db_cred.sign_count,
    )

    db_cred.sign_count = verification.new_sign_count
    db_cred.save()
```

---

## 8. Recovery Codes (Last Resort)

```python
class RecoveryCode(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    code_hash = models.CharField(max_length=128)
    used = models.BooleanField(default=False)
```

**Rules:**

* single-use
* hashed at rest
* regenerate on MFA reset

---

## 9. Security Controls (Critical)

### Enforced Policies

| Control                            | Reason               |
| ---------------------------------- | -------------------- |
| MFA required for admins            | Privilege protection |
| WebAuthn preferred                 | Phishing resistance  |
| Step-up auth for sensitive actions | Zero-trust           |
| Re-auth on role change             | Session trust reset  |

---

## 10. Red-Team MFA Test Cases

| Attack               | Expected Result   |
| -------------------- | ----------------- |
| Phishing password    | Blocked           |
| Replay WebAuthn      | Blocked           |
| Brute force TOTP     | Rate limited      |
| Steal session cookie | Step-up required  |
| Disable MFA via API  | Permission denied |

---

## 11. Production Checklist (MFA)

* [ ] HTTPS enforced
* [ ] WebAuthn origin locked
* [ ] MFA challenge timeout
* [ ] Recovery codes stored hashed
* [ ] MFA audit logs enabled
* [ ] MFA required for admins
* [ ] WebAuthn devices manageable

---

## 12. Final Architecture Impact

You now have:

✅ Password authentication
✅ MFA (TOTP)
✅ Phishing-resistant WebAuthn
✅ Zero-trust step-up authentication
✅ Enterprise-grade account protection

This elevates your Django platform from **“secure”** to **“modern identity system”**.

---

# 📱 Mobile WebAuthn, 🧪 Automated MFA Security Testing, 🏛 Compliance Mapping

## Enterprise-Grade Identity for Django (Zero-Trust)

---

# 📱 Part 1 — Mobile WebAuthn (Passkeys on iOS & Android)

## 1. Why Mobile WebAuthn Matters

Mobile devices are now:

* the **primary authentication device**
* hardware-backed (Secure Enclave / StrongBox)
* biometric-enabled (FaceID, TouchID, Fingerprint)

**Passwords + SMS ≠ secure**
**Mobile WebAuthn = phishing-resistant MFA**

---

## 2. Mobile WebAuthn Architecture

```
Mobile Browser / App
        ↓
 WebAuthn API
        ↓
 Device Secure Enclave
        ↓
 Public Key Credential
        ↓
 Django Verification
```

### Key Security Guarantees

* Private key **never leaves device**
* Bound to **domain (origin)**
* Cannot be replayed or phished

---

## 3. WebAuthn Settings for Mobile Compatibility

### Django Settings

```python
WEBAUTHN_RP_ID = "example.com"
WEBAUTHN_ORIGIN = "https://example.com"
WEBAUTHN_TIMEOUT = 60000
```

⚠️ **Critical**

* RP ID must match domain
* HTTPS is mandatory
* Subdomains require careful planning

---

## 4. Frontend (Mobile Browser / WebView)

### WebAuthn Registration (JS)

```javascript
const credential = await navigator.credentials.create({
  publicKey: options
})
```

### Mobile Notes

| Platform       | Notes                  |
| -------------- | ---------------------- |
| iOS Safari     | Passkeys supported     |
| Android Chrome | Passkeys supported     |
| In-App WebView | Requires configuration |
| Native Apps    | Use platform APIs      |

---

## 5. Mobile WebAuthn UX Patterns

### Recommended

* WebAuthn as **default**
* Password as **fallback**
* Recovery codes last

### Anti-Patterns

❌ Forcing SMS OTP
❌ Allowing password-only for admins
❌ No recovery flow

---

## 6. Mobile Threat Scenarios

| Attack        | Outcome               |
| ------------- | --------------------- |
| Phishing page | WebAuthn blocked      |
| Malware       | Private key protected |
| Token theft   | Step-up required      |
| MITM          | Origin mismatch       |

---

# 🧪 Part 2 — Automated MFA Security Tests (Pytest)

## 7. Why MFA Must Be Tested Like Security Code

Authentication failures are **catastrophic**, not bugs.

We test:

* bypass attempts
* race conditions
* replay attacks
* role escalation

---

## 8. Test Strategy

| Layer       | Purpose             |
| ----------- | ------------------- |
| Unit        | Logic correctness   |
| Integration | Flow validation     |
| Red-team    | Adversarial testing |

---

## 9. Pytest Setup

```bash
pip install pytest pytest-django
```

---

## 10. MFA Enforcement Tests

### Password-Only Login Blocked

```python
def test_password_login_blocked_when_mfa_enabled(client, user):
    user.mfa_settings.mfa_enabled = True
    user.mfa_settings.save()

    response = client.post("/login/", {
        "email": user.email,
        "password": "password"
    })

    assert response.status_code == 403
```

---

### TOTP Validation

```python
def test_totp_required(client, user, totp_device):
    response = client.post("/mfa/verify/", {
        "token": "123456"
    })

    assert response.status_code == 401
```

---

## 11. WebAuthn Replay Attack Test

```python
def test_webauthn_replay_attack(client, webauthn_credential):
    response1 = client.post("/webauthn/auth/finish/", payload)
    response2 = client.post("/webauthn/auth/finish/", payload)

    assert response2.status_code == 403
```

---

## 12. Privilege Escalation Tests

```python
def test_admin_requires_webauthn(client, admin_user):
    admin_user.mfa_settings.webauthn_enabled = False
    admin_user.mfa_settings.save()

    response = client.post("/admin/login/")
    assert response.status_code == 403
```

---

## 13. Red-Team MFA Scenarios (Executable)

| Scenario       | Expected          |
| -------------- | ----------------- |
| Token theft    | Step-up auth      |
| Session replay | Block             |
| Disable MFA    | Permission denied |
| Change email   | Re-auth required  |

---

# 🏛 Part 3 — Compliance Mapping (NIST / SOC2)

This section allows **security teams and auditors** to map your implementation directly to controls.

---

## 14. NIST 800-63 Mapping

| NIST Control          | Implementation    |
| --------------------- | ----------------- |
| AAL2                  | Password + TOTP   |
| AAL3                  | WebAuthn          |
| Replay resistance     | Sign counter      |
| Phishing resistance   | WebAuthn          |
| Authenticator binding | Origin-bound keys |

---

## 15. SOC2 Trust Service Criteria

### CC6 — Logical Access

| Control            | Evidence          |
| ------------------ | ----------------- |
| MFA enforced       | MFASettings model |
| Admin protections  | Role rules        |
| Session protection | Step-up auth      |

---

### CC7 — Change Management

| Control                    | Evidence   |
| -------------------------- | ---------- |
| Permission changes audited | Audit logs |
| Role escalation protected  | Re-auth    |

---

### CC8 — Incident Response

| Control               | Evidence        |
| --------------------- | --------------- |
| Credential revocation | Token blacklist |
| MFA reset workflow    | Recovery codes  |
| Audit logs            | Auth events     |

---

## 16. Evidence Artifacts You Can Produce

* MFA enforcement policy
* WebAuthn configuration
* Audit logs
* Test results
* Threat models

These are **SOC2-ready artifacts**.

---

## 17. Final Security Posture

You now have:

✅ Password authentication
✅ MFA (TOTP)
✅ Mobile WebAuthn / Passkeys
✅ Automated red-team tests
✅ Zero-trust step-up auth
✅ Compliance-mapped identity

This is no longer *just authentication* —
this is an **identity security platform**.

---

# 🧠 Threat Modeling, Reference Architecture & Cloud Integration

*(Enterprise Extension for Zero-Trust Django Authentication)*

This section elevates the authentication platform from **“secure application”** to **“auditable, production-ready security system”** by covering:

* Structured **threat modeling**
* Reference **repo architecture**
* **Cloud IAM & Terraform integration**
* Compliance-ready design thinking

---

## 1️⃣ Threat Modeling with STRIDE (Deep Dive)

Threat modeling is not optional in zero-trust systems. It is the **design-time security discipline** that prevents vulnerabilities *before code is written*.

We will use **STRIDE**, the industry-standard model from Microsoft.

### STRIDE Overview

| Category | Threat                 |
| -------- | ---------------------- |
| **S**    | Spoofing identity      |
| **T**    | Tampering with data    |
| **R**    | Repudiation            |
| **I**    | Information disclosure |
| **D**    | Denial of service      |
| **E**    | Elevation of privilege |

---

## 2️⃣ STRIDE Applied to Our Django Auth Platform

### 🔐 System Components in Scope

* Browser / Mobile Client
* Django Auth Service
* JWT / OAuth tokens
* Database (Users, Profiles, Tenants)
* Email / MFA provider
* Reverse proxy (Nginx)
* Cloud IAM

---

### 🟥 Spoofing Identity

**Threats**

* Stolen JWT used to impersonate a user
* OAuth token replay
* MFA bypass attempts

**Mitigations**

* Short-lived access tokens (5–10 mins)
* Refresh token rotation
* Device binding for MFA
* WebAuthn (hardware-backed credentials)
* HTTPS everywhere

```python
# settings.py
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=10),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
}
```

---

### 🟧 Tampering with Data

**Threats**

* JWT payload modification
* API request manipulation
* Profile escalation attempts

**Mitigations**

* Cryptographic signatures (RS256)
* Server-side permission checks
* Immutable token claims
* HMAC-verified webhooks

---

### 🟨 Repudiation

**Threats**

* User denies performing a sensitive action
* Admin claims no access was granted

**Mitigations**

* Audit logs
* Immutable timestamps
* Actor + IP + device fingerprint

```python
class AuditLog(models.Model):
    actor = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    action = models.CharField(max_length=255)
    ip_address = models.GenericIPAddressField()
    created_at = models.DateTimeField(auto_now_add=True)
```

---

### 🟦 Information Disclosure

**Threats**

* Leaking user emails
* JWT payload exposure
* Stack traces in production

**Mitigations**

* Never store secrets in JWT payloads
* Use opaque IDs
* Secure error handling
* Encrypted fields for PII

---

### 🟪 Denial of Service

**Threats**

* Login brute force
* Refresh token abuse
* Password reset flooding

**Mitigations**

* Rate limiting
* CAPTCHA on auth endpoints
* Progressive lockouts
* Redis-based throttling

```python
REST_FRAMEWORK = {
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.UserRateThrottle"
    ],
    "DEFAULT_THROTTLE_RATES": {
        "user": "100/hour"
    }
}
```

---

### ⬛ Elevation of Privilege

**Threats**

* User modifies role claim
* Tenant boundary escape
* Admin endpoint misuse

**Mitigations**

* Server-side permission enforcement
* Tenant-aware queries
* No trust in client claims

```python
def tenant_queryset(user):
    return Project.objects.filter(tenant=user.profile.tenant)
```

---

## 3️⃣ Threat Modeling Worksheets (Training-Ready)

### Worksheet Example

**Component:** JWT Authentication
**Threat:** Token replay
**STRIDE:** Spoofing
**Likelihood:** Medium
**Impact:** High
**Mitigation:** Short-lived tokens, refresh rotation
**Residual Risk:** Low

📌 These worksheets are ideal for:

* Security reviews
* Developer onboarding
* Compliance audits
* SOC2 evidence

---

## 4️⃣ Full Reference Repository Structure

This structure is designed for **reuse across projects**.

```text
auth_platform/
├── apps/
│   ├── accounts/
│   │   ├── models.py        # CustomUser
│   │   ├── profiles.py      # UserProfile
│   │   ├── permissions.py
│   │   ├── signals.py
│   │   └── admin.py
│   ├── tenants/
│   │   ├── models.py
│   │   └── middleware.py
│   ├── audit/
│   │   └── models.py
│   └── mfa/
│       ├── webauthn.py
│       └── totp.py
├── auth/
│   ├── jwt.py
│   ├── oauth.py
│   └── backends.py
├── tests/
│   ├── test_permissions.py
│   ├── test_mfa.py
│   └── test_tenants.py
├── docker/
│   ├── Dockerfile
│   └── nginx.conf
├── terraform/
│   ├── iam.tf
│   ├── secrets.tf
│   └── variables.tf
└── manage.py
```

This repo can be:

* Installed as a Django app
* Used as a template
* Deployed as a standalone auth service

---

## 5️⃣ Terraform & Cloud IAM Integration

### Goals

* Zero hard-coded secrets
* Identity-based access
* Least privilege by default

---

### Example: AWS IAM Role for Django

```hcl
resource "aws_iam_role" "django_app" {
  name = "django-auth-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
```

---

### Secrets via Parameter Store

```hcl
resource "aws_ssm_parameter" "django_secret_key" {
  name  = "/auth/secret_key"
  type  = "SecureString"
  value = var.secret_key
}
```

```python
# settings.py
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
```

---

## 6️⃣ Zero-Trust Principles Enforced

This platform enforces:

✅ No implicit trust
✅ Every request authenticated
✅ Every action authorized
✅ Tenant boundaries enforced
✅ Continuous verification

---

## 7️⃣ Production Hardening Summary

| Area           | Status                 |
| -------------- | ---------------------- |
| JWT            | Short-lived + rotation |
| MFA            | WebAuthn + TOTP        |
| OAuth          | External IdP           |
| Permissions    | Role + Tenant          |
| Logging        | Immutable audit        |
| Infrastructure | IAM + Terraform        |
| Compliance     | SOC2 / NIST aligned    |

---

## 8️⃣ Final Takeaway

This authentication platform is **not a tutorial toy**.

It is:

* 🏗 **Architected**
* 🔐 **Threat-modeled**
* 🧪 **Tested**
* 📦 **Deployable**
* 🏛 **Compliance-ready**

It can serve as:

* A **shared internal auth service**
* A **reference architecture**
* A **training curriculum**
* A **production foundation**

---

## 📐 Visual Architecture Diagrams (Queued)

### 1️⃣ **High-Level Zero-Trust Architecture**

**Purpose:** Executive + technical overview

**Shows:**

```
Client (Web / Mobile)
        ↓
     Nginx (TLS, Rate Limit)
        ↓
Django Auth Platform
 ├─ Identity & MFA
 ├─ Permissions Engine
 ├─ Tenant Isolation
 ├─ Audit Logs
        ↓
 Database / Cache / IdP
```

Highlights:

* No implicit trust
* Every request authenticated
* Defense-in-depth layers

---

### 2️⃣ **Authentication Lifecycle Diagram**

**Purpose:** Developer understanding

Flow:

```
Login → Credential Validation
      → MFA Challenge
      → JWT Issued
      → Access Token Usage
      → Refresh Token Rotation
      → Logout / Revocation
```

Includes:

* Access vs Refresh token boundaries
* MFA decision points
* Revocation strategy

---

### 3️⃣ **JWT Verification & Zero-Trust Request Flow**

**Purpose:** Security review / training

Shows:

```
API Request
 → JWT Signature Check
 → Token Expiry Check
 → Tenant Context Resolution
 → Role & Permission Evaluation
 → Business Logic
 → Audit Log
```

Overlay:

* What is trusted
* What is re-verified on every request

---

### 4️⃣ **Multi-Tenant Authorization Model**

**Purpose:** Prevent privilege escalation

Diagram:

```
User
 ↓
UserProfile
 ↓
Role
 ↓
Permission Set
 ↓
Tenant Boundary
```

Clearly visualizes:

* Why tenant isolation is enforced server-side
* Why JWT claims are advisory, not authoritative

---

### 5️⃣ **OAuth2 / SSO Integration Flow**

**Purpose:** Enterprise integration

Flow:

```
User → External IdP
     → OAuth Authorization Code
     → Django Token Exchange
     → Internal JWT Issued
```

Shows:

* Where trust is delegated
* Where it is re-asserted internally

---

### 6️⃣ **Threat-Model Overlay (STRIDE)**

**Purpose:** Security training & compliance

Same architecture diagram with:

* 🔴 Spoofing points
* 🟠 Tampering risks
* 🟡 Repudiation controls
* 🔵 Disclosure risks
* 🟣 DoS mitigations
* ⚫ Privilege escalation blocks

---








