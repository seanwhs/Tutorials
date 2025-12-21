# **End-to-End Engineering Handbook: Django CRUD Application (FBVs)**

**Edition:** 1.0
**Framework:** Django
**View Style:** Function-Based Views (FBVs)
**Database:** SQLite (Embedded, single-node; scalable to MySQL/PostgreSQL)
**Deployment:** Docker + Gunicorn
**Audience:** Engineers, Trainers, Architects

---

## **Executive Summary**

This handbook provides a **step-by-step engineering blueprint** for building **TaskHub**, a production-ready **multi-user task management system**.

**Highlights:**

* Authenticated CRUD workflows with **ownership enforcement**
* Multi-tenant support for **multiple organizations**
* **Audit logging** for operational visibility and compliance
* Explicit **request–response lifecycle with FBVs**
* Automated **unit testing, integration testing**, and **containerized deployment**

**Engineering Focus:**

* Systematic **design before coding**
* Explicit **architectural and security decisions**
* Testable, maintainable, and production-ready code

---

## **Module Map**

| Module | Topic                                         |
| ------ | --------------------------------------------- |
| 1      | System Conception & Requirements Engineering  |
| 2      | Architecture & Design Decisions               |
| 3      | Environment & Project Setup                   |
| 4      | Database Design with SQLite                   |
| 5      | Forms & Validation                            |
| 6      | CRUD Implementation (FBVs)                    |
| 7      | Authentication & Authorization                |
| 8      | Templates & Request Flow                      |
| 9      | Testing Strategy                              |
| 10     | Production Hardening                          |
| 11     | Containerization                              |
| 12     | Deployment                                    |
| 13     | Operational Considerations                    |
| 14     | Multi-Tenant Extension                        |
| 15     | Audit Logging Module                          |
| 16     | Advanced Multi-Tenant Production Enhancements |

---

# **Module 12 – Deployment**

### **12.1 Objectives**

* Package TaskHub as a **Docker container**
* Deploy to internal tools or **cloud platforms**
* Understand limitations of SQLite and migration paths

### **12.2 Single-Node Docker Deployment**

**Dockerfile:**

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN python manage.py collectstatic --noinput
CMD ["gunicorn", "taskhub.wsgi:application", "--bind", "0.0.0.0:8000"]
```

**Text-Based Deployment Flow Diagram:**

```
Developer Machine
       |
       v
  Docker Build
       |
       v
Docker Image -> Run Container
       |
       v
   TaskHub App (Gunicorn)
       |
       v
  Exposed on Port 8000
```

**Docker Compose (optional for dev):**

```yaml
version: '3'
services:
  web:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - .:/app
```

### **12.3 Cloud Deployment Steps**

```
Build Docker Image -> Push to Registry -> Deploy Cloud Container
        |                 |                    |
        v                 v                    v
   Local Testing    Docker Hub/ECR/GCR    Cloud Run / ECS / GKE
        |                                      |
        v                                      v
     Container starts                        App accessible via HTTPS
```

---

# **Module 13 – Operational Considerations**

### **13.1 SQLite Considerations**

* Embedded and single-threaded
* Ideal for **development, small internal tools**
* Not suitable for high concurrency or multi-node production

### **13.2 Database Migration**

* Migration path: SQLite → MySQL/PostgreSQL
* Steps:

```
Install Target DB -> Update settings.py -> Migrate -> Import Data
```

### **13.3 Scaling Considerations**

* Monolithic single-node initially
* Horizontal scaling: multiple containers + centralized DB
* Ownership & tenant enforcement ensures **safe multi-instance operation**

---

# **Module 14 – Multi-Tenant Extension**

### **14.1 Objectives**

* Support multiple organizations (**tenants**)
* Tenant-specific task filtering
* Automatic tenant assignment

### **14.2 Tenant Models**

```python
class Tenant(models.Model):
    name = models.CharField(max_length=100, unique=True)

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name='users')
```

### **14.3 Tenant-Aware CRUD Example**

```python
@login_required
def task_list(request):
    tenant = request.user.userprofile.tenant
    tasks = Task.objects.filter(owner=request.user, tenant=tenant)
    return render(request, 'tasks/task_list.html', {'tasks': tasks})
```

**Tenant Enforcement Flow:**

```
Incoming Request -> FBV
        |
        v
Get user tenant -> Filter queryset by tenant
        |
        v
Return tenant-specific tasks
```

### **14.4 Automatic Tenant Assignment on Create**

```python
task.tenant = request.user.userprofile.tenant
```

---

# **Module 15 – Audit Logging Module**

### **15.1 Objectives**

* Track **who made changes**
* Capture **create, update, delete** actions
* Store optional **old/new values**

### **15.2 TaskAudit Model**

```python
class TaskAudit(models.Model):
    ACTION_CHOICES = [('CREATE','Create'),('UPDATE','Update'),('DELETE','Delete')]
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='audits')
    action = models.CharField(max_length=10, choices=ACTION_CHOICES)
    performed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    performed_at = models.DateTimeField(auto_now_add=True)
    old_values = models.JSONField(blank=True, null=True)
    new_values = models.JSONField(blank=True, null=True)
```

### **15.3 Integrate Audit Logging in Views**

```
Request -> FBV
   |
   v
Fetch task -> Capture old_values
   |
   v
Form validation & save
   |
   v
Capture new_values -> Create TaskAudit entry
   |
   v
Return response
```

**Example for update:**

```python
old_values = {'title': task.title, 'description': task.description}
...
new_values = {'title': task.title, 'description': task.description}
TaskAudit.objects.create(task=task, action='UPDATE', performed_by=request.user, old_values=old_values, new_values=new_values)
```

---

# **Module 16 – Advanced Multi-Tenant Production Enhancements**

### **16.1 Objectives**

* Deploy **TaskHub with SQLite** for small orgs
* Migrate to **MySQL/PostgreSQL** for SaaS
* Implement **role-based access per tenant**
* Maintain **full audit logs**

### **16.2 Role-Based Access**

```python
class TenantRole(models.TextChoices):
    ADMIN = 'ADMIN', 'Admin'
    MANAGER = 'MANAGER', 'Manager'
    USER = 'USER', 'User'

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name='users')
    role = models.CharField(max_length=10, choices=TenantRole.choices, default=TenantRole.USER)
```

**Access Enforcement Function:**

```python
def user_can_edit_task(user, task):
    profile = user.userprofile
    if profile.role == 'ADMIN':
        return True
    elif profile.role == 'MANAGER':
        return task.owner.userprofile.tenant == profile.tenant
    else:
        return task.owner == user
```

**Role-Based Flow:**

```
Incoming Request -> FBV
   |
   v
Get user role & tenant
   |
   v
Check permissions (ADMIN/Manager/User)
   |
   v
Allow or deny CRUD operation
```

### **16.3 MySQL Deployment for Production**

```
Update settings.py -> Run migrate -> Deploy container
```

*Multi-node capable, supports SaaS load and high concurrency.*

### **16.4 Full Audit Logging**

* Records **old/new field values**
* Tenant isolation enforced
* Compliance-ready audit trails

**Audit Flow in Multi-Tenant Production:**

```
User Action -> FBV -> Permission Check -> Save Task -> Audit Logging
        |
        v
Tenant isolation enforced
        |
        v
AuditEntry (old/new values) stored in DB
```

---

# ✅ **Integrated System Flow Diagram (Text-Based)**

```
[User Browser]
      |
      v
[FBV Request] -> Auth Check -> Role/Tenant Enforcement
      |
      v
[Form Validation / Task CRUD]
      |
      +-> Audit Logging -> TaskAudit Table
      |
      v
[Database Operation (Task Table)]
      |
      v
[Response to User -> Update UI]
```

**Highlights:**

* All CRUD operations are **tenant-aware and role-protected**
* Audit logs capture changes in **real-time**
* Flow supports **SQLite → MySQL migration** for SaaS scaling


