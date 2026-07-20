# Quiz: Phase 3 — Advanced Retrieval Architectures: Agentic & Vectorless RAG

---

**Q1.** A new engineer joins your team and says: "Our knowledge base only has 40 documents — why are we bothering with keyword/tag scoring instead of just using a vector database like every RAG tutorial recommends?" How would you justify the vectorless approach using the specific criteria from this phase?



---

**Q2.** Trace through what would happen if `judgeRetrieval()` itself started throwing errors on every call (e.g., due to a bug in its own JSON parsing). Would `agenticRetrieve()` get stuck in an infinite retry loop? Why or why not?



---

**Q3.** Why would it be a mistake to route a request like "what's the status of order ORD-1004" through the `searchKnowledgeBase` tool's agentic retrieval loop, even if you added "ORD-1004" as a searchable tag to a document?



---

**Q4.** The cost calculator prices input and output tokens completely separately rather than using one blended per-token rate. Construct a concrete scenario where two requests have identical `totalTokens` but meaningfully different actual dollar costs, and explain why.



---

**Q5.** Why does `getModelPricing()` return a fallback rate (rather than, say, `0` or throwing an error) when a model name isn't found in the pricing table, and why is this specific choice safer than the alternatives?



---

**Q6.** How does the `trackShipment` tool's error handling distinguish "no tracking information exists for this number" from "the carrier's API is currently broken" — and why does that distinction matter for how the agent should respond to the user?
