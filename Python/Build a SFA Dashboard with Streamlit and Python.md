# 📘 Python & Streamlit for Sales Force Automation (SFA) 

## Build a Real-World Sales Force Automation Dashboard Using Python + Streamlit

**Audience:** Sales teams, managers, operations teams, analysts, and complete beginners to Python and Streamlit

**Outcome:** By the end of this tutorial, you will:

* Think **visually and interactively** about sales automation pipelines
* Build **interactive dashboards** for sales, leads, and document automation
* Integrate **Python-for-Excel** for CRM data ingestion and **Python-for-Word** for proposal/quote generation
* Include **alerts, role-based views, reconciliation, forecasting, daily call rosters, and production-ready checks**
* Deploy dashboards for internal use

This tutorial is **verbose, example-rich, hands-on, and enterprise-ready**, including:

* Mental models
* Step-by-step code examples
* Hands-on exercises with solutions
* ASCII/slide-ready architecture diagrams
* ✅ Production-readiness checkpoints

---

# 🧭 Part 0: Big Picture — From CRM Data to Streamlit Sales Dashboard

### Mental Model

Streamlit dashboards serve as the **interactive front-end** for Python automation pipelines.

```
CRM / Excel Data --> Validation --> Processing --> Reporting / Call Rosters
        |               |               |                       |
        v               v               v                       v
  Reconciliation    Alerts       KPIs & Metrics       Interactive Dashboards
                                                  Role-based Views
```

### Interactive Walkthrough Exercise

* Draw your own pipeline for your sales team on paper or a whiteboard.
* Identify which steps can be automated and which need alerts.

### Checkpoints

* [ ] Sales workflow mapped
* [ ] KPIs identified
* [ ] Alerts and validation points defined

---

# 🐍 Part 1: Streamlit Basics for SFA

### Installation

```bash
pip install streamlit pandas matplotlib openpyxl python-docx
```

### Your First Dashboard

```python
import streamlit as st
st.title("Sales Force Automation Dashboard")
st.write("Track your leads, opportunities, and tasks interactively.")
```

Run:

```bash
streamlit run sfa_dashboard.py
```

### ASCII Architecture Diagram

```
Streamlit App
   |
   v
User Interaction --> Filters, Selectors, Inputs
   |
   v
Dashboard Rendering --> Tables, Charts, Alerts
```

### Interactive Exercise

* Add a sidebar with filters and test dynamic updates.

### Checkpoints

* [ ] App runs successfully
* [ ] Sidebar filter implemented
* [ ] Dashboard updates dynamically

---

# 📊 Part 2: Loading and Displaying CRM Data

### Load Data

```python
import pandas as pd

df_leads = pd.read_excel("leads.xlsx")
st.dataframe(df_leads)
```

### ASCII Diagram

```
CRM Excel File --> Pandas DataFrame --> Streamlit Table
```

### Interactive Exercise

* Load your CRM data
* Display filtered views based on rep or region

### Checkpoints

* [ ] Data loads correctly
* [ ] Filtering works
* [ ] Large datasets handled

---

# 📈 Part 3: KPIs and Metrics

```python
total_leads = len(df_leads)
converted_leads = df_leads['Status'].value_counts().get('Won', 0)
conversion_rate = converted_leads / total_leads * 100
st.metric("Lead Conversion Rate", f"{conversion_rate:.2f}%")
```

### ASCII Diagram

```
DataFrame --> KPI Calculations --> Metric Cards in Dashboard
```

### Interactive Exercise

* Add metrics for revenue per rep and average deal size.
* Validate calculations by manually checking a subset.

### Checkpoints

* [ ] Metrics calculated correctly
* [ ] Dashboard updates dynamically

---

# 📊 Part 4: Interactive Filtering

```python
selected_rep = st.selectbox("Select Sales Rep", df_leads['Rep'].unique())
filtered_df = df_leads[df_leads['Rep'] == selected_rep]
st.dataframe(filtered_df)
```

### ASCII Diagram

```
User Selection --> Filtered DataFrame --> Updated Table & Charts
```

### Interactive Exercise

* Add filters for region and product line
* Ensure charts and tables update automatically

### Checkpoints

* [ ] Filters interactive
* [ ] Charts and tables update correctly

---

# 🔔 Part 5: Alerts & Notifications

```python
if filtered_df['Status'].value_counts().get('Pending', 0) > 10:
    st.warning("High number of pending leads!")
```

### ASCII Diagram

```
KPI / Threshold Check --> Alert Component in Dashboard
```

### Interactive Exercise

* Add threshold alerts for overdue tasks
* Integrate mock email/Slack notifications

### Checkpoints

* [ ] Alerts visible
* [ ] Notifications configured

---

# 📄 Part 6: Document Generation

```python
from docx import Document

for i, row in filtered_df.iterrows():
    doc = Document("proposal_template.docx")
    doc.paragraphs[0].text = f"Proposal for {row['Customer']}"
    doc.save(f"proposal_{row['Customer']}.docx")
```

### ASCII Diagram

```
Filtered DataFrame --> Template Filling --> Word Documents
```

### Interactive Exercise

* Generate proposal documents for filtered leads
* Embed dynamic tables for each lead

### Checkpoints

* [ ] Documents generated
* [ ] Placeholders replaced
* [ ] Alerts on missing templates

---

# 🔮 Part 7: Forecasting & Scenario Analysis

```python
forecasted_revenue = df_leads['ExpectedRevenue'].sum() * 1.1
st.metric("Forecasted Revenue", f"${forecasted_revenue:,.2f}")
```

### ASCII Diagram

```
Historical Data --> Forecast Calculation --> KPI Display
```

### Interactive Exercise

* Add best/worst/expected scenario projections
* Trigger alert if forecast below target

### Checkpoints

* [ ] Forecasts accurate
* [ ] Alerts trigger correctly

---

# 🗓️ Part 8: Daily/Weekly Sales Task Roster

```python
for day in ['Monday','Tuesday','Wednesday']:
    doc = Document("daily_roster_template.docx")
    for rep in df_leads['Rep'].unique():
        doc.add_paragraph(f"{rep} - Call list for {day}")
    doc.save(f"roster_{day}.docx")
```

### ASCII Diagram

```
Employee List + Schedule Logic --> Roster Docs --> Alerts for Conflicts
```

### Interactive Exercise

* Generate roster and detect double-bookings
* Notify reps of conflicts

### Checkpoints

* [ ] Rosters generated
* [ ] Conflict detection active
* [ ] Alerts sent

---

# 👥 Part 9: Role-Based Views

```python
role = st.radio("Select Role", ["Sales Rep", "Manager", "Executive"])
if role == "Manager":
    st.dataframe(df_leads[['Rep','Customer','ExpectedRevenue']])
elif role == "Executive":
    st.dataframe(df_leads.groupby('Region')['ExpectedRevenue'].sum())
```

### ASCII Diagram

```
User Role --> Filtered View --> Table / Chart Rendering
```

### Interactive Exercise

* Implement role-based filtering and masking
* Test views for each role

### Checkpoints

* [ ] Role-based filtering works
* [ ] Sensitive data hidden

---

# 🏗️ Part 10: Production-Ready Features

### Validation & Reconciliation

```python
if df_leads['ExpectedRevenue'].sum() != df_sales_records['Revenue'].sum():
    st.error("Reconciliation mismatch detected!")
```

### ASCII Diagram

```
Data Validation --> Reconciliation Check --> Alert / Error Display
```

### Interactive Exercise

* Implement reconciliation between CRM and reported revenue
* Schedule dashboard refresh and alerts

### Checkpoints

* [ ] Validation rules active
* [ ] Alerts working
* [ ] CLI supports scheduled runs

---

# 🎉 Final Mindset Shift

* Dashboards are **interactive, actionable, and auditable**
* Alerts prevent missed opportunities
* Daily/weekly task rosters make sales activity predictable
* Integration with Python-for-Excel and Python-for-Word ensures end-to-end automation

Congratulations! You are now capable of **building a full Sales Force Automation dashboard** that is **interactive, production-ready, and integrated** with document generation and data pipelines.
