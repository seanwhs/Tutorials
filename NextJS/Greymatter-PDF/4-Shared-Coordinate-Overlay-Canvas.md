# Part 4: The Shared Coordinate Overlay Canvas

*(Phase 2 — Building the Interactive Annotation Engine)*

## Why this part exists

Phase 1 (Parts 1–3) gave us a fast, secure PDF viewer. Now we begin Phase 2: letting users actually draw on top of what they see — highlights, freehand lines, shapes — exactly like Adobe Acrobat or Apryse's annotation tools.

Analogy: imagine the rendered PDF page (the canvas from Part 2) is a valuable painting hanging in a gallery. You would never let visitors draw directly on the painting. Instead, galleries sometimes place a transparent sheet of glass or acrylic in front of artwork, and in some interactive exhibits, visitors can draw on that glass with a dry-erase marker without ever touching the actual painting underneath. Our "glass sheet" is a separate HTML element — an SVG layer — positioned exactly on top of each `PdfPageCanvas` from Part 2, pixel-for-pixel.

The hard problem this part solves is not "how do we draw a line" (that is easy) — it is "how do we make sure a highlight drawn at 100% zoom still appears in exactly the right spot when the user zooms to 150%, or when they view the same document on a phone with a different screen size." This requires translating between two different coordinate systems, which we define carefully below before writing any code.

---

## 4.1 Two coordinate systems: document space vs. screen space

**The Concept:** think of "document space" as the PDF's own permanent, unchanging ruler — every PDF page has fixed dimensions defined in points (a physical unit, roughly 1/72 of an inch) that never change no matter how you view the file. "Screen space" is the temporary, ever-changing pixel grid of the user's current browser window — it changes every time they zoom, resize the window, or view on a different device.

If we saved an annotation's position using screen space pixels (e.g. "the highlight is at pixel 340, 220"), it would appear in the wrong place the moment the user zoomed in or out, because pixel 340,220 means something different at every zoom level. Instead, we must convert every annotation into document space coordinates at the moment it is drawn, and convert back to screen space only at the moment of rendering. This conversion is the single most important concept in this Part.

We define document space coordinates using a normalized rectangle format: `[x, y, w, h]`, where:
- **x, y**: the top-left corner of the annotation, expressed as a fraction (0 to 1) of the page's total width and height respectively
- **w, h**: the width and height of the annotation, also expressed as fractions (0 to 1) of the page's total width and height

Using fractions (0 to 1) rather than raw PDF points has a deliberate advantage: it makes the math for converting to/from screen space pixels a single multiplication, regardless of the page's actual point dimensions or the current zoom level — we will see this exact formula in Section 4.3.

---

## 4.2 Why SVG, and why a second canvas is not enough

**The Concept:** you might ask why we do not just draw annotations directly onto the same `<canvas>` element from Part 2 that pdf.js already renders into. Two reasons:

1. **Re-rendering:** a `<canvas>` is like a chalkboard — once you draw something, the canvas has no memory of it as a distinct "thing"; it is just pixels. If the user needs to select, move, resize, or delete a specific annotation later (which real annotation tools always support), you would need to manually track and redraw everything from scratch. An **SVG** (Scalable Vector Graphics), by contrast, is a live document made of individual, addressable elements — each annotation is its own `<rect>`, `<path>`, or `<line>` element that the browser remembers and lets us individually select, move, or delete, similar to how shapes work in a vector drawing tool like Figma or Illustrator.
2. **Resolution independence:** SVG shapes are defined mathematically (points, curves) rather than as fixed pixels, so they stay perfectly crisp at any zoom level with zero extra rendering work from us — the browser handles the redraw automatically when the SVG's viewBox or containing size changes.

So our final per-page layering, front to back, is: **SVG annotation layer** (top, interactive) → **PdfPageCanvas** from Part 2 (bottom, the rendered PDF page). We achieve this with standard CSS absolute positioning inside a shared, relatively-positioned wrapper.

---

## 4.3 The coordinate conversion formulas

**The Concept:** with our document space defined as fractions (0 to 1) of page width/height, converting to and from screen space becomes simple multiplication and division, using values we already have from Part 2's `PdfPageCanvas` (specifically, its `widthCss` and `heightCss`).

**Screen space → document space** (used when the user draws something new):
```
documentX = screenX / pageWidthCss
documentY = screenY / pageHeightCss
documentW = screenW / pageWidthCss
documentH = screenH / pageHeightCss
```

**Document space → screen space** (used when rendering an existing annotation):
```
screenX = documentX * currentPageWidthCss
screenY = documentY * currentPageHeightCss
screenW = documentW * currentPageWidthCss
screenH = documentH * currentPageHeightCss
```

Because `currentPageWidthCss` changes whenever the user zooms (recall from Part 2 that `widthCss`/`heightCss` are derived from the `scale` value passed to `renderPage`), simply re-running this second formula with the new width/height automatically repositions every annotation correctly at the new zoom level — no manual adjustment logic required anywhere else in our codebase.

---

## Step 1: Define shared annotation types and conversion utilities

**The Target:** `src/types/annotation.ts` and `src/lib/pdf/coordinates.ts`

**The Concept:** just like Part 2's `pdf-worker.ts` types created a shared contract between two pieces of code, here we define the shape of an "annotation" once, in one place, so every component (the drawing layer, the toolbar, the future database sync in Part 5) agrees on the exact same structure.

**The Implementation:**

### `src/types/annotation.ts`

```typescript
// The kinds of annotations Greymatter PDF supports. We start with a small
// set in this Part and can extend this union later without breaking
// existing code, since TypeScript will flag every place that needs to
// handle a new kind.
export type AnnotationKind = "highlight" | "rectangle" | "freehand";

// A rectangle in document space: all four values are fractions (0 to 1)
// of the page's total width/height, NOT raw pixels. See Section 4.1 for
// why this matters.
export interface DocumentSpaceRect {
  x: number;
  y: number;
  w: number;
  h: number;
}

// A single point in document space, used for freehand line paths where a
// simple bounding rectangle is not enough to describe the shape drawn.
export interface DocumentSpacePoint {
  x: number;
  y: number;
}

export interface BaseAnnotation {
  id: string;
  pageNumber: number; // which page this annotation belongs to, 1-indexed
  kind: AnnotationKind;
  color: string; // CSS color string, e.g. "#FFFF00"
  createdAt: number; // Unix timestamp in milliseconds
}

export interface HighlightAnnotation extends BaseAnnotation {
  kind: "highlight";
  rect: DocumentSpaceRect;
}

export interface RectangleAnnotation extends BaseAnnotation {
  kind: "rectangle";
  rect: DocumentSpaceRect;
  strokeWidth: number; // in document-space fraction units, same idea as rect
}

export interface FreehandAnnotation extends BaseAnnotation {
  kind: "freehand";
  points: DocumentSpacePoint[]; // an ordered path of points, document space
  strokeWidth: number;
}

// The union of every annotation type -- this is what most of our code
// will actually reference, letting TypeScript narrow to the specific kind
// via the `kind` discriminant field when needed.
export type Annotation =
  | HighlightAnnotation
  | RectangleAnnotation
  | FreehandAnnotation;
```

### `src/lib/pdf/coordinates.ts`

```typescript
import type { DocumentSpacePoint, DocumentSpaceRect } from "@/types/annotation";

// Converts a rectangle measured in on-screen CSS pixels (relative to the
// top-left of the page's canvas element) into document space fractions,
// using the exact formulas derived in Section 4.3. Called the moment a
// user finishes drawing a new annotation.
export function screenRectToDocumentSpace(
  screenRect: { x: number; y: number; w: number; h: number },
  pageWidthCss: number,
  pageHeightCss: number
): DocumentSpaceRect {
  return {
    x: screenRect.x / pageWidthCss,
    y: screenRect.y / pageHeightCss,
    w: screenRect.w / pageWidthCss,
    h: screenRect.h / pageHeightCss,
  };
}

// The inverse operation: converts a document space rectangle back into
// on-screen CSS pixels for the CURRENT page size, whatever that may be at
// the current zoom level. Called every time we render an existing
// annotation.
export function documentSpaceRectToScreen(
  docRect: DocumentSpaceRect,
  pageWidthCss: number,
  pageHeightCss: number
): { x: number; y: number; w: number; h: number } {
  return {
    x: docRect.x * pageWidthCss,
    y: docRect.y * pageHeightCss,
    w: docRect.w * pageWidthCss,
    h: docRect.h * pageHeightCss,
  };
}

// Same idea as the rect converters above, but for a single point -- used
// for freehand drawing, where we convert every point in the user's mouse
// path individually as they draw.
export function screenPointToDocumentSpace(
  screenPoint: { x: number; y: number },
  pageWidthCss: number,
  pageHeightCss: number
): DocumentSpacePoint {
  return {
    x: screenPoint.x / pageWidthCss,
    y: screenPoint.y / pageHeightCss,
  };
}

export function documentSpacePointToScreen(
  docPoint: DocumentSpacePoint,
  pageWidthCss: number,
  pageHeightCss: number
): { x: number; y: number } {
  return {
    x: docPoint.x * pageWidthCss,
    y: docPoint.y * pageHeightCss,
  };
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## Step 2: Build the annotation store (local state management)

**The Target:** `src/lib/pdf/use-annotations.ts`

**The Concept:** multiple components need to read and update the same list of annotations for a document — the drawing layer that creates new ones, a future toolbar that lets users pick colors, and eventually (Part 5) a sync mechanism that saves them to a database. We centralize this in one custom hook, similar in spirit to Part 2's `usePdfWorker`, so there is exactly one place that owns "the current list of annotations for this document."

**The Implementation:**

### `src/lib/pdf/use-annotations.ts`

```typescript
"use client";

import { useState, useCallback } from "react";
import type { Annotation } from "@/types/annotation";

// Generates a reasonably unique ID for a new annotation. A real production
// system might use a proper UUID library, but this is sufficient for
// client-generated, not-yet-persisted IDs -- Part 5 discusses how these
// IDs interact with server-assigned IDs once annotations are saved.
function createAnnotationId(): string {
  return `annotation-${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

export function useAnnotations(initialAnnotations: Annotation[] = []) {
  const [annotations, setAnnotations] = useState<Annotation[]>(
    initialAnnotations
  );

  // Adds a brand new annotation to the list. The caller supplies every
  // field except `id` and `createdAt`, which this hook is responsible for
  // generating consistently.
  const addAnnotation = useCallback(
    (annotation: Omit<Annotation, "id" | "createdAt">) => {
      const newAnnotation = {
        ...annotation,
        id: createAnnotationId(),
        createdAt: Date.now(),
      } as Annotation;

      setAnnotations((current) => [...current, newAnnotation]);
      return newAnnotation;
    },
    []
  );

  const removeAnnotation = useCallback((id: string) => {
    setAnnotations((current) => current.filter((a) => a.id !== id));
  }, []);

  const getAnnotationsForPage = useCallback(
    (pageNumber: number) => {
      return annotations.filter((a) => a.pageNumber === pageNumber);
    },
    [annotations]
  );

  return {
    annotations,
    addAnnotation,
    removeAnnotation,
    getAnnotationsForPage,
  };
}
```

Note: we use `useCallback` and `useState` here deliberately, following the same reasoning from Part 2 — this is a shared hook whose returned functions are consumed by other components' effect dependency arrays, so stable references still matter here even with the React Compiler active. The next Step, however, is where we finally see the Compiler doing real work for us, inside the actual rendering component.

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## Step 3: Build the annotation overlay component (SVG layer)

**The Target:** `src/components/annotations/AnnotationOverlay.tsx`

**The Concept:** this component renders the "glass sheet" from our analogy — an absolutely-positioned SVG element, exactly matching the dimensions of its corresponding `PdfPageCanvas`, that (a) draws every existing annotation for the current page, converting each from document space to screen space using Section 4.3's formulas, and (b) listens for mouse events to let the user draw a brand new rectangle-based annotation (we cover freehand paths in a later part).

Here is where the React Compiler (enabled back in Part 1) earns its keep: this component recalculates screen coordinates on every single mouse-move event while the user is dragging out a new highlight — potentially dozens of times per second. Under the older, manual-optimization style of React, a careful engineer would wrap the coordinate math in `useMemo` and the event handlers in `useCallback` to avoid re-rendering child elements unnecessarily on every mouse pixel of movement. With the Compiler active, we simply write plain, readable code, and the Compiler's build-time analysis inserts the equivalent memoization automatically wherever it determines it is safe and beneficial — so the component below contains **zero manual `useMemo`/`useCallback` calls**, by design.

**The Implementation:**

### `src/components/annotations/AnnotationOverlay.tsx`

```typescript
"use client";

import { useState } from "react";
import type { Annotation } from "@/types/annotation";
import {
  documentSpaceRectToScreen,
  screenRectToDocumentSpace,
} from "@/lib/pdf/coordinates";

interface AnnotationOverlayProps {
  pageNumber: number;
  pageWidthCss: number;
  pageHeightCss: number;
  annotations: Annotation[];
  activeColor: string;
  isDrawingEnabled: boolean;
  onCreateAnnotation: (
    annotation: Omit<Annotation, "id" | "createdAt">
  ) => void;
}

// A small local type describing an in-progress drag, in raw screen pixels
// relative to the overlay's own top-left corner. This never leaves this
// component -- the moment the drag finishes, we convert it to document
// space and hand it upward via onCreateAnnotation.
interface DraftRect {
  startX: number;
  startY: number;
  currentX: number;
  currentY: number;
}

export function AnnotationOverlay({
  pageNumber,
  pageWidthCss,
  pageHeightCss,
  annotations,
  activeColor,
  isDrawingEnabled,
  onCreateAnnotation,
}: AnnotationOverlayProps) {
  const [draftRect, setDraftRect] = useState<DraftRect | null>(null);

  // Notice there is no useCallback wrapping these handlers, and no
  // useMemo wrapping the coordinate math below in the JSX -- the React
  // Compiler (Part 1) handles the equivalent optimization automatically
  // at build time, which is precisely why Part 1 enabled it before we
  // ever needed it here.
  function handlePointerDown(event: React.PointerEvent<SVGSVGElement>) {
    if (!isDrawingEnabled) return;

    const svgBounds = event.currentTarget.getBoundingClientRect();
    const startX = event.clientX - svgBounds.left;
    const startY = event.clientY - svgBounds.top;

    setDraftRect({ startX, startY, currentX: startX, currentY: startY });
    // Capture the pointer so we keep receiving move/up events even if the
    // cursor briefly leaves the SVG's bounds mid-drag.
    event.currentTarget.setPointerCapture(event.pointerId);
  }

  function handlePointerMove(event: React.PointerEvent<SVGSVGElement>) {
    if (!draftRect) return;

    const svgBounds = event.currentTarget.getBoundingClientRect();
    const currentX = event.clientX - svgBounds.left;
    const currentY = event.clientY - svgBounds.top;

    setDraftRect((current) =>
      current ? { ...current, currentX, currentY } : null
    );
  }

  function handlePointerUp() {
    if (!draftRect) return;

    // Normalize the drag into a top-left-origin rectangle regardless of
    // which direction the user dragged (e.g. dragging up-and-left would
    // otherwise produce a negative width/height).
    const x = Math.min(draftRect.startX, draftRect.currentX);
    const y = Math.min(draftRect.startY, draftRect.currentY);
    const w = Math.abs(draftRect.currentX - draftRect.startX);
    const h = Math.abs(draftRect.currentY - draftRect.startY);

    setDraftRect(null);

    // Ignore accidental clicks that produce a near-zero-sized rectangle.
    if (w < 4 || h < 4) return;

    const documentRect = screenRectToDocumentSpace(
      { x, y, w, h },
      pageWidthCss,
      pageHeightCss
    );

    onCreateAnnotation({
      pageNumber,
      kind: "highlight",
      color: activeColor,
      rect: documentRect,
    });
  }

  return (
    <svg
      // Absolute positioning inside the shared wrapper (built in Step 4)
      // places this SVG exactly on top of the PdfPageCanvas beneath it.
      className="absolute left-0 top-0"
      width={pageWidthCss}
      height={pageHeightCss}
      style={{
        // Only intercept pointer events while actively drawing; otherwise
        // let clicks pass through to whatever is beneath (e.g. text
        // selection in a future Part).
        pointerEvents: isDrawingEnabled ? "auto" : "none",
        cursor: isDrawingEnabled ? "crosshair" : "default",
      }}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
    >
      {/* Render every already-saved annotation for this page, converting
          each from document space to the CURRENT screen size on every
          render -- this is what makes annotations automatically reposition
          correctly whenever pageWidthCss/pageHeightCss change due to
          zooming, with no special-case zoom-handling code required. */}
      {annotations
        .filter((a) => a.pageNumber === pageNumber && a.kind === "highlight")
        .map((annotation) => {
          if (annotation.kind !== "highlight") return null;
          const screenRect = documentSpaceRectToScreen(
            annotation.rect,
            pageWidthCss,
            pageHeightCss
          );
          return (
            <rect
              key={annotation.id}
              x={screenRect.x}
              y={screenRect.y}
              width={screenRect.w}
              height={screenRect.h}
              fill={annotation.color}
              fillOpacity={0.4}
            />
          );
        })}

      {/* While the user is actively dragging, render a live preview
          rectangle in raw screen coordinates -- this one is NOT yet
          converted to document space, since it does not exist as a saved
          annotation until handlePointerUp fires. */}
      {draftRect && (
        <rect
          x={Math.min(draftRect.startX, draftRect.currentX)}
          y={Math.min(draftRect.startY, draftRect.currentY)}
          width={Math.abs(draftRect.currentX - draftRect.startX)}
          height={Math.abs(draftRect.currentY - draftRect.startY)}
          fill={activeColor}
          fillOpacity={0.25}
          stroke={activeColor}
          strokeDasharray="4 2"
        />
      )}
    </svg>
  );
}
```

**The Verification:** this component needs to be wired into the page layout to be testable in a browser — continue to Step 4.

---

## Step 4: Update PdfPageCanvas to host the overlay

**The Target:** update `src/components/viewer/PdfPageCanvas.tsx` from Part 2

**The Concept:** recall from Part 2 that `PdfPageCanvas` renders a single canvas element wrapped in a relatively-positioned div. We now add the `AnnotationOverlay` as a sibling to that canvas, inside the same wrapper, so its absolute positioning lines up exactly.

**The Implementation:**

### `src/components/viewer/PdfPageCanvas.tsx` (replaces the Part 2 version)

```typescript
"use client";

import { useEffect, useRef, useState } from "react";
import { usePdfWorker } from "@/lib/pdf/use-pdf-worker";
import { AnnotationOverlay } from "@/components/annotations/AnnotationOverlay";
import type { Annotation } from "@/types/annotation";

interface PdfPageCanvasProps {
  pageNumber: number;
  scale: number;
  renderPage: ReturnType<typeof usePdfWorker>["renderPage"];
  annotations: Annotation[];
  activeColor: string;
  isDrawingEnabled: boolean;
  onCreateAnnotation: (
    annotation: Omit<Annotation, "id" | "createdAt">
  ) => void;
}

export function PdfPageCanvas({
  pageNumber,
  scale,
  renderPage,
  annotations,
  activeColor,
  isDrawingEnabled,
  onCreateAnnotation,
}: PdfPageCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [isRendering, setIsRendering] = useState(true);
  const [error, setError] = useState<string | null>(null);
  // We now track the page's current CSS dimensions in component state,
  // because A nnotationOverlay needs these exact values to convert
  // document space coordinates into on-screen pixels (Section 4.3). Prior
  // to this Part, PdfPageCanvas set canvas.style.width/height directly and
  // never needed to expose those numbers to anything else.
  const [pageSizeCss, setPageSizeCss] = useState<{
    width: number;
    height: number;
  } | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function draw() {
      setIsRendering(true);
      setError(null);
      try {
        const devicePixelRatio = window.devicePixelRatio || 1;
        const result = await renderPage(pageNumber, scale, devicePixelRatio);

        if (cancelled) return;

        const canvas = canvasRef.current;
        if (!canvas) return;

        canvas.width = result.bitmap.width;
        canvas.height = result.bitmap.height;
        canvas.style.width = `${result.widthCss}px`;
        canvas.style.height = `${result.heightCss}px`;

        const context = canvas.getContext("2d");
        if (!context) {
          throw new Error("Could not acquire a 2D context for the canvas.");
        }
        context.drawImage(result.bitmap, 0, 0);
        result.bitmap.close();

        // Publish the page's CSS dimensions so AnnotationOverlay (rendered
        // as a sibling below) can size and position itself identically.
        setPageSizeCss({ width: result.widthCss, height: result.heightCss });
      } catch (caughtError) {
        if (!cancelled) {
          setError(
            caughtError instanceof Error
              ? caughtError.message
              : "Failed to render page."
          );
        }
      } finally {
        if (!cancelled) setIsRendering(false);
      }
    }

    draw();

    return () => {
      cancelled = true;
    };
  }, [pageNumber, scale, renderPage]);

  return (
    <div className="relative mb-4 flex justify-center">
      {isRendering && (
        <div className="absolute inset-0 flex items-center justify-center bg-gray-100 text-sm text-gray-500">
          Rendering page {pageNumber}...
        </div>
      )}
      {error && (
        <div className="absolute inset-0 flex items-center justify-center bg-red-50 text-sm text-red-600">
          Error on page {pageNumber}: {error}
        </div>
      )}
      {/* This inner wrapper is the shared "relatively positioned parent"
          that both the canvas and the SVG overlay position themselves
          against -- this is what makes the overlay line up pixel-for-pixel
          with the rendered page beneath it. */}
      <div className="relative">
        <canvas
          ref={canvasRef}
          className="border border-gray-200 shadow-sm"
          aria-label={`PDF page ${pageNumber}`}
        />
        {pageSizeCss && (
          <AnnotationOverlay
            pageNumber={pageNumber}
            pageWidthCss={pageSizeCss.width}
            pageHeightCss={pageSizeCss.height}
            annotations={annotations}
            activeColor={activeColor}
            isDrawingEnabled={isDrawingEnabled}
            onCreateAnnotation={onCreateAnnotation}
          />
        )}
      </div>
    </div>
  );
}
```

---

## Step 5: A minimal toolbar and updated PdfViewer

**The Target:** `src/components/annotations/AnnotationToolbar.tsx` and an updated `src/components/viewer/PdfViewer.tsx`

**The Concept:** the user needs a way to toggle "drawing mode" on/off and pick a highlight color. We keep this toolbar deliberately simple in this Part — a proper multi-tool toolbar (freehand, shapes, eraser) is refined further in later parts, but the wiring pattern established here does not change.

**The Implementation:**

### `src/components/annotations/AnnotationToolbar.tsx`

```typescript
"use client";

const COLOR_OPTIONS = ["#FFFF00", "#00FF00", "#FF69B4", "#87CEEB"];

interface AnnotationToolbarProps {
  isDrawingEnabled: boolean;
  onToggleDrawing: () => void;
  activeColor: string;
  onSelectColor: (color: string) => void;
}

export function AnnotationToolbar({
  isDrawingEnabled,
  onToggleDrawing,
  activeColor,
  onSelectColor,
}: AnnotationToolbarProps) {
  return (
    <div className="flex items-center gap-3 border-b border-gray-200 bg-white p-3">
      <button
        onClick={onToggleDrawing}
        className={`rounded px-3 py-1.5 text-sm font-medium ${
          isDrawingEnabled
            ? "bg-blue-600 text-white"
            : "bg-gray-100 text-gray-700"
        }`}
      >
        {isDrawingEnabled ? "Drawing: On" : "Drawing: Off"}
      </button>
      <div className="flex items-center gap-1.5">
        {COLOR_OPTIONS.map((color) => (
          <button
            key={color}
            onClick={() => onSelectColor(color)}
            aria-label={`Select color ${color}`}
            className="h-6 w-6 rounded-full border-2"
            style={{
              backgroundColor: color,
              borderColor: activeColor === color ? "#111827" : "transparent",
            }}
          />
        ))}
      </div>
    </div>
  );
}
```

### `src/components/viewer/PdfViewer.tsx` (replaces the Part 2/Part 3 version)

```typescript
"use client";

import { useEffect, useState } from "react";
import { usePdfWorker } from "@/lib/pdf/use-pdf-worker";
import { useAnnotations } from "@/lib/pdf/use-annotations";
import { PdfPageCanvas } from "@/components/viewer/PdfPageCanvas";
import { AnnotationToolbar } from "@/components/annotations/AnnotationToolbar";

interface PdfViewerProps {
  fileUrl: string;
}

export function PdfViewer({ fileUrl }: PdfViewerProps) {
  const { loadDocument, renderPage } = usePdfWorker();
  const [numPages, setNumPages] = useState<number | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [scale] = useState(1.25);

  // New in this Part: the annotation store and drawing-mode UI state.
  const { annotations, addAnnotation, getAnnotationsForPage } =
    useAnnotations();
  const [isDrawingEnabled, setIsDrawingEnabled] = useState(false);
  const [activeColor, setActiveColor] = useState("#FFFF00");

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        const response = await fetch(fileUrl);
        if (!response.ok) {
          throw new Error(
            `Failed to fetch PDF: ${response.status} ${response.statusText}`
          );
        }
        const arrayBuffer = await response.arrayBuffer();

        if (cancelled) return;

        const pages = await loadDocument(arrayBuffer);
        if (!cancelled) setNumPages(pages);
      } catch (error) {
        if (!cancelled) {
          setLoadError(
            error instanceof Error ? error.message : "Failed to load PDF."
          );
        }
      }
    }

    load();

    return () => {
      cancelled = true;
    };
  }, [fileUrl, loadDocument]);

  if (loadError) {
    return (
      <div className="p-4 text-sm text-red-600">
        Could not load document: {loadError}
      </div>
    );
  }

  if (numPages === null) {
    return <div className="p-4 text-sm text-gray-500">Loading document...</div>;
  }

  return (
    <div className="flex h-full flex-col">
      <AnnotationToolbar
        isDrawingEnabled={isDrawingEnabled}
        onToggleDrawing={() => setIsDrawingEnabled((v) => !v)}
        activeColor={activeColor}
        onSelectColor={setActiveColor}
      />
      <div className="flex flex-1 flex-col items-center overflow-y-auto p-4">
        {Array.from({ length: numPages }, (_, index) => index + 1).map(
          (pageNumber) => (
            <PdfPageCanvas
              key={pageNumber}
              pageNumber={pageNumber}
              scale={scale}
              renderPage={renderPage}
              annotations={annotations}
              activeColor={activeColor}
              isDrawingEnabled={isDrawingEnabled}
              onCreateAnnotation={addAnnotation}
            />
          )
        )}
      </div>
    </div>
  );
}
```

Note that `getAnnotationsForPage` from `useAnnotations` is unused here — `PdfPageCanvas`/`AnnotationOverlay` currently filter the full annotations array by `pageNumber` internally instead. Both approaches work; we pass the full array down for simplicity in this Part, and `getAnnotationsForPage` remains available for Part 5, where we will likely want per-page filtering to happen closer to the data-fetching layer instead.

---

## Step 6: Full verification

**The Target:** prove that drawing, positioning, and zoom-repositioning all work correctly together.

**Step 1** — start everything:

```bash
docker compose up -d
npm run dev
```

**Step 2** — sign in and open the viewer (from Part 3):

Visit http://localhost:3000/dev-sign-in, which redirects to `/viewer/sample`.

**Step 3** — confirm the toolbar renders:

You should see a toolbar at the top with a "Drawing: Off" button and four colored circles. Confirm clicking a color circle visibly highlights it with a dark border, indicating it is selected.

**Step 4** — enable drawing mode and draw a highlight:

Click the "Drawing: Off" button — it should switch to "Drawing: On" with a blue background. Move your mouse over any PDF page — the cursor should change to a crosshair. Click and drag to draw a rectangle; you should see a live, dashed-border preview rectangle following your drag in your selected color. Release the mouse button — the preview should disappear and be replaced by a solid, semi-transparent highlight rectangle in the same position.

**Step 5** — confirm the highlight persists across re-renders:

Scroll away from the page you highlighted, then scroll back. The highlight rectangle should still be exactly where you drew it — this confirms the `annotations` array in `useAnnotations` correctly persists in React state and `AnnotationOverlay` correctly re-renders it from document space coordinates.

**Step 6** — the critical test: confirm zoom-correctness.

This test proves the entire point of this Part's coordinate system design. Currently, our `scale` value is hardcoded to `1.25` with no UI control — to test zoom-repositioning without building a full zoom control yet, temporarily edit `src/components/viewer/PdfViewer.tsx` and change:

```typescript
const [scale] = useState(1.25);
```

to:

```typescript
const [scale] = useState(2.0);
```

Save the file (the dev server will hot-reload). Confirm your previously-drawn highlight is still positioned correctly over the exact same content on the page — proportionally in the same place relative to the text/images around it — even though the page itself is now rendered noticeably larger. This is the direct payoff of storing annotations as document space fractions (Section 4.1) rather than raw screen pixels: the exact same stored data automatically repositions correctly at any zoom level, with zero special-case code.

Once confirmed, revert the scale value back to 1.25 (a real zoom control arrives in a later part).

**Step 7** — confirm disabling drawing mode restores normal interaction:

Click "Drawing: On" to toggle it back to "Drawing: Off". Confirm your cursor returns to normal over the PDF pages, and that clicking/dragging no longer creates new highlights — this confirms the `pointerEvents: "none"` style correctly lets interactions pass through to whatever will live beneath the overlay in future parts (e.g. text selection).

---

## Part 4 Summary

By this point you have: a clearly defined two-coordinate-system model (document space vs. screen space) with conversion utilities that make zoom-correctness automatic; a shared `Annotation` type describing highlights, rectangles, and freehand paths (only highlights are drawable in this Part; Part 5+ can extend the toolbar to support the others using the same underlying types); a `useAnnotations` hook centralizing annotation state; an `AnnotationOverlay` SVG component that both renders existing annotations and captures new ones via pointer events, written with **zero manual `useMemo`/`useCallback`** thanks to the React Compiler enabled back in Part 1; and a working, end-to-end tested drawing experience layered precisely on top of Part 2's rendering pipeline and Part 3's secure delivery mechanism.

Critically, annotations currently live only in React state — refreshing the browser tab loses them completely. Part 5 solves this by designing a relational database schema for annotations (PostgreSQL + Prisma), building a synchronization pipeline that pushes local canvas events to Next.js Server Actions, and translating our web-native `[x, y, w, h]` document space format into the industry-standard XFDF XML schema used by enterprise tools like Adobe and Apryse — making Greymatter PDF's annotations portable and interoperable, not just locally functional.
