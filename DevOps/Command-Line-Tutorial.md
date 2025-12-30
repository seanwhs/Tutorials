# 📘 Command Line Tutorial 

**Edition:** 1.0
**Audience:** Beginners → Intermediate
**Goal:** Learn command line basics and common workflows
**Prerequisites:** None — works on Linux, macOS, and Windows (via Git Bash or PowerShell)

---

# 🧭 Mental Model

Think of the command line as a **direct interface to your computer’s brain**:

```
You (user)
    |
    v
Terminal / Shell
    |
    v
Operating System
    |
    v
Files, Processes, Programs
```

* You type **commands**
* The **shell interprets** them
* The OS executes them
* Output appears on your screen

---

# 🏗️ Step 1: Open the Terminal

* **Linux/macOS:** Use Terminal app
* **Windows:** Use Command Prompt, PowerShell, or Git Bash

**ASCII Diagram: Terminal Stack**

```
+------------------+
| Terminal / Shell |
+------------------+
         |
         v
+------------------+
| Operating System |
+------------------+
         |
         v
+------------------+
| File System / OS |
+------------------+
```

---

# ⚡ Step 2: Basic Navigation

| Command      | Purpose                 | Example       |
| ------------ | ----------------------- | ------------- |
| `pwd`        | Print current directory | `/home/user`  |
| `ls` / `dir` | List files and folders  | `ls -l`       |
| `cd <dir>`   | Change directory        | `cd projects` |
| `cd ..`      | Move up one directory   | `cd ..`       |

**ASCII Diagram: Directory Navigation**

```
/home/user/
├── projects/
│   ├── project1/
│   └── project2/
├── documents/
└── downloads/

pwd → /home/user
cd projects → /home/user/projects
cd .. → /home/user
```

---

# 🏗️ Step 3: File & Folder Operations

| Command           | Purpose                   | Example                  |
| ----------------- | ------------------------- | ------------------------ |
| `touch <file>`    | Create new file           | `touch app.js`           |
| `mkdir <dir>`     | Create new folder         | `mkdir test`             |
| `cp <src> <dest>` | Copy file or folder       | `cp file.txt backup.txt` |
| `mv <src> <dest>` | Move or rename            | `mv old.txt new.txt`     |
| `rm <file>`       | Delete file               | `rm file.txt`            |
| `rm -r <dir>`     | Delete folder recursively | `rm -r test`             |

**ASCII Diagram: File Operations**

```
project/
├── file1.txt
├── file2.txt
└── folder1/

cp file1.txt backup.txt
mv file2.txt folder1/file2.txt
rm backup.txt
```

---

# ⚡ Step 4: Viewing & Editing Files

| Command                      | Purpose               | Example               |
| ---------------------------- | --------------------- | --------------------- |
| `cat <file>`                 | View file contents    | `cat file.txt`        |
| `less <file>`                | Scrollable file view  | `less file.txt`       |
| `head <file>`                | Show first lines      | `head -n 10 file.txt` |
| `tail <file>`                | Show last lines       | `tail -n 10 file.txt` |
| `nano <file>` / `vim <file>` | Edit file in terminal | `nano app.js`         |

---

# 🏗️ Step 5: Searching & Filtering

| Command                      | Purpose           | Example                |
| ---------------------------- | ----------------- | ---------------------- |
| `grep <pattern> <file>`      | Search text       | `grep "TODO" file.txt` |
| `find <dir> -name <pattern>` | Find files        | `find . -name "*.py"`  |
| `sort <file>`                | Sort lines        | `sort file.txt`        |
| `uniq <file>`                | Remove duplicates | `uniq file.txt`        |

**ASCII Diagram: Search Flow**

```
file.txt
├─ line1
├─ TODO: fix bug
├─ line3
└─ TODO: write tests

grep "TODO" file.txt
└─ TODO: fix bug
└─ TODO: write tests
```

---

# ⚡ Step 6: File Permissions & Ownership

* Check permissions:

```bash
ls -l
```

* Modify permissions:

```bash
chmod +x script.sh   # Make executable
chmod 644 file.txt   # Owner read/write, others read
```

* Change owner:

```bash
chown user:group file.txt
```

**ASCII Diagram: Permission Bits**

```
-rwxr-xr--
│ │  │
│ │  └─ others
│ └─ group
└─ owner
```

---

# 🏗️ Step 7: Process Management

| Command         | Purpose                   | Example        |
| --------------- | ------------------------- | -------------- |
| `ps`            | List running processes    | `ps aux`       |
| `top` / `htop`  | Real-time process monitor | `top`          |
| `kill <pid>`    | Terminate process         | `kill 1234`    |
| `kill -9 <pid>` | Force terminate           | `kill -9 1234` |

**ASCII Diagram: Process Flow**

```
Terminal → Launch script → Process ID (PID) → System executes
```

---

# ⚡ Step 8: Package Management

**Linux/macOS Example (Node.js / Python):**

* Node.js (npm):

```bash
npm init -y
npm install express
npm run start
```

* Python (pip):

```bash
python -m venv venv
source venv/bin/activate
pip install requests
```

---

# 🏗️ Step 9: Networking Basics

| Command         | Purpose                  | Example                             |
| --------------- | ------------------------ | ----------------------------------- |
| `ping <host>`   | Check connectivity       | `ping google.com`                   |
| `curl <url>`    | Fetch HTTP resource      | `curl https://example.com`          |
| `wget <url>`    | Download files           | `wget https://example.com/file.zip` |
| `ssh user@host` | Connect to remote server | `ssh root@1.2.3.4`                  |

**ASCII Diagram: Remote Interaction**

```
Local Terminal → SSH → Remote Server
          │
          └─ Commands executed remotely
```

---

# ⚡ Step 10: Redirects & Pipes

* Redirect output to file:

```bash
ls > filelist.txt
```

* Append output:

```bash
echo "Hello" >> file.txt
```

* Pipe between commands:

```bash
cat file.txt | grep "TODO" | sort
```

**ASCII Diagram: Pipe Flow**

```
cat file.txt ──> grep "TODO" ──> sort ──> stdout
```

---

# 🏗️ Step 11: Aliases & Shortcuts

* Create shortcut:

```bash
alias ll='ls -alh'
```

* Make permanent: add to `.bashrc` or `.zshrc`

* Navigate quickly:

```bash
cd ~/projects
cd -       # Previous directory
```

---

# 📝 Best Practices

* Use **tab completion** to speed typing
* Explore commands with `--help`
* Avoid running dangerous commands as root
* Keep organized folder structure

---

# ✅ Key Takeaways

* CLI = **direct interface to OS**
* Learn navigation, file ops, search, permissions, processes
* Pipes & redirects = **powerful data flow**
* CLI mastery improves productivity and debugging skills

---

**Full ASCII Flow Overview of Command Line:**

```
User
  │
  v
Terminal / Shell
  │
  ├─ Navigate Directories
  ├─ Create / Edit Files
  ├─ Run Programs / Scripts
  ├─ Search & Filter
  ├─ Manage Processes
  └─ Interact with Remote Servers
  │
  v
Operating System → Files / Network / CPU / Memory
```

---
