### TickerHub Project Plan

#### Phase 1: Infrastructure as Code (Day 1-3)

*Goal: Establish the local Docker environment that mirrors production.*

* **Container Orchestration:** Create `docker-compose.yml` to spin up Redis, Kafka, and PostgreSQL.
* **Volume Mapping:** Configure the `docker-compose` volume mounts to point your local `sgx-terminal/` directory to `/app` inside the container.
* **Gateway Setup:** Dockerize the FastAPI/Panel service with a hot-reload watcher, allowing you to edit code in your local IDE and see changes reflect in the browser instantly.

#### Phase 2: Core Domain & Event Backbone (Day 4-7)

*Goal: Build the "source of truth" and communication protocol.*

* **Domain Models:** Implement `Position`, `Portfolio`, `Order`, and `Trade` dataclasses.
* **Event Bus:** Develop the `EventBus` to facilitate inter-service communication.
* **Repository Layer:** Write adapters for PostgreSQL and Redis to ensure state persistence is decoupled from service logic.

#### Phase 3: Service Logic & Background Compute (Day 8-12)

*Goal: Implement the "brains" of the terminal.*

* **Service Workers:** Develop `MarketService` (real-time stream handling), `PortfolioService` (PnL calculation), and `RiskService` (VaR/CVaR compute).
* **Worker Pools:** Use Celery or Python `multiprocessing` inside the container to ensure heavy risk calculations don't block the UI.
* **Feed Processor:** Create the `feed_worker` to ingest market ticks and distribute them to the Event Bus.

#### Phase 4: UI & State Orchestration (Day 13-17)

*Goal: Build the Panel front-end components.*

* **Panel Components:** Develop independent `Watchlist`, `Chart`, `OrderBook`, and `Portfolio` widgets.
* **State Binding:** Use `param` to bind the UI widgets to the service state.
* **Layout Management:** Use `FastListTemplate` to assemble the workspace.

#### Phase 5: Hardening & Cloud Transition (Day 18-21)

*Goal: Secure the application and prepare for Hugging Face deployment.*

* **Auth Layer:** Implement JWT/OAuth2 flow via the FastAPI Gateway.
* **Observability:** Integrate Prometheus/Grafana to monitor local feed rates and memory usage.
* **Hugging Face Prep:** Optimize the `Dockerfile` for the HF Space environment and test against their specific constraints (e.g., hardware resource limits).

---

### Revised Project Roadmap Table

| Horizon | Focus | Key Task |
| --- | --- | --- |
| **I. Foundation** | Infrastructure | Configure Docker Compose & Volume Mounts |
| **II. Logic** | Domain & Events | Implement Business Logic & Event Bus |
| **III. Compute** | Services & Workers | Offload Risk & Analytics to Background Workers |
| **IV. View** | UI Layer | Bind Panel Components to `param` state |
| **V. Release** | Deployment | Secure & push to Hugging Face |

---

### Technical Implementation Guidelines for Local Development

1. **Keep Logic in Services:** Even though you are local, code as if the services will eventually run in separate containers. Avoid `import`ing UI components into your services.
2. **State Separation:** The UI (Panel) should only read from the `MarketState` and `PortfolioState`. It should never "own" the logic; it should only emit "commands" to the services.
3. **Hugging Face Portability:** When you are ready for Hugging Face, you won't need to change your application code; you will only need to ensure the Hugging Face environment variable mappings match your local `docker-compose` service names.

**Since the container infrastructure will serve as your development environment, are you ready to define the specific folder structure for your `docker-compose.yml` and services, or would you like to start by sketching out the `EventBus` logic first?**
