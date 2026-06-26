# Building TickerHub

## Part 20: Building the FastAPI Gateway & Authentication Layer — Creating Security Boundaries in a Distributed Trading System

> The fastest way to destroy a financial system is to trust the client.

Professional trading systems are designed around a fundamental principle:

```text
The UI is not trusted.
```

This surprises many developers.

After all, didn't we build the portfolio screen?

Didn't we build the order entry panel?

Didn't we build the risk dashboard?

Yes.

But professional systems assume that:

* browsers can be compromised,
* API requests can be forged,
* WebSocket messages can be replayed,
* sessions can be stolen,
* users can be malicious.

This is why professional systems place a:

```text
Security Boundary
```

between:

```text
Users

and

Business Logic
```

---

# The Beginner Architecture

Most tutorials build:

```text
Browser
    |
    V
Database
```

or:

```text
Browser
    |
    V
Backend
    |
    V
Database
```

This works.

Until:

* multiple users exist,
* permissions exist,
* audit requirements exist,
* regulators exist,
* attackers exist.

Then:

```text
Application
```

becomes:

```text
Distributed Security System
```

---

# Professional Architecture

```text
User
     |
     V

Authentication
     |
     V

API Gateway
     |
     V

Authorization
     |
     V

Business Services
     |
     V

Infrastructure
```

The important part is:

```text
Every request
crosses
a security boundary.
```

---

# Why Do We Need a Gateway?

Suppose a trader submits:

```json
{
    "symbol": "D05",
    "quantity": 1000,
    "price": 42
}
```

Questions immediately arise:

* Who submitted this?
* Is this user authenticated?
* Can they trade DBS?
* Do they have sufficient capital?
* Did they exceed risk limits?
* Should this action be audited?

The order itself is the easy part.

The hard part is:

```text
Trust
```

---

# Gateway Architecture

```text
Panel UI
      |
      V

FastAPI Gateway
      |
      +------ Authentication
      |
      +------ Authorization
      |
      +------ Audit
      |
      +------ Validation
      |
      +------ Rate Limiting
      |
      +------ Service Routing
```

---

# Project Structure

Create:

```text
api/

    main.py

    auth.py

    dependencies.py

    routes/

        market.py

        portfolio.py

        order.py

        risk.py
```

---

# Installing FastAPI

```bash
pip install fastapi
pip install uvicorn
pip install python-jose
pip install passlib
```

---

# Creating FastAPI

```python
from fastapi import FastAPI

app = FastAPI(
    title="TickerHub API"
)
```

---

# First Endpoint

```python
@app.get("/health")
async def health():

    return {
        "status": "ok"
    }
```

---

Result:

```json
{
    "status": "ok"
}
```

---

# Why Health Checks Matter

Professional systems constantly verify:

```text
Can this service still operate?
```

Examples:

```text
API
Database
Redis
Kafka
Workers
Market Feed
```

---

# Authentication

Authentication answers:

```text
Who are you?
```

---

# Authorization

Authorization answers:

```text
What may you do?
```

---

# Identity Model

Create:

```python
from dataclasses import dataclass
```

---

```python
@dataclass
class User:

    user_id: str

    username: str

    roles: list

    permissions: list
```

---

Example:

```python
User(

    user_id="123",

    username="trader",

    roles=[
        "trader"
    ],

    permissions=[
        "trade",
        "portfolio"
    ]
)
```

---

# Password Hashing

Never store:

```text
password
```

Store:

```text
password hash
```

---

Example:

```python
from passlib.context import (
    CryptContext
)
```

---

```python
pwd = CryptContext(

    schemes=["bcrypt"]
)
```

---

Hash:

```python
hashed = pwd.hash(
    "secret"
)
```

---

Verify:

```python
pwd.verify(

    "secret",

    hashed
)
```

---

# JWT Tokens

Professional APIs use:

```text
JSON Web Tokens
```

---

Example:

```json
{
    "sub":"user123",
    "role":"trader",
    "exp":123456
}
```

---

# Create Token

```python
from jose import jwt
```

---

```python
token = jwt.encode(

    payload,

    SECRET,

    algorithm="HS256"
)
```

---

# Verify Token

```python
payload = jwt.decode(

    token,

    SECRET,

    algorithms=["HS256"]
)
```

---

# Login Endpoint

```python
@app.post("/login")
async def login(
    username,
    password
):
```

---

Verify:

```python
user = authenticate(
    username,
    password
)
```

---

Return:

```python
return {

    "token":
        create_token(
            user
        )
}
```

---

# Example Response

```json
{
    "token":
    "eyJ..."
}
```

---

# Sending Token

Panel includes:

```http
Authorization:

Bearer eyJ...
```

---

# Dependency Injection

Create:

```python
from fastapi import Depends
```

---

Example:

```python
@app.get(
    "/portfolio"
)
async def portfolio(

    user=Depends(
        get_user
    )
):
```

---

Now:

```text
FastAPI automatically
loads the user.
```

---

# Permission Checks

Example:

```python
if "trade" not in (

    user.permissions
):
```

Raise:

```python
raise HTTPException(
    403
)
```

---

# Example Roles

```text
Admin

Trader

Analyst

Viewer
```

---

# Trader

Permissions:

```text
Trade
Portfolio
Risk
News
```

---

# Analyst

Permissions:

```text
Research
Portfolio
News
```

---

# Viewer

Permissions:

```text
Read Only
```

---

# Order Endpoint

Create:

```python
@app.post(
    "/orders"
)
async def create_order(
```

---

Input:

```python
order: OrderRequest
```

---

Validate:

```python
if order.quantity <= 0:

    raise Exception()
```

---

Publish:

```python
event_bus.publish(
    order
)
```

---

Return:

```python
{
    "status":
        "accepted"
}
```

---

# Why Publish?

Because:

```text
HTTP

≠

Business Logic
```

The gateway only accepts requests.

The system decides what happens.

---

# Event Flow

```text
Panel
     |
     V

FastAPI
     |
     V

Event Bus
     |
     V

Order Service
     |
     V

Risk Service
     |
     V

Portfolio Service
```

---

# API Validation

Professional systems reject:

```text
Negative quantities

Negative prices

Unknown symbols

Invalid accounts

Unauthorized trades
```

---

Example:

```python
from pydantic import (
    BaseModel
)
```

---

```python
class OrderRequest(

    BaseModel
):

    symbol: str

    quantity: int

    price: float
```

---

Validate:

```python
if quantity <= 0:
```

Raise:

```text
Validation Error
```

---

# Rate Limiting

Professional systems defend against:

```text
Bugs

Bots

Attackers
```

---

Example:

```text
100 requests
per minute
```

---

Store:

```text
Redis
```

---

Check:

```python
if count > limit:
```

Reject:

```text
429
Too Many Requests
```

---

# Audit Logging

Every action is recorded.

---

Example:

```python
audit = {

    "user":
        user.id,

    "action":
        "BUY",

    "symbol":
        "D05",

    "timestamp":
        now()
}
```

---

Save:

```text
PostgreSQL
```

---

Why?

Because regulators may ask:

> Who placed this trade six months ago?

---

# Request Tracing

Professional systems assign:

```text
Correlation IDs
```

---

Example:

```text
request_id

=

abc123
```

---

Every service logs:

```text
abc123
```

allowing reconstruction of the entire request flow.

---

# API Versioning

Professional APIs never expose:

```text
/api/orders
```

They expose:

```text
/api/v1/orders
```

---

Later:

```text
/api/v2/orders
```

---

# WebSocket Gateway

REST is insufficient.

Professional terminals require:

```text
Real-Time Streaming
```

---

Example:

```python
@app.websocket(
    "/stream"
)
```

---

Client connects:

```text
Panel
     |
     V
WebSocket
     |
     V
FastAPI
```

---

Server pushes:

```text
Prices

Orders

Risk

News

Alerts
```

without polling.

---

# Authentication Flow

```text
User
     |
     V

Login
     |
     V

JWT
     |
     V

Panel Session
     |
     V

API Gateway
     |
     V

Services
```

---

# Authorization Flow

```text
Request
     |
     V

Authentication
     |
     V

Role Check
     |
     V

Permission Check
     |
     V

Business Rule Check
     |
     V

Execution
```

---

# Why Enterprise Systems Feel Different

Because every action passes through:

```text
Security

Validation

Authorization

Auditing

Observability
```

before any business logic executes.

---

# The Real Gateway Architecture

```text
User
      |
      V

Authentication
      |
      V

Authorization
      |
      V

Validation
      |
      V

Audit
      |
      V

Rate Limiting
      |
      V

Event Bus
      |
      V

Business Services
```

---

# Architecture Lesson #20

Beginners think:

```text
Frontend
     |
     V
Backend
```

Professionals think:

```text
Trust Boundary
     |
     V
Security Boundary
     |
     V
Business Boundary
     |
     V
Infrastructure Boundary
```

The API is not an implementation detail.

It is the security perimeter of the entire system.

---

# Current Architecture

```text
Panel UI
      |
      V

FastAPI Gateway
      |
      +------ Authentication
      |
      +------ Authorization
      |
      +------ Audit
      |
      +------ Validation
      |
      +------ Event Bus
      |
      V

Services
      |
      +------ Market
      |
      +------ Portfolio
      |
      +------ Risk
      |
      +------ News
      |
      +------ Alert
      |
      +------ Workspace
```

TickerHub now contains:

✅ Trading UI

✅ Portfolio engine

✅ Risk engine

✅ News engine

✅ Alert engine

✅ Workspace engine

✅ Authentication

✅ Authorization

✅ FastAPI gateway

✅ Audit trail

✅ Security boundaries

At this point, TickerHub no longer resembles a Panel application.

It resembles:

```text
A Distributed Financial Platform
```

---

# In Part 21

We will build the **Kafka Event Backbone**, where you'll discover that enterprise systems are not:

```text
Applications that call functions
```

but rather:

```text
Distributed event processing systems
whose components may never directly talk to each other.
```
