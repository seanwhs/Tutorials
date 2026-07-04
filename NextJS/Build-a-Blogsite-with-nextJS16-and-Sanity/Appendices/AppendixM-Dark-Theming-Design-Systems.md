# **Appendix M — Dark Mode, Theming, and Design Systems**

> **Goal of this appendix:** Learn how to implement production-grade theming in Next.js, including dark mode, design tokens, typography systems, semantic colors, and scalable styling architectures.

---

# Introduction

One of the biggest misconceptions beginners have is:

```text
Styling
     =
Colors
```

Professional engineers think:

```text
Styling
     =
System Design
```

A production application needs a visual system that supports:

```text
✓ Light Mode
✓ Dark Mode
✓ Accessibility
✓ Typography
✓ Responsive Design
✓ Design Tokens
✓ Brand Themes
✓ Component Variants
✓ Future Design Changes
```

The goal of GreyMatter Journal is not merely to create a beautiful blog.

The goal is to create a **maintainable visual system**.

---

# The Evolution of Styling

Most developers evolve through four stages.

### Stage 1 — Inline Styles

```tsx
<div style={{
  color: "red",
  padding: "20px",
}}>
```

Problems:

```text
No consistency
No reuse
No theming
```

---

### Stage 2 — CSS Files

```css
.article {
  color: black;
}
```

Better, but still problematic:

```text
Global collisions
Difficult maintenance
Limited scalability
```

---

### Stage 3 — Utility CSS (Tailwind)

```tsx
<div className="text-gray-900 p-6">
```

Benefits:

```text
Reusable
Composable
Predictable
```

---

### Stage 4 — Design Systems

Professional applications eventually evolve toward:

```text
Design Tokens
        ↓
Semantic Variables
        ↓
Component System
        ↓
Application UI
```

This is the architecture we'll build.

---

# The Problem With Hardcoded Colors

Beginners often write:

```tsx
<div className="bg-white text-black">
```

This immediately creates problems.

How do you support:

```text
Light Mode
Dark Mode
Future Rebranding
Accessibility Improvements
```

Instead we use semantic design tokens.

---

# CSS Variables as Design Tokens

Update:

```text
app/globals.css
```

```css
@import "tailwindcss";

:root {
  --background: #ffffff;
  --foreground: #111827;

  --card: #ffffff;
  --card-foreground: #111827;

  --border: #e5e7eb;

  --muted: #6b7280;

  --primary: #2563eb;
  --primary-foreground: #ffffff;
}
```

---

# Adding Dark Mode Tokens

```css
.dark {
  --background: #09090b;
  --foreground: #fafafa;

  --card: #18181b;
  --card-foreground: #fafafa;

  --border: #27272a;

  --muted: #a1a1aa;

  --primary: #3b82f6;
  --primary-foreground: #ffffff;
}
```

---

# Applying Theme Variables

Instead of:

```tsx
<div className="bg-white text-black">
```

write:

```css
body {
  background: var(--background);
  color: var(--foreground);
}
```

Now the entire application changes theme automatically.

---

# Why Design Tokens Matter

Suppose the designer changes:

```text
Blue
    ↓
Purple
```

Without tokens:

```text
Edit 500 files
```

With tokens:

```text
Edit one variable
```

This is the same principle as:

```text
Functions
     ↓
Abstraction

Variables
     ↓
Abstraction

Design Tokens
     ↓
Visual Abstraction
```

---

# Installing Dark Mode Support

Install:

```bash
npm install next-themes
```

---

# Configure Theme Provider

Create:

```text
components/providers/theme-provider.tsx
```

```tsx
"use client";

import { ThemeProvider } from "next-themes";

export function Providers({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ThemeProvider
      attribute="class"
      defaultTheme="system"
      enableSystem
    >
      {children}
    </ThemeProvider>
  );
}
```

---

# Update RootLayout

```tsx
import { Providers } from "@/components/providers/theme-provider";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
    >
      <body>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
```

---

# Building a Theme Toggle

Create:

```text
components/ui/theme-toggle.tsx
```

```tsx
"use client";

import { useTheme } from "next-themes";

export default function ThemeToggle() {
  const {
    theme,
    setTheme,
  } = useTheme();

  return (
    <button
      onClick={() =>
        setTheme(
          theme === "dark"
            ? "light"
            : "dark"
        )
      }
    >
      {theme === "dark"
        ? "☀️"
        : "🌙"}
    </button>
  );
}
```

---

# Semantic Tailwind Classes

Avoid:

```tsx
className="
bg-white
text-black
border-gray-200
"
```

Prefer:

```tsx
className="
bg-[var(--card)]
text-[var(--foreground)]
border-[var(--border)]
"
```

This creates components that automatically adapt to themes.

---

# Typography Systems

A content platform lives or dies by typography.

For GreyMatter Journal we optimize for:

```text
Readability
Consistency
Accessibility
Scanning
```

---

## Body Typography

```css
body {
  font-family:
    Inter,
    sans-serif;

  line-height: 1.7;
}
```

---

## Code Typography

```css
code,
pre {
  font-family:
    "JetBrains Mono",
    monospace;
}
```

---

## Article Width

Research consistently shows:

```text
60–75 characters
```

is optimal for reading.

Therefore:

```css
.prose {
  max-width: 75ch;
}
```

---

# Building a Color System

Professional systems rarely use:

```text
Blue
Red
Green
```

Instead they use semantic meanings:

```text
Primary
Secondary
Accent
Muted
Success
Warning
Danger
Info
```

Example:

```css
:root {
  --success: #16a34a;
  --warning: #eab308;
  --danger: #dc2626;
}
```

This allows future redesigns without changing application code.

---

# Component Variants

Instead of creating:

```text
PrimaryButton
SecondaryButton
DangerButton
GhostButton
```

Create one component:

```tsx
<Button variant="primary" />
<Button variant="danger" />
<Button variant="ghost" />
```

Example:

```tsx
<Button
  variant="destructive"
>
  Delete
</Button>
```

This is called:

```text
Composition
       >
Inheritance
```

---

# Responsive Design Strategy

GreyMatter Journal follows a mobile-first strategy.

```text
Mobile
    ↓
Tablet
    ↓
Desktop
```

Example:

```tsx
<div className="
  px-4
  md:px-8
  lg:px-12
">
```

---

# Motion and Animation

For content websites:

Use:

```text
Subtle transitions
Hover effects
Fade animations
```

Avoid:

```text
Parallax
Heavy motion
Complex transforms
```

Content platforms optimize for:

```text
Reading
     >
Entertainment
```

---

# Accessibility and Themes

Every theme must support:

```text
WCAG contrast ratios
Keyboard navigation
Screen readers
Reduced motion
Focus indicators
```

Example:

```css
:focus-visible {
  outline: 2px solid
    var(--primary);
}
```

---

# GreyMatter Journal Visual Architecture

```text
Design Tokens
        ↓

Theme Variables
        ↓

Tailwind Utilities
        ↓

Reusable Components
        ↓

Page Layouts
        ↓

Application UI
```

---

# Mental Model To Remember Forever

Beginners think:

```text
Styling
     =
Making things pretty
```

Professional engineers think:

```text
Styling
     =
Building a visual operating system
```

The same engineering principles apply:

```text
Abstraction

Composition

Contracts

Encapsulation

Scalability
```

because a design system is ultimately another form of software architecture.

> **Performance Engineering, Bundle Optimization, Fonts, Images, Streaming UI, and Core Web Vitals in Next.js 16**.
