# 📘 React + Django REST Framework (DRF) Sales Force Automation (SFA) — Step-by-Step Beginner Tutorial

## Build a Complete Sales Force Automation Application Using React + DRF

**Audience:** Complete beginners, frontend & backend developers, sales operations teams, analysts.

**Outcome:** By the end of this tutorial, you will be able to:

* Build a **full-stack SFA system** from scratch
* Integrate **Python-for-Excel** for CRM data ingestion and **Python-for-Word** for proposal/quote generation
* Implement **role-based views, alerts, reconciliation, forecasting, and daily call rosters**
* Build **interactive dashboards and production-ready APIs**
* Deploy a full-stack solution internally or on cloud

This tutorial is **verbose, example-driven, and beginner-friendly**. Every part contains step-by-step instructions, explanations, exercises, and checkpoints.

---

# Step 0: Understand the Big Picture

### What We Are Building

Our SFA application will:

* Pull data from CRM or Excel files
* Validate and reconcile data automatically
* Generate reports, dashboards, and daily rosters
* Send alerts and notifications
* Allow role-based views (Analyst, Manager, Executive)
* Generate Word proposals/quotes

### Architecture (ASCII Diagram)

```
CRM / Excel Data --> Validation --> Processing --> Reporting / Roster Generation
        |                    |             |
        v                    v             v
  Reconciliation         Alerts & Metrics --> Interactive Dashboards
                                  |
                                  v
                            Role-Based Views
```

### Mental Model

* Think of the system as **automated, observable workflows** where all errors, tasks, and metrics are visible and actionable.

### Exercise

* Draw your own SFA workflow and label the key components.
* Identify data sources, alerts, reports, and dashboards.

### Checkpoints

* [ ] Workflow diagram completed
* [ ] Roles and permissions identified
* [ ] Key metrics defined

---

# Step 1: Set Up Django REST Framework Backend

### 1.1 Install Dependencies

```bash
pip install django djangorestframework pandas openpyxl python-docx
```

### 1.2 Create Project and App

```bash
django-admin startproject sfa_backend
cd sfa_backend
django-admin startapp crm
```

### 1.3 Define Models

```python
# crm/models.py
from django.db import models

class Lead(models.Model):
    customer = models.CharField(max_length=255)
    rep = models.CharField(max_length=100)
    status = models.CharField(max_length=50)
    expected_revenue = models.DecimalField(max_digits=10, decimal_places=2)
```

### Explanation

* `Lead` represents each sales opportunity.
* Fields are equivalent to Excel columns: `customer`, `rep`, `status`, `expected_revenue`.

### Exercise

* Add `Opportunity` and `Task` models.
* Run `python manage.py makemigrations` and `python manage.py migrate`.

### Checkpoints

* [ ] Models created
* [ ] Migrations applied
* [ ] Admin panel accessible

---

# Step 2: Expose APIs with DRF

### 2.1 Create Serializers

```python
# crm/serializers.py
from rest_framework import serializers
from .models import Lead

class LeadSerializer(serializers.ModelSerializer):
    class Meta:
        model = Lead
        fields = '__all__'
```

### 2.2 Create ViewSets

```python
# crm/views.py
from rest_framework import viewsets
from .models import Lead
from .serializers import LeadSerializer

class LeadViewSet(viewsets.ModelViewSet):
    queryset = Lead.objects.all()
    serializer_class = LeadSerializer
```

### 2.3 Register Routes

```python
# sfa_backend/urls.py
from rest_framework import routers
from crm.views import LeadViewSet

router = routers.DefaultRouter()
router.register(r'leads', LeadViewSet)
urlpatterns = router.urls
```

### ASCII Diagram

```
Lead Model --> Serializer --> ViewSet --> REST API Endpoint
```

### Exercise

* Add API endpoints for `Opportunity` and `Task`.
* Test CRUD operations with Postman.

### Checkpoints

* [ ] API endpoints respond
* [ ] CRUD operations functional

---

# Step 3: Set Up React Frontend

### 3.1 Create React App

```bash
npx create-react-app sfa_frontend
cd sfa_frontend
npm install axios react-router-dom recharts
```

### 3.2 Fetch Data from Backend

```javascript
import React, { useEffect, useState } from 'react';
import axios from 'axios';

function App() {
  const [leads, setLeads] = useState([]);

  useEffect(() => {
    axios.get('http://localhost:8000/leads/')
      .then(res => setLeads(res.data));
  }, []);

  return (
    <div>
      <h1>Sales Leads</h1>
      <ul>{leads.map(lead => <li key={lead.id}>{lead.customer} - {lead.rep}</li>)}</ul>
    </div>
  );
}

export default App;
```

### ASCII Diagram

```
REST API Endpoint --> Axios Request --> React State --> UI Component
```

### Exercise

* Display Opportunities in a table.
* Add filter by Rep and Status.

### Checkpoints

* [ ] Data fetch works
* [ ] Filters functional
* [ ] UI updates dynamically

---

# Step 4: KPIs and Charts

### Using Recharts

```javascript
import { LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid } from 'recharts';
const data = leads.map(l => ({ customer: l.customer, revenue: l.expected_revenue }));
<LineChart width={500} height={300} data={data}>
  <Line type="monotone" dataKey="revenue" stroke="#8884d8" />
  <CartesianGrid stroke="#ccc" />
  <XAxis dataKey="customer" />
  <YAxis />
  <Tooltip />
</LineChart>
```

### Exercise

* Add revenue per rep and conversion rate metrics.
* Validate metrics manually with small dataset.

### Checkpoints

* [ ] Charts display correctly
* [ ] Metrics update dynamically
* [ ] Handles large datasets

---

# Step 5: Alerts and Notifications

### Backend Logic

```python
from django.core.mail import send_mail
from .models import Lead

def check_pending_leads():
    pending = Lead.objects.filter(status='Pending')
    if pending.count() > 10:
        send_mail('High Pending Leads', 'Please review pending leads', 'admin@example.com', ['manager@example.com'])
```

### Frontend Display

```javascript
{pendingLeads > 10 && <div className='alert'>High number of pending leads!</div>}
```

### Exercise

* Add overdue task alerts.
* Integrate Slack notifications.

### Checkpoints

* [ ] Alerts visible
* [ ] Notifications delivered
* [ ] Thresholds configurable

---

# Step 6: Document Generation (Word)

### Generate Proposals/Quotes

```python
from docx import Document
for lead in Lead.objects.all():
    doc = Document('proposal_template.docx')
    doc.paragraphs[0].text = f'Proposal for {lead.customer}'
    doc.save(f'proposal_{lead.customer}.docx')
```

### Exercise

* Create API endpoint to generate proposals.
* Trigger from React frontend.

### Checkpoints

* [ ] Documents generated correctly
* [ ] API functional
* [ ] Frontend trigger works

---

# Step 7: Forecasting and Scenario Analysis

### Backend Calculation

```python
forecasted_revenue = Lead.objects.aggregate(Sum('expected_revenue'))['expected_revenue__sum'] * 1.1
```

### Exercise

* Add best/worst/expected scenarios.
* Trigger alerts on deviations.

### Checkpoints

* [ ] Forecast calculations correct
* [ ] Alerts functional
* [ ] Dashboard updates dynamically

---

# Step 8: Daily/Weekly Sales Roster

### Backend Generation

```python
for day in ['Monday','Tuesday']:
    for rep in Lead.objects.values_list('rep', flat=True).distinct():
        # generate roster document
        pass
```

### Exercise

* Detect double-booked calls.
* Notify reps of conflicts.

### Checkpoints

* [ ] Rosters generated
* [ ] Conflicts detected
* [ ] Alerts sent

---

# Step 9: Role-Based Views

### Backend Filtering

```python
if user.role == 'Manager':
    leads = Lead.objects.filter(region=user.region)
elif user.role == 'Executive':
    leads = Lead.objects.all()
```

### Exercise

* Test role-based filtering.
* Ensure sensitive data hidden.

### Checkpoints

* [ ] Backend role filtering works
* [ ] Frontend displays correctly
* [ ] Sensitive data hidden

---

# Step 10: Production-Ready Features

* **Validation & Reconciliation**
* **Enterprise Scheduling & CLI Triggers**
* **Alerts & Notifications**
* **Role-Based Access Control**
* **Audit & Monitoring**
* **Error Handling & Recovery**
* **Documentation & Configurable Settings**

### Exercise

* Test reconciliation, scheduling, alerts, and role-based access.

### Checkpoints

* [ ] Validation and reconciliation implemented
* [ ] Scheduling functional
* [ ] Alerts delivered
* [ ] RBAC enforced
* [ ] Audit logs maintained
* [ ] Error-handling verified

Congratulations! You now have a **complete, production-ready full-stack Sales Force Automation system** built step-by-step from scratch.
