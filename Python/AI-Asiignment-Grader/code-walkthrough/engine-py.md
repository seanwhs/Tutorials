## First block: setup and client

```python
import os
import asyncio
import re
from dotenv import load_dotenv
from openai import AsyncOpenAI

load_dotenv()
API_KEY = os.getenv("OPENROUTER_API_KEY")

client = AsyncOpenAI(
    api_key=API_KEY,
    base_url="https://openrouter.ai/api/v1"
)
```

### Why this exists
This block solves one basic problem: the program needs a safe way to get an API key and create a reusable connection object for calling the AI service. Instead of hardcoding secrets into the file, it reads them from an environment file, which is a common way to keep credentials out of source code. Then it creates one shared `client` object so the rest of the program can make API requests consistently.

### Python constructs used
- `import ...` brings in modules or libraries.
- `load_dotenv()` loads variables from a `.env` file into the environment.
- `os.getenv(...)` reads a value from the environment safely.
- `AsyncOpenAI(...)` creates an asynchronous API client.
- `async` support matters because later code uses `await`, which means the program can pause while waiting for network requests without freezing everything.

### Pattern analysis
This is a classic **initialization pattern**: set up configuration first, then create a service client once and reuse it everywhere. It is also a Pythonic use of **configuration via environment variables**, which is much safer than embedding secrets directly in code. The async client choice hints that the program expects many network calls and wants to stay responsive.

### What if
Change `base_url` to the official OpenAI endpoint or another provider endpoint and observe how the same code structure can target a different backend. That helps you see that the client is just a connector, while the surrounding logic stays the same.

### Check your understanding
Why is `OPENROUTER_API_KEY` loaded from the environment instead of written directly into the file?
