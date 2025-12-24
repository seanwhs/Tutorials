# 🛡️ Security Hardening Guide — React & Django (Production Grade)

Modern frontend–backend systems are no longer protected by a single firewall or login screen.
A React + Django application is a **distributed system** running across browsers, APIs, and infrastructure boundaries.

This guide focuses on **practical, high-impact security controls** that close the most common real-world attack vectors without overengineering.

> **Security philosophy:**
> *Assume the frontend is hostile, the network is observable, and attackers are patient.*

---

## 1️⃣ Secure Token Storage (JWT Authentication)

### ❌ The Common Mistake: `localStorage`

Storing JWTs in `localStorage` or `sessionStorage` is one of the most frequent frontend security failures.

**Why it’s dangerous:**

* Any successful **XSS (Cross-Site Scripting)** attack can read `localStorage`
* Once stolen, JWTs allow full session hijacking
* Tokens persist across browser restarts and are easy to exfiltrate

---

### ✅ Production Strategy: HttpOnly Cookies

**Recommended approach:**

* Store access tokens in **HttpOnly, Secure cookies**
* Use **SameSite=Strict** (or `Lax` if needed for redirects)

```text
Set-Cookie:
  access_token=...;
  HttpOnly;
  Secure;
  SameSite=Strict;
```

**Why this works:**

* `HttpOnly` cookies are **inaccessible to JavaScript**
* Even if an attacker injects malicious JS, they **cannot read or steal the token**
* The browser handles cookie transmission automatically

> 🔐 Result: XSS no longer equals account takeover.

---

### 🔁 Token Rotation (Recommended)

For higher-security systems:

* Use **short-lived access tokens**
* Use **rotating refresh tokens**
* Revoke refresh tokens on logout or suspicious activity

This limits blast radius even if a token is compromised.

---

## 2️⃣ CSRF Protection (Cross-Site Request Forgery)

When authentication uses cookies, **CSRF becomes a real threat**.

### The Attack Scenario

1. User is logged into your site
2. User visits a malicious website
3. That site silently submits a POST request to your API
4. Browser automatically includes cookies
5. Action executes without user consent

---

### ✅ Django Defense: CSRF Middleware

Ensure `CsrfViewMiddleware` is enabled:

```python
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    ...
]
```

Django automatically:

* Issues CSRF tokens
* Validates them on unsafe HTTP methods (POST, PUT, DELETE)

---

### ✅ React + Axios Integration

Your frontend must **read the CSRF token from cookies and echo it back** in headers.

```javascript
// Axios global CSRF configuration
axios.defaults.xsrfCookieName = 'csrftoken';
axios.defaults.xsrfHeaderName = 'X-CSRFToken';
```

**Resulting flow:**

```
Django → csrftoken cookie
React  → reads cookie
Axios  → sends X-CSRFToken header
Django → validates match
```

> 🧠 Key Insight:
> **JWT protects authentication. CSRF protects intent. You need both.**

---

## 3️⃣ Content Security Policy (CSP)

XSS is one of the most damaging web vulnerabilities.
A **Content Security Policy (CSP)** dramatically reduces its impact—even if a bug slips through.

---

### What CSP Does

CSP tells the browser:

* Which scripts are allowed to run
* Which domains can load assets
* Whether inline scripts are permitted

If injected code violates the policy, **the browser blocks it automatically**.

---

### Django Implementation

Use `django-csp` to define and enforce CSP headers.

```bash
pip install django-csp
```

```python
INSTALLED_APPS = [
    'csp',
    ...
]
```

---

### Example Policy

```http
Content-Security-Policy:
  default-src 'self';
  script-src 'self' https://trustedscripts.com;
  style-src 'self' 'unsafe-inline';
  img-src 'self' data:;
```

**Security impact:**

* Prevents unauthorized script execution
* Blocks injected `<script>` tags
* Mitigates supply-chain attacks

> 🛑 CSP turns XSS from “critical” into “contained”.

---

## 4️⃣ Backend Rate Limiting & Throttling

APIs are attack surfaces.

Without throttling, attackers can:

* Brute-force login credentials
* Enumerate users
* Flood file uploads
* Exhaust system resources

---

### Django REST Framework Throttling

Enable global throttling in `settings.py`:

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

### Best Practices

* Apply **stricter limits** on:

  * `/login`
  * `/password-reset`
  * `/upload`
* Log throttle violations
* Combine with CAPTCHA for high-risk endpoints

> 🧠 Rate limiting converts brute force into noise.

---

## 5️⃣ Input Validation & Sanitization (Defense in Depth)

Never trust data from:

* Forms
* Query parameters
* Headers
* JSON payloads

Frontend validation improves UX — **backend validation ensures safety**.

---

### Backend: Django REST Framework Serializers

DRF serializers enforce:

* Data types
* Length constraints
* Formats (email, UUID, dates)
* Business rules

```python
class UserSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(min_length=8)
```

Invalid input never reaches business logic.

---

### Frontend: Schema Validation (UX Layer)

Use schema validators to prevent invalid data from being sent:

* `Zod`
* `Yup`
* `React Hook Form`

```ts
const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
})
```

**Why both layers matter:**

* Frontend → user experience
* Backend → security guarantee

---

## 6️⃣ Secure Production Deployment Checklist

Before going live, **infrastructure-level security must be enabled**.

| Feature            | Setting                            | Purpose                     |
| ------------------ | ---------------------------------- | --------------------------- |
| **HTTPS**          | Always enabled                     | Encrypts data in transit    |
| **Secure Cookies** | `SESSION_COOKIE_SECURE = True`     | Prevents cookie leakage     |
| **XSS Filter**     | `SECURE_BROWSER_XSS_FILTER = True` | Browser-side XSS mitigation |
| **HSTS**           | `SECURE_HSTS_SECONDS = 31536000`   | Forces HTTPS                |
| **CORS**           | `CORS_ALLOWED_ORIGINS`             | Restricts frontend domains  |
| **Debug Off**      | `DEBUG = False`                    | Prevents info leaks         |

---

### CORS vs CSRF (Common Confusion)

* **CORS** controls *who can call your API*
* **CSRF** controls *whether a request is intentional*

They solve **different problems** and must be configured together.

---

## 🧠 Threat Coverage Summary

| Threat         | Mitigation                    |
| -------------- | ----------------------------- |
| XSS            | HttpOnly cookies, CSP         |
| CSRF           | CSRF tokens, SameSite cookies |
| Brute Force    | Rate limiting                 |
| Injection      | Serializer validation         |
| Session Hijack | Secure cookies, HTTPS         |
| Token Theft    | No localStorage               |

---

## 🎓 Security Outcome

By applying these controls, your system transitions from:

> ❌ “It works on my machine”
> to
> ✅ **Enterprise-ready, OWASP-aware architecture**

You have meaningfully reduced the risk of:

* Broken access control
* Injection attacks
* Token theft
* Cryptographic failures

🚀 Your React + Django stack is now **defensible, resilient, and production-worthy**.
