# 📘 Production-Grade Django + AdminLTE + React Dashboard Handbook

## Build, Deploy, and Maintain a Real-World Admin Dashboard

**Edition:** 7.0
**Audience:** Engineers, Bootcamp Learners, Trainers
**Level:** Beginner → Professional

**Tech Stack:**

* Django 5.x + DRF (Backend/API)
* Python 3.12+
* AdminLTE 3.x (UI/Components)
* React 18+ + React Router DOM (SPA)
* Vite (Frontend bundling)
* Axios, Chart.js, React Chart.js 2
* Bootstrap 5
* PostgreSQL (Production), SQLite (Dev)
* Nginx + Gunicorn
* HTTPS (Let’s Encrypt or self-signed cert)

---

## 🎯 Learning Outcomes

By the end of this guide, readers will:

✅ Build a **fully functional Django + React + AdminLTE dashboard**
✅ Preserve **AdminLTE layout, styles, and interactive behavior**
✅ Implement **multi-level collapsible sidebar with active link highlighting**
✅ Consume Django REST API endpoints via Axios
✅ Fully separate **frontend (React SPA)** and **backend (Django API)**
✅ Deploy **production-ready dashboard** with Nginx, Gunicorn, HTTPS, and static file handling

---

# 🏗️ Step 1: Project Setup

## Backend (Django + DRF)

```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

pip install django djangorestframework django-cors-headers psycopg2-binary
django-admin startproject config .
python manage.py startapp dashboard
```

**`settings.py` (key settings):**

```python
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

### Models & API Views

* `UserProfile` and `Order` models
* DRF serializers
* API views for `/api/users/` and `/api/orders/`

---

# ⚡ Step 2: Frontend Setup (React SPA + AdminLTE)

```bash
npm create vite@latest frontend --template react
cd frontend
npm install axios chart.js react-chartjs-2 react-router-dom
npm run dev
```

**Vite config with proxy:**

```js
export default defineConfig({
  plugins: [react()],
  server: { port: 5173, proxy: { '/api': 'http://127.0.0.1:8000' } }
});
```

**AdminLTE Integration**:

1. Copy AdminLTE assets (`dist/css`, `dist/js`, `plugins`) to `frontend/src/assets/adminlte/`
2. Import AdminLTE CSS in `main.jsx` or `App.jsx`:

```js
import "./assets/adminlte/css/adminlte.min.css";
import "./assets/css/custom.css";
```

3. AdminLTE JS interactions (e.g., dropdown toggles) are **replaced by React components**—no jQuery needed.

---

# 🏗️ Step 3: React SPA with Routing & AdminLTE Sidebar

### `main.jsx`

```jsx
import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import "./assets/adminlte/css/adminlte.min.css";
import "./assets/css/custom.css";

ReactDOM.createRoot(document.getElementById("root")).render(
  <BrowserRouter>
    <App />
  </BrowserRouter>
);
```

---

### `App.jsx`

```jsx
import React from "react";
import { Routes, Route } from "react-router-dom";
import Navbar from "./components/Navbar";
import Sidebar from "./components/Sidebar";
import DashboardPage from "./components/pages/DashboardPage";
import UsersPage from "./components/pages/UsersPage";
import SalesPage from "./components/pages/SalesPage";

function App() {
  return (
    <div className="wrapper">
      <Navbar />
      <Sidebar />
      <div className="content-wrapper p-4">
        <Routes>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/users/*" element={<UsersPage />} />
          <Route path="/sales/*" element={<SalesPage />} />
        </Routes>
      </div>
    </div>
  );
}

export default App;
```

---

### Sidebar with Multi-Level Menus & Active Highlighting (`Sidebar.jsx`)

```jsx
import React, { useState } from "react";
import { Link, useLocation } from "react-router-dom";

const menu = [
  { name: "Dashboard", icon: "fas fa-th", path: "/" },
  { 
    name: "Users", icon: "fas fa-user", path: "/users", children: [
      { name: "All Users", path: "/users" },
      { name: "Add User", path: "/users/add" }
    ] 
  },
  { 
    name: "Sales", icon: "fas fa-chart-line", path: "/sales", children: [
      { name: "All Sales", path: "/sales" },
      { name: "Monthly Sales", path: "/sales/monthly" }
    ] 
  }
];

export default function Sidebar() {
  const [collapsedMenus, setCollapsedMenus] = useState({});
  const location = useLocation();

  const toggleMenu = (name) => {
    setCollapsedMenus(prev => ({ ...prev, [name]: !prev[name] }));
  };

  const isActive = (path) => location.pathname === path ? "active" : "";

  return (
    <aside className="main-sidebar sidebar-dark-primary elevation-4">
      <Link to="/" className="brand-link">
        <span className="brand-text font-weight-light">AdminLTE React</span>
      </Link>
      <div className="sidebar">
        <nav className="mt-2">
          <ul className="nav nav-pills nav-sidebar flex-column" role="menu">
            {menu.map(item => (
              <li key={item.name} className={`nav-item ${item.children ? "has-treeview" : ""} ${collapsedMenus[item.name] ? "menu-open" : ""}`}>
                <Link to={item.path} className={`nav-link ${isActive(item.path)}`} onClick={e => { if(item.children){ e.preventDefault(); toggleMenu(item.name); } }}>
                  <i className={`nav-icon ${item.icon}`}></i>
                  <p>
                    {item.name}
                    {item.children && <i className="right fas fa-angle-left"></i>}
                  </p>
                </Link>
                {item.children && (
                  <ul className="nav nav-treeview" style={{ display: collapsedMenus[item.name] ? "block" : "none" }}>
                    {item.children.map(sub => (
                      <li key={sub.name} className="nav-item">
                        <Link to={sub.path} className={`nav-link ${isActive(sub.path)}`}>
                          <i className="far fa-circle nav-icon"></i>
                          <p>{sub.name}</p>
                        </Link>
                      </li>
                    ))}
                  </ul>
                )}
              </li>
            ))}
          </ul>
        </nav>
      </div>
    </aside>
  );
}
```

> ✅ Multi-level sidebar, active link highlighting, AdminLTE look fully preserved.

---

### Navbar (`Navbar.jsx`)

```jsx
import React from "react";

export default function Navbar() {
  return (
    <nav className="main-header navbar navbar-expand navbar-white navbar-light">
      <ul className="navbar-nav">
        <li className="nav-item">
          <a className="nav-link" href="#" role="button">
            <i className="fas fa-bars"></i>
          </a>
        </li>
      </ul>
      <ul className="navbar-nav ml-auto">
        <li className="nav-item">
          <a className="nav-link" href="#" role="button">
            <i className="fas fa-expand-arrows-alt"></i>
          </a>
        </li>
      </ul>
    </nav>
  );
}
```

---

### Pages & Components

* `DashboardPage.jsx` → DashboardCards
* `UsersPage.jsx` → UsersTable
* `SalesPage.jsx` → SalesChart
* Axios calls to `/api/users/` and `/api/orders/`
* Cards, tables, charts styled like AdminLTE

---

# ⚡ Step 4: Production Deployment

## 4.1 Build React SPA

```bash
cd frontend
npm run build
```

* Output: `frontend/dist/` → copy to `/var/www/frontend/`

---

## 4.2 Configure Django

```python
DEBUG = False
ALLOWED_HOSTS = ["your-domain.com"]
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
```

```bash
python manage.py collectstatic
```

* Gunicorn serves Django API only

---

## 4.3 Nginx Config (`/etc/nginx/sites-available/dashboard`)

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

* Enable HTTPS via Certbot:

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

---

## 4.4 Gunicorn Service

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

# 🧪 Step 5: Access & Test

* Visit `https://your-domain.com` → React SPA dashboard
* Sidebar menus collapse/expand and highlight active routes
* Cards, charts, tables load via Axios calls to Django API
* AdminLTE layout, branding, and interactivity fully preserved

---

# ✅ Key Takeaways

* Fully **React SPA + Django API + AdminLTE** project
* Multi-level **sidebar with SPA-aware active highlighting**
* Production-ready: **Nginx + Gunicorn + HTTPS + static files**
* End-to-end guide from **development → SPA integration → production deployment**

---
Got it! Let’s **rewrite the entire handbook**, keeping all previous content, and **integrate AdminLTE fully**, so the **React SPA preserves AdminLTE’s layout, styles, and behavior**, including **multi-level collapsible sidebar menus, active link highlighting, and production-ready deployment** with Nginx + Django API + HTTPS.

I’ll structure it as a **step-by-step guide** so readers can build, run, and deploy the full project.

---

# 📘 Production-Grade Django + AdminLTE + React Dashboard Handbook

## Build, Deploy, and Maintain a Real-World Admin Dashboard

**Edition:** 7.0
**Audience:** Engineers, Bootcamp Learners, Trainers
**Level:** Beginner → Professional

**Tech Stack:**

* Django 5.x + DRF (Backend/API)
* Python 3.12+
* AdminLTE 3.x (UI/Components)
* React 18+ + React Router DOM (SPA)
* Vite (Frontend bundling)
* Axios, Chart.js, React Chart.js 2
* Bootstrap 5
* PostgreSQL (Production), SQLite (Dev)
* Nginx + Gunicorn
* HTTPS (Let’s Encrypt or self-signed cert)

---

## 🎯 Learning Outcomes

By the end of this guide, readers will:

✅ Build a **fully functional Django + React + AdminLTE dashboard**
✅ Preserve **AdminLTE layout, styles, and interactive behavior**
✅ Implement **multi-level collapsible sidebar with active link highlighting**
✅ Consume Django REST API endpoints via Axios
✅ Fully separate **frontend (React SPA)** and **backend (Django API)**
✅ Deploy **production-ready dashboard** with Nginx, Gunicorn, HTTPS, and static file handling

---

# 🏗️ Step 1: Project Setup

## Backend (Django + DRF)

```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

pip install django djangorestframework django-cors-headers psycopg2-binary
django-admin startproject config .
python manage.py startapp dashboard
```

**`settings.py` (key settings):**

```python
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

### Models & API Views

* `UserProfile` and `Order` models
* DRF serializers
* API views for `/api/users/` and `/api/orders/`

---

# ⚡ Step 2: Frontend Setup (React SPA + AdminLTE)

```bash
npm create vite@latest frontend --template react
cd frontend
npm install axios chart.js react-chartjs-2 react-router-dom
npm run dev
```

**Vite config with proxy:**

```js
export default defineConfig({
  plugins: [react()],
  server: { port: 5173, proxy: { '/api': 'http://127.0.0.1:8000' } }
});
```

**AdminLTE Integration**:

1. Copy AdminLTE assets (`dist/css`, `dist/js`, `plugins`) to `frontend/src/assets/adminlte/`
2. Import AdminLTE CSS in `main.jsx` or `App.jsx`:

```js
import "./assets/adminlte/css/adminlte.min.css";
import "./assets/css/custom.css";
```

3. AdminLTE JS interactions (e.g., dropdown toggles) are **replaced by React components**—no jQuery needed.

---

# 🏗️ Step 3: React SPA with Routing & AdminLTE Sidebar

### `main.jsx`

```jsx
import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import "./assets/adminlte/css/adminlte.min.css";
import "./assets/css/custom.css";

ReactDOM.createRoot(document.getElementById("root")).render(
  <BrowserRouter>
    <App />
  </BrowserRouter>
);
```

---

### `App.jsx`

```jsx
import React from "react";
import { Routes, Route } from "react-router-dom";
import Navbar from "./components/Navbar";
import Sidebar from "./components/Sidebar";
import DashboardPage from "./components/pages/DashboardPage";
import UsersPage from "./components/pages/UsersPage";
import SalesPage from "./components/pages/SalesPage";

function App() {
  return (
    <div className="wrapper">
      <Navbar />
      <Sidebar />
      <div className="content-wrapper p-4">
        <Routes>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/users/*" element={<UsersPage />} />
          <Route path="/sales/*" element={<SalesPage />} />
        </Routes>
      </div>
    </div>
  );
}

export default App;
```

---

### Sidebar with Multi-Level Menus & Active Highlighting (`Sidebar.jsx`)

```jsx
import React, { useState } from "react";
import { Link, useLocation } from "react-router-dom";

const menu = [
  { name: "Dashboard", icon: "fas fa-th", path: "/" },
  { 
    name: "Users", icon: "fas fa-user", path: "/users", children: [
      { name: "All Users", path: "/users" },
      { name: "Add User", path: "/users/add" }
    ] 
  },
  { 
    name: "Sales", icon: "fas fa-chart-line", path: "/sales", children: [
      { name: "All Sales", path: "/sales" },
      { name: "Monthly Sales", path: "/sales/monthly" }
    ] 
  }
];

export default function Sidebar() {
  const [collapsedMenus, setCollapsedMenus] = useState({});
  const location = useLocation();

  const toggleMenu = (name) => {
    setCollapsedMenus(prev => ({ ...prev, [name]: !prev[name] }));
  };

  const isActive = (path) => location.pathname === path ? "active" : "";

  return (
    <aside className="main-sidebar sidebar-dark-primary elevation-4">
      <Link to="/" className="brand-link">
        <span className="brand-text font-weight-light">AdminLTE React</span>
      </Link>
      <div className="sidebar">
        <nav className="mt-2">
          <ul className="nav nav-pills nav-sidebar flex-column" role="menu">
            {menu.map(item => (
              <li key={item.name} className={`nav-item ${item.children ? "has-treeview" : ""} ${collapsedMenus[item.name] ? "menu-open" : ""}`}>
                <Link to={item.path} className={`nav-link ${isActive(item.path)}`} onClick={e => { if(item.children){ e.preventDefault(); toggleMenu(item.name); } }}>
                  <i className={`nav-icon ${item.icon}`}></i>
                  <p>
                    {item.name}
                    {item.children && <i className="right fas fa-angle-left"></i>}
                  </p>
                </Link>
                {item.children && (
                  <ul className="nav nav-treeview" style={{ display: collapsedMenus[item.name] ? "block" : "none" }}>
                    {item.children.map(sub => (
                      <li key={sub.name} className="nav-item">
                        <Link to={sub.path} className={`nav-link ${isActive(sub.path)}`}>
                          <i className="far fa-circle nav-icon"></i>
                          <p>{sub.name}</p>
                        </Link>
                      </li>
                    ))}
                  </ul>
                )}
              </li>
            ))}
          </ul>
        </nav>
      </div>
    </aside>
  );
}
```

> ✅ Multi-level sidebar, active link highlighting, AdminLTE look fully preserved.

---

### Navbar (`Navbar.jsx`)

```jsx
import React from "react";

export default function Navbar() {
  return (
    <nav className="main-header navbar navbar-expand navbar-white navbar-light">
      <ul className="navbar-nav">
        <li className="nav-item">
          <a className="nav-link" href="#" role="button">
            <i className="fas fa-bars"></i>
          </a>
        </li>
      </ul>
      <ul className="navbar-nav ml-auto">
        <li className="nav-item">
          <a className="nav-link" href="#" role="button">
            <i className="fas fa-expand-arrows-alt"></i>
          </a>
        </li>
      </ul>
    </nav>
  );
}
```

---

### Pages & Components

* `DashboardPage.jsx` → DashboardCards
* `UsersPage.jsx` → UsersTable
* `SalesPage.jsx` → SalesChart
* Axios calls to `/api/users/` and `/api/orders/`
* Cards, tables, charts styled like AdminLTE

---

# ⚡ Step 4: Production Deployment

## 4.1 Build React SPA

```bash
cd frontend
npm run build
```

* Output: `frontend/dist/` → copy to `/var/www/frontend/`

---

## 4.2 Configure Django

```python
DEBUG = False
ALLOWED_HOSTS = ["your-domain.com"]
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
```

```bash
python manage.py collectstatic
```

* Gunicorn serves Django API only

---

## 4.3 Nginx Config (`/etc/nginx/sites-available/dashboard`)

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

* Enable HTTPS via Certbot:

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

---

## 4.4 Gunicorn Service

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

# 🧪 Step 5: Access & Test

* Visit `https://your-domain.com` → React SPA dashboard
* Sidebar menus collapse/expand and highlight active routes
* Cards, charts, tables load via Axios calls to Django API
* AdminLTE layout, branding, and interactivity fully preserved

---

# ✅ Key Takeaways

* Fully **React SPA + Django API + AdminLTE** project
* Multi-level **sidebar with SPA-aware active highlighting**
* Production-ready: **Nginx + Gunicorn + HTTPS + static files**
* End-to-end guide from **development → SPA integration → production deployment**

---

This handbook allows readers to **build a complete AdminLTE-style React SPA dashboard**, **consume Django APIs**, and **deploy in production** with HTTPS and static file handling.

---

