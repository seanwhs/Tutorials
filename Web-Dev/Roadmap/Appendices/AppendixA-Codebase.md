# Appendix A: Codebase Reference

The complete DevBoard project, as it stands after Part 8.

## A.1 Full File Tree

```
devboard/
├── .env.example
├── .env.local                      # gitignored — Neon DATABASE_URL
├── .gitignore
├── next.config.ts
├── package.json
├── postcss.config.mjs
├── tsconfig.json
├── components.json                 # shadcn/ui config
├── prisma/
│   ├── schema.prisma
│   ├── seed.ts
│   └── migrations/
│       └── 20260101000000_init/
│           └── migration.sql
├── lib/
│   ├── db.ts                       # Prisma client singleton
│   └── utils.ts                    # cn() helper (clsx + tailwind-merge)
├── components/
│   └── ui/                         # shadcn/ui generated components
│       ├── button.tsx
│       ├── card.tsx
│       ├── dialog.tsx
│       ├── input.tsx
│       └── label.tsx
└── app/
    ├── layout.tsx
    ├── page.tsx
    ├── globals.css
    ├── actions/
    │   └── cards.ts                # Server Actions: createCard, deleteCard, createColumn
    ├── api/
    │   └── cards/
    │       └── route.ts            # Route Handler (GET/POST/DELETE) — Part 5 reference impl
    ├── board/
    │   ├── page.tsx
    │   └── [boardId]/
    │       └── page.tsx
    └── components/
        ├── AddCardDialog.tsx
        ├── AddCardForm.tsx
        ├── CardColumn.tsx
        ├── PriorityBadge.tsx
        ├── SubmitButton.tsx
        └── ThemeToggle.tsx
```

## A.2 Complete `package.json`

```json
{
  "name": "devboard",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint .",
    "prisma:migrate": "prisma migrate dev",
    "prisma:seed": "prisma db seed"
  },
  "prisma": {
    "seed": "ts-node prisma/seed.ts"
  },
  "dependencies": {
    "next": "^16.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "@prisma/client": "^6.0.0",
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.5.0",
    "lucide-react": "^0.460.0",
    "zod": "^3.24.0",
    "class-variance-authority": "^0.7.0",
    "@radix-ui/react-dialog": "^1.1.0",
    "@radix-ui/react-label": "^2.1.0"
  },
  "devDependencies": {
    "typescript": "^5.7.0",
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "tailwindcss": "^4.0.0",
    "@tailwindcss/postcss": "^4.0.0",
    "postcss": "^8.4.49",
    "eslint": "^9.0.0",
    "eslint-config-next": "^16.0.0",
    "prisma": "^6.0.0",
    "ts-node": "^10.9.2"
  }
}
```

## A.3 `.env.example`

```bash
DATABASE_URL="postgresql://user:password@host/dbname?sslmode=require"
```

## A.4 `.gitignore`

```gitignore
/node_modules
/.next/
/out/
.env*.local
.env
.DS_Store
*.pem
/prisma/migrations/dev.db
```

## A.5 Key Design Decisions Recap

| Decision | Why (see Part) |
|---|---|
| App Router, not Pages Router | Server Components require App Router (Part 5) |
| No `tailwind.config.js` | Tailwind v4 uses CSS-first `@theme` config (Part 7.2) |
| Prisma singleton in `lib/db.ts` | Avoids connection pool leaks on hot reload (Part 8.4) |
| Server Actions instead of a REST client layer | Native form + mutation model, less boilerplate (Part 6.1) |
| shadcn/ui via CLI, not npm package | You own the component source, fully editable (Part 7.4) |

---
*See also: `Roadmap Tutorial - Appendix B: The Web Encyclopedia`, `Roadmap Tutorial - Appendix C: Deployment Checklist`*
