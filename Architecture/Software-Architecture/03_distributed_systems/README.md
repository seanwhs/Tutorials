# Part III — Distributed Systems & Microservices

Distribution is not an automatic upgrade—it’s a **trade-off** where you sacrifice local simplicity (shared memory, ACID transactions) for global scalability and team autonomy.

## 1. Microservices: The Organizational Strategy

As popularized by **Martin Fowler**, microservices are essentially **"componentization via services."** They allow a system to be split along domain lines, enabling teams to deploy and scale their specific services without coordinating a global release.

### The "Microservices Tax"

Before adopting this pattern, you must be prepared to pay the "tax" of:

* **Network Latency:** Every call now takes milliseconds instead of nanoseconds.
* **Partial Failure:** What happens if the Billing service is up but the Payment service is down?
* **Observability:** You need distributed tracing (Jaeger/Zipkin) to see where a request failed.

---

## 2. Essential Distributed Patterns

To manage the chaos of distributed systems, we rely on three core patterns:

### CQRS (Command Query Responsibility Segregation)

* **The Problem:** The way we write data (optimized for consistency) is often not the way we read data (optimized for UI performance).
* **The Solution:** Use different models for updating (Commands) and reading (Queries).
* **Example:** A relational DB handles the logic for a "New Order," while an Elasticsearch index serves the "Order History" search.

<img width="2048" height="1453" alt="image" src="https://github.com/user-attachments/assets/9faf9093-0ba5-4b6c-83a8-8aad576f8562" />

### Saga Pattern (Distributed Transactions)

* **The Problem:** You can no longer wrap an entire operation in a single database `BEGIN/COMMIT`.
* **The Solution:** A sequence of local transactions. If a step fails, the Saga triggers "Compensating Transactions" to undo the previous successful steps.
* **Modes:** * **Choreography:** Services exchange events (decentralized).
* **Orchestration:** A central manager tells services what to do (easier to debug).



### Circuit Breaker

* **The Problem:** If one service is slow, it can back up the entire system, leading to a "cascading failure."
* **The Solution:** If a service fails repeatedly, the "breaker" trips. For a set window, all calls to that service fail immediately, protecting the rest of the system until the service recovers.

---

## 💻 Code Example: The Circuit Breaker (TypeScript/Resilience4js)

This demonstrates how to protect your application from a failing downstream dependency.

```typescript
import { CircuitBreaker } from 'resilience4js';

// 1. Define the service call
const fetchPaymentStatus = async (id: string) => {
  const response = await fetch(`https://api.payments.com/status/${id}`);
  if (!response.ok) throw new Error('Downstream failure');
  return response.json();
};

// 2. Wrap it in a Circuit Breaker
const breaker = CircuitBreaker.of('payment-api', {
  failureRateThreshold: 50, // Trip if 50% of calls fail
  waitDurationInOpenState: 10000, // Wait 10s before retrying
});

const protectedCall = breaker.decoratePromise(fetchPaymentStatus);

// 3. Usage
try {
  const status = await protectedCall('order_123');
} catch (error) {
  // If the breaker is open, this catches immediately without hitting the network
  console.error('Service unavailable or Circuit Broken');
}

```

---

## 📂 Directory Contents

* `/cqrs-es-demo`: A sample showing a "Write Model" in SQL and a "Read Model" in a Document store.
* `/saga-orchestration`: A Node.js example of a travel booking saga (Flight + Hotel + Car).
* `/resilience-patterns`: Implementation of Retries, Timeouts, and Circuit Breakers.

---

