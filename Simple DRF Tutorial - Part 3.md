# 📝 Part 3 - Real-Time WebSocket Updates

---

## 1️⃣ Backend — Django Channels Setup

### Install Packages

```bash
pip install channels channels-redis
```

### Update `settings.py`

```python
INSTALLED_APPS += ['channels']

# Channels
ASGI_APPLICATION = "myproject.asgi.application"

# Redis as channel layer
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.core.RedisChannelLayer",
        "CONFIG": {
            "hosts": [("localhost", 6379)],
        },
    },
}
```

---

### Create ASGI Entry Point

* `myproject/asgi.py`:

```python
import os
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from django.core.asgi import get_asgi_application
import api.routing

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myproject.settings")

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(api.routing.websocket_urlpatterns)
    ),
})
```

---

### Define WebSocket Routes

* `api/routing.py`:

```python
from django.urls import path
from . import consumers

websocket_urlpatterns = [
    path("ws/tasks/", consumers.TaskConsumer.as_asgi()),
]
```

---

### Create a WebSocket Consumer

* `api/consumers.py`:

```python
import json
from channels.generic.websocket import AsyncWebsocketConsumer

class TaskConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.channel_layer.group_add("tasks", self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard("tasks", self.channel_name)

    async def task_update(self, event):
        # Send task data to WebSocket
        await self.send(text_data=json.dumps(event["data"]))
```

---

### Trigger WebSocket Updates

Whenever a task is created or updated, broadcast it:

* `api/signals.py`:

```python
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Task
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from .serializers import TaskSerializer

@receiver(post_save, sender=Task)
def broadcast_task_update(sender, instance, created, **kwargs):
    channel_layer = get_channel_layer()
    serializer = TaskSerializer(instance)
    async_to_sync(channel_layer.group_send)(
        "tasks",
        {
            "type": "task_update",
            "data": serializer.data,
        }
    )
```

* Register signals in `api/apps.py` or `api/__init__.py`:

```python
default_app_config = "api.apps.ApiConfig"
```

---

## 2️⃣ Frontend — React WebSocket Integration

### Connect to WebSocket

* `src/hooks/useTasksWS.js`:

```javascript
import { useEffect, useState } from "react";

export default function useTasksWS() {
  const [tasks, setTasks] = useState([]);

  useEffect(() => {
    const ws = new WebSocket("ws://localhost:8000/ws/tasks/");

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      setTasks((prev) => {
        const index = prev.findIndex((t) => t.id === data.id);
        if (index >= 0) {
          // Update existing task
          const newTasks = [...prev];
          newTasks[index] = data;
          return newTasks;
        } else {
          // Add new task
          return [...prev, data];
        }
      });
    };

    ws.onclose = () => console.log("WebSocket disconnected");
    return () => ws.close();
  }, []);

  return tasks;
}
```

---

### Use WebSocket Hook in Dashboard

* `TaskDashboard.js`:

```javascript
import useTasksWS from "../hooks/useTasksWS";

export default function TaskDashboard() {
  const tasks = useTasksWS();

  return (
    <div>
      <h2>Tasks (Real-Time Updates)</h2>
      <ul>
        {tasks.map((task) => (
          <li key={task.id}>
            {task.title} - {task.completed ? "✅" : "❌"}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

* Now any task created, updated, or deleted in Django will **immediately appear on the React dashboard**.

---

## 3️⃣ Test Real-Time Updates

1. Run **Redis** locally:

```bash
redis-server
```

2. Run Django server with ASGI:

```bash
python manage.py runserver
```

3. Run React frontend:

```bash
npm start
```

4. Open multiple browser tabs at `http://localhost:3000`.
5. Create or update tasks via Django admin or DRF endpoints — changes appear **live** in all tabs.

---

## ✅ Key Takeaways

* **WebSocket Integration:** Django Channels + Redis pushes updates to clients in real-time.
* **Signals + Channels:** Triggered by database changes; ensures reactive dashboards.
* **React Live Updates:** Hook-based WebSocket listener keeps UI synchronized with backend.
* **Scalable Architecture:** Decoupled backend, message-driven updates, non-blocking frontend.

---

