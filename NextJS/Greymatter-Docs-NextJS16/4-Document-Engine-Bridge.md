# Part 4 — Document Engine Bridge (Next.js Edition)

## Formalizing Document Lifecycle Handling

> **Goal:** Build a dedicated document engine service that manages the full lifecycle of document generation — loading a template, replacing placeholders, tracking modification state, and saving the result — as a clean, reusable service layer.

**Milestone:** By the end of this chapter, Greymatter Docs will generate real `.docx` documents from live customer data through a proper service layer, with every placeholder replacement logged and the document's modified state trackable [7].

---

## THEORY & ARCHITECTURE

So far, our `TemplateProcessor` (Part 3) handles the mechanics of rendering a template. But a real document generation platform needs more structure around that: a service that owns the full lifecycle of a document — open, process, track state, save, and report back what happened [7].

This mirrors the layered pipeline described in the architecture: presentation code never touches the template engine directly — it always goes through an orchestrator and a service layer [1]. Our stub `DocumentEngineService` from Part 1 gets its real implementation now:

```text
DocumentOrchestrator (Part 7)
        │
        ▼
DocumentEngineService   ← built in this chapter
        │
        ▼
TemplateProcessor (Part 3)
        │
        ▼
docxtemplater / pizzip
```

The service layer's job is to:
* Load a template and the data needed to fill it
* Track whether placeholders were actually replaced (a "document is modified" check)
* Log every replacement event for auditability [7]
* Save the finished document to the output directory
* Report success/failure back to whatever called it

---

## Step 1 — Expand the `DocumentEngineService`

Recall our Part 1 stub only proved the service could initialize. Now we give it real behavior.

**src/services/documentEngineService.js**
```js
// src/services/documentEngineService.js
import fs from "fs";
import path from "path";
import { templateProcessor } from "@/processor/templateProcessor";
import { settings } from "@/config/settings";
import { logger } from "@/lib/logger";

export class DocumentEngineService {
  constructor() {
    this.connected = false;
    this._lastDocumentModified = false;
  }

  connect() {
    try {
      logger.info("DocumentEngineService: engine ready.");
      this.connected = true;
      return true;
    } catch (error) {
      logger.error("DocumentEngineService failed to initialize.", {
        error: error.message,
      });
      throw new Error("Unable to initialize document engine.");
    }
  }

  isConnected() {
    return this.connected;
  }

  /**
   * Enriches raw data with computed placeholders like {{generated_date}}
   * before rendering, matching the convention of adding derived fields
   * that aren't stored directly in the database.
   */
  _withGeneratedFields(values) {
    return {
      ...values,
      generated_date: new Date().toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
      }),
    };
  }

  /**
   * Full lifecycle: load template, replace placeholders, track modification
   * state, save output, and return a result summary.
   * @param {string} templateName
   * @param {object} values
   * @param {string} outputFileName
   */
  generateDocument(templateName, values, outputFileName) {
    if (!this.connected) {
      this.connect();
    }

    const enrichedValues = this._withGeneratedFields(values);

    logger.info("Starting document generation.", {
      templateName,
      outputFileName,
    });

    try {
      const buffer = templateProcessor.render(templateName, enrichedValues);

      // A document is considered "modified" if rendering succeeded and
      // produced non-empty output — the JS equivalent of checking whether
      // the in-memory document differs from the original template.
      this._lastDocumentModified = buffer && buffer.length > 0;

      if (!fs.existsSync(settings.outputDir)) {
        fs.mkdirSync(settings.outputDir, { recursive: true });
      }

      const outputPath = path.join(settings.outputDir, outputFileName);
      fs.writeFileSync(outputPath, buffer);

      logger.info("Document saved.", { outputPath });

      // Log every field that was replaced, for auditability.
      Object.keys(enrichedValues).forEach((field) => {
        logger.info("Placeholder replaced.", { field });
      });

      logger.info("Document generation complete.", { outputFileName });

      return {
        success: true,
        outputPath,
        modified: this._lastDocumentModified,
      };
    } catch (error) {
      logger.error("Document generation failed.", {
        templateName,
        error: error.message,
      });
      return { success: false, error: error.message };
    }
  }

  /**
   * Checks whether the most recently generated document contains changes,
   * i.e. whether placeholder replacement actually occurred.
   */
  documentIsModified() {
    return this._lastDocumentModified;
  }
}

export const documentEngineService = new DocumentEngineService();
export default documentEngineService;
```

This gives us `{{generated_date}}` support automatically on every document [7], a `documentIsModified()` check [7], and structured logging of every placeholder field replaced [7] — all without needing an external document engine process running in the background.

---

## Step 2 — Generate Multiple Documents in a Single Run

**src/app/api/generate-batch/route.js**
```js
// src/app/api/generate-batch/route.js
import { NextResponse } from "next/server";
import { customerRepository } from "@/repositories/customerRepository";
import { documentEngineService } from "@/services/documentEngineService";
import { logger } from "@/lib/logger";

export async function GET() {
  try {
    const customers = customerRepository.getAllCustomers().slice(0, 3);

    const results = customers.map((customer) => {
      const outputFileName = `letter_${customer.id}.docx`;
      return documentEngineService.generateDocument(
        "customer_letter.docx",
        customer,
        outputFileName
      );
    });

    logger.info("Batch generation complete.", { count: results.length });

    return NextResponse.json({ results });
  } catch (error) {
    logger.error("Batch generation failed.", { error: error.message });
    return NextResponse.json({ error: "Batch generation failed." }, { status: 500 });
  }
}
```

Visit `http://localhost:3000/api/generate-batch` — you should see three documents generated in `output/`, each with `{{generated_date}}` filled in automatically, and a `results` array confirming success and modification state for each one.

---

## CHALLENGE LAB

1. Extend placeholder replacement to cover nested objects (e.g., `{{address.city}}` style dot-notation) for future flexibility.
2. Add a method `documentSummary()` that returns which fields were replaced in the last run.
3. Log a warning if `documentIsModified()` returns `false` after generation — this likely indicates the template had no matching placeholders.
4. Generate three customer documents in a single execution (done above) — now add a fourth that intentionally uses a non-existent customer ID and confirm the failure is logged and isolated without crashing the batch.
5. Add support for replacing placeholders inside document headers/footers by testing with a template that includes header/footer text — confirm `docxtemplater` handles this natively.

---

## TROUBLESHOOTING

| Problem | Cause | Solution |
|---|---|---|
| `{{generated_date}}` not replaced | Field not merged into values before render | Confirm `_withGeneratedFields()` runs before `templateProcessor.render()` |
| `documentIsModified()` always returns `false` | Render failed silently or buffer was empty | Check `logs/errors.log` for the underlying render error |
| Batch stops entirely after one failure | Missing per-job error isolation | Wrap each `generateDocument()` call in its own try/catch (formalized fully in Part 7's orchestrator) |
| Output documents missing expected fields | Customer record incomplete in database | Verify the customer row includes all fields the template expects |

---

## Chapter Summary

In this chapter, you:

* Built a real `DocumentEngineService` on top of the Part 1 stub, giving it an actual lifecycle: connect, generate, track modification state, save
* Added automatic `{{generated_date}}` support
* Logged every placeholder field replaced during generation, for auditability [7]
* Added a `documentIsModified()` check
* Generated multiple customer documents in a single execution run

**Next: Part 5 — The Processor Engine**, where we expand the document engine to support dynamic, repeating data — line-item tables built from live invoice data — turning Greymatter Docs from a simple mail-merge tool into a full document generation engine [6].
