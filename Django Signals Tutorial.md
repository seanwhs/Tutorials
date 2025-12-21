# 📘 Production-Grade Django Signals Handbook

## Build a Complete Django Application with Safe, Testable Signals

**Edition:** 1.0
**Audience:** Engineers, Bootcamp Learners, Trainers
**Level:** Intermediate → Professional

**Tech Stack:**

* Python 3.11+
* Django 4.x / 5.x
* Django ORM
* Django REST Framework (API)
* Pytest / Django TestCase
* Celery (async side effects)
* PostgreSQL (production-ready)

---

## 🎯 Learning Outcomes

By the end of this guide, readers will:

✅ Understand **what Django signals really are (and are not)**
✅ Know **when signals are appropriate vs harmful**
✅ Build a **complete Django application using signals correctly**
✅ Structure signals for **maintainability and testability**
✅ Handle **transactions, async execution, and failures safely**
✅ Write **production-grade tests for signal-driven behavior**

---

# 🧭 Architecture Overview

---

## Where Signals Fit (Big Picture)

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
| (Side Effects Only)  |
+----------+-----------+
           |
           v
+----------------------+
| External Systems     |
| Email / Cache / MQ   |
+----------------------+
```

> **Signals do not run the business.**
> They **react** to it.

---

## Core Design Rules (Non-Negotiable)

* **Signals must be optional**
* **Signals must be idempotent**
* **Signals must never control correctness**
* **Signals must delegate to services**
* **Signals must be testable in isolation**

---

# 🏗️ The Application We Will Build

---

## Example Application: Order Management System

### Features

✔ Create orders via API
✔ Persist orders in DB
✔ Automatically:

* Write audit logs
* Send notifications
* Trigger async workflows

✔ All side effects implemented via **signals**

---

## High-Level Flow

```
POST /api/orders
        |
        v
Order Created (DB)
        |
        v
post_save signal fires
        |
        +--> Audit Log
        |
        +--> Notification
        |
        +--> Async Processing
```

---

# 📁 Project Structure (Final State)

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

# ⚙️ Part 1: Project Setup

---

## 1️⃣ Create Django Project

```bash
django-admin startproject order_system
cd order_system
python manage.py startapp orders
python manage.py startapp audit
```

---

## 2️⃣ Register Apps

### `settings.py`

```python
INSTALLED_APPS = [
    ...
    "orders.apps.OrdersConfig",
    "audit",
    "rest_framework",
]
```

---

# 🧠 Part 2: Domain Modeling (No Signals Yet)

---

## `orders/models.py`

```python
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

---

## Why This Matters

```
Domain Model
     |
     v
Signals will react to THIS
```

> Signals should **never compensate for poor domain design**.

---

# 🌐 Part 3: API Layer (Triggering Signals Naturally)

---

## `orders/serializers.py`

```python
from rest_framework import serializers
from .models import Order

class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = "__all__"
```

---

## `orders/views.py`

```python
from rest_framework.viewsets import ModelViewSet
from .models import Order
from .serializers import OrderSerializer

class OrderViewSet(ModelViewSet):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
```

---

## URL Wiring

```
Client
  |
  v
DRF ViewSet
  |
  v
Order.objects.create()
```

Signals will hook **after** this point.

---

# ⚡ Part 4: Signal Registration (Critical)

---

## `orders/apps.py`

```python
from django.apps import AppConfig

class OrdersConfig(AppConfig):
    name = "orders"

    def ready(self):
        from . import signals  # noqa
```

> If this step is skipped → **signals never fire**

---

## `orders/signals.py`

```python
from .receivers import audit, notifications, async_tasks
```

This ensures **all receivers are imported**.

---

# 🧠 Part 5: Writing Signals Correctly

---

## Rule: Signals Call Services, Not Logic

---

### `orders/receivers/audit.py`

```python
from django.db.models.signals import post_save
from django.dispatch import receiver
from orders.models import Order
from audit.services import write_audit_log

@receiver(post_save, sender=Order)
def order_audit_log(sender, instance, created, **kwargs):
    if not created:
        return

    write_audit_log(
        action="ORDER_CREATED",
        object_id=instance.id,
        metadata={"total": str(instance.total)}
    )
```

---

### `audit/services.py`

```python
from .models import AuditLog

def write_audit_log(action: str, object_id: int, metadata: dict):
    AuditLog.objects.create(
        action=action,
        object_id=object_id,
        metadata=metadata
    )
```

---

## Flow Diagram

```
Order Saved
    |
    v
post_save signal
    |
    v
Audit Service
    |
    v
AuditLog DB
```

---

# 🧵 Part 6: Transactions & `on_commit`

---

## The Problem

```
BEGIN TRANSACTION
  Order.objects.create()
  post_save fires ❌
ROLLBACK
```

Audit log written for **non-existent order**.

---

## The Fix (MANDATORY in Production)

### `orders/receivers/audit.py`

```python
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

---

## Correct Execution Flow

```
Transaction Commit
        |
        v
Signal Side Effects Run
```

---

# 🔔 Part 7: Notifications via Signals

---

### `orders/receivers/notifications.py`

```python
from django.db.models.signals import post_save
from django.dispatch import receiver
from orders.models import Order

@receiver(post_save, sender=Order)
def notify_order_created(sender, instance, created, **kwargs):
    if created:
        print(f"Notify: Order {instance.id} created")
```

---

## Diagram

```
Order Created
    |
    +--> Audit
    |
    +--> Notification
```

Signals **fan out cleanly**.

---

# ⏳ Part 8: Async Signals (Celery)

---

## Why Async?

❌ Email in request thread
❌ Slow external APIs
❌ Long-running tasks

---

### `orders/receivers/async_tasks.py`

```python
from django.db.models.signals import post_save
from django.dispatch import receiver
from orders.models import Order
from orders.tasks import process_order_async

@receiver(post_save, sender=Order)
def trigger_async_processing(sender, instance, created, **kwargs):
    if created:
        process_order_async.delay(instance.id)
```

---

## Execution Model

```
HTTP Request
    |
    v
Order Created
    |
    v
Signal → Celery Task
    |
    v
Worker Executes Later
```

---

# 🧪 Part 9: Testing Signals Properly

---

## `orders/tests/test_signals.py`

```python
import pytest
from orders.models import Order
from audit.models import AuditLog

@pytest.mark.django_db
def test_audit_log_created_on_order_create():
    Order.objects.create(total=100, status="NEW")
    assert AuditLog.objects.count() == 1
```

---

## Testing Strategy

| Layer         | Tested | Why                  |
| ------------- | ------ | -------------------- |
| Domain Models | ✅      | Core correctness     |
| Signals       | ✅      | Side effects         |
| Services      | ✅      | Business integration |
| Views         | ⚠️     | Covered indirectly   |

---

# 🚫 Part 10: Anti-Patterns (Avoid at All Costs)

---

❌ Signals modifying the same model
❌ Signals creating other domain objects
❌ Signals with complex branching
❌ Signals without tests
❌ Signals without `on_commit`

---

# 🚀 Part 11: Deployment Considerations

---

## Production Checklist

✔ Signals imported via `AppConfig.ready()`
✔ Idempotent handlers
✔ Async for slow work
✔ Observability (logging / metrics)
✔ Feature-flagged if risky

---

# 🏛 Part 12: Enterprise Extensions

---

Add progressively:

🔐 Multi-tenant audit logs
📊 Signal execution metrics
🧪 Contract testing
🧩 Event-driven architecture (signals → events)
📦 Replace signals with domain events

---

# 🎓 Final Mental Model

```
Business Logic
     |
     v
Persist State
     |
     v
Signals (Optional Reactions)
     |
     v
Side Effects
```

> **If signals disappeared tomorrow, your app must still work.**

---

