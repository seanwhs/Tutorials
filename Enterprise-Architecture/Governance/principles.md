# Architectural Principles

These principles are the "North Star" for all technical decisions. When in doubt, align with these tenets.

1. **Standardization over Freedom**: Prefer the "Golden Path" for non-differentiating features (CI/CD, Logging, Auth) to minimize cognitive load.
2. **API-First Design**: All services must expose their functionality via well-defined, versioned APIs before any UI is developed.
3. **Database per Service**: Each service owns its data. Direct cross-service database access is strictly prohibited.
4. **Design for Failure**: Assume dependencies will fail. Use circuit breakers, retries, and bulkheads to ensure graceful degradation.
5. **Security by Design**: Security is not a "final check." It is integrated into the blueprint via Zero Trust and Policy as Code.
6. **Automate Everything**: If a task is performed more than twice, it must be codified and automated.
7. **Observability is Mandatory**: A service is not "Production Ready" unless it emits the Four Golden Signals (Latency, Traffic, Errors, Saturation).
