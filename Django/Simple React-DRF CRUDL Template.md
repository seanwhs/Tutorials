# 🌐 Full-Stack CRUDL Template: Django DRF + React

**Goal:** Implement **Create, Read, Update, Delete, List** operations for a simple `Book` entity using **DRF APIs** and **React frontend**.

---

## **1. Backend: Django + DRF**

### **1.1 Project Setup**

```bash
# Create Django project
django-admin startproject myproject
cd myproject

# Create app
python manage.py startapp books

# Install DRF
pip install djangorestframework

# Add to settings.py
INSTALLED_APPS = [
    ...,
    'rest_framework',
    'books',
]
```

---

### **1.2 Models (`books/models.py`)**

```python
from django.db import models

class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.CharField(max_length=100)
    published_date = models.DateField()

    def __str__(self):
        return self.title
```

---

### **1.3 Serializers (`books/serializers.py`)**

```python
from rest_framework import serializers
from .models import Book

class BookSerializer(serializers.ModelSerializer):
    class Meta:
        model = Book
        fields = '__all__'
```

---

### **1.4 Views / ViewSets (`books/views.py`)**

```python
from rest_framework import viewsets
from .models import Book
from .serializers import BookSerializer

class BookViewSet(viewsets.ModelViewSet):
    queryset = Book.objects.all()
    serializer_class = BookSerializer
```

---

### **1.5 URLs (`books/urls.py`)**

```python
from rest_framework.routers import DefaultRouter
from .views import BookViewSet

router = DefaultRouter()
router.register(r'books', BookViewSet, basename='book')

urlpatterns = router.urls
```

Include in project `urls.py`:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('books.urls')),
]
```

---

### ✅ Backend Summary

* **API Endpoints:**

| Method | Endpoint         | Action         |
| ------ | ---------------- | -------------- |
| GET    | /api/books/      | List books     |
| POST   | /api/books/      | Create book    |
| GET    | /api/books/{id}/ | Retrieve book  |
| PUT    | /api/books/{id}/ | Update book    |
| PATCH  | /api/books/{id}/ | Partial update |
| DELETE | /api/books/{id}/ | Delete book    |

---

## **2. Frontend: React**

### **2.1 Project Setup**

```bash
# Create React app
npx create-react-app book-frontend
cd book-frontend

# Install axios
npm install axios
```

---

### **2.2 Project Structure**

```
book-frontend/
├── public/
│   └── index.html
├── src/
│   ├── components/
│   │   ├── BookList.js
│   │   ├── BookDetail.js
│   │   ├── BookForm.js
│   │   └── BookDelete.js
│   ├── services/
│   │   └── apiService.js
│   ├── App.js
│   └── index.js
└── package.json
```

---

### **2.3 API Service (`src/services/apiService.js`)**

```javascript
import axios from 'axios';

const API_URL = 'http://127.0.0.1:8000/api/books/';

export const getBooks = () => axios.get(API_URL);
export const getBook = (id) => axios.get(`${API_URL}${id}/`);
export const createBook = (data) => axios.post(API_URL, data);
export const updateBook = (id, data) => axios.put(`${API_URL}${id}/`, data);
export const deleteBook = (id) => axios.delete(`${API_URL}${id}/`);
```

---

### **2.4 Components**

**1. BookList.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBooks } from '../services/apiService';
import { Link } from 'react-router-dom';

export default function BookList() {
    const [books, setBooks] = useState([]);

    useEffect(() => {
        getBooks().then(res => setBooks(res.data));
    }, []);

    return (
        <div>
            <h1>Books</h1>
            <Link to="/create">Add Book</Link>
            <ul>
                {books.map(book => (
                    <li key={book.id}>
                        <Link to={`/detail/${book.id}`}>{book.title}</Link>
                        {' '}| <Link to={`/update/${book.id}`}>Edit</Link>
                        {' '}| <Link to={`/delete/${book.id}`}>Delete</Link>
                    </li>
                ))}
            </ul>
        </div>
    );
}
```

**2. BookDetail.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBook } from '../services/apiService';
import { useParams, Link } from 'react-router-dom';

export default function BookDetail() {
    const { id } = useParams();
    const [book, setBook] = useState(null);

    useEffect(() => {
        getBook(id).then(res => setBook(res.data));
    }, [id]);

    if (!book) return <div>Loading...</div>;

    return (
        <div>
            <h1>{book.title}</h1>
            <p>Author: {book.author}</p>
            <p>Published: {book.published_date}</p>
            <Link to={`/update/${book.id}`}>Edit</Link> | 
            <Link to={`/delete/${book.id}`}>Delete</Link> | 
            <Link to="/">Back</Link>
        </div>
    );
}
```

**3. BookForm.js (Create & Update)**

```javascript
import React, { useState, useEffect } from 'react';
import { createBook, getBook, updateBook } from '../services/apiService';
import { useParams, useNavigate } from 'react-router-dom';

export default function BookForm() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [form, setForm] = useState({ title: '', author: '', published_date: '' });

    useEffect(() => {
        if (id) {
            getBook(id).then(res => setForm(res.data));
        }
    }, [id]);

    const handleChange = e => setForm({ ...form, [e.target.name]: e.target.value });

    const handleSubmit = e => {
        e.preventDefault();
        if (id) updateBook(id, form).then(() => navigate('/'));
        else createBook(form).then(() => navigate('/'));
    }

    return (
        <form onSubmit={handleSubmit}>
            <input name="title" value={form.title} onChange={handleChange} placeholder="Title" required />
            <input name="author" value={form.author} onChange={handleChange} placeholder="Author" required />
            <input name="published_date" value={form.published_date} onChange={handleChange} type="date" required />
            <button type="submit">Save</button>
        </form>
    );
}
```

**4. BookDelete.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBook, deleteBook } from '../services/apiService';
import { useParams, useNavigate, Link } from 'react-router-dom';

export default function BookDelete() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [book, setBook] = useState(null);

    useEffect(() => {
        getBook(id).then(res => setBook(res.data));
    }, [id]);

    const handleDelete = () => {
        deleteBook(id).then(() => navigate('/'));
    };

    if (!book) return <div>Loading...</div>;

    return (
        <div>
            <h1>Delete "{book.title}"?</h1>
            <button onClick={handleDelete}>Confirm Delete</button>
            <Link to="/">Cancel</Link>
        </div>
    );
}
```

---

### **2.5 React Router Setup (`App.js`)**

```javascript
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import BookList from './components/BookList';
import BookDetail from './components/BookDetail';
import BookForm from './components/BookForm';
import BookDelete from './components/BookDelete';

function App() {
    return (
        <Router>
            <Routes>
                <Route path="/" element={<BookList />} />
                <Route path="/detail/:id" element={<BookDetail />} />
                <Route path="/create" element={<BookForm />} />
                <Route path="/update/:id" element={<BookForm />} />
                <Route path="/delete/:id" element={<BookDelete />} />
            </Routes>
        </Router>
    );
}

export default App;
```

---

## ✅ **3. Summary**

* **Backend:** DRF `ModelViewSet` exposes **CRUDL APIs** for `Book`.
* **Frontend:** React SPA with **Axios service layer**, **React Router**, and full **CRUDL UI**.
* **Flow:**
  `React Form → Axios → DRF API → Django ORM → Database → Axios Response → React UI`.
* **Scalable:** Can extend to multiple models, authentication, pagination, and search.

---

If you want, I can now make a **fully packaged ZIP-ready projectPerfect! Let’s create a **full-stack CRUDL template** using **Django + DRF (backend API) + React (frontend SPA)**. I’ll make it verbose, well-structured, and fully functional.

---

# 🌐 Full-Stack CRUDL Template: Django DRF + React

**Goal:** Implement **Create, Read, Update, Delete, List** operations for a simple `Book` entity using **DRF APIs** and **React frontend**.

---

## **1. Backend: Django + DRF**

### **1.1 Project Setup**

```bash
# Create Django project
django-admin startproject myproject
cd myproject

# Create app
python manage.py startapp books

# Install DRF
pip install djangorestframework

# Add to settings.py
INSTALLED_APPS = [
    ...,
    'rest_framework',
    'books',
]
```

---

### **1.2 Models (`books/models.py`)**

```python
from django.db import models

class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.CharField(max_length=100)
    published_date = models.DateField()

    def __str__(self):
        return self.title
```

---

### **1.3 Serializers (`books/serializers.py`)**

```python
from rest_framework import serializers
from .models import Book

class BookSerializer(serializers.ModelSerializer):
    class Meta:
        model = Book
        fields = '__all__'
```

---

### **1.4 Views / ViewSets (`books/views.py`)**

```python
from rest_framework import viewsets
from .models import Book
from .serializers import BookSerializer

class BookViewSet(viewsets.ModelViewSet):
    queryset = Book.objects.all()
    serializer_class = BookSerializer
```

---

### **1.5 URLs (`books/urls.py`)**

```python
from rest_framework.routers import DefaultRouter
from .views import BookViewSet

router = DefaultRouter()
router.register(r'books', BookViewSet, basename='book')

urlpatterns = router.urls
```

Include in project `urls.py`:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('books.urls')),
]
```

---

### ✅ Backend Summary

* **API Endpoints:**

| Method | Endpoint         | Action         |
| ------ | ---------------- | -------------- |
| GET    | /api/books/      | List books     |
| POST   | /api/books/      | Create book    |
| GET    | /api/books/{id}/ | Retrieve book  |
| PUT    | /api/books/{id}/ | Update book    |
| PATCH  | /api/books/{id}/ | Partial update |
| DELETE | /api/books/{id}/ | Delete book    |

---

## **2. Frontend: React**

### **2.1 Project Setup**

```bash
# Create React app
npx create-react-app book-frontend
cd book-frontend

# Install axios
npm install axios
```

---

### **2.2 Project Structure**

```
book-frontend/
├── public/
│   └── index.html
├── src/
│   ├── components/
│   │   ├── BookList.js
│   │   ├── BookDetail.js
│   │   ├── BookForm.js
│   │   └── BookDelete.js
│   ├── services/
│   │   └── apiService.js
│   ├── App.js
│   └── index.js
└── package.json
```

---

### **2.3 API Service (`src/services/apiService.js`)**

```javascript
import axios from 'axios';

const API_URL = 'http://127.0.0.1:8000/api/books/';

export const getBooks = () => axios.get(API_URL);
export const getBook = (id) => axios.get(`${API_URL}${id}/`);
export const createBook = (data) => axios.post(API_URL, data);
export const updateBook = (id, data) => axios.put(`${API_URL}${id}/`, data);
export const deleteBook = (id) => axios.delete(`${API_URL}${id}/`);
```

---

### **2.4 Components**

**1. BookList.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBooks } from '../services/apiService';
import { Link } from 'react-router-dom';

export default function BookList() {
    const [books, setBooks] = useState([]);

    useEffect(() => {
        getBooks().then(res => setBooks(res.data));
    }, []);

    return (
        <div>
            <h1>Books</h1>
            <Link to="/create">Add Book</Link>
            <ul>
                {books.map(book => (
                    <li key={book.id}>
                        <Link to={`/detail/${book.id}`}>{book.title}</Link>
                        {' '}| <Link to={`/update/${book.id}`}>Edit</Link>
                        {' '}| <Link to={`/delete/${book.id}`}>Delete</Link>
                    </li>
                ))}
            </ul>
        </div>
    );
}
```

**2. BookDetail.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBook } from '../services/apiService';
import { useParams, Link } from 'react-router-dom';

export default function BookDetail() {
    const { id } = useParams();
    const [book, setBook] = useState(null);

    useEffect(() => {
        getBook(id).then(res => setBook(res.data));
    }, [id]);

    if (!book) return <div>Loading...</div>;

    return (
        <div>
            <h1>{book.title}</h1>
            <p>Author: {book.author}</p>
            <p>Published: {book.published_date}</p>
            <Link to={`/update/${book.id}`}>Edit</Link> | 
            <Link to={`/delete/${book.id}`}>Delete</Link> | 
            <Link to="/">Back</Link>
        </div>
    );
}
```

**3. BookForm.js (Create & Update)**

```javascript
import React, { useState, useEffect } from 'react';
import { createBook, getBook, updateBook } from '../services/apiService';
import { useParams, useNavigate } from 'react-router-dom';

export default function BookForm() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [form, setForm] = useState({ title: '', author: '', published_date: '' });

    useEffect(() => {
        if (id) {
            getBook(id).then(res => setForm(res.data));
        }
    }, [id]);

    const handleChange = e => setForm({ ...form, [e.target.name]: e.target.value });

    const handleSubmit = e => {
        e.preventDefault();
        if (id) updateBook(id, form).then(() => navigate('/'));
        else createBook(form).then(() => navigate('/'));
    }

    return (
        <form onSubmit={handleSubmit}>
            <input name="title" value={form.title} onChange={handleChange} placeholder="Title" required />
            <input name="author" value={form.author} onChange={handleChange} placeholder="Author" required />
            <input name="published_date" value={form.published_date} onChange={handleChange} type="date" required />
            <button type="submit">Save</button>
        </form>
    );
}
```

**4. BookDelete.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBook, deleteBook } from '../services/apiService';
import { useParams, useNavigate, Link } from 'react-router-dom';

export default function BookDelete() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [book, setBook] = useState(null);

    useEffect(() => {
        getBook(id).then(res => setBook(res.data));
    }, [id]);

    const handleDelete = () => {
        deleteBook(id).then(() => navigate('/'));
    };

    if (!book) return <div>Loading...</div>;

    return (
        <div>
            <h1>Delete "{book.title}"?</h1>
            <button onClick={handleDelete}>Confirm Delete</button>
            <Link to="/">Cancel</Link>
        </div>
    );
}
```

---

### **2.5 React Router Setup (`App.js`)**

```javascript
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import BookList from './components/BookList';
import BookDetail from './components/BookDetail';
import BookForm from './components/BookForm';
import BookDelete from './components/BookDelete';

function App() {
    return (
        <Router>
            <Routes>
                <Route path="/" element={<BookList />} />
                <Route path="/detail/:id" element={<BookDetail />} />
                <Route path="/create" element={<BookForm />} />
                <Route path="/update/:id" element={<BookForm />} />
                <Route path="/delete/:id" element={<BookDelete />} />
            </Routes>
        </Router>
    );
}

export default App;
```

---

## ✅ **3. Summary**

* **Backend:** DRF `ModelViewSet` exposes **CRUDL APIs** for `Book`.
* **Frontend:** React SPA with **Axios service layer**, **React Router**, and full **CRUDL UI**.
* **Flow:**
  `React Form → Axios → DRF API → Django ORM → Database → Axios Response → React UI`.
* **Scalable:** Can extend to multiple models, authentication, pagination, and search.

---

If you want, I can now make a **fully packaged ZIP-ready project** with **all folder structures, ready to `npm install` + `python manage.py migrate` + run**.

Do you want me to do that next?
Perfect! Let’s create a **full-stack CRUDL template** using **Django + DRF (backend API) + React (frontend SPA)**. I’ll make it verbose, well-structured, and fully functional.

---

# 🌐 Full-Stack CRUDL Template: Django DRF + React

**Goal:** Implement **Create, Read, Update, Delete, List** operations for a simple `Book` entity using **DRF APIs** and **React frontend**.

---

## **1. Backend: Django + DRF**

### **1.1 Project Setup**

```bash
# Create Django project
django-admin startproject myproject
cd myproject

# Create app
python manage.py startapp books

# Install DRF
pip install djangorestframework

# Add to settings.py
INSTALLED_APPS = [
    ...,
    'rest_framework',
    'books',
]
```

---

### **1.2 Models (`books/models.py`)**

```python
from django.db import models

class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.CharField(max_length=100)
    published_date = models.DateField()

    def __str__(self):
        return self.title
```

---

### **1.3 Serializers (`books/serializers.py`)**

```python
from rest_framework import serializers
from .models import Book

class BookSerializer(serializers.ModelSerializer):
    class Meta:
        model = Book
        fields = '__all__'
```

---

### **1.4 Views / ViewSets (`books/views.py`)**

```python
from rest_framework import viewsets
from .models import Book
from .serializers import BookSerializer

class BookViewSet(viewsets.ModelViewSet):
    queryset = Book.objects.all()
    serializer_class = BookSerializer
```

---

### **1.5 URLs (`books/urls.py`)**

```python
from rest_framework.routers import DefaultRouter
from .views import BookViewSet

router = DefaultRouter()
router.register(r'books', BookViewSet, basename='book')

urlpatterns = router.urls
```

Include in project `urls.py`:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('books.urls')),
]
```

---

### ✅ Backend Summary

* **API Endpoints:**

| Method | Endpoint         | Action         |
| ------ | ---------------- | -------------- |
| GET    | /api/books/      | List books     |
| POST   | /api/books/      | Create book    |
| GET    | /api/books/{id}/ | Retrieve book  |
| PUT    | /api/books/{id}/ | Update book    |
| PATCH  | /api/books/{id}/ | Partial update |
| DELETE | /api/books/{id}/ | Delete book    |

---

## **2. Frontend: React**

### **2.1 Project Setup**

```bash
# Create React app
npx create-react-app book-frontend
cd book-frontend

# Install axios
npm install axios
```

---

### **2.2 Project Structure**

```
book-frontend/
├── public/
│   └── index.html
├── src/
│   ├── components/
│   │   ├── BookList.js
│   │   ├── BookDetail.js
│   │   ├── BookForm.js
│   │   └── BookDelete.js
│   ├── services/
│   │   └── apiService.js
│   ├── App.js
│   └── index.js
└── package.json
```

---

### **2.3 API Service (`src/services/apiService.js`)**

```javascript
import axios from 'axios';

const API_URL = 'http://127.0.0.1:8000/api/books/';

export const getBooks = () => axios.get(API_URL);
export const getBook = (id) => axios.get(`${API_URL}${id}/`);
export const createBook = (data) => axios.post(API_URL, data);
export const updateBook = (id, data) => axios.put(`${API_URL}${id}/`, data);
export const deleteBook = (id) => axios.delete(`${API_URL}${id}/`);
```

---

### **2.4 Components**

**1. BookList.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBooks } from '../services/apiService';
import { Link } from 'react-router-dom';

export default function BookList() {
    const [books, setBooks] = useState([]);

    useEffect(() => {
        getBooks().then(res => setBooks(res.data));
    }, []);

    return (
        <div>
            <h1>Books</h1>
            <Link to="/create">Add Book</Link>
            <ul>
                {books.map(book => (
                    <li key={book.id}>
                        <Link to={`/detail/${book.id}`}>{book.title}</Link>
                        {' '}| <Link to={`/update/${book.id}`}>Edit</Link>
                        {' '}| <Link to={`/delete/${book.id}`}>Delete</Link>
                    </li>
                ))}
            </ul>
        </div>
    );
}
```

**2. BookDetail.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBook } from '../services/apiService';
import { useParams, Link } from 'react-router-dom';

export default function BookDetail() {
    const { id } = useParams();
    const [book, setBook] = useState(null);

    useEffect(() => {
        getBook(id).then(res => setBook(res.data));
    }, [id]);

    if (!book) return <div>Loading...</div>;

    return (
        <div>
            <h1>{book.title}</h1>
            <p>Author: {book.author}</p>
            <p>Published: {book.published_date}</p>
            <Link to={`/update/${book.id}`}>Edit</Link> | 
            <Link to={`/delete/${book.id}`}>Delete</Link> | 
            <Link to="/">Back</Link>
        </div>
    );
}
```

**3. BookForm.js (Create & Update)**

```javascript
import React, { useState, useEffect } from 'react';
import { createBook, getBook, updateBook } from '../services/apiService';
import { useParams, useNavigate } from 'react-router-dom';

export default function BookForm() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [form, setForm] = useState({ title: '', author: '', published_date: '' });

    useEffect(() => {
        if (id) {
            getBook(id).then(res => setForm(res.data));
        }
    }, [id]);

    const handleChange = e => setForm({ ...form, [e.target.name]: e.target.value });

    const handleSubmit = e => {
        e.preventDefault();
        if (id) updateBook(id, form).then(() => navigate('/'));
        else createBook(form).then(() => navigate('/'));
    }

    return (
        <form onSubmit={handleSubmit}>
            <input name="title" value={form.title} onChange={handleChange} placeholder="Title" required />
            <input name="author" value={form.author} onChange={handleChange} placeholder="Author" required />
            <input name="published_date" value={form.published_date} onChange={handleChange} type="date" required />
            <button type="submit">Save</button>
        </form>
    );
}
```

**4. BookDelete.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBook, deleteBook } from '../services/apiService';
import { useParams, useNavigate, Link } from 'react-router-dom';

export default function BookDelete() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [book, setBook] = useState(null);

    useEffect(() => {
        getBook(id).then(res => setBook(res.data));
    }, [id]);

    const handleDelete = () => {
        deleteBook(id).then(() => navigate('/'));
    };

    if (!book) return <div>Loading...</div>;

    return (
        <div>
            <h1>Delete "{book.title}"?</h1>
            <button onClick={handleDelete}>Confirm Delete</button>
            <Link to="/">Cancel</Link>
        </div>
    );
}
```

---

### **2.5 React Router Setup (`App.js`)**

```javascript
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import BookList from './components/BookList';
import BookDetail from './components/BookDetail';
import BookForm from './components/BookForm';
import BookDelete from './components/BookDelete';

function App() {
    return (
        <Router>
            <Routes>
                <Route path="/" element={<BookList />} />
                <Route path="/detail/:id" element={<BookDetail />} />
                <Route path="/create" element={<BookForm />} />
                <Route path="/update/:id" element={<BookForm />} />
                <Route path="/delete/:id" element={<BookDelete />} />
            </Routes>
        </Router>
    );
}

export default App;
```

---

## ✅ **3. Summary**

* **Backend:** DRF `ModelViewSet` exposes **CRUDL APIs** for `Book`.
* **Frontend:** React SPA with **Axios service layer**, **React Router**, and full **CRUDL UI**.
* **Flow:**
  `React Form → Axios → DRF API → Django ORM → Database → Axios Response → React UI`.
* **Scalable:** Can extend to multiple models, authentication, pagination, and search.

---

If you want, I can now make a **fully packaged ZIP-ready project** with **all folder structures, ready to `npm install` + `python manage.py migrate` + run**.

Do you want me to do that next?
Perfect! Let’s create a **full-stack CRUDL template** using **Django + DRF (backend API) + React (frontend SPA)**. I’ll make it verbose, well-structured, and fully functional.

---

# 🌐 Full-Stack CRUDL Template: Django DRF + React

**Goal:** Implement **Create, Read, Update, Delete, List** operations for a simple `Book` entity using **DRF APIs** and **React frontend**.

---

## **1. Backend: Django + DRF**

### **1.1 Project Setup**

```bash
# Create Django project
django-admin startproject myproject
cd myproject

# Create app
python manage.py startapp books

# Install DRF
pip install djangorestframework

# Add to settings.py
INSTALLED_APPS = [
    ...,
    'rest_framework',
    'books',
]
```

---

### **1.2 Models (`books/models.py`)**

```python
from django.db import models

class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.CharField(max_length=100)
    published_date = models.DateField()

    def __str__(self):
        return self.title
```

---

### **1.3 Serializers (`books/serializers.py`)**

```python
from rest_framework import serializers
from .models import Book

class BookSerializer(serializers.ModelSerializer):
    class Meta:
        model = Book
        fields = '__all__'
```

---

### **1.4 Views / ViewSets (`books/views.py`)**

```python
from rest_framework import viewsets
from .models import Book
from .serializers import BookSerializer

class BookViewSet(viewsets.ModelViewSet):
    queryset = Book.objects.all()
    serializer_class = BookSerializer
```

---

### **1.5 URLs (`books/urls.py`)**

```python
from rest_framework.routers import DefaultRouter
from .views import BookViewSet

router = DefaultRouter()
router.register(r'books', BookViewSet, basename='book')

urlpatterns = router.urls
```

Include in project `urls.py`:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('books.urls')),
]
```

---

### ✅ Backend Summary

* **API Endpoints:**

| Method | Endpoint         | Action         |
| ------ | ---------------- | -------------- |
| GET    | /api/books/      | List books     |
| POST   | /api/books/      | Create book    |
| GET    | /api/books/{id}/ | Retrieve book  |
| PUT    | /api/books/{id}/ | Update book    |
| PATCH  | /api/books/{id}/ | Partial update |
| DELETE | /api/books/{id}/ | Delete book    |

---

## **2. Frontend: React**

### **2.1 Project Setup**

```bash
# Create React app
npx create-react-app book-frontend
cd book-frontend

# Install axios
npm install axios
```

---

### **2.2 Project Structure**

```
book-frontend/
├── public/
│   └── index.html
├── src/
│   ├── components/
│   │   ├── BookList.js
│   │   ├── BookDetail.js
│   │   ├── BookForm.js
│   │   └── BookDelete.js
│   ├── services/
│   │   └── apiService.js
│   ├── App.js
│   └── index.js
└── package.json
```

---

### **2.3 API Service (`src/services/apiService.js`)**

```javascript
import axios from 'axios';

const API_URL = 'http://127.0.0.1:8000/api/books/';

export const getBooks = () => axios.get(API_URL);
export const getBook = (id) => axios.get(`${API_URL}${id}/`);
export const createBook = (data) => axios.post(API_URL, data);
export const updateBook = (id, data) => axios.put(`${API_URL}${id}/`, data);
export const deleteBook = (id) => axios.delete(`${API_URL}${id}/`);
```

---

### **2.4 Components**

**1. BookList.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBooks } from '../services/apiService';
import { Link } from 'react-router-dom';

export default function BookList() {
    const [books, setBooks] = useState([]);

    useEffect(() => {
        getBooks().then(res => setBooks(res.data));
    }, []);

    return (
        <div>
            <h1>Books</h1>
            <Link to="/create">Add Book</Link>
            <ul>
                {books.map(book => (
                    <li key={book.id}>
                        <Link to={`/detail/${book.id}`}>{book.title}</Link>
                        {' '}| <Link to={`/update/${book.id}`}>Edit</Link>
                        {' '}| <Link to={`/delete/${book.id}`}>Delete</Link>
                    </li>
                ))}
            </ul>
        </div>
    );
}
```

**2. BookDetail.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBook } from '../services/apiService';
import { useParams, Link } from 'react-router-dom';

export default function BookDetail() {
    const { id } = useParams();
    const [book, setBook] = useState(null);

    useEffect(() => {
        getBook(id).then(res => setBook(res.data));
    }, [id]);

    if (!book) return <div>Loading...</div>;

    return (
        <div>
            <h1>{book.title}</h1>
            <p>Author: {book.author}</p>
            <p>Published: {book.published_date}</p>
            <Link to={`/update/${book.id}`}>Edit</Link> | 
            <Link to={`/delete/${book.id}`}>Delete</Link> | 
            <Link to="/">Back</Link>
        </div>
    );
}
```

**3. BookForm.js (Create & Update)**

```javascript
import React, { useState, useEffect } from 'react';
import { createBook, getBook, updateBook } from '../services/apiService';
import { useParams, useNavigate } from 'react-router-dom';

export default function BookForm() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [form, setForm] = useState({ title: '', author: '', published_date: '' });

    useEffect(() => {
        if (id) {
            getBook(id).then(res => setForm(res.data));
        }
    }, [id]);

    const handleChange = e => setForm({ ...form, [e.target.name]: e.target.value });

    const handleSubmit = e => {
        e.preventDefault();
        if (id) updateBook(id, form).then(() => navigate('/'));
        else createBook(form).then(() => navigate('/'));
    }

    return (
        <form onSubmit={handleSubmit}>
            <input name="title" value={form.title} onChange={handleChange} placeholder="Title" required />
            <input name="author" value={form.author} onChange={handleChange} placeholder="Author" required />
            <input name="published_date" value={form.published_date} onChange={handleChange} type="date" required />
            <button type="submit">Save</button>
        </form>
    );
}
```

**4. BookDelete.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBook, deleteBook } from '../services/apiService';
import { useParams, useNavigate, Link } from 'react-router-dom';

export default function BookDelete() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [book, setBook] = useState(null);

    useEffect(() => {
        getBook(id).then(res => setBook(res.data));
    }, [id]);

    const handleDelete = () => {
        deleteBook(id).then(() => navigate('/'));
    };

    if (!book) return <div>Loading...</div>;

    return (
        <div>
            <h1>Delete "{book.title}"?</h1>
            <button onClick={handleDelete}>Confirm Delete</button>
            <Link to="/">Cancel</Link>
        </div>
    );
}
```

---

### **2.5 React Router Setup (`App.js`)**

```javascript
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import BookList from './components/BookList';
import BookDetail from './components/BookDetail';
import BookForm from './components/BookForm';
import BookDelete from './components/BookDelete';

function App() {
    return (
        <Router>
            <Routes>
                <Route path="/" element={<BookList />} />
                <Route path="/detail/:id" element={<BookDetail />} />
                <Route path="/create" element={<BookForm />} />
                <Route path="/update/:id" element={<BookForm />} />
                <Route path="/delete/:id" element={<BookDelete />} />
            </Routes>
        </Router>
    );
}

export default App;
```

---

## ✅ **3. Summary**

* **Backend:** DRF `ModelViewSet` exposes **CRUDL APIs** for `Book`.
* **Frontend:** React SPA with **Axios service layer**, **React Router**, and full **CRUDL UI**.
* **Flow:**
  `React Form → Axios → DRF API → Django ORM → Database → Axios Response → React UI`.
* **Scalable:** Can extend to multiple models, authentication, pagination, and search.

---

If you want, I can now make a **fully packaged ZIP-ready project** with **all folder structures, ready to `npm install` + `python manage.py migrate` + run**.

Do you want me to do that next?
Perfect! Let’s create a **full-stack CRUDL template** using **Django + DRF (backend API) + React (frontend SPA)**. I’ll make it verbose, well-structured, and fully functional.

---

# 🌐 Full-Stack CRUDL Template: Django DRF + React

**Goal:** Implement **Create, Read, Update, Delete, List** operations for a simple `Book` entity using **DRF APIs** and **React frontend**.

---

## **1. Backend: Django + DRF**

### **1.1 Project Setup**

```bash
# Create Django project
django-admin startproject myproject
cd myproject

# Create app
python manage.py startapp books

# Install DRF
pip install djangorestframework

# Add to settings.py
INSTALLED_APPS = [
    ...,
    'rest_framework',
    'books',
]
```

---

### **1.2 Models (`books/models.py`)**

```python
from django.db import models

class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.CharField(max_length=100)
    published_date = models.DateField()

    def __str__(self):
        return self.title
```

---

### **1.3 Serializers (`books/serializers.py`)**

```python
from rest_framework import serializers
from .models import Book

class BookSerializer(serializers.ModelSerializer):
    class Meta:
        model = Book
        fields = '__all__'
```

---

### **1.4 Views / ViewSets (`books/views.py`)**

```python
from rest_framework import viewsets
from .models import Book
from .serializers import BookSerializer

class BookViewSet(viewsets.ModelViewSet):
    queryset = Book.objects.all()
    serializer_class = BookSerializer
```

---

### **1.5 URLs (`books/urls.py`)**

```python
from rest_framework.routers import DefaultRouter
from .views import BookViewSet

router = DefaultRouter()
router.register(r'books', BookViewSet, basename='book')

urlpatterns = router.urls
```

Include in project `urls.py`:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('books.urls')),
]
```

---

### ✅ Backend Summary

* **API Endpoints:**

| Method | Endpoint         | Action         |
| ------ | ---------------- | -------------- |
| GET    | /api/books/      | List books     |
| POST   | /api/books/      | Create book    |
| GET    | /api/books/{id}/ | Retrieve book  |
| PUT    | /api/books/{id}/ | Update book    |
| PATCH  | /api/books/{id}/ | Partial update |
| DELETE | /api/books/{id}/ | Delete book    |

---

## **2. Frontend: React**

### **2.1 Project Setup**

```bash
# Create React app
npx create-react-app book-frontend
cd book-frontend

# Install axios
npm install axios
```

---

### **2.2 Project Structure**

```
book-frontend/
├── public/
│   └── index.html
├── src/
│   ├── components/
│   │   ├── BookList.js
│   │   ├── BookDetail.js
│   │   ├── BookForm.js
│   │   └── BookDelete.js
│   ├── services/
│   │   └── apiService.js
│   ├── App.js
│   └── index.js
└── package.json
```

---

### **2.3 API Service (`src/services/apiService.js`)**

```javascript
import axios from 'axios';

const API_URL = 'http://127.0.0.1:8000/api/books/';

export const getBooks = () => axios.get(API_URL);
export const getBook = (id) => axios.get(`${API_URL}${id}/`);
export const createBook = (data) => axios.post(API_URL, data);
export const updateBook = (id, data) => axios.put(`${API_URL}${id}/`, data);
export const deleteBook = (id) => axios.delete(`${API_URL}${id}/`);
```

---

### **2.4 Components**

**1. BookList.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBooks } from '../services/apiService';
import { Link } from 'react-router-dom';

export default function BookList() {
    const [books, setBooks] = useState([]);

    useEffect(() => {
        getBooks().then(res => setBooks(res.data));
    }, []);

    return (
        <div>
            <h1>Books</h1>
            <Link to="/create">Add Book</Link>
            <ul>
                {books.map(book => (
                    <li key={book.id}>
                        <Link to={`/detail/${book.id}`}>{book.title}</Link>
                        {' '}| <Link to={`/update/${book.id}`}>Edit</Link>
                        {' '}| <Link to={`/delete/${book.id}`}>Delete</Link>
                    </li>
                ))}
            </ul>
        </div>
    );
}
```

**2. BookDetail.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBook } from '../services/apiService';
import { useParams, Link } from 'react-router-dom';

export default function BookDetail() {
    const { id } = useParams();
    const [book, setBook] = useState(null);

    useEffect(() => {
        getBook(id).then(res => setBook(res.data));
    }, [id]);

    if (!book) return <div>Loading...</div>;

    return (
        <div>
            <h1>{book.title}</h1>
            <p>Author: {book.author}</p>
            <p>Published: {book.published_date}</p>
            <Link to={`/update/${book.id}`}>Edit</Link> | 
            <Link to={`/delete/${book.id}`}>Delete</Link> | 
            <Link to="/">Back</Link>
        </div>
    );
}
```

**3. BookForm.js (Create & Update)**

```javascript
import React, { useState, useEffect } from 'react';
import { createBook, getBook, updateBook } from '../services/apiService';
import { useParams, useNavigate } from 'react-router-dom';

export default function BookForm() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [form, setForm] = useState({ title: '', author: '', published_date: '' });

    useEffect(() => {
        if (id) {
            getBook(id).then(res => setForm(res.data));
        }
    }, [id]);

    const handleChange = e => setForm({ ...form, [e.target.name]: e.target.value });

    const handleSubmit = e => {
        e.preventDefault();
        if (id) updateBook(id, form).then(() => navigate('/'));
        else createBook(form).then(() => navigate('/'));
    }

    return (
        <form onSubmit={handleSubmit}>
            <input name="title" value={form.title} onChange={handleChange} placeholder="Title" required />
            <input name="author" value={form.author} onChange={handleChange} placeholder="Author" required />
            <input name="published_date" value={form.published_date} onChange={handleChange} type="date" required />
            <button type="submit">Save</button>
        </form>
    );
}
```

**4. BookDelete.js**

```javascript
import React, { useEffect, useState } from 'react';
import { getBook, deleteBook } from '../services/apiService';
import { useParams, useNavigate, Link } from 'react-router-dom';

export default function BookDelete() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [book, setBook] = useState(null);

    useEffect(() => {
        getBook(id).then(res => setBook(res.data));
    }, [id]);

    const handleDelete = () => {
        deleteBook(id).then(() => navigate('/'));
    };

    if (!book) return <div>Loading...</div>;

    return (
        <div>
            <h1>Delete "{book.title}"?</h1>
            <button onClick={handleDelete}>Confirm Delete</button>
            <Link to="/">Cancel</Link>
        </div>
    );
}
```

---

### **2.5 React Router Setup (`App.js`)**

```javascript
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import BookList from './components/BookList';
import BookDetail from './components/BookDetail';
import BookForm from './components/BookForm';
import BookDelete from './components/BookDelete';

function App() {
    return (
        <Router>
            <Routes>
                <Route path="/" element={<BookList />} />
                <Route path="/detail/:id" element={<BookDetail />} />
                <Route path="/create" element={<BookForm />} />
                <Route path="/update/:id" element={<BookForm />} />
                <Route path="/delete/:id" element={<BookDelete />} />
            </Routes>
        </Router>
    );
}

export default App;
```

---

## ✅ **3. Summary**

* **Backend:** DRF `ModelViewSet` exposes **CRUDL APIs** for `Book`.
* **Frontend:** React SPA with **Axios service layer**, **React Router**, and full **CRUDL UI**.
* **Flow:**
  `React Form → Axios → DRF API → Django ORM → Database → Axios Response → React UI`.
* **Scalable:** Can extend to multiple models, authentication, pagination, and search.
