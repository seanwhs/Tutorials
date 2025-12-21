# 📘 Production-Grade Django + AdminLTE + React Dashboard Handbook 

## Build, Deploy, and Maintain a Real-World Admin Dashboard

**Edition:** 8.0
**Audience:** Engineers, Bootcamp Learners, Trainers
**Level:** Beginner → Professional

**Tech Stack:**

* Django 5.x + DRF (Backend/API)
* Python 3.12+
* MySQL 8.x (Database)
* AdminLTE 3.x (UI/Components)
* React 18+ + React Router DOM (SPA)
* Vite (Frontend bundling)
* Axios, Chart.js, React Chart.js 2
* Bootstrap 5
* Nginx + Gunicorn
* HTTPS (Let’s Encrypt or self-signed cert)

---

## 🎯 Learning Outcomes

By the end of this guide, readers will:

✅ Build a **fully functional Django + React + AdminLTE dashboard**
✅ Implement **multi-level collapsible sidebar with active link highlighting**
✅ Consume Django REST API endpoints via Axios
✅ Use **MySQL database** for production-ready backend
✅ Deploy **production-ready dashboard** with Nginx, Gunicorn, HTTPS, and static file handling

---

# 🏗️ Step 1: Backend Setup (Django + MySQL)

### 1.1 Install MySQL Client

```bash
sudo apt update
sudo apt install mysql-server libmysqlclient-dev
```

* Start MySQL service:

```bash
sudo systemctl start mysql
sudo systemctl enable mysql
```

* Create database & user:

```sql
CREATE DATABASE dashboard_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'dashboard_user'@'localhost' IDENTIFIED BY 'StrongPassword!';
GRANT ALL PRIVILEGES ON dashboard_db.* TO 'dashboard_user'@'localhost';
FLUSH PRIVILEGES;
```

---

### 1.2 Django Project & MySQL Configuration

```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
pip install django djangorestframework mysqlclient django-cors-headers
django-admin startproject config .
python manage.py startapp dashboard
```

**`settings.py`**:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'dashboard_db',
        'USER': 'dashboard_user',
        'PASSWORD': 'StrongPassword!',
        'HOST': 'localhost',
        'PORT': '3306',
    }
}

INSTALLED_APPS = [
    ...,
    'dashboard',
    'rest_framework',
    'corsheaders',
]

MIDDLEWARE = ['corsheaders.middleware.CorsMiddleware'] + MIDDLEWARE
CORS_ALLOWED_ORIGINS = ["https://your-domain.com"]

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
```

---

### 1.3 Models, Serializers, and API Views

* **UserProfile** and **Order** models
* DRF serializers
* API views for `/api/users/` and `/api/orders/`

---

# ⚡ Step 2: Frontend Setup (React + AdminLTE SPA)

```bash
npm create vite@latest frontend --template react
cd frontend
npm install axios chart.js react-chartjs-2 react-router-dom
npm run dev
```

**Vite proxy config**:

```js
export default defineConfig({
  plugins: [react()],
  server: { port: 5173, proxy: { '/api': 'http://127.0.0.1:8000' } }
});
```

* Copy AdminLTE assets (`dist/css`, `dist/js`, `plugins`) to `frontend/src/assets/adminlte/`
* Import CSS in `main.jsx`:

```js
import "./assets/adminlte/css/adminlte.min.css";
import "./assets/css/custom.css";
```

* AdminLTE JS interactions replaced with React components

---

# 🏗️ Step 3: React SPA with Routing & AdminLTE

* `App.jsx` with `Routes` and `Route` for `/`, `/users`, `/sales`
* `Sidebar.jsx` with multi-level collapsible menus and SPA-aware active highlighting
* `Navbar.jsx`
* Pages: `DashboardPage.jsx`, `UsersPage.jsx`, `SalesPage.jsx`
* Axios calls to `/api/users/` and `/api/orders/`

> Sidebar, Navbar, and pages preserve **AdminLTE look & feel**.

---

# ⚡ Step 4: Development Run

**Backend**:

```bash
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

**Frontend**:

```bash
cd frontend
npm run dev
```

Access `http://localhost:5173/` → fully SPA React-driven dashboard.

---

# ⚡ Step 5: Production Deployment

## 5.1 Build React SPA

```bash
cd frontend
npm run build
```

* Copy `dist/` → `/var/www/frontend/`

---

## 5.2 Django Production Settings

```python
DEBUG = False
ALLOWED_HOSTS = ["your-domain.com"]
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
```

```bash
python manage.py collectstatic
```

* Gunicorn will serve Django API only

---

## 5.3 Nginx Configuration

**`/etc/nginx/sites-available/dashboard`**:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    root /var/www/frontend;
    index index.html;

    location / {
        try_files $uri /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /static/ {
        alias /path/to/backend/staticfiles/;
    }
}
```

* Enable HTTPS with Certbot:

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

---

## 5.4 Gunicorn Service

**`/etc/systemd/system/gunicorn.service`**:

```ini
[Unit]
Description=gunicorn daemon for Django API
After=network.target

[Service]
User=youruser
Group=www-data
WorkingDirectory=/path/to/backend
ExecStart=/path/to/backend/venv/bin/gunicorn config.wsgi:application --bind 127.0.0.1:8000

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn
```

---

# 🧪 Step 6: Access & Test

* Visit `https://your-domain.com` → React SPA dashboard
* Sidebar menus collapse/expand and highlight active routes
* Cards, charts, tables load via Axios calls to Django API
* AdminLTE layout and interactivity preserved
* MySQL handles production database

---

# ✅ Key Takeaways

* **Django + MySQL** backend
* **React SPA + AdminLTE** frontend
* Multi-level sidebar with SPA-aware active highlighting
* Production-ready deployment: **Nginx + Gunicorn + HTTPS + static files**
* Full end-to-end step-by-step guide

---

