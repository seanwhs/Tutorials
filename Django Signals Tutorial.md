# 📘 Production-Grade Django Signals Handbook — Enhanced Edition

**Build Maintainable, Safe, Testable Django Signals in Production**

**Edition:** 1.1
**Audience:** Intermediate → Professional
**Tech Stack:** Python 3.11+, Django 4.x / 5.x, DRF, Celery, PostgreSQL, Pytest

---

## 🎯 Learning Outcomes

By the end of this guide, you will be able to:

✅ Understand **what Django signals are (and are not)**
✅ Identify **good vs bad use cases**
✅ Implement **testable, production-ready signals**
✅ Handle **transactions, async execution, and failures safely**
✅ Build signals with **observability, idempotency, and maintainability**

---

# 🧭 Architecture Overview — Where Signals Fit

```
Client (Browser / API Consumer)
          |
          v
+----------------------+
| Django Views / DRF   |
| (Controllers)        |
+----------+-----------+
           |
           v
+----------------------+
| Domain Layer         |
| Models + Services    |
+----------+-----------+
           |
           v
+----------------------+
| Django Signals       |
| (Optional Side Effects) |
+----------+-----------+
           |
           v
+----------------------+
| External Systems     |
| Email / Cache / MQ   |
+----------------------+
```

> Signals **react** to business events. They do **not** enforce core domain rules.

---

# ⚙️ Core Design Principles

1. **Signals are optional** – The system works if they are removed.
2. **Signals are idempotent** – Multiple executions should have no side effects.
3. **Signals do not control correctness** – Business logic lives in models/services.
4. **Signals delegate to services** – Keep handlers minimal.
5. **Signals must be testable** – Cover in isolation with unit tests.
6. **Always use `transaction.on_commit`** – Avoid running side effects on rolled-back transactions.

---

# 🏗️ Example Application: Order Management System

**Use Case:** Process orders, log audits, notify stakeholders, trigger async workflows.

**High-Level Flow:**

```
POST /api/orders
        |
        v
Order Created (DB)
        |
        v
post_save signal fires
        |
        +--> Audit Log Service
        |
        +--> Notification Service
        |
        +--> Async Processing via Celery
```

---

# 📁 Project Structure (Final)

```
order_system/
│
├── manage.py
├── pyproject.toml
├── config/
│   ├── settings.py
│   ├── urls.py
│   └── celery.py
│
├── orders/
│   ├── apps.py
│   ├── models.py
│   ├── serializers.py
│   ├── views.py
│   ├── services.py
│   ├── signals.py
│   ├── receivers/
│   │   ├── __init__.py
│   │   ├── audit.py
│   │   ├── notifications.py
│   │   └── async_tasks.py
│   └── tests/
│       ├── test_models.py
│       ├── test_signals.py
│       └── test_api.py
│
└── audit/
    ├── models.py
    └── services.py
```

---

# 🏗️ Part 1: Project Setup

```bash
django-admin startproject order_system
cd order_system
python manage.py startapp orders
python manage.py startapp audit
```

**Register apps in `settings.py`:**

```python
INSTALLED_APPS = [
    ...,
    "orders.apps.OrdersConfig",
    "audit",
    "rest_framework",
]
```

---

# 🧠 Part 2: Domain Modeling (No Signals Yet)

```python
# orders/models.py
from django.db import models

class Order(models.Model):
    STATUS_CHOICES = [
        ("NEW", "New"),
        ("PAID", "Paid"),
        ("SHIPPED", "Shipped"),
    ]
    total = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)
```

**ASCII Diagram: Domain Model**

```
Order
├── id
├── total
├── status
└── created_at
```

> Signals will react to **these models**. Poor domain design cannot be fixed by signals.

---

# 🌐 Part 3: API Layer — Triggering Signals Naturally

**Serializer:**

```python
# orders/serializers.py
from rest_framework import serializers
from .models import Order

class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = "__all__"
```

**ViewSet:**

```python
# orders/views.py
from rest_framework.viewsets import ModelViewSet
from .models import Order
from .serializers import OrderSerializer

class OrderViewSet(ModelViewSet):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
```

**Flow Diagram:**

```
Client → DRF ViewSet → Order.objects.create()
                           |
                           v
                     post_save signals
```

---

# ⚡ Part 4: Signal Registration (Critical)

```python
# orders/apps.py
from django.apps import AppConfig

class OrdersConfig(AppConfig):
    name = "orders"

    def ready(self):
        from . import signals  # noqa
```

> If this is skipped → **signals never fire**.

```python
# orders/signals.py
from .receivers import audit, notifications, async_tasks
```

> Import all receivers to register signal handlers.

---

# 🧵 Part 5: Writing Signals Correctly

**Rule:** Signals call **services**, not business logic.

**Audit Example:**

```python
# orders/receivers/audit.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from orders.models import Order
from audit.services import write_audit_log
from django.db import transaction

@receiver(post_save, sender=Order)
def order_audit_log(sender, instance, created, **kwargs):
    if not created:
        return

    transaction.on_commit(
        lambda: write_audit_log(
            action="ORDER_CREATED",
            object_id=instance.id,
            metadata={"total": str(instance.total)}
        )
    )
```

**Flow Diagram:**

```
Order Saved → Transaction Commit → Signal → Audit Service → AuditLog DB
```

---

# 🔔 Notifications via Signals

```python
# orders/receivers/notifications.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from orders.models import Order

@receiver(post_save, sender=Order)
def notify_order_created(sender, instance, created, **kwargs):
    if created:
        print(f"Notify: Order {instance.id} created")
```

**Flow Diagram: Fan-out of Signals**

```
Order Created
    |
    +--> Audit Service
    |
    +--> Notification Service
    |
    +--> Async Task
```

---

# ⏳ Async Signals (Celery)

```python
# orders/receivers/async_tasks.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from orders.models import Order
from orders.tasks import process_order_async

@receiver(post_save, sender=Order)
def trigger_async_processing(sender, instance, created, **kwargs):
    if created:
        process_order_async.delay(instance.id)
```

**Execution Flow:**

```
HTTP Request → Order Created → Signal → Celery Worker → Async Processing
```

---

# 🧪 Testing Signals

```python
# orders/tests/test_signals.py
import pytest
from orders.models import Order
from audit.models import AuditLog

@pytest.mark.django_db
def test_audit_log_created_on_order_create():
    Order.objects.create(total=100, status="NEW")
    assert AuditLog.objects.count() == 1
```

**Testing Strategy Diagram:**

```
Domain Models ✔ → Signals ✔ → Services ✔ → Views (indirectly tested)
```

---

# 🚫 Anti-Patterns

❌ Signals modifying the same model
❌ Signals creating domain objects
❌ Signals with complex branching
❌ Signals without `on_commit`
❌ Signals without unit tests

---

# 🚀 Deployment Considerations

* Always register signals in `AppConfig.ready()`
* Ensure idempotency
* Use async for long-running tasks
* Enable logging & metrics for observability
* Feature-flag risky signals if needed

---

# 🏛 Enterprise Extensions

* Multi-tenant audit logs
* Signal execution metrics
* Contract testing
* Event-driven architecture (signals → domain events)
* Gradual replacement of signals with explicit events

---

# 🎓 Mental Model

```
Business Logic → Persist State → Signals (Optional) → Side Effects
```

> **Signals are reactors, not controllers. Remove them and the system still works.**

---

Do you want me to produce that next?
