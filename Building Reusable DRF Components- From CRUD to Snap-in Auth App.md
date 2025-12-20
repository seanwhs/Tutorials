## **Step 1: Create the CRUD Django Project**

### **1.1 Project Setup**

```bash
mkdir django_crud_project
cd django_crud_project
python -m venv venv
source venv/bin/activate       # Windows: venv\Scripts\activate
pip install django djangorestframework
django-admin startproject crud_project .
```

> ✅ Sets up a new Django project named `crud_project` with DRF installed.

---

### **1.2 Create the Blog App**

```bash
python manage.py startapp blog
```

---

### **1.3 Define Models (blog/models.py)**

```python
from django.db import models

class Post(models.Model):
    title = models.CharField(max_length=255)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title
```

---

### **1.4 Create Serializers (blog/serializers.py)**

```python
from rest_framework import serializers
from .models import Post

class PostSerializer(serializers.ModelSerializer):
    class Meta:
        model = Post
        fields = ['id', 'title', 'content', 'created_at', 'updated_at']
```

---

### **1.5 Implement Views (blog/views.py)**

```python
from rest_framework import viewsets, permissions
from .models import Post
from .serializers import PostSerializer

class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
```

> Uses DRF ViewSet; all endpoints require JWT authentication.

---

### **1.6 Configure URLs (crud_project/urls.py)**

```python
from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from blog.views import PostViewSet

router = DefaultRouter()
router.register(r'posts', PostViewSet, basename='post')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
]
```

---

### **1.7 Settings (crud_project/settings.py)**

```python
INSTALLED_APPS = [
    ...
    'rest_framework',
    'blog',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
}
```

---

### **1.8 Migrate & Run**

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py runserver
```

> ✅ CRUD API accessible at `http://127.0.0.1:8000/api/posts/`.

---

## **Step 2: Create Standalone DRF Auth App with JWT**

### **2.1 Project Setup**

```bash
mkdir django_auth_app
cd django_auth_app
python -m venv venv
source venv/bin/activate
pip install django djangorestframework djangorestframework-simplejwt
django-admin startproject auth_project .
python manage.py startapp auth_app
```

---

### **2.2 Custom User, Profile, and Tenant Models (auth_app/models.py)**

```python
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.conf import settings

class Tenant(models.Model):
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name

class CustomUser(AbstractUser):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, null=True, blank=True)

class UserProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    bio = models.TextField(blank=True, null=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)

    def __str__(self):
        return f"{self.user.username}'s profile"
```

---

### **2.3 Serializers (auth_app/serializers.py)**

```python
from rest_framework import serializers
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'tenant']

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            tenant=validated_data.get('tenant')
        )
        return user

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'tenant']

class JWTTokenSerializer(serializers.Serializer):
    access = serializers.CharField()
    refresh = serializers.CharField()
```

---

### **2.4 Views (auth_app/views.py)**

```python
from rest_framework import generics, permissions
from rest_framework.response import Response
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import RegisterSerializer, UserSerializer, JWTTokenSerializer
from django.contrib.auth import get_user_model

User = get_user_model()

class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

class LoginView(generics.GenericAPIView):
    serializer_class = RegisterSerializer  # just for input

    def post(self, request, *args, **kwargs):
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(username=username, password=password)
        if user:
            refresh = RefreshToken.for_user(user)
            return Response({
                'access': str(refresh.access_token),
                'refresh': str(refresh),
            })
        return Response({"error": "Invalid credentials"}, status=400)

class UserProfileView(generics.RetrieveAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user
```

---

### **2.5 URLs (auth_app/urls.py)**

```python
from django.urls import path
from .views import RegisterView, LoginView, UserProfileView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('profile/', UserProfileView.as_view(), name='profile'),
]
```

---

### **2.6 Settings (auth_project/settings.py)**

```python
INSTALLED_APPS = [
    ...
    'rest_framework',
    'auth_app',
]

AUTH_USER_MODEL = 'auth_app.CustomUser'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
}
```

---

### **2.7 Migrate & Run**

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py runserver
```

> ✅ Auth API ready:
>
> * `POST /auth/register/`
> * `POST /auth/login/` → returns JWT
> * `GET /auth/profile/` → JWT required

---

## **Step 3: Snap-in Auth App into CRUD Project**

1. Copy `auth_app` into `django_crud_project/`.
2. Add `'auth_app'` to `INSTALLED_APPS`.
3. Update `AUTH_USER_MODEL` in `crud_project/settings.py`:

```python
AUTH_USER_MODEL = 'auth_app.CustomUser'
```

4. Include auth URLs:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('blog.urls')),  # CRUD API
    path('auth/', include('auth_app.urls')),  # Auth API
]
```

5. CRUD API now requires JWT authentication; use `Authorization: Bearer <access_token>` in headers.

6. Run migrations:

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

---

## **Repository Structure Overview**

```
django-modular-tutorial/
│
├── 1_crud_project/
│   ├── blog/
│   │   ├── models.py
│   │   ├── serializers.py
│   │   └── views.py
│   ├── crud_project/
│   ├── manage.py
│   └── venv/
│
├── 2_standalone_auth_app/
│   ├── auth_project/
│   ├── auth_app/
│   │   ├── models.py
│   │   ├── serializers.py
│   │   └── views.py
│   ├── manage.py
│   └── venv/
│
└── 3_crud_with_auth/
    ├── blog/
    ├── auth_app/
    ├── crud_project/
    ├── manage.py
    └── venv/
```

---

### **Notes**

* **1_crud_project**: Standalone DRF CRUD API.
* **2_standalone_auth_app**: Standalone DRF JWT auth with custom user, tenants, profiles.
* **3_crud_with_auth**: CRUD + auth combined; JWT-secured endpoints.

---

### **Running Any Project**

```bash
source venv/bin/activate   # Windows: venv\Scripts\activate
python manage.py makemigrations
python manage.py migrate
python manage.py runserver
```

> JWT tokens are used for authentication on all API endpoints.

---

