# Enterprise Service Readiness Checklist (The Quality Gate)

This checklist serves as the final validation before any service moves from **Staging** to **Production**. In an ecosystem of 50+ applications, this ensures that every service is "born" with the necessary operational rigor to survive in a distributed environment.

## 1. Governance & Identity
- [ ] **Service Catalog:** Service is registered in Backstage.io with assigned owners and on-call rotation.
- [ ] **ADR Compliance:** Major architectural deviations from the "Golden Path" are documented in an approved ADR.
- [ ] **IAM Integration:** Service uses centralized OIDC for authentication and OPA for fine-grained authorization.

## 2. Communication & Reliability
- [ ] **Standardized Protocol:** Service utilizes sanctioned REST/gRPC patterns or Kafka for async events.
- [ ] **Resilience Primitives:** Timeouts, retries, and circuit breakers are configured for all downstream calls.
- [ ] **Idempotency:** All write operations (API or Event consumers) handle duplicate requests safely.
- [ ] **Contract Testing:** APIs are documented via OpenAPI/Swagger; Kafka events are registered in the Schema Registry.

## 3. Data Integrity
- [ ] **Database per Service:** The service owns its schema; no other service accesses its database directly.
- [ ] **Consistency Strategy:** If cross-service consistency is required, a Saga or Outbox pattern is implemented and tested.
- [ ] **Migration Safety:** Database migrations follow the "Expand and Contract" pattern to support rolling deployments.

## 4. Security & Compliance
- [ ] **Threat Model:** A STRIDE threat model has been completed and reviewed by the Security team.
- [ ] **Secret Management:** No secrets, keys, or passwords exist in code or environment variables (using Vault/Secret Manager).
- [ ] **Encryption:** Data is encrypted at rest and in transit (mTLS enforced via Service Mesh).
- [ ] **PII Handling:** Any Personally Identifiable Information is identified and handled per the Data Sovereignty policy.

## 5. Observability & HA
- [ ] **Golden Signals:** Dashboard is live for Latency, Traffic, Errors, and Saturation.
- [ ] **Tracing:** Distributed tracing (OpenTelemetry) is propagated through all entry and exit points.
- [ ] **SLOs Defined:** Service has defined availability and latency targets with an active Error Budget.
- [ ] **DR/Scaling:** Horizontal Pod Autoscaling (HPA) is configured, and a Disaster Recovery plan is documented.

## 6. Deployment & Automation
- [ ] **CI/CD:** Pipeline includes automated linting, unit tests, and security scanning (SAST/DAST).
- [ ] **Progressive Delivery:** Service is configured for Canary or Blue-Green deployment via the IDP.
- [ ] **Runbook:** A "Point of Failure" guide is available for the on-call engineer, linked in the Service Catalog.
