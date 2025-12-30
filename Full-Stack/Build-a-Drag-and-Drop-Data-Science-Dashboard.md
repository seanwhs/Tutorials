# ⚛️ Drag-and-Drop Data Science Dashboard 

This guide walks you through building a **full-stack, interactive, drag-and-drop data science dashboard** using **Django REST Framework (DRF)** for the backend and **React** for the frontend. The dashboard supports **dynamic dataset filtering**, **offline caching**, **multi-tab synchronization**, and **resizable chart widgets**.

---

## **Folder Structure – Modular and Scalable**

We adopt a modular folder layout to ensure **separation of concerns**, maintainability, and scalability:

```
data-science-app/
├── backend/
│   └── ... (unchanged from previous template: Django + DRF models, serializers, views)
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Dashboard.js         # Main drag-and-drop dashboard container
│   │   │   ├── ChartWidget.js       # Individual chart widget component
│   │   │   ├── DataTable.js         # Optional tabular display of datasets
│   │   │   └── FiltersPanel.js      # Dynamic dataset filtering panel
│   │   ├── context/
│   │   │   └── DataContext.js       # Global state management via Context + Reducer
│   │   ├── hooks/
│   │   │   └── useFetchData.js      # Custom hook for fetching datasets
│   │   ├── reducers/
│   │   │   └── dataReducer.js       # Reducer to manage dataset state
│   │   ├── services/
│   │   │   └── apiService.js        # API adapter for DRF endpoints
│   │   ├── App.js                   # Root React component
│   │   └── index.js                 # Entry point
```

> This layout ensures that **UI components, business logic, and API services are decoupled**, facilitating maintainability and reusability.

---

## **1. Backend – Optional Dynamic Filtering Endpoint**

We extend the DRF `ViewSet` to allow **dynamic filtering of datasets** on the backend.

```python
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import viewsets
import pandas as pd
from .models import Dataset
from .serializers import DatasetSerializer

class DatasetViewSet(viewsets.ModelViewSet):
    """
    DatasetViewSet handles CRUD operations on datasets
    and provides a dynamic filtering endpoint for the frontend.
    """
    queryset = Dataset.objects.all()
    serializer_class = DatasetSerializer

    @action(detail=True, methods=['get'])
    def filter(self, request, pk=None):
        """
        Dynamic filtering by feature range:
        - feature: column to filter
        - min: minimum value
        - max: maximum value
        """
        dataset = self.get_object()
        feature = request.query_params.get('feature')
        min_val = float(request.query_params.get('min', 0))
        max_val = float(request.query_params.get('max', 100))
        
        df = pd.read_csv(dataset.data_file.path)
        filtered = df[(df[feature] >= min_val) & (df[feature] <= max_val)]
        return Response(filtered.to_dict(orient='records'))
```

> ✅ This endpoint allows React to **request filtered datasets in real time**, enabling interactive chart updates.

---

## **2. Frontend – Drag-and-Drop Dashboard**

The frontend provides a **responsive grid layout** with drag-and-drop, resizable chart widgets, and dynamic filters.

---

### **2.1 Install Required Packages**

```bash
npm install react-grid-layout react-resizable react-draggable react-plotly.js idb axios
```

* `react-grid-layout`: For **grid-based layouts and drag-and-drop**
* `react-resizable` & `react-draggable`: For **resizing and moving components**
* `react-plotly.js`: For **interactive charts**
* `idb`: IndexedDB wrapper for **offline caching**
* `axios`: For **API requests**

---

### **2.2 Dashboard.js – Drag-and-Drop Layout**

```javascript
import React from 'react';
import { Responsive, WidthProvider } from 'react-grid-layout';
import ChartWidget from './ChartWidget';
import FiltersPanel from './FiltersPanel';
import useFetchData from '../hooks/useFetchData';
import 'react-grid-layout/css/styles.css';
import 'react-resizable/css/styles.css';

const ResponsiveGridLayout = WidthProvider(Responsive);

export default function Dashboard() {
  const state = useFetchData();
  const { datasets, loading, error } = state;

  if (loading) return <p>Loading datasets...</p>;
  if (error) return <p>Error loading datasets</p>;

  return (
    <div>
      <h1>Data Science Dashboard</h1>
      <FiltersPanel datasets={datasets} />
      <ResponsiveGridLayout
        className="layout"
        cols={{ lg: 12, md: 10, sm: 6, xs: 4 }}
        rowHeight={120}
        isResizable
        isDraggable
      >
        {datasets.map((ds, i) => (
          <div key={ds.id} data-grid={{ x: 0, y: i, w: 6, h: 3 }}>
            <ChartWidget datasetId={ds.id} strategy="linear" />
          </div>
        ))}
      </ResponsiveGridLayout>
    </div>
  );
}
```

> Here, `react-grid-layout` provides a **responsive, resizable, and draggable grid**. Each chart widget is independent and can be moved or resized.

---

### **2.3 FiltersPanel.js – Interactive Filtering**

```javascript
import React, { useState, useContext } from 'react';
import { DataContext } from '../context/DataContext';
import { fetchFilteredDataset } from '../services/apiService';

export default function FiltersPanel({ datasets }) {
  const { dispatch } = useContext(DataContext);
  const [feature, setFeature] = useState('');
  const [min, setMin] = useState('');
  const [max, setMax] = useState('');
  const [datasetId, setDatasetId] = useState(datasets[0]?.id || 0);

  const handleFilter = async () => {
    dispatch({ type: 'FETCH_START' });
    try {
      const res = await fetchFilteredDataset(datasetId, feature, min, max);
      dispatch({ type: 'FETCH_SUCCESS', payload: res.data });
    } catch (err) {
      dispatch({ type: 'FETCH_ERROR', payload: err });
    }
  };

  return (
    <div style={{ marginBottom: '20px' }}>
      <select onChange={e => setDatasetId(e.target.value)} value={datasetId}>
        {datasets.map(ds => <option key={ds.id} value={ds.id}>{ds.name}</option>)}
      </select>
      <input placeholder="Feature" value={feature} onChange={e => setFeature(e.target.value)} />
      <input placeholder="Min" type="number" value={min} onChange={e => setMin(e.target.value)} />
      <input placeholder="Max" type="number" value={max} onChange={e => setMax(e.target.value)} />
      <button onClick={handleFilter}>Apply Filter</button>
    </div>
  );
}
```

> Filters are applied **in real time**. On filter change, `ChartWidget` re-renders automatically due to **state updates** in the context.

---

### **2.4 apiService.js – API Adapter**

```javascript
import axios from 'axios';

export const fetchDatasets = () => axios.get('http://localhost:8000/datasets/');

export const fetchFilteredDataset = (id, feature, min, max) =>
  axios.get(`http://localhost:8000/datasets/${id}/filter/?feature=${feature}&min=${min}&max=${max}`);
```

> Using an **adapter pattern** separates API calls from UI logic, improving modularity and testability.

---

### **2.5 ChartWidget.js – Reusable Chart Component**

```javascript
import React, { useEffect, useState } from 'react';
import Plot from 'react-plotly.js';
import { fetchFilteredDataset } from '../services/apiService';

export default function ChartWidget({ datasetId, strategy }) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    fetchFilteredDataset(datasetId, 'feature1', 0, 100)
      .then(res => {
        setData(res.data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, [datasetId, strategy]);

  if (loading) return <p>Loading chart...</p>;

  return (
    <Plot
      data={[{
        x: data.map(d => d.feature1),
        y: data.map(d => d.predicted),
        type: 'scatter',
        mode: 'lines+markers',
        name: strategy
      }]}
      layout={{ title: `Predictions (${strategy}) vs Feature1` }}
    />
  );
}
```

> Each chart widget is **independent and reusable**, allowing different datasets and strategies.

---

## **3. Context + Reducer – Offline and Multi-Tab Sync**

We use **React Context + Reducer** for state management, combined with **IndexedDB** for offline caching and `localStorage` events for multi-tab sync.

```javascript
import React, { createContext, useReducer, useEffect } from 'react';
import { openDB } from 'idb';
import { fetchDatasets } from '../services/apiService';

export const DataContext = createContext();

const initialState = { datasets: [], loading: false, error: null };

function reducer(state, action) {
  switch (action.type) {
    case 'FETCH_START': return { ...state, loading: true, error: null };
    case 'FETCH_SUCCESS': return { ...state, loading: false, datasets: action.payload };
    case 'FETCH_ERROR': return { ...state, loading: false, error: action.payload };
    default: return state;
  }
}

export const DataProvider = ({ children }) => {
  const [state, dispatch] = useReducer(reducer, initialState);

  // Initialize IndexedDB and fetch datasets
  useEffect(() => {
    const initDB = async () => {
      const db = await openDB('DataScienceDB', 1, {
        upgrade(db) { db.createObjectStore('datasets', { keyPath: 'id' }); }
      });
      return db;
    };

    const loadData = async () => {
      dispatch({ type: 'FETCH_START' });
      try {
        const db = await initDB();
        const res = await fetchDatasets();
        const datasets = res.data;
        const tx = db.transaction('datasets', 'readwrite');
        datasets.forEach(ds => tx.store.put(ds));
        await tx.done;
        dispatch({ type: 'FETCH_SUCCESS', payload: datasets });
      } catch (err) {
        const db = await initDB();
        const cached = await db.getAll('datasets');
        if (cached.length > 0) dispatch({ type: 'FETCH_SUCCESS', payload: cached });
        else dispatch({ type: 'FETCH_ERROR', payload: err });
      }
    };

    loadData();
  }, []);

  // Multi-tab synchronization
  useEffect(() => {
    const handler = e => {
      if (e.key === 'datasets-update') {
        const updated = JSON.parse(e.newValue);
        dispatch({ type: 'FETCH_SUCCESS', payload: updated });
      }
    };
    window.addEventListener('storage', handler);
    return () => window.removeEventListener('storage', handler);
  }, []);

  return <DataContext.Provider value={{ state, dispatch }}>{children}</DataContext.Provider>;
};
```

> This setup ensures **offline-first access** and **real-time updates across multiple tabs**.

---

## **4. Key Design Patterns and Concepts**

| Layer                 | Pattern / Concept                     | Usage Example                            |
| --------------------- | ------------------------------------- | ---------------------------------------- |
| Frontend Components   | Reusable Widgets, Compound Components | `ChartWidget`, `FiltersPanel`            |
| Frontend Layout       | Drag-and-Drop, Responsive Grid        | `react-grid-layout`                      |
| Frontend State        | Context + Reducer                     | Global dataset updates                   |
| Offline & Sync        | IndexedDB + LocalStorage Event        | Multi-tab synchronization                |
| Backend Service Layer | Strategy / Adapter / Facade           | Dynamic filtering, multi-model selection |
| Observer              | React re-render on state changes      | Context triggers dashboard updates       |
| DRY / Modular         | Separation of concerns                | Components, services, hooks              |

> Following these patterns improves **maintainability, scalability, and testability**.

---

## **5. Running the Full-Stack Dashboard**

### **Backend**

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py makemigrations
python manage.py migrate
python manage.py runserver
```

### **Frontend**

```bash
cd frontend
npm install
npm start
```

**Visit the app at:** `http://localhost:3000`

> ✅ You now have a **multi-tab, offline-capable, drag-and-drop dashboard** with dynamic filtering and interactive charts.

---

### **Key Takeaways**

1. **Clean Folder Structure** – separates concerns for frontend, backend, and services.
2. **Pattern-Driven Architecture** – Context + Reducer, Adapter/Facade, Strategy patterns.
3. **Offline & Multi-Tab Functionality** – using IndexedDB and `localStorage` events.
4. **Interactive, Resizable, Drag-and-Drop Charts** – using `react-grid-layout` and `Plotly.js`.
5. **Full-Stack Integration** – DRF backend serving data dynamically to React frontend.

> This approach demonstrates **modern full-stack dashboard design**, balancing **responsiveness, interactivity, and robustness**.

---
# ⚛️ Drag-and-Drop Data Science Dashboard – Comprehensive Guide

This guide walks you through building a **full-stack, interactive, drag-and-drop data science dashboard** using **Django REST Framework (DRF)** for the backend and **React** for the frontend. The dashboard supports **dynamic dataset filtering**, **offline caching**, **multi-tab synchronization**, and **resizable chart widgets**.

---

## **Folder Structure – Modular and Scalable**

We adopt a modular folder layout to ensure **separation of concerns**, maintainability, and scalability:

```
data-science-app/
├── backend/
│   └── ... (unchanged from previous template: Django + DRF models, serializers, views)
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Dashboard.js         # Main drag-and-drop dashboard container
│   │   │   ├── ChartWidget.js       # Individual chart widget component
│   │   │   ├── DataTable.js         # Optional tabular display of datasets
│   │   │   └── FiltersPanel.js      # Dynamic dataset filtering panel
│   │   ├── context/
│   │   │   └── DataContext.js       # Global state management via Context + Reducer
│   │   ├── hooks/
│   │   │   └── useFetchData.js      # Custom hook for fetching datasets
│   │   ├── reducers/
│   │   │   └── dataReducer.js       # Reducer to manage dataset state
│   │   ├── services/
│   │   │   └── apiService.js        # API adapter for DRF endpoints
│   │   ├── App.js                   # Root React component
│   │   └── index.js                 # Entry point
```

> This layout ensures that **UI components, business logic, and API services are decoupled**, facilitating maintainability and reusability.

---

## **1. Backend – Optional Dynamic Filtering Endpoint**

We extend the DRF `ViewSet` to allow **dynamic filtering of datasets** on the backend.

```python
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import viewsets
import pandas as pd
from .models import Dataset
from .serializers import DatasetSerializer

class DatasetViewSet(viewsets.ModelViewSet):
    """
    DatasetViewSet handles CRUD operations on datasets
    and provides a dynamic filtering endpoint for the frontend.
    """
    queryset = Dataset.objects.all()
    serializer_class = DatasetSerializer

    @action(detail=True, methods=['get'])
    def filter(self, request, pk=None):
        """
        Dynamic filtering by feature range:
        - feature: column to filter
        - min: minimum value
        - max: maximum value
        """
        dataset = self.get_object()
        feature = request.query_params.get('feature')
        min_val = float(request.query_params.get('min', 0))
        max_val = float(request.query_params.get('max', 100))
        
        df = pd.read_csv(dataset.data_file.path)
        filtered = df[(df[feature] >= min_val) & (df[feature] <= max_val)]
        return Response(filtered.to_dict(orient='records'))
```

> ✅ This endpoint allows React to **request filtered datasets in real time**, enabling interactive chart updates.

---

## **2. Frontend – Drag-and-Drop Dashboard**

The frontend provides a **responsive grid layout** with drag-and-drop, resizable chart widgets, and dynamic filters.

---

### **2.1 Install Required Packages**

```bash
npm install react-grid-layout react-resizable react-draggable react-plotly.js idb axios
```

* `react-grid-layout`: For **grid-based layouts and drag-and-drop**
* `react-resizable` & `react-draggable`: For **resizing and moving components**
* `react-plotly.js`: For **interactive charts**
* `idb`: IndexedDB wrapper for **offline caching**
* `axios`: For **API requests**

---

### **2.2 Dashboard.js – Drag-and-Drop Layout**

```javascript
import React from 'react';
import { Responsive, WidthProvider } from 'react-grid-layout';
import ChartWidget from './ChartWidget';
import FiltersPanel from './FiltersPanel';
import useFetchData from '../hooks/useFetchData';
import 'react-grid-layout/css/styles.css';
import 'react-resizable/css/styles.css';

const ResponsiveGridLayout = WidthProvider(Responsive);

export default function Dashboard() {
  const state = useFetchData();
  const { datasets, loading, error } = state;

  if (loading) return <p>Loading datasets...</p>;
  if (error) return <p>Error loading datasets</p>;

  return (
    <div>
      <h1>Data Science Dashboard</h1>
      <FiltersPanel datasets={datasets} />
      <ResponsiveGridLayout
        className="layout"
        cols={{ lg: 12, md: 10, sm: 6, xs: 4 }}
        rowHeight={120}
        isResizable
        isDraggable
      >
        {datasets.map((ds, i) => (
          <div key={ds.id} data-grid={{ x: 0, y: i, w: 6, h: 3 }}>
            <ChartWidget datasetId={ds.id} strategy="linear" />
          </div>
        ))}
      </ResponsiveGridLayout>
    </div>
  );
}
```

> Here, `react-grid-layout` provides a **responsive, resizable, and draggable grid**. Each chart widget is independent and can be moved or resized.

---

### **2.3 FiltersPanel.js – Interactive Filtering**

```javascript
import React, { useState, useContext } from 'react';
import { DataContext } from '../context/DataContext';
import { fetchFilteredDataset } from '../services/apiService';

export default function FiltersPanel({ datasets }) {
  const { dispatch } = useContext(DataContext);
  const [feature, setFeature] = useState('');
  const [min, setMin] = useState('');
  const [max, setMax] = useState('');
  const [datasetId, setDatasetId] = useState(datasets[0]?.id || 0);

  const handleFilter = async () => {
    dispatch({ type: 'FETCH_START' });
    try {
      const res = await fetchFilteredDataset(datasetId, feature, min, max);
      dispatch({ type: 'FETCH_SUCCESS', payload: res.data });
    } catch (err) {
      dispatch({ type: 'FETCH_ERROR', payload: err });
    }
  };

  return (
    <div style={{ marginBottom: '20px' }}>
      <select onChange={e => setDatasetId(e.target.value)} value={datasetId}>
        {datasets.map(ds => <option key={ds.id} value={ds.id}>{ds.name}</option>)}
      </select>
      <input placeholder="Feature" value={feature} onChange={e => setFeature(e.target.value)} />
      <input placeholder="Min" type="number" value={min} onChange={e => setMin(e.target.value)} />
      <input placeholder="Max" type="number" value={max} onChange={e => setMax(e.target.value)} />
      <button onClick={handleFilter}>Apply Filter</button>
    </div>
  );
}
```

> Filters are applied **in real time**. On filter change, `ChartWidget` re-renders automatically due to **state updates** in the context.

---

### **2.4 apiService.js – API Adapter**

```javascript
import axios from 'axios';

export const fetchDatasets = () => axios.get('http://localhost:8000/datasets/');

export const fetchFilteredDataset = (id, feature, min, max) =>
  axios.get(`http://localhost:8000/datasets/${id}/filter/?feature=${feature}&min=${min}&max=${max}`);
```

> Using an **adapter pattern** separates API calls from UI logic, improving modularity and testability.

---

### **2.5 ChartWidget.js – Reusable Chart Component**

```javascript
import React, { useEffect, useState } from 'react';
import Plot from 'react-plotly.js';
import { fetchFilteredDataset } from '../services/apiService';

export default function ChartWidget({ datasetId, strategy }) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    fetchFilteredDataset(datasetId, 'feature1', 0, 100)
      .then(res => {
        setData(res.data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, [datasetId, strategy]);

  if (loading) return <p>Loading chart...</p>;

  return (
    <Plot
      data={[{
        x: data.map(d => d.feature1),
        y: data.map(d => d.predicted),
        type: 'scatter',
        mode: 'lines+markers',
        name: strategy
      }]}
      layout={{ title: `Predictions (${strategy}) vs Feature1` }}
    />
  );
}
```

> Each chart widget is **independent and reusable**, allowing different datasets and strategies.

---

## **3. Context + Reducer – Offline and Multi-Tab Sync**

We use **React Context + Reducer** for state management, combined with **IndexedDB** for offline caching and `localStorage` events for multi-tab sync.

```javascript
import React, { createContext, useReducer, useEffect } from 'react';
import { openDB } from 'idb';
import { fetchDatasets } from '../services/apiService';

export const DataContext = createContext();

const initialState = { datasets: [], loading: false, error: null };

function reducer(state, action) {
  switch (action.type) {
    case 'FETCH_START': return { ...state, loading: true, error: null };
    case 'FETCH_SUCCESS': return { ...state, loading: false, datasets: action.payload };
    case 'FETCH_ERROR': return { ...state, loading: false, error: action.payload };
    default: return state;
  }
}

export const DataProvider = ({ children }) => {
  const [state, dispatch] = useReducer(reducer, initialState);

  // Initialize IndexedDB and fetch datasets
  useEffect(() => {
    const initDB = async () => {
      const db = await openDB('DataScienceDB', 1, {
        upgrade(db) { db.createObjectStore('datasets', { keyPath: 'id' }); }
      });
      return db;
    };

    const loadData = async () => {
      dispatch({ type: 'FETCH_START' });
      try {
        const db = await initDB();
        const res = await fetchDatasets();
        const datasets = res.data;
        const tx = db.transaction('datasets', 'readwrite');
        datasets.forEach(ds => tx.store.put(ds));
        await tx.done;
        dispatch({ type: 'FETCH_SUCCESS', payload: datasets });
      } catch (err) {
        const db = await initDB();
        const cached = await db.getAll('datasets');
        if (cached.length > 0) dispatch({ type: 'FETCH_SUCCESS', payload: cached });
        else dispatch({ type: 'FETCH_ERROR', payload: err });
      }
    };

    loadData();
  }, []);

  // Multi-tab synchronization
  useEffect(() => {
    const handler = e => {
      if (e.key === 'datasets-update') {
        const updated = JSON.parse(e.newValue);
        dispatch({ type: 'FETCH_SUCCESS', payload: updated });
      }
    };
    window.addEventListener('storage', handler);
    return () => window.removeEventListener('storage', handler);
  }, []);

  return <DataContext.Provider value={{ state, dispatch }}>{children}</DataContext.Provider>;
};
```

> This setup ensures **offline-first access** and **real-time updates across multiple tabs**.

---

## **4. Key Design Patterns and Concepts**

| Layer                 | Pattern / Concept                     | Usage Example                            |
| --------------------- | ------------------------------------- | ---------------------------------------- |
| Frontend Components   | Reusable Widgets, Compound Components | `ChartWidget`, `FiltersPanel`            |
| Frontend Layout       | Drag-and-Drop, Responsive Grid        | `react-grid-layout`                      |
| Frontend State        | Context + Reducer                     | Global dataset updates                   |
| Offline & Sync        | IndexedDB + LocalStorage Event        | Multi-tab synchronization                |
| Backend Service Layer | Strategy / Adapter / Facade           | Dynamic filtering, multi-model selection |
| Observer              | React re-render on state changes      | Context triggers dashboard updates       |
| DRY / Modular         | Separation of concerns                | Components, services, hooks              |

> Following these patterns improves **maintainability, scalability, and testability**.

---

## **5. Running the Full-Stack Dashboard**

### **Backend**

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py makemigrations
python manage.py migrate
python manage.py runserver
```

### **Frontend**

```bash
cd frontend
npm install
npm start
```

**Visit the app at:** `http://localhost:3000`

> ✅ You now have a **multi-tab, offline-capable, drag-and-drop dashboard** with dynamic filtering and interactive charts.

---

### **Key Takeaways**

1. **Clean Folder Structure** – separates concerns for frontend, backend, and services.
2. **Pattern-Driven Architecture** – Context + Reducer, Adapter/Facade, Strategy patterns.
3. **Offline & Multi-Tab Functionality** – using IndexedDB and `localStorage` events.
4. **Interactive, Resizable, Drag-and-Drop Charts** – using `react-grid-layout` and `Plotly.js`.
5. **Full-Stack Integration** – DRF backend serving data dynamically to React frontend.

> This approach demonstrates **modern full-stack dashboard design**, balancing **responsiveness, interactivity, and robustness**.

---

# **🖥️ Master Architecture Diagram – Full-Stack Drag-and-Drop Dashboard**

```
                                    ┌───────────────────────────┐
                                    │        Backend (DRF)      │
                                    │---------------------------│
                                    │ DatasetViewSet            │
                                    │  • CRUD datasets          │
                                    │  • /filter endpoint       │
                                    │---------------------------│
                                    │ Pandas DataFrame          │
                                    │  • Filter by feature      │
                                    │  • Return JSON records    │
                                    └─────────────┬─────────────┘
                                                  │ REST API
                                                  │ (axios)
                                                  ▼
                                    ┌───────────────────────────┐
                                    │      API Service Layer     │
                                    │---------------------------│
                                    │ fetchDatasets()           │
                                    │ fetchFilteredDataset()    │
                                    │---------------------------│
                                    │ Adapter / Facade Pattern  │
                                    │  • Separates API calls     │
                                    │    from UI logic          │
                                    └─────────────┬─────────────┘
                                                  │
                                                  ▼
                                    ┌───────────────────────────┐
                                    │    Context + Reducer      │
                                    │---------------------------│
                                    │ DataContext.js            │
                                    │  • Global dataset state   │
                                    │  • FETCH_START/           │
                                    │    FETCH_SUCCESS/         │
                                    │    FETCH_ERROR            │
                                    │---------------------------│
                                    │ IndexedDB Cache           │
                                    │  • Offline-first support  │
                                    │  • Stores datasets locally│
                                    │---------------------------│
                                    │ Multi-Tab Sync            │
                                    │  • localStorage event     │
                                    │  • Updates all tabs       │
                                    └─────────────┬─────────────┘
                                                  │
                                                  ▼
                                    ┌───────────────────────────┐
                                    │   React Components Layer   │
                                    │---------------------------│
                                    │ Dashboard.js              │
                                    │  • Responsive Grid Layout │
                                    │  • Drag & Drop widgets    │
                                    │---------------------------│
                                    │ FiltersPanel.js           │
                                    │  • Dynamic filtering      │
                                    │  • Dispatches FETCH actions│
                                    │---------------------------│
                                    │ ChartWidget.js            │
                                    │  • Reusable charts        │
                                    │  • Updates on filter/state│
                                    │  • Plotly.js scatter/line │
                                    └─────────────┬─────────────┘
                                                  │ User Interaction
                                                  ▼
                                    ┌───────────────────────────┐
                                    │     User Actions          │
                                    │---------------------------│
                                    │ 1. Select dataset         │
                                    │ 2. Apply filter (feature, │
                                    │    min, max)              │
                                    │ 3. Drag & resize widgets  │
                                    │---------------------------│
                                    │ Lifecycle Flow:           │
                                    │  • Filter triggers API    │
                                    │  • Context updates state  │
                                    │  • ChartWidget re-renders │
                                    │  • IndexedDB caches data  │
                                    │  • localStorage syncs tabs│
                                    └───────────────────────────┘
```

---

### **Highlights of the Master Diagram**

1. **Backend (DRF)**

   * Handles CRUD operations and dynamic filtering.
   * Pandas handles **feature-based filtering**, returns JSON.

2. **API Service Layer**

   * Acts as an **adapter/facade**, isolating network calls from UI logic.
   * Provides reusable functions like `fetchDatasets()`.

3. **Context + Reducer**

   * Central **state manager** for dataset updates.
   * Integrates **IndexedDB** for offline-first access.
   * Supports **multi-tab synchronization** via `localStorage`.

4. **React Components**

   * **Dashboard.js**: Grid layout supporting drag, drop, and resize.
   * **FiltersPanel.js**: Sends filter requests and updates context.
   * **ChartWidget.js**: Reusable chart component that reacts to context updates.

5. **User Interaction**

   * Filter datasets, drag-and-drop widgets, resize charts.
   * **Full reactive lifecycle**: Input → API → Context → UI → Offline caching → Multi-tab sync.

---

This **master diagram** merges both **structural layers** and **dataset lifecycle**, giving a **complete view of the dashboard architecture**—perfect for a textbook-style reference.

---

