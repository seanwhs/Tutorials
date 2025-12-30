# 📝 Part 4 — Full-Stack DRF + React Deployment & Scaling

## 1️⃣ Containerize Backend & Frontend

### Create `Dockerfile` for Django Backend

```dockerfile
# Base image
FROM python:3.12-slim

# Set work directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy project files
COPY . .

# Expose port for Django
EXPOSE 8000

# Run ASGI server for Channels
CMD ["daphne", "-b", "0.0.0.0", "-p", "8000", "myproject.asgi:application"]
```

### Create `Dockerfile` for React Frontend

```dockerfile
# Build stage
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## 2️⃣ Docker-Compose Setup

`docker-compose.yml` for local dev or cloud deployment:

```yaml
version: "3.9"

services:
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypass
      POSTGRES_DB: mydb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    ports:
      - "6379:6379"

  backend:
    build:
      context: ./backend
    command: daphne -b 0.0.0.0 -p 8000 myproject.asgi:application
    volumes:
      - ./backend:/app
    ports:
      - "8000:8000"
    depends_on:
      - db
      - redis
    environment:
      - DATABASE_URL=postgres://myuser:mypass@db:5432/mydb
      - REDIS_URL=redis://redis:6379/0

  celery:
    build:
      context: ./backend
    command: celery -A myproject worker -l info
    depends_on:
      - redis
      - db

  frontend:
    build:
      context: ./frontend
    ports:
      - "3000:80"
    depends_on:
      - backend

volumes:
  postgres_data:
```

---

## 3️⃣ Environment Configuration

* Use **`.env`** file for sensitive values (`SECRET_KEY`, DB passwords, API keys).
* Backend reads environment variables for **database and Redis connections**.

Example `.env`:

```
SECRET_KEY=supersecretkey
DEBUG=False
DATABASE_URL=postgres://myuser:mypass@db:5432/mydb
REDIS_URL=redis://redis:6379/0
```

---

## 4️⃣ Cloud Deployment Options

1. **Docker Compose on VPS**

   * Deploy backend, frontend, Redis, and Postgres on a single VPS instance.
   * Use `docker-compose up -d` to run services in detached mode.

2. **Kubernetes (Optional for Scaling)**

   * Deploy backend, frontend, Redis, and Postgres as separate pods.
   * Use **Horizontal Pod Autoscaler (HPA)** for backend and Celery workers.

3. **Managed Cloud Services**

   * Postgres → AWS RDS / GCP Cloud SQL
   * Redis → AWS Elasticache / GCP Memorystore
   * Backend → AWS ECS / GCP Cloud Run / Heroku
   * Frontend → Vercel / Netlify / S3 + CloudFront

---

## 5️⃣ Configure Nginx Reverse Proxy (Optional)

* Reverse proxy backend and frontend under the same domain:

```nginx
server {
    listen 80;

    location /api/ {
        proxy_pass http://backend:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    location / {
        proxy_pass http://frontend:80/;
    }
}
```

---

## 6️⃣ Scaling Real-Time Features

* **WebSocket Channels** → Redis channel layer allows multiple backend instances to push live updates.
* **Celery Workers** → Increase the number of workers to process tasks concurrently.
* **Frontend** → Static assets served via CDN for performance.

---

## 7️⃣ Testing & CI/CD

* Use **GitHub Actions / GitLab CI** to:

  * Run backend tests
  * Build Docker images
  * Deploy to cloud
* Test WebSocket updates across multiple tabs/clients after deployment.

---

## ✅ Key Takeaways

1. **Dockerization** ensures consistent dev/prod environments.
2. **Docker Compose** simplifies multi-service orchestration.
3. **Cloud deployment options** enable scaling backend, Celery, and frontend independently.
4. **WebSocket scaling** is trivial with Channels + Redis.
5. **CI/CD integration** ensures reproducible deployments for real-world apps.

---

