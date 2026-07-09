# Part 2: Creating a Next.js 16 App with Tailwind CSS v4

## 1. Create the project

In your terminal, navigate to your dev folder and run:

```bash
cd ~/dev
npx create-next-app@latest acme-boards
```

This pulls the latest `create-next-app`, which at time of writing scaffolds a **Next.js 16** project. You'll be asked several questions. Answer like this:

```
Would you like to use TypeScript?  Yes
Would you like to use ESLint?      Yes
Would you like to use Tailwind CSS? Yes
Would you like to use `src/` directory? Yes
Would you like to use App Router? Yes
Would you like to use Turbopack for `next dev`? Yes
Would you like to customize the default import alias (@/*)? No
```

This scaffolds a full Next.js 16 app **with Tailwind CSS v4 already installed and configured** - `create-next-app` does this for us automatically, so there's no separate Tailwind install step needed. Turbopack is now the default bundler in Next.js 16 for both `next dev` and `next build`.

## 2. Open the project

```bash
cd acme-boards
code .
```

(`code .` opens the current folder in VS Code, assuming you installed the VS Code command-line shortcut - if that doesn't work, just open VS Code and use File → Open Folder.)

## 3. Explore the structure

```
acme-boards/
├── src/
│   └── app/
│       ├── layout.tsx
│       ├── page.tsx
│       └── globals.css
├── public/
├── package.json
├── tsconfig.json
└── next.config.ts
```

Key files:
- `src/app/layout.tsx` - the root layout, wraps every page. This is where we'll add `ClerkProvider` in Part 5.
- `src/app/page.tsx` - your homepage.
- `src/app/globals.css` - contains the Tailwind import directive.

Notice there's **no `tailwind.config.ts` file** - Tailwind CSS v4 uses a CSS-first configuration approach. Open `src/app/globals.css` and confirm it contains:

```css
@import "tailwindcss";
```

That single line is all that's needed to enable Tailwind v4 - no config file, no content-path globs to maintain. If you ever need custom theme values (custom colors, fonts, etc.), Tailwind v4 lets you define them directly in this CSS file using an `@theme` block, but we won't need that for this tutorial.

## 4. Run the dev server

```bash
npm run dev
```

Next.js 16 will start the dev server using **Turbopack** by default - you'll see this mentioned in the terminal output. Open http://localhost:3000 in your browser. You should see the default Next.js starter page, already styled with Tailwind.

## 5. Quick sanity check that Tailwind works

Open `src/app/page.tsx` and replace its contents with:

```tsx
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-gray-50">
      <h1 className="text-4xl font-bold text-blue-600">Acme Boards</h1>
      <p className="mt-2 text-gray-600">If this text is styled, Tailwind works!</p>
    </main>
  );
}
```

Save, and check your browser (it should hot-reload automatically, and quickly thanks to Turbopack). You should see a large blue bold heading and gray subtext, centered on the page. If the text is unstyled black serif text, see Troubleshooting below.

## 6. First Git commit

```bash
git init
git add .
git commit -m "Initial commit: Next.js 16 + Tailwind v4 starter"
```

(If `create-next-app` already initialized git for you, `git init` will just say it's already a repo - that's fine.)

Later, in Part 14, we'll push this to GitHub for deployment. For now, having local commits as we go is good practice - commit after each part.

## Checkpoint

- [ ] `acme-boards` project created with TypeScript, Tailwind CSS v4, App Router, `src/` directory, Turbopack
- [ ] Dev server runs at http://localhost:3000
- [ ] Tailwind utility classes visibly style the homepage
- [ ] Project committed to a local git repo

## Troubleshooting

**Tailwind classes have no visual effect.**
In Tailwind v4's CSS-first setup, this is rarer than in older versions since there's no content-path config to misconfigure, but double-check `globals.css` still contains `@import "tailwindcss";` and that `layout.tsx` actually imports `./globals.css`.

**Port 3000 already in use.**
Another process is using it. Either stop that process, or run `npm run dev -- -p 3001` to use a different port.

**`npx create-next-app` fails with a Node version error.**
Next.js 16 requires Node 20.9+ or 22 LTS. Go back to Part 1 and confirm `node -v` reports a compatible version.

**`npx create-next-app` hangs or fails to download.**
Check your internet connection, or try again - npm registry hiccups happen. You can also try `npm create next-app@latest acme-boards` as an alternative invocation.

**`code .` doesn't open VS Code.**
The VS Code CLI shortcut isn't installed. In VS Code, open the Command Palette (Cmd/Ctrl+Shift+P), type "Shell Command: Install 'code' command in PATH", and run it. Or just open VS Code manually and use File → Open Folder each time.

**I see something unexpected about Turbopack in the terminal output (warnings, etc.).**
Turbopack is stable and default in Next.js 16, but if you hit a Turbopack-specific bug with a particular package later in this tutorial, you can fall back to the older webpack bundler by running `next dev --webpack` / `next build --webpack` as a temporary workaround - nothing in this tutorial should require that, but it's good to know the escape hatch exists.

Next up: Part 3, a Tailwind CSS crash course, before we bring in Clerk.
