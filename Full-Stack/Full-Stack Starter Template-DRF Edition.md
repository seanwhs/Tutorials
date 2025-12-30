# **Full-Stack Starter Template (DRF Edition)**

---

## **1. Project Structure**

```
fullstack-app-drf/
├── backend/
│   ├── myproject/
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── users/
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── services.py
│   │   ├── urls.py
│   │   └── signals.py
│   └── manage.py
├── web/
│   ├── src/
│   │   ├── components/
│   │   │   └── UserList.tsx
│   │   ├── context/
│   │   │   └── UserContext.tsx
│   │   ├── hooks/
│   │   │   └── useUserService.ts
│   │   ├── services/
│   │   │   └── userService.ts
│   │   ├── App.tsx
│   │   └── index.tsx
│   └── package.json
├── mobile/
│   ├── src/
│   │   ├── components/
│   │   │   └── UserList.tsx
│   │   ├── context/
│   │   │   └── UserContext.tsx
│   │   ├── hooks/
│   │   │   └── useUserService.ts
│   │   ├── services/
│   │   │   └── userService.ts
│   │   └── App.tsx
│   └── package.json
└── README.md
```

---

## **2. Backend: Django + DRF**

### **2.1 Setup**

```bash
# Create project
django-admin startproject myproject backend
cd backend
python -m venv venv
source venv/bin/activate
pip install django djangorestframework psycopg2-binary
python manage.py startapp users
```

Add to `INSTALLED_APPS`:

```python
INSTALLED_APPS = [
    ...
    'rest_framework',
    'users',
]
```

---

### **2.2 Models**

`backend/users/models.py`

```python
from django.db import models

class User(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)

    def __str__(self):
        return self.name
```

Run migrations:

```bash
python manage.py makemigrations
python manage.py migrate
```

---

### **2.3 Serializers**

`backend/users/serializers.py`

```python
from rest_framework import serializers
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'name', 'email']
```

---

### **2.4 Service Layer (Facade / Adapter)**

`backend/users/services.py`

```python
from .models import User

class UserService:
    @staticmethod
    def list_users():
        return User.objects.all()

    @staticmethod
    def get_user(pk):
        return User.objects.get(pk=pk)

    @staticmethod
    def create_user(name, email):
        return User.objects.create(name=name, email=email)

    @staticmethod
    def update_user(pk, data):
        user = User.objects.get(pk=pk)
        user.name = data.get('name', user.name)
        user.email = data.get('email', user.email)
        user.save()
        return user

    @staticmethod
    def delete_user(pk):
        user = User.objects.get(pk=pk)
        user.delete()
        return True
```

---

### **2.5 Views (DRF ViewSets)**

`backend/users/views.py`

```python
from rest_framework import viewsets
from rest_framework.response import Response
from rest_framework import status
from .serializers import UserSerializer
from .services import UserService

class UserViewSet(viewsets.ViewSet):

    def list(self, request):
        users = UserService.list_users()
        serializer = UserSerializer(users, many=True)
        return Response(serializer.data)

    def retrieve(self, request, pk=None):
        user = UserService.get_user(pk)
        serializer = UserSerializer(user)
        return Response(serializer.data)

    def create(self, request):
        data = request.data
        user = UserService.create_user(data['name'], data['email'])
        serializer = UserSerializer(user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def update(self, request, pk=None):
        data = request.data
        user = UserService.update_user(pk, data)
        serializer = UserSerializer(user)
        return Response(serializer.data)

    def destroy(self, request, pk=None):
        UserService.delete_user(pk)
        return Response(status=status.HTTP_204_NO_CONTENT)
```

---

### **2.6 URLs**

`backend/users/urls.py`

```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')

urlpatterns = [
    path('', include(router.urls)),
]
```

Include in `myproject/urls.py`:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('users.urls')),
]
```

---

### ✅ **Backend Highlights**

* **Layered:** Views → Service → Models → Database
* **Patterns:** Adapter, Facade, Observer (signals), Repository (ORM abstraction)
* **Endpoints:** `/api/users/` → GET, POST, PUT, DELETE

---

## **3. Web Frontend (React + TypeScript)**

**Same as previous template**, only **API endpoint points to DRF backend**:

```ts
const API_URL = "http://localhost:8000/api/users/";
```

Use **hooks, context, service adapters** to fetch DRF endpoints. Component example:

```tsx
<ul>
  {users.map(u => <li key={u.id}>{u.name} ({u.email})</li>)}
</ul>
```

---

## **4. Mobile Frontend (React Native + TS)**

Also **same as previous mobile template**, with **API endpoint pointing to DRF backend**:

```ts
const API_URL = "http://localhost:8000/api/users/";
```

Service layer + hooks remain identical to Web for code sharing.

---

### ✅ **Full DRF Edition Features**

* **Backend:** Django REST Framework CRUD with Service Layer
* **Web Frontend:** React + TS, service adapter pattern, hooks
* **Mobile Frontend:** React Native + TS, shared hooks/services
* **Design Patterns:** Adapter, Facade, Observer, Repository
* **Cross-platform:** Web + Mobile, same backend API

