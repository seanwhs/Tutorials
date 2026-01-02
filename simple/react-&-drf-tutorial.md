# 📘 **React + Django REST Framework Integration**

**Goal:** Build a **full-stack Todo application** using **React functional components** and **Django REST Framework Function-Based Views (FBVs)**. By the end, you will understand **how frontend communicates with backend**, **how data flows**, and **how to structure full-stack projects professionally**.

---

# 🎯 **Learning Objectives**

After completing this tutorial, you will:

1. Understand **how React components manage state** and interact with APIs.
2. Learn **how DRF FBVs process HTTP requests** and respond with JSON.
3. Master **full CRUD operations**: GET, POST, PUT/PATCH, DELETE.
4. Understand **validation, error handling, and mental models** for request/response cycles.
5. Visualize **frontend-backend communication** with ASCII diagrams.
6. Build a **full Todo application** and expand your mental model for full-stack web development.
7. Know how to structure your **project code** professionally.

---

# 🧠 **SECTION 1 — Understanding the Full-Stack Mental Model**

Before writing any code, it is crucial to **visualize the system**.

```
  +------------------+
  |      Browser     |
  |   (React UI)     |
  +--------+---------+
           |
           | HTTP Request (GET/POST/PUT/PATCH/DELETE)
           |
  +--------v---------+
  | DRF Backend (FBV)|
  | Handles request  |
  | Serializes data  |
  +--------+---------+
           |
           | Query/Update
           |
  +--------v---------+
  | Database (SQLite/PostgreSQL)
  +------------------+
```

**Explanation / Mental Model:**

1. **React** is the **UI layer**. It handles **user input, displays state**, and triggers HTTP requests.
2. **DRF FBV** is the **API layer**. Each **function corresponds to one or more HTTP methods**. It handles **data validation, CRUD operations, and serialization**.
3. **Database** is the **persistent storage layer**. DRF interacts with it using Django ORM.

---

# 🧠 **SECTION 2 — Backend: Django REST Framework Setup**

### 2.1 Create Virtual Environment and Install Packages

```bash
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install django djangorestframework
```

**Why:**

* Virtual environment isolates dependencies.
* DRF allows you to **build REST APIs quickly**.

---

### 2.2 Project & App Creation

```bash
django-admin startproject myproject .
python manage.py startapp api
```

Update `settings.py`:

```python
INSTALLED_APPS = [
    'rest_framework',
    'api',
]
```

**Mental Model:**

* **Project** = global config and settings.
* **App** = modular component, handles tasks-related API.

---

# 🧠 **SECTION 3 — Backend: Models**

`api/models.py`:

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

Run:

```bash
python manage.py makemigrations
python manage.py migrate
```

**Mental Model:**

* **Model** = Python representation of database table.
* Each **instance** = a row in DB.
* `auto_now_add` ensures creation timestamp is stored automatically.

---

# 🧠 **SECTION 4 — Backend: Serializers**

`api/serializers.py`:

```python
from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ['id', 'title', 'description', 'completed', 'created_at']
        read_only_fields = ['id', 'created_at']
```

**Mental Model / Explanation:**

* **Serializer** = bridge between **Python objects** and **JSON**.
* Handles **validation** automatically.
* `read_only_fields` = prevents client from overwriting fields like ID.

---

# 🧠 **SECTION 5 — Backend: FBVs**

`api/views.py`:

```python
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Task
from .serializers import TaskSerializer

# GET all tasks
@api_view(['GET'])
def task_list(request):
    tasks = Task.objects.all()
    serializer = TaskSerializer(tasks, many=True)
    return Response(serializer.data)

# GET single task
@api_view(['GET'])
def task_detail(request, pk):
    try:
        task = Task.objects.get(pk=pk)
    except Task.DoesNotExist:
        return Response({'error': 'Task not found'}, status=status.HTTP_404_NOT_FOUND)
    serializer = TaskSerializer(task)
    return Response(serializer.data)

# POST new task
@api_view(['POST'])
def task_create(request):
    serializer = TaskSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# PUT/PATCH update
@api_view(['PUT', 'PATCH'])
def task_update(request, pk):
    try:
        task = Task.objects.get(pk=pk)
    except Task.DoesNotExist:
        return Response({'error': 'Task not found'}, status=status.HTTP_404_NOT_FOUND)

    partial = request.method == 'PATCH'
    serializer = TaskSerializer(task, data=request.data, partial=partial)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# DELETE task
@api_view(['DELETE'])
def task_delete(request, pk):
    try:
        task = Task.objects.get(pk=pk)
    except Task.DoesNotExist:
        return Response({'error': 'Task not found'}, status=status.HTTP_404_NOT_FOUND)
    task.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)
```

**Mental Model / Flowchart for FBV:**

```
HTTP Request -> FBV -> Check method (GET/POST/PUT/PATCH/DELETE)
   |
   |--> GET -> Query DB -> Serialize -> Response
   |--> POST -> Validate JSON -> Save to DB -> Response
   |--> PUT/PATCH -> Fetch object -> Update fields -> Save -> Response
   |--> DELETE -> Fetch object -> Delete -> Response
```

---

# 🧠 **SECTION 6 — Backend: URLs**

`api/urls.py`:

```python
from django.urls import path
from . import views

urlpatterns = [
    path('tasks/', views.task_list, name='task_list'),
    path('tasks/<int:pk>/', views.task_detail, name='task_detail'),
    path('tasks/create/', views.task_create, name='task_create'),
    path('tasks/<int:pk>/update/', views.task_update, name='task_update'),
    path('tasks/<int:pk>/delete/', views.task_delete, name='task_delete'),
]
```

Include in `myproject/urls.py`:

```python
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
]
```

**Mental Model:**

* Each **path** = HTTP endpoint
* DRF FBV handles request → returns JSON

---

# 🧠 **SECTION 7 — React Frontend (Functional Components)**

### 7.1 Mental Model

```
User Action -> React State -> fetch('API_URL') -> DRF FBV -> DB -> JSON Response -> Update React State -> Re-render
```

**Explanation:**

* **React State** = single source of truth.
* **fetch API** triggers backend request.
* **JSON** is the data interchange format.

---

# 🧠 **SECTION 8 — React Components**

### 8.1 App.js

```jsx
import { useState, useEffect } from 'react';
import TaskList from './TaskList';
import AddTask from './AddTask';

function App() {
  const [tasks, setTasks] = useState([]);

  // Fetch tasks from backend
  useEffect(() => {
    async function fetchTasks() {
      const res = await fetch('http://localhost:8000/api/tasks/');
      const data = await res.json();
      setTasks(data);
    }
    fetchTasks();
  }, []);

  return (
    <div>
      <h1>Todo App</h1>
      <AddTask setTasks={setTasks} tasks={tasks} />
      <TaskList tasks={tasks} setTasks={setTasks} />
    </div>
  );
}

export default App;
```

---

### 8.2 TaskList.js

```jsx
function TaskList({ tasks, setTasks }) {
  async function deleteTask(id) {
    await fetch(`http://localhost:8000/api/tasks/${id}/delete/`, { method: 'DELETE' });
    setTasks(tasks.filter(task => task.id !== id));
  }

  return (
    <ul>
      {tasks.map(task => (
        <li key={task.id}>
          {task.title}
          <button onClick={() => deleteTask(task.id)}>Delete</button>
        </li>
      ))}
    </ul>
  );
}

export default TaskList;
```

---

### 8.3 AddTask.js

```jsx
import { useState } from 'react';

function AddTask({ tasks, setTasks }) {
  const [title, setTitle] = useState('');

  async function handleAdd() {
    const res = await fetch('http://localhost:8000/api/tasks/create/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title })
    });
    const data = await res.json();
    setTasks([...tasks, data]);
    setTitle('');
  }

  return (
    <div>
      <input value={title} onChange={e => setTitle(e.target.value)} placeholder="Task title" />
      <button onClick={handleAdd}>Add Task</button>
    </div>
  );
}

export default AddTask;
```

---

# 🧠 **SECTION 9 — Asynchronous Mental Model**

```
React Component renders UI
       |
       | user clicks "Add" -> handleAdd()
       |
   fetch('API_URL', {method: 'POST', body})
       |
       | DRF FBV validates -> saves to DB -> returns JSON
       |
   React receives JSON -> updates state -> re-render UI
```

**Explanation:**

* React **does not block UI** while waiting for API.
* `async/await` pauses the function until **Promise resolves**.
* DRF **status codes** guide React in handling errors.

---

# 🧾 **Addendum A — Full Project Code**

```
Backend (DRF)
├── api/
│   ├── models.py
│   ├── serializers.py
│   ├── views.py
│   └── urls.py
├── myproject/
│   ├── settings.py
│   └── urls.py
└── manage.py

Frontend (React)
├── src/
│   ├── App.js
│   ├── TaskList.js
│   └── AddTask.js
└── package.json
```

---

# 🧾 **Addendum B — Visual Cheat Sheet**

```
HTTP Methods -> FBV Mapping
---------------------------
GET      -> Retrieve data
POST     -> Create data
PUT/PATCH-> Update data
DELETE   -> Delete data

React State -> Single source of truth
fetch()    -> Communication with backend
JSON       -> Standard data format

Data Flow:
User Action -> React Event -> fetch API -> DRF FBV -> DB -> JSON -> React State -> UI Update
```




Do you want me to do that next?
