# 📝 Part 5 — Advanced Features: Permissions, Audit Logging, & Notifications

This part extends the **Task API** with enterprise-level features for security, compliance, and user experience.

---

## 1️⃣ User Permissions & Roles

### Define User Roles

* **Admin:** Can manage all tasks and users.
* **User:** Can only manage their own tasks.

Add a `owner` field to `Task` in `api/models.py`:

```python
from django.contrib.auth.models import User

class Task(models.Model):
    title = models.CharField(max_length=200)
    completed = models.BooleanField(default=False)
    owner = models.ForeignKey(User, on_delete=models.CASCADE)

    def __str__(self):
        return self.title
```

---

### Update Serializer

In `api/serializers.py`:

```python
class TaskSerializer(serializers.ModelSerializer):
    owner = serializers.ReadOnlyField(source='owner.username')

    class Meta:
        model = Task
        fields = ['id', 'title', 'completed', 'owner']
```

---

### Permissions

Create `api/permissions.py`:

```python
from rest_framework import permissions

class IsOwnerOrAdmin(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        # Admins can access all
        if request.user.is_staff:
            return True
        # Users can only access their own tasks
        return obj.owner == request.user
```

---

### Apply Permissions in Views

```python
from .permissions import IsOwnerOrAdmin

class TaskRetrieveUpdateDestroyAPIView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    permission_classes = [IsOwnerOrAdmin]

class TaskListCreateAPIView(generics.ListCreateAPIView):
    serializer_class = TaskSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Regular users see only their tasks
        user = self.request.user
        if user.is_staff:
            return Task.objects.all()
        return Task.objects.filter(owner=user)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)
```

---

## 2️⃣ Audit Logging

Keep a record of **task creation, updates, and deletions**.

### Model for Audit Log

```python
class TaskAuditLog(models.Model):
    task = models.ForeignKey(Task, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    action = models.CharField(max_length=50)
    timestamp = models.DateTimeField(auto_now_add=True)
```

### Signals to Track Changes

```python
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver

@receiver(post_save, sender=Task)
def log_task_save(sender, instance, created, **kwargs):
    action = "created" if created else "updated"
    TaskAuditLog.objects.create(task=instance, user=instance.owner, action=action)

@receiver(post_delete, sender=Task)
def log_task_delete(sender, instance, **kwargs):
    TaskAuditLog.objects.create(task=instance, user=instance.owner, action="deleted")
```

* Now every task change is tracked for compliance and auditing.

---

## 3️⃣ Email Notifications

Send users notifications for **task assignment or updates**.

### Setup Email Backend (in `settings.py`)

```python
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = 'your-email@gmail.com'
EMAIL_HOST_PASSWORD = 'your-email-password'
```

### Trigger Emails in Signals

```python
from django.core.mail import send_mail

@receiver(post_save, sender=Task)
def notify_task_change(sender, instance, created, **kwargs):
    subject = f"Task {'Created' if created else 'Updated'}: {instance.title}"
    message = f"Task '{instance.title}' has been {'created' if created else 'updated'}."
    recipient = [instance.owner.email]
    send_mail(subject, message, 'no-reply@example.com', recipient)
```

---

## 4️⃣ Frontend Enhancements

* **Show Task Owner:** Display who owns each task.
* **Role-Based Access:** Hide buttons for non-admin users.
* **Notifications:** Display real-time task notifications via WebSocket.

Example update in **TaskDashboard.js**:

```javascript
<ul>
  {tasks.map((task) => (
    <li key={task.id}>
      {task.title} - {task.completed ? "✅" : "❌"} (Owner: {task.owner})
    </li>
  ))}
</ul>
```

---

## 5️⃣ WebSocket Notifications

Enhance `TaskConsumer` to send **owner-specific notifications**:

```python
async def connect(self):
    user = self.scope["user"]
    self.group_name = f"user_{user.id}"
    await self.channel_layer.group_add(self.group_name, self.channel_name)
    await self.accept()

async def task_update(self, event):
    await self.send(text_data=json.dumps(event["data"]))
```

* Signal broadcasts only to the task owner group.

---

## 6️⃣ Testing & Security

* Test role restrictions by logging in as multiple users.
* Verify **audit logs** are created for each task action.
* Ensure **email notifications** are delivered correctly.
* Confirm WebSocket notifications only reach authorized users.

---

## ✅ Key Takeaways

1. **Permissions & Roles:** Protects resources based on user roles and ownership.
2. **Audit Logging:** Enables traceability for compliance and debugging.
3. **Email Notifications:** Improves user engagement.
4. **WebSocket Notifications:** Keeps the dashboard in sync in real-time.
5. **Production Ready:** Combines security, observability, and interactivity for a robust enterprise-grade app.

---

