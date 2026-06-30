# Tailwind CSS v4: A Modern, CSS-First Workflow

Tailwind CSS v4 revolutionizes project architecture by moving configuration from JavaScript files directly into native CSS. This "CSS-first" approach eliminates the need for `tailwind.config.js` files, keeping your design tokens, plugins, and utilities exactly where they belong: in your stylesheets.

---

## 1. Installation

Install the framework and the official Vite plugin:

```bash
npm install tailwindcss @tailwindcss/vite

```

## 2. Vite Configuration

Register the Tailwind plugin in your `vite.config.ts` (or `vite.config.js`). This enables Tailwind's high-performance engine to process your styles automatically.

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
  ],
})

```

## 3. The CSS Entry Point

In your global CSS file (e.g., `src/index.css`), replace all older `@tailwind` directives with a single, clean import. This acts as the engine for your entire project.

```css
@import "tailwindcss";

```

## 4. Native Plugin Management

Tailwind v4 utilizes the native `@plugin` directive. You no longer need to manage a `plugins` array in a separate configuration file.

### Example: `tailwind-scrollbar`

After installing the plugin (`npm install tailwind-scrollbar`), register and configure it directly in your CSS:

```css
@import "tailwindcss";

@plugin "tailwind-scrollbar" {
  nocompatible: true;
  preferredStrategy: "pseudoelements";
}

```

> **Note on IDE Support:** If your IDE flags `@plugin` as an "Unknown at rule," it is because your editor's CSS validator is still catching up to v4 syntax. You can safely ignore these warnings; your terminal build will process it correctly.

## 5. Custom Utilities & Theme Variables

Tailwind v4 treats design tokens as native CSS variables. Define your custom theme, components, and utilities in one readable file:

```css
@import "tailwindcss";

/* 1. Define Design Tokens */
@theme {
  --font-display: "Satoshi", sans-serif;
  --breakpoint-3xl: 1920px;
  --color-brand-primary: #3b82f6;
}

/* 2. Define Components */
@layer components {
  .btn-primary {
    @apply px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-blue-700 transition-colors;
  }
}

/* 3. Define Custom Utilities */
@utility flex-center {
  display: flex;
  align-items: center;
  justify-content: center;
}

```

---

## Why Migrate to v4?

* **Zero-Config Discovery:** Tailwind automatically detects your template files; no `content` array required.
* **Elimination of `tailwind.config.js`:** All configuration (colors, breakpoints, plugins) is now handled via standard CSS variables and directives.
* **Native CSS Layers:** Use `@layer` to gain better control over cascade priority without fighting specificity.
* **Blazing Fast Builds:** By moving configuration to the CSS layer, Tailwind removes the overhead of parsing large JavaScript objects.

---

## Integration Test: `App.jsx`

To verify your configuration, use this component to test your custom tokens, utilities, and plugins.

```jsx
// src/App.jsx
export default function App() {
  return (
    <div className="min-h-screen bg-slate-50 p-8">
      <h1 className="text-3xl font-bold mb-6">Tailwind v4 Feature Test</h1>

      {/* 1. Custom Utility (@utility) */}
      <div className="flex-center h-24 bg-blue-100 rounded-lg mb-6">
        <p className="text-blue-800 font-bold">Tested: @utility flex-center</p>
      </div>

      {/* 2. Custom Theme Token (--font-display) */}
      <div className="p-6 bg-white shadow-lg rounded-2xl mb-6">
        <h2 style={{ fontFamily: 'var(--font-display)' }} className="text-4xl mb-2">
          Custom Font Test
        </h2>
        <p className="text-slate-600">This text uses the custom --font-display token.</p>
      </div>

      {/* 3. Component Layer (@apply) */}
      <div className="mb-6">
        <button className="btn-primary">Test @layer components</button>
      </div>

      {/* 4. Plugin Test (tailwind-scrollbar) */}
      <div className="h-40 overflow-y-scroll scrollbar scrollbar-thumb-blue-500 scrollbar-track-blue-100 p-4 bg-white border border-slate-200 rounded-lg">
        <p className="font-bold mb-2">Tested: tailwind-scrollbar</p>
        <p>Scroll down to see the custom-styled scrollbar.</p>
        <div className="h-64 mt-4 bg-slate-100 rounded"></div>
      </div>
    </div>
  )
}

```

### Setup Verification

1. **CSS Import:** Ensure your `main.jsx` (or `main.tsx`) imports your global CSS (`import './index.css';`).
2. **Dev Server:** Run `npm run dev`.
3. **Validation:** If the `flex-center` div is aligned, the button has the custom primary color, and the scrollbar is styled, your v4 installation is fully operational.
