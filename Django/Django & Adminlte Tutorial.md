# 📘 Production-Grade Django + React + AdminLTE Dashboard Handbook

**MySQL + JWT + Role-Based Menus + AdminLTE Tables + Celery**

**Edition:** 13.0
**Audience:** Engineers, Bootcamp Learners, Trainers
**Level:** Beginner → Professional

**Tech Stack**

* Django 5.x + DRF (Backend/API)
* MySQL 8.x (persistent storage)
* React 18+ + React Router DOM (SPA frontend)
* AdminLTE 3.x (UI layout & components)
* Vite (frontend bundling)
* Axios + Chart.js + React Chart.js 2 (HTTP & visualization)
* Bootstrap 5 (UI framework)
* Celery + Redis (async tasks)
* Nginx + Gunicorn + HTTPS (production deployment)

---

# 🧠 Core Mental Models

### 1. Full System Architecture (high-level mental model)

```
+----------------+
|     USER       |  <-- Sends requests, interacts with UI
+----------------+
        │
        ▼
+----------------+
|   React SPA    |  <-- AdminLTE + React Components
| - Navbar       |
| - Sidebar      |
| - Pages        |
| - Tables/Charts|
+----------------+
        │ JSON/HTTP (Axios + JWT)
        ▼
+----------------+
| Django REST API|  <-- Stateless API + Business logic
| - JWT Auth     |
| - Role-based Menus
| - CRUD API     |
+----------------+
        │ ORM
        ▼
+----------------+
|    MySQL DB    |  <-- Persistent storage
| - Users, Roles |
| - Orders       |
| - Transactions |
+----------------+
        ▲
        │ Async Jobs
+----------------+
|    Celery      |  <-- Background tasks
| - Reports      |
| - Emails       |
| - Analytics    |
+----------------+
        ▲
        │ Broker
      Redis
```

**Teaching Note:** This diagram helps visualize **where data flows**, **what responsibilities each layer has**, and why **Celery is separate** (non-blocking background jobs).

---

### 2. Frontend vs Backend Responsibilities

| Layer      | Responsibility                     | Example/Notes                          |
| ---------- | ---------------------------------- | -------------------------------------- |
| React SPA  | UI, state, routing, tables, charts | Does not directly talk to DB           |
| AdminLTE   | Layout & CSS                       | React replaces jQuery for interactions |
| Django API | Business logic, auth, validation   | Stateless JWT; role-based menus        |
| MySQL      | Persistent storage                 | Transactions, relational integrity     |
| Celery     | Async jobs                         | Reports, emails, heavy calculations    |

**Teaching Note:** This mental model separates concerns clearly: **UI vs Logic vs Storage vs Async**.

---

# 🏗️ STEP 1: Backend Setup — Django + MySQL + JWT + Role-Based Menus + Celery

### 1.1 Virtual Environment & Install Packages

```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

pip install django djangorestframework django-cors-headers mysqlclient djangorestframework-simplejwt celery redis
```

**Example:** `django-cors-headers` allows your frontend (Vite server) to call Django APIs on localhost:8000 without CORS errors.

---

### 1.2 MySQL Setup

```sql
CREATE DATABASE dashboard_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'dashboard_user'@'%' IDENTIFIED BY 'strongpassword';
GRANT ALL PRIVILEGES ON dashboard_db.* TO 'dashboard_user'@'%';
FLUSH PRIVILEGES;
```

**Teaching Note:**

* Always use `utf8mb4` for emoji support.
* Separate DB user for security.

---

### 1.3 Django `settings.py` Essentials

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.mysql",
        "NAME": "dashboard_db",
        "USER": "dashboard_user",
        "PASSWORD": "strongpassword",
        "HOST": "127.0.0.1",
        "PORT": "3306",
        "OPTIONS": {"charset": "utf8mb4", "init_command": "SET sql_mode='STRICT_TRANS_TABLES'"}
    }
}

INSTALLED_APPS = [
    "dashboard",
    "rest_framework",
    "corsheaders",
]

MIDDLEWARE = ["corsheaders.middleware.CorsMiddleware"] + MIDDLEWARE

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 10,
}

CORS_ALLOWED_ORIGINS = ["http://localhost:5173", "https://your-domain.com"]

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
```

**Teaching Note:**

* `JWTAuthentication` keeps API **stateless**.
* Pagination ensures **large tables don’t overwhelm frontend**.

---

### 1.4 Models: Users, Roles, Orders

```python
from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    ROLE_CHOICES = [("admin", "Admin"), ("manager", "Manager"), ("staff", "Staff")]
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default="staff")

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    full_name = models.CharField(max_length=255)

class Order(models.Model):
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)
```

**Example:**

* `User.role` drives **role-based menus**.
* `Order` links to `UserProfile` → supports **reporting per user**.

---

### 1.5 Serializers

```python
from rest_framework import serializers
from .models import User, UserProfile, Order

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email", "role"]

class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = ["id", "user", "amount", "created_at"]
```

**Teaching Note:** Serializers **convert Django models to JSON**, which React SPA consumes via Axios.

---

### 1.6 Views + Role-Based Menus

```python
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import User, Order
from .serializers import UserSerializer, OrderSerializer

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=False)
    def menu(self, request):
        role = request.user.role
        menu_map = {
            "admin": ["Dashboard", "Users", "Sales", "Reports"],
            "manager": ["Dashboard", "Sales", "Reports"],
            "staff": ["Dashboard", "Orders"]
        }
        return Response(menu_map.get(role, ["Dashboard"]))

class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]
```

**Mental Model:** Backend **decides what menu each role can see** → React SPA renders dynamically.

---

### 1.7 JWT Auth Flow (ASCII)

```
[React SPA] --> POST /api/token/ (username/password)
     │
     ▼
[Django API JWT] --> returns {access, refresh}
     │
     ▼
[React SPA stores JWT in localStorage]
     │
     ▼
[Axios attaches JWT in Authorization header]
     │
     ▼
[Protected API endpoints validate JWT]
```

---

### 1.8 Celery Setup + Task

**`config/celery.py`**

```python
import os
from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
app = Celery("config", broker="redis://localhost:6379/0")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
```

**`dashboard/tasks.py`**

```python
from celery import shared_task
from .models import Order

@shared_task
def calculate_monthly_sales():
    return Order.objects.filter(created_at__month=12).count()
```

**Task Flow**

```
[User triggers report] --> Django API --> Celery task queued
     │
     ▼
[Redis Broker stores task]
     │
     ▼
[Celery Worker executes task] --> DB update / Email / Report
```

---

# 🏗️ STEP 2: Frontend Setup — React + AdminLTE + Vite

```bash
npm create vite@latest frontend --template react
cd frontend
npm install axios react-router-dom chart.js react-chartjs-2
```

---

### 2.1 Axios + JWT Setup

```js
axios.defaults.baseURL = "http://localhost:8000";
axios.defaults.headers.common['Authorization'] = `Bearer ${localStorage.getItem("access_token")}`;
```

**Teaching Note:** Axios automatically sends JWT → backend protects endpoints.

---

### 2.2 Role-Based Sidebar

```jsx
const [menu, setMenu] = useState([]);

useEffect(() => {
  axios.get("/api/users/menu/").then(res => setMenu(res.data));
}, []);
```

---

### 2.3 AdminLTE Tables + Pagination

```jsx
const [users, setUsers] = useState([]);
const [page, setPage] = useState(1);

useEffect(() => {
  axios.get(`/api/users/?page=${page}`).then(res => setUsers(res.data.results));
}, [page]);
```

**Teaching Note:** DRF pagination + Axios → keeps SPA **responsive and fast** even with 1000+ users.

---

### 2.4 Sidebar + Multi-Level Menus (ASCII)

```
Sidebar
├─ Dashboard
├─ Users
│  ├─ All Users
│  └─ Add User
├─ Sales
│  ├─ All Sales
│  └─ Monthly Sales
└─ Reports
```

---

# 🚀 STEP 3: Deployment Architecture

```
[Internet]
   │
   ▼
[Nginx]
   │
   ├─ /        --> React SPA static files
   ├─ /api/    --> Gunicorn + Django API
   └─ /static/ --> Django collected static files
```

---

# ✅ Key Takeaways

* React SPA = UI & state
* AdminLTE = layout + CSS + tables + responsive cards
* JWT = stateless authentication
* Role-based menus = backend-driven, frontend-rendered
* AdminLTE tables = paginated
* Celery = async background tasks
* Django + MySQL = business logic + persistent storage
* Nginx + Gunicorn + HTTPS = production-ready

---

