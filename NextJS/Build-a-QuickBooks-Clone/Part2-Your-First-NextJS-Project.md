## Part 2: Your First Next.js Project

Goal: create a real working Next.js 16 project, understand file-based routing, and make your first live edit.

Prerequisite: Part 1 completed (Node.js 20.9+ / 22 LTS installed and verified).

---

### 1. What is a framework?

Next.js is a framework built on React that gives you file-based routing, server components, API routes, and built-in optimization, so you don't build all the plumbing of a website by hand. This course uses **Next.js 16**, which defaults to **Turbopack** (a much faster Rust-based bundler) and requires all dynamic request data (`params`, `searchParams`, `cookies()`, `headers()`) to be read asynchronously — you'll see this pattern starting in Part 12.

### 2. Create your project

In your terminal:

**Mac:**
```
cd ~/Desktop/qb-clone-course
```
**Windows:**
```
cd %USERPROFILE%\Desktop\qb-clone-course
```

Run:
```
npx create-next-app@latest
```

Answer each prompt exactly like this (use arrow keys + Enter):

```
What is your project named?  qb-clone
Would you like to use TypeScript?  Yes
Would you like to use ESLint?  Yes
Would you like to use Tailwind CSS?  Yes
Would you like your code inside a `src/` directory?  Yes
Would you like to use App Router?  Yes
Would you like to use Turbopack for `next dev`?  Yes
Would you like to customize the import alias?  No
```

This takes a minute or two, and scaffolds Next.js 16 with React 19, Turbopack, and Tailwind CSS v4 (CSS-first configuration — no `tailwind.config.js` file, just an `@import "tailwindcss";` line at the top of `globals.css`).

### 3. Open the project

```
cd qb-clone
code .
```

### 4. Run the dev server

In VS Code's terminal (Terminal menu -> New Terminal), confirm you're inside `qb-clone`, then:
```
npm run dev
```

Expected output:
```
  ▲ Next.js 16.x.x
  - Local:        http://localhost:3000

 ✓ Ready in 900ms
```

Open http://localhost:3000 in your browser — you should see the default Next.js welcome page.

Leave this terminal running. Open a second terminal tab (the + icon in VS Code's terminal panel) for other commands.

### 5. Project structure

```
qb-clone/
├── src/
│   └── app/
│       ├── page.tsx        <- homepage
│       ├── layout.tsx      <- wraps every page
│       └── globals.css
├── public/
├── package.json
├── next.config.ts
└── tsconfig.json
```

### 6. File-based routing — create your first new page

Create a new folder `src/app/about/`, then inside it create a file named `page.tsx`. Type this exactly:

```tsx
export default function AboutPage() {
  return (
    <div>
      <h1>About this app</h1>
      <p>This is a QuickBooks clone I'm building to learn Next.js.</p>
    </div>
  );
}
```

Save, then visit http://localhost:3000/about — your new page should appear immediately with no restart needed (Turbopack recompiles almost instantly).

### 7. Edit the homepage

Open `src/app/page.tsx`. Select everything in the file and replace it entirely with:

```tsx
export default function Home() {
  return (
    <main style={{ padding: "2rem" }}>
      <h1>QB Clone</h1>
      <p>Welcome to your QuickBooks clone project.</p>
    </main>
  );
}
```

Save, check http://localhost:3000 — it updates instantly.

### 8. First Git commit

In your second terminal tab:
```
git status
```
You'll see your changed files listed. Then:
```
git add .
git commit -m "Initial Next.js project setup with about page"
```

Expected output ends with something like `2 files changed, 10 insertions(+), 5 deletions(-)`.

---

### ✅ Checkpoint

- [ ] `npm run dev` runs with no errors, http://localhost:3000 loads
- [ ] http://localhost:3000/about shows your custom page
- [ ] You understand: folder + `page.tsx` inside `src/app/` = a URL route
- [ ] `git add .` and `git commit` ran successfully

---

### Troubleshooting

**`npx create-next-app@latest` hangs or fails to download**
Check your internet connection. If it's a corporate/school network, it may block npm's registry — try a different network, or a personal hotspot.

**After answering the prompts, you see "npm error" in red**
Usually a stale npm cache. Run `npm cache clean --force` then try `npx create-next-app@latest` again.

**`npm run dev` says "Cannot find module" or similar**
You're likely not inside the `qb-clone` folder. Run `pwd` (Mac) or `cd` (Windows) to check your location — it should end in `/qb-clone`. If not, `cd qb-clone` and try again. If it still fails, delete the `node_modules` folder and `package-lock.json`, then run `npm install` again.

**Browser shows "This site can't be reached" at localhost:3000**
Check the terminal running `npm run dev` — if it shows an error instead of "Ready", the server never actually started; scroll up in that terminal to find the real error message. Also confirm you're using `http://` not `https://`.

**Port 3000 is already in use**
Another process is using that port (maybe a previous `npm run dev` still running in a closed terminal window). Next.js will usually auto-offer port 3001 instead — check the terminal output for the actual URL it's using. To fully stop the old process on Mac/Linux: `lsof -ti:3000 | xargs kill -9`. On Windows: find the PID with `netstat -ano | findstr :3000` then `taskkill /PID <that number> /F`.

**Editing `page.tsx` doesn't update the browser**
Make sure you actually saved the file (Cmd+S / Ctrl+S). If it still doesn't update, stop the dev server (Ctrl+C in its terminal) and run `npm run dev` again.

**TypeScript red squiggly lines under your JSX**
Make sure the file is named exactly `page.tsx` (not `.js` or `.jsx`) and that VS Code's ESLint/TypeScript extensions finished installing from Part 1. Restarting VS Code often clears stale errors.

**`git commit` says "Please tell me who you are"**
You skipped the one-time Git setup from Part 1. Run the two `git config --global` commands from Part 1's step 3, then commit again.

**`npm run dev` prints an error about Node.js version, or `create-next-app` refuses to run**
Next.js 16 requires Node.js 20.9+. Run `node -v` — if it's below v20.9, revisit Part 1 and reinstall Node.js from nodejs.org (the current LTS), then close and reopen your terminal completely before trying again.
