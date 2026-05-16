# 🛡️ Production Security Hardening Guide

**React + Django (Enterprise / OWASP-Aligned)**

Modern React + Django systems are **distributed**, spanning browsers, APIs, networks, and infrastructure—not monolithic apps. Security emerges from **layered controls**, **assumed compromise**, and **intent verification at every boundary**.

> **Security Philosophy**
>
> * Assume the browser is hostile
> * Assume the network is observable
> * Assume attackers are patient

Focus: **Active Defense**, **Runtime Protection**, **Dynamic Security Orchestration**.

---

# 🛡️ Architectural Principles

Security is **blast-radius reduction**, not “preventing all breaches.”

> ❌ “Prevent all breaches”
> ✅ **“Contain every breach”**

Each layer assumes the previous may fail.

---

# 🏗️ Layer 1 — Zero-Trust Authentication & Stateful Token Management

Browsers are **never trusted**. Long-lived tokens are high-risk:

* XSS → instant account takeover
* Persistent storage → silent exfiltration

### ✅ Double-Token Strategy

| Token Type    | Lifetime | Storage                           |
| ------------- | -------- | --------------------------------- |
| Access Token  | 5–15 min | Memory / short-lived HttpOnly     |
| Refresh Token | ~7 days  | HttpOnly, Secure, SameSite=Strict |

**Benefits:**

* Access tokens expire quickly
* Refresh tokens not accessible via JS
* XSS ≠ persistent compromise

### 🔁 Token Rotation & Revocation

* Rotate refresh tokens on use
* Revoke on logout or suspicious activity
* Track lineage server-side (e.g., Redis deny list using JWT `jti`)

---

# 🔐 Layer 2 — Cryptographic Intent & CSRF Protection

JWT protects **who you are**, CSRF protects **what you intended**.

**Django Settings:**

```python
CSRF_COOKIE_HTTPONLY = False
SESSION_COOKIE_HTTPONLY = True
```

**React + Axios:**

```javascript
axios.defaults.xsrfCookieName = 'csrftoken';
axios.defaults.xsrfHeaderName = 'X-CSRFToken';
```

**Flow:**

```
Django → csrftoken cookie
React  → reads token
Axios  → sends X-CSRFToken header
Django → validates intent
```

**Optional:** Per-request **HMAC** for sensitive mutations.

---

# 🛡️ Layer 3 — Browser Runtime Shield (CSP)

* Unique `nonce` per request
* Route-specific CSP:

  * Public → strict
  * Admin → charts allowed
  * Payment → zero third-party scripts
* Start with `Content-Security-Policy-Report-Only`

---

# 🧪 Layer 4 — Input Validation & Injection Barriers

* **Backend:** DRF serializers + `bleach`/`html-sanitizer`
* **No-Raw Policy:** Block `raw()`, `extra()`, `execute()`
* **Frontend (UX only):** Zod, Yup, React Hook Form
* **React Warning:** Never use `dangerouslySetInnerHTML` without sanitization

```python
class UserSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(min_length=8)
```

---

# 🚦 Layer 5 — Rate Limiting & Behavioral Analysis

* Block IPs triggering 50+ different 404s/min → 72-hour ban
* Inspect payloads via WAF (`../`, `UNION SELECT`, `<script>`)

**DRF Example:**

```python
REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/day',
        'user': '1000/day',
    }
}
```

---

# 🧱 Hardened Stack Infrastructure

| Component     | Tooling           | Goal                           |
| ------------- | ----------------- | ------------------------------ |
| API Proxy     | Nginx + Fail2Ban  | Block repetitive attackers     |
| App Server    | Gunicorn + Gevent | Resource isolation / DoS       |
| Database      | PostgreSQL + SSL  | Encrypted at-rest & in-transit |
| Observability | Sentry + ELK      | Real-time security alerts      |

---

# 🔐 Production Deployment Checklist

| Control        | Setting                        | Purpose          |
| -------------- | ------------------------------ | ---------------- |
| HTTPS          | Always on                      | Encrypt transit  |
| Secure Cookies | `SESSION_COOKIE_SECURE=True`   | Prevent leakage  |
| HSTS           | `SECURE_HSTS_SECONDS=31536000` | Force HTTPS      |
| Debug          | `DEBUG=False`                  | Prevent leaks    |
| CORS           | Explicit allowlist             | Restrict origins |

**CORS vs CSRF**

| Control | Solves                         |
| ------- | ------------------------------ |
| CORS    | Who can call API               |
| CSRF    | Whether request is intentional |

---

# 🎓 SOC-Ready Security Pack

**Auth & Session:** Short-lived access tokens, HttpOnly refresh tokens, rotation, logout revokes tokens
**Browser & Frontend:** CSP, no localStorage tokens, audited `dangerouslySetInnerHTML`, CSRF present
**Transport & Headers:** HTTPS, HSTS ≥1yr, X-Frame-Options, X-Content-Type-Options, Permissions-Policy locked
**API & Backend:** DRF validation, no raw SQL, global throttling, hardened endpoints
**Monitoring & Response:** CSP reports, throttle alerts, auth failure alerts, immutable logs

**Threat Mapping**

| Threat       | Control                |
| ------------ | ---------------------- |
| XSS          | CSP + HttpOnly cookies |
| CSRF         | Token validation       |
| Brute Force  | Throttling             |
| Token Theft  | Rotation + expiry      |
| Clickjacking | Frame denial           |

---

# 🏁 Security Audit Script

```python
from django.conf import settings

def audit():
    checks = {
        "DEBUG is False": not settings.DEBUG,
        "HSTS Enabled": settings.SECURE_HSTS_SECONDS > 0,
        "Secure Cookies": settings.SESSION_COOKIE_SECURE and settings.CSRF_COOKIE_SECURE,
        "CORS is Restricted": settings.CORS_ALLOWED_ORIGINS != "*",
    }
    
    for label, passed in checks.items():
        print(f"{'✅' if passed else '❌ CRITICAL'} {label}")
```

---

# 📦 GitHub Action: `django-security-audit.yml`

Automates CI/CD verification (build, migrate, audit, fail on CRITICAL).

---

# 🛡️ React + Django Security Blueprint (ASCII)

```
Browser (React SPA)
 ├─ Access Token in Memory (5–15min)
 ├─ Refresh Token HttpOnly (7d)
 └─ CSRF Token (Double-submit)
      │
      ▼
  API Request → Django API
      │
      ├─ JWT Validator / Deny List
      ├─ CSRF Checker
      ├─ HMAC Validator
      ├─ DRF Serializers / Input Sanitizer
      └─ Rate/Behavioral Limiting (WAF)
      │
      ▼
 Database / Persistent Layer (PostgreSQL + SSL)
      │
      ▼
 Observability & Logs (Sentry + ELK / CSP reports)
```

---

# 🚨 Incident Response & Disaster Recovery

## Phase I: Detection & Analysis

* Identify vector (token leak, SQLi, admin compromise)
* Audit logs & database trails
* Verify integrity of React build / Django views

## Phase II: Containment

* **Global Token Revocation** (flush deny list / rotate JWT_SECRET_KEY)
* **IP Shunning** via Nginx / Firewall
* **Database Lockdown** → READ-ONLY mode if exfiltration suspected

## Phase III: Eradication & Recovery

* Rotate all secrets (`DATABASE_URL`, `STRIPE_SECRET`, etc.)
* Rollback/redeploy from verified Git commit
* Apply code patches

## Phase IV: Post-Mortem & Notification

* Root Cause Analysis (“Five Whys”)
* Regulatory notifications (GDPR/CCPA)
* Update automated tests / GitHub Actions to prevent recurrence

---

# 🛡️ Emergency Kill-Switch (Django Middleware)

```python
from django.http import JsonResponse
from django.core.cache import cache

class EmergencyLockdownMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if cache.get("EMERGENCY_LOCKDOWN"):
            return JsonResponse(
                {"error": "System under maintenance for security updates."}, 
                status=503
            )
        return self.get_response(request)
```

---

### ✅ Defense-in-Depth Summary

1. **Preparation:** Hardened React/Django
2. **Prevention:** CSP, JWT Rotation, Throttling
3. **Detection:** GitHub Actions, Logging
4. **Response:** Triage, Kill-Switch, Post-Mortem



