# 📘 PyInsight: Build a Production-Ready CSV Analytics App with React + Django REST (DRI)

> Step-by-step guide for building a full-stack CSV analytics platform with async pipelines, plugin support, rule engine, metrics, secrets, Docker/Kubernetes deployment, and a modular React DRI frontend.

---

## 0️⃣ Prerequisites

* Python 3.12+, Node 20+, npm/yarn
* Docker & Docker Compose (optional for containerized setup)
* Basic understanding of React, TypeScript, Django REST Framework

---

## 1️⃣ Create the Project Structure

Create the root folder:

```bash
mkdir pyinsight
cd pyinsight
mkdir backend frontend docker k8s
```

---

### Folder Layout

```
pyinsight/
├── backend/
├── frontend/
├── docker/
├── k8s/
└── README.md
```

---

## 2️⃣ Backend Setup (Django REST)

### 2.1 Create & Activate Virtualenv

```bash
cd backend
python -m venv venv
source venv/bin/activate
```

---

### 2.2 Install Dependencies

```bash
pip install django djangorestframework pyyaml aiofiles opentelemetry-api opentelemetry-sdk
```

---

### 2.3 Create Django Project & App

```bash
django-admin startproject pyinsight .
python manage.py startapp pyinsight
```

---

### 2.4 Backend Directory Layout

```
backend/
├── pyinsight/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── asgi.py
│   ├── wsgi.py
│   ├── models.py
│   ├── serializers.py
│   ├── views.py
│   ├── tasks.py
│   ├── validators.py
│   ├── plugins/
│   │   ├── __init__.py
│   │   └── base.py
│   ├── rules.py
│   ├── rules.yaml
│   ├── metrics.py
│   └── secrets.py
├── manage.py
└── requirements.txt
```

---

## 2.5 Backend Code (Full)

### `validators.py`

```python
from rest_framework.exceptions import ValidationError

def validate_rows(rows, required_columns):
    for idx, row in enumerate(rows, start=1):
        for col in required_columns:
            if col not in row or row[col] == "":
                raise ValidationError(f"Missing or empty '{col}' in row {idx}")
```

---

### `tasks.py` (Async Pipelines + Plugin Orchestration)

```python
import asyncio
import csv
from pyinsight.plugins import discover_plugins
from pyinsight.rules import evaluate_rules
from pyinsight.analysis import summarize

async def analyze_async_from_rows(rows, column):
    summary = summarize(rows, column)
    rule_flags = evaluate_rules(rows)
    plugin_results = await discover_plugins(rows)
    return {"summary": summary, "rules": rule_flags, "plugins": plugin_results}

def run_analysis(rows, column):
    loop = asyncio.get_event_loop()
    return loop.run_until_complete(analyze_async_from_rows(rows, column))
```

---

### `analysis.py` (Core Analysis)

```python
def summarize(rows, column):
    values = [float(r[column]) for r in rows if r[column] != ""]
    count = len(values)
    return {
        "count": count,
        "avg": sum(values)/count if count else 0,
        "min": min(values) if values else 0,
        "max": max(values) if values else 0
    }
```

---

### `rules.py` (Declarative Rule Engine)

```python
import yaml

def evaluate_rules(rows):
    with open("pyinsight/rules.yaml") as f:
        rules = yaml.safe_load(f)["rules"]
    violations = []
    for rule in rules:
        col = rule["column"]
        for idx, row in enumerate(rows, start=1):
            value = float(row.get(col, 0))
            if eval(rule["condition"], {"value": value}):
                violations.append({"row": idx, "rule": rule["name"], "action": rule["action"]})
    return violations
```

---

### `plugins/base.py`

```python
from abc import ABC, abstractmethod

class Plugin(ABC):
    name: str

    @abstractmethod
    async def analyze(self, rows):
        ...
```

### `plugins/sample_plugin.py`

```python
from .base import Plugin

class RSICalculator(Plugin):
    name = "rsi"
    async def analyze(self, rows):
        return {"rsi": 42}  # placeholder
```

---

### `views.py`

```python
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
import csv
from pyinsight.validators import validate_rows
from pyinsight.tasks import run_analysis

class AnalyzeCSV(APIView):
    def post(self, request):
        file = request.FILES.get("file")
        column = request.data.get("column")
        if not file or not column:
            return Response({"error": "Missing file or column"}, status=status.HTTP_400_BAD_REQUEST)

        rows = [row for row in csv.DictReader(file.read().decode().splitlines())]
        validate_rows(rows, [column])
        summary = run_analysis(rows, column)
        return Response(summary)
```

---

### `urls.py`

```python
from django.urls import path
from pyinsight.views import AnalyzeCSV

urlpatterns = [
    path("api/analyze/", AnalyzeCSV.as_view()),
]
```

---

### `rules.yaml`

```yaml
rules:
  - name: high_score
    column: score
    condition: "value > 90"
    action: "flag"
  - name: low_score
    column: score
    condition: "value < 40"
    action: "warn"
```

---

## 3️⃣ Frontend Setup (React + TypeScript + DRI)

### 3.1 Create React App

```bash
cd ../frontend
npm create vite@latest pyinsight-frontend -- --template react-ts
cd pyinsight-frontend
npm install axios
```

---

### 3.2 Frontend Folder Structure

```
frontend/src/
├── api/pyinsightAPI.ts
├── components/
│   ├── Dashboard.tsx
│   ├── FileUploader.tsx
│   ├── SummaryCard.tsx
│   ├── RuleFlags.tsx
│   └── PluginResults.tsx
├── hooks/usePyInsight.ts
├── App.tsx
└── main.tsx
```

---

### `api/pyinsightAPI.ts`

```ts
import axios from "axios";

export const analyzeCSV = async (file: File, column: string) => {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("column", column);
  const response = await axios.post("/api/analyze/", formData);
  return response.data;
};
```

---

### `hooks/usePyInsight.ts`

```ts
import { useState } from "react";
import { analyzeCSV } from "../api/pyinsightAPI";

export const usePyInsight = () => {
  const [summary, setSummary] = useState<any>(null);
  const [rules, setRules] = useState<any[]>([]);
  const [plugins, setPlugins] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>("");

  const runAnalysis = async (file: File, column: string) => {
    setLoading(true);
    setError("");
    try {
      const data = await analyzeCSV(file, column);
      setSummary(data.summary);
      setRules(data.rules);
      setPlugins(data.plugins);
    } catch (err: any) {
      setError(err.message || "Analysis failed");
    } finally {
      setLoading(false);
    }
  };

  return { summary, rules, plugins, loading, error, runAnalysis };
};
```

---

### `components/FileUploader.tsx`

```tsx
import React, { useState } from "react";

interface Props { onUpload: (file: File, column: string) => void }

export const FileUploader: React.FC<Props> = ({ onUpload }) => {
  const [file, setFile] = useState<File | null>(null);
  const [column, setColumn] = useState("score");
  return (
    <div>
      <input type="file" onChange={e => setFile(e.target.files?.[0] ?? null)} />
      <input type="text" value={column} onChange={e => setColumn(e.target.value)} />
      <button onClick={() => file && onUpload(file, column)}>Analyze</button>
    </div>
  );
};
```

---

### `components/SummaryCard.tsx`

```tsx
import React from "react";

export const SummaryCard = ({ summary, column }: any) => {
  if (!summary) return null;
  return (
    <div>
      <h3>{column} Summary</h3>
      {Object.entries(summary).map(([k, v]) => <div key={k}>{k}: {v}</div>)}
    </div>
  );
};
```

---

### `components/RuleFlags.tsx`

```tsx
import React from "react";

export const RuleFlags = ({ rules }: any) => {
  if (!rules.length) return null;
  return (
    <div>
      <h3>Rule Violations</h3>
      {rules.map((r: any, i: number) => (
        <div key={i}>{r.row}: {r.rule} ({r.action})</div>
      ))}
    </div>
  );
};
```

---

### `components/PluginResults.tsx`

```tsx
import React from "react";

export const PluginResults = ({ plugins }: any) => {
  if (!plugins.length) return null;
  return (
    <div>
      <h3>Plugin Results</h3>
      {plugins.map((p: any, i: number) => (
        <div key={i}>{p.name}: {JSON.stringify(p.result)}</div>
      ))}
    </div>
  );
};
```

---

### `components/Dashboard.tsx`

```tsx
import React from "react";
import { FileUploader } from "./FileUploader";
import { SummaryCard } from "./SummaryCard";
import { RuleFlags } from "./RuleFlags";
import { PluginResults } from "./PluginResults";
import { usePyInsight } from "../hooks/usePyInsight";

export const Dashboard: React.FC = () => {
  const { summary, rules, plugins, loading, error, runAnalysis } = usePyInsight();
  return (
    <div>
      <h1>PyInsight Dashboard</h1>
      <FileUploader onUpload={runAnalysis} />
      {loading && <p>Loading...</p>}
      {error && <p style={{color:"red"}}>{error}</p>}
      <SummaryCard summary={summary} column="score" />
      <RuleFlags rules={rules} />
      <PluginResults plugins={plugins} />
    </div>
  );
};
```

---

### `App.tsx`

```tsx
import React from "react";
import { Dashboard } from "./components/Dashboard";

function App() {
  return <Dashboard />;
}

export default App;
```

---

## 4️⃣ Run Application Locally

### Backend

```bash
cd backend
python manage.py migrate
python manage.py runserver
```

### Frontend

```bash
cd frontend/pyinsight-frontend
npm install
npm run dev
```

Open browser → `http://localhost:5173` → upload CSV → see summary, rules, plugins.

---

## 5️⃣ Next Steps

1. **Add Celery for async backend tasks** for heavy CSVs.
2. **Add WebSocket / polling** to update plugin results dynamically.
3. **Add Docker & Kubernetes configs** for deployment.
4. **Add authentication, secrets, and metrics** (OpenTelemetry) for production readiness.

---

