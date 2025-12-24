# 📜 Security Audit Report: Project PyInsight

**Audit Date:** December 24, 2025

**Status:** 🟢 **RESILIENT** **Architecture:** Decoupled React (Vite) + Django REST Framework (DRF)

---

## 1. Authentication & Session Integrity

**Standard:** OWASP A01:2021 – Broken Access Control

| Control | Implementation Details | Status |
| --- | --- | --- |
| **Token Storage** | Refresh tokens stored in `HttpOnly`, `Secure`, `SameSite=Strict` cookies. | ✅ |
| **Session Lifetime** | Access Tokens: 15m | Refresh Tokens: 7d. | ✅ |
| **Revocation** | Redis-backed JTI (JWT ID) Deny-List for instant session termination. | ✅ |
| **Rotation** | Refresh Token Rotation (RTR) enabled on every token exchange. | ✅ |

---

## 2. Browser-Side Runtime Protection

**Standard:** OWASP A03:2021 – Injection (XSS)

| Control | Implementation Details | Status |
| --- | --- | --- |
| **CSP** | Nonce-based Content Security Policy (Strict). | ✅ |
| **Data Flow** | Zero use of `dangerouslySetInnerHTML` without `DOMPurify` scrubbing. | ✅ |
| **Clickjacking** | `X-Frame-Options: DENY` enforced globally. | ✅ |
| **MIME Sniffing** | `X-Content-Type-Options: nosniff` active. | ✅ |

---

## 3. API & Intent Verification

**Standard:** OWASP A01 & A05: Security Misconfiguration

| Control | Implementation Details | Status |
| --- | --- | --- |
| **CSRF Defense** | Double-submit cookie pattern with Axios interceptors. | ✅ |
| **Throttling** | IP-based Anon Throttling + User-based Burst/Sustained limits. | ✅ |
| **Payload Scan** | WAF-level inspection for directory traversal and SQL signatures. | ✅ |
| **CORS** | Strict Origin Allow-list; no wildcard (`*`) usage in production. | ✅ |

---

## 4. Input/Output Data Hardening

**Standard:** OWASP A03 – Injection

| Control | Implementation Details | Status |
| --- | --- | --- |
| **Validation** | DRF Serializers acting as a type-safe gatekeeper for all mutations. | ✅ |
| **ORM Usage** | Strict "No-Raw SQL" policy enforced via linting and code review. | ✅ |
| **Sanitization** | Server-side scrubbing of HTML inputs via `bleach` library. | ✅ |

---

## 5. Resilience & Incident Response

**Standard:** OWASP A09:2021 – Security Logging and Monitoring Failures

| Control | Implementation Details | Status |
| --- | --- | --- |
| **Observability** | Sentry logging for `SuspiciousOperation` and `403 Forbidden` spikes. | ✅ |
| **Kill-Switch** | Redis-triggered `EmergencyLockdownMiddleware` for instant API halt. | ✅ |
| **Audit Trail** | Immutable database logs for sensitive data mutations. | ✅ |

---

## 🛠️ Executive Summary & Recommendations

The PyInsight platform currently operates at a **Senior-Tier Security Maturity Level**. The implementation of a hybrid stateful-stateless authentication model significantly reduces the risk of session hijacking, while the nonce-based CSP provides a robust secondary defense against XSS.

**Next Strategic Steps:**

1. **Automated DAST:** Integrate a Dynamic Application Security Testing tool (like OWASP ZAP) into the CI/CD pipeline.
2. **MFA Expansion:** Implement WebAuthn/FIDO2 support for administrative accounts.
3. **Secrets Management:** Transition from `.env` files to a dedicated provider like **HashiCorp Vault** or **AWS Secrets Manager**.

---

### 🎓 Moving Forward

You have now documented a system that is not only secure but **defensible**. This report can be included in your project documentation or presented during technical interviews to demonstrate your mastery of Fullstack Security Engineering.

---
Moving from `.env` files to a dedicated secret vault like **HashiCorp Vault** or **AWS Secrets Manager** is the final step in enterprise-grade hardening. This eliminates "Secret Sprawl" and enables **Dynamic Secrets** (credentials that are generated on the fly and expire automatically).

---

# 🗝️ Secrets Management Migration Plan

## 1. The "Secret Sprawl" Problem vs. The Vault Solution

In a standard setup, secrets live in `.env` files on various servers. If a server is compromised, all secrets are exposed. Centralized management changes this.

| Feature | Legacy (.env) | Enterprise (Vault/AWS) |
| --- | --- | --- |
| **Storage** | Plaintext on Disk | Encrypted in Memory/HSM |
| **Rotation** | Manual (High Risk) | Automatic & Programmatic |
| **Audit** | None | Full log of "Who accessed what" |
| **Dynamic** | Static Passwords | Just-in-Time Credentials |

---

## 2. Phase I: Extraction & Mapping

Before moving to a vault, you must audit your existing environment variables and categorize them.

* **Static Secrets:** `SECRET_KEY`, API Keys, OAuth client secrets.
* **Infrastructure Secrets:** `DATABASE_URL`, Redis passwords, AWS credentials.
* **Non-Secret Config:** `DEBUG`, `ALLOWED_HOSTS`, `CORS_ALLOWED_ORIGINS` (These should stay as env vars or in a config file).

---

## 3. Phase II: Implementation (Django + hvac)

The most common way to integrate Django with HashiCorp Vault is using the `hvac` library.

### ⚙️ The Vault Utility Helper

Instead of reading from `os.getenv`, we create a utility that fetches from the Vault API during the Django boot process.

```python
import hvac
import os

def get_vault_secret(path):
    client = hvac.Client(url=os.getenv('VAULT_ADDR'), token=os.getenv('VAULT_TOKEN'))
    if not client.is_authenticated():
        raise Exception("Vault Authentication Failed")
    
    response = client.secrets.kv.v2.read_secret_path(path=path)
    return response['data']['data']

```

### ⚙️ Updating `settings.py`

We load the secrets once at startup. For highly dynamic secrets (like DB passwords), we use a wrapper that refreshes the credentials periodically.

```python
# settings.py
from .vault_utils import get_vault_secret

# Fetch all production secrets in one call
vault_secrets = get_vault_secret('project/production/django')

SECRET_KEY = vault_secrets['SECRET_KEY']
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': vault_secrets['DB_NAME'],
        'USER': vault_secrets['DB_USER'],
        'PASSWORD': vault_secrets['DB_PASSWORD'],
        'HOST': vault_secrets['DB_HOST'],
    }
}

```

---

## 4. Phase III: Deployment & CI/CD Integration

The goal is to ensure that **no human** ever sees the production secrets.

* **Development:** Use a local Vault container or `dev` path.
* **Production:** Use **AppRole** authentication. Django identifies itself to Vault using a `RoleID` and `SecretID` provided by your orchestration tool (like Terraform or Kubernetes).
* **CI/CD:** Use **OIDC (OpenID Connect)**. GitHub Actions can authenticate directly with Vault/AWS without storing a long-lived master key.

---

## 5. Phase IV: The "Kill-Switch" Rotation

One of the greatest benefits of this migration is the ability to rotate secrets instantly across your entire cluster if a breach is suspected.

> **The "Emergency Rotation" Command:**
> With one command in Vault, you can rotate the Database password. Vault will update the DB and then signal your Django workers to refresh their credentials, effectively locking out any attacker using old leaked credentials.

---

### 🎓 Strategic Summary

By moving to a Secrets Manager, you have removed the "single point of failure" in your security stack. Your application no longer "knows" its own secrets; it "borrows" them from a secure source as needed.

