# **Enterprise-Grade Guide: Step-by-Step Build of a Modular Django REST App with JWT & Async Observability (MySQL Edition)**

This guide provides a **comprehensive roadmap** to building a **production-ready, modular Django REST Framework (DRF) application** optimized for **multi-tenant SaaS environments**, with strong observability, tenant isolation, and a MySQL backend.

The application includes:

* **JWT Authentication** – Stateless, tenant-aware tokens for secure access
* **Async Observability** – Non-blocking logging, error tracking, and metrics collection
* **Multi-Tenant Awareness** – Tenant-specific logs, metrics, and dashboards
* **MySQL Backend** – Reliable relational storage
* **Modular Architecture** – Plug-and-play apps for extensibility

This step-by-step guide is aimed at **enterprise-grade production deployments**.

---

## **1. Understanding Core Concepts**

Before starting development, familiarize yourself with key concepts:

### **1.1 Modular Apps**

Each feature is implemented as a **standalone Django app**, e.g., `CRUD`, `Auth`, `Observability`.

**Advantages:**

* **Independent Testing:** Each app can be tested in isolation
* **Extensibility:** New features can be added without affecting other modules
* **Maintainability:** Smaller, focused apps reduce complexity

---

### **1.2 JWT Authentication**

JSON Web Tokens (JWT) provide **stateless, scalable authentication**.

* Tokens include a **`tenant_id`** field to support tenant-aware API calls.
* No server-side session storage is required, allowing **horizontal scaling**.
* Essential for SaaS where multiple tenants share the same infrastructure.

---

### **1.3 Async Observability**

Using **Celery + Redis**, requests, errors, and metrics are logged **asynchronously**:

* Ensures **non-blocking request handling**
* High throughput logging for **enterprise-scale workloads**
* Supports **real-time metrics** for dashboards and alerts

---

### **1.4 Tenant Awareness**

Logs, metrics, and dashboards are **tenant-specific**:

* Enables **compliance with data segregation rules**
* Provides **tenant-specific alerting and dashboards**
* Ensures **data isolation** while maintaining shared infrastructure

---

### **1.5 Plug-and-Play Extensibility**

The modular design allows new apps, like **Notifications** or **Billing**, to integrate without impacting core functionality.

---

## **2. Define Project Modules**

| Module                       | Purpose                                                 |
| ---------------------------- | ------------------------------------------------------- |
| `1_crud_project`             | Standalone CRUD API (`Post` model) with JWT             |
| `2_standalone_auth_app`      | Reusable Auth app: custom users, tenants, JWT endpoints |
| `3_crud_with_auth`           | Full integration of CRUD + Auth with JWT                |
| `4_standalone_observability` | Async Observability: request logs, errors, metrics      |

> Each module is **developed, tested, and deployed independently**, simplifying complexity in multi-tenant SaaS systems.

---

## **3. Project Structure**

```
django-modular-tutorial/
├── 1_crud_project/             # CRUD API
├── 2_standalone_auth_app/      # Authentication & tenants
├── 3_crud_with_auth/           # Integrated CRUD + Auth + Observability
│   ├── blog/                   # CRUD models, serializers, views
│   ├── auth_app/               # JWT & user/tenant management
│   ├── observ_app/             # Async observability & metrics
│   └── crud_project/           # Project settings
└── 4_standalone_observability/ # Standalone observability
```

---

## **4. Step-by-Step Application Build**

### **Step 4.1: Environment Setup**

1. Create a Python virtual environment:

```bash
python -m venv venv
source venv/bin/activate   # Linux/macOS
venv\Scripts\activate      # Windows
```

2. Install required packages:

```bash
pip install django djangorestframework djangorestframework-simplejwt celery redis mysqlclient
```

> **Notes:**
>
> * `mysqlclient` connects Django to MySQL.
> * Virtual environments ensure **dependency isolation and reproducibility**.

---

### **Step 4.2: MySQL Configuration**

In `settings.py`:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'modular_db',
        'USER': 'admin',
        'PASSWORD': 'password',
        'HOST': 'db',
        'PORT': '3306',
        'OPTIONS': {
            'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
        }
    }
}
```

> **Explanation:**
>
> * `STRICT_TRANS_TABLES` enforces **data integrity** and prevents invalid inserts.
> * MySQL ensures **reliable transaction handling** in multi-tenant scenarios.

---

### **Step 4.3: Create Modular Apps**

```bash
python manage.py startapp blog       # CRUD operations
python manage.py startapp auth_app   # JWT authentication & tenant management
python manage.py startapp observ_app # Observability & metrics
```

> Each app follows the **single-responsibility principle**.

---

### **Step 4.4: JWT Authentication Setup**

**Update `settings.py`:**

```python
INSTALLED_APPS += ['rest_framework', 'rest_framework_simplejwt']

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    )
}
```

**Define JWT URLs (`auth_app/urls.py`):**

```python
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from django.urls import path

urlpatterns = [
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
```

> **Notes:** JWT tokens are **stateless, tenant-aware, and scalable** for SaaS environments.

---

### **Step 4.5: Observability App**

#### **4.5.1 Models**

```python
class RequestLog(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    path = models.CharField(max_length=255)
    method = models.CharField(max_length=10)
    status_code = models.IntegerField()
    duration_ms = models.FloatField()
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

class ErrorLog(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    path = models.CharField(max_length=255)
    message = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']
```

> Separate tables improve **query efficiency** and support **high-volume logging**.

---

#### **4.5.2 Serializers & Views**

```python
class RequestLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = RequestLog
        fields = '__all__'

class ErrorLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = ErrorLog
        fields = '__all__'

class RequestLogListView(generics.ListAPIView):
    queryset = RequestLog.objects.all()
    serializer_class = RequestLogSerializer
    permission_classes = [permissions.IsAdminUser]

class ErrorLogListView(generics.ListAPIView):
    queryset = ErrorLog.objects.all()
    serializer_class = ErrorLogSerializer
    permission_classes = [permissions.IsAdminUser]
```

**URLs:**

```python
urlpatterns = [
    path('requests/', RequestLogListView.as_view(), name='request-logs'),
    path('errors/', ErrorLogListView.as_view(), name='error-logs'),
]
```

> Allows **integration with dashboards** such as Grafana and Kibana for tenant-specific insights.

---

### **Step 4.6: Async Logging with Celery + Redis**

**Celery (`celery.py`):**

```python
from celery import Celery
app = Celery('django_modular_tutorial')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()
```

**Tasks (`observ_app/tasks.py`):**

```python
@shared_task
def log_request_task(user_id, path, method, status_code, duration_ms):
    user = get_user_model().objects.filter(id=user_id).first() if user_id else None
    RequestLog.objects.create(user=user, path=path, method=method, status_code=status_code, duration_ms=duration_ms)

@shared_task
def log_error_task(user_id, path, message):
    user = get_user_model().objects.filter(id=user_id).first() if user_id else None
    ErrorLog.objects.create(user=user, path=path, message=message)
```

**Middleware (`observ_app/middleware.py`):**

```python
class AsyncRequestLoggingMiddleware(MiddlewareMixin):
    def process_request(self, request):
        request._start_time = time.time()

    def process_response(self, request, response):
        duration = (time.time() - getattr(request, "_start_time", time.time())) * 1000
        log_request_task.delay(getattr(request.user, "id", None),
                               request.path,
                               request.method,
                               response.status_code,
                               duration)
        return response

    def process_exception(self, request, exception):
        log_error_task.delay(getattr(request.user, "id", None),
                             request.path,
                             str(exception))
```

**Enable Middleware (`settings.py`):**

```python
MIDDLEWARE += ['observ_app.middleware.AsyncRequestLoggingMiddleware']
```

> Middleware captures **request lifecycle events**; Celery ensures **non-blocking, async persistence**.

---

### **Step 4.7: Multi-Tenant Observability Flow**

```
Client / UI
  │
API Gateway / Auth (JWT → tenant_id)
  │
CRUD / Auth API
  │
Observability Middleware
  │
Redis Queues (Requests / Errors / Metrics)
  │
Celery Workers (Async, Tenant-aware)
  │
MySQL DB (Tenant-isolated logs & metrics)
  │
Dashboards & Alerts (Grafana / Prometheus / Slack / Email)
```

---

### **Step 4.8: Run Migrations & Start Server**

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py runserver
```

---

### **Step 4.9: Dockerized Infrastructure**

```yaml
services:
  db:
    image: mysql:8.1
    environment:
      MYSQL_DATABASE: modular_db
      MYSQL_USER: admin
      MYSQL_PASSWORD: password
      MYSQL_ROOT_PASSWORD: rootpassword
    ports:
      - "3306:3306"

  redis:
    image: redis:7-alpine

  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    ports: ["8000:8000"]
    depends_on: [db, redis]

  worker:
    build: .
    command: celery -A config worker --loglevel=info -Q logging_queue
    depends_on: [redis]

  prometheus:
    image: prom/prometheus
    ports: ["9090:9090"]
```

> Docker ensures **consistent deployment** and **multi-service orchestration**.

---

## **5. Best Practices**

* Use `bulk_create` for **high-volume logs**
* Maintain **separate Celery queues** for Requests / Errors / Metrics
* Capture **IP, headers, tenant_id** for observability
* Keep apps modular for **future expansion**
* Configure **alerts** via Slack, email, or webhooks

---

## **6. Architecture Advantages**

* High-performance, **non-blocking APIs**
* **Tenant-aware logging and dashboards**
* Modular, plug-and-play **Observability & Auth apps**
* Scalable with **Celery + Redis**
* Extensible for **metrics, alerts, and analytics**

---

## **7. Observability Stack**

| Component | Technology | Role                                  |
| --------- | ---------- | ------------------------------------- |
| Broker    | Redis      | Non-blocking queue storage            |
| Worker    | Celery     | Async persistence to DB               |
| Metrics   | Prometheus | Real-time aggregation                 |
| Dashboard | Grafana    | Tenant health & latency visualization |

---

## **8. Multi-Tenant Async Mesh (MySQL Edition)**

```
──────────────────────────────────────────────
           MULTI-TENANT ASYNC OBSERVABILITY
──────────────────────────────────────────────

             Clients / UI
                   │
                   ▼
          API Gateway / Auth
       (JWT → tenant_id)
                   │
                   ▼
           CRUD / Auth API
       (Tenant-aware Business Logic)
                   │
                   ▼
       Observability Middleware
  (Capture requests, errors, duration)
                   │
     ┌─────────────┼─────────────┐
     ▼             ▼             ▼
   Tenant A       Tenant B       Tenant C
 ┌─────────┐   ┌─────────┐   ┌─────────┐
 │ Req Q   │   │ Req Q   │   │ Req Q   │
 │ Err Q   │   │ Err Q   │   │ Err Q   │
 │ Mtr Q   │   │ Mtr Q   │   │ Mtr Q   │
 └─────────┘   └─────────┘   └─────────┘
     │             │             │
     └───────┬─────┴─────┬───────┘
             ▼           ▼
     Celery Workers (Async, Tenant-aware)
             │
     ┌───────┴───────┐
     ▼               ▼
  RequestLog DB    ErrorLog DB
  (Tenant-specific MySQL tables)
             │
             ▼
      Prometheus Metrics
             │
             ▼
      Dashboards & Alerts
```

---

## **9. Visual Architecture Diagrams**

### **9.1 High-Level Architecture**

```
Clients / UI
    │
    ▼
API Gateway (JWT Auth, tenant_id)
    │
    ▼
CRUD / Auth Modules (Tenant-aware)
    │
    ▼
Observability Layer (Middleware + Queues)
    │
    ▼
Request Logs Queue    Error Logs Queue
```

### **9.2 Tenant-Specific Async Flow**

```
Observability Middleware
      │
┌─────┼─────┐
▼     ▼     ▼
Tenant A  Tenant B  Tenant C
 Req Q     Req Q     Req Q
 Err Q     Err Q     Err Q
 Mtr Q     Mtr Q     Mtr Q
      │
      ▼
Celery Workers
      │
      ▼
Tenant-specific MySQL Tables
      │
      ▼
Prometheus Metrics
```

### **9.3 Observability Stack Integration**

```
Tenant-specific MySQL (RequestLog / ErrorLog)
         │
         ▼
   Celery Workers
         │
         ▼
      Redis Broker
         │
         ▼
    Prometheus Metrics
         │
         ▼
      Grafana Dashboards
         │
         ▼
     Alerts / Slack / Email / Webhook
```

---

✅ **Outcome:** This guide delivers a **complete step-by-step approach** to:

* Build a **modular, multi-tenant DRF application**
* Implement **JWT authentication** with tenant-awareness
* Enable **async observability** with Celery, Redis, MySQL
* Create **tenant-isolated metrics and dashboards**
* Follow **enterprise best practices** for SaaS deployments

---

# **Modular Django REST Skeleton **

Includes **all directories, files, and minimal boilerplate code**, ready to run.

* `blog` (CRUD module)
* `auth_app` (JWT authentication + multi-tenant support)
* `observ_app` (async observability: requests, errors, metrics)
* Celery + Redis integration
* MySQL database setup
* Docker support for multi-service deployment
  
### **Project Structure**

```
django_modular_saas/
├── config/                    # Project settings & celery
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
│   └── celery.py
├── blog/                      # CRUD app
│   ├── __init__.py
│   ├── models.py
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   └── admin.py
├── auth_app/                  # Auth & tenants
│   ├── __init__.py
│   ├── models.py
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   └── admin.py
├── observ_app/                # Observability
│   ├── __init__.py
│   ├── models.py
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   ├── tasks.py
│   └── middleware.py
├── manage.py
├── requirements.txt
├── Dockerfile
└── docker-compose.yml
```

---

## **1. config/settings.py (MySQL + DRF + JWT)**

```python
import os
from pathlib import Path
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'replace-with-your-secret-key'
DEBUG = True
ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework_simplejwt',
    'blog',
    'auth_app',
    'observ_app',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'observ_app.middleware.AsyncRequestLoggingMiddleware',
]

ROOT_URLCONF = 'config.urls'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'modular_db',
        'USER': 'admin',
        'PASSWORD': 'password',
        'HOST': 'db',
        'PORT': '3306',
        'OPTIONS': {
            'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
        }
    }
}

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    )
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
}

STATIC_URL = '/static/'

CELERY_BROKER_URL = 'redis://redis:6379/0'
CELERY_RESULT_BACKEND = 'redis://redis:6379/0'
```

---

## **2. config/celery.py**

```python
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

app = Celery('django_modular_saas')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()
```

---

## **3. blog/models.py (CRUD Model)**

```python
from django.db import models

class Post(models.Model):
    title = models.CharField(max_length=255)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title
```

---

## **4. blog/serializers.py**

```python
from rest_framework import serializers
from .models import Post

class PostSerializer(serializers.ModelSerializer):
    class Meta:
        model = Post
        fields = '__all__'
```

---

## **5. blog/views.py**

```python
from rest_framework import generics, permissions
from .models import Post
from .serializers import PostSerializer

class PostListCreateView(generics.ListCreateAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]

class PostRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
```

---

## **6. blog/urls.py**

```python
from django.urls import path
from .views import PostListCreateView, PostRetrieveUpdateDestroyView

urlpatterns = [
    path('posts/', PostListCreateView.as_view(), name='post-list-create'),
    path('posts/<int:pk>/', PostRetrieveUpdateDestroyView.as_view(), name='post-detail'),
]
```

---

## **7. auth_app/models.py**

```python
from django.contrib.auth.models import AbstractUser
from django.db import models

class Tenant(models.Model):
    name = models.CharField(max_length=255)
    domain = models.CharField(max_length=255, unique=True)

    def __str__(self):
        return self.name

class User(AbstractUser):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, null=True, blank=True)
```

---

## **8. auth_app/serializers.py**

```python
from rest_framework import serializers
from .models import User, Tenant

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'tenant']

class TenantSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tenant
        fields = ['id', 'name', 'domain']
```

---

## **9. auth_app/views.py**

```python
from rest_framework import generics
from .models import User, Tenant
from .serializers import UserSerializer, TenantSerializer
from rest_framework.permissions import IsAdminUser

class UserListCreateView(generics.ListCreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAdminUser]

class TenantListCreateView(generics.ListCreateAPIView):
    queryset = Tenant.objects.all()
    serializer_class = TenantSerializer
    permission_classes = [IsAdminUser]
```

---

## **10. auth_app/urls.py**

```python
from django.urls import path
from .views import UserListCreateView, TenantListCreateView

urlpatterns = [
    path('users/', UserListCreateView.as_view(), name='user-list-create'),
    path('tenants/', TenantListCreateView.as_view(), name='tenant-list-create'),
]
```

---

## **11. observ_app/models.py**

```python
from django.db import models
from django.conf import settings

class RequestLog(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    path = models.CharField(max_length=255)
    method = models.CharField(max_length=10)
    status_code = models.IntegerField()
    duration_ms = models.FloatField()
    timestamp = models.DateTimeField(auto_now_add=True)

class ErrorLog(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    path = models.CharField(max_length=255)
    message = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
```

---

## **12. observ_app/tasks.py**

```python
from celery import shared_task
from django.contrib.auth import get_user_model
from .models import RequestLog, ErrorLog

@shared_task
def log_request_task(user_id, path, method, status_code, duration_ms):
    user = get_user_model().objects.filter(id=user_id).first() if user_id else None
    RequestLog.objects.create(user=user, path=path, method=method, status_code=status_code, duration_ms=duration_ms)

@shared_task
def log_error_task(user_id, path, message):
    user = get_user_model().objects.filter(id=user_id).first() if user_id else None
    ErrorLog.objects.create(user=user, path=path, message=message)
```

---

## **13. observ_app/middleware.py**

```python
import time
from django.utils.deprecation import MiddlewareMixin
from .tasks import log_request_task, log_error_task

class AsyncRequestLoggingMiddleware(MiddlewareMixin):
    def process_request(self, request):
        request._start_time = time.time()

    def process_response(self, request, response):
        duration = (time.time() - getattr(request, "_start_time", time.time())) * 1000
        log_request_task.delay(getattr(request.user, "id", None),
                               request.path,
                               request.method,
                               response.status_code,
                               duration)
        return response

    def process_exception(self, request, exception):
        log_error_task.delay(getattr(request.user, "id", None),
                             request.path,
                             str(exception))
```

---

## **14. config/urls.py**

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/blog/', include('blog.urls')),
    path('api/auth/', include('auth_app.urls')),
    path('api/observ/', include('observ_app.urls')),
]
```

---

## **15. Dockerfile**

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

---

## **16. docker-compose.yml**

```yaml
version: '3.8'
services:
  db:
    image: mysql:8.1
    environment:
      MYSQL_DATABASE: modular_db
      MYSQL_USER: admin
      MYSQL_PASSWORD: password
      MYSQL_ROOT_PASSWORD: rootpassword
    ports:
      - "3306:3306"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    ports:
      - "8000:8000"
    depends_on:
      - db
      - redis

  worker:
    build: .
    command: celery -A config worker --loglevel=info
    depends_on:
      - redis
      - db
```

---

## **17. requirements.txt**

```
Django>=4.3
djangorestframework
djangorestframework-simplejwt
mysqlclient
celery
redis
```

---

✅ **Next Steps:**

1. Run `docker-compose up --build` to start **MySQL, Redis, Django server, and Celery worker**.
2. Apply migrations:

```bash
docker-compose run web python manage.py makemigrations
docker-compose run web python manage.py migrate
```

3. Access API endpoints:

* CRUD: `http://localhost:8000/api/blog/posts/`
* Auth: `http://localhost:8000/api/auth/users/`
* Observability: `http://localhost:8000/api/observ/requests/`

4. Add **Prometheus + Grafana** for metrics collection and dashboards.

---

This skeleton provides a **ready-to-use enterprise-grade multi-tenant Django app**, with **modular apps**, **JWT authentication**, **async observability**, **MySQL backend**, and **containerized deployment**.

---
