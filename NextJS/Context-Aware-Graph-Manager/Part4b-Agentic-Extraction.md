# Part 4b: AI-Agentic Extraction (Parsing Chunks into Nodes and Edges)

Goal: take each stored Chunk, ask the LLM to identify entities and relationships mentioned in it, validate the LLM's output against a strict Zod schema, then de-duplicate and persist into the Node/Edge/NodeSourceChunk/EdgeSourceChunk tables from Part 2.

## 1. Why structured output instead of asking for JSON in a prompt
A naive approach asks the model to "respond in JSON" inside a plain text prompt, then calls `JSON.parse` on the response. This breaks constantly in practice: models wrap JSON in markdown fences, add explanatory prose before/after it, misspell field names, or omit required fields under load. The Vercel AI SDK's `generateObject` solves this properly: it takes a Zod schema, converts it to a JSON Schema the model is instructed to follow (and enforces it directly when the provider supports native structured output/tool calling), and returns a value that is already validated against your schema before your code ever sees it. If the model's output cannot satisfy the schema, the SDK throws a catchable error instead of handing you broken data.

## 2. The extraction schema
This schema is the single source of truth for what "a valid extraction result" looks like. Both the LLM's output and our persistence code are constrained by it.

`src/lib/ai/extraction-schema.ts`:
```ts
import { z } from "zod";

export const NodeTypeEnum = z.enum([
  "PERSON",
  "ORGANIZATION",
  "LOCATION",
  "CONCEPT",
  "EVENT",
  "PRODUCT",
  "OTHER",
]);

export const ExtractedNodeSchema = z.object({
  name: z.string().min(1).describe("The canonical, short name of the entity, e.g. 'Marie Curie'"),
  type: NodeTypeEnum.describe("The entity category"),
  description: z
    .string()
    .optional()
    .describe("A one-sentence description of this entity based only on the given text"),
});

export const ExtractedEdgeSchema = z.object({
  sourceName: z.string().min(1).describe("Name of the entity the relationship starts from"),
  targetName: z.string().min(1).describe("Name of the entity the relationship points to"),
  label: z
    .string()
    .min(1)
    .describe("A short, uppercase, snake-free relationship label, e.g. 'WORKS_AT', 'DISCOVERED', 'LOCATED_IN'"),
});

export const ExtractionResultSchema = z.object({
  nodes: z.array(ExtractedNodeSchema).describe("All distinct entities mentioned in the text"),
  edges: z
    .array(ExtractedEdgeSchema)
    .describe("All relationships between the extracted entities, referencing them by name"),
});

export type ExtractedNode = z.infer<typeof ExtractedNodeSchema>;
export type ExtractedEdge = z.infer<typeof ExtractedEdgeSchema>;
export type ExtractionResult = z.infer<typeof ExtractionResultSchema>;
```

Why edges reference nodes by `sourceName`/`targetName` strings, not database IDs: the LLM only sees raw chunk text, it has no knowledge of our database's cuid values. Referencing by name lets the model express "Alice founded Acme Corp" naturally, and our persistence layer (step 4 below) resolves those names to real Node IDs, creating new Node rows for names it hasn't seen before and reusing existing ones otherwise.

## 3. The extraction agent
`src/lib/ai/extract-graph-data.ts`:
```ts
import { generateObject } from "ai";
import { getModelInstance } from "./provider";
import { EXTRACTION_MODEL_ID } from "./models";
import { ExtractionResultSchema, type ExtractionResult } from "./extraction-schema";

const SYSTEM_PROMPT = `You are an information extraction engine. Given a piece of text, extract:
1. Every distinct real-world entity mentioned (people, organizations, locations, concepts, events, products).
2. Every relationship stated or clearly implied between two of those entities.

Rules:
- Only extract what is explicitly supported by the text. Do not invent facts.
- Use short, consistent entity names (e.g. always "Marie Curie", not sometimes "Curie" and sometimes "Marie").
- Relationship labels must be short, uppercase, and directional (e.g. "WORKS_AT", "FOUNDED", "LOCATED_IN").
- If the text contains no extractable entities or relationships, return empty arrays. Do not fabricate content to fill the schema.`;

export async function extractGraphData(chunkText: string): Promise<ExtractionResult> {
  const model = getModelInstance(EXTRACTION_MODEL_ID);

  const { object } = await generateObject({
    model,
    schema: ExtractionResultSchema,
    system: SYSTEM_PROMPT,
    prompt: `Text:\n"""\n${chunkText}\n"""`,
  });

  return object;
}
```

Note the explicit "do not invent facts" and "return empty arrays" instructions in the system prompt. Without them, smaller free models especially tend to hallucinate at least one plausible-sounding entity per chunk just to have something to return — a subtle failure mode that is easy to miss in testing but pollutes a real knowledge graph badly over many documents.

## 4. Persistence: de-duplication and provenance linking
This is the part that turns "one chunk's extraction result" into "durable additions to a shared graph."

`src/lib/ai/persist-graph-data.ts`:
```ts
import { db } from "@/lib/db";
import type { ExtractionResult } from "./extraction-schema";

export async function persistGraphData(chunkId: string, result: ExtractionResult) {
  const nameToNodeId = new Map<string, string>();

  for (const node of result.nodes) {
    const saved = await db.node.upsert({
      where: { name_type: { name: node.name, type: node.type } },
      update: {
        description: node.description ?? undefined,
      },
      create: {
        name: node.name,
        type: node.type,
        description: node.description,
      },
    });

    nameToNodeId.set(node.name, saved.id);

    await db.nodeSourceChunk.upsert({
      where: { nodeId_chunkId: { nodeId: saved.id, chunkId } },
      update: {},
      create: { nodeId: saved.id, chunkId },
    });
  }

  for (const edge of result.edges) {
    const sourceId = nameToNodeId.get(edge.sourceName);
    const targetId = nameToNodeId.get(edge.targetName);

    if (!sourceId || !targetId) {
      console.warn(
        `Skipping edge "${edge.label}": unresolved node name (${edge.sourceName} -> ${edge.targetName}). ` +
        `This can happen if the model referenced an entity it didn't also list in "nodes".`
      );
      continue;
    }

    const savedEdge = await db.edge.upsert({
      where: {
        sourceId_targetId_label: { sourceId, targetId, label: edge.label },
      },
      update: {},
      create: { sourceId, targetId, label: edge.label },
    });

    await db.edgeSourceChunk.upsert({
      where: { edgeId_chunkId: { edgeId: savedEdge.id, chunkId } },
      update: {},
      create: { edgeId: savedEdge.id, chunkId },
    });
  }
}
```

Two important design choices here:
- `Node.upsert` on the `name_type` unique key (from Part 2's schema) is exactly what prevents duplicate "Alice" nodes when Alice is mentioned across multiple chunks or documents — every mention resolves to the same row.
- Skipping edges with unresolved node names rather than throwing: a slightly imperfect model output (an edge mentioning an entity that didn't quite make it into the `nodes` array) should degrade gracefully, not crash the whole ingestion pipeline for the entire document.

## 5. Wiring extraction into the ingestion flow
Update the server action from Part 3 to run extraction on every chunk right after it's embedded, then flip the document to `DONE`.

`src/actions/ingest-document.ts` (add this import and the loop body change):
```ts
import { extractGraphData } from "@/lib/ai/extract-graph-data";
import { persistGraphData } from "@/lib/ai/persist-graph-data";

// ... inside the existing for (const chunk of chunks) loop, after setChunkEmbedding:
const extraction = await extractGraphData(chunk.content);
await persistGraphData(created.id, extraction);

// ... after the loop, replace the "EXTRACTING" status update with:
await db.document.update({
  where: { id: document.id },
  data: { status: "DONE" },
});
```

Why extraction runs synchronously inside the same server action rather than as a background job: for a beginner-friendly PoC without an external queue service, doing it inline keeps the architecture simple and free-tier friendly. The tradeoff is the upload request takes longer to resolve for large documents. Part 7 (Polish) adds a proper pending/processing UI state so this tradeoff feels intentional rather than like a bug, and Appendix A's roadmap notes background queues (e.g. Inngest, Vercel Cron) as the natural next upgrade.

## 6. A standalone extraction test action (optional but recommended)
Testing extraction against a single hardcoded string, without needing a real file upload, saves a lot of iteration time when tuning prompts or comparing models.

`src/actions/extract-graph.ts`:
```ts
"use server";

import { extractGraphData } from "@/lib/ai/extract-graph-data";

export async function testExtraction(text: string) {
  return extractGraphData(text);
}
```

## 7. Verification checkpoint
Re-upload the same small test file from Part 3's checkpoint ("Marie Curie discovered polonium while working in Paris."). Confirm in Prisma Studio (`npx prisma studio`):
1. `nodes` table has rows like "Marie Curie" (PERSON), "polonium" (CONCEPT or PRODUCT), "Paris" (LOCATION).
2. `edges` table has a row connecting Marie Curie to polonium with a label like "DISCOVERED", and possibly Marie Curie to Paris with "LOCATED_IN" or similar.
3. `node_source_chunks` and `edge_source_chunks` each have rows linking those nodes/edges back to the chunk you just created.
4. The document row's status is now `DONE`.

Then upload a second, unrelated file that also mentions "Marie Curie" by name. Confirm no duplicate "Marie Curie" node is created — the existing one gains an additional `node_source_chunks` row instead.

Next: Part 5 - Graph Visualization (react-force-graph).
