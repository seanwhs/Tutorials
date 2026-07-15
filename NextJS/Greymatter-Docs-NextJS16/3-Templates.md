# Part 3 — Template Architecture (Next.js Edition)

## Designing Templates and Building the Placeholder Processor

> **Goal:** Replace hardcoded text with a real template system that separates presentation from data, using templates and a placeholder convention processed with standard JavaScript libraries — no LibreOffice, no external document engine.

**Milestone:** By the end of this chapter, Greymatter Docs will support reusable `.docx` templates with `{{placeholder}}` syntax, and a `TemplateProcessor` that loads a template and replaces placeholders with real data [13].

---

## THEORY & ARCHITECTURE

Every document Greymatter Docs generates needs structured data, and instead of hardcoding values into the application, we store them in a database and inject them into a template at runtime — the same layered idea used throughout the series, where a Template Loader feeds a Placeholder Processor, which feeds a Table Processor, which feeds the final Document Processor [1]. In this chapter we build the first two of those: the template loader and the placeholder processor.

A template uses placeholders like:

```text
Customer Name:
{{first_name}} {{last_name}}

Company:
{{company}}

Email:
{{email}}

Phone:
{{phone}}

Address:
{{address}}

City:
{{city}}

Country:
{{country}}
```

The placeholder convention is simple and consistent: always use double curly braces, keep names lowercase with underscores, match database field names where possible, and avoid spaces or special characters [8]. This convention stays consistent for the rest of the series [8].

These names line up field-for-field with the `customers` table (id, first_name, last_name, company, email, phone, address, city, country, created_at) [9], so no translation layer is needed between database rows and template placeholders.

---

## Step 1 — Create the Templates Folder

We already created `templates/` in Part 1. Confirm it exists:

```bash
mkdir -p templates
```

---

## Step 2 — Create a Sample Template

Using Word, Google Docs, or any word processor, create a `.docx` file with this structure:

```text
Customer Information

Customer Name:
{{first_name}} {{last_name}}

Company:
{{company}}

Email:
{{email}}

Phone:
{{phone}}

Address:
{{address}}

City:
{{city}}

Country:
{{country}}

Thank you for choosing Greymatter Docs.
```

Save it as:

```text
templates/customer_letter.docx
```

---

## Step 3 — Build the `TemplateProcessor`

We already installed `docxtemplater` and `pizzip` in Part 1. This module loads a template, discovers placeholders, and replaces them with real values.

**src/processor/templateProcessor.js**
```js
// src/processor/templateProcessor.js
import fs from "fs";
import path from "path";
import PizZip from "pizzip";
import Docxtemplater from "docxtemplater";
import { settings } from "@/config/settings";
import { logger } from "@/lib/logger";

export class TemplateProcessor {
  /**
   * Loads a .docx template and replaces {{placeholder}} values with data.
   * @param {string} templateName - filename inside templates/ (e.g. "customer_letter.docx")
   * @param {object} values - key/value pairs matching placeholder names
   * @returns {Buffer} the generated .docx file as a buffer
   */
  render(templateName, values) {
    const templatePath = path.join(settings.templatesDir, templateName);

    if (!fs.existsSync(templatePath)) {
      logger.error("Template file not found.", { templatePath });
      throw new Error(`Template not found: ${templateName}`);
    }

    try {
      const content = fs.readFileSync(templatePath, "binary");
      const zip = new PizZip(content);

      const doc = new Docxtemplater(zip, {
        paragraphLoop: true,
        linebreaks: true,
        delimiters: { start: "{{", end: "}}" },
      });

      doc.render(values);

      const buffer = doc.getZip().generate({ type: "nodebuffer" });

      logger.info("Template rendered successfully.", { templateName });

      return buffer;
    } catch (error) {
      logger.error("Failed to render template.", {
        templateName,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Returns any placeholder names found in the raw template text that are
   * missing from the supplied values object. Useful for catching typos or
   * missing data before rendering.
   * @param {string} templateText - raw text extracted from the template
   * @param {object} values - key/value pairs intended for rendering
   * @returns {string[]} list of unresolved placeholder names
   */
  validatePlaceholders(templateText, values) {
    const matches = [...templateText.matchAll(/{{\s*([\w.]+)\s*}}/g)];
    const placeholderNames = matches.map((m) => m[1]);
    const unresolved = placeholderNames.filter((name) => !(name in values));
    return [...new Set(unresolved)];
  }
}

export const templateProcessor = new TemplateProcessor();
export default templateProcessor;
```

`docxtemplater` is configured with `delimiters: { start: "{{", end: "}}" }`, matching the `{{field_name}}` convention exactly [8]. The `validatePlaceholders` method gives beginners an easy way to catch missing data before rendering, rather than discovering blank placeholders in the final document.

---

## Step 4 — Verify With an API Route

Now connect the template processor to the `CustomerRepository` from Part 2.

**src/app/api/generate-letter/route.js**
```js
// src/app/api/generate-letter/route.js
import { NextResponse } from "next/server";
import fs from "fs";
import path from "path";
import { customerRepository } from "@/repositories/customerRepository";
import { templateProcessor } from "@/processor/templateProcessor";
import { settings } from "@/config/settings";
import { logger } from "@/lib/logger";

export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const id = searchParams.get("id") || "1";

  try {
    const customer = customerRepository.getCustomerById(Number(id));

    if (!customer) {
      return NextResponse.json({ error: "Customer not found." }, { status: 404 });
    }

    const buffer = templateProcessor.render("customer_letter.docx", customer);

    if (!fs.existsSync(settings.outputDir)) {
      fs.mkdirSync(settings.outputDir, { recursive: true });
    }

    const outputPath = path.join(settings.outputDir, `letter_${customer.id}.docx`);
    fs.writeFileSync(outputPath, buffer);

    logger.info("Letter generated.", { customerId: customer.id, outputPath });

    return NextResponse.json({
      status: "ok",
      file: `letter_${customer.id}.docx`,
    });
  } catch (error) {
    logger.error("Failed to generate letter.", { error: error.message });
    return NextResponse.json({ error: "Generation failed." }, { status: 500 });
  }
}
```

Run the dev server and visit:

```text
http://localhost:3000/api/generate-letter?id=1
```

Check `output/letter_1.docx` — every placeholder should now show real customer data.

---

## CHALLENGE LAB

1. Add support for `{{current_date}}` that inserts today's date automatically before rendering.
2. Log every placeholder that could not be resolved, using `validatePlaceholders()`.
3. Wire `validatePlaceholders()` into the API route as a pre-check, returning a 400 response listing any unresolved placeholders instead of generating a broken document.
4. Create a second template named `invoice_template.docx` using at least 10 placeholders.
5. Generate both templates from the same customer data.

---

## TROUBLESHOOTING

| Problem | Cause | Solution |
|---|---|---|
| Output still contains `{{placeholders}}` | Missing keys in the values object | Ensure placeholder names match object keys exactly (case-sensitive) |
| `Multi error` from docxtemplater | Malformed placeholder in the `.docx` (split across formatting runs) | Retype the placeholder in one continuous run |
| `ENOENT: no such file or directory` | Template file not found | Verify the template exists in `templates/` and the filename matches exactly |
| Generated file won't open in Word | Corrupted zip due to editing the template incorrectly | Re-save the template as standard `.docx` |

---

## Chapter Summary

In this chapter, you:

* Learned why templates separate presentation from data
* Adopted a consistent `{{field_name}}` placeholder convention [8]
* Created a `.docx` template matching the `customers` schema fields [9]
* Built a `TemplateProcessor` using `docxtemplater` and `pizzip`, including a `validatePlaceholders` method
* Verified end-to-end generation by combining the template processor with the `CustomerRepository` from Part 2

**Next: Part 4 — Document Engine Bridge**, where we formalize document lifecycle handling (open/generate/save) as a dedicated service layer, ahead of dynamic tables in Part 5 [6].
