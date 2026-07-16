**Phase 1, Module 1.3: The "Lost in the Middle" & Truncation Flaws (Failure Mode)**

### 1. The Threat Model / The Challenge
Real security logs are huge (15,000+ lines for a single CloudTrail or auth.log day). LLMs have a fixed context window (e.g., 8k–128k tokens). Stuffing everything in causes:
- **Lost in the Middle**: Important events in the middle are silently ignored.
- **Truncation**: Hard cutoffs with no warning.
- **Token waste / cost explosion** (even locally, slower responses).

**Challenge**: Implement deterministic chunking *before* sending to the model, combine results intelligently, and surface the limitation transparently.

### 2. The Architecture Blueprint
```
Full Log File
    ↓
Chunking Engine (pure Python, sliding window + overlap)
    ↓ (multiple smaller prompts)
Ollama (per chunk)
    ↓
Pydantic-validated results per chunk
    ↓
Merger + Deduplication → Final Report
```

No black-box libraries for chunking — full control and visibility.

### 3. The Lab (Code-First)

**Step 1: Add Chunking Logic**  
**The Target**: New `chunker.py` for deterministic splitting.  
**The Concept**: Analogy — reading a thick novel. Instead of trying to remember the whole book at once (impossible), you read 10 pages at a time with 2-page overlaps so you don’t miss plot connections between sections. We do the same with log lines.

Create `chunker.py` (complete):

```python
from typing import List, Generator

def chunk_log_lines(
    log_file: str,
    lines_per_chunk: int = 50,
    overlap: int = 5
) -> Generator[List[str], None, None]:
    """
    Yield overlapping chunks of log lines.
    Pure Python, deterministic, no tokenization needed yet.
    """
    if lines_per_chunk < 10:
        lines_per_chunk = 10
    if overlap >= lines_per_chunk:
        overlap = lines_per_chunk // 3

    with open(log_file, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    for i in range(0, len(lines), lines_per_chunk - overlap):
        chunk = lines[i : i + lines_per_chunk]
        if not chunk:
            break
        yield [line.strip() for line in chunk if line.strip()]

    # Final stats
    print(f"Total lines: {len(lines)} | Chunks created: {(len(lines) + lines_per_chunk - overlap - 1) // (lines_per_chunk - overlap)}")
```

**Verification**:
```bash
python -c "
from chunker import chunk_log_lines
list(chunk_log_lines('sample_auth.log', lines_per_chunk=3, overlap=1))
"
```

**Step 2: Integrate Chunking into Main CLI**  
**The Target**: Final `sec_log_parse.py` for Phase 1 (complete, building on 1.2).  
**The Concept**: The chunker feeds manageable bites to the LLM. Pydantic ensures every bite is valid. Overlap prevents missing attacks that span chunk boundaries. This is production-grade engineering: explicit, observable, and fixable.

Replace `sec_log_parse.py` with this **full final version**:

```python
#!/usr/bin/env python3
"""
Paranoid AI Log Analyst CLI - Phase 1.3: Chunking + Full Pipeline
"""
import typer
import ollama
from dotenv import load_dotenv
import os
from rich.console import Console
from rich.panel import Panel

from models import AnalysisResult
from chunker import chunk_log_lines

load_dotenv()

app = typer.Typer(help="sec-log-parse: Chunked + Pydantic Log Analyzer")
console = Console()

SYSTEM_PROMPT = """You are a paranoid senior security analyst.
Analyze the provided LOG LINES for authentication anomalies only.
Return valid JSON with the exact schema: {"anomalies": [...]}. No extra text."""

@app.command()
def parse(
    log_file: str = typer.Argument(..., help="Path to log file"),
    model: str = typer.Option(None, help="Model override"),
    lines_per_chunk: int = typer.Option(50, help="Lines per chunk"),
    overlap: int = typer.Option(5, help="Overlap lines"),
):
    """Full chunked analysis with validation."""
    if not os.path.exists(log_file):
        console.print(f"[red]File not found: {log_file}[/red]")
        raise typer.Exit(1)

    effective_model = model or os.getenv("OLLAMA_MODEL", "llama3.2")
    console.print(Panel(f"Chunked Analysis | Model: {effective_model} | Chunk size: {lines_per_chunk}", title="Starting Phase 1.3"))

    all_anomalies = []
    chunk_count = 0
    validation_fails = 0

    for chunk_lines in chunk_log_lines(log_file, lines_per_chunk, overlap):
        chunk_count += 1
        chunk_text = "\n".join(chunk_lines)

        try:
            response = ollama.chat(
                model=effective_model,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": f"Log chunk {chunk_count}:\n{chunk_text}"}
                ],
                format="json",
                options={"temperature": 0.0}
            )
            raw = response['message']['content']
            result = AnalysisResult.model_validate_json(raw)
            all_anomalies.extend(result.anomalies)
        except Exception as e:
            validation_fails += 1
            console.print(f"[yellow]Chunk {chunk_count} failed: {e}[/yellow]")

    # Simple deduplication by reason+ip (expandable)
    seen = set()
    unique = []
    for a in all_anomalies:
        key = (a.source_ip, a.reason)
        if key not in seen:
            seen.add(key)
            unique.append(a)

    final = AnalysisResult(anomalies=unique)
    console.print(Panel(
        f"Chunks: {chunk_count}\n"
        f"Raw anomalies: {len(all_anomalies)}\n"
        f"Unique after dedup: {len(unique)}\n"
        f"Validation fails: {validation_fails}",
        title="✅ Chunked Analysis Complete",
        border_style="green"
    ))
    console.print(final.to_json())
    return final

if __name__ == "__main__":
    app()
```

**Verification**:
1. Create a larger test log (simulate scale):
   ```bash
   python -c '
   with open("large_sample.log", "w") as f:
       for i in range(300):
           f.write(f"Jan 17 10:{i:02d}:00 server sshd[{1000+i}]: Failed password for invalid user test{i%10} from 192.168.1.{i%255}\n")
   '
   ```
2. Run: `./sec_log_parse.py large_sample.log --lines-per-chunk 30`
3. Observe chunk stats, successful merging, and clean output.

**Step 3: Update Tests**
Update `test_parse.py` to test chunking (add similar assertion for chunk handling).

### 4. The Failure Mode
**The Trap**: No overlap → missed cross-chunk attacks. Bad chunk size → too many calls (slow) or still too large (truncation). No deduplication → noisy output.  
**The Fix**: Configurable overlap, simple deduplication, per-chunk validation, and visible stats. This is the foundation for scaling to real enterprise logs.

---

### Reference Section (Isolated Deep Dives)

**"Lost in the Middle" Phenomenon**: LLMs perform worst on information in the middle of long contexts. Chunking + overlap is the standard deterministic mitigation before any advanced summarization.

**Token Physics (Simple Explanation)**: A token ≈ 4 characters. `llama3.2` default is often 8k–32k tokens. Always measure (future modules can add exact token counting via tiktoken or Ollama).

**Phase 1 Complete!**  
You now have a solid, local, structured, chunk-aware Log Analyst CLI.

**Next Phase**: Reply **"next"** for Phase 2.1 — Malware Intel RAG Engine.

Congratulations on finishing Phase 1. Run the large sample and explore the code!
