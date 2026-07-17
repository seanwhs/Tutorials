# Appendix D — Embeddings, Cosine Similarity, and Vector Search, in Depth

Part 3 introduced embeddings and cosine similarity with a library-shelf analogy and working code. This appendix goes deeper into the actual mathematics and the practical tuning knobs you'll encounter using this pattern in a real project.

## What an Embedding Vector Actually Is

An embedding model takes a piece of text and outputs a fixed-length list of floating-point numbers — for `text-embedding-3-small`, exactly 1536 numbers, regardless of whether the input text was one word or several paragraphs. Each number doesn't correspond to anything humanly interpretable on its own (there's no "dimension 47 means formality") — the *meaning* only emerges from a text's position relative to other texts in this 1536-dimensional space. This is learned automatically during the model's training on massive amounts of text, where the training process nudges semantically similar texts toward nearby coordinates and dissimilar texts toward distant ones.

## Why Cosine Similarity, Specifically

Given two vectors, there are several ways to measure "closeness" — Euclidean distance (straight-line distance, like a ruler), Manhattan distance (grid-like distance, like city blocks), and cosine similarity (the angle between them, ignoring magnitude). We used cosine similarity for a specific reason: **embedding magnitude often correlates with things irrelevant to meaning** — like text length or word frequency — while the *direction* a vector points captures its semantic content far more reliably. Two texts expressing the same idea, one verbose and one terse, may produce vectors of different lengths but pointing in nearly the same direction — cosine similarity correctly scores them as similar; Euclidean distance might not.

The formula, as implemented in `src/retrieval/vectorStore.ts`:

```
cosine_similarity(A, B) = (A · B) / (||A|| × ||B||)
```

Where `A · B` is the **dot product** (multiply corresponding elements, sum the results) and `||A||` is the **magnitude** (square root of the sum of squares of its elements — literally the Pythagorean theorem, generalized to 1536 dimensions instead of 2 or 3). The result ranges from -1 (pointing in exactly opposite directions — meaning as different as this model can represent) to 1 (pointing in exactly the same direction — meaning essentially identical).

## Why We Implemented This by Hand Instead of Using a Library

Ten lines of straightforward arithmetic don't warrant a dependency. More importantly, implementing it directly meant we could verify it with fabricated 2D vectors first (Part 3, Step 3's verification with `[1, 0]`, `[0, 1]`, `[0.7, 0.7]`) — a technique worth remembering generally: **test the math with simple, human-checkable numbers before trusting it on 1536-dimensional real embeddings you can't manually verify.**

## Practical Tuning Knobs You'll Encounter Beyond This Series

**`topK` (how many results to retrieve):** We used `topK: 3` for direct retrieval and `topK: 8` before reranking (Part 4). This is a real trade-off: too small risks missing a relevant chunk that scored just outside the cutoff; too large increases both cost (more tokens sent to the LLM or reranker) and reintroduces some of Part 1's noise-dilution risk. The `8-then-rerank-to-3` pattern from Part 4 exists specifically to get a wider net without paying the "everything sent to the final LLM call" cost for all 8.

**Embedding model choice:** We used `text-embedding-3-small` throughout for cost efficiency. OpenAI also offers `text-embedding-3-large` (higher-dimensional, more nuanced, notably more expensive per token) — a real production decision would benchmark both against your own eval suite (Part 8) rather than assuming bigger is proportionally better for your specific corpus.

**Similarity thresholds:** Our reranker (Part 4) used a `minScore: 5` cutoff on a 0-10 scale, chosen somewhat arbitrarily as a starting point. In a real system, this threshold should be tuned empirically against your golden dataset (Part 8) — run the eval suite at several threshold values and pick the one that maximizes precision without sacrificing recall, rather than guessing once and never revisiting it.

## Why In-Memory Linear Scan Was Honest, Not a Shortcut

Our `VectorStore.search()` method compares a query against *every* stored vector, one by one — an approach that scales linearly with corpus size. At our scale (149-187 chunks), this runs in milliseconds and is genuinely the right engineering choice — a dedicated vector database would be premature optimization. At real production scale (tens of thousands to millions of chunks), a linear scan becomes measurably slow, and this is where dedicated vector databases (pgvector, Pinecone, Weaviate, Qdrant) earn their keep — they use **approximate nearest-neighbor (ANN)** algorithms (like HNSW — Hierarchical Navigable Small World graphs) that trade a small amount of accuracy for dramatically faster lookups at scale. The important architectural note: our `VectorStore` class's *public interface* (`addAll`, `search`) was deliberately designed so that swapping its internals for a real vector database later requires changing one class's implementation, not any of the code that calls it.
