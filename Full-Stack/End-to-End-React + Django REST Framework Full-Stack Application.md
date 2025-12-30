# **End-to-End Engineering Handbook: React + Django REST Framework Full-Stack Application**

**Edition:** 1.1
**Frontend Framework:** React (TypeScript)
**Backend Framework:** Django REST Framework (DRF)
**Database:** SQLite (for development, scalable to MySQL/PostgreSQL)
**Deployment:** Dockerized (React + DRF)
**Audience:** Engineers, Full-Stack Developers, Architects

---

## **Executive Summary**

This handbook provides a **complete blueprint** to build **TaskHub**, a multi-user, multi-tenant task management system featuring:

* **Authenticated CRUD APIs** via DRF
* **Role-based access control** for tenants
* **Audit logging** for compliance
* **React SPA frontend** consuming DRF APIs
* **Unit, integration, and end-to-end testing**
* **Containerized deployment** ready for cloud production

It is designed so that **readers can follow step-by-step from system conception, through development, testing, and finally cloud deployment**.

---

## **Module Map**

| Module | Topic                                         |
| ------ | --------------------------------------------- |
| 1      | System Conception & Requirements Engineering  |
| 2      | Architecture & Design Decisions               |
| 3      | Backend Environment & DRF Setup               |
| 4      | Frontend Environment & React Setup            |
| 5      | Database Design & Models                      |
| 6      | API Implementation (DRF)                      |
| 7      | Authentication & Permissions                  |
| 8      | React Frontend Components & API Integration   |
| 9      | Testing Strategy (Backend + Frontend)         |
| 10     | Production Hardening & Security               |
| 11     | Containerization (React + DRF)                |
| 12     | Deployment to Cloud                           |
| 13     | Operational Considerations                    |
| 14     | Multi-Tenant Extension                        |
| 15     | Audit Logging Module                          |
| 16     | Advanced Multi-Tenant Production Enhancements |

---

# **Module 1 – System Conception & Requirements Engineering**

### **Step 1: Define the Problem**

We are building **TaskHub**, a multi-user task management system:

* Users can **authenticate**, create, update, delete, and view tasks
* Roles per tenant determine permissions (**Admin, Manager, User**)
* Each tenant is isolated (**multi-tenancy**)
* Audit logging captures **who did what**
* Frontend SPA communicates via **DRF REST API**

### **Step 2: Functional Requirements**

* User authentication (JWT)
* Task CRUD operations
* Tenant-based role access
* Admin oversight of tenant users
* Audit logs for compliance

### **Step 3: Non-Functional Requirements**

| Category        | Requirement                                   |
| --------------- | --------------------------------------------- |
| Security        | JWT authentication, role-based access, HTTPS  |
| Maintainability | Modular frontend & backend design             |
| Testability     | Unit, integration, and e2e tests              |
| Deployability   | Dockerized containers                         |
| Scalability     | SQLite dev, MySQL/PostgreSQL production-ready |

---

# **Module 2 – Architecture & Design Decisions**

### **Backend Architecture**

* **DRF ViewSets** for REST APIs
* **Models:** Task, Tenant, UserProfile
* **Permissions:** Role-based, multi-tenant enforcement
* **Audit logging** on create/update/delete

### **Frontend Architecture**

* **React SPA** with functional components & hooks
* **Axios** for API calls
* **React Router** for navigation
* **Context API** for authentication state

### **Multi-Tenant Architecture**

* Tenant isolation via database foreign keys
* API querysets filtered by tenant
* Roles enforce access per tenant

---

# **Module 3 – Backend Environment & DRF Setup**

### **Step 1: Create Virtual Environment**

```bash
python -m venv venv
source venv/bin/activate  # Linux/macOS
venv\Scripts\activate     # Windows
```

### **Step 2: Install Dependencies**

```bash
pip install django djangorestframework djangorestframework-simplejwt pytest pytest-django
```

`requirements.txt`:

```
Django>=4.2
djangorestframework
djangorestframework-simplejwt
pytest
pytest-django
```

### **Step 3: Create Django Project & App**

```bash
django-admin startproject taskhub_backend
cd taskhub_backend
python manage.py startapp tasks
```

### **Step 4: Configure DRF**

```python
# settings.py
INSTALLED_APPS = [
    ...
    'rest_framework',
    'tasks',
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

# **Module 4 – Frontend Environment & React Setup**

### **Step 1: Create React App**

```bash
npx create-react-app taskhub-frontend --template typescript
cd taskhub-frontend
npm install axios react-router-dom
```

### **Step 2: Project Structure**

```
src/
├── api/
│   └── tasks.ts
├── components/
│   ├── TaskList.tsx
│   ├── TaskForm.tsx
│   └── Login.tsx
├── context/
│   └── AuthContext.tsx
├── App.tsx
└── index.tsx
```

---

# **Module 5 – Database Design & Models**

```python
# tasks/models.py
from django.db import models
from django.contrib.auth.models import User

class Tenant(models.Model):
    name = models.CharField(max_length=100, unique=True)

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    role = models.CharField(max_length=10, choices=[('ADMIN','Admin'),('MANAGER','Manager'),('USER','User')], default='USER')

class Task(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

**Step 1:** Apply migrations:

```bash
python manage.py makemigrations
python manage.py migrate
```

---

# **Module 6 – API Implementation (DRF)**

### **Step 1: Create Serializers**

```python
# tasks/serializers.py
from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = '__all__'
        read_only_fields = ('owner','tenant')
```

### **Step 2: Create ViewSets**

```python
# tasks/views.py
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Task
from .serializers import TaskSerializer

class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        tenant = self.request.user.userprofile.tenant
        return Task.objects.filter(tenant=tenant)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user, tenant=self.request.user.userprofile.tenant)
```

### **Step 3: Configure URLs**

```python
# taskhub_backend/urls.py
from rest_framework import routers
from tasks.views import TaskViewSet
from django.urls import path, include

router = routers.DefaultRouter()
router.register(r'tasks', TaskViewSet)

urlpatterns = [
    path('api/', include(router.urls)),
]
```

---

# **Module 7 – Authentication & Permissions**

### **JWT Authentication**

```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    )
}
```

```bash
pip install djangorestframework-simplejwt
```

### **Role-Based Permissions Example**

```python
from rest_framework import permissions

class IsOwnerOrTenantAdmin(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        profile = request.user.userprofile
        if profile.role == 'ADMIN':
            return True
        return obj.owner == request.user
```

---

# **Module 8 – React Frontend Components & API Integration**

### **API Calls**

```ts
// src/api/tasks.ts
import axios from 'axios';

const api = axios.create({ baseURL: 'http://localhost:8000/api' });

export const getTasks = (token: string) => api.get('/tasks/', { headers: { Authorization: `Bearer ${token}` } });
export const createTask = (token: string, data: any) => api.post('/tasks/', data, { headers: { Authorization: `Bearer ${token}` } });
```

### **TaskList Component**

```ts
import { useEffect, useState } from 'react';
import { getTasks } from '../api/tasks';

export default function TaskList() {
    const [tasks, setTasks] = useState<any[]>([]);
    const token = localStorage.getItem('token')!;

    useEffect(() => {
        getTasks(token).then(res => setTasks(res.data));
    }, [token]);

    return (
        <ul>{tasks.map(task => <li key={task.id}>{task.title}</li>)}</ul>
    );
}
```

---

# **Module 9 – Testing Strategy**

### **Backend: pytest-django**

```python
import pytest
from django.contrib.auth.models import User
from tasks.models import Task

@pytest.mark.django_db
def test_task_creation():
    user = User.objects.create_user(username='u', password='p')
    task = Task.objects.create(title='Test', owner=user, tenant=user.userprofile.tenant)
    assert task.owner == user
```

### **Frontend: Jest + React Testing Library**

```ts
// TaskList.test.tsx
import { render, screen } from '@testing-library/react';
import TaskList from './TaskList';

test('renders tasks', () => {
  render(<TaskList />);
  expect(screen.getByRole('list')).toBeInTheDocument();
});
```

---

# **Module 10 – Production Hardening & Security**

* `DEBUG=False`
* HTTPS enabled
* JWT token expiration & refresh
* CORS configured for frontend
* Sensitive data via environment variables

---

# **Module 11 – Containerization**

**Backend Dockerfile**

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["gunicorn", "taskhub_backend.wsgi:application", "--bind", "0.0.0.0:8000"]
```

**Frontend Dockerfile**

```dockerfile
FROM node:20
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npx","serve","-s","build"]
```

**docker-compose.yml**

```yaml
version: '3'
services:
  backend:
    build: ./taskhub_backend
    ports:
      - "8000:8000"
  frontend:
    build: ./taskhub-frontend
    ports:
      - "3000:3000"
```

---

# **Module 12 – Deployment to Cloud**

1. Build Docker images: `docker build -t taskhub-backend ./taskhub_backend`
2. Push to registry: Docker Hub, GCP, AWS ECR
3. Deploy containers via ECS, GKE, or Cloud Run
4. Set environment variables for secrets
5. Optional: Use Nginx reverse proxy for frontend

---

# **Module 13 – Operational Considerations**

* SQLite for development, migrate to MySQL/PostgreSQL for production
* Horizontal scaling: multiple containers behind load balancer
* Tenant isolation ensures safe multi-instance deployment

---

# **Module 14 – Multi-Tenant Extension**

* Tenant + UserProfile models
* Backend API filters by tenant
* Automatic tenant assignment in `perform_create`

---

# **Module 15 – Audit Logging Module**

```python
class TaskAudit(models.Model):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='audits')
    action = models.CharField(max_length=10)
    performed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    performed_at = models.DateTimeField(auto_now_add=True)
    old_values = models.JSONField(null=True)
    new_values = models.JSONField(null=True)
```

*Hook into DRF ViewSets on create/update/delete.*

---

# **Module 16 – Advanced Multi-Tenant Production Enhancements**

* Role-based permissions per tenant
* MySQL/PostgreSQL for production
* Full field-level audit logging
* Cloud-ready deployment with Docker

---

# **Architecture & Flow Diagrams (Text-Based)**

### **1. Overall System Architecture**

```
+------------------+          +------------------+         +-------------------+
| React Frontend   |  HTTPS   | DRF Backend      |  REST   | SQLite/MySQL DB   |
+------------------+          +------------------+         +-------------------+
          ^                             ^
          |                             |
          |                             |
      JWT Token                     Role-based Access
```

---

### **2. Frontend Flow (React SPA)**

```
User Interaction
       |
       v
+------------------+     Axios Requests
| Task Components  +--------------------+
+------------------+                    |
       |                                 v
       v                         +------------------+
State Updates <------------------ | API Calls to DRF |
                                 +------------------+
```

---

### **3. Backend Flow (DRF)**

```
Incoming Request -> DRF ViewSet
         |
         v
  Authentication (JWT)
         |
         v
 Permissions Check (Tenant / Role)
         |
         v
 Serializer Validation
         |
         v
 Database Operation
         |
         v
 Response (JSON)
```

---

### **4. Multi-Tenant Data Structure**

```
Tenant Table
     |
UserProfile Table
     |
Task Table
```

---

### **5. Audit Logging Flow**

```
CRUD Action -> ViewSet Hook -> Capture old/new values -> TaskAudit Table
```

---

### **6. Cloud Deployment Architecture**

```
Users / Clients
       |
Cloud Load Balancer
       |
+-----------------+
| Frontend        |
| React + Nginx   |
+-----------------+
       |
+-----------------+
| Backend         |
| Django + DRF    |
+-----------------+
       |
Centralized DB (MySQL/PostgreSQL)
       |
Persistent Storage (S3)
       |
Monitoring & Logging
       |
CI/CD Pipeline
```

---


