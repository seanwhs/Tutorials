# Part 10: Theming Clerk with Tailwind (appearance prop + dark mode)

If you'd rather keep using Clerk's prebuilt components (Part 6) but want them to visually match your Tailwind design system, Clerk's `appearance` prop is the tool for that — no need to go fully headless like Part 9.

## 1. A global appearance object

Create `src/lib/clerkAppearance.ts`:

```ts
import type { Appearance } from "@clerk/types";

export const clerkAppearance: Appearance = {
  variables: {
    colorPrimary: "#2563eb", // Tailwind's blue-600
    colorText: "#111827", // Tailwind's gray-900
    colorTextSecondary: "#4b5563", // Tailwind's gray-600
    colorBackground: "#ffffff",
    colorInputBackground: "#ffffff",
    colorInputText: "#111827",
    borderRadius: "0.375rem", // Tailwind's rounded-md
    fontFamily: "inherit",
  },
  elements: {
    card: "shadow-md border border-gray-200",
    formButtonPrimary:
      "bg-blue-600 hover:bg-blue-700 text-sm normal-case font-medium",
    footerActionLink: "text-blue-600 hover:text-blue-700",
    formFieldInput:
      "border-gray-300 focus:border-blue-500 focus:ring-blue-500",
  },
};
```

Clerk's `appearance` prop has two layers:
- **`variables`** — high-level design tokens (colors, radius, fonts) that cascade through every internal element automatically. Start here for 90% of theming needs.
- **`elements`** — target specific internal parts by name (e.g. `card`, `formButtonPrimary`) and pass your own Tailwind classes directly onto them, for fine-grained overrides `variables` can't reach.

Note the hex values here (`#2563eb`, etc.) are Tailwind v3/v4 default palette values expressed as plain CSS — since Clerk's `variables` object expects real CSS values, not Tailwind class names, this works identically regardless of which Tailwind config style your project uses.

## 2. Apply it globally via `ClerkProvider`

Update `src/app/layout.tsx`:

```tsx
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import { clerkAppearance } from "@/lib/clerkAppearance";
import "./globals.css";

export const metadata: Metadata = {
  title: "Acme Boards",
  description: "A Next.js + Clerk + Tailwind demo app",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <ClerkProvider appearance={clerkAppearance}>
      <html lang="en">
        <body className="antialiased">{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

Passing `appearance` to `ClerkProvider` applies it to **every** Clerk component in the app (`SignIn`, `SignUp`, `UserButton`, `OrganizationSwitcher`, etc.) — no need to repeat it per-component. You can still override it per-instance by passing `appearance` directly to an individual component too, which merges with the global one.

## 3. Test it

Restart the dev server (`Ctrl+C` then `npm run dev`) and visit `/sign-in` and `/sign-up`. You should see:
- The primary button now blue (`blue-600`), matching your homepage buttons
- Slightly more pronounced card shadow/border
- Input focus rings in blue instead of Clerk's default color

Visit `/dashboard` and click your `UserButton` avatar — the dropdown/modal should also reflect the same primary color.

## 4. Adding dark mode support

Clerk ships a prebuilt dark theme you can combine with your own tokens. Install nothing extra — it's part of `@clerk/themes` which comes bundled with `@clerk/nextjs`.

Update `src/app/layout.tsx` to conditionally apply it based on a simple approach: following the system preference via CSS, combined with Clerk's `dark` theme object as a base when in dark mode. For a straightforward version that follows OS dark mode automatically:

```tsx
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import { dark } from "@clerk/themes";
import { clerkAppearance } from "@/lib/clerkAppearance";
import "./globals.css";

export const metadata: Metadata = {
  title: "Acme Boards",
  description: "A Next.js + Clerk + Tailwind demo app",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <ClerkProvider
      appearance={{
        baseTheme: undefined, // swap to `dark` conditionally - see note below
        ...clerkAppearance,
      }}
    >
      <html lang="en">
        <body className="antialiased">{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

**Note on true dynamic dark mode:** `ClerkProvider` is rendered once on the server as part of the root layout, so toggling `baseTheme` based on live client state (like a dark-mode toggle button) requires either (a) a small client component wrapper that reads a theme preference (e.g. from `localStorage` or a cookie) and re-renders `ClerkProvider`'s children appropriately, or (b) simply always including `dark` conditionally based on a server-read cookie you set from a theme toggle (reading that cookie server-side uses the async `cookies()` API from Next.js 16 - `await cookies()` - inside the Server Component that renders `RootLayout`). Implementing a full toggle button is a great extension exercise, but out of scope for this tutorial — the important concept to take away is: `baseTheme: dark` (imported from `@clerk/themes`) switches Clerk's components to their dark palette, and your `variables`/`elements` overrides still layer on top of whichever base theme is active.

## 5. Commit

```bash
git add .
git commit -m "Theme Clerk components with Tailwind-matching appearance config"
```

## Checkpoint

- [ ] `src/lib/clerkAppearance.ts` created with `variables` and `elements`
- [ ] `ClerkProvider` in `layout.tsx` applies the appearance globally
- [ ] Sign-in/sign-up buttons and focus states now match your Tailwind blue
- [ ] You understand how `baseTheme: dark` from `@clerk/themes` works conceptually

## Troubleshooting

**Colors didn't change after editing `clerkAppearance.ts`.**
Restart the dev server — appearance config is read at initialization in some cached scenarios, and a hard refresh (Cmd/Ctrl+Shift+R) helps clear any stale CSS.

**TypeScript can't find module `@clerk/types` for the `Appearance` type.**
It's a sub-dependency of `@clerk/nextjs` and should already be available. If you get a resolution error, you can safely drop the type annotation (`: Appearance`) and let TypeScript infer the shape instead — functionality is unaffected.

**`elements` class names don't seem to apply.**
Confirm you're targeting a valid element key — Clerk's internal element names are specific (e.g. `formButtonPrimary`, not `submitButton`). Check Appendix D for a link to Clerk's full appearance element reference, or inspect the rendered DOM (each Clerk element typically has a `data-localization-key` or class hint you can cross-reference).

**I want totally different styling for `/sign-in` vs `/dashboard`'s `UserButton`.**
Pass a component-level `appearance` prop directly to that specific component (e.g. `<UserButton appearance={{...}} />`) — it merges with (and can override) the global one from `ClerkProvider`.

**If I read a theme preference cookie server-side to pick `dark`/`light`, do I need to `await` anything special because of Next.js 16?**
Yes — if you go down that path, reading cookies server-side requires `const cookieStore = await cookies();` (from `next/headers`) inside an async Server Component, consistent with the async dynamic API conventions used throughout this series (see Part 7).

Next up: Part 11, where we add Organizations so users can create and belong to shared team workspaces.
