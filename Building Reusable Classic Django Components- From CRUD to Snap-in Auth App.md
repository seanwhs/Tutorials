## **Step 1: Create the CRUD Django Project**

### **1.1 Project Setup**

```bash
mkdir django_crud_project
cd django_crud_project
python -m venv venv
source venv/bin/activate       # Windows: venv\Scripts\activate
pip install django
django-admin startproject crud_project .
```

> ✅ Sets up a new Django project named `crud_project`.

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

> Simple Post model with title, content, and timestamps.

---

### **1.4 Create Forms (blog/forms.py)**

```python
from django import forms
from .models import Post

class PostForm(forms.ModelForm):
    class Meta:
        model = Post
        fields = ['title', 'content']
```

> Form for creating and updating posts.

---

### **1.5 Implement Views (blog/views.py)**

```python
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import Post
from .forms import PostForm

@login_required
def post_list(request):
    posts = Post.objects.all()
    return render(request, 'blog/post_list.html', {'posts': posts})

@login_required
def post_create(request):
    if request.method == 'POST':
        form = PostForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('post_list')
    else:
        form = PostForm()
    return render(request, 'blog/post_form.html', {'form': form})

@login_required
def post_update(request, pk):
    post = get_object_or_404(Post, pk=pk)
    if request.method == 'POST':
        form = PostForm(request.POST, instance=post)
        if form.is_valid():
            form.save()
            return redirect('post_list')
    else:
        form = PostForm(instance=post)
    return render(request, 'blog/post_form.html', {'form': form})

@login_required
def post_delete(request, pk):
    post = get_object_or_404(Post, pk=pk)
    if request.method == 'POST':
        post.delete()
        return redirect('post_list')
    return render(request, 'blog/post_confirm_delete.html', {'post': post})
```

> CRUD views protected with `login_required`.

---

### **1.6 Configure URLs**

**blog/urls.py**

```python
from django.urls import path
from . import views

urlpatterns = [
    path('', views.post_list, name='post_list'),
    path('create/', views.post_create, name='post_create'),
    path('update/<int:pk>/', views.post_update, name='post_update'),
    path('delete/<int:pk>/', views.post_delete, name='post_delete'),
]
```

**crud_project/urls.py**

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('blog/', include('blog.urls')),
]
```

---

### **1.7 Templates**

Create `templates/blog/`:

* `post_list.html`
* `post_form.html`
* `post_confirm_delete.html`

> Use basic HTML forms and loops for posts.

---

### **1.8 Settings**

Add `'blog'` to `INSTALLED_APPS`.

No auth needed yet.

---

### **1.9 Migrate & Run**

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py runserver
```

> ✅ CRUD project accessible at `http://127.0.0.1:8000/blog/`.

---

## **Step 2: Create Standalone Auth App with Custom User, Profiles, and Tenants**

### **2.1 Project Setup**

```bash
mkdir django_auth_app
cd django_auth_app
python -m venv venv
source venv/bin/activate
pip install django
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

### **2.3 Forms for Registration and Login (auth_app/forms.py)**

```python
from django import forms
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from .models import CustomUser

class CustomUserCreationForm(UserCreationForm):
    class Meta:
        model = CustomUser
        fields = ['username', 'email', 'password1', 'password2', 'tenant']

class CustomAuthenticationForm(AuthenticationForm):
    username = forms.CharField(max_length=150)
    password = forms.CharField(widget=forms.PasswordInput)
```

---

### **2.4 Auth Views (auth_app/views.py)**

```python
from django.shortcuts import render, redirect
from django.contrib.auth import login, authenticate, logout
from django.contrib import messages
from .forms import CustomUserCreationForm, CustomAuthenticationForm

def register_view(request):
    if request.method == 'POST':
        form = CustomUserCreationForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            messages.success(request, "Registered successfully")
            return redirect('home')  # placeholder
    else:
        form = CustomUserCreationForm()
    return render(request, 'auth_app/register.html', {'form': form})

def login_view(request):
    if request.method == 'POST':
        form = CustomAuthenticationForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            return redirect('home')  # placeholder
        else:
            messages.error(request, "Invalid credentials")
    else:
        form = CustomAuthenticationForm()
    return render(request, 'auth_app/login.html', {'form': form})

def logout_view(request):
    logout(request)
    return redirect('login')
```

---

### **2.5 Auth URLs (auth_app/urls.py)**

```python
from django.urls import path
from . import views

urlpatterns = [
    path('register/', views.register_view, name='register'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
]
```

---

### **2.6 Templates**

Create `templates/auth_app/`:

* `register.html`
* `login.html`

> Classic Django forms for registration and login.

---

### **2.7 Settings Updates (auth_project/settings.py)**

```python
INSTALLED_APPS = [
    ...
    'auth_app',
]

AUTH_USER_MODEL = 'auth_app.CustomUser'
LOGIN_URL = 'login'
LOGIN_REDIRECT_URL = 'home'
```

> Auth app is standalone, reusable, and includes tenants, profiles, and custom user.

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
    path('blog/', include('blog.urls')),
    path('auth/', include('auth_app.urls')),  # snap-in auth
]
```

5. Protect CRUD views using `@login_required`.
6. Run migrations and create superuser:

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

> ✅ CRUD project now includes **classic Django standalone auth** with **custom user, profiles, tenants, login/register forms**.

---

## **Repository Structure Overview**

```
django-modular-tutorial/
│
├── 1_crud_project/
│   ├── blog/
│   ├── crud_project/
│   ├── templates/blog/
│   ├── manage.py
│   └── venv/
│
├── 2_standalone_auth_app/
│   ├── auth_project/
│   ├── auth_app/
│   │   ├── models.py
│   │   ├── forms.py
│   │   ├── views.py
│   │   └── urls.py
│   ├── templates/auth_app/
│   ├── manage.py
│   └── venv/
│
└── 3_crud_with_auth/
    ├── blog/
    ├── auth_app/
    ├── crud_project/
    ├── templates/
    │   ├── blog/
    │   └── auth_app/
    ├── manage.py
    └── venv/
```

---

### **Notes**

* **1_crud_project**: Standalone CRUD app, no auth.
* **2_standalone_auth_app**: Classic Django reusable auth app with custom user, profiles, tenants, login/register.
* **3_crud_with_auth**: CRUD + auth integrated, ready to run.

---

### **Running Any Project**

```bash
source venv/bin/activate   # Windows: venv\Scripts\activate
python manage.py makemigrations
python manage.py migrate
python manage.py runserver
```

> All projects are independent; the auth app can be snapped in without touching CRUD logic.

---
