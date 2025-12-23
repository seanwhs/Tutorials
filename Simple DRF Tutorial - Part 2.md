# 📝 Full-Stack DRF + React Tutorial

This guide extends the previous **Task API** and adds:

* JWT authentication (login/signup)
* Filtering and searching tasks
* React frontend to consume the API

---

## 1️⃣ Backend — Django REST Framework Enhancements

### Install Required Packages

```bash
pip install djangorestframework-simplejwt django-cors-headers
```

### Update `settings.py`

```python
INSTALLED_APPS = [
    ...,
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'api',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    ...,
]

# Allow React frontend (for local dev)
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
}
```

---

### JWT URL Routes

In `myproject/urls.py`:

```python
from django.urls import path, include
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
```

---

### Add Filtering to Task API

Install Django filter:

```bash
pip install django-filter
```

Update `settings.py`:

```python
REST_FRAMEWORK['DEFAULT_FILTER_BACKENDS'] = [
    'django_filters.rest_framework.DjangoFilterBackend'
]
```

Update `api/views.py`:

```python
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters

class TaskListCreateAPIView(generics.ListCreateAPIView):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['completed']
    search_fields = ['title']
    ordering_fields = ['id', 'title']
```

* Now you can filter tasks by completion, search by title, and sort results.

---

## 2️⃣ Frontend — React Setup

### Initialize React App

```bash
npx create-react-app pyinsight-frontend
cd pyinsight-frontend
npm install axios jwt-decode react-router-dom
```

---

### Axios Configuration with JWT

Create `src/api/axios.js`:

```javascript
import axios from "axios";

const API = axios.create({
  baseURL: "http://127.0.0.1:8000/api/",
});

API.interceptors.request.use((config) => {
  const token = localStorage.getItem("access_token");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default API;
```

---

### Authentication Components

* **LoginForm.js**

```javascript
import { useState } from "react";
import API from "../api/axios";
import jwt_decode from "jwt-decode";

export default function LoginForm({ setUser }) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  const handleLogin = async (e) => {
    e.preventDefault();
    const response = await API.post("token/", { username, password });
    localStorage.setItem("access_token", response.data.access);
    setUser(jwt_decode(response.data.access));
  };

  return (
    <form onSubmit={handleLogin}>
      <input placeholder="Username" value={username} onChange={(e)=>setUsername(e.target.value)} />
      <input type="password" placeholder="Password" value={password} onChange={(e)=>setPassword(e.target.value)} />
      <button type="submit">Login</button>
    </form>
  );
}
```

---

### Task Dashboard Component

* **TaskDashboard.js**

```javascript
import { useState, useEffect } from "react";
import API from "../api/axios";

export default function TaskDashboard() {
  const [tasks, setTasks] = useState([]);
  const [filter, setFilter] = useState("");

  useEffect(() => {
    fetchTasks();
  }, [filter]);

  const fetchTasks = async () => {
    const params = filter ? { completed: filter } : {};
    const response = await API.get("tasks/", { params });
    setTasks(response.data);
  };

  return (
    <div>
      <h2>Tasks</h2>
      <select onChange={(e) => setFilter(e.target.value)}>
        <option value="">All</option>
        <option value="true">Completed</option>
        <option value="false">Pending</option>
      </select>
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

---

### Routing

* **App.js**

```javascript
import { useState } from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import LoginForm from "./components/LoginForm";
import TaskDashboard from "./components/TaskDashboard";

function App() {
  const [user, setUser] = useState(null);

  return (
    <Router>
      <Routes>
        <Route path="/" element={user ? <TaskDashboard /> : <LoginForm setUser={setUser} />} />
      </Routes>
    </Router>
  );
}

export default App;
```

---

## 3️⃣ Test the Full-Stack App

1. Start Django backend:

```bash
python manage.py runserver
```

2. Start React frontend:

```bash
npm start
```

3. Open `http://localhost:3000` in your browser.
4. Log in with a Django superuser or created account.
5. View tasks, filter by completion, search, and sort.

---

## ✅ Key Takeaways

1. **JWT Authentication:** Secures API endpoints and allows token-based login.
2. **Filtering & Searching:** `django-filter` and DRF search filters improve API usability.
3. **React Integration:** Frontend dynamically consumes API data and reacts to user inputs.
4. **Full-stack Architecture:** Backend decoupled from frontend; each handles its responsibility.
5. **Ready for Expansion:** Add task creation, editing, deletion, and even WebSocket-based live updates.

---

I can also **upgrade this tutorial with live WebSocket updates** from Django Channels so React sees task updates in real-time — essentially mimicking the PyInsight incremental dashboard behavior.

Do you want me to add the **WebSocket/real-time layer next**?
