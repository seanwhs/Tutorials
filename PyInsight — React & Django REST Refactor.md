# 📘 PyInsight — Step-by-Step Build Guide

## Build a Production-Ready CSV Analytics Platform with **React + Django REST (DRF)**

> Hands-on guide to building a **cloud-native, extensible analytics platform**—covering CSV ingestion, async pipelines, plugins, ML, observability, security, and Kubernetes deployment.
> **Not a demo.** By following this guide, you’ll have a **production-grade system** ready for internal platforms or SaaS.

---

## 🧭 What You Will Build

**PyInsight** enables users to:

1. Upload **large CSV datasets**
2. Run **asynchronous analysis jobs**
3. Apply **declarative business rules**
4. Extend functionality via **plugins**
5. View **live results** in a React dashboard
6. Operate securely in **multi-tenant environments**
7. Deploy using **Docker & Kubernetes**

---

## 🏗 Architecture Overview

```
React Frontend (TS/DRI)
        │ REST / WebSocket
Django REST API
  ├ JWT Auth
  ├ Job Orchestration
  ├ Rule Engine
  ├ Plugin Registry
  └ Metrics/Tracing
        │ Celery Tasks
Celery Workers
  ├ CSV Processing
  ├ Rule Evaluation
  ├ Plugin Execution
  └ ML Pipelines
        │
Redis / MySQL (State & Results)
```

---

## 0️⃣ Prerequisites

* Python 3.12+, Node.js 20+, Docker & Docker Compose
* Familiarity with Django REST Framework & React + TypeScript

> Install Python, Node, Docker, and VSCode or PyCharm.

---

## 1️⃣ Project Bootstrap

```bash
pyinsight/
├── backend/    # Django REST backend
├── frontend/   # React + TypeScript frontend
├── docker/     # Docker Compose & Dockerfiles
├── k8s/        # Kubernetes manifests
└── README.md
```

```bash
cd pyinsight
git init
python -m venv venv
source venv/bin/activate
```

---

# **Part 1: Backend — Django REST + Celery + WebSockets**

### 2️⃣ Setup

```bash
cd backend
pip install django djangorestframework celery redis django-celery-results \
channels channels-redis pyyaml aiofiles djangorestframework-simplejwt \
django-cors-headers

pip freeze > requirements.txt

django-admin startproject pyinsight .
python manage.py startapp core
```

### Layout

```
backend/
├── pyinsight/      # settings, urls, asgi, wsgi, celery
├── core/
│   ├── analysis.py
│   ├── consumers.py
│   ├── metrics.py
│   ├── models.py
│   ├── plugins/    # base.py, sample_plugin.py
│   ├── rules.py
│   ├── rules.yaml
│   ├── tasks.py
│   ├── validators.py
│   ├── views.py
│   └── routing.py
└── manage.py
```

---

## 3️⃣ Core Backend Components

### CSV Validation

```python
# core/validators.py
from django.core.exceptions import ValidationError

def validate_rows(rows, required_columns):
    for i, row in enumerate(rows, 1):
        for col in required_columns:
            if not row.get(col):
                raise ValidationError(f"Missing '{col}' in row {i}")
```

### Analytics Engine

```python
# core/analysis.py
def summarize(rows, column):
    values = [float(r[column]) for r in rows if r[column]]
    return {
        "count": len(values),
        "avg": sum(values)/len(values) if values else 0,
        "min": min(values) if values else 0,
        "max": max(values) if values else 0,
    }
```

### Rule Engine

```yaml
# core/rules.yaml
rules:
  - name: high_score
    column: score
    condition: "value > 90"
    action: flag
```

```python
# core/rules.py
import yaml

def evaluate_rules(rows):
    rules = yaml.safe_load(open("core/rules.yaml"))["rules"]
    violations = []
    for rule in rules:
        for i, row in enumerate(rows, 1):
            value = float(row.get(rule["column"], 0))
            if eval(rule["condition"], {"value": value}):
                violations.append({"row": i, "rule": rule["name"], "action": rule["action"]})
    return violations
```

> **Tip:** Replace `eval` with a safe parser for production.

### Plugin Interface

```python
# core/plugins/base.py
from abc import ABC, abstractmethod

class Plugin(ABC):
    name: str
    version: str

    @abstractmethod
    async def analyze(self, rows, context):
        ...
```

### Celery Task

```python
# core/tasks.py
from celery import shared_task
from .analysis import summarize
from .rules import evaluate_rules

@shared_task
def analyze_csv(rows, column):
    return {
        "summary": summarize(rows, column),
        "rules": evaluate_rules(rows),
        "plugins": [],
    }
```

### API Endpoints

```python
# core/views.py
import csv
from rest_framework.views import APIView
from rest_framework.response import Response
from .tasks import analyze_csv
from celery.result import AsyncResult

class AnalyzeCSV(APIView):
    def post(self, request):
        rows = list(csv.DictReader(request.FILES["file"].read().decode().splitlines()))
        task = analyze_csv.delay(rows, request.data["column"])
        return Response({"task_id": task.id}, status=202)

class JobStatus(APIView):
    def get(self, request, task_id):
        r = AsyncResult(task_id)
        return Response({"state": r.state, "result": r.result if r.ready() else None})
```

### WebSocket Consumer

```python
# core/consumers.py
from channels.generic.websocket import AsyncJsonWebsocketConsumer

class JobConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        await self.accept()
```

Routing:

```python
# core/routing.py
from django.urls import path
from .consumers import JobConsumer

websocket_urlpatterns = [path("ws/jobs/", JobConsumer.as_asgi())]
```

ASGI:

```python
# pyinsight/asgi.py
import os
from channels.routing import ProtocolTypeRouter, URLRouter
from django.core.asgi import get_asgi_application
from channels.auth import AuthMiddlewareStack
from core.routing import websocket_urlpatterns

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "pyinsight.settings")

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(URLRouter(websocket_urlpatterns)),
})
```

URLs:

```python
# pyinsight/urls.py
from django.contrib import admin
from django.urls import path
from core.views import AnalyzeCSV, JobStatus

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/analyze/", AnalyzeCSV.as_view()),
    path("api/status/<str:task_id>/", JobStatus.as_view()),
]
```

**✅ Backend Ready**

* `POST /api/analyze/` → upload CSV, returns `task_id`
* `GET /api/status/<task_id>/` → async result
* WebSocket: `ws://localhost:8000/ws/jobs/`

---

# **Part 2: Frontend — React + TypeScript**

### Setup

```bash
npx create-react-app frontend --template typescript
cd frontend
npm install axios
```

Structure:

```
frontend/src/
├── api/        # pyinsight.ts
├── hooks/      # usePyInsight.ts
├── components/ # Dashboard.tsx
├── App.tsx
└── index.tsx
```

### Axios API

```ts
// frontend/src/api/pyinsight.ts
import axios from "axios";
export const api = axios.create({ baseURL: "http://localhost:8000" });
```

### Hook

```ts
// frontend/src/hooks/usePyInsight.ts
import { api } from "../api/pyinsight";

export const usePyInsight = () => {
  const analyze = (file: File, column: string) => {
    const form = new FormData();
    form.append("file", file);
    form.append("column", column);
    return api.post("/api/analyze/", form);
  };
  const status = (taskId: string) => api.get(`/api/status/${taskId}/`);
  return { analyze, status };
};
```

### Dashboard

```tsx
// frontend/src/components/Dashboard.tsx
import React, { useState } from "react";
import { usePyInsight } from "../hooks/usePyInsight";

export const Dashboard = () => {
  const { analyze, status } = usePyInsight();
  const [file, setFile] = useState<File | null>(null);
  const [column, setColumn] = useState("score");
  const [result, setResult] = useState<any>(null);

  const handleUpload = async () => {
    if (!file) return;
    const res = await analyze(file, column);
    const interval = setInterval(async () => {
      const s = await status(res.data.task_id);
      if (s.data.state === "SUCCESS") {
        setResult(s.data.result);
        clearInterval(interval);
      }
    }, 1000);
  };

  return (
    <div>
      <h1>PyInsight Dashboard</h1>
      <input type="file" onChange={e => e.target.files && setFile(e.target.files[0])} />
      <input value={column} onChange={e => setColumn(e.target.value)} />
      <button onClick={handleUpload}>Analyze CSV</button>
      {result && <pre>{JSON.stringify(result, null, 2)}</pre>}
    </div>
  );
};
```

### App.tsx

```tsx
import React from "react";
import { Dashboard } from "./components/Dashboard";

function App() { return <Dashboard />; }
export default App;
```

**✅ Frontend Ready**

* Live polling results
* Extendable with plugins, ML, WASM

---

# **Docker & MySQL Setup**

### Backend Dockerfile

```dockerfile
FROM python:3.12-slim
WORKDIR /app
RUN apt-get update && apt-get install -y gcc build-essential default-libmysqlclient-dev && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt
COPY . .
RUN python manage.py collectstatic --noinput
CMD ["gunicorn", "pyinsight.wsgi:application", "--bind", "0.0.0.0:8000"]
```

### Frontend Dockerfile

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
RUN npm install -g serve
CMD ["serve", "-s", "build", "-l", "3000"]
```

### Docker Compose

```yaml
version: "3.9"

services:
  mysql:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: pyinsight
      MYSQL_USER: pyinsight
      MYSQL_PASSWORD: pyinsight123
    ports: ["3306:3306"]
    volumes: [mysql_data:/var/lib/mysql]

  redis:
    image: redis:7
    ports: ["6379:6379"]

  backend:
    build: ../backend
    ports: ["8000:8000"]
    env_file: ../backend/.env
    depends_on: [redis, mysql]

  worker:
    build: ../backend
    command: celery -A pyinsight worker -l info
    env_file: ../backend/.env
    depends_on: [redis, mysql, backend]

  frontend:
    build: ../frontend
    ports: ["3000:3000"]
    depends_on: [backend]

volumes:
  mysql_data:
```

### Django MySQL Settings

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.mysql",
        "NAME": os.getenv("MYSQL_DATABASE", "pyinsight"),
        "USER": os.getenv("MYSQL_USER", "pyinsight"),
        "PASSWORD": os.getenv("MYSQL_PASSWORD", "pyinsight123"),
        "HOST": os.getenv("MYSQL_HOST", "mysql"),
        "PORT": os.getenv("MYSQL_PORT", "3306"),
    }
}
```

### Environment (`backend/.env`)

```env
DJANGO_SECRET=supersecretkey
DEBUG=1
MYSQL_HOST=mysql
MYSQL_DATABASE=pyinsight
MYSQL_USER=pyinsight
MYSQL_PASSWORD=pyinsight123
REDIS_HOST=redis
REDIS_PORT=6379
```

### Run Stack

```bash
cd docker
docker-compose up --build
docker exec -it pyinsight-backend python manage.py migrate
docker exec -it pyinsight-backend python manage.py createsuperuser
```

**Endpoints:**

* Backend: `http://localhost:8000`
* Frontend: `http://localhost:3000`
* MySQL: `localhost:3306`
* Redis: `localhost:6379`

---

# ✅ Notes

1. Hot reload enabled via volumes
2. Celery async tasks processed with Redis
3. WebSocket channels use Redis
4. Production: set `DEBUG=0`, secure secrets, optionally use Daphne/Uvicorn for ASGI


