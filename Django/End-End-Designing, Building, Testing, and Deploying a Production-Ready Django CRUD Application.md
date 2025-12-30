# 📘 **End-to-End Engineering Handbook**

## **Production-Grade Django CRUD Application (Function-Based Views)**

**Edition:** 1.0
**Framework:** Django
**View Style:** Function-Based Views (FBVs)
**Database:** SQLite → MySQL / PostgreSQL
**Deployment:** Docker + Gunicorn
**Audience:** Engineers · Trainers · Architects

---

## 1️⃣ Executive Summary

This handbook is a **complete engineering blueprint** for building **TaskHub**, a production-ready **multi-user, multi-tenant task management system** using **Django Function-Based Views (FBVs)**.

It emphasizes **explicit control**, **clarity of flow**, and **architectural correctness** over abstraction magic.

### What You Will Build

* Secure **CRUD application** with authentication
* **Tenant-aware data isolation**
* **Role-based access control**
* **Audit logging** for compliance
* **Containerized deployment**
* Clean, testable FBV codebase

### Why FBVs?

FBVs make **request handling explicit**:

```
Request → Authentication → Authorization → Validation → DB → Response
```

This is ideal for:

* learning Django internals
* security reviews
* audits
* debugging production incidents

---

## 2️⃣ Engineering Philosophy

### Core Principles

1. **Design before code**
2. **Explicit is better than implicit**
3. **Security is structural, not optional**
4. **Infrastructure is part of the application**
5. **Auditability is a first-class concern**

---

## 3️⃣ System Overview – TaskHub

### Functional Scope

* Users belong to **tenants (organizations)**
* Users create and manage **tasks**
* Tasks are:

  * owned by users
  * scoped to tenants
* All changes are **audited**

---

## 4️⃣ High-Level Architecture

```
Browser
  |
  v
Django URLs
  |
  v
Function-Based Views (FBVs)
  |
  +--> Authentication
  +--> Tenant & Role Enforcement
  +--> Validation
  |
  v
ORM (Models)
  |
  +--> Task
  +--> Tenant
  +--> AuditLog
  |
  v
Database (SQLite → MySQL/Postgres)
```

---

## 5️⃣ Project Structure

```
taskhub/
├── manage.py
├── taskhub/
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
│
├── accounts/
│   ├── models.py
│   ├── signals.py
│   └── admin.py
│
├── tasks/
│   ├── models.py
│   ├── forms.py
│   ├── views.py
│   ├── urls.py
│   └── templates/
│
├── audits/
│   ├── models.py
│   └── utils.py
│
└── templates/
```

---

## 6️⃣ Authentication & User Profiles

### UserProfile Model

```python
class Tenant(models.Model):
    name = models.CharField(max_length=100, unique=True)

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
```

### Why Not Put Tenant on User?

* Keeps auth model clean
* Allows future identity providers (SSO)
* Supports richer profile metadata

---

## 7️⃣ Task Domain Model

```python
class Task(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
```

---

## 8️⃣ Forms & Validation

```python
class TaskForm(forms.ModelForm):
    class Meta:
        model = Task
        fields = ["title", "description", "completed"]
```

**Rules:**

* Never trust request data
* All writes go through forms
* Validation happens **before persistence**

---

## 9️⃣ CRUD with Function-Based Views

### Task List (Tenant-Aware)

```python
@login_required
def task_list(request):
    tenant = request.user.userprofile.tenant
    tasks = Task.objects.filter(
        owner=request.user,
        tenant=tenant
    )
    return render(request, "tasks/list.html", {"tasks": tasks})
```

---

### Task Create

```python
@login_required
def task_create(request):
    if request.method == "POST":
        form = TaskForm(request.POST)
        if form.is_valid():
            task = form.save(commit=False)
            task.owner = request.user
            task.tenant = request.user.userprofile.tenant
            task.save()
            return redirect("task_list")
    else:
        form = TaskForm()
    return render(request, "tasks/form.html", {"form": form})
```

---

### Task Update

```python
@login_required
def task_update(request, pk):
    task = get_object_or_404(Task, pk=pk)

    if task.owner != request.user:
        return HttpResponseForbidden()

    if request.method == "POST":
        form = TaskForm(request.POST, instance=task)
        if form.is_valid():
            form.save()
            return redirect("task_list")
    else:
        form = TaskForm(instance=task)

    return render(request, "tasks/form.html", {"form": form})
```

---

## 🔐 10️⃣ Authorization & Ownership

### Ownership Rules

```
User can:
✔ Read own tasks
✔ Modify own tasks
✘ Access other users’ tasks
```

### Enforcement Pattern

```
FBV
 ├─ fetch object
 ├─ check ownership / tenant
 └─ proceed or deny
```

---

## 11️⃣ Multi-Tenant Architecture

### Tenant Enforcement Rule

> **Every query MUST include tenant filtering**

```python
Task.objects.filter(tenant=request.user.userprofile.tenant)
```

### Tenant Flow

```
Request
  |
  v
Authenticated User
  |
  v
Resolve Tenant
  |
  v
Tenant-Scoped Query
```

---

## 12️⃣ Role-Based Access Control (RBAC)

```python
class TenantRole(models.TextChoices):
    ADMIN = "ADMIN"
    MANAGER = "MANAGER"
    USER = "USER"
```

```python
class UserProfile(models.Model):
    role = models.CharField(
        max_length=10,
        choices=TenantRole.choices,
        default=TenantRole.USER
    )
```

### Permission Logic

```python
def can_edit_task(user, task):
    profile = user.userprofile
    if profile.role == "ADMIN":
        return True
    if profile.role == "MANAGER":
        return task.tenant == profile.tenant
    return task.owner == user
```

---

## 13️⃣ Audit Logging

### Why Audit Logs Matter

* Compliance (SOC2, ISO, HIPAA)
* Debugging incidents
* Legal accountability

---

### Audit Model

```python
class TaskAudit(models.Model):
    task = models.ForeignKey(Task, on_delete=models.CASCADE)
    action = models.CharField(max_length=10)
    performed_by = models.ForeignKey(User, null=True, on_delete=models.SET_NULL)
    old_values = models.JSONField(null=True, blank=True)
    new_values = models.JSONField(null=True, blank=True)
    performed_at = models.DateTimeField(auto_now_add=True)
```

---

### Audit Flow

```
Update Request
  |
  v
Capture old_values
  |
  v
Save Task
  |
  v
Capture new_values
  |
  v
Persist Audit Log
```

---

## 14️⃣ Testing Strategy

### What to Test

| Layer       | Test Type   |
| ----------- | ----------- |
| Forms       | Unit        |
| Views       | Integration |
| Permissions | Security    |
| Audit Logs  | Regression  |

### Example Test

```python
def test_task_is_tenant_scoped(client, user):
    client.force_login(user)
    response = client.get("/tasks/")
    assert response.status_code == 200
```

---

## 15️⃣ Containerization

### Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["gunicorn", "taskhub.wsgi:application", "--bind", "0.0.0.0:8000"]
```

---

## 16️⃣ Deployment Strategy

### Single-Node (SQLite)

```
Docker → Gunicorn → SQLite
```

### Production (SaaS)

```
Load Balancer
  |
  v
Multiple Containers
  |
  v
PostgreSQL / MySQL
```

---

## 17️⃣ Migration Strategy

```
SQLite
  |
  v
PostgreSQL
  |
  v
Multi-Node Scaling
```

---

## 18️⃣ Operational Considerations

* Log all auth failures
* Monitor audit table growth
* Enforce migrations in CI
* Backups are mandatory

---

## 19️⃣ Full System Flow (End-to-End)

```
Browser
  |
  v
FBV
  |
  +-> Auth
  +-> Tenant Enforcement
  +-> Role Check
  |
  v
Form Validation
  |
  v
DB Write
  |
  +-> Audit Log
  |
  v
Response
```

---

## 20️⃣ Final Mental Model

> **Django FBVs are not primitive.
> They are precise.
> Precision scales.**

If you can reason about:

* every request
* every permission
* every database write

You can operate systems **with confidence**.

---


