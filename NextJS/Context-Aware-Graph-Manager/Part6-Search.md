# Part 6: Search and Retrieval UI

Goal: let the user type a natural-language query, embed it, run a pgvector similarity search against stored chunks, and show results that link back into the graph — so search and graph exploration feel like one connected tool instead of two separate features.

## 1. Why vector similarity search here, and why it lives in Postgres
Keyword search would miss a query like "who found a radioactive element" matching a chunk that says "Marie Curie discovered polonium" — no shared words. Embedding both the query and the stored chunks into the same vector space lets us match by meaning instead of exact text. Because the embeddings already live in the chunks table's `vector(768)` column (Part 2/3), the similarity search is just one more SQL query against the same database — no separate vector store round trip, and we can join straight from a matching chunk to the Node rows extracted from it in the same query.

## 2. The pgvector similarity query
pgvector's `<=>` operator computes cosine distance (lower = more similar). We extend the `vector.ts` helper from Part 3.

`src/lib/vector.ts` (add this function):
```ts
export interface ChunkSearchResult {
  chunkId: string;
  documentId: string;
  content: string;
  fileName: string;
  distance: number;
}

export async function searchSimilarChunks(
  queryEmbedding: number[],
  limit: number = 8
): Promise<ChunkSearchResult[]> {
  const vectorLiteral = toVectorLiteral(queryEmbedding);

  const rows = await db.$queryRaw<ChunkSearchResult[]>`
    SELECT
      c.id AS "chunkId",
      c."documentId" AS "documentId",
      c.content AS content,
      d."fileName" AS "fileName",
      (c.embedding <=> ${vectorLiteral}::vector) AS distance
    FROM chunks c
    JOIN documents d ON d.id = c."documentId"
    WHERE c.embedding IS NOT NULL
    ORDER BY c.embedding <=> ${vectorLiteral}::vector
    LIMIT ${limit}
  `;

  return rows;
}
```

Why `ORDER BY` the raw distance expression instead of a `WHERE` threshold: cosine distance thresholds that "feel right" vary by embedding model and content domain, and picking a fixed cutoff is a common beginner mistake that either hides good matches or lets in noise. Ordering by distance and taking a fixed `LIMIT` is simpler and more predictable for a first version; a real production system would eventually make the threshold/limit tunable.

## 3. Linking search results to graph nodes
A chunk-level match is useful, but "context-aware" means also surfacing which graph nodes were extracted from that same chunk, since that's exactly the `NodeSourceChunk` provenance link built in Part 4b.

`src/lib/vector.ts` (add this function):
```ts
export async function getNodesForChunks(chunkIds: string[]) {
  if (chunkIds.length === 0) return [];

  return db.node.findMany({
    where: {
      sourceChunks: {
        some: { chunkId: { in: chunkIds } },
      },
    },
    select: { id: true, name: true, type: true },
  });
}
```

## 4. The search API route
`src/app/api/search/route.ts`:
```ts
import { NextResponse } from "next/server";
import { embedText } from "@/lib/ai/embed";
import { searchSimilarChunks, getNodesForChunks } from "@/lib/vector";

export async function POST(req: Request) {
  const { query } = (await req.json()) as { query: string };

  if (!query || query.trim().length === 0) {
    return NextResponse.json({ error: "Query is required" }, { status: 400 });
  }

  try {
    const queryEmbedding = await embedText(query);
    const chunkResults = await searchSimilarChunks(queryEmbedding, 8);
    const relatedNodes = await getNodesForChunks(chunkResults.map((r) => r.chunkId));

    return NextResponse.json({
      results: chunkResults,
      relatedNodes,
    });
  } catch (err) {
    console.error("Search failed:", err);
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Search failed" },
      { status: 500 }
    );
  }
}
```

Why a Route Handler rather than a Server Action here too: the search bar needs a request/response cycle triggered by arbitrary, frequent user input (typing and re-searching), which maps naturally onto `fetch()` from a client component, matching the same reasoning as the graph data endpoint in Part 5.

## 5. The search bar component
`src/components/search-bar.tsx`:
```tsx
"use client";

import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Search } from "lucide-react";

interface ChunkResult {
  chunkId: string;
  documentId: string;
  content: string;
  fileName: string;
  distance: number;
}

interface RelatedNode {
  id: string;
  name: string;
  type: string;
}

export function SearchBar() {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<ChunkResult[]>([]);
  const [relatedNodes, setRelatedNodes] = useState<RelatedNode[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    if (!query.trim()) return;

    setIsSearching(true);
    setError(null);

    try {
      const res = await fetch("/api/search", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query }),
      });
      const data = await res.json();

      if (!res.ok) {
        setError(data.error ?? "Search failed");
        setResults([]);
        setRelatedNodes([]);
      } else {
        setResults(data.results);
        setRelatedNodes(data.relatedNodes);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Search failed");
    } finally {
      setIsSearching(false);
    }
  }

  return (
    <div className="space-y-4">
      <form onSubmit={handleSearch} className="flex gap-2">
        <Input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Ask about your documents, e.g. 'who discovered polonium'"
        />
        <Button type="submit" disabled={isSearching}>
          <Search className="mr-1 h-4 w-4" />
          {isSearching ? "Searching..." : "Search"}
        </Button>
      </form>

      {error && <p className="text-sm text-destructive">{error}</p>}

      {relatedNodes.length > 0 && (
        <div>
          <p className="text-xs font-medium uppercase text-muted-foreground">
            Related graph nodes
          </p>
          <div className="mt-1 flex flex-wrap gap-1">
            {relatedNodes.map((node) => (
              <a key={node.id} href="/graph">
                <Badge variant="outline" className="cursor-pointer hover:bg-accent">
                  {node.name} · {node.type}
                </Badge>
              </a>
            ))}
          </div>
        </div>
      )}

      <div className="space-y-2">
        {results.map((r) => (
          <Card key={r.chunkId}>
            <CardContent className="pt-4">
              <p className="text-sm">{r.content}</p>
              <p className="mt-2 text-xs text-muted-foreground">
                From "{r.fileName}" · distance {r.distance.toFixed(3)}
              </p>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
```

The "Related graph nodes" badges linking to `/graph` are the connective tissue between search and visualization — clicking one takes the user to the same graph view built in Part 5, where they can click that same node for the full context panel. Part 7 can optionally deep-link this further (e.g. `/graph?focus=nodeId`) as a polish enhancement.

## 6. Wire the search bar into the home page
`src/app/page.tsx` (updated):
```tsx
import { UploadForm } from "@/components/upload-form";
import { SearchBar } from "@/components/search-bar";
import Link from "next/link";

export default function HomePage() {
  return (
    <main className="mx-auto max-w-2xl px-6 py-16 space-y-10">
      <div>
        <h1 className="text-2xl font-semibold">Cortex - Knowledge Graph Manager</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Upload a document to extract entities and relationships into a knowledge graph.
        </p>
        <div className="mt-6">
          <UploadForm />
        </div>
        <Link href="/graph" className="mt-3 inline-block text-sm text-primary underline">
          View Graph →
        </Link>
      </div>

      <div>
        <h2 className="text-lg font-medium">Search your documents</h2>
        <div className="mt-3">
          <SearchBar />
        </div>
      </div>
    </main>
  );
}
```

## 7. Verification checkpoint
1. With at least two ingested documents (from earlier checkpoints), search a phrase that's semantically related but not word-for-word identical to your source text (e.g. if a doc says "discovered polonium," search "who found a radioactive element").
2. Confirm relevant chunk(s) appear ranked with the lowest distance first, and confirm the "Related graph nodes" badges show entities that were genuinely extracted from those chunks.
3. Click a related node badge, land on `/graph`, and manually click that same node to confirm the context panel shows consistent info with what search surfaced.
4. Search a nonsense query unrelated to anything uploaded — confirm it still returns *some* results (vector search always returns the closest matches, it doesn't have a built-in "no match" concept) but with visibly higher distance values, and confirm the UI doesn't crash on an empty `relatedNodes` list.

Next: Part 7 - Final Polish and Deployment.
