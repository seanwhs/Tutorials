# Appendix A2: Full Codebase Reference — PulseBoard (Tailwind v4 + Next.js 16 + React 19)

This appendix consolidates every file from the Part 11 capstone into one place for copy-paste reference. File paths are relative to the project root created in Part 2 (`tw4-mastery`).

## A.1 Project Tree

```text
tw4-mastery/
├── package.json
├── postcss.config.mjs
├── tsconfig.json
├── .prettierrc.json
├── .vscode/
│   └── settings.json
└── src/
    ├── app/
    │   ├── layout.tsx
    │   ├── globals.css
    │   └── page.tsx
    ├── components/
    │   ├── ui/
    │   │   ├── Card.tsx
    │   │   ├── Button.tsx
    │   │   ├── Badge.tsx
    │   │   └── Alert.tsx
    │   ├── ThemeToggle.tsx
    │   ├── Sidebar.tsx
    │   ├── Topbar.tsx
    │   ├── StatGrid.tsx
    │   ├── RevenueChartCard.tsx
    │   ├── RecentActivityFeed.tsx
    │   └── PlanUsagePanel.tsx
    └── lib/
        ├── cn.ts
        └── fake-data.ts
```

## A.2 `package.json`

```json
{
  "name": "tw4-mastery",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint ."
  },
  "dependencies": {
    "next": "^16.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.5.5",
    "class-variance-authority": "^0.7.1",
    "lucide-react": "^0.460.0"
  },
  "devDependencies": {
    "typescript": "^5.7.0",
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "tailwindcss": "^4.1.0",
    "@tailwindcss/postcss": "^4.1.0",
    "postcss": "^8.5.0",
    "eslint": "^9.0.0",
    "eslint-config-next": "^16.0.0",
    "eslint-plugin-tailwindcss": "^3.17.0",
    "prettier": "^3.4.0",
    "prettier-plugin-tailwindcss": "^0.6.9"
  }
}
```

## A.3 `postcss.config.mjs`

```js
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
```

## A.4 `.prettierrc.json`

```json
{
  "semi": true,
  "singleQuote": false,
  "plugins": ["prettier-plugin-tailwindcss"],
  "tailwindStylesheet": "./src/app/globals.css"
}
```

## A.5 `.vscode/settings.json`

```jsonc
{
  "tailwindCSS.classFunctions": ["cva", "cn", "clsx"],
  "tailwindCSS.experimental.configFile": "src/app/globals.css",
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode"
}
```

## A.6 `src/app/globals.css`

```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
  --color-brand-50:  oklch(0.97 0.02 265);
  --color-brand-100: oklch(0.93 0.05 265);
  --color-brand-500: oklch(0.58 0.22 265);
  --color-brand-600: oklch(0.50 0.22 265);
  --color-brand-700: oklch(0.42 0.20 265);
  --color-brand-900: oklch(0.28 0.14 265);
  --color-success: oklch(0.6 0.16 150);
  --color-warning: oklch(0.75 0.18 80);
  --color-danger:  oklch(0.55 0.22 25);

  --font-display: "Geist", ui-sans-serif, system-ui, sans-serif;
  --font-mono: "Geist Mono", ui-monospace, monospace;

  --radius-xl: 1rem;
  --radius-2xl: 1.5rem;
  --shadow-soft: 0 2px 10px rgb(0 0 0 / 0.06), 0 8px 24px rgb(0 0 0 / 0.08);
  --ease-snappy: cubic-bezier(0.2, 0, 0, 1);
  --animate-fade-in: fade-in 0.4s ease-out;
}

@keyframes fade-in {
  from { opacity: 0; transform: translateY(0.5rem); }
  to { opacity: 1; transform: translateY(0); }
}

body {
  @apply bg-slate-50 text-slate-900 dark:bg-slate-950 dark:text-slate-100;
}
```

## A.7 `src/lib/cn.ts`

```ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

## A.8 `src/lib/fake-data.ts`

```ts
export type ActivityItem = {
  id: string;
  user: string;
  action: string;
  timestamp: string;
};

export const stats = [
  { label: "MRR", value: "$42,900", trend: "up" as const },
  { label: "Active Users", value: "8,120", trend: "up" as const },
  { label: "Churn Rate", value: "1.8%", trend: "down" as const },
  { label: "Avg. Session", value: "6m 12s", trend: "up" as const },
];

export const revenueByMonth = [
  { month: "Jan", value: 28 },
  { month: "Feb", value: 32 },
  { month: "Mar", value: 30 },
  { month: "Apr", value: 38 },
  { month: "May", value: 41 },
  { month: "Jun", value: 47 },
];

export const recentActivity: ActivityItem[] = [
  { id: "1", user: "Ava Chen", action: "upgraded to Pro plan", timestamp: "2m ago" },
  { id: "2", user: "Marcus Lee", action: "invited 3 teammates", timestamp: "18m ago" },
  { id: "3", user: "Priya Nair", action: "created a new workspace", timestamp: "1h ago" },
  { id: "4", user: "Diego Ruiz", action: "cancelled subscription", timestamp: "3h ago" },
];

export const planUsage = {
  plan: "Pro",
  documentsUsed: 420,
  documentsLimit: 1000,
  messagesUsed: 3200,
  messagesLimit: 5000,
};
```

---

*Next: Tailwind v4 Mastery - Appendix A (continued): Component Files*
