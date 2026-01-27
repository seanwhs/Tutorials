# 🚀 Django SPA Task Manager – Teaching Guide

**Tech Stack:** Django · HTMX · Tailwind · MySQL · Chart.js · SSE · Sortable.js · Crispy Forms

This guide shows how to build a **real-time task manager SPA** with Django, featuring:

* CRUD without page reloads
* Multi-project support
* Drag-and-drop ordering
* Real-time notifications
* CSV exports
* Visual analytics

We emphasize **both “how” and “why”**, highlighting the mental models behind architecture and workflow.

---

## 🧠 Why SPA with Django + HTMX?

Think of your app as a **living page**:

* **Traditional Django:** Full-page reloads on every action → slow UX, wasted bandwidth.
* **SPA approach:** Only update the DOM fragments that change. HTMX acts as a **remote control for the DOM**.

**Complementary stack:**

* Tailwind → Styling & responsive UI
* MySQL → Persistent, reliable storage
* Django signals + SSE → Real-time updates

> Mental model: MySQL is a **ledger**—every task update is reliably recorded, ensuring SPA state integrity.

---

## 🛠 Prerequisites

* Python 3.10+ & `pip`
* MySQL installed
* Familiarity with Python, Django, HTML

---

## 1️⃣ Environment & MySQL Setup

### Project & Virtual Environment

```bash
mkdir task-manager && cd task-manager
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

> **Mental model:** Virtual environments isolate dependencies—your SPA won’t break if other projects differ.

### Dependencies

```bash
pip install django mysqlclient django-crispy-forms crispy-tailwind
```

* `mysqlclient` → Connect Django to MySQL
* `django-crispy-forms` + `crispy-tailwind` → Clean, DRY forms

### Create Project & App

```bash
django-admin startproject config .
python manage.py startapp tasks
```

### Configure MySQL (`config/settings.py`)

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'task_db',
        'USER': 'your_mysql_user',
        'PASSWORD': 'your_password',
        'HOST': 'localhost',
        'PORT': '3306',
    }
}
```

> **Mental model:** ORM abstracts SQL; indexing fields (like `title`) ensures fast live search.

---

## 2️⃣ Data Models (`tasks/models.py`)

```python
from django.db import models
from django.contrib.auth.models import User

class Project(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

class Category(models.Model):
    name = models.CharField(max_length=100)
    color = models.CharField(max_length=7, default='#3B82F6')

class Task(models.Model):
    PRIORITY_CHOICES = [('low','Low'),('medium','Medium'),('high','High'),('urgent','Urgent')]

    title = models.CharField(max_length=200, db_index=True)
    description = models.TextField(blank=True)
    completed = models.BooleanField(default=False)
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    project = models.ForeignKey(Project, on_delete=models.CASCADE, null=True, blank=True)
    position = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['position', 'completed', '-created_at']
```

**Mental models:**

* `position` → **priority queue** for drag-and-drop ordering
* `db_index=True` → faster search
* `project` → multi-workspace organization

---

## 3️⃣ HTMX Views – SPA Logic

```python
from django.shortcuts import render, get_object_or_404
from django.views.decorators.http import require_http_methods
from .models import Task, Project
from .forms import TaskForm

def task_list(request):
    return render(request, 'tasks/list.html', {'tasks': Task.objects.all(), 'task_form': TaskForm()})

@require_http_methods(["POST"])
def create_task(request):
    form = TaskForm(request.POST)
    project_id = request.GET.get('project_id')
    if form.is_valid():
        task = form.save(commit=False)
        if project_id: task.project_id = project_id
        task.user = request.user
        task.save()
        return render(request, 'tasks/partials/task_card.html', {'task': task})
```

> **Mental model:** HTMX swaps fragments instead of reloading pages—like updating Lego blocks instead of rebuilding the tower.

Other SPA actions: `toggle_task`, `delete_task`, `reorder_tasks`, `search_tasks`, `project_tasks`.

---

## 4️⃣ Real-Time Notifications – Signals + SSE

### Signals (`tasks/signals.py`)

```python
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Task

notification_queue = []

@receiver(post_save, sender=Task)
def task_saved_notification(sender, instance, created, **kwargs):
    action = "created" if created else "updated"
    notification_queue.append(f"Task '{instance.title}' was {action}!")
```

> **Mental model:** Signals = automatic triggers on database events.

### SSE Stream (`tasks/views.py`)

```python
import time
from django.http import StreamingHttpResponse
from .signals import notification_queue

def event_stream():
    while True:
        if notification_queue:
            message = notification_queue.pop(0)
            yield f"event: task-update\ndata: <div class='p-4 mb-2 bg-indigo-600 text-white rounded shadow-lg animate-fade-in'>🔔 {message}</div>\n\n"
        time.sleep(1)

def stream_notifications(request):
    return StreamingHttpResponse(event_stream(), content_type='text/event-stream')
```

> **Mental model:** SSE = **server → browser push**, no reload needed.

---

## 5️⃣ Frontend – HTMX + Tailwind + Sortable.js + Chart.js

**Base Template (`base.html`)**: includes HTMX, Tailwind, Sortable.js, Chart.js, SSE container.

**Task List + Form + Search**: HTMX handles form submission, search, and dynamic updates.

**Dashboard – Chart.js**: real-time stats updated via `dashboard_stats` view.

**CSV Export**: snapshot of MySQL data for offline analysis.

---

## 6️⃣ URL Patterns

```python
from django.urls import path
from . import views

urlpatterns = [
    path('', views.task_list, name='task_list'),
    path('create/', views.create_task, name='create_task'),
    path('toggle/<int:pk>/', views.toggle_task, name='toggle_task'),
    path('delete/<int:pk>/', views.delete_task, name='delete_task'),
    path('reorder/', views.reorder_tasks, name='reorder_tasks'),
    path('search/', views.search_tasks, name='search_tasks'),
    path('project/<slug:slug>/', views.project_tasks, name='project_tasks'),
    path('events/', views.stream_notifications, name='stream_notifications'),
    path('export/', views.export_tasks_csv, name='export_tasks_csv'),
    path('dashboard-stats/', views.dashboard_stats, name='dashboard_stats'),
]
```

---

## 7️⃣ Folder Structure & HTMX Partial Flow

```
task-manager/
├── config/
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── tasks/
│   ├── models.py
│   ├── forms.py
│   ├── views.py
│   ├── signals.py
│   ├── urls.py
│   └── templates/tasks/
│       ├── base.html
│       ├── list.html
│       └── partials/
│           ├── task_card.html
│           ├── task_list_items.html
│           └── dashboard.html
├── venv/
└── manage.py
```

**HTMX Partial Flow:**

```
[Task List Page: list.html]
   ├─> Task Add Form → hx-target="#task-list" → task_card.html inserted
   ├─> Search / Project Switch → hx-get → task_list_items.html swapped
   ├─> Drag & Drop → hx-post reorder_tasks → updates DB
   └─> Dashboard → hx-get dashboard_stats → dashboard.html with Chart.js

[SSE Notifications]
   ├─> hx-ext="sse" sse-connect → #notifications-toast
   └─> server pushes task updates → toast inserted
```

---

## 🧠 Mental Models Recap

1. **Partial Reuse:** `task_card.html` is atomic → reused across list & updates.
2. **Container + Target Pattern:** `#task-list` = dynamic swap target.
3. **Event-driven UI:** Key triggers: `keyup`, drag `end`, SSE.
4. **SPA Flow:**

```
User Action → HTMX → Django View → MySQL → Partial HTML → HTMX Swap → DOM Updated
```

5. **Separation of Concerns:**

* Frontend → HTMX/Tailwind
* Backend → Django Views & Signals
* Database → MySQL
* Real-Time → SSE & Signals

---

## ✅ Visual Diagram Integration

Your uploaded infographic illustrates:

* Folder structure
* HTMX request & partial flow
* SSE notifications & dashboard updates

This provides a **visual mental model** for SPA architecture.

![Django SPA Task Manager – Folder & Flow Diagram](file:///mnt/data/An_infographic-style_diagram_illustrates_the_folde.png)

---

## 🎨 Color-Coded SPA Flow (HTMX + SSE)

| Element          | Color  | Meaning                             |
| ---------------- | ------ | ----------------------------------- |
| User Action      | Blue   | Clicks, form submit, keyup, drag    |
| HTMX Request     | Purple | AJAX-like request                   |
| Django View      | Green  | Backend processing & DB interaction |
| MySQL            | Orange | Database storage / read / update    |
| Partial HTML     | Yellow | Fragment templates returned         |
| DOM Update       | Teal   | HTMX swaps content in browser       |
| SSE Notification | Red    | Real-time push from server          |

---

### Step-by-Step Flows

**Task Add / Create**

```
User → HTMX POST → Django View → MySQL Insert → Return Partial → HTMX Swap → SSE Notification
```

**Task Toggle / Complete**

```
User → HTMX POST → Django View → Update MySQL → Return Partial → HTMX Swap → SSE Notification
```

**Drag-and-Drop Reordering**

```
User → Sortable.js → HTMX POST → Django View → Update MySQL → DOM Update
```

**Search / Filter**

```
User → HTMX GET → Django View → Query MySQL → Return Partial → HTMX Swap
```

**Dashboard & Analytics**

```
User → HTMX GET → Django View → Aggregate MySQL → Return Partial + Chart.js → HTMX Swap
```

**SSE Notifications**

```
Task Created/Updated → Signal → Append to Queue → SSE Event → Browser DOM Update
```

---

**Key Insights**

* HTMX handles request + swap
* Django Views enforce logic & update MySQL
* Signals + SSE push asynchronous updates
* Partial templates = reusable Lego blocks
* Sortable.js + position = drag-and-drop persistence

