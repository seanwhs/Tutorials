# 📝 DRF + Channels + Celery — Real-Time Async CSV Processing

---

## 1️⃣ Install Required Packages

```bash
pip install celery redis pandas djangorestframework channels channels-redis
```

* **Celery:** Handles heavy computation asynchronously.
* **Redis:** Used both as Celery broker and Channels backend.
* **Pandas:** Efficient CSV parsing.
* **DRF + Channels:** API + WebSocket updates.

---

## 2️⃣ Configure Celery

* `myproject/celery.py`:

```python
import os
from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myproject.settings")
app = Celery("myproject")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
```

* `myproject/__init__.py`:

```python
from .celery import app as celery_app

__all__ = ("celery_app",)
```

* `settings.py`:

```python
CELERY_BROKER_URL = "redis://localhost:6379/0"
CELERY_RESULT_BACKEND = "redis://localhost:6379/0"
CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"
```

---

## 3️⃣ Create CSV Analysis Task

* `api/tasks.py`:

```python
from celery import shared_task
import pandas as pd
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

@shared_task(bind=True)
def analyze_csv(self, file_path):
    channel_layer = get_channel_layer()
    chunk_size = 1000

    for chunk in pd.read_csv(file_path, chunksize=chunk_size):
        summary = {
            "rows": len(chunk),
            "columns": list(chunk.columns),
            "preview": chunk.head(5).to_dict(orient="records")
        }

        async_to_sync(channel_layer.group_send)(
            "tasks",
            {
                "type": "task_update",
                "data": {"task_id": self.request.id, "summary": summary}
            }
        )
    return {"status": "completed", "task_id": self.request.id}
```

* **Explanation:**

  * Reads CSV in chunks (`chunksize`) to avoid memory overload.
  * Sends **incremental summaries** to the WebSocket group `"tasks"`.
  * Returns a final completion status.

---

## 4️⃣ Create DRF API to Trigger Task

* `api/views.py`:

```python
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .tasks import analyze_csv
import tempfile

class CSVUploadView(APIView):
    def post(self, request):
        csv_file = request.FILES.get("file")
        if not csv_file.name.endswith(".csv"):
            return Response({"error": "Invalid file format"}, status=status.HTTP_400_BAD_REQUEST)

        # Save temporarily
        temp_file = tempfile.NamedTemporaryFile(delete=False)
        for chunk in csv_file.chunks():
            temp_file.write(chunk)
        temp_file.close()

        task = analyze_csv.delay(temp_file.name)
        return Response({"task_id": task.id})
```

---

## 5️⃣ Frontend — Real-Time CSV Dashboard

* `useCSVTasksWS.js` (React hook):

```javascript
import { useEffect, useState } from "react";

export default function useCSVTasksWS(taskId) {
  const [updates, setUpdates] = useState([]);

  useEffect(() => {
    const ws = new WebSocket("ws://localhost:8000/ws/tasks/");

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.task_id === taskId) {
        setUpdates((prev) => [...prev, data.summary]);
      }
    };

    return () => ws.close();
  }, [taskId]);

  return updates;
}
```

* `CSVDashboard.js`:

```javascript
import useCSVTasksWS from "../hooks/useCSVTasksWS";

export default function CSVDashboard({ taskId }) {
  const updates = useCSVTasksWS(taskId);

  return (
    <div>
      <h2>CSV Analysis Updates</h2>
      {updates.map((u, index) => (
        <div key={index}>
          <p>Rows: {u.rows}</p>
          <p>Columns: {u.columns.join(", ")}</p>
          <pre>{JSON.stringify(u.preview, null, 2)}</pre>
          <hr />
        </div>
      ))}
    </div>
  );
}
```

---

## 6️⃣ Run Services Locally

1. **Redis:**

```bash
redis-server
```

2. **Celery Worker:**

```bash
celery -A myproject worker -l info
```

3. **Django ASGI Server:**

```bash
python manage.py runserver
```

4. **React Frontend:**

```bash
npm start
```

*Upload a CSV via API or frontend, and watch incremental updates appear in **real-time**.*

---

## 7️⃣ Optional: Docker Compose for Local Deployment

```yaml
version: '3.9'
services:
  redis:
    image: redis:7
    ports:
      - "6379:6379"

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
    ports:
      - "5432:5432"

  backend:
    build: .
    command: daphne -b 0.0.0.0 -p 8000 myproject.asgi:application
    volumes:
      - .:/code
    ports:
      - "8000:8000"
    depends_on:
      - redis
      - db

  worker:
    build: .
    command: celery -A myproject worker -l info
    volumes:
      - .:/code
    depends_on:
      - redis
      - db

  frontend:
    build:
      context: ./frontend
    ports:
      - "3000:3000"
```

---

### ✅ Key Benefits

* **Non-blocking CSV processing:** Celery handles large files asynchronously.
* **Incremental updates:** Users see real-time progress via WebSocket.
* **Reactive dashboard:** React renders partial analytics immediately.
* **Scalable & containerized:** Redis + Celery + Channels + React architecture is production-ready.

---

