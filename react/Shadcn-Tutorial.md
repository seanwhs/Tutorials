# 📘 shadcn/ui Tutorial

## 🧭 What you are learning

You are not learning a UI library.

You are learning a **UI ownership system**.

shadcn/ui flips the traditional frontend model:

> Instead of importing UI components… you generate and OWN them.

This changes architecture, scalability, and long-term maintainability.

---

# 1. 🧠 The Core Paradigm Shift: You Own the UI

## 🏛 Traditional UI libraries (black box model)

```text
Your App
   ↓
npm package (Material UI, AntD, etc.)
   ↓
Precompiled components (cannot easily modify internals)
```

Problems:

* rigid styling system
* deep dependency lock-in
* bundle bloat
* difficult overrides
* fighting defaults constantly

---

## ⚡ shadcn/ui model (ownership model)

```text
shadcn CLI
   ↓
Copies source code into your repo
   ↓
You directly edit components
   ↓
Your UI system evolves like application code
```

Instead of:

> “Using a component library”

You are:

> “Building your own component system with generated primitives”

---

## 🧠 The key mental model

shadcn/ui is:

> A **code scaffolding system for UI primitives**, not a dependency.

---

# 2. 🧱 The Magic Stack Behind shadcn

shadcn works because it composes 3 foundational systems:

### 🧩 Core pillars

* React → component model
* Tailwind CSS → styling system
* Radix UI → behavior + accessibility

---

## 🧬 Architecture flow

```text
Radix UI (logic, accessibility, state)
        ↓
shadcn wrapper (variants + structure)
        ↓
Tailwind CSS (visual styling)
        ↓
Your application
```

---

## 🧠 CVA (Class Variance Authority)

Used for variant systems:

Instead of:

```tsx
<ButtonPrimary />
<ButtonDanger />
<ButtonLargeRed />
```

You get:

```tsx
<Button variant="destructive" size="lg" />
```

Internally powered by:

* class variance mapping
* type-safe variants
* composable styling rules

---

# 3. 🚀 Full Setup From Scratch (Production Ready)

## Step 1: Create project

```bash
npx create-next-app@latest shadcn-masterclass \
--typescript --tailwind --eslint --app
```

---

## Step 2: Initialize shadcn

```bash
npx shadcn@latest init
```

Recommended config:

```text
Style: Default
Base color: Slate
CSS file: src/app/globals.css
CSS variables: yes
Tailwind config: tailwind.config.ts
Alias: @/components
Utils alias: @/lib/utils
Registry: shadcn/ui
```

---

## Step 3: What gets generated

### 📁 Key outputs

```text
components.json
src/lib/utils.ts
```

---

## 🔧 The `cn()` utility (critical system primitive)

```ts
import { clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

### 🧠 Why it matters

Solves:

* conflicting Tailwind classes
* conditional styling chaos
* override bugs

Example:

```tsx
className="px-4 px-2"
```

→ becomes:

```text
px-2 (correct override)
```

---

# 4. 🧩 Your First Components

```bash
npx shadcn@latest add button input
```

Creates:

```text
src/components/ui/button.tsx
src/components/ui/input.tsx
```

---

## 🧠 Anatomy of a shadcn Button

### Core structure

```tsx
const Button = React.forwardRef(...)
```

Key ideas:

---

## 1. Variant system (CVA)

```ts
const buttonVariants = cva(baseStyles, {
  variants: {
    variant: {
      default: "...",
      destructive: "...",
      outline: "...",
    },
    size: {
      sm: "...",
      lg: "...",
    }
  }
})
```

---

## 2. Component composition

```tsx
className={cn(buttonVariants({ variant, size, className }))}
```

Everything merges cleanly.

---

## 3. `asChild` pattern (Radix Slot)

```tsx
<Button asChild>
  <Link href="/dashboard">Go</Link>
</Button>
```

### 🧠 Why this matters

Without `asChild`:

* invalid nested `<button><a></a></button>`

With `asChild`:

* button styles applied to Link directly
* semantic HTML preserved

Powered by:

Radix UI Slot system

---

# 5. 🏗 Building a Real UI System (Login Form)

Install:

```bash
npx shadcn@latest add card form label button input
```

---

## Full production-style component

```tsx
"use client"

import * as React from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"

export default function Login() {
  const [loading, setLoading] = React.useState(false)

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)

    setTimeout(() => {
      setLoading(false)
      alert("Logged in!")
    }, 1200)
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950">
      <Card className="w-full max-w-md bg-slate-900 text-white">
        <CardHeader>
          <CardTitle>Login</CardTitle>
        </CardHeader>

        <form onSubmit={onSubmit}>
          <CardContent className="space-y-4">
            <div>
              <Label>Email</Label>
              <Input placeholder="you@example.com" />
            </div>

            <div>
              <Label>Password</Label>
              <Input type="password" />
            </div>

            <Button className="w-full" disabled={loading}>
              {loading ? "Signing in..." : "Sign in"}
            </Button>
          </CardContent>
        </form>
      </Card>
    </div>
  )
}
```

---

## 🧠 What you just gained

* composable layout system
* accessible inputs
* reusable primitives
* full styling control
* zero black-box dependency lock-in

---

# 6. 🎨 Design System Architecture

## CSS Variables (token system)

```css
:root {
  --background: 0 0% 100%;
  --primary: 221.2 83.2% 53.3%;
  --radius: 0.5rem;
}
```

---

## Tailwind binding

```ts
colors: {
  background: "hsl(var(--background))",
  primary: "hsl(var(--primary))"
}
```

---

## 🧠 Result

You now have:

* theme system
* design tokens
* dark mode support
* scalable UI architecture

---

# 7. 🌙 Dark Mode System

```css
.dark {
  --background: 222.2 84% 4.9%;
  --primary: 217.2 91.2% 59.8%;
}
```

Toggle:

```tsx
<html className="dark">
```

---

# 8. ⚙️ Production Architecture (IMPORTANT)

## Recommended structure

```text
components/
  ui/           → shadcn primitives
  forms/        → form compositions
  layout/       → nav, sidebar
  features/     → domain-specific UI
```

---

# 9. 🧠 Core Engineering Principles

## ✔ DO

* treat `/ui` as owned code
* modify components freely
* extend CVA variants
* compose instead of wrapping

---

## ❌ DON’T

* over-wrap primitives
* create abstraction layers too early
* treat it like a locked library
* duplicate component logic unnecessarily

---

# 10. 🚀 Advanced Patterns

## Pattern 1: Slot composition

```tsx
<Button asChild>
  <a href="/docs">Docs</a>
</Button>
```

---

## Pattern 2: Controlled components

```tsx
<Dialog open={open} onOpenChange={setOpen} />
```

---

## Pattern 3: Feature-level composition

```text
LoginForm (feature)
  ├── Input (ui)
  ├── Button (ui)
  ├── Card (ui)
```

---

# 11. 🧠 Final Mental Model (Most Important Section)

Think of shadcn/ui as:

> A system where **your UI is not imported — it is generated, owned, and evolved inside your codebase**

Not:

> a UI library

But:

> a **frontend architecture foundation**

Just tell me the direction.
