# Architectural Blueprints

Blueprints are the high-level design specifications for recurring enterprise challenges. They provide the "conceptual north star" for implementation.

## Core Blueprints
* **Event-Driven Backbone**: Standards for Kafka/Pulsar integration and schema registry enforcement.

* **Distributed Consistency**: Implementation of Saga patterns (Orchestration vs. Choreography) and the Transactional Outbox.

* **Observability & Telemetry**: Universal standards for OpenTelemetry (OTel) instrumentation and correlation IDs.

* **Traffic Management**: Specifications for API Gateway (North-South) and Service Mesh (East-West) integration.

## Usage
Blueprints are used during the design phase of a new service to ensure alignment with the "Golden Path" before a single line of code is written.
