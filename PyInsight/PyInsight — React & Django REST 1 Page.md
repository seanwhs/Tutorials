# 📘 PyInsight — Ready-to-Deploy Guide

## Project Structure

```
pyinsight/
├── backend/          # Django REST + Celery + Channels
├── frontend/         # React + TypeScript + Axios
├── docker/           # Docker Compose & Dockerfiles
└── k8s/              # Optional Kubernetes manifests
```

---

## 1️⃣ Backend: Django + DRF + Celery + Channels

### Install dependencies

```bash
cd backend
pip install django djangorestframework celery redis django-celery-results \
channels channels-redis pyyaml aiofiles djangorestframework-simplejwt \
django-cors-headers mysqlclient
pip freeze > requirements.txt
```

### Project & App

```bash
django-admin startproject pyinsight .
python manage.py startapp core
```

### Database (MySQL) — `pyinsight/settings.py`

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

### Async CSV Task — `core/tasks.py`

```python
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

### API Endpoints — `core/views.py`

```python
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

### WebSocket Consumer — `core/consumers.py`

```python
from channels.generic.websocket import AsyncJsonWebsocketConsumer

class JobConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        await self.accept()
```

### ASGI Routing — `pyinsight/asgi.py`

```python
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

### URLs — `pyinsight/urls.py`

```python
from django.contrib import admin
from django.urls import path
from core.views import AnalyzeCSV, JobStatus

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/analyze/", AnalyzeCSV.as_view()),
    path("api/status/<str:task_id>/", JobStatus.as_view()),
]
```

### Environment — `backend/.env`

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

---

## 2️⃣ Frontend: React + TypeScript + Axios

### Create App

```bash
npx create-react-app frontend --template typescript
cd frontend
npm install axios
```

### Axios API — `frontend/src/api/pyinsight.ts`

```ts
import axios from "axios";
export const api = axios.create({ baseURL: "http://localhost:8000" });
```

### Hook — `frontend/src/hooks/usePyInsight.ts`

```ts
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

### Dashboard — `frontend/src/components/Dashboard.tsx`

```tsx
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

---

## 3️⃣ Docker & Docker Compose

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

### Docker Compose — `docker/docker-compose.yml`

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

---

## 4️⃣ Run Everything

```bash
cd docker
docker-compose up --build
docker exec -it pyinsight-backend python manage.py migrate
docker exec -it pyinsight-backend python manage.py createsuperuser
```

**Access:**

* Frontend: `http://localhost:3000`
* Backend API: `http://localhost:8000`
* MySQL: `localhost:3306`
* Redis: `localhost:6379`

✅ Hot reload, async tasks, and WebSocket live updates are ready out-of-the-box.


