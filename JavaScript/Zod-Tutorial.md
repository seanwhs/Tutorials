# 📘 Zod Tutorial

## TypeScript Runtime Validation for Real-World Systems

---

# 🧠 0. The Fundamental Problem (Why This Stack Exists)

TypeScript is excellent for catching bugs during development—but it has one critical limitation:

> ⚠️ TypeScript does NOT exist at runtime.

Once your application runs in production:

* API responses are untrusted
* database results may be malformed
* form inputs are raw strings
* third-party services can break contracts silently

### ❌ The Reality Without Runtime Validation

```ts
type User = {
  id: string;
  name: string;
};

const user = JSON.parse(data);

// 💥 Runtime crash
console.log(user.name.toUpperCase());
```

TypeScript provides no protection here.

---

# 🛡️ 1. Zod: The Runtime Safety Layer

Zod solves this by introducing a **single concept**:

> A schema is both:
>
> * a runtime validator
> * a TypeScript type generator

You define it once → you get safety everywhere.

---

# ⚙️ 2. Setup

```bash
npm install zod
```

Enable strict TypeScript:

```json
{
  "compilerOptions": {
    "strict": true
  }
}
```

---

# 🧱 3. Core Mental Model

A Zod schema is:

> A **runtime blueprint + validator + type generator**

```ts
import { z } from "zod";
```

---

## Primitive Building Blocks

```ts
z.string();
z.number();
z.boolean();
z.date();
```

---

# 🔍 4. Validation Modes

## ❌ parse (throws errors)

```ts
z.string().parse(123);
```

Use when:

* backend logic
* internal services
* fail-fast systems

---

## ✅ safeParse (recommended for external input)

```ts
const result = z.string().safeParse(123);

if (!result.success) {
  console.log(result.error.errors);
} else {
  console.log(result.data);
}
```

---

# 🧠 5. Object Schemas (Core Building Block)

```ts
const UserSchema = z.object({
  id: z.string().uuid(),
  username: z.string().min(3).max(20),
  email: z.string().email(),
  age: z.number().int().positive(),
  isActive: z.boolean().default(true),
});
```

---

## 🎯 Type Inference (Critical Feature)

```ts
type User = z.infer<typeof UserSchema>;
```

Now you have:

* single source of truth
* no duplicate interfaces
* runtime + compile-time alignment

---

# 🧩 6. Handling Missing Data

JavaScript has multiple “empty” states:

| Type      | Meaning             |
| --------- | ------------------- |
| undefined | missing             |
| null      | intentionally empty |

---

```ts
z.string().optional();   // may be undefined
z.string().nullable();   // may be null
z.string().nullish();    // null or undefined
```

---

# 📦 7. Arrays, Tuples, Enums

## Arrays

```ts
z.array(z.string());
```

## Tuples (fixed structure)

```ts
z.tuple([z.number(), z.number(), z.string()]);
```

## Enums

```ts
z.enum(["admin", "editor", "viewer"]);
```

## Literals

```ts
z.literal("VIP_USER");
```

---

# 🔀 8. Unions & Discriminated Unions

## Simple Union

```ts
z.union([z.string(), z.number()]);
```

---

## Production Pattern: Discriminated Union

```ts
const Success = z.object({
  status: z.literal("success"),
  data: z.array(z.string()),
});

const Error = z.object({
  status: z.literal("error"),
  message: z.string(),
});

const ApiResponse = z.discriminatedUnion("status", [
  Success,
  Error,
]);
```

👉 This enables safe API pattern matching.

---

# 🧬 9. Schema Composition (Enterprise Pattern)

## Extend

```ts
const BaseArticle = z.object({
  title: z.string(),
  content: z.string(),
});

const PremiumArticle = BaseArticle.extend({
  paywallTier: z.enum(["gold", "platinum"]),
});
```

---

## Pick / Omit

```ts
BaseArticle.pick({ title: true });
BaseArticle.omit({ content: true });
```

---

## Partial (PATCH updates)

```ts
BaseArticle.partial();
```

---

# 🧱 10. Object Behavior Control

```ts
z.object({ name: z.string() }).strict();      // reject extras
z.object({ name: z.string() }).strip();       // remove extras (default)
z.object({ name: z.string() }).passthrough(); // keep extras
```

---

# 🔄 11. Coercion & Transformation

## Coercion (fix form inputs)

```ts
z.object({
  age: z.coerce.number(),
  isActive: z.coerce.boolean(),
});
```

---

## Transform

```ts
z.string().transform((val) => val.trim());
```

---

# 🧠 12. Custom Validation

## Simple refinement

```ts
z.string().min(8).refine(val => val.includes("!"), {
  message: "Must include !",
});
```

---

## Cross-field validation

```ts
z.object({
  password: z.string(),
  confirmPassword: z.string(),
}).refine(data => data.password === data.confirmPassword, {
  message: "Passwords do not match",
  path: ["confirmPassword"],
});
```

---

# 🌍 13. Real-World API Layer

```ts
const ProductSchema = z.object({
  id: z.number(),
  title: z.string(),
  price: z.coerce.number(),
});

const ProductsSchema = z.array(ProductSchema);
```

---

## Safe Fetch Pattern

```ts
async function fetchProducts() {
  const res = await fetch("/api/products");
  const raw = await res.json();

  const result = ProductsSchema.safeParse(raw);

  if (!result.success) {
    console.error(result.error.format());
    throw new Error("Invalid API response");
  }

  return result.data;
}
```

---

# 🧠 14. Environment Validation (Production Critical)

```ts
const Env = z.object({
  DATABASE_URL: z.string().url(),
  PORT: z.coerce.number(),
});

const env = Env.parse(process.env);
```

Fail fast → prevent broken deployments.

---

# ⚛️ 15. Zod + React Hook Form (Full Production System)

---

# 🧠 Core Idea

We combine:

* Zod → validation + schema + types
* React Hook Form → state management engine
* Resolver → bridge between them

---

# ⚙️ 16. Installation

```bash
npm install react-hook-form zod @hookform/resolvers
```

---

# 🧱 17. Architecture Layers

```
1. Schema Layer (Zod)
2. Type Layer (z.infer)
3. Form Engine (React Hook Form)
4. UI Layer (React components)
```

---

# 📦 18. Define Schema

```ts
export const RegisterSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(8),
  confirmPassword: z.string(),
  age: z.coerce.number().min(18),
  agreeToTerms: z.boolean(),
});
```

---

## Cross-field validation

```ts
export const RegisterSchema = RegisterSchema.refine(
  data => data.password === data.confirmPassword,
  {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  }
);
```

---

# 🧠 19. Infer Types

```ts
export type RegisterFormValues = z.infer<typeof RegisterSchema>;
```

---

# ⚛️ 20. Setup React Hook Form

```ts
const form = useForm<RegisterFormValues>({
  resolver: zodResolver(RegisterSchema),
  mode: "onBlur",
});
```

---

# 🧩 21. UI Layer

```tsx
<form onSubmit={form.handleSubmit(onSubmit)}>
  <input {...form.register("name")} />
  <p>{form.formState.errors.name?.message}</p>

  <input {...form.register("email")} />
  <p>{form.formState.errors.email?.message}</p>

  <button type="submit">Submit</button>
</form>
```

---

# 🧠 22. Execution Flow Mental Model

```
User Input
   ↓
React Hook Form
   ↓
Zod Resolver
   ↓
Zod Schema Validation
   ↓
Typed Result OR Structured Errors
   ↓
UI Updates
```

---

# 🧱 23. Advanced Patterns

## Field arrays

Dynamic lists (skills, items, etc.)

## Async validation

Email uniqueness checks

## Reusable form hooks

```ts
useRegisterForm()
```

## Component abstraction

```tsx
<TextField error={errors.email?.message} />
```

---

# 🧠 24. Final Mental Model

```
Zod        → Truth layer (rules)
RHF        → State engine
UI         → Presentation layer
Resolver   → Translation layer
```

---

# 🚀 Final Summary

This architecture gives you:

### 🛡 Runtime safety

No invalid data enters your system

### 🧠 Type safety

No duplicated interfaces

### ⚡ Clean UI logic

No validation clutter in components

### 🔥 Production scalability

Works for:

* authentication
* checkout systems
* dashboards
* onboarding flows

Just tell me 👍
