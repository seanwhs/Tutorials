# Tailwind CSS v4: The CSS-First Workflow

Tailwind CSS v4 introduces a "CSS-first" design, moving configuration from JavaScript files directly into your global CSS. This simplifies setup and keeps your design tokens and plugins close to your styles.

---

## 1. Installation

Install the framework and the Vite plugin in your project root:

```bash
npm install tailwindcss @tailwindcss/vite

```

## 2. Vite Configuration

Register the Tailwind plugin in `vite.config.ts`:

```javascript
@import "tailwindcss";

@theme {
  /* Define custom design tokens */
  --font-display: "Satoshi", sans-serif;
  --breakpoint-3xl: 1920px;
}

@layer components {
  .btn-primary {
    @apply px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700;
  }
}

@utility flex-center {
  display: flex;
  align-items: center;
  justify-content: center;
}
```

## 3. The CSS Entry Point

In your main CSS file (e.g., `src/index.css`), replace all previous `@tailwind` directives with a single import:

```css
@import "tailwindcss";

```

## 4. Plugins in v4

Tailwind v4 uses the `@plugin` directive directly in your CSS. You no longer need to manage a `plugins` array in a `tailwind.config.js` file.

### Adding a Plugin

After installing a plugin (e.g., `npm install tailwind-scrollbar`), register it in your CSS:

```css
@import "tailwindcss";

@plugin "tailwind-scrollbar" {
  nocompatible: true;
  preferredStrategy: "pseudoelements";
}

```

*Note: If your IDE flags `@plugin` as an "Unknown at rule," this is due to your editor's CSS validator not yet recognizing v4’s custom syntax. As long as your terminal build succeeds, this is safe to ignore.*

## 5. Custom Utilities and Theme Variables

You can define custom styles and design tokens directly in your CSS using native-style variables and directives:

```css
@import "tailwindcss";

@theme {
  /* Define custom design tokens */
  --font-display: "Satoshi", sans-serif;
  --breakpoint-3xl: 1920px;
}

@layer components {
  .btn-primary {
    @apply px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700;
  }
}

@utility flex-center {
  display: flex;
  align-items: center;
  justify-content: center;
}

```

---

### Key Takeaways for v4

* **Zero Configuration:** Tailwind automatically detects your template files; no need for a `content` array.
* **No `tailwind.config.js`:** Everything previously handled in JS (colors, breakpoints, plugins) is now handled via CSS variables and directives.
* **Native CSS Layers:** Tailwind v4 uses standard CSS `@layer` for organizing base, components, and utilities.
* **Faster Builds:** By using CSS-first configuration, Tailwind avoids the overhead of parsing large JavaScript configuration objects.
