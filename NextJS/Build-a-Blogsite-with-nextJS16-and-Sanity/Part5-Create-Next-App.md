# **✅ Part 5 — Creating GreyMatter Journal**

---

# GreyMatter Journal  
## Part 5 — Creating GreyMatter Journal: What `create-next-app` Actually Builds

> **Goal of this lesson:** Initialize the official Next.js 16 project and deeply understand the purpose of every generated file and folder.

---

### Now We Build

After four foundational lessons, we finally have the mental models needed to create **GreyMatter Journal** properly.

Open your terminal and run:

```bash
npx create-next-app@latest greymatter-journal
```

### Recommended Configuration

Choose these options:

```text
✔ TypeScript? ...................... Yes
✔ ESLint? .......................... Yes
✔ Tailwind CSS? .................... Yes
✔ Use src/ directory? .............. No
✔ App Router? ...................... Yes
✔ Turbopack? ....................... Yes
✔ Customize import alias? .......... No
```

---

### Why These Choices?

| Option               | Choice | Reason |
|----------------------|--------|--------|
| **TypeScript**       | Yes    | Industry standard for large apps, excellent editor support |
| **ESLint**           | Yes    | Catches bugs and enforces consistent style |
| **Tailwind CSS**     | Yes    | Fast, utility-first styling (matches Appendix B) |
| **src/ folder**      | No     | Simpler structure, aligns with modern Next.js & Appendix B |
| **App Router**       | Yes    | Required for layouts, Server Components, and modern features |
| **Turbopack**        | Yes    | Blazing-fast development server |

---

### Project Structure After Creation

```text
greymatter-journal/
├── app/                  # Core application logic (most important)
├── public/               # Static files (images, fonts, etc.)
├── package.json          # Project manifest
├── next.config.ts        # Next.js configuration
├── tsconfig.json         # TypeScript configuration
├── tailwind.config.ts    # Tailwind configuration
├── postcss.config.mjs
├── eslint.config.mjs
└── README.md
```

---

### Key Files Explained

#### 1. `app/` — The Heart of Your Application

- `layout.tsx` — Root layout (persistent shell)
- `page.tsx` — Homepage (`/`)
- `globals.css` — Global styles
- `favicon.ico` — Browser icon

#### 2. `public/` — Static Assets

Anything placed here is served directly:
- `/logo.png` → `public/logo.png`
- Ideal for images, icons, `robots.txt`, etc.

#### 3. `package.json` — The Brain

```json
{
  "name": "greymatter-journal",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "16.x",
    "react": "^19",
    "react-dom": "^19"
  }
}
```

This file controls everything you run with `npm run ...`

---

### Running the Project

```bash
cd greymatter-journal
npm run dev
```

Visit `http://localhost:3000`

You should see the default Next.js starter page.

---

### First Customization (GreyMatter Journal Identity)

Replace the content of `app/page.tsx` with:

```tsx
export default function HomePage() {
  return (
    <main className="min-h-screen flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-6xl font-bold tracking-tight">
          GreyMatter Journal
        </h1>
        <p className="mt-6 text-xl text-gray-600 max-w-md mx-auto">
          Exploring software engineering, 
          systems thinking, and architecture.
        </p>
      </div>
    </main>
  );
}
```

Save the file. Thanks to **Turbopack**, the browser updates instantly.

---

### Mental Model To Remember Forever

When you run:

```bash
npx create-next-app@latest greymatter-journal
```

You are not just creating files.

You are creating a **complete professional development environment** that includes:

- Runtime (Node.js)
- Package management (npm)
- Framework (Next.js + React)
- Type system (TypeScript)
- Styling (Tailwind)
- Development engine (Turbopack)
- Linting & best practices

The actual website is just the visible part of a much larger, sophisticated system.

---

### Up Next — Part 6: Building Our Application Shell

We will:
- Design and implement a clean, persistent `RootLayout`
- Create `Header` and `Footer` components
- Set up global styling with Tailwind
- Align the project with the final architecture from **Appendix B**

This is where **GreyMatter Journal** starts to feel like a real publication.
