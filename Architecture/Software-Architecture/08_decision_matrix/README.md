# Architectural Decision Matrix

Guidance for selecting patterns based on goals and trade-offs.

| Goal               | Architecture     | Primary Trade-off     |
| ------------------ | ---------------- | --------------------- |
| Speed to market    | Modular Monolith | Scaling ceiling       |
| Team autonomy      | Microservices    | Ops complexity        |
| Real-time UX       | Event-Driven     | Debugging difficulty  |
| Strong consistency | Saga / CQRS      | Development effort    |
| Ultra-low latency  | Edge Computing   | Operational sprawl    |
| Data intelligence  | Data Mesh        | Governance complexity |
| AI enablement      | RAG / Agentic    | Cost and complexity   |
