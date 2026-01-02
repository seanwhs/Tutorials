# 📘 **Django REST Framework (DRF) — FBV Full Tutorial**

**Goal:** Learn DRF from scratch, understand concepts, write function-based views, implement full CRUD with proper validation, and understand mental models behind HTTP and serialization.

---

# 🎯 Learning Objectives

After completing this tutorial, you will:

1. Understand APIs as **HTTP contracts** and mental models for request-response flow.
2. Implement **GET, POST, PUT, PATCH** using **Function-Based Views** (FBV) in DRF.
3. Learn **serialization**: why it’s needed, when to use it, and how it validates data.
4. Apply **validation mental models** to prevent bad data from entering the database.
5. Build a **fully working DRF project** with models, views, serializers, and URLs.

---

# 🧠 Core Mental Models

Think of your DRF API as a series of transformations:

```
CLIENT → HTTP request → API contract → Resource representation → Django → DRF → Response → CLIENT
```

* **Client**: Browser, mobile app, frontend JS
* **HTTP request**: Method + path + body + headers
* **API contract**: Status code + JSON + headers
* **Resource representation**: Python dictionary or serialized model
* **Django**: Handles routing, middleware, request/response objects
* **DRF**: Formalizes API behavior and standardizes validation

---

# 🧭 SECTION 1 — HTTP GET: BEFORE DJANGO

---

### 1.1 GET Concept

* **GET** retrieves a resource
* **Safe**: Does not modify server state
* **Idempotent**: Repeating GET returns the same data
* **Cacheable**: Can be cached by browser or intermediaries

---

### 1.2 Python Dictionary Example

```python
tasks = {
    1: {"id": 1, "title": "Learn DRF", "completed": False},
    2: {"id": 2, "title": "Understand GET deeply", "completed": False},
}
```

```python
def get_task(task_id):
    return tasks.get(task_id)
```

* Works in Python, **but it is not an HTTP API**
* Does not handle **status codes**, **headers**, or **JSON response**

---

# 🧩 SECTION 2 — DJANGO JSON VIEW (WITHOUT DRF)

```python
from django.http import JsonResponse, Http404

def get_task_view(request, task_id):
    task = tasks.get(task_id)
    if task is None:
        raise Http404("Task not found")
    return JsonResponse(task)
```

* Returns JSON
* Handles HTTP requests
* **No DRF features** like `status` or `Response`

---

# 🚀 SECTION 3 — DRF GET VIEW (DICTIONARY)

```python
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

@api_view(["GET"])
def get_task_view(request, task_id):
    task = tasks.get(task_id)
    if task is None:
        return Response(
            {"detail": "Task not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    return Response(task, status=status.HTTP_200_OK)
```

**Explanation:**

* `@api_view(["GET"])` → Declares allowed HTTP method
* `Response()` → DRF-aware JSON response
* `status.HTTP_404_NOT_FOUND` → Explicit status code

---

# 🧠 SECTION 4 — SERIALIZATION

### 4.1 Why Serialization is Needed

```python
task = Task.objects.get(pk=1)
```

* Python object is **not JSON serializable**
* Serializer converts object → dict → JSON

---

### 4.2 Serializer Example

```python
from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ["id", "title", "description", "completed", "created_at"]
```

* Converts models → dict
* Validates incoming data
* Controls exposed fields

---

# 🗄️ SECTION 5 — MODELS

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

**Mental model:**

```
Model = rich Python object (DB + logic)
Serializer = flatten object → JSON
```

---

# 🔁 SECTION 6 — GET WITH MODEL + SERIALIZER

```python
from django.shortcuts import get_object_or_404

@api_view(["GET"])
def get_task_model(request, task_id):
    task = get_object_or_404(Task, pk=task_id)
    serializer = TaskSerializer(task)
    return Response(serializer.data)
```

* Uses serializer to **convert model → dict → JSON**
* Returns `200 OK` or `404 Not Found`

---

# 📝 SECTION 7 — POST: CREATE RESOURCE

```python
@api_view(["POST"])
def create_task(request):
    serializer = TaskSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
```

**Mental Model:**

```
Client POST JSON → Serializer validates → DB saves → Response 201
```

* POST = Create new resource
* Validation prevents bad data
* Status 201 = Created

---

# 🔄 SECTION 8 — PUT (FULL UPDATE)

```python
@api_view(["PUT"])
def update_task(request, task_id):
    task = get_object_or_404(Task, pk=task_id)
    serializer = TaskSerializer(task, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
```

* Replaces all fields
* Idempotent
* Status 200 = OK

---

# 🩹 SECTION 9 — PATCH (PARTIAL UPDATE)

```python
@api_view(["PATCH"])
def partial_update_task(request, task_id):
    task = get_object_or_404(Task, pk=task_id)
    serializer = TaskSerializer(task, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
```

* Updates only provided fields
* Idempotent
* Status 200 = OK

---

# 🧩 SECTION 10 — VALIDATION MENTAL MODELS

```
Client → Serializer → Database → Response
      ^ Validation prevents bad data
```

* `serializer.is_valid()` → ensures data integrity
* `serializer.save()` → persists validated data
* Invalid → 400 Bad Request

---

# 🌐 SECTION 11 — URL ROUTING (WITH NAMES)

```python
from django.urls import path
from .views import (
    get_task_view,
    get_task_model,
    create_task,
    update_task,
    partial_update_task
)

urlpatterns = [
    path("tasks/<int:task_id>/", get_task_view, name="get_task"),
    path("tasks-db/<int:task_id>/", get_task_model, name="get_task_model"),
    path("tasks/", create_task, name="create_task"),
    path("tasks/<int:task_id>/update/", update_task, name="update_task"),
    path("tasks/<int:task_id>/partial/", partial_update_task, name="partial_update_task"),
]
```

---

# 📦 SECTION 12 — ASCII DIAGRAMS (CRUD)

**GET dictionary**

```
Client GET /tasks/1/
       |
   tasks dict -> retrieve key
       |
   Response 200 JSON
```

**GET model**

```
Client GET /tasks-db/1/
       |
   DB -> Task object
       |
Serializer -> dict
       |
   Response 200 JSON
```

**POST**

```
Client POST /tasks/
       |
Serializer -> validate
       |
save -> DB
       |
Response 201 JSON
```

**PUT**

```
Client PUT /tasks/1/update/
       |
Serializer validate -> save
       |
Response 200 JSON (full update)
```

**PATCH**

```
Client PATCH /tasks/1/partial/
       |
Serializer validate -> save partial
       |
Response 200 JSON (partial update)
```

---

# 📝 Addendum A — Full Project Code

### **Project Structure**

```
drf_tutorial/
├── manage.py
├── drf_tutorial/
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

---

### `api/models.py`

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

---

### `api/serializers.py`

```python
from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ["id", "title", "description", "completed", "created_at"]
```

---

### `api/views.py`

```python
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from .models import Task
from .serializers import TaskSerializer

tasks = {
    1: {"id": 1, "title": "Learn DRF", "completed": False},
    2: {"id": 2, "title": "Understand GET deeply", "completed": False},
}

# GET dictionary
@api_view(["GET"])
def get_task_view(request, task_id):
    task = tasks.get(task_id)
    if task is None:
        return Response({"detail": "Task not found"}, status=status.HTTP_404_NOT_FOUND)
    return Response(task, status=status.HTTP_200_OK)

# GET model
@api_view(["GET"])
def get_task_model(request, task_id):
    task = get_object_or_404(Task, pk=task_id)
    serializer = TaskSerializer(task)
    return Response(serializer.data, status=status.HTTP_200_OK)

# POST
@api_view(["POST"])
def create_task(request):
    serializer = TaskSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# PUT
@api_view(["PUT"])
def update_task(request, task_id):
    task = get_object_or_404(Task, pk=task_id)
    serializer = TaskSerializer(task, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# PATCH
@api_view(["PATCH"])
def partial_update_task(request, task_id):
    task = get_object_or_404(Task, pk=task_id)
    serializer = TaskSerializer(task, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
```

---

### `api/urls.py`

```python
from django.urls import path
from .views import (
    get_task_view,
    get_task_model,
    create_task,
    update_task,
    partial_update_task
)

urlpatterns = [
    path("tasks/<int:task_id>/", get_task_view, name="get_task"),
    path("tasks-db/<int:task_id>/", get_task_model, name="get_task_model"),
    path("tasks/", create_task, name="create_task"),
    path("tasks/<int:task_id>/update/", update_task, name="update_task"),
    path("tasks/<int:task_id>/partial/", partial_update_task, name="partial_update_task"),
]
```

---

### `drf_tutorial/urls.py`

```python
from django.urls import path, include

urlpatterns = [
    path("api/", include("api.urls")),
]
```

---

Perfect! Let’s create **Addendum A — Visual Cheat-Sheet for CRUD Flows and Mental Models**, designed to accompany the full tutorial. This will be **textbook-style, visual, and fully explanatory**, so you can quickly reference **GET, POST, PUT, PATCH, validation, and serializer flows**.

---

# 📝 **Addendum B — Visual Cheat-Sheet: DRF CRUD Flows**

---

## 🌐 **1. HTTP Methods & API Mental Models**

| Method | Purpose                  | Idempotent | Typical Status Codes | Mental Model                              |
| ------ | ------------------------ | ---------- | -------------------- | ----------------------------------------- |
| GET    | Read / retrieve resource | Yes        | 200, 404             | "I only want to look, not touch"          |
| POST   | Create new resource      | No         | 201, 400             | "I send data; server makes something new" |
| PUT    | Full update              | Yes        | 200, 400, 404        | "Replace everything about the resource"   |
| PATCH  | Partial update           | Yes        | 200, 400, 404        | "Change only the fields I specify"        |

**Key Insight:**

> DRF enforces **status codes, response consistency, and validation** automatically if used properly.

---

## 🔍 **2. GET Example (Dictionary Context)**

**Scenario:** Resource is just a Python dict, no model, no serialization needed.

```python
tasks = {
    1: {"id": 1, "title": "Learn DRF", "completed": False}
}
```

**Flow Diagram:**

```
Client GET /tasks/1/
       |
       v
tasks dictionary -> retrieve key
       |
       v
Response(data) 200 OK
```

**Mental Notes:**

* Serializer not needed because dict is already JSON-serializable
* `404` if key not found

---

## 🗄️ **3. GET Example (Model + Serializer)**

**Scenario:** Resource is a Django model → needs serializer.

**Flow Diagram:**

```
Client GET /tasks-db/1/
       |
       v
Database -> Task object
       |
Serializer -> dict
       |
       v
Response(data) 200 OK
```

**Mental Notes:**

* Models are **Python objects with DB metadata**
* Serializers convert model → JSON-safe dict
* Ensures frontend never receives DB-specific objects

---

## 🟢 **4. POST (Create Resource)**

**Flow Diagram:**

```
Client POST /tasks/
  Body: { "title": "New Task", "description": "Learn POST" }
       |
       v
-------------------------------
| Serializer(data=request.data)|
| is_valid()?                  |
|    | Yes -> serializer.save()|
|    | No  -> Response 400     |
-------------------------------
       |
       v
Response(data) 201 CREATED
```

**Mental Notes:**

* **Validation is the gatekeeper**
* POST creates **new IDs** and persists in DB
* Non-idempotent → repeated POST creates new entries

---

## 🔄 **5. PUT (Full Update)**

**Flow Diagram:**

```
Client PUT /tasks/1/update/
  Body: { "title": "Updated Task", "description": "Replace all", "completed": True }
       |
       v
-----------------------------
| get_object_or_404(Task,1) |
| Serializer(task, data=request.data) |
| is_valid()?               |
|   | Yes -> serializer.save()       |
|   | No  -> Response 400            |
-----------------------------
       |
       v
Response(data) 200 OK
```

**Mental Notes:**

* **All fields required** → must send complete object
* Idempotent → repeated PUT with same data does not create duplicates
* Full replacement ensures DB record exactly matches client input

---

## 🩹 **6. PATCH (Partial Update)**

**Flow Diagram:**

```
Client PATCH /tasks/1/partial/
  Body: { "completed": True }
       |
       v
-----------------------------
| get_object_or_404(Task,1) |
| Serializer(task, data=request.data, partial=True) |
| is_valid()?               |
|   | Yes -> serializer.save()       |
|   | No  -> Response 400            |
-----------------------------
       |
       v
Response(data) 200 OK
```

**Mental Notes:**

* Partial = update **only provided fields**
* Keep other fields intact
* Idempotent → repeated PATCH with same payload has no side effects

---

## 🔑 **7. Validation Mental Model**

```
Client JSON → Serializer → is_valid()? → DB save → Response
      ^ Validation stops invalid data
```

**Notes:**

* `serializer.is_valid()` = **gatekeeper**
* `serializer.save()` = commits data to DB
* `serializer.errors` → automatic 400 response with field-level messages

---

## 📊 **8. CRUD Summary Table**

| Method | Resource | Serializer Needed? | Validation? | Idempotent? | Typical Status |
| ------ | -------- | ------------------ | ----------- | ----------- | -------------- |
| GET    | dict     | No                 | No          | Yes         | 200, 404       |
| GET    | model    | Yes                | No          | Yes         | 200, 404       |
| POST   | model    | Yes                | Yes         | No          | 201, 400       |
| PUT    | model    | Yes                | Yes         | Yes         | 200, 400, 404  |
| PATCH  | model    | Yes                | Yes         | Yes         | 200, 400, 404  |

---

## 📦 **9. Full CRUD ASCII Flow — One Page Reference**

```
GET DICT:
Client -> /tasks/1 -> tasks dict -> Response 200

GET MODEL:
Client -> /tasks-db/1 -> DB -> Serializer -> Response 200

POST:
Client -> /tasks/ -> Serializer(data) -> is_valid? -> save -> Response 201

PUT:
Client -> /tasks/1/update/ -> Serializer(task, data) -> is_valid? -> save -> Response 200

PATCH:
Client -> /tasks/1/partial/ -> Serializer(task, data, partial=True) -> is_valid? -> save -> Response 200
```

**Mnemonic:**

> GET = look, POST = create, PUT = replace, PATCH = update partially

---



