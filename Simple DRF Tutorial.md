# 📝 Django REST Framework (DRF) Tutorial — Building a Simple Task API

This guide walks you through creating a **RESTful API** using Django and DRF to manage a list of tasks.

---

## 1️⃣ Initial Setup

### Install Django and DRF

```bash
pip install django djangorestframework
```

### Create Project and App

```bash
django-admin startproject myproject
cd myproject
python manage.py startapp api
```

### Configure Installed Apps

In `myproject/settings.py`:

```python
INSTALLED_APPS = [
    ...,
    'rest_framework',
    'api',
]
```

---

## 2️⃣ Define Your Data Model

In `api/models.py`, define a simple `Task` model:

```python
from django.db import models

class Task(models.Model):
    title = models.CharField(max_length=200)
    completed = models.BooleanField(default=False)

    def __str__(self):
        return self.title
```

### Apply Migrations

```bash
python manage.py makemigrations
python manage.py migrate
```

---

## 3️⃣ Create a Serializer

Serializers convert model instances to JSON for API responses.

Create `api/serializers.py`:

```python
from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ['id', 'title', 'completed']
```

---

## 4️⃣ Build Views

We’ll use **Generic Views** to handle CRUD operations.

In `api/views.py`:

```python
from rest_framework import generics
from .models import Task
from .serializers import TaskSerializer

# List all tasks or create a new task
class TaskListCreateAPIView(generics.ListCreateAPIView):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer

# Retrieve, update, or delete a single task
class TaskRetrieveUpdateDestroyAPIView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
```

---

## 5️⃣ Configure URLs

### In `api/urls.py`:

```python
from django.urls import path
from .views import TaskListCreateAPIView, TaskRetrieveUpdateDestroyAPIView

urlpatterns = [
    path('tasks/', TaskListCreateAPIView.as_view(), name='task-list-create'),
    path('tasks/<int:pk>/', TaskRetrieveUpdateDestroyAPIView.as_view(), name='task-detail'),
]
```

### Include API URLs in `myproject/urls.py`:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
]
```

---

## 6️⃣ Test the API

Start the Django development server:

```bash
python manage.py runserver
```

* Browse to `http://127.0.0.1:8000/api/tasks/` to see the **DRF Browsable API**.
* Create, update, or delete tasks directly from the browser interface.

**Example JSON response:**

```json
[
    {
        "id": 1,
        "title": "Learn Django REST Framework",
        "completed": false
    },
    {
        "id": 2,
        "title": "Build my first API",
        "completed": true
    }
]
```

---

## ✅ Key Takeaways

1. DRF makes it easy to **expose Django models as REST APIs**.
2. **Serializers** handle converting database models to JSON.
3. **Generic Views** simplify CRUD operations.
4. Browsable API allows **interactive testing** in the browser.
5. This setup is ready to expand with **authentication, permissions, filtering, and pagination**.
