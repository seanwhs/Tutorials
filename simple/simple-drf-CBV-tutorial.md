# 📘 Django REST Framework (DRF) Tutorial — Class-Based Views (CBV)

**Goal:** Build a fully functional DRF API using **Class-Based Views** (CBVs), understanding the **mental models behind HTTP, serialization, validation, and CRUD operations**.

---

# 🎯 Learning Objectives

By the end of this tutorial, you will:

1. Understand how DRF CBVs structure your API for scalability and maintainability.
2. Implement **GET, POST, PUT, PATCH** operations.
3. Understand why **serializers** are essential for model-to-JSON conversion.
4. Apply **validation mental models** to prevent bad data from being saved.
5. Build a **complete DRF project** with models, serializers, views, URLs, and tests.
6. Use **ASCII diagrams** to visualize data flow.
7. Reference **full project code** and a **visual CRUD cheat-sheet** for quick learning.

---

# 🧠 Section 1 — Core Mental Models

Understanding DRF requires thinking in **layers of responsibility**:

```
CLIENT → HTTP request → DRF View → Serializer → Model/Database → DRF Response → CLIENT
```

* **Client**: Frontend app, browser, or mobile client.
* **HTTP Request**: Includes method (GET, POST, etc.), path, headers, and body.
* **DRF View (CBV)**: Determines what code executes for each HTTP method.
* **Serializer**: Converts Python objects (models) to JSON and validates incoming data.
* **Model/Database**: Stores and retrieves persistent data.
* **Response**: DRF converts Python dict back to JSON, sends HTTP status codes.

> CBVs allow you to encapsulate logic for multiple HTTP methods in one class, improving **reusability** and **scalability**.

---

# 🗂️ Section 2 — GET Before Database: Dictionary Example

Before using models, you can simulate an API using **Python dictionaries**.

```python
tasks = {
    1: {"id": 1, "title": "Learn DRF", "completed": False},
    2: {"id": 2, "title": "Understand CBV", "completed": False},
}
```

**Class-Based View Example (Dictionary)**:

```python
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

class TaskDictView(APIView):
    """GET a task from an in-memory dictionary"""
    def get(self, request, task_id):
        task = tasks.get(task_id)
        if not task:
            return Response({"detail": "Task not found"}, status=status.HTTP_404_NOT_FOUND)
        return Response(task, status=status.HTTP_200_OK)
```

**Key Points:**

* `APIView` provides **method dispatching** (`get`, `post`, etc.).
* No serializer is needed because dictionaries are already JSON-serializable.
* Status codes indicate success (`200 OK`) or failure (`404 Not Found`).

**ASCII Diagram:**

```
Client GET /tasks/1/
       |
    tasks dict -> lookup
       |
Response 200 OK
```

---

# 🗄️ Section 3 — Models

**Models** represent persistent data.

```python
from django.db import models

class Task(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title
```

**Mental Model:**

```
Model = Python object + database mapping
Serializer = JSON-safe flattening
```

* `title` → string field
* `description` → optional text
* `completed` → boolean state
* `created_at` → automatically set timestamp

---

# 🧩 Section 4 — Serializers

Serializers are essential because **Python objects cannot be returned directly as JSON**.

```python
from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ["id", "title", "description", "completed", "created_at"]
```

* Converts **model → dict → JSON**
* Performs **validation** before data is saved
* Controls which fields are exposed in the API

---

# 🔁 Section 5 — GET From Model

Retrieve a model instance and return serialized data.

```python
from django.shortcuts import get_object_or_404

class TaskModelView(APIView):
    """GET a task from the database"""
    def get(self, request, task_id):
        task = get_object_or_404(Task, pk=task_id)
        serializer = TaskSerializer(task)
        return Response(serializer.data, status=status.HTTP_200_OK)
```

**ASCII Diagram:**

```
Client GET /tasks-db/1/
       |
       v
Database -> Task object
       |
Serializer -> dict
       |
Response 200 OK
```

**Mental Model:**

* `get_object_or_404` → raises 404 if object does not exist
* Serializer ensures data is JSON-serializable

---

# 📝 Section 6 — POST (Create Resource)

```python
class TaskCreateView(APIView):
    """Create a new task"""
    def post(self, request):
        serializer = TaskSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
```

**Mental Model:**

```
Client POST -> Serializer -> validate -> save -> Response
```

* Status 201 → Created
* Validation prevents invalid data from entering the database

---

# 🔄 Section 7 — PUT (Full Update)

```python
class TaskUpdateView(APIView):
    """Full update of a task"""
    def put(self, request, task_id):
        task = get_object_or_404(Task, pk=task_id)
        serializer = TaskSerializer(task, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
```

* Requires **all fields** to be provided
* Idempotent operation (repeated PUT = same result)

---

# 🩹 Section 8 — PATCH (Partial Update)

```python
class TaskPartialUpdateView(APIView):
    """Partial update of a task"""
    def patch(self, request, task_id):
        task = get_object_or_404(Task, pk=task_id)
        serializer = TaskSerializer(task, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
```

* Updates only provided fields
* Idempotent

---

# 🧠 Section 9 — Validation Mental Models

```
Client JSON -> Serializer -> is_valid() -> save -> Response
       ^ Validation prevents invalid data
```

**Key Points:**

* `serializer.is_valid()` checks constraints
* `serializer.save()` persists valid data
* Invalid → Response 400

---

# 🌐 Section 10 — Named URL Routing

```python
from django.urls import path
from .views import (
    TaskDictView,
    TaskModelView,
    TaskCreateView,
    TaskUpdateView,
    TaskPartialUpdateView
)

urlpatterns = [
    path("tasks/<int:task_id>/", TaskDictView.as_view(), name="get_task_dict"),
    path("tasks-db/<int:task_id>/", TaskModelView.as_view(), name="get_task_model"),
    path("tasks/", TaskCreateView.as_view(), name="create_task"),
    path("tasks/<int:task_id>/update/", TaskUpdateView.as_view(), name="update_task"),
    path("tasks/<int:task_id>/partial/", TaskPartialUpdateView.as_view(), name="partial_update_task"),
]
```

---

# 🧾 Section 11 — ASCII CRUD Flows

**GET Dictionary**

```
Client GET /tasks/1/
       |
       v
tasks dict -> lookup
       |
Response 200 OK
```

**GET Model**

```
Client GET /tasks-db/1/
       |
DB -> Task object
       |
Serializer -> dict
       |
Response 200 OK
```

**POST**

```
Client POST /tasks/
       |
Serializer -> validate -> save -> Response 201
```

**PUT**

```
Client PUT /tasks/1/update/
       |
Serializer -> validate -> save -> Response 200
```

**PATCH**

```
Client PATCH /tasks/1/partial/
       |
Serializer -> validate -> save partial -> Response 200
```

---

# 🧾 Addendum A — Full Project Code

**Project Structure**

```
drf_cbv_tutorial/
├── manage.py
├── drf_cbv_tutorial/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
└── api/
    ├── __init__.py
    ├── apps.py
    ├── models.py
    ├── serializers.py
    ├── views.py
    ├── urls.py
    └── migrations/
```

**Code:** Already included in sections above. (models, serializers, views, urls)

---

# 🧾 Addendum B — Visual CRUD Cheat-Sheet

```
GET DICT:
Client -> /tasks/1 -> tasks dict -> Response 200 OK

GET MODEL:
Client -> /tasks-db/1 -> DB -> Serializer -> Response 200 OK

POST:
Client -> /tasks/ -> Serializer(data) -> validate -> save -> Response 201

PUT:
Client -> /tasks/1/update/ -> Serializer(data) -> validate -> save -> Response 200

PATCH:
Client -> /tasks/1/partial/ -> Serializer(data, partial=True) -> validate -> save -> Response 200
```

**Mnemonic:**

> GET = look, POST = create, PUT = replace fully, PATCH = update partially

**Validation Mental Model:**

```
Client JSON -> Serializer -> is_valid? -> save -> Response
       ^ Validation stops invalid data
```

---


