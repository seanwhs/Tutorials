# How to Install Tailwind CSS v4 in a Vite React Project

This tutorial shows how to set up Tailwind CSS v4 in a Vite React app, then extend it with plugins, custom utilities, and daisyUI 5. Tailwind v4 uses a CSS-first workflow, so most of the setup now happens in your global stylesheet instead of a `tailwind.config.js` file. [tailwindcss](https://tailwindcss.com/docs/installation/framework-guides)[tailwindcss](https://tailwindcss.com/docs/functions-and-directives)

## Prerequisites

Before you start, make sure you already have a Vite React project ready. The steps below assume you are working inside the project root and using a main stylesheet such as `src/index.css`. [tailwindcss](https://tailwindcss.com/docs/installation/framework-guides)

## 1. Install Tailwind CSS

Run this command in your project root:

```bash
npm install tailwindcss @tailwindcss/vite
```

This installs Tailwind CSS and the official Vite plugin needed for the v4 setup. [youtube](https://www.youtube.com/watch?v=h4ZPff8s0u8)[tailwindcss](https://tailwindcss.com/docs/installation/framework-guides)

## 2. Add the Vite plugin

Open `vite.config.js` or `vite.config.ts` and register the Tailwind plugin alongside React:

```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
})
```

This lets Vite process Tailwind correctly during development and production builds. [tailwindcss](https://tailwindcss.com/docs/installation/framework-guides)[youtube](https://www.youtube.com/watch?v=h4ZPff8s0u8)

## 3. Import Tailwind in CSS

Open your main CSS file, usually `src/index.css`, and replace any starter styles you do not need with this line:

```css
@import "tailwindcss";
```

That single import gives you access to Tailwind’s utilities across the entire project. [youtube](https://www.youtube.com/watch?v=h4ZPff8s0u8)[tailwindcss](https://tailwindcss.com/docs/functions-and-directives)

## 4. Start the dev server

Run the development server:

```bash
npm run dev
```

Then test the setup by using Tailwind classes in a component such as `src/App.jsx`:

```jsx
export default function App() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-900 text-white">
      <h1 className="text-4xl font-bold tracking-tight text-sky-400">
        Tailwind CSS is Working!
      </h1>
    </div>
  )
}
```

If the page styles update, your Tailwind setup is working correctly. [youtube](https://www.youtube.com/watch?v=h4ZPff8s0u8)

## Add Plugins in v4

Tailwind CSS v4 uses a CSS-first plugin workflow. Instead of relying on a `tailwind.config.js` plugin array, you can load plugins directly in your global stylesheet with `@plugin`. [tailwindcss](https://tailwindcss.com/docs/functions-and-directives)[tailwindcss](https://tailwindcss.com/blog/tailwindcss-v4)

### Install a plugin

To use a plugin such as `tailwind-scrollbar`, install it first:

```bash
npm install tailwind-scrollbar
```

### Register it in CSS

Then add it to `src/index.css`:

```css
@import "tailwindcss";

@plugin "tailwind-scrollbar";
```

This keeps plugin registration close to your styles and matches Tailwind v4’s CSS-first design. [stackoverflow](https://stackoverflow.com/questions/79383758/how-to-setting-tailwind-css-v4-global-class)[tailwindcss](https://tailwindcss.com/docs/functions-and-directives)

## Create Custom Utilities

You can also define project-specific styles directly in CSS. Use `@layer components` for reusable class-based components and `@utility` for utility-style helpers. [tailwindcss](https://tailwindcss.com/docs/functions-and-directives)

```css
@import "tailwindcss";

/* Custom component styles */
@layer components {
  .btn-primary {
    @apply px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors cursor-pointer;
  }

  .card-premium {
    @apply p-6 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-xl;
  }
}

/* Custom utility */
@utility flex-center {
  display: flex;
  align-items: center;
  justify-content: center;
}
```

This is a simple way to keep common styles consistent without turning everything into a JavaScript plugin. [stackoverflow](https://stackoverflow.com/questions/79383758/how-to-setting-tailwind-css-v4-global-class)[tailwindcss](https://tailwindcss.com/docs/functions-and-directives)

## Use JavaScript Plugins

Tailwind v4 still supports JavaScript-based plugins through the same `@plugin` directive. This is useful when you want to load a local plugin file or distribute a more advanced plugin as a package. [tailwindcss](https://tailwindcss.com/docs/functions-and-directives)[github](https://github.com/tailwindlabs/tailwindcss/discussions/13292)

```css
@import "tailwindcss";

@plugin "../plugins/my-custom-plugin.js";
```

A basic plugin module looks like this:

```js
// src/plugins/my-custom-plugin.js
import plugin from 'tailwindcss/plugin'

export default plugin(function ({ addUtilities }) {
  addUtilities({
    '.text-shadow-sm': {
      textShadow: '0 1px 2px rgba(0, 0, 0, 0.05)',
    },
  })
})
```

This approach is still useful for reusable plugin logic that needs to live outside your main stylesheet. [github](https://github.com/tailwindlabs/tailwindcss/discussions/13292)

## Prefer React Components

For app UI, it is usually better to wrap Tailwind classes inside reusable React components instead of creating large CSS abstraction layers. That keeps styling close to behavior and makes your code easier to maintain. [dev](https://dev.to/plainsailing/getting-started-with-tailwind-v4-3cip)

```jsx
// src/components/Button.jsx
export default function Button({ children, onClick }) {
  return (
    <button
      onClick={onClick}
      className="px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors cursor-pointer"
    >
      {children}
    </button>
  )
}
```

## daisyUI 5 Setup

daisyUI 5 works with Tailwind CSS v4 and can be loaded directly from your CSS file using `@plugin`. Its themes can also be configured in CSS, which fits the new workflow nicely. [daisyui](https://daisyui.com/docs/config/?lang=en)[daisyui](https://daisyui.com/docs/themes/)

### Install daisyUI

```bash
npm install daisyui@latest
```

### Register daisyUI

Add this to your global CSS file:

```css
@import "tailwindcss";

@plugin "daisyui";
```

### Configure themes

You can also configure themes and options in the same file:

```css
@import "tailwindcss";

@plugin "daisyui" {
  themes: light --default, forest --prefersdark, cupcake;
  prefix: "daisy-";
}
```

daisyUI themes are controlled through the `data-theme` attribute, so a small React theme switcher can update the active theme on the root element. [daisyui](https://daisyui.com/docs/themes/)

## Wrap-up

Tailwind CSS v4 makes setup simpler, more CSS-driven, and easier to extend. Once the base installation works, you can add plugins, define your own utilities, and layer in component libraries like daisyUI without leaving your CSS workflow. [tailwindcss](https://tailwindcss.com/blog/tailwindcss-v4)[daisyui](https://daisyui.com/docs/v5/)
