# Part I — Architectural Discipline: The 12-Factor App

The 12-Factor methodology is the "contract" between the developer and the platform. By adhering to these constraints, your application becomes **platform-agnostic**, allowing it to run seamlessly on Kubernetes, AWS Lambda, or a local developer machine.

## Core Principles for 2026

### 1. Single Codebase, Many Deployments

There is a 1-to-1 correlation between a Git repository and a service. You use **GitOps** principles to promote the same immutable build through different environments (Dev → Staging → Prod).

### 2. Explicit Dependency Isolation

Modern systems must never rely on the implicit existence of system-wide packages.

* **Tooling:** Use `npm shrinkwrap`, `go.sum`, or `Poetry` to lock versions.
* **Encapsulation:** Use multi-stage Docker builds to ensure the runtime image contains *only* what is necessary to run the app, reducing the attack surface.

### 3. Environment-Based Configuration

Configuration (everything that likely varies between deploys) is injected via **Environment Variables**.

* **Rule:** If you can’t open-source your codebase right now because it contains secrets or hardcoded IP addresses, you have violated this factor.

### 4. Attached Resources

Treat backing services—Databases, Message Brokers, and even **LLM Inference APIs**—as "attached resources." The application shouldn't care if the database is a local container or a managed cloud instance.

### 5. Disposability

Maximize robustness with **fast startup** and **graceful shutdown**.

* **Startup:** Minimize the time between the "start" command and the process being ready to receive traffic.
* **Shutdown:** When the process receives a `SIGTERM` (e.g., during a scale-down event), it must stop accepting new work, finish current requests, and exit cleanly.

---

## 💻 Implementation Example: Graceful Shutdown (Node.js/TypeScript)

This code demonstrates **Factor 9 (Disposability)**. It ensures that when Kubernetes or an Orchestrator shuts down a pod, no user requests are dropped.

```typescript
import express from 'express';
import { createServer } from 'http';

const app = express();
const server = createServer(app);

app.get('/long-task', (req, res) => {
  // Simulate a 5-second business process
  setTimeout(() => res.send('Task Complete'), 5000);
});

// SIGTERM is sent by the orchestrator to request a shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received: Closing HTTP server gracefully...');
  
  // 1. Stop accepting new connections
  // 2. Wait for existing connections to finish (Keep-Alive)
  server.close(() => {
    console.log('HTTP server closed. Cleaning up backing services...');
    
    // 3. Close DB connections, Flush logs, etc.
    // database.close().then(() => process.exit(0));
    process.exit(0);
  });

  // Force shutdown if graceful exit takes too long (e.g., 30s)
  setTimeout(() => {
    console.error('Forced shutdown due to timeout');
    process.exit(1);
  }, 30000);
});

server.listen(3000, () => console.log('App running on port 3000'));

```

---


**Would you like me to move on to Part II and draft the README and code for the Modular Monolith vs. Hexagonal Architecture section?**
