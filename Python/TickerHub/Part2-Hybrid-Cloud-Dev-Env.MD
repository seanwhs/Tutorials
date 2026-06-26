# Building TickerHub

## Part 2: Building the Hybrid Cloud Development Environment

> Before building a distributed system, we must build the environment that will run it.

Most tutorials begin with:

```bash
pip install something
```

Professional systems begin with:

```text
Where will the system run?
How will services communicate?
How will developers work?
How will production differ from development?
```

For TickerHub, we will adopt a **Hybrid Cloud Development Model**.

This means:

```text
Laptop
    +
Cloud Infrastructure
```

rather than:

```text
Everything on laptop
```

---

# Why Not Run Everything Locally?

A typical development environment for a modern financial terminal might require:

| Service    | Memory |
| ---------- | ------ |
| PostgreSQL | 500 MB |
| Redis      | 300 MB |
| Kafka      | 2 GB   |
| Zookeeper  | 1 GB   |
| Prometheus | 500 MB |
| Grafana    | 500 MB |
| FastAPI    | 200 MB |
| Panel      | 500 MB |
| Workers    | 1–2 GB |

Total:

```text
6–10 GB RAM
```

before opening your browser.

Your laptop quickly becomes:

```text
Laptop
   ↓
Fan Noise
   ↓
Thermal Throttling
   ↓
Sadness
```

Professional teams increasingly use:

* managed databases,
* managed caches,
* managed messaging systems,
* managed observability platforms,

even during development.

---

# The TickerHub Hybrid Architecture

Our development architecture will look like this:

```text
                 YOUR LAPTOP

         ┌──────────────────────┐
         │                      │
         │      VS Code         │
         │                      │
         │      Python          │
         │                      │
         │      Panel           │
         │                      │
         │     FastAPI          │
         │                      │
         └──────────┬───────────┘
                    │
                    │ Internet
                    │
    ┌───────────────┼───────────────────┐
    │               │                   │
    ▼               ▼                   ▼

 Supabase      Upstash Redis       Kafka Cloud

 PostgreSQL        Cache           Event Bus
```

This provides several advantages.

---

# Advantage 1: Production Parity

The environment becomes:

```text
Development == Production
```

instead of:

```text
Laptop
     !=
Production
```

This eliminates the classic:

> "But it worked on my machine."

problem.

---

# Advantage 2: Lower Resource Usage

Instead of:

```text
16GB laptop
        ↓
80% memory usage
```

you get:

```text
16GB laptop
        ↓
10% memory usage
```

---

# Advantage 3: Real Network Conditions

Professional systems do not run with:

```text
localhost latency = 0ms
```

They run with:

```text
database latency
cache latency
network latency
broker latency
```

Building against remote infrastructure forces us to design:

* retries,
* async execution,
* timeout handling,
* graceful degradation.

These are critical engineering skills.

---

# Our Cloud Stack

We'll use three free-tier services.

| Service    | Provider                  | Purpose        |
| ---------- | ------------------------- | -------------- |
| PostgreSQL | Supabase                  | persistence    |
| Redis      | Upstash                   | cache          |
| Kafka      | Upstash Kafka / CloudAMQP | event backbone |

---

# Step 1 — Create a Supabase Project

Create an account at:

```text
supabase.com
```

Then create:

```text
tickerhub-dev
```

project.

After creation you'll receive:

```text
Project URL
Database Password
Connection String
```

Example:

```text
postgresql://postgres:password@host.supabase.co:5432/postgres
```

---

# Step 2 — Create an Upstash Redis Database

Create:

```text
tickerhub-cache
```

You'll receive:

```text
UPSTASH_REDIS_HOST
UPSTASH_REDIS_PORT
UPSTASH_REDIS_PASSWORD
```

Example:

```text
rediss://default:password@host.upstash.io:6379
```

---

# Step 3 — Create a Kafka Cluster

For tutorials, one of:

```text
Upstash Kafka
CloudAMQP
Confluent Cloud
Redpanda Cloud
```

works perfectly.

You will receive:

```text
bootstrap.servers
username
password
topic information
```

---

# Creating the Repository

Let's create our project.

```bash
mkdir tickerhub
cd tickerhub
```

---

Create:

```bash
mkdir app
mkdir api
mkdir components
mkdir state
mkdir domain
mkdir services
mkdir repositories
mkdir events
mkdir workers
mkdir infrastructure
mkdir deployment
mkdir tests
```

---

Result:

```text
tickerhub/

├── app/
├── api/
├── components/
├── state/
├── domain/
├── services/
├── repositories/
├── events/
├── workers/
├── infrastructure/
├── deployment/
└── tests/
```

---

# Python Environment

Create the environment.

```bash
python -m venv .venv
```

Activate:

### Windows

```bash
.venv\Scripts\activate
```

### Linux/Mac

```bash
source .venv/bin/activate
```

---

Install dependencies.

```bash
pip install \
panel \
param \
fastapi \
uvicorn \
sqlalchemy \
asyncpg \
redis \
aiokafka \
httpx \
python-dotenv \
pydantic-settings
```

---

Create:

```text
requirements.txt
```

```bash
pip freeze > requirements.txt
```

---

# Creating the .env File

The most important file in TickerHub is not:

```text
app.py
```

It is:

```text
.env
```

Create:

```bash
touch .env
```

---

Example:

```env
APP_ENV=development

SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_DB=postgresql://user:password@host/db

REDIS_URL=rediss://default:password@host.upstash.io:6379

KAFKA_BOOTSTRAP=xxxxx.kafka.upstash.io:9092
KAFKA_USER=username
KAFKA_PASSWORD=password

JWT_SECRET=super-secret

LOG_LEVEL=INFO
```

---

# Why .env Is So Important

Our entire architecture obeys one rule:

> Environment determines infrastructure.

Meaning:

Development:

```env
REDIS_URL=upstash-dev
```

Production:

```env
REDIS_URL=upstash-prod
```

No source code changes.

Only configuration changes.

This principle is one of the foundations of modern cloud engineering.

---

# Creating the Configuration Layer

Create:

```text
infrastructure/config.py
```

---

## config.py

```python
from pydantic_settings import (
    BaseSettings,
    SettingsConfigDict,
)


class Settings(BaseSettings):

    APP_ENV: str

    SUPABASE_URL: str

    SUPABASE_DB: str

    REDIS_URL: str

    KAFKA_BOOTSTRAP: str

    KAFKA_USER: str

    KAFKA_PASSWORD: str

    JWT_SECRET: str

    LOG_LEVEL: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=".env"
    )


settings = Settings()
```

---

Test it.

```python
from infrastructure.config import settings

print(settings.APP_ENV)
print(settings.REDIS_URL)
```

---

# Why Use a Configuration Object?

Many beginners write:

```python
import os

url = os.getenv(
    "REDIS_URL"
)
```

everywhere.

Professional systems centralize configuration:

```text
Environment
      ↓
Settings
      ↓
Application
```

Benefits:

* validation,
* autocomplete,
* typing,
* documentation,
* testing.

---

# Creating Infrastructure Adapters

Create:

```text
infrastructure/

    postgres.py
    redis.py
    kafka.py
```

---

# PostgreSQL Adapter

```python
from sqlalchemy.ext.asyncio import (
    create_async_engine,
)

from infrastructure.config import (
    settings,
)

engine = create_async_engine(

    settings.SUPABASE_DB,

    pool_size=10,

    max_overflow=20,

    pool_pre_ping=True,
)
```

---

# Redis Adapter

```python
import redis.asyncio as redis

from infrastructure.config import (
    settings,
)

cache = redis.from_url(

    settings.REDIS_URL,

    decode_responses=True,
)
```

---

# Kafka Adapter

```python
from aiokafka import (
    AIOKafkaProducer,
)

from infrastructure.config import (
    settings,
)

producer = AIOKafkaProducer(

    bootstrap_servers=
        settings.KAFKA_BOOTSTRAP,

    sasl_mechanism="PLAIN",

    security_protocol=
        "SASL_SSL",

    sasl_plain_username=
        settings.KAFKA_USER,

    sasl_plain_password=
        settings.KAFKA_PASSWORD,
)
```

---

# Why Everything Is Async

Because our infrastructure lives here:

```text
Singapore
      ↓
Internet
      ↓
US Datacenter
      ↓
Cloud Service
```

every operation involves latency.

Bad:

```python
price = database.fetch()
```

because the UI freezes.

Good:

```python
price = await database.fetch()
```

because other work continues.

This single design decision shapes the entire architecture.

---

# Designing for Failure

Cloud systems fail.

Professional systems expect failure.

Never write:

```python
value = await redis.get(
    "price"
)
```

Instead:

```python
try:

    value = await redis.get(
        "price"
    )

except Exception:

    value = None
```

---

Even better:

```text
Retry
    ↓
Fallback
    ↓
Cache
    ↓
Database
    ↓
Default Value
```

This concept is called:

# Graceful Degradation

---

# Verifying the Architecture

At the end of Part 2, your system should look like:

```text
                     Laptop

            Panel + FastAPI
                    |
                    |
          --------------------
          |        |         |
          |        |         |
          ▼        ▼         ▼

      Redis   PostgreSQL   Kafka

          (all remote)
```

No containers.

No local databases.

No local Kafka.

No laptop suffering.

---

# Architecture Lesson #2

Professional systems do not begin with:

```python
pn.widgets.DataFrame()
```

They begin with:

```text
Infrastructure
        ↓
Connectivity
        ↓
Configuration
        ↓
Resilience
        ↓
Application
```

Without infrastructure, there is no application.

---

# In Part 3

We will design the **TickerHub repository structure and engineering architecture**, including:

* modular monolith design,
* service boundaries,
* dependency inversion,
* package organization,
* domain ownership,
* enterprise project layout.
