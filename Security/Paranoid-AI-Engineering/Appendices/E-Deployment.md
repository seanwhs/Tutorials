**Appendix E: Production Deployment Checklist**

### 1. Environment Variables Reference (`.env.example`)
```env
OLLAMA_MODEL=llama3.2
OLLAMA_HOST=http://localhost:11434

# Gateway
GATEWAY_HOST=0.0.0.0
GATEWAY_PORT=8000
MAX_TOKENS=8192
REQUESTS_PER_MINUTE=30

# Security
SECRET_KEY=your-super-secret-key-here
DEBUG=false

# Optional
SHODAN_API_KEY=...
```

### 2. Production Deployment Checklist

**Pre-Deployment**
- [ ] Run full test suite (`pytest`)
- [ ] Red-team with Appendix D scenarios
- [ ] Scan dependencies (`pip-audit` or `safety`)
- [ ] Review all `exec` / `subprocess` calls
- [ ] Set strong secrets (use `openssl rand -hex 32`)

**Infrastructure**
- [ ] Use Docker Compose or Kubernetes
- [ ] Enable Ollama GPU acceleration if available
- [ ] Set resource limits (CPU/Memory)
- [ ] Use reverse proxy (Nginx/Traefik) with TLS
- [ ] Implement proper logging (JSON to stdout)

**Monitoring & Observability**
- [ ] Prometheus metrics for token usage, request rate, error rate
- [ ] Grafana dashboards
- [ ] Alert on high error rates or circuit breaker triggers
- [ ] Audit log retention (at least 90 days)

**Security Controls**
- [ ] Network segmentation (agent cannot reach internet unless needed)
- [ ] Input/output validation at every boundary
- [ ] Rate limiting + WAF rules
- [ ] Regular model updates + checksum verification
- [ ] Backup ChromaDB and rule artifacts

**Operational Runbook**
- How to add new tools safely
- Emergency shutdown procedure
- Incident response for detected attacks on the AI itself

**Scaling**
- Horizontal scaling of gateway instances
- Queue system (Celery/RabbitMQ) for heavy agent jobs
- Multi-model routing (fast model for logs, smart model for malware)

### 3. One-Command Production Start
```bash
docker compose -f docker-compose.prod.yml up -d --build
```

**docker-compose.prod.yml** would include secrets, volumes, and healthchecks.

---

This checklist helps you move from tutorial to production with confidence.
