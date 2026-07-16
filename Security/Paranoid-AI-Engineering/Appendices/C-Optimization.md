**Appendix C: Performance & Cost Optimization**

### 1. Token Management (Critical for Local & Cloud)
Create `utils/token_counter.py`:

```python
from typing import List

def estimate_tokens(text: str) -> int:
    """Rough but fast estimation (4 chars ≈ 1 token)."""
    return len(text) // 4 + 10  # Add buffer for formatting

def truncate_to_token_limit(text: str, max_tokens: int = 8000) -> str:
    """Smart truncation preserving recent lines."""
    lines = text.split("\n")
    token_count = 0
    kept_lines = []
    
    for line in reversed(lines):  # Prefer recent data
        line_tokens = estimate_tokens(line)
        if token_count + line_tokens > max_tokens:
            break
        kept_lines.append(line)
        token_count += line_tokens
    
    return "\n".join(reversed(kept_lines))
```

**Usage in chunker/agent**:
```python
chunk_text = truncate_to_token_limit(raw_chunk, max_tokens=6000)
```

### 2. Caching Layer
```python
# utils/cache.py
from functools import lru_cache
import hashlib

@lru_cache(maxsize=512)
def cached_llm_call(prompt_hash: str, model: str):
    # In practice: store Ollama responses by hash
    pass

def get_prompt_hash(prompt: str) -> str:
    return hashlib.sha256(prompt.encode()).hexdigest()
```

### 3. Model Selection Guide

| Use Case                    | Recommended Model       | Context Window | Speed     | Quality   |
|----------------------------|-------------------------|----------------|-----------|-----------|
| Log parsing / Quick analysis | `llama3.2:1b` or `3b`  | 8k–16k        | Very Fast | Good      |
| Malware rule generation     | `llama3.2:8b`          | 32k           | Medium    | Excellent |
| Agent reasoning             | `llama3.1:8b` or `70b` | 128k          | Slower    | Best      |

**Tip**: Use `ollama list` and `ollama rm` to manage VRAM usage.

### 4. Benchmarking Script (`benchmarks/run.py`)
```python
import time
import statistics

def benchmark_agent(ip_list: list):
    times = []
    for ip in ip_list:
        start = time.time()
        # Run agent.investigate(ip)
        duration = time.time() - start
        times.append(duration)
    print(f"Avg: {statistics.mean(times):.2f}s | Max: {max(times):.2f}s")
```

### 5. Resource Optimization Tips
- **Batch processing** in Phase 1 chunker.
- **Async** tool calls in Phase 3.
- **Quantized models** (`llama3.2:8b-q4`).
- Monitor with `htop` + Ollama’s `/api/ps` endpoint.
- Set `OLLAMA_FLASH_ATTENTION=1` for GPU acceleration.

---

This appendix helps you scale from a learning project to a real-world tool without exploding costs or latency.
