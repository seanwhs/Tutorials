# **Step-by-Step Tutorial: Building a Django + AdminLTE Data Science Dashboard**

**Goal:** Create a web application to upload CSV datasets, explore data, and visualize key metrics with AdminLTE UI.

**Tech Stack:**

* Backend: Django (Python 3.x)
* Frontend: AdminLTE (Bootstrap 4/5)
* Database: SQLite (for development) / MySQL/PostgreSQL (optional for production)
* Data Handling: Pandas
* Visualization: Plotly, Matplotlib, Seaborn
* Deployment: Optional (Heroku, Railway, or Render free-tier)

---

## **Step 1: Set Up the Project Environment**

1. Create a project folder:

```bash
mkdir django_admlte_ds
cd django_admlte_ds
```

2. Set up a virtual environment:

```bash
python -m venv venv
source venv/bin/activate      # Linux/Mac
venv\Scripts\activate         # Windows
```

3. Install dependencies:

```bash
pip install django pandas matplotlib seaborn plotly django-crispy-forms
```

4. Start Django project:

```bash
django-admin startproject dashboard_project .
```

5. Start a Django app:

```bash
python manage.py startapp analytics
```

---

## **Step 2: Integrate AdminLTE**

AdminLTE provides a **pre-built dashboard UI**.

1. Download AdminLTE:
   [AdminLTE GitHub](https://github.com/ColorlibHQ/AdminLTE)

2. Copy the **`dist` folder** into `analytics/static/adminlte/`.

3. Configure static files in `settings.py`:

```python
STATIC_URL = '/static/'
STATICFILES_DIRS = [BASE_DIR / 'analytics/static']
```

4. Create a base template: `analytics/templates/base.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>{% block title %}Dashboard{% endblock %}</title>
  <link rel="stylesheet" href="{% static 'adminlte/css/adminlte.min.css' %}">
  <link rel="stylesheet" href="{% static 'adminlte/plugins/fontawesome-free/css/all.min.css' %}">
  {% block extra_css %}{% endblock %}
</head>
<body class="hold-transition sidebar-mini">
<div class="wrapper">
    <!-- Navbar -->
    {% include 'partials/navbar.html' %}
    <!-- Sidebar -->
    {% include 'partials/sidebar.html' %}

    <div class="content-wrapper">
        <section class="content">
            {% block content %}{% endblock %}
        </section>
    </div>

    {% include 'partials/footer.html' %}
</div>

<script src="{% static 'adminlte/plugins/jquery/jquery.min.js' %}"></script>
<script src="{% static 'adminlte/js/adminlte.min.js' %}"></script>
{% block extra_js %}{% endblock %}
</body>
</html>
```

---

## **Step 3: Define Models (Data Upload)**

Create a model to handle CSV uploads.

`analytics/models.py`:

```python
from django.db import models

class Dataset(models.Model):
    name = models.CharField(max_length=100)
    csv_file = models.FileField(upload_to='datasets/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name
```

Run migrations:

```bash
python manage.py makemigrations
python manage.py migrate
```

---

## **Step 4: Create Forms for File Upload**

`analytics/forms.py`:

```python
from django import forms
from .models import Dataset

class DatasetForm(forms.ModelForm):
    class Meta:
        model = Dataset
        fields = ['name', 'csv_file']
```

---

## **Step 5: Create Views**

`analytics/views.py`:

```python
from django.shortcuts import render, redirect
from .forms import DatasetForm
from .models import Dataset
import pandas as pd
import plotly.express as px
import json

def upload_dataset(request):
    if request.method == 'POST':
        form = DatasetForm(request.POST, request.FILES)
        if form.is_valid():
            dataset = form.save()
            return redirect('dataset_detail', pk=dataset.pk)
    else:
        form = DatasetForm()
    return render(request, 'upload.html', {'form': form})

def dataset_detail(request, pk):
    dataset = Dataset.objects.get(pk=pk)
    df = pd.read_csv(dataset.csv_file.path)

    # Simple stats
    stats = df.describe().to_html()

    # Plotly example
    if not df.empty:
        fig = px.histogram(df, x=df.columns[0])
        graph = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
    else:
        graph = None

    return render(request, 'dataset_detail.html', {'dataset': dataset, 'stats': stats, 'graph': graph})
```

---

## **Step 6: Create Templates**

1. `analytics/templates/upload.html`:

```html
{% extends 'base.html' %}
{% block content %}
<div class="container mt-4">
    <h2>Upload Dataset</h2>
    <form method="post" enctype="multipart/form-data">
        {% csrf_token %}
        {{ form.as_p }}
        <button type="submit" class="btn btn-primary">Upload</button>
    </form>
</div>
{% endblock %}
```

2. `analytics/templates/dataset_detail.html`:

```html
{% extends 'base.html' %}
{% block content %}
<div class="container mt-4">
    <h2>{{ dataset.name }}</h2>
    <h4>Statistics</h4>
    {{ stats|safe }}

    <h4>Visualization</h4>
    <div id="graph"></div>
</div>
{% block extra_js %}
<script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
<script>
    var graphData = {{ graph|safe }};
    Plotly.newPlot('graph', graphData.data, graphData.layout);
</script>
{% endblock %}
{% endblock %}
```

---

## **Step 7: Configure URLs**

`dashboard_project/urls.py`:

```python
from django.contrib import admin
from django.urls import path
from analytics import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.upload_dataset, name='upload_dataset'),
    path('dataset/<int:pk>/', views.dataset_detail, name='dataset_detail'),
]
```

---

## **Step 8: Test the Application**

1. Run the server:

```bash
python manage.py runserver
```

2. Navigate to `http://127.0.0.1:8000/` and upload a CSV.
3. Check the stats and histogram visualization on the detail page.

---

## **Step 9: Enhance with AdminLTE Components**

* **Sidebar menu:** Add links to datasets, charts, reports.
* **Cards:** Use AdminLTE cards for dataset summaries and metrics.
* **Charts:** Integrate Plotly/Matplotlib graphs in cards.
* **Responsive layout:** AdminLTE grids (`col-md-6`, `col-lg-4`) for dashboard layout.

**Example text-based dashboard layout:**

```
+----------------------+----------------------+
| Dataset 1 Summary    | Dataset 2 Summary    |
| Card with stats      | Card with stats      |
+----------------------+----------------------+
| Graph 1 (Histogram)  | Graph 2 (Scatter)   |
+----------------------+----------------------+
```

---

## **Step 10: Next Steps / Enhancements**

1. **Filtering**: Add dropdown filters for columns or time range.
2. **Multi-file support**: Store multiple datasets and show list.
3. **Advanced analytics**: Correlation matrix, trendlines, or ML predictions.
4. **Deployment**:

   * Use `whitenoise` for static files.
   * Deploy to Render or Railway for free-tier hosting.
5. **Authentication & Roles**: Use Django `auth` for user-specific dashboards.
6. **Audit logs**: Track dataset uploads and downloads.

---

✅ By following these steps, readers can **build a complete Django + AdminLTE data science dashboard** that supports CSV uploads, descriptive stats, and interactive visualizations.

---


Do you want me to generate that full project structure next?
