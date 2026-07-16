**Appendix A: Full Project Structure & Dockerization**

### Final Project Layout
```
paranoid-ai-engineering/
├── sec-log-parse/              # Phase 1
│   ├── sec_log_parse.py
│   ├── models.py
│   ├── chunker.py
│   ├── .env
│   └── sample_auth.log
├── malware-rag/                # Phase 2
│   ├── knowledge_base.py
│   ├── malware_analyzer.py
│   ├── malware_action.py
│   ├── rule_validator.py
│   └── models.py
├── secops-agent/               # Phase 3
│   ├── agent.py
│   ├── executor.py
│   ├── models.py
│   └── tools.py
├── hardened-gateway/           # Phase 4
│   ├── main.py
│   ├── exploit_sim.py
│   └── final_test.py
├── chroma_db/                  # Persistent vector store
├── generated_rules/            # Output artifacts
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── README.md
```

### `requirements.txt` (Unified)
```txt
typer[all]
ollama
pydantic
python-dotenv
rich
chromadb
sentence-transformers
yara-python
fastapi
uvicorn[standard]
requests
lxml
pyyaml
```

### `Dockerfile` (Multi-stage, Secure)
```dockerfile
FROM python:3.11-slim AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Non-root user
RUN useradd -m -u 1000 appuser
USER appuser

FROM base AS ollama
# Ollama runs in separate service (see compose)

FROM base AS gateway
COPY hardened-gateway/ /app/
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

FROM base AS agent
COPY secops-agent/ /app/
CMD ["python", "agent.py"]
```

### `docker-compose.yml` (Full Stack)
```yaml
version: '3.9'

services:
  ollama:
    image: ollama/ollama
    container_name: ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    deploy:
      resources:
        limits:
          memory: 8G

  chroma:
    image: chromadb/chroma
    ports:
      - "8001:8000"
    volumes:
      - chroma_data:/chroma/chroma

  gateway:
    build:
      context: .
      dockerfile: Dockerfile
      target: gateway
    ports:
      - "8000:8000"
    depends_on:
      - ollama
    environment:
      - OLLAMA_HOST=http://ollama:11434
    restart: unless-stopped

  agent:
    build:
      context: .
      dockerfile: Dockerfile
      target: agent
    depends_on:
      - ollama
    environment:
      - OLLAMA_HOST=http://ollama:11434

volumes:
  ollama_data:
  chroma_data:
```

### Quick Start with Docker
```bash
# 1. Pull models on host first
docker compose up ollama -d
docker exec -it ollama ollama pull llama3.2

# 2. Start full stack
docker compose up --build

# 3. Test gateway
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"ip": "192.168.1.100"}'
```

### Security Hardening in Docker
- Non-root user
- Resource limits
- No unnecessary packages
- Read-only volumes where possible
- Network isolation between services

---

**This appendix makes your entire system portable, reproducible, and much more secure.**
