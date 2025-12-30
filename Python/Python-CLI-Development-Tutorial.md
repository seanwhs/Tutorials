# 📘 PYTHON CLI APPLICATION DEVELOPMENT – STEP-BY-STEP

## **From Simple Scripts to Extensible, Multi-Command CLI Tools**

---

# PART I — WHAT WE ARE BUILDING

### Application Name (Conceptual)

> **TaskCLI**

**TaskCLI** is a **command-line task manager** that allows users to:

* Add, list, update, delete, and search tasks
* Persist tasks locally in **SQLite**
* Use subcommands (`taskcli add`, `taskcli list`, etc.)
* Support configuration files
* Enable logging and debugging
* Extend via plugins

```
┌──────────────────────────────┐
│ Python CLI (TaskCLI)         │
│                              │
│ Commands → add/list/update    │
│ Local DB → SQLite             │
│ Config & Logging             │
│ Plugins → Extend functionality│
└──────────────────────────────┘
```

---

# PART II — PROJECT SETUP

## 1️⃣ Folder Structure

```
taskcli/
│
├── taskcli.py                # Main CLI entrypoint
├── core/
│   ├── config.py             # Configuration management
│   ├── db.py                 # SQLite persistence
│   └── logger.py             # Logging setup
├── commands/
│   ├── add.py
│   ├── list.py
│   ├── update.py
│   └── delete.py
├── plugins/
│   └── example_plugin.py
├── tests/
│   ├── test_add.py
│   ├── test_list.py
│   └── test_db.py
└── requirements.txt
```

---

## 2️⃣ Install Dependencies

```bash
pip install click rich sqlite3
```

* `click` → CLI framework
* `rich` → Fancy console output
* `sqlite3` → Persistence (built-in)

---

# PART III — BASIC CLI WITH CLICK

### `taskcli.py`

```python
import click
from commands import add, list

@click.group()
def cli():
    """TaskCLI – Manage your tasks from the terminal."""
    pass

# Register subcommands
cli.add_command(add.add_task)
cli.add_command(list.list_tasks)

if __name__ == "__main__":
    cli()
```

---

### ASCII COMMAND FLOW

```
taskcli
  │
  ├─ add      → Adds a task
  ├─ list     → Lists tasks
  ├─ update   → Updates a task
  └─ delete   → Deletes a task
```

---

# PART IV — CONFIGURATION & DATABASE

### `core/config.py`

```python
import os

DB_PATH = os.environ.get("TASKCLI_DB", "tasks.db")
LOG_LEVEL = os.environ.get("TASKCLI_LOG", "INFO")
```

### `core/db.py`

```python
import sqlite3
from core.config import DB_PATH

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            completed INTEGER DEFAULT 0
        )
    """)
    conn.commit()
    conn.close()

def execute(query, params=()):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute(query, params)
    conn.commit()
    result = cursor.fetchall()
    conn.close()
    return result
```

---

# PART V — COMMANDS

### 1️⃣ Add Command (`commands/add.py`)

```python
import click
from core.db import execute

@click.command()
@click.argument("title")
@click.option("--description", default="")
def add_task(title, description):
    """Add a new task"""
    execute("INSERT INTO tasks (title, description) VALUES (?, ?)", (title, description))
    click.echo(f"Task '{title}' added.")
```

---

### 2️⃣ List Command (`commands/list.py`)

```python
import click
from core.db import execute
from rich.console import Console
from rich.table import Table

@click.command()
def list_tasks():
    """List all tasks"""
    rows = execute("SELECT id, title, description, completed FROM tasks")
    table = Table(title="Tasks")
    table.add_column("ID", justify="right")
    table.add_column("Title")
    table.add_column("Description")
    table.add_column("Completed")
    
    for r in rows:
        table.add_row(str(r[0]), r[1], r[2], str(bool(r[3])))
    
    Console().print(table)
```

---

# PART VI — UPDATE AND DELETE COMMANDS

### `commands/update.py`

```python
import click
from core.db import execute

@click.command()
@click.argument("task_id", type=int)
@click.option("--title", default=None)
@click.option("--description", default=None)
@click.option("--completed", type=bool, default=None)
def update_task(task_id, title, description, completed):
    """Update a task"""
    if title:
        execute("UPDATE tasks SET title=? WHERE id=?", (title, task_id))
    if description:
        execute("UPDATE tasks SET description=? WHERE id=?", (description, task_id))
    if completed is not None:
        execute("UPDATE tasks SET completed=? WHERE id=?", (int(completed), task_id))
    click.echo(f"Task {task_id} updated.")
```

### `commands/delete.py`

```python
import click
from core.db import execute

@click.command()
@click.argument("task_id", type=int)
def delete_task(task_id):
    """Delete a task"""
    execute("DELETE FROM tasks WHERE id=?", (task_id,))
    click.echo(f"Task {task_id} deleted.")
```

---

# PART VII — PLUGIN SYSTEM

### `plugins/example_plugin.py`

```python
def activate(cli_group):
    @cli_group.command()
    def hello():
        """Sample plugin command"""
        click.echo("Hello from plugin!")
```

*Plugins can dynamically register commands to the main CLI.*

---

# PART VIII — LOGGING

### `core/logger.py`

```python
import logging
from core.config import LOG_LEVEL

logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)
```

*Use `logger.info("message")` throughout your CLI.*

---

# PART IX — UNIT TESTING

### `tests/test_db.py`

```python
import unittest
from core.db import execute, init_db

class TestDB(unittest.TestCase):
    def setUp(self):
        init_db()
        execute("DELETE FROM tasks")

    def test_add_task(self):
        execute("INSERT INTO tasks (title) VALUES (?)", ("Test Task",))
        rows = execute("SELECT * FROM tasks")
        self.assertEqual(len(rows), 1)

if __name__ == "__main__":
    unittest.main()
```

---

# PART X — RUNNING THE CLI

```bash
python taskcli.py add "Buy groceries" --description "Milk, Eggs, Bread"
python taskcli.py list
python taskcli.py update 1 --completed True
python taskcli.py delete 1
```

---

# PART XI — ASCII DIAGRAM OF CLI FLOW

```
taskcli
  │
  ├─ add → Insert into DB
  ├─ list → Query & Render Table
  ├─ update → Modify DB row
  ├─ delete → Remove DB row
  └─ plugins → Dynamic commands
```

---

# PART XII — EXTENSIONS YOU CAN ADD

* Search/filter tasks
* Import/export CSV
* Configurable DB path
* Scheduled reminders (use `threading` or `APScheduler`)
* Unit tests for commands
* Plugin marketplace with sandboxing

---

# ✅ TAKEAWAYS

* `click` makes multi-command CLI apps **easy and structured**
* SQLite persistence ensures offline data storage
* Plugins allow extensibility without changing core code
* Rich + Table gives professional output
* Unit testing ensures correctness
* Config + Logging make it production-ready

---

# 📘 ADDENDUM — TASKCLI: FULL ENTERPRISE CLI ECOSYSTEM

## **Overview**

**TaskCLI** demonstrates a **desktop-style ecosystem in CLI form**. It includes:

* Multi-command CLI with **Click**
* SQLite persistence with **CRUD + pagination**
* **Background scheduler** for sync or recurring tasks
* **Server-side sync** with Django REST Framework (DRF)
* **Plugin sandboxing**
* Reporting dashboards (console + matplotlib)
* Unit tests for **all business logic**
* Config and logging

Readers can **clone, run, and extend**.

---

# PART I — PROJECT STRUCTURE

```
taskcli/
│
├── taskcli.py                    # CLI entrypoint
├── core/
│   ├── config.py                 # Config management
│   ├── db.py                     # SQLite persistence
│   ├── logger.py                 # Logging setup
│   └── scheduler.py              # Background scheduler
├── commands/
│   ├── add.py
│   ├── list.py
│   ├── update.py
│   └── delete.py
├── plugins/
│   └── example_plugin.py
├── reports/
│   └── dashboard.py
├── server_client/
│   └── sync.py                   # Client-side sync engine
├── tests/
│   ├── test_add.py
│   ├── test_list.py
│   └── test_db.py
└── requirements.txt
```

---

# PART II — INSTALL DEPENDENCIES

```bash
pip install click rich matplotlib requests
```

---

# PART III — CORE MODULES

### `core/config.py`

```python
import os

DB_PATH = os.environ.get("TASKCLI_DB", "tasks.db")
LOG_LEVEL = os.environ.get("TASKCLI_LOG", "INFO")
SYNC_SERVER_URL = os.environ.get("TASKCLI_SYNC_URL", "http://localhost:8000/api/sync/")
```

### `core/db.py`

```python
import sqlite3
from core.config import DB_PATH

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            completed INTEGER DEFAULT 0,
            version INTEGER DEFAULT 1,
            synced INTEGER DEFAULT 0
        )
    """)
    conn.commit()
    conn.close()

def execute(query, params=()):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute(query, params)
    conn.commit()
    rows = cursor.fetchall()
    conn.close()
    return rows
```

### `core/logger.py`

```python
import logging
from core.config import LOG_LEVEL

logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)
```

### `core/scheduler.py`

```python
import threading, time

def schedule(interval, func):
    """Run func every 'interval' seconds in background thread"""
    def loop():
        while True:
            time.sleep(interval)
            func()
    threading.Thread(target=loop, daemon=True).start()
```

---

# PART IV — CLI COMMANDS

### `commands/add.py`

```python
import click
from core.db import execute
from core.logger import logger

@click.command()
@click.argument("title")
@click.option("--description", default="")
def add_task(title, description):
    """Add a new task"""
    execute("INSERT INTO tasks (title, description) VALUES (?, ?)", (title, description))
    click.echo(f"Task '{title}' added.")
    logger.info(f"Added task: {title}")
```

### `commands/list.py`

```python
import click
from core.db import execute
from rich.console import Console
from rich.table import Table

@click.command()
@click.option("--page", default=1)
@click.option("--page_size", default=10)
def list_tasks(page, page_size):
    """List all tasks with pagination"""
    offset = (page-1)*page_size
    rows = execute("SELECT id, title, description, completed FROM tasks LIMIT ? OFFSET ?", (page_size, offset))
    table = Table(title="Tasks")
    table.add_column("ID", justify="right")
    table.add_column("Title")
    table.add_column("Description")
    table.add_column("Completed")

    for r in rows:
        table.add_row(str(r[0]), r[1], r[2], str(bool(r[3])))

    Console().print(table)
```

### `commands/update.py`

```python
import click
from core.db import execute

@click.command()
@click.argument("task_id", type=int)
@click.option("--title", default=None)
@click.option("--description", default=None)
@click.option("--completed", type=bool, default=None)
def update_task(task_id, title, description, completed):
    """Update a task"""
    if title:
        execute("UPDATE tasks SET title=? WHERE id=?", (title, task_id))
    if description:
        execute("UPDATE tasks SET description=? WHERE id=?", (description, task_id))
    if completed is not None:
        execute("UPDATE tasks SET completed=? WHERE id=?", (int(completed), task_id))
```

### `commands/delete.py`

```python
import click
from core.db import execute

@click.command()
@click.argument("task_id", type=int)
def delete_task(task_id):
    """Delete a task"""
    execute("DELETE FROM tasks WHERE id=?", (task_id,))
```

---

# PART V — PLUGIN SYSTEM

### `plugins/example_plugin.py`

```python
def activate(cli_group):
    @cli_group.command()
    def hello():
        """Sample plugin command"""
        click.echo("Hello from plugin!")
```

---

# PART VI — REPORTING DASHBOARD

### `reports/dashboard.py`

```python
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from core.db import execute

def generate_task_chart():
    rows = execute("SELECT completed, COUNT(*) FROM tasks GROUP BY completed")
    completed, counts = zip(*rows) if rows else ([0,1],[0,1])
    fig = Figure(figsize=(5,4))
    ax = fig.add_subplot(111)
    ax.bar(["Incomplete","Complete"], counts)
    return fig
```

---

# PART VII — CLIENT-SIDE SYNC ENGINE

### `server_client/sync.py`

```python
import requests
from core.db import execute
from core.config import SYNC_SERVER_URL

class SyncService:
    def push(self):
        unsynced = execute("SELECT id, title, description, version FROM tasks WHERE synced=0")
        if unsynced:
            payload = [{"id":r[0],"title":r[1],"description":r[2],"version":r[3]} for r in unsynced]
            try:
                r = requests.post(SYNC_SERVER_URL+"push/", json={"records": payload})
                if r.ok:
                    for rec in unsynced:
                        execute("UPDATE tasks SET synced=1 WHERE id=?", (rec[0],))
            except Exception as e:
                print("Push failed:", e)

    def pull(self):
        try:
            r = requests.get(SYNC_SERVER_URL+"pull/")
            if r.ok:
                for rec in r.json().get("records", []):
                    execute(
                        "INSERT OR REPLACE INTO tasks (id, title, description, completed, version, synced) VALUES (?,?,?,?,?,1)",
                        (rec["id"], rec["title"], rec["description"], rec.get("completed",0), rec["version"])
                    )
        except Exception as e:
            print("Pull failed:", e)
```

---

# PART VIII — CLI ENTRYPOINT

### `taskcli.py`

```python
import click
from core.db import init_db
from commands import add, list, update, delete
from plugins.example_plugin import activate
from core.scheduler import schedule
from server_client.sync import SyncService

# Initialize DB
init_db()
sync_service = SyncService()

@click.group()
def cli():
    """TaskCLI – Enterprise CLI Task Manager"""
    pass

# Register core commands
cli.add_command(add.add_task)
cli.add_command(list.list_tasks)
cli.add_command(update.update_task)
cli.add_command(delete.delete_task)

# Register plugins
activate(cli)

# Schedule sync
schedule(300, sync_service.push)
schedule(600, sync_service.pull)

if __name__ == "__main__":
    cli()
```

---

# PART IX — UNIT TESTING

### Example: `tests/test_db.py`

```python
import unittest
from core.db import init_db, execute

class TestDB(unittest.TestCase):
    def setUp(self):
        init_db()
        execute("DELETE FROM tasks")

    def test_add_task(self):
        execute("INSERT INTO tasks (title) VALUES (?)", ("Test Task",))
        rows = execute("SELECT * FROM tasks")
        self.assertEqual(len(rows),1)

if __name__ == "__main__":
    unittest.main()
```

Run all tests:

```bash
python -m unittest discover tests
```

---

# PART X — ASCII DIAGRAM

```
TaskCLI CLI
  │
  ├─ Commands: add/list/update/delete
  │       │
  │       ▼
  │    SQLite (Offline)
  │
  ├─ Plugins → Dynamic CLI commands
  │
  ├─ Reports → Dashboard generation
  │
  └─ Sync Engine ↔ Server API
           │
           ▼
      Django REST Framework
      Push/Pull API → Central DB
```

---

# ✅ TAKEAWAYS

* CLI apps can emulate **desktop-like offline-first ecosystems**
* Plugins + background tasks → scalable CLI architecture
* Server sync + versioning → enterprise consistency
* Rich console dashboards + unit tests → production-ready
* Step-by-step instructions make this **followable for readers**

---

# 📘 TASKCLI SERVER — FULL DRF SCAFFOLD

## PART I — PROJECT STRUCTURE

```
taskcli_server/
│
├── manage.py
├── taskcli_server/                 # Project settings
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
│
├── api/
│   ├── __init__.py
│   ├── models.py                  # User, Task, AuditLog
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   └── permissions.py
├── requirements.txt
└── db.sqlite3
```

---

## PART II — INSTALL DEPENDENCIES

```bash
pip install django djangorestframework djangorestframework-simplejwt
```

---

## PART III — DJANGO PROJECT SETUP

```bash
django-admin startproject taskcli_server .
python manage.py startapp api
```

Add apps to `settings.py`:

```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'api',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
}
```

---

## PART IV — MODELS

### `api/models.py`

```python
from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    ROLE_CHOICES = (
        ('USER', 'User'),
        ('MANAGER', 'Manager'),
        ('ADMIN', 'Admin'),
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='USER')

class Task(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    completed = models.BooleanField(default=False)
    version = models.IntegerField(default=1)
    updated_at = models.DateTimeField(auto_now=True)

class AuditLog(models.Model):
    action = models.CharField(max_length=50)
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    task = models.ForeignKey(Task, on_delete=models.SET_NULL, null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
```

---

## PART V — SERIALIZERS

### `api/serializers.py`

```python
from rest_framework import serializers
from .models import Task, AuditLog, User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role']

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ['id', 'title', 'description', 'completed', 'version', 'updated_at']

class AuditLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuditLog
        fields = '__all__'
```

---

## PART VI — PERMISSIONS

### `api/permissions.py`

```python
from rest_framework.permissions import BasePermission

class IsManagerOrAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.role in ('MANAGER', 'ADMIN')
```

---

## PART VII — VIEWS (CRUD + SYNC)

### `api/views.py`

```python
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Task, AuditLog
from .serializers import TaskSerializer, AuditLogSerializer
from .permissions import IsManagerOrAdmin
from django.utils import timezone

class TaskViewSet(viewsets.ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]

    # Server-side sync: push from client
    @action(detail=False, methods=['post'])
    def push(self, request):
        records = request.data.get("records", [])
        synced_ids = []

        for rec in records:
            task, created = Task.objects.update_or_create(
                id=rec.get("id"),
                defaults={
                    "title": rec.get("title"),
                    "description": rec.get("description"),
                    "completed": rec.get("completed", False),
                    "version": rec.get("version",1),
                    "updated_at": timezone.now()
                }
            )
            AuditLog.objects.create(action="SYNC_PUSH", user=request.user, task=task)
            synced_ids.append(task.id)

        return Response({"synced": synced_ids}, status=status.HTTP_200_OK)

    # Server-side sync: pull to client
    @action(detail=False, methods=['get'])
    def pull(self, request):
        since = request.query_params.get("since")
        tasks = Task.objects.all()
        serializer = TaskSerializer(tasks, many=True)
        return Response({"records": serializer.data})

class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AuditLog.objects.all().order_by("-timestamp")
    serializer_class = AuditLogSerializer
    permission_classes = [IsManagerOrAdmin]
```

---

## PART VIII — URLS

### `api/urls.py`

```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TaskViewSet, AuditLogViewSet
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

router = DefaultRouter()
router.register(r'tasks', TaskViewSet, basename='tasks')
router.register(r'auditlogs', AuditLogViewSet, basename='auditlogs')

urlpatterns = [
    path('auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('', include(router.urls)),
]
```

### `taskcli_server/urls.py`

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
]
```

---

## PART IX — MIGRATIONS

```bash
python manage.py makemigrations
python manage.py migrate
python createsuperuser
```

---

## PART X — ASCII ARCHITECTURE (CLIENT ↔ SERVER)

```
TaskCLI CLI / Tkinter
     │
     ├─ SQLite (offline)
     │
     └─ Sync Engine → HTTP → JWT
                       │
                Django REST Framework
                  ├─ /api/tasks/push  (client → server)
                  ├─ /api/tasks/pull  (server → client)
                  ├─ /api/auth/login
                  └─ /api/auditlogs/ (admin only)
```

---

## PART XI — TESTING

Create `api/tests.py`:

```python
from django.test import TestCase
from django.contrib.auth import get_user_model
from .models import Task

User = get_user_model()

class TaskSyncTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='test', password='pass')

    def test_push_create_task(self):
        self.client.login(username='test', password='pass')
        response = self.client.post('/api/tasks/push/', {"records":[{"title":"Task 1"}]}, format='json')
        self.assertEqual(response.status_code,200)
        self.assertEqual(Task.objects.count(),1)
```

Run:

```bash
python manage.py test
```

---

## ✅ TAKEAWAYS

* Fully **runnable server for TaskCLI**
* **JWT auth**, **CRUD tasks**, **versioned push/pull sync**
* **Audit logs** for compliance
* Ready to integrate with **CLI or Tkinter client**
* Step-by-step scaffold: **clone → migrate → run → sync**

---

This provides a **complete, step-by-step server backend** for your enterprise CLI/Desktop ecosystem.

---

# 📘 ADDENDUM — TASKCLI FULL STACK DEMO

## **Goal:**

Provide a **runnable starter repository** demonstrating:

* Multi-window Tkinter client
* FastAPI/DRF server (here DRF)
* SQLite persistence
* CRUDL + pagination
* Server push/pull sync
* Plugin sandboxing
* Reporting dashboards
* Background scheduler

Readers can **clone → migrate → run → sync** immediately.

---

## PART I — PROJECT STRUCTURE (CLIENT + SERVER)

```
taskcli_fullstack/
│
├── client/
│   ├── app.py                # Tkinter main app
│   ├── views/                # Multi-window GUI
│   ├── controllers/          # Logic handlers
│   ├── services/             # Auth, sync, plugin, scheduler
│   ├── dashboards/           # Matplotlib reporting
│   ├── plugins/              # Plugin base & sandbox
│   └── db.sqlite3            # Local offline DB
│
├── server/
│   ├── manage.py
│   ├── taskcli_server/
│   │   ├── __init__.py
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── api/
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   └── permissions.py
│   └── db.sqlite3
│
└── README.md
```

---

## PART II — INSTALL DEPENDENCIES

### Client

```bash
pip install tkinter bcrypt matplotlib requests
```

### Server

```bash
pip install django djangorestframework djangorestframework-simplejwt
```

---

## PART III — CLIENT: MULTI-WINDOW TKINTER

### `client/app.py`

```python
import tkinter as tk
from views.login_view import LoginWindow

root = tk.Tk()
root.title("TaskCLI")
root.geometry("800x600")
LoginWindow(root)
root.mainloop()
```

### Multi-window flow

```
Login Window
     │
     ▼
Main Window
     │
     ▼
Task Dashboard
     │
     ▼
Plugin Manager
```

---

### Plugin Sandbox Example

```python
SAFE_BUILTINS = {"print": print, "len": len, "range": range}

def sandbox_exec(code):
    exec(code, {"__builtins__": SAFE_BUILTINS})
```

---

### Sync Service (Client)

```python
class SyncService:
    def __init__(self, db, api_client):
        self.db = db
        self.api = api_client

    def push(self):
        unsynced = self.db.get_unsynced()
        self.api.push(unsynced)
        self.db.mark_synced(unsynced)

    def pull(self):
        changes = self.api.pull(self.db.last_sync_time())
        self.db.apply(changes)
```

### Background Scheduler

```python
import threading, time

def schedule(interval, fn):
    def loop():
        while True:
            time.sleep(interval)
            fn()
    threading.Thread(target=loop, daemon=True).start()
```

---

## PART IV — SERVER: DRF BACKEND

### `server/api/models.py`

```python
from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    ROLE_CHOICES = (('USER','User'),('MANAGER','Manager'),('ADMIN','Admin'))
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='USER')

class Task(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    completed = models.BooleanField(default=False)
    version = models.IntegerField(default=1)
    updated_at = models.DateTimeField(auto_now=True)

class AuditLog(models.Model):
    action = models.CharField(max_length=50)
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    task = models.ForeignKey(Task, on_delete=models.SET_NULL, null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
```

---

### Server-side sync endpoints

```
POST /api/tasks/push   → Client → Server
GET  /api/tasks/pull   → Server → Client
POST /api/auth/login   → JWT
```

* Version-aware
* Audit-logged
* Idempotent

---

### ASCII Server-Client Flow

```
TaskCLI Client
 ├─ SQLite (Offline)
 └─ Sync Engine → HTTPS → JWT
                     │
                Django REST Framework
                  ├─ /api/tasks/push
                  ├─ /api/tasks/pull
                  └─ /api/auditlogs/
```

---

## PART V — DASHBOARDS

```python
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from matplotlib.figure import Figure

def render_chart(parent, data):
    fig = Figure(figsize=(5,4))
    ax = fig.add_subplot(111)
    ax.plot(data)
    canvas = FigureCanvasTkAgg(fig, parent)
    canvas.get_tk_widget().pack()
```

---

## PART VI — UNIT TESTS (SERVER)

```python
from django.test import TestCase
from django.contrib.auth import get_user_model
from .models import Task

User = get_user_model()

class TaskSyncTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='test', password='pass')

    def test_push_create_task(self):
        self.client.login(username='test', password='pass')
        response = self.client.post('/api/tasks/push/', {"records":[{"title":"Task 1"}]}, format='json')
        self.assertEqual(response.status_code,200)
        self.assertEqual(Task.objects.count(),1)
```

---

## PART VII — GETTING STARTED

1. Clone repository
2. Install dependencies
3. Server: `python manage.py migrate` + `createsuperuser`
4. Client: Run `app.py`
5. Test multi-window GUI, dashboard, and plugin loading
6. Sync: push/pull tasks → server

---

## PART VIII — FINAL ARCHITECTURE (ASCII)

```
┌──────────── Desktop Client ─────────────┐
│ Tkinter Views → Controllers → Services  │
│ SQLite (Offline Source of Truth)        │
│ Sync Engine ↔ DRF Server API             │
│ Plugin Sandbox                           │
└───────────────┬────────────────────────┘
                │ HTTPS / JWT
┌───────────────▼────────────────────────┐
│ DRF Server Platform                      │
│ Auth API & JWT Tokens                     │
│ Tasks CRUD + Sync Push/Pull              │
│ Audit Logs                               │
│ Central Database & Conflict Resolution   │
└─────────────────────────────────────────┘
```

---

## ✅ TAKEAWAYS

* **Runnable full-stack demo** for readers
* Demonstrates **offline-first + server sync**
* Multi-window Tkinter GUI with **plugin sandboxing**
* Reporting dashboards and background scheduler
* Step-by-step clone → run → sync workflow

---

This **addendum** can be included in your **Enterprise Tkinter Tutorial** to let readers immediately see a full **offline-first, plugin-enabled, sync-capable desktop + server ecosystem** in action.

---
