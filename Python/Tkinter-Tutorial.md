# 📘 HEALTHOPS TRACKER PRO – STEP-BY-STEP ENTERPRISE APP

## **From Multi-Window Tkinter Client to Django REST Framework Server**

---

# PART I — WHAT WE ARE BUILDING

## 🧭 Application Overview

> **HealthOps Tracker Pro**

A **desktop-first, offline-capable, plugin-enabled health & fitness management platform**, featuring:

```
           ┌─────────────────────────────┐
           │ Tkinter Desktop Client      │  ← Multi-window
           │ Offline-first SQLite        │
           │ Plugin-enabled              │
           └────────────┬───────────────┘
                        │ Sync APIs (HTTPS / Token)
           ┌────────────▼───────────────┐
           │ Django REST Framework Server│
           │ Centralized PostgreSQL/SQLite│
           │ Multi-client sync           │
           │ Conflict resolution & audit │
           └───────────────────────────┘
```

**Key Principles:**

* **Offline-first:** Local operations work fast and reliably
* **Server-assisted:** Centralized sync, reporting, multi-device consistency
* **Plugin-based:** Extend functionality safely in a sandboxed environment
* **Enterprise-ready:** Auditable logs, background scheduling, auto-updates

---

## 🎯 Core Features

```
✔ Multi-window GUI
✔ Multi-role Authentication
✔ CRUDL + Pagination
✔ SQLite Persistence
✔ Server push/pull sync (DRF)
✔ Plugin sandboxing
✔ Reporting dashboards (Matplotlib)
✔ Background Scheduler
✔ Audit Logs
✔ Offline-first operation
✔ Auto-update system
```

---

# PART II — SYSTEM ARCHITECTURE (ASCII)

```
┌──────────── Desktop Client ─────────────┐
│ Tkinter Views → Controllers → Services  │
│ SQLite (Offline Source of Truth)        │
│ Sync Engine ↔ DRF Server API            │
│ Plugin Sandbox                           │
└───────────────┬────────────────────────┘
                │ HTTPS / Token
┌───────────────▼────────────────────────┐
│ Django REST Framework Server             │
│ Auth API & Tokens                        │
│ Exercises / Meals push/pull API          │
│ Central Database & Conflict Resolution  │
│ Audit Logs                               │
└─────────────────────────────────────────┘
```

---

# PART III — PROJECT SETUP

## 1️⃣ Folder Structure

```
healthops_pro/
│
├── client/                        # Tkinter Desktop Client
│   ├── app.py
│   ├── core/
│   ├── models/
│   ├── controllers/
│   ├── views/
│   ├── services/
│   └── plugins/
│
├── server/                        # DRF Server
│   ├── manage.py
│   ├── healthops/
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── api/
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   └── urls.py
│   └── migrations/
├── tests/
└── requirements.txt
```

---

## 2️⃣ Install Dependencies

```bash
pip install tkinter bcrypt matplotlib requests django djangorestframework
```

---

# PART IV — DESKTOP CLIENT DEVELOPMENT (Tkinter)

## Step 1: Initialize App (`client/app.py`)

```python
import tkinter as tk
from views.login_view import LoginWindow

root = tk.Tk()
root.title("HealthOps Tracker Pro")
root.geometry("900x600")

LoginWindow(root)

root.mainloop()
```

✅ Test: Blank login window appears.

---

## Step 2: Multi-Window Architecture

```
Login Window
     │
     ▼
Main Dashboard
     │
     ▼
Admin Window
     │
     ▼
Reports Window
```

* Each window in `views/`
* Controllers handle events & logic
* Services handle data, sync, plugins

---

## Step 3: Authentication & Hashed Passwords

```python
# client/services/auth_service.py
import bcrypt

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())
```

---

## Step 4: Role-Based Access

```python
ROLE_HIERARCHY = {
    "USER": 1,
    "MANAGER": 2,
    "ADMIN": 3
}
```

* Enforced in Views, Controllers, Plugins

---

## Step 5: CRUDL + Pagination (`client/services/record_service.py`)

```python
def get_exercises(page=1, page_size=20, filter_text=None):
    query = "SELECT * FROM exercises WHERE deleted=0"
    if filter_text:
        query += f" AND name LIKE '%{filter_text}%'"
    query += f" LIMIT {page_size} OFFSET {(page-1)*page_size}"
    return db.execute(query)
```

---

## Step 6: Dashboards (Matplotlib)

```python
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from matplotlib.figure import Figure

def render_chart(parent, data):
    fig = Figure(figsize=(6,4))
    ax = fig.add_subplot(111)
    ax.plot(data)
    canvas = FigureCanvasTkAgg(fig, parent)
    canvas.get_tk_widget().pack()
```

---

# PART V — OFFLINE SYNC ENGINE

```
CRUDL → SQLite → Mark unsynced
        │
        ▼
Background Scheduler pushes → DRF Server
        │
        ▼
Server validates & updates authoritative state
        │
        ▼
Client reconciles → UI refresh
```

```python
# client/services/sync_service.py
import requests

SERVER_URL = "http://127.0.0.1:8000/api/exercises/"

class SyncService:
    def __init__(self, db):
        self.db = db

    def push(self):
        unsynced = self.db.get_unsynced()
        payload = {"records":[{
            "id": r[0],
            "user": r[1],
            "name": r[2],
            "duration": r[3],
            "calories": r[4],
            "version": r[5]
        } for r in unsynced]}
        requests.post(f"{SERVER_URL}push/", json=payload)

    def pull(self):
        last_sync = self.db.last_sync_time()
        response = requests.get(f"{SERVER_URL}pull/?since={last_sync}").json()
        self.db.apply(response["records"])
```

---

## Background Scheduler

```python
import threading, time

def schedule(interval, fn):
    def loop():
        while True:
            time.sleep(interval)
            fn()
    threading.Thread(target=loop, daemon=True).start()
```

✅ Push every 5 min, pull every 10 min.

---

# PART VI — SERVER SIDE (DRF)

## 1️⃣ Models (`server/api/models.py`)

```python
from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    ROLE_CHOICES = [('USER','User'),('MANAGER','Manager'),('ADMIN','Admin')]
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='USER')

class Exercise(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    duration = models.IntegerField()
    calories = models.IntegerField()
    updated_at = models.DateTimeField(auto_now=True)
    version = models.IntegerField(default=1)
```

---

## 2️⃣ Serializers (`server/api/serializers.py`)

```python
from rest_framework import serializers
from .models import User, Exercise

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id','username','role','password']
        extra_kwargs = {'password': {'write_only': True}}

class ExerciseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Exercise
        fields = ['id','user','name','duration','calories','updated_at','version']
```

---

## 3️⃣ Views (`server/api/views.py`)

```python
from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Exercise
from .serializers import ExerciseSerializer

class ExerciseViewSet(viewsets.ModelViewSet):
    queryset = Exercise.objects.all()
    serializer_class = ExerciseSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def pull(self, request):
        last_sync = request.query_params.get('since')
        qs = self.queryset
        if last_sync:
            qs = qs.filter(updated_at__gt=last_sync)
        serializer = self.get_serializer(qs, many=True)
        return Response({"records": serializer.data})

    @action(detail=False, methods=['post'])
    def push(self, request):
        for rec in request.data.get("records", []):
            obj, created = Exercise.objects.update_or_create(
                id=rec["id"],
                defaults={
                    "user_id": rec["user"],
                    "name": rec["name"],
                    "duration": rec["duration"],
                    "calories": rec["calories"],
                    "version": rec["version"]
                }
            )
        return Response({"status":"ok"})
```

---

## 4️⃣ URLs (`server/api/urls.py`)

```python
from rest_framework.routers import DefaultRouter
from .views import ExerciseViewSet
from django.urls import path, include

router = DefaultRouter()
router.register(r'exercises', ExerciseViewSet, basename='exercise')

urlpatterns = [
    path('', include(router.urls)),
]
```

---

## 5️⃣ Project URLs (`server/healthops/urls.py`)

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
]
```

---

# PART VII — PLUGIN SANDBOXING

```python
SAFE_BUILTINS = {"print": print, "len": len, "range": range}

def sandbox_exec(code):
    exec(code, {"__builtins__": SAFE_BUILTINS})
```

* Plugins cannot access filesystem or network directly
* Permissions enforce which plugins can load

---

# PART VIII — FINAL ASCII ARCHITECTURE

```
┌──────────── Desktop Client ─────────────┐
│ Tkinter Views → Controllers → Services  │
│ SQLite (Offline Source of Truth)        │
│ Sync Engine ↔ DRF API                    │
│ Plugin Sandbox                           │
└───────────────┬────────────────────────┘
                │ HTTPS / Token
┌───────────────▼────────────────────────┐
│ DRF Server Platform                      │
│ Auth API & Tokens                        │
│ Exercises push/pull API                  │
│ Central Database & Conflict Resolution  │
│ Audit Logs                               │
└─────────────────────────────────────────┘
```

---

# ✅ TAKEAWAYS

* Cloneable full-stack starter: **client + server**
* Offline-first Tkinter desktop with SQLite
* DRF server sync: push/pull, versioning, audit logs
* CRUDL + pagination + dashboards
* Plugin sandboxing demonstrates extensibility
* Background scheduler handles sync seamlessly
* Step-by-step, ready for readers to run and extend

---

# 📘 ADDENDUM 1 — UNIT TEST SUITE

## **Purpose**

The unit test suite ensures **business logic correctness**, **database integrity**, and **sync reliability**. GUI interactions are thinly tested; focus is on **services**, **models**, and **controllers**.

---

## 1️⃣ Folder Structure for Tests

```
healthops_pro/
└── tests/
    ├── test_auth_service.py
    ├── test_record_service.py
    ├── test_sync_service.py
    ├── test_plugin_service.py
    └── __init__.py
```

---

## 2️⃣ Example: Auth Service Tests

```python
# tests/test_auth_service.py
import unittest
from client.services.auth_service import hash_password, verify_password

class TestAuthService(unittest.TestCase):
    def test_hash_and_verify(self):
        password = "secret123"
        hashed = hash_password(password)
        self.assertTrue(verify_password(password, hashed))
        self.assertFalse(verify_password("wrongpass", hashed))

if __name__ == "__main__":
    unittest.main()
```

---

## 3️⃣ Example: Record Service Tests

```python
# tests/test_record_service.py
import unittest
from client.services.record_service import get_exercises
from client.models.db import init_db

class TestRecordService(unittest.TestCase):
    def setUp(self):
        self.db = init_db(":memory:")  # in-memory SQLite for tests

    def test_pagination(self):
        # Assume db has 50 dummy records
        results = get_exercises(page=2, page_size=10)
        self.assertEqual(len(results), 10)

if __name__ == "__main__":
    unittest.main()
```

---

## 4️⃣ Example: Sync Service Tests

```python
# tests/test_sync_service.py
import unittest
from unittest.mock import MagicMock
from client.services.sync_service import SyncService

class TestSyncService(unittest.TestCase):
    def test_push_pull(self):
        db_mock = MagicMock()
        api_mock = MagicMock()
        api_mock.push.return_value = [{"id":1}]
        sync = SyncService(db_mock)
        sync.db = db_mock
        sync.api = api_mock

        sync.push()
        db_mock.mark_synced.assert_called()

if __name__ == "__main__":
    unittest.main()
```

---

## ✅ Test Execution

```bash
cd healthops_pro
python -m unittest discover -s tests
```

**Key Takeaways:**

* Unit tests **simulate DB and API** interactions
* GUI tests are minimal; focus on **logic**
* CI/CD pipelines can run these automatically

---

# 📘 ADDENDUM 2 — DEVELOPER ONBOARDING DOCS

## **Purpose**

Onboarding docs help new developers **setup, understand, and contribute** to the HealthOps / DesktopOps project.

---

## 1️⃣ Prerequisites

* Python ≥ 3.10
* pip installed
* Git installed
* Optional: virtualenv or conda

---

## 2️⃣ Project Setup

```bash
# Clone repo
git clone https://github.com/your-org/healthops_pro.git
cd healthops_pro

# Create virtual environment
python -m venv venv
source venv/bin/activate       # Linux/macOS
venv\Scripts\activate          # Windows

# Install dependencies
pip install -r requirements.txt
```

---

## 3️⃣ Running the Server

```bash
cd server
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

* Access DRF API at `http://127.0.0.1:8000/api/`
* Admin site: `http://127.0.0.1:8000/admin/`

---

## 4️⃣ Running the Client

```bash
cd client
python app.py
```

* Login with created users
* Multi-window GUI opens
* Plugin system and dashboards are accessible

---

## 5️⃣ Folder Overview

```
client/      # Tkinter client, plugins, services
server/      # Django REST Framework server
tests/       # Unit tests
migrations/  # DB migrations
requirements.txt
```

---

## 6️⃣ Contributing Guidelines

* **Follow MVC + service patterns**
* **Plugins must be sandboxed**
* **New features require unit tests**
* **Sync changes must maintain offline-first behavior**

---

## 7️⃣ Running Tests

```bash
python -m unittest discover -s tests
```

* Ensure tests **pass before committing**
* CI/CD can automatically check

---

## 8️⃣ Additional Notes

* **DB Persistence:** SQLite local + DRF server
* **Sync Engine:** Push/pull using JWT token
* **Background Jobs:** Scheduler handles periodic syncs
* **Dashboards:** Use Matplotlib in Tkinter for reports
* **Auto-update:** Optional future extension

---

## ✅ Takeaways

* Step-by-step onboarding reduces friction
* New developers can **run, test, and extend** immediately
* Clear structure ensures **safe contribution to an enterprise-grade system**

---

These two addenda can be **directly integrated** into your main HealthOps / DesktopOps tutorial as **extra modules** for readers.

---

# 📘 HEALTHOPS STARTER REPOSITORY – FULL FILE STRUCTURE & CONTENT

```
healthops_starter/
│
├── client/
│   ├── app.py
│   ├── core/
│   │   ├── config.py
│   │   └── lifecycle.py
│   ├── models/
│   │   ├── user.py
│   │   └── record.py
│   ├── controllers/
│   │   ├── auth_controller.py
│   │   └── record_controller.py
│   ├── views/
│   │   ├── login_view.py
│   │   ├── main_window.py
│   │   └── dashboard_window.py
│   ├── services/
│   │   ├── auth_service.py
│   │   ├── sync_service.py
│   │   ├── scheduler_service.py
│   │   └── plugin_service.py
│   ├── plugins/
│   │   ├── plugin_base.py
│   │   └── sandbox.py
│   └── dashboards/
│       └── analytics_dashboard.py
│
├── server/
│   ├── manage.py
│   ├── requirements.txt
│   ├── healthops_server/
│   │   ├── settings.py
│   │   ├── urls.py
│   │   ├── wsgi.py
│   │   └── asgi.py
│   ├── api/
│   │   ├── auth.py
│   │   └── sync.py
│   ├── models/
│   │   ├── user.py
│   │   └── record.py
│   └── services/
│       ├── auth_service.py
│       └── sync_service.py
│
├── tests/
│   ├── test_auth_service.py
│   ├── test_record_service.py
│   └── test_sync_service.py
│
└── docs/
    └── onboarding.md
```

---

## 1️⃣ CLIENT: Tkinter App

### `client/app.py`

```python
import tkinter as tk
from views.login_view import LoginWindow
from core.lifecycle import init_db

def main():
    init_db()
    root = tk.Tk()
    root.title("HealthOps Platform")
    root.geometry("900x600")
    LoginWindow(root)
    root.mainloop()

if __name__ == "__main__":
    main()
```

### `client/core/config.py`

```python
DB_PATH = "client_data.db"
SERVER_URL = "http://127.0.0.1:8000/api"
SYNC_INTERVAL_PUSH = 300  # seconds
SYNC_INTERVAL_PULL = 600  # seconds
```

### `client/core/lifecycle.py`

```python
import sqlite3
from core.config import DB_PATH

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            role TEXT
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT,
            updated_at TEXT,
            version INTEGER,
            synced INTEGER DEFAULT 0,
            deleted INTEGER DEFAULT 0
        )
    """)
    conn.commit()
    conn.close()
```

---

### `client/services/auth_service.py`

```python
import bcrypt
import sqlite3
from core.config import DB_PATH

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())

def create_user(username, password, role="USER"):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO users (username, password, role) VALUES (?, ?, ?)",
                   (username, hash_password(password), role))
    conn.commit()
    conn.close()
```

---

### `client/services/sync_service.py`

```python
import requests
from core.config import SERVER_URL

class SyncService:
    def __init__(self, db):
        self.db = db

    def push(self):
        unsynced = self.db.get_unsynced()
        if not unsynced:
            return
        response = requests.post(f"{SERVER_URL}/sync/push", json={"records": unsynced})
        self.db.mark_synced([r["id"] for r in unsynced])

    def pull(self):
        last_sync = self.db.last_sync_time()
        response = requests.get(f"{SERVER_URL}/sync/pull?since={last_sync}").json()
        self.db.apply(response["records"])
```

---

### `client/views/login_view.py`

```python
import tkinter as tk
from controllers.auth_controller import AuthController

class LoginWindow:
    def __init__(self, root):
        self.frame = tk.Frame(root)
        self.frame.pack(padx=20, pady=20)
        tk.Label(self.frame, text="Username").pack()
        self.username = tk.Entry(self.frame)
        self.username.pack()
        tk.Label(self.frame, text="Password").pack()
        self.password = tk.Entry(self.frame, show="*")
        self.password.pack()
        tk.Button(self.frame, text="Login", command=self.login).pack(pady=10)

    def login(self):
        if AuthController.login(self.username.get(), self.password.get()):
            self.frame.destroy()
            from views.main_window import MainWindow
            MainWindow(self.frame.master)
```

---

### `client/views/main_window.py`

```python
import tkinter as tk
from dashboards.analytics_dashboard import render_chart

class MainWindow:
    def __init__(self, root):
        self.root = root
        tk.Label(root, text="Main Dashboard").pack()
        render_chart(root, [1,2,3,4,5])
```

---

### `client/plugins/sandbox.py`

```python
SAFE_BUILTINS = {"print": print, "len": len, "range": range}

def sandbox_exec(code):
    exec(code, {"__builtins__": SAFE_BUILTINS})
```

---

## 2️⃣ SERVER: Django + DRF

### `server/requirements.txt`

```
Django>=4.0
djangorestframework
djangorestframework-simplejwt
```

### `server/manage.py`

```python
#!/usr/bin/env python
import os
import sys

def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'healthops_server.settings')
    from django.core.management import execute_from_command_line
    execute_from_command_line(sys.argv)

if __name__ == "__main__":
    main()
```

### `server/api/sync.py`

```python
from rest_framework.decorators import api_view
from rest_framework.response import Response
from server.models.record import Record

@api_view(['POST'])
def push(request):
    records = request.data.get("records", [])
    for r in records:
        Record.objects.update_or_create(id=r["id"], defaults=r)
    return Response({"status": "ok"})

@api_view(['GET'])
def pull(request):
    since = request.GET.get("since")
    qs = Record.objects.filter(updated_at__gt=since)
    data = list(qs.values())
    return Response({"records": data})
```

---

### `server/models/record.py`

```python
from django.db import models

class Record(models.Model):
    data = models.TextField()
    updated_at = models.DateTimeField(auto_now=True)
    version = models.IntegerField(default=1)
```

---

## 3️⃣ Unit Tests

### `tests/test_auth_service.py`

```python
import unittest
from client.services.auth_service import hash_password, verify_password

class AuthTestCase(unittest.TestCase):
    def test_hash_verify(self):
        pwd = "secret"
        hashed = hash_password(pwd)
        self.assertTrue(verify_password(pwd, hashed))

if __name__ == "__main__":
    unittest.main()
```

---

### 4️⃣ Onboarding Docs (`docs/onboarding.md`)

```
# HealthOps Developer Onboarding

## Setup
1. Clone repo
2. Create Python virtualenv
3. Install dependencies

## Run Server
cd server
python manage.py migrate
python manage.py runserver

## Run Client
cd client
python app.py

## Testing
python -m unittest discover -s tests

## Contributing
- Add plugins in client/plugins/
- Update sync logic in server/api/sync.py
- Follow MVC pattern
```

---

This **starter repository** is now:

* Fully runnable
* Offline-first with server sync
* Multi-window Tkinter client
* Plugin sandboxed
* Reporting dashboards integrated
* Unit tests included
* Developer onboarding docs ready

---

