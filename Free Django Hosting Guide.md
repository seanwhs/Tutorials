# 📘 Free Hosting Guide for Django CRUD & React + DRF with MySQL

**Edition:** 1.1
**Audience:** Beginners, Bootcamp Learners, Web Developers
**Goal:** Learn **where and how to host Django and fullstack React + Django REST applications for free**, including MySQL setup, AdminLTE-style UI, and SPA routing.

---

# 🏗️ Part 1: Hosting Django CRUD with MySQL

Django CRUD apps require **backend hosting + MySQL database**. Free hosting options exist for **learning and small projects**, but typically have limits on CPU, RAM, and sleep on inactivity.

### Recommended Platforms for Django + MySQL

| Platform           | Free Tier Features                                  | Step-by-Step Instructions                                                                                                                                                                                                                                                                                                                                                                           | Pros                                             | Cons                                                         |
| ------------------ | --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------ |
| **PythonAnywhere** | Free web hosting, MySQL included, subdomain hosting | 1. Sign up [PythonAnywhere](https://www.pythonanywhere.com/)<br>2. Create a **new web app** → select Django & Python version<br>3. Set up **MySQL database** in "Databases"<br>4. Upload project via **Git** or **Files tab**<br>5. Configure `settings.py` for MySQL<br>6. Configure **WSGI** file<br>7. Run migrations and `collectstatic`<br>8. Access app via `yourusername.pythonanywhere.com` | Beginner-friendly, integrated MySQL, web console | Apps sleep after inactivity, only subdomain, limited CPU/RAM |
| **AlwaysData**     | Free hosting, MySQL database included               | 1. Sign up [AlwaysData](https://www.alwaysdata.com/)<br>2. Create MySQL database<br>3. Upload Django project via FTP/Git<br>4. Configure WSGI settings<br>5. Update `settings.py` for MySQL<br>6. Run migrations & `collectstatic`<br>7. Access via free domain provided                                                                                                                            | MySQL included, supports small Django apps       | Free tier limited RAM, request limits, WSGI setup required   |
| **GearHost**       | Free web hosting + MySQL                            | 1. Sign up [GearHost](https://www.gearhost.com/)<br>2. Create MySQL database<br>3. Upload Django project via Git<br>4. Configure database settings<br>5. Deploy and test                                                                                                                                                                                                                            | MySQL supported, simple setup                    | Small storage/bandwidth, apps may sleep, limited CPU         |

**Diagram (Django CRUD Free Hosting Flow):**

```
Local Django App
       |
       v
Upload / Git Push
       |
       v
Free Hosting Platform
       |
       v
MySQL Database
       |
       v
Public URL: yourapp.pythonanywhere.com
```

---

# 🏗️ Part 2: Hosting React + Django REST Framework with MySQL (Fullstack)

For **React SPA frontend + Django REST API backend**, free hosting requires splitting **frontend and backend**.

### Recommended Free Hosting Stack

| Layer                        | Free Hosting                           | Instructions                                                                                                                                                                                 | Notes                                                             |
| ---------------------------- | -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| **Backend (Django + MySQL)** | PythonAnywhere, AlwaysData, GearHost   | 1. Follow Django CRUD steps above<br>2. Install `djangorestframework`<br>3. Create API endpoints (`views.py`) and URLs (`urls.py`)<br>4. Add `django-cors-headers` and allow frontend origin | Backend serves **REST API** only, connects to MySQL               |
| **Frontend (React SPA)**     | Vercel Free, Netlify Free, Render Free | 1. Build React app (`npm run build`)<br>2. Push to GitHub<br>3. Deploy build folder on **Vercel / Netlify / Render**<br>4. Point API calls to backend URL                                    | React SPA handles routing, multi-level sidebar, AdminLTE-style UI |
| **Database**                 | MySQL (PythonAnywhere / AlwaysData)    | 1. Create database on backend hosting<br>2. Configure `settings.py`                                                                                                                          | Free tiers may limit storage/connections                          |

**Diagram (Fullstack Free Deployment Flow):**

```
React SPA (Vercel/Netlify)
        |
        v
HTTP Requests -> Django REST API (PythonAnywhere)
        |
        v
MySQL Database (PythonAnywhere)
```

---

# ⚡ Step-by-Step Deployment Guide for Free Fullstack

## Step 1: Backend Setup (Django + MySQL + DRF)

1. Create virtual environment:

```bash
python -m venv venv
source venv/bin/activate  # Linux / Mac
venv\Scripts\activate     # Windows
```

2. Install dependencies:

```bash
pip install django djangorestframework mysqlclient django-cors-headers
```

3. Configure `settings.py`:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'your_db_name',
        'USER': 'your_username',
        'PASSWORD': 'your_password',
        'HOST': 'your_host',  # e.g., PythonAnywhere hostname
        'PORT': '3306',
    }
}

INSTALLED_APPS += ['rest_framework', 'corsheaders']
MIDDLEWARE = ['corsheaders.middleware.CorsMiddleware'] + MIDDLEWARE
CORS_ALLOW_ALL_ORIGINS = True
```

4. Push backend to **PythonAnywhere / AlwaysData** as per Part 1.

---

## Step 2: Frontend Setup (React SPA)

1. Create React app:

```bash
npm create vite@latest frontend --template react
cd frontend
npm install react-router-dom chart.js
```

2. Create pages: `Dashboard.jsx`, `Orders.jsx`, `Users.jsx`.

3. Use `fetch` to call backend API:

```js
fetch("https://your-backend.pythonanywhere.com/api/orders/")
```

4. Build React app:

```bash
npm run build
```

---

## Step 3: Deploy Frontend

1. Push `build/` folder to **Vercel / Netlify / Render Free Tier**
2. Configure build command: `npm run build`, output directory: `dist`
3. Update API endpoint URLs in React to point to PythonAnywhere backend
4. Test SPA navigation, charts, CRUD pages

---

## Step 4: Final Flow Overview

```
Developer Local Repo
 ├── Backend: Django + DRF + MySQL
 └── Frontend: React SPA
        |
        v
Push to GitHub
        |
        v
Free Hosting Platforms
 ├── PythonAnywhere (Django + MySQL)
 └── Vercel / Netlify / Render (React SPA)
        |
        v
Live Fullstack Website
```

---

### ✅ Advantages

* **Fully free hosting:** PythonAnywhere backend + Vercel frontend
* **React SPA:** AdminLTE-style UI, multi-level collapsible sidebar, active link highlighting
* **Django REST Framework:** Exposes CRUD endpoints
* **MySQL database:** Persistent storage on free backend
* **Step-by-step deployable:** Beginners can clone repo and go live immediately

---

### 🔹 Key Features for React + Django Free Hosting

* **Multi-level collapsible sidebar** mimics AdminLTE
* **Active route highlighting** via `react-router-dom`
* **Dashboard cards & chart placeholders** using Chart.js
* **Fullstack SPA**: frontend and backend decoupled
* **Free-tier friendly**: compatible with PythonAnywhere + Vercel

---

