# Part 7: Programmatic Stamping, Watermarking, and Form Flattening

*(Phase 3 — Server-Side Manipulation and Advanced Execution)*

## Why this part exists

Part 6 gave us page-level surgery: merge, split, extract, reorder. This Part goes one level deeper — editing the actual visual content of a page, not just rearranging whole pages. Three related capabilities, all built on the same underlying pdf-lib technique of drawing directly onto a page's content stream:

1. **Watermarking:** stamping a diagonal "CONFIDENTIAL" or "DRAFT" mark across every page, common in legal and business documents before final signoff.
2. **Form field injection:** filling in an interactive PDF form's fields programmatically (e.g. auto-filling a name and date on a template) rather than requiring a human to click into each field manually.
3. **Flattening:** converting an interactive form (fields a user could still click and edit) into permanent, non-editable content — required for long-term legal/compliance archiving, where a "final" signed document must never be alterable again.

Analogy: think of watermarking and form-filling as writing directly onto a physical printed page with a pen — the page's original printed content is untouched, but new ink is now permanently part of that sheet of paper. Flattening is the equivalent of laminating that page afterward: whatever was written or filled in becomes sealed as part of the page itself, and the sticky-note-like interactive form fields underneath are no longer separately editable.

---

## 7.1 Understanding PDF forms (AcroForms)

**The Concept:** a PDF can contain an **AcroForm** — a set of interactive fields (text boxes, checkboxes, dropdowns) layered on top of the static page content, similar in spirit to Part 4's annotation overlay concept, but built into the PDF format itself rather than something we invented. pdf-lib exposes these through `pdfDoc.getForm()`, which returns a Form object letting us look up individual fields by name and set their values.

---

## 7.2 Building the watermarking Server Action

**The Target:** `src/server-actions/watermark.ts`

**The Concept:** pdf-lib lets us draw text (and, with more setup, images) directly onto any page's content using `page.drawText()`, specifying position, size, rotation, and opacity. A watermark is simply text drawn at a diagonal angle, semi-transparent, positioned to span the visible page area, repeated identically on every page.

**The Implementation:**

### `src/server-actions/watermark.ts`

```typescript
"use server";

import { PDFDocument, StandardFonts, rgb, degrees } from "pdf-lib";
import { randomUUID } from "node:crypto";
import { getCurrentUserId } from "@/lib/auth/session";
import { createDocument } from "@/lib/db/documents";
import { putObjectBytes } from "@/lib/storage/s3-client";
import { loadDocumentBytes } from "@/server-actions/documents";

export async function addWatermark(
  documentId: string,
  watermarkText: string
) {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");

  const bytes = await loadDocumentBytes(documentId);
  const pdfDoc = await PDFDocument.load(bytes);

  // StandardFonts are 14 fonts guaranteed to be available in every PDF
  // reader without embedding any font data ourselves -- ideal for a
  // watermark, where we do not need a specific brand font, just clearly
  // legible text.
  const font = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

  const pages = pdfDoc.getPages();
  for (const page of pages) {
    const { width, height } = page.getSize();

    // Center the watermark roughly in the middle of the page, then rely
    // on the rotation below to angle it across the page diagonally --
    // this exact position/rotation combination is what produces the
    // familiar diagonal "CONFIDENTIAL"-style stamp seen in real
    // documents, rather than plain horizontal text.
    page.drawText(watermarkText, {
      x: width / 4,
      y: height / 2,
      size: 48,
      font,
      color: rgb(0.75, 0.1, 0.1), // a muted red, common for warnings
      opacity: 0.3, // semi-transparent so underlying page content stays legible
      rotate: degrees(45),
    });
  }

  const watermarkedBytes = await pdfDoc.save();
  const storageKey = `documents/${randomUUID()}.pdf`;
  await putObjectBytes(storageKey, watermarkedBytes, "application/pdf");

  return createDocument({
    ownerId: userId,
    storageKey,
    fileName: `watermarked-${watermarkText.toLowerCase().replace(/\s+/g, "-")}.pdf`,
  });
}
```

Why we create a new Document rather than modifying in place: identical reasoning to Part 6 — preserving the unwatermarked original as a separate, recoverable file, consistent with the "Save As" philosophy established there.

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## 7.3 Building the form field injection and flattening Server Actions

**The Target:** `src/server-actions/forms.ts`

**The Concept:** two related but distinct operations. **Filling** a form means setting field values programmatically — the fields remain interactive afterward, still clickable/editable by anyone who opens the file, exactly as if a human had typed into them. **Flattening** means permanently baking the current field values into the page's static content and removing the interactive fields entirely — afterward, the text is just part of the page, like any other printed content, and cannot be edited without the byte-level surgery techniques from Part 6.

**The Implementation:**

### `src/server-actions/forms.ts`

```typescript
"use server";

import { PDFDocument } from "pdf-lib";
import { randomUUID } from "node:crypto";
import { getCurrentUserId } from "@/lib/auth/session";
import { createDocument } from "@/lib/db/documents";
import { putObjectBytes } from "@/lib/storage/s3-client";
import { loadDocumentBytes } from "@/server-actions/documents";

// Lists every field name found in a document's AcroForm, along with its
// type -- useful for a future UI that needs to know what fields exist
// before offering the user a way to fill them in. Included now so the
// forms.ts module is complete and self-describing.
export async function listFormFields(documentId: string) {
  await getCurrentUserId(); // Server Actions still require a valid session
  const bytes = await loadDocumentBytes(documentId);
  const pdfDoc = await PDFDocument.load(bytes);
  const form = pdfDoc.getForm();

  return form.getFields().map((field) => ({
    name: field.getName(),
    type: field.constructor.name, // e.g. "PDFTextField", "PDFCheckBox"
  }));
}

// Fills in named text fields with given values. fieldValues is a simple
// { fieldName: value } map -- the caller looks up available field names
// via listFormFields above first. The form remains interactive after this
// call; use flattenForm (below) separately once the values are final.
export async function fillFormFields(
  documentId: string,
  fieldValues: Record<string, string>
) {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");

  const bytes = await loadDocumentBytes(documentId);
  const pdfDoc = await PDFDocument.load(bytes);
  const form = pdfDoc.getForm();

  for (const [fieldName, value] of Object.entries(fieldValues)) {
    try {
      // getTextField throws if the named field does not exist or is not
      // a text field -- we catch per-field so one typo'd field name does
      // not abort filling in every other correctly-named field.
      const field = form.getTextField(fieldName);
      field.setText(value);
    } catch (error) {
      console.warn(`Could not set field "${fieldName}":`, error);
    }
  }

  const filledBytes = await pdfDoc.save();
  const storageKey = `documents/${randomUUID()}.pdf`;
  await putObjectBytes(storageKey, filledBytes, "application/pdf");

  return createDocument({
    ownerId: userId,
    storageKey,
    fileName: "filled-form.pdf",
  });
}

// Permanently bakes the CURRENT values of every form field into the
// page's static content, then removes the interactive fields entirely.
// This is the "laminating" step from this Part's analogy -- afterward,
// there is no AcroForm left to inspect; form.getFields() on the result
// would return an empty array.
export async function flattenForm(documentId: string) {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");

  const bytes = await loadDocumentBytes(documentId);
  const pdfDoc = await PDFDocument.load(bytes);
  const form = pdfDoc.getForm();

  // pdf-lib's flatten() does exactly the two-step "bake in, then remove"
  // process described above, entirely internally -- this single call
  // handles walking every field, rendering its current appearance
  // directly onto the page content, and deleting the interactive
  // widgets.
  form.flatten();

  const flattenedBytes = await pdfDoc.save();
  const storageKey = `documents/${randomUUID()}.pdf`;
  await putObjectBytes(storageKey, flattenedBytes, "application/pdf");

  return createDocument({
    ownerId: userId,
    storageKey,
    fileName: "flattened.pdf",
  });
}

// A convenience action combining fillFormFields and flattenForm into one
// call -- the common real-world case of "fill in this template and lock
// it as final," e.g. generating a signed, non-editable copy of a
// completed application form.
export async function fillAndFlattenForm(
  documentId: string,
  fieldValues: Record<string, string>
) {
  const userId = await getCurrentUserId();
  if (!userId) throw new Error("Not authenticated.");

  const bytes = await loadDocumentBytes(documentId);
  const pdfDoc = await PDFDocument.load(bytes);
  const form = pdfDoc.getForm();

  for (const [fieldName, value] of Object.entries(fieldValues)) {
    try {
      const field = form.getTextField(fieldName);
      field.setText(value);
    } catch (error) {
      console.warn(`Could not set field "${fieldName}":`, error);
    }
  }

  form.flatten();

  const finalBytes = await pdfDoc.save();
  const storageKey = `documents/${randomUUID()}.pdf`;
  await putObjectBytes(storageKey, finalBytes, "application/pdf");

  return createDocument({
    ownerId: userId,
    storageKey,
    fileName: "final-signed.pdf",
  });
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

Expected output: no errors.

---

## Step 1: Add watermark and flatten buttons to DocumentManager

**The Target:** update `src/components/documents/DocumentManager.tsx` from Part 6

**The Concept:** we extend Part 6's existing document list UI with two more per-document actions, following the exact same handler pattern already established there.

**The Implementation** (add these handler functions and buttons to the existing Part 6 component):

### `src/components/documents/DocumentManager.tsx` (additions)

```typescript
// Add this import alongside the existing Part 6 imports:
import { addWatermark } from "@/server-actions/watermark";
import { flattenForm } from "@/server-actions/forms";

// Add this handler function inside the DocumentManager component, next to
// handleSplit and handleExtractFirstPage from Part 6:
function handleWatermark(documentId: string) {
  startTransition(async () => {
    try {
      const watermarked = await addWatermark(documentId, "CONFIDENTIAL");
      setDocuments((current) => [...current, watermarked]);
      setStatusMessage(`Watermarked into "${watermarked.fileName}".`);
    } catch (error) {
      setStatusMessage(
        error instanceof Error ? error.message : "Watermark failed."
      );
    }
  });
}

function handleFlatten(documentId: string) {
  startTransition(async () => {
    try {
      const flattened = await flattenForm(documentId);
      setDocuments((current) => [...current, flattened]);
      setStatusMessage(`Flattened into "${flattened.fileName}".`);
    } catch (error) {
      setStatusMessage(
        error instanceof Error ? error.message : "Flatten failed."
      );
    }
  });
}

// Add these two buttons inside the existing per-document <div className="flex gap-2">
// block, alongside the Part 6 "Split" and "Extract page 1" buttons:
```

```jsx
<button
  onClick={() => handleWatermark(doc.id)}
  disabled={isPending}
  className="text-xs text-blue-600 hover:underline disabled:opacity-50"
>
  Watermark
</button>
<button
  onClick={() => handleFlatten(doc.id)}
  disabled={isPending}
  className="text-xs text-blue-600 hover:underline disabled:opacity-50"
>
  Flatten form
</button>
```

**The Verification:** this needs the dev server running — continue to Step 2.

---

## Step 2: Full end-to-end verification

**Step 1** — start everything and sign in, as in prior Parts:

```bash
docker compose up -d
npm run dev
```

Visit http://localhost:3000/dev-sign-in, then http://localhost:3000/documents.

**Step 2** — confirm watermarking works:

Click "Watermark" next to any uploaded document. Confirm a new entry named `watermarked-confidential.pdf` appears. Open it in the viewer (`/viewer/<new-document-id>`) and confirm every page shows a diagonal, semi-transparent "CONFIDENTIAL" stamp, with the original page content still fully legible underneath it.

**Step 3** — confirm form filling and flattening (requires a PDF with an actual AcroForm):

Most everyday PDFs (scanned documents, exported reports) do **NOT** contain interactive form fields, so `listFormFields`/`fillFormFields`/`flattenForm` will report zero fields on them — this is expected, not a bug. To test this specific feature meaningfully, upload a PDF that actually contains fillable form fields (many governments and HR departments publish these as downloadable "fillable PDF" forms; search for "IRS fillable pdf form" or similar for a freely available example, or create one yourself in Adobe Acrobat's form tools if available to you).

With such a file uploaded, you can exercise `listFormFields`, `fillFormFields`, and `flattenForm` directly via a quick Node script or by temporarily wiring a debug button into `DocumentManager` — confirm that after calling `flattenForm`, opening the resulting document and attempting to click into what was previously a fillable field does nothing, because the field no longer exists as an interactive element; the text is now permanent, static page content.

**Step 4** — confirm originals are preserved:

Throughout Steps 2–3, confirm your original, unwatermarked/unflattened documents remain in the list and remain viewable/unchanged — consistent with Part 6's "never overwrite the original" principle, carried forward into this Part's operations as well.

---

## 7.4 A note on PDF/A and long-term archiving compliance

**The Concept:** Part 7's original outline references "PDF/A compliance" for long-term archiving. **PDF/A** is a specialized ISO-standardized subset of the PDF format specifically designed for long-term digital preservation — it forbids certain features that could cause a document to render differently or become unreadable years later, such as encryption, external font references (a PDF/A file must embed every font it uses, rather than relying on a font being installed on some future reader's machine), JavaScript, and audio/video content.

Flattening (Section 7.3) is one necessary component of typical PDF/A workflows (an interactive AcroForm field is one of the disallowed dynamic features), but full PDF/A conformance additionally requires font embedding verification, colorspace restrictions, and metadata requirements that go beyond what pdf-lib alone validates or guarantees out of the box. Implementing a true, certifiably-conformant PDF/A converter is a substantial specialized undertaking (dedicated commercial libraries exist solely for this purpose) and is intentionally out of scope for this series — Greymatter PDF's flattening feature is a meaningful, genuinely useful step toward archival-readiness, but should not be presented to end users as a guarantee of full PDF/A certification without further, dedicated validation tooling.

---

## Part 7 Summary

By this point you have: a watermarking Server Action that draws semi-transparent, rotated text across every page of a document using pdf-lib's `drawText`, `StandardFonts`, and rotation/opacity controls; a `forms.ts` module providing `listFormFields` (introspection), `fillFormFields` (setting values on an interactive form, which remains editable afterward), `flattenForm` (permanently baking in current values and removing the interactive AcroForm entirely), and a combined `fillAndFlattenForm` convenience action for the common "complete and lock" workflow; a UI extension following the exact same pattern established in Part 6, keeping the codebase consistent; and an honest scoping note distinguishing "flattening," which we fully implement, from full PDF/A archival certification, which requires additional specialized tooling beyond this series' scope.

This completes the core feature set of Phase 3 (the Manipulation Engine): Part 6 handled whole-page orchestration, and this Part handled in-page content stamping and form lifecycle management. Phase 4 begins in Part 8, which tackles the fourth and final pillar from Part 1's original breakdown — the Conversion Engine — by setting up a headless LibreOffice microservice in Docker to convert `.docx`, `.xlsx`, and `.pptx` uploads into PDFs viewable in our existing Part 2 rendering pipeline.
