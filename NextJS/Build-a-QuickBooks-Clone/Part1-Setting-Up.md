## Part 1: Setting Up Your Computer

**Goal:** install every tool this course depends on, and get comfortable with the terminal. No app code yet — this is pure environment setup.

---

### 1. Install Node.js

1. Go to https://nodejs.org
2. Download the **LTS** version
3. Run the installer, accept all defaults, restart your computer if prompted

**Verify it worked.** Open a terminal:
- **Windows:** Press Windows key, type `cmd`, press Enter
- **Mac:** Press Cmd+Space, type `Terminal`, press Enter

Type exactly:
```
node -v
```
Expected output (your exact version may differ): `v20.11.0`

```
npm -v
```
Expected output: `10.2.4` (or similar)

### 2. Install VS Code

1. Go to https://code.visualstudio.com
2. Download and install for your OS, then open it once

### 3. Install Git

1. Go to https://git-scm.com/downloads
2. Download and install (Windows: accept all default options)

**Verify:**
```
git --version
```
Expected output: `git version 2.43.0` (or similar)

**One-time setup — run these two commands, replacing with your own info:**
```
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```
No output means it worked.

### 4. Create a GitHub account

Go to https://github.com, sign up, verify your email.

### 5. Terminal basics

| Command | What it does |
|---|---|
| `cd folder-name` | Move into a folder |
| `cd ..` | Move up one folder |
| `ls` (Mac) / `dir` (Windows) | List files/folders here |
| `mkdir folder-name` | Create a new folder |
| `pwd` | Print where you currently are |

Try it now:

**Mac:**
```
cd ~/Desktop
mkdir qb-clone-course
cd qb-clone-course
pwd
```
Expected output of `pwd`: something like `/Users/yourname/Desktop/qb-clone-course`

**Windows:**
```
cd %USERPROFILE%\Desktop
mkdir qb-clone-course
cd qb-clone-course
cd
```
Expected output: something like `C:\Users\yourname\Desktop\qb-clone-course`

### 6. Install VS Code extensions

Open VS Code, click the Extensions icon (4 squares icon, left sidebar), search for and install each of these:
- **ESLint**
- **Prettier - Code formatter**
- **Tailwind CSS IntelliSense**

---

### ✅ Checkpoint

- [ ] `node -v` prints a version number starting with v18 or higher
- [ ] `npm -v` prints a version number
- [ ] `git --version` prints a version number
- [ ] VS Code opens
- [ ] You have a GitHub account
- [ ] `qb-clone-course` folder exists and your terminal can `cd` into it

---

### Troubleshooting

**`node -v` says "command not found" or "'node' is not recognized"**
Node wasn't installed correctly, or your terminal was opened before you finished installing it. Close ALL terminal/VS Code windows completely, reopen a fresh terminal, and try again. If it still fails, reinstall Node.js from nodejs.org and restart your computer.

**`npm -v` works but `node -v` doesn't (or vice versa)**
This shouldn't normally happen since they install together — try reinstalling Node.js from the official installer again, choosing "Repair" if offered.

**Windows: "running scripts is disabled on this system" when running npm commands later**
This is a PowerShell security setting. Open PowerShell as Administrator and run:
```
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
Type `Y` and press Enter when prompted. Try your command again.

**`git config` commands produce no confirmation — did it work?**
That's normal — these commands succeed silently. Verify by running:
```
git config --global user.name
```
It should print the name you set.

**`mkdir qb-clone-course` says the folder already exists**
That's fine if you already created it — just `cd qb-clone-course` to enter it, or pick a different folder name if you want to start fresh.

**VS Code's "code ." command isn't recognized (you'll need this in Part 2)**
Open VS Code manually now, press Cmd+Shift+P (Mac) or Ctrl+Shift+P (Windows), type "Shell Command: Install 'code' command in PATH", select it, then restart your terminal.

---

Ready for **Part 2: Your First Next.js Project** whenever you want — just say "continue."
