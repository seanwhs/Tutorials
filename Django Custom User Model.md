# 🧩 Django Custom User Model - Conceptual & Code Walkthrough

**From Identity Theory → Django Internals → Production Architecture**

---

## 1️⃣ Identity Is a Security Boundary (Not Just a Table)

Before touching Django, we must fix a **common mental model mistake**:

> ❌ “The User model stores user data”
> ✅ “The User model represents an *authentication boundary*”

### What the User Model Actually Does

The Django User model is responsible for only **four critical things**:

1. **Identity** – Who is attempting to authenticate?
2. **Credential Verification** – Is the password valid?
3. **Account State** – Is this account active, locked, staff, or superuser?
4. **Permission Interface** – Can this identity do X?

Everything else is **context**, not identity.

---

## 2️⃣ Why Django’s Default User Is a Trap

Django’s default `User` model was designed in **2005-era web assumptions**.

### Structural Limitations

| Default Field             | Why It’s a Problem                             |
| ------------------------- | ---------------------------------------------- |
| `username`                | Artificial identifier, not business-meaningful |
| `first_name`, `last_name` | Not global-friendly                            |
| Mixed concerns            | Profile + identity combined                    |
| Hard migration            | Cannot easily swap later                       |

> 🔥 **Once you migrate data into `auth_user`, you are locked in.**

---

## 3️⃣ Designing the Custom User Model (Before Coding)

### The Correct Architectural Split

```
┌────────────┐
│   User     │  ← Authentication Boundary
├────────────┤
│ email      │
│ password   │
│ is_active  │
│ is_staff   │
└────────────┘
       │
       ▼
┌──────────────┐
│ UserProfile  │  ← Business Context
├──────────────┤
│ full_name    │
│ phone        │
│ department   │
│ tenant       │
└──────────────┘
```

This split is not stylistic — it is **security engineering**.

---

## 4️⃣ Custom User Manager — Why It Exists

### Why Django Requires a User Manager

Django uses the **manager** to enforce:

* How users are created
* How passwords are hashed
* What invariants must always be true

Without a custom manager, Django **does not know how to create users properly**.

---

### Code: `UserManager`

```python
class UserManager(BaseUserManager):
```

🔍 This inherits Django’s base manager that already understands:

* Password hashing
* Database routing
* Superuser creation logic

---

```python
def create_user(self, email, password=None, **extra_fields):
```

✔ This method is used by:

* `createsuperuser`
* Admin panel
* Programmatic user creation

---

```python
if not email:
    raise ValueError("Users must have an email address")
```

🚨 **Invariant enforcement**

Without this:

* You could create users with `NULL` identity
* Authentication becomes undefined
* Permissions break

---

```python
email = self.normalize_email(email)
```

✔ Prevents:

* Case-sensitive duplicates
* Unicode email issues

---

```python
user = self.model(email=email, **extra_fields)
```

📌 **Important**
This does **not** save the user yet.

---

```python
user.set_password(password)
```

🚨 **Critical security step**

* Hashes the password
* Applies Django’s password hashers
* Adds salt automatically

❌ Never assign `user.password = password`

---

```python
user.save(using=self._db)
```

✔ Ensures compatibility with:

* Multiple databases
* Replication
* Sharding

---

## 5️⃣ Why `AbstractBaseUser` + `PermissionsMixin`

### Why Not `AbstractUser`?

| Option             | Use Case                   |
| ------------------ | -------------------------- |
| `AbstractUser`     | Minor tweaks only          |
| `AbstractBaseUser` | Full control (recommended) |

We want **full control**.

---

### Custom User Model Explained Line-by-Line

```python
class User(AbstractBaseUser, PermissionsMixin):
```

🔍 This gives us:

| Mixin              | What It Provides                 |
| ------------------ | -------------------------------- |
| `AbstractBaseUser` | Password hashing, login tracking |
| `PermissionsMixin` | Groups, permissions, superuser   |

---

```python
email = models.EmailField(unique=True)
```

✔ Email becomes the **identity key**
✔ Database enforces uniqueness

---

```python
USERNAME_FIELD = "email"
```

🚨 **This is what tells Django how to authenticate**

Without this:

* Django still expects `username`
* Authentication fails silently

---

```python
objects = UserManager()
```

📌 Mandatory
Django will **refuse** to create users without it.

---

## 6️⃣ Why You Must Set `AUTH_USER_MODEL` Early

```python
AUTH_USER_MODEL = "accounts.User"
```

This tells Django:

> “All foreign keys pointing to users must reference this model.”

Changing this later breaks:

* Foreign keys
* Migrations
* Permissions
* Admin

---

## 7️⃣ User Profile Model — Deep Rationale

### Why Not Put Profile Fields in User?

| Reason           | Explanation                          |
| ---------------- | ------------------------------------ |
| Security         | Profile data is not auth-critical    |
| Change frequency | Profiles change often                |
| Multi-tenant     | Profiles are tenant-scoped           |
| Extensibility    | Different apps need different fields |

---

### One-to-One Relationship

```python
user = models.OneToOneField(
    settings.AUTH_USER_MODEL,
    on_delete=models.CASCADE,
    related_name="profile"
)
```

This creates:

```python
user.profile.full_name
```

✔ Clean
✔ Discoverable
✔ Safe

---

## 8️⃣ Why Signals Are Used (And When Not To)

```python
@receiver(post_save, sender=settings.AUTH_USER_MODEL)
```

This ensures:

* Profile always exists
* No race condition
* No manual creation

📌 **Use signals sparingly**
This is one of the *correct* use cases.

---

## 9️⃣ Permissions & Roles — Real-World Authorization

### Django Permissions ≠ Business Roles

Django permissions are **low-level**:

```
add_user
change_user
delete_user
```

But businesses think in **roles**:

```
Admin
Manager
Viewer
```

---

### Role Abstraction Layer

```python
class Role(models.Model):
    name = models.CharField(max_length=50)
    permissions = models.ManyToManyField(Permission)
```

This creates:

```
User → Profile → Role → Permissions
```

✔ Clean
✔ Auditable
✔ Replaceable

---

## 🔐 Security Implications (Very Important)

### What This Architecture Prevents

✔ Privilege escalation
✔ Token overloading
✔ Data leakage across tenants
✔ Accidental permission grants

---

## 🧠 Mental Model Summary

| Layer      | Responsibility             |
| ---------- | -------------------------- |
| User       | Authentication & identity  |
| Profile    | Business context           |
| Role       | Human-readable permissions |
| Permission | Enforcement                |

---

## 🚀 Why This Matters in Production

This architecture enables:

* JWT auth
* OAuth2 / SSO
* MFA
* Multi-tenant SaaS
* Compliance audits
* Zero-trust APIs

---

## 🏁 Final Takeaway

> **Your User model is not a table — it is a security boundary.**

Design it as such, and Django becomes an **enterprise-grade identity platform**, not just a framework.

---

