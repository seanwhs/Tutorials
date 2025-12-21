# 📘 Production-Grade DRF + TypeScript Application Handbook

## Design, Secure, Type, Test, and Ship a Full-Stack Application

**Edition:** 1.0
**Audience:** Engineers, Bootcamp Learners, Trainers
**Level:** Beginner → Professional

---

## 🧰 Tech Stack

### Backend

* Python 3.11+
* Django 4.x
* Django REST Framework
* SimpleJWT (Authentication)
* PostgreSQL (SQLite for dev)
* Pytest

### Frontend

* TypeScript (ES2022+)
* Vite
* Fetch API
* Zod (runtime validation)
* Vitest
* OpenAPI / schema-driven typing

---

## 🎯 Learning Outcomes

By the end of this guide, readers will:

✅ Design **clean REST APIs with DRF**
✅ Implement **JWT authentication** correctly
✅ Separate **domain, API, and infrastructure layers**
✅ Generate **TypeScript types from backend contracts**
✅ Build **end-to-end type-safe applications**
✅ Prevent backend/frontend integration bugs
✅ Apply **enterprise backend + frontend patterns**

---

# 🧭 Architecture Overview

---

## High-Level Architecture

```
+---------------------+
|   TypeScript App    |
|  (Vite + TS)        |
+----------+----------+
           |
           v
+---------------------+        +----------------------+
| Typed API Client    | <----> | Django REST API      |
| (Zod / OpenAPI)     |        | (Views + Serializers)|
+----------+----------+        +----------+-----------+
           |
           v
+---------------------+
| Domain Types        |
| (Shared Contracts) |
+---------------------+
```

> **Key idea:**
> **The API contract is the source of truth** — both backend and frontend obey it.

---

## Design Principles

* **API-first design**
* **Thin views, rich domain**
* **Serializers as contracts**
* **Authentication as infrastructure**
* **Type safety across boundaries**
* **Tests at every layer**

---

# 📁 Project Structure (Production-Grade)

```
drf-ts-task-manager/
│
├── backend/
│   ├── manage.py
│   ├── config/
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   │
│   ├── tasks/
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   └── tests.py
│   │
│   └── requirements.txt
│
├── frontend/
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   │
│   └── src/
│       ├── api/
│       │   ├── client.ts
│       │   ├── schemas.ts
│       │   └── tasks.ts
│       │
│       ├── domain/
│       │   └── task.ts
│       │
│       ├── main.ts
│       └── tests/
│           └── api.test.ts
│
└── README.md
```

---

# ⚙️ Part 1: Backend Setup (DRF)

---

## 1️⃣ Create Django Project

```bash
django-admin startproject config backend
cd backend
python manage.py startapp tasks
```

---

## 2️⃣ Install Dependencies

```bash
pip install django djangorestframework djangorestframework-simplejwt pytest
```

---

## 3️⃣ Enable DRF (`settings.py`)

```python
INSTALLED_APPS = [
    ...
    "rest_framework",
    "tasks",
]

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    )
}
```

---

# 🧠 Part 2: Domain Modeling (Backend)

---

## `tasks/models.py`

```python
from django.db import models

class Task(models.Model):
    title = models.CharField(max_length=255)
    completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
```

---

## Why This Matters

* Models represent **domain truth**
* No HTTP, no JSON, no auth here
* Framework-agnostic thinking

---

# 🧾 Part 3: Serializers as Contracts

---

## `tasks/serializers.py`

```python
from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ["id", "title", "completed"]
```

> **Serializer = API contract**
> This shape must be mirrored in TypeScript.

---

# 🌐 Part 4: API Views (Thin Controllers)

---

## `tasks/views.py`

```python
from rest_framework.viewsets import ModelViewSet
from rest_framework.permissions import IsAuthenticated
from .models import Task
from .serializers import TaskSerializer

class TaskViewSet(ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]
```

---

## `tasks/urls.py`

```python
from rest_framework.routers import DefaultRouter
from .views import TaskViewSet

router = DefaultRouter()
router.register("tasks", TaskViewSet)

urlpatterns = router.urls
```

---

# 🔐 Part 5: Authentication (JWT)

---

## Enable JWT URLs

```python
# config/urls.py
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    path("api/token/", TokenObtainPairView.as_view()),
    path("api/token/refresh/", TokenRefreshView.as_view()),
]
```

---

## Auth Flow

```
Login (username/password)
        ↓
JWT Access Token
        ↓
Authorization: Bearer <token>
        ↓
Protected API Access
```

---

# 🧪 Part 6: Backend Testing

---

## `tasks/tests.py`

```python
import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient

@pytest.mark.django_db
def test_create_task():
    user = User.objects.create_user("test", password="pass")
    client = APIClient()
    client.force_authenticate(user=user)

    response = client.post("/api/tasks/", {"title": "Test task"})
    assert response.status_code == 201
```

---

# ⚙️ Part 7: Frontend Setup (TypeScript)

---

## 1️⃣ Initialize Frontend

```bash
npm create vite@latest frontend -- --template vanilla-ts
cd frontend
npm install
```

---

## 2️⃣ Install Dependencies

```bash
npm install zod
npm install vitest --save-dev
```

---

# 🧠 Part 8: Type Contracts (Frontend)

---

## `src/domain/task.ts`

```ts
export interface Task {
  id: number;
  title: string;
  completed: boolean;
}
```

---

## Zod Schema (Runtime Safety)

### `src/api/schemas.ts`

```ts
import { z } from "zod";

export const TaskSchema = z.object({
  id: z.number(),
  title: z.string(),
  completed: z.boolean(),
});

export type Task = z.infer<typeof TaskSchema>;
```

---

# 🌐 Part 9: Typed API Client

---

## `src/api/client.ts`

```ts
export async function apiFetch<T>(
  url: string,
  token: string,
  schema: any
): Promise<T> {
  const res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  const data = await res.json();
  return schema.parse(data);
}
```

---

## Task API

### `src/api/tasks.ts`

```ts
import { apiFetch } from "./client";
import { TaskSchema } from "./schemas";

export function getTasks(token: string) {
  return apiFetch("/api/tasks/", token, TaskSchema.array());
}
```

---

# 🧪 Part 10: Frontend Testing

---

## `tests/api.test.ts`

```ts
import { describe, it, expect } from "vitest";
import { TaskSchema } from "../api/schemas";

it("validates task shape", () => {
  const task = { id: 1, title: "Test", completed: false };
  expect(TaskSchema.parse(task)).toBeTruthy();
});
```

---

# 🚀 Part 11: End-to-End Flow

---

```
Django Model
   ↓
Serializer (Contract)
   ↓
JSON API
   ↓
Zod Validation
   ↓
TypeScript Domain
```

> **If the backend changes, the frontend breaks immediately — by design.**

---

# 🏛 Part 12: Enterprise-Grade Extensions

---

Add progressively:

🔐 Refresh token rotation
📦 OpenAPI schema → TS generation
🧪 Contract tests (backend ↔ frontend)
🧩 Multi-tenant auth
📊 Audit logging
🚀 CI/CD with type gates

---

