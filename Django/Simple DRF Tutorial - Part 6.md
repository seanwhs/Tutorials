# 🎨 Part 6 — Full-Stack Architecture & Async Flow

```
🟦 USER (Browser / React App)
 ├─ 🔐 Login / Signup
 ├─ 📝 Create Task
 ├─ ✏️ Update Task
 ├─ ❌ Delete Task
 ├─ 🔍 Filter / Search Tasks
 └─ ⚡ View Live Updates
        │
        ▼
🟩 FRONTEND (React + Axios + WebSocket)
 ├─ 🔑 POST /api/token/ → Receive JWT
 ├─ 📋 GET /api/tasks/ → Fetch tasks
 ├─ ✅ POST /api/tasks/ → Create task
 ├─ ✏️ PUT /api/tasks/:id → Update task
 ├─ ❌ DELETE /api/tasks/:id → Delete task
 ├─ 🔍 Filter / Search via query params
 ├─ ⚡ Optional WebSocket subscription
 └─ 📊 Render dashboard (task list, completed/pending, live updates)
        │
        ▼
🟨 BACKEND API (Django REST Framework)
 ├─ 🔐 Validate JWT
 ├─ 🛠️ CRUD Generic Views
 ├─ 🔍 Apply Filters / Search
 ├─ 🔄 Serializers → JSON ↔ DB
 └─ ⚡ Optional WebSocket events via signals
        │
        ▼
🟫 STORAGE
 ├─ 🗄️ SQLite / MySQL / PostgreSQL → Persistent task storage
 └─ 🔄 Redis → Ephemeral live updates (if WebSocket enabled)
        │
        ▼
🟧 WEBSOCKET / CHANNELS
 ├─ 🔄 Listen to Redis pub/sub events
 └─ ⚡ Broadcast task updates to subscribed frontend clients
```

---

## 🌈 Legend

| Emoji          | Meaning                                      |
| -------------- | -------------------------------------------- |
| 🟦 USER        | Human actions (browser / React)              |
| 🟩 FRONTEND    | React components, Axios, WebSocket listeners |
| 🟨 BACKEND API | DRF Generic Views, JWT auth, filters         |
| 🟫 STORAGE     | Persistent DB + ephemeral Redis              |
| 🟧 WEBSOCKET   | Channels / PubSub for real-time updates      |
| 🔐             | Authentication / JWT                         |
| 📝             | Task creation                                |
| ✏️             | Task update                                  |
| ❌              | Task deletion                                |
| 🔍             | Filter / Search                              |
| 📋             | Fetch / render tasks                         |
| ⚡              | Real-time updates / WebSocket                |
| 📊             | Dashboard rendering                          |

---

## 🔹 Key Flow Highlights

1. **User actions → Frontend → Backend**

   * JWT token ensures secure requests.
2. **CRUD operations handled by DRF Generic Views**

   * Serializers handle DB ↔ JSON conversions.
3. **Filters & search**

   * Frontend queries backend API with parameters.
4. **Optional WebSocket / Live Updates**

   * Signal triggers → Redis pub/sub → WebSocket → React dashboard.
5. **Frontend dashboard is fully reactive**

   * Updates dynamically with filtered, sorted, or live task data.
6. **Decoupled, modular architecture**

   * Backend, frontend, storage, and WebSocket layers are independent → scalable & maintainable.
