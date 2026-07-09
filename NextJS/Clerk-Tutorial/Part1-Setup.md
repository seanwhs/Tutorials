# Part 1: Setting Up Your Dev Environment

Before we touch Clerk or Next.js, let's get your computer ready. Skip any step you've already done.

## 1. Install Node.js

Node.js lets you run JavaScript outside the browser, and comes with `npm` (Node Package Manager), which we'll use to install everything else.

**Important for this series: Next.js 16 requires Node.js 20.9 or higher, or Node 22 LTS.** Older versions (like Node 18) are not supported.

1. Go to https://nodejs.org
2. Download the **LTS** (Long Term Support) version - at time of writing this is Node 22, which satisfies Next.js 16's requirement.
3. Run the installer, accepting the defaults.
4. Verify it worked. Open a terminal (Terminal on Mac/Linux, Command Prompt or PowerShell on Windows) and run:

```bash
node -v
npm -v
```

You should see version numbers (e.g. `v22.11.0` and `10.9.0`). If you see "command not found", restart your terminal (and computer, if that doesn't help) and try again. **If your version starts with `v18` or lower, you must upgrade** before continuing - Next.js 16 will refuse to run otherwise.

## 2. Install VS Code

1. Go to https://code.visualstudio.com
2. Download and install for your OS.
3. Open it once to confirm it launches.

Recommended free extensions (optional but helpful): **Tailwind CSS IntelliSense**, **ESLint**, **Prettier**.

## 3. Install Git

Git tracks changes to your code and lets you push it to GitHub.

1. Go to https://git-scm.com/downloads
2. Install for your OS (defaults are fine).
3. Verify:

```bash
git --version
```

## 4. Create a GitHub account

1. Go to https://github.com and sign up (free).
2. We'll use this in Part 14 to deploy to Vercel, but it's good to have ready now.

## 5. Configure Git with your identity

In your terminal, run (replace with your own info):

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

## 6. Pick a folder for your projects

Create a folder somewhere sensible, e.g.:

```bash
mkdir ~/dev
cd ~/dev
```

We'll create our actual project inside here in Part 2.

## Checkpoint

You should now have:
- [ ] Node.js 20.9+ (ideally Node 22 LTS) and npm installed and verified via `node -v` / `npm -v`
- [ ] VS Code installed
- [ ] Git installed and verified via `git --version`
- [ ] A GitHub account
- [ ] Git configured with your name/email
- [ ] A `dev` folder ready for projects

## Troubleshooting

**"node: command not found" after installing.**
Your terminal was opened before Node finished installing, or your PATH wasn't updated. Fully close and reopen the terminal (sometimes a computer restart is needed on Windows). Re-run `node -v`.

**`node -v` shows an old version like v16 or v18.**
This will cause `create-next-app` (Part 2) or `next dev`/`next build` to fail outright on Next.js 16, often with an explicit error naming the minimum required version. Uninstall the old Node version completely and install the current LTS (Node 22) fresh from nodejs.org. If you use a version manager (see below), switch to a compatible version instead of reinstalling globally.

**I already have a Node version manager (nvm, fnm, volta) installed.**
That's fine - just make sure the *active* version reports 20.9 or higher via `node -v`. With nvm, for example: `nvm install 22 && nvm use 22`.

**`npm -v` works but `node -v` doesn't (or vice versa).**
This is rare but can happen with a broken install. Uninstall Node completely and reinstall the LTS version fresh from nodejs.org.

**Git asks for a username/password when pushing later and it fails.**
GitHub no longer accepts plain passwords for Git operations. When we get to Part 14 (deployment) we'll use the GitHub website/desktop flow or a personal access token - don't worry about this now.

**VS Code terminal vs system terminal.**
VS Code has a built-in terminal (View → Terminal). It's the same as your system terminal, just convenient. Feel free to use either throughout this series.

Next up: Part 2, where we create your first Next.js 16 + Tailwind CSS v4 project.
