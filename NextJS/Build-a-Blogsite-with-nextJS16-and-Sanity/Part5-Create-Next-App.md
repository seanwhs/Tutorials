# **✅ Part 5 — Creating GreyMatter Journal**

---

# GreyMatter Journal  
## Part 5 — Creating GreyMatter Journal: What `create-next-app` Actually Builds

> **Goal of this lesson:** Initialize the Next.js 16 project and deeply understand what the scaffolding actually creates.

---

### Finally — Time to Build

We’ve built strong mental models. Now we create the foundation.

---

### Run the Command

```bash
npx create-next-app@latest greymatter-journal
```

**Recommended options:**

- TypeScript → Yes
- ESLint → Yes
- Tailwind CSS → Yes
- `src/` directory → **No**
- App Router → Yes
- Turbopack → Yes

---

### Why These Choices?

| Option               | Choice | Reason |
|----------------------|--------|--------|
| TypeScript           | Yes    | Contracts, safety, excellent tooling |
| ESLint               | Yes    | Code quality and consistency |
| Tailwind CSS         | Yes    | Fast, utility-first styling |
| `src/` directory     | No     | Simpler structure (aligns with Appendix B) |
| App Router           | Yes    | Modern patterns, layouts, Server Components |
| Turbopack            | Yes    | Lightning-fast development server |

---

### Project Structure Overview

```text
greymatter-journal/
├── app/                  # Core application (most important)
├── public/               # Static assets
├── next.config.ts        # Next.js configuration
├── tsconfig.json         # TypeScript settings
├── tailwind.config.ts    # Tailwind configuration
├── package.json          # Project manifest
└── ...
```

---

### Key Files to Understand First

- **`app/layout.tsx`** — Root application shell
- **`app/page.tsx`** — Homepage
- **`app/globals.css`** — Global styles
- **`package.json`** — Scripts and dependencies

---

### Run the Development Server

```bash
cd greymatter-journal
npm run dev
```

Visit `http://localhost:3000`

---

### First Customization

Replace `app/page.tsx` with a clean homepage:

```tsx
export default function HomePage() {
  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-6xl font-bold tracking-tight">
          GreyMatter Journal
        </h1>
        <p className="mt-6 text-xl text-gray-600 max-w-md mx-auto">
          Exploring software engineering, systems thinking, and architecture.
        </p>
      </div>
    </div>
  );
}
```

---

### Mental Model To Remember Forever

> `create-next-app` doesn’t create a website.  
> It creates a **professional development platform** containing everything needed to build, test, and ship modern applications.

---

### Up Next — Part 6: Building Our First Application Shell

We’ll create `Header`, `Footer`, and the site layout following the structure in Appendix B.
