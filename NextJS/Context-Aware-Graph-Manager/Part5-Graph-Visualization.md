# Part 5: Graph Visualization (react-force-graph)

Goal: fetch nodes/edges from the database, render them as an interactive force-directed graph in the browser, and let the user click a node to see its context (description, type, and directly connected neighbors with provenance).

## 1. Why react-force-graph instead of hand-rolling a layout
Force-directed graph layout (nodes repel each other, edges act like springs, the whole system settles into a readable arrangement) is a nontrivial physics simulation. react-force-graph wraps the well-tested force-graph / d3-force engine and renders to an HTML canvas, giving you pan/zoom/drag and a stable layout algorithm for free. We use the 2D canvas variant (`react-force-graph-2d`, installed in Part 1) rather than the 3D/WebGL variant for lower resource use and simpler mental model — swapping to 3D later is a near drop-in change if you want it.

## 2. The graph data API route
`src/app/api/graph/route.ts`:
```ts
import { NextResponse } from "next/server";
import { db } from "@/lib/db";

export async function GET() {
  const nodes = await db.node.findMany({
    select: { id: true, name: true, type: true, description: true },
  });

  const edges = await db.edge.findMany({
    select: { id: true, sourceId: true, targetId: true, label: true },
  });

  return NextResponse.json({
    nodes: nodes.map((n) => ({
      id: n.id,
      name: n.name,
      type: n.type,
      description: n.description,
    })),
    links: edges.map((e) => ({
      id: e.id,
      source: e.sourceId,
      target: e.targetId,
      label: e.label,
    })),
  });
}
```

Why a Route Handler here instead of a Server Action: `react-force-graph-2d` expects a plain client-side fetch-able JSON payload it can re-fetch/refresh on demand (e.g. a manual "Refresh graph" button), and keeping graph data behind a normal GET endpoint also means it's trivially cacheable/inspectable in browser devtools while you're debugging layout issues — a Server Action call is harder to independently poke at.

## 3. Color-coding node types
`src/lib/graph-colors.ts`:
```ts
export const NODE_TYPE_COLORS: Record<string, string> = {
  PERSON: "#6366f1",
  ORGANIZATION: "#f59e0b",
  LOCATION: "#10b981",
  CONCEPT: "#ec4899",
  EVENT: "#3b82f6",
  PRODUCT: "#8b5cf6",
  OTHER: "#94a3b8",
};

export function colorForNodeType(type: string): string {
  return NODE_TYPE_COLORS[type] ?? NODE_TYPE_COLORS.OTHER;
}
```

These are raw hex strings, not Tailwind classes, because `react-force-graph-2d` paints directly to a `<canvas>` element — canvas drawing APIs need actual color values, they cannot read Tailwind's generated CSS classes. This is a common beginner trip-up: your Tailwind theme tokens from Part 1 style the surrounding UI chrome (buttons, panels), while the canvas itself needs this separate plain-JS color map.

## 4. The graph view component
`src/components/graph-view.tsx`:
```tsx
"use client";

import { useEffect, useState, useCallback, useRef } from "react";
import dynamic from "next/dynamic";
import { colorForNodeType } from "@/lib/graph-colors";
import { NodeContextPanel } from "@/components/node-context-panel";

const ForceGraph2D = dynamic(() => import("react-force-graph-2d"), { ssr: false });

interface GraphNode {
  id: string;
  name: string;
  type: string;
  description: string | null;
}

interface GraphLink {
  id: string;
  source: string;
  target: string;
  label: string;
}

interface GraphData {
  nodes: GraphNode[];
  links: GraphLink[];
}

export function GraphView() {
  const [data, setData] = useState<GraphData>({ nodes: [], links: [] });
  const [selectedNodeId, setSelectedNodeId] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const containerRef = useRef<HTMLDivElement>(null);

  const loadGraph = useCallback(async () => {
    setIsLoading(true);
    const res = await fetch("/api/graph");
    const json = (await res.json()) as GraphData;
    setData(json);
    setIsLoading(false);
  }, []);

  useEffect(() => {
    loadGraph();
  }, [loadGraph]);

  if (isLoading) {
    return <div className="p-8 text-sm text-muted-foreground">Loading graph...</div>;
  }

  if (data.nodes.length === 0) {
    return (
      <div className="p-8 text-sm text-muted-foreground">
        No graph data yet. Upload a document on the home page to get started.
      </div>
    );
  }

  return (
    <div className="relative h-[70vh] w-full" ref={containerRef}>
      <ForceGraph2D
        graphData={data}
        nodeId="id"
        nodeLabel={(node: any) => `${node.name} (${node.type})`}
        nodeColor={(node: any) => colorForNodeType(node.type)}
        linkLabel={(link: any) => link.label}
        linkDirectionalArrowLength={5}
        linkDirectionalArrowRelPos={1}
        linkCurvature={0.1}
        onNodeClick={(node: any) => setSelectedNodeId(node.id)}
        nodeRelSize={6}
      />

      {selectedNodeId && (
        <NodeContextPanel
          nodeId={selectedNodeId}
          allNodes={data.nodes}
          allLinks={data.links}
          onClose={() => setSelectedNodeId(null)}
        />
      )}
    </div>
  );
}
```

Why `next/dynamic` with `ssr: false`: `react-force-graph-2d` reaches for browser-only globals (`canvas`, `window`) at import time. Rendering it during Next.js's server-side render pass would crash the page. Dynamic-importing it client-only sidesteps that entirely — a pattern worth remembering any time you integrate a canvas/WebGL library into an App Router page.

## 5. The node context panel
This is what makes the graph "context-aware" in the UI, not just in the database: clicking a node surfaces its description, type, and its direct neighbors, all sourced from data already fetched — no extra round trip needed for this first level of context.

`src/components/node-context-panel.tsx`:
```tsx
"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { X } from "lucide-react";

interface GraphNode {
  id: string;
  name: string;
  type: string;
  description: string | null;
}

interface GraphLink {
  id: string;
  source: string;
  target: string;
  label: string;
}

interface Props {
  nodeId: string;
  allNodes: GraphNode[];
  allLinks: GraphLink[];
  onClose: () => void;
}

export function NodeContextPanel({ nodeId, allNodes, allLinks, onClose }: Props) {
  const node = allNodes.find((n) => n.id === nodeId);
  if (!node) return null;

  const neighborLinks = allLinks.filter(
    (l) => l.source === nodeId || l.target === nodeId
  );

  const neighbors = neighborLinks.map((link) => {
    const isOutgoing = link.source === nodeId;
    const otherId = isOutgoing ? link.target : link.source;
    const other = allNodes.find((n) => n.id === otherId);
    return { link, other, isOutgoing };
  });

  return (
    <Card className="absolute right-4 top-4 w-80 shadow-lg">
      <CardHeader className="flex flex-row items-start justify-between space-y-0">
        <div>
          <CardTitle className="text-base">{node.name}</CardTitle>
          <Badge variant="secondary" className="mt-1">{node.type}</Badge>
        </div>
        <Button variant="ghost" size="icon" onClick={onClose} className="h-6 w-6">
          <X className="h-4 w-4" />
        </Button>
      </CardHeader>
      <CardContent className="space-y-3">
        {node.description && (
          <p className="text-sm text-muted-foreground">{node.description}</p>
        )}

        <div>
          <p className="text-xs font-medium uppercase text-muted-foreground">
            Connections ({neighbors.length})
          </p>
          <ul className="mt-1 space-y-1">
            {neighbors.map(({ link, other, isOutgoing }) => (
              <li key={link.id} className="text-sm">
                {isOutgoing ? (
                  <span>
                    <span className="text-muted-foreground">{link.label} →</span>{" "}
                    {other?.name ?? "Unknown"}
                  </span>
                ) : (
                  <span>
                    {other?.name ?? "Unknown"}{" "}
                    <span className="text-muted-foreground">→ {link.label}</span>
                  </span>
                )}
              </li>
            ))}
            {neighbors.length === 0 && (
              <li className="text-sm text-muted-foreground">No connections yet.</li>
            )}
          </ul>
        </div>
      </CardContent>
    </Card>
  );
}
```

## 6. The graph page
`src/app/graph/page.tsx`:
```tsx
import { GraphView } from "@/components/graph-view";

export default function GraphPage() {
  return (
    <main className="mx-auto max-w-6xl px-6 py-10">
      <h1 className="text-xl font-semibold">Knowledge Graph</h1>
      <p className="mt-1 text-sm text-muted-foreground">
        Click any node to see its details and connections.
      </p>
      <div className="mt-6">
        <GraphView />
      </div>
    </main>
  );
}
```

Add a nav link from the home page (`src/app/page.tsx`) to `/graph` so the flow from upload to visualization is discoverable — a simple `next/link` "View Graph →" under the upload form is enough at this stage; Part 7 polishes navigation further.

## 7. Verification checkpoint
1. Run `npm run dev`, visit `/graph` after having ingested at least one document from Part 3/4.
2. Confirm nodes render as colored circles, edges render as directional arrows with labels visible on hover, and dragging a node updates the layout smoothly.
3. Click a node — confirm the context panel appears top-right with its type, description, and a correct list of connections (direction arrows matching the edge direction stored in the database).
4. Upload a second document that shares an entity with the first (e.g. mentions "Marie Curie" again) and refresh `/graph` — confirm it's still a single node with connections from both source documents, not two separate nodes.

Next: Part 6 - Search & Retrieval UI.
