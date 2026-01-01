# **Tutorial: Building a Production-Ready REST API with Django REST Framework (DRF)**

**Objective:** This tutorial will guide you through building a complete REST API using Django REST Framework. We will create a “Task Management API” with full CRUD functionality, filtering, searching, pagination, authentication, admin management, and production-ready considerations including Docker deployment and Swagger/OpenAPI documentation.

By the end of this tutorial, you will understand **how to build, structure, secure, and document a real-world API** with Django and DRF.

---

## **Section 1: Introduction and Environment Setup**

### 1.1 Introduction to DRF

Django REST Framework (DRF) extends Django’s capabilities to create **JSON-based APIs**. Key features include:

* **Serializers:** Convert complex data models to JSON and validate input.
* **ViewSets & Routers:** Simplify CRUD operations.
* **Browsable API:** Interactive interface for testing.
* **Authentication & Permissions:** Control access.
* **Filtering & Pagination:** Handle large datasets and improve usability.

DRF is **modular**, allowing incremental adoption: you can use serializers and views independently, or integrate authentication and advanced filtering as needed.

---

### 1.2 Setting up the Environment

1. **Create a project folder and virtual environment:**

```bash
mkdir drf_task_app
cd drf_task_app
python -m venv venv
```

2. **Activate the virtual environment:**

* macOS/Linux: `source venv/bin/activate`
* Windows: `venv\Scripts\activate`

3. **Install dependencies:**

```bash
pip install django djangorestframework django-filter djangorestframework-simplejwt drf-yasg
```

> **Explanation:**
>
> * `django-filter` enables filtering API results.
> * `djangorestframework-simplejwt` provides JWT authentication.
> * `drf-yasg` generates Swagger/OpenAPI documentation.

---

### 1.3 Create Project and App

1. Create the Django project:

```bash
django-admin startproject myproject .
```

2. Create the API app:

```bash
python manage.py startapp api
```

3. Add the app and DRF to `INSTALLED_APPS` in `myproject/settings.py`:

```python
INSTALLED_APPS = [
    ...
    'rest_framework',
    'django_filters',
    'drf_yasg',
    'api',
]
```

4. Configure DRF settings in `settings.py`:

```python
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 10,
    'DEFAULT_FILTER_BACKENDS': ['django_filters.rest_framework.DjangoFilterBackend',
                                'rest_framework.filters.SearchFilter',
                                'rest_framework.filters.OrderingFilter'],
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
}
```

> **Pedagogical Note:** Setting defaults here ensures consistent behavior for pagination, filtering, searching, ordering, and authentication across all API endpoints.

---

## **Section 2: Modeling the Data**

### 2.1 Create the Task Model

`api/models.py`:

```python
from django.db import models

class Task(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title
```

**Explanation:**

* `title`: Name of the task
* `description`: Optional details
* `completed`: Boolean status
* `created_at`: Auto timestamp for creation
* `updated_at`: Auto timestamp for modifications

Apply migrations:

```bash
python manage.py makemigrations
python manage.py migrate
```

---

## **Section 3: Serializers**

`api/serializers.py`:

```python
from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = '__all__'
```

> **Tip:** Explicitly listing fields instead of `__all__` is recommended in production for security and maintainability.

---

## **Section 4: ViewSets and API Views**

`api/views.py`:

```python
from rest_framework import viewsets, filters
from .models import Task
from .serializers import TaskSerializer
from rest_framework.permissions import IsAuthenticatedOrReadOnly

class TaskViewSet(viewsets.ModelViewSet):
    """
    Handles CRUD operations for tasks.
    """
    queryset = Task.objects.all().order_by('-created_at')
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    # Enable search and ordering
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description']
    ordering_fields = ['created_at', 'updated_at']
```

> **Explanation:**
>
> * `IsAuthenticatedOrReadOnly` allows public read access while restricting modifications.
> * `search_fields` supports query-based searches.
> * `ordering_fields` enables clients to sort tasks dynamically.

---

## **Section 5: URL Routing with Routers**

`api/urls.py`:

```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TaskViewSet

router = DefaultRouter()
router.register(r'tasks', TaskViewSet, basename='task')

urlpatterns = [
    path('', include(router.urls)),
]
```

Include API URLs in the main project:

`myproject/urls.py`:

```python
from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from rest_framework import permissions

# Swagger/OpenAPI schema
schema_view = get_schema_view(
    openapi.Info(
        title="Task API",
        default_version='v1',
        description="API documentation for Task management",
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
]
```

> **Explanation:**
>
> * `TokenObtainPairView` and `TokenRefreshView` provide JWT authentication endpoints.
> * Swagger/OpenAPI is integrated for interactive API documentation.

---

## **Section 6: Admin Registration**

`api/admin.py`:

```python
from django.contrib import admin
from .models import Task

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ('title', 'completed', 'created_at')
    list_filter = ('completed',)
    search_fields = ('title', 'description')
```

> **Explanation:**
> The admin interface allows for fast task management without relying solely on the API.

---

## **Section 7: Testing the API**

1. Run the server:

```bash
python manage.py runserver
```

2. Test endpoints:

* Browsable API: `http://127.0.0.1:8000/api/tasks/`
* JWT Authentication: `/api/token/`
* Swagger Docs: `/swagger/`

> Use Postman or Insomnia for automated testing. You can test JWT token issuance and secured API access.

---

## **Section 8: Production-Ready Considerations**

### 8.1 Dockerizing the Project

Create a `Dockerfile`:

```dockerfile
# Use official Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Expose port
EXPOSE 8000

# Run server
CMD ["gunicorn", "myproject.wsgi:application", "--bind", "0.0.0.0:8000"]
```

`docker-compose.yml`:

```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    command: gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
```

> **Explanation:** Docker ensures consistent deployment across environments.

---

### 8.2 Security Best Practices

* Always use JWT or OAuth2 for authentication in production.
* Set `DEBUG=False` in `settings.py`.
* Configure allowed hosts: `ALLOWED_HOSTS = ['yourdomain.com']`.
* Use HTTPS and environment variables for secrets.

---

### 8.3 API Documentation with Swagger/OpenAPI

The Swagger UI is accessible at `/swagger/`. It provides:

* Endpoint descriptions
* Request/response examples
* Authentication testing
* Interactive testing interface

> Documentation improves developer experience and is a requirement for professional APIs.

---

## **Section 9: Summary**

This tutorial covered a **full, production-ready DRF project**:

1. Environment setup with virtual environments and dependencies
2. Project and app creation
3. Task model design with timestamps and fields
4. Serializers for JSON conversion and validation
5. ViewSets with search, ordering, and permissions
6. Router-based URL configuration
7. JWT authentication for secure access
8. Admin interface for management
9. Pagination, filtering, and browsable API for usability
10. Swagger/OpenAPI documentation
11. Docker deployment for production readiness

> By following this guide, you now have a **fully functional, scalable, and maintainable REST API** suitable for both learning and production environments.
