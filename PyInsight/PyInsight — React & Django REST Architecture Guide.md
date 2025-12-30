# 📘 PyInsight — Architecture, Async Flow & Deployment

---

## 1️⃣ High-Level Architecture Overview

PyInsight is built on a **modern asynchronous stack**, designed to handle multi-gigabyte CSV files without blocking the UI. By decoupling data ingestion from analytics, users get **real-time partial results** while heavy computations execute asynchronously.

```
🟦 USER
└─ Upload CSV & Select Columns
      │
      ▼
🟩 FRONTEND (React/TypeScript)
├─ Upload CSV file
├─ Select columns, filters, and options
├─ POST /api/analyze() → submit analysis request
├─ Poll API or subscribe to WebSocket events
└─ Render JSON, tables, charts, and visualizations
      │
      ▼
🟨 BACKEND API (Django REST)
├─ Validate CSV structure, format, and required columns
├─ Return async task_id to frontend
└─ Schedule Celery task for asynchronous processing
      │
      ▼
🟪 CELERY WORKER
├─ Compute CSV summaries: stats, aggregations, correlations
├─ Evaluate configurable business rules (rules.yaml)
├─ Execute plugins or ML pipelines for advanced analytics
└─ Save incremental progress (Redis) and final results (MySQL/PostgreSQL)
      │
      ▼
🟫 STORAGE
├─ Redis (ephemeral progress tracking & pub/sub)
└─ MySQL/PostgreSQL (persistent storage, audits, historical analytics)
      │
      ▼
🟧 WEBSOCKET / CHANNELS
├─ Push incremental updates to subscribed clients
└─ Notify dashboard in real-time
      │
      ▼
🟩 DASHBOARD UI
├─ Render live summaries and interactive tables
├─ Highlight rule violations & alerts
├─ Show plugin outputs, charts, and heatmaps
└─ Provide dynamic filtering, sorting, and column selection
```

**Key Highlights:**

* Each component is **decoupled**, enabling maintainability and scalability.
* **Parallel plugin/ML execution** allows modular extensions.
* **Incremental updates** via WebSocket + Redis provide a reactive UI.
* Supports **interactive visualizations**, letting users explore partial results immediately.

---

## 2️⃣ Async Timeline & Component Flow
The following sequence highlights the non-blocking nature of the system. The user never waits for the "Processing" spinner to finish before seeing the first data points.
```
Time →
🟦 USER       🟩 FRONTEND        🟨 BACKEND API      🟪 CELERY WORKER      🟫 STORAGE       🟧 WEBSOCKET      🟩 DASHBOARD
----        --------        -----------      -------------     ---------       ---------        ---------
  |               |                |                  |                 |                |               |
  | Upload CSV    |                |                  |                 |                |               |
  |-------------->|                |                  |                 |                |               |
  |               | POST /api/analyze()           |                  |                |               |
  |               |------------------------------->| Validate CSV & columns|              |               |
  |               |                                |----------------->| Schedule Celery task|             |
  |               | Receive task_id                |                  | Store initial state |             |
  |               |<-------------------------------|                  |               |               |
  | Poll / WS     | GET /api/status / WS event     |                  |               |               |
  |-------------->|------------------------>|                        |                 |               |
  | Render partial|                                |                  | Push incremental updates ----->| Render partial results|
  ▼               ▼                                ▼                  ▼                 ▼               ▼               ▼
Final Analytics  Live JSON / Table Updates   Async task execution    CSV summarization &   Redis = ephemeral  WS pushes partial   Dashboard renders
& Rule Violations updates on Dashboard       (task_id returned)     rules evaluation      MySQL = persistent + final results      analytics & plugin outputs
```

**Notes:**

* Frontend immediately receives `task_id` → **non-blocking UX**
* Heavy tasks run asynchronously in Celery → **async offloading**
* Redis + WebSocket → **incremental updates**
* MySQL/PostgreSQL → **persistent final results & audit**

---

## 3️⃣ Backend Component Sequence
The backend follows a strict pipeline to ensure data integrity before any computation begins.
```
CSV Upload
  │
  ▼
API View (AnalyzeCSV)
  ├─ validators.py → Checks CSV structure, required headers, data types
  ├─ serializers.py → Validates request payload
  └─ tasks.py → Schedule Celery task, generate task_id, store metadata
      │
      ▼
Celery Worker
  ├─ analysis.py → Compute stats, aggregations, correlations
  ├─ rules.py + rules.yaml → Evaluate configurable business rules
  ├─ plugins/base.py → Execute ML models or analytics plugins
  └─ Store results → Redis (ephemeral) + MySQL/PostgreSQL (persistent)
```

**Design Rationale:**

* YAML-driven rules → **non-developer configurable**
* Plugin hooks → **modular extensions**
* Storage separation → Redis (progress) vs MySQL (persistent)

---

## 4️⃣ Frontend & Dashboard Flow
React components are built to be state-aware, reacting to partial data chunks as they arrive from the WebSocket stream.
```
Dashboard.tsx
  │ Upload CSV & select columns
  ▼
usePyInsight Hook
  ├ analyze(file, columns) → POST /api/analyze() → receive task_id
  └ status(task_id) → Poll GET /api/status/<task_id> or subscribe WS events
       │
Dashboard renders:
  • Partial summaries in real-time
  • Rule violations (severity & priority)
  • Plugin/ML outputs (charts, tables, visualizations)
  • Interactive filtering, sorting, column selection
```

**Notes:** Reactive, incremental rendering, dynamic visualizations.

---

## 5️⃣ WebSocket Event Flow
To achieve "Live" updates, we utilize a Pub/Sub (Publisher/Subscriber) pattern via Redis. This decouples the worker's progress from the API's web server logic.
```
🟪 Celery Worker
      │ Publishes task events → 🟫 Redis (pub/sub)
      ▼
🟨 Backend Channels (JobConsumer)
      │ Subscribes to Redis events → forwards to WS clients
      ▼
🟧 WebSocket Client
      │ Receives incremental updates
      ▼
🟩 Dashboard UI
      │ Updates partial results, highlights violations, renders plugin outputs
```

---

## 6️⃣ Docker Deployment Architecture
The entire ecosystem is containerized, ensuring that the development environment perfectly mirrors production.
```
+-----------+    +--------+    +------------+
|  🟫 MySQL |    | 🟫 Redis|    | 🟨 Backend |
| Database  |    | Cache  |    | Django +  |
| 8.x       |    | 7.x    |    | Celery + |
+-----+-----+    +---+----+    | Channels |
      │              │          +-----+-----+
 Docker Compose network connects all containers
      │
🟩 Frontend React container → Axios + WebSocket
      │
🟦 User Dashboard → interacts with backend
```

* All components containerized → consistent dev/prod environments
* Docker Compose → simplifies local deployment
* Kubernetes-ready → supports horizontal scaling
* CI/CD friendly → reproducible deployments

---

## 7️⃣ Dockerfile Examples

### Backend Dockerfile (`backend/Dockerfile`)

```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy code
COPY backend/ .

# Collect static files (if any)
RUN python manage.py collectstatic --noinput

EXPOSE 8000
CMD ["gunicorn", "pyinsight.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "4"]
```

### Frontend Dockerfile (`frontend/Dockerfile`)

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY frontend/package.json frontend/package-lock.json ./
RUN npm install

COPY frontend/ .
RUN npm run build

EXPOSE 3000
CMD ["npm", "run", "start"]
```

### Celery Worker Dockerfile (`celery/Dockerfile`)

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .

CMD ["celery", "-A", "pyinsight", "worker", "--loglevel=info"]
```

---

## 8️⃣ docker-compose.yml Example

```yaml
version: "3.9"

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: pyinsight-backend
    command: gunicorn pyinsight.wsgi:application --bind 0.0.0.0:8000 --workers 4
    volumes:
      - ./backend:/app
    ports:
      - "8000:8000"
    depends_on:
      - db
      - redis

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: pyinsight-frontend
    ports:
      - "3000:3000"
    depends_on:
      - backend

  celery:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: pyinsight-celery
    command: celery -A pyinsight worker --loglevel=info
    depends_on:
      - backend
      - redis
      - db

  redis:
    image: redis:7-alpine
    container_name: pyinsight-redis
    ports:
      - "6379:6379"

  db:
    image: mysql:8.0
    container_name: pyinsight-db
    environment:
      MYSQL_DATABASE: pyinsight
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_USER: pyinsightuser
      MYSQL_PASSWORD: pyinsightpass
    ports:
      - "3306:3306"
```

**Notes:**

* All services share a Docker network → easy communication
* Redis = ephemeral progress/pub-sub, MySQL = persistent storage
* Frontend & backend container ports exposed for local and cloud deployment
* Cloud deployment is seamless using the same images + Kubernetes or ECS

---

## 9️⃣ Unified Async Swimlane
This view summarizes the handoff points between every major actor in the system.
```
🟦 USER → 🟩 FRONTEND → 🟨 BACKEND → 🟪 CELERY → 🟫 STORAGE → 🟧 WEBSOCKET → 🟩 DASHBOARD
Select CSV/Columns → Upload CSV → Validate & Return task_id → Summarize CSV, Evaluate Rules, Execute Plugins → Redis/MySQL → Push incremental updates → Render partial & final analytics
```

---

## 🔟 Key Takeaways

1. **Decoupled, modular architecture** → easy maintenance & scalability
2. **Asynchronous workflows** → responsive UX even for very large CSVs
3. **Incremental feedback (Redis + WebSocket)** → live dashboards
4. **Flexible rule engine & plugin/ML pipelines** → business-driven customization
5. **Containerized & cloud-ready** → deploy locally via Docker Compose or to cloud clusters

---


Do you want me to generate that diagram next?
