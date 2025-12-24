## 🛡️ CI/CD Security Pipeline (`security-scan.yml`)

Create this file in `.github/workflows/security-scan.yml`.

```yaml
name: "Security Scan"

on:
  push:
    branches: [ "main", "master" ]
  pull_request:
    branches: [ "main", "master" ]
  schedule:
    - cron: '30 1 * * 1' # Runs every Monday at 1:30 AM

jobs:
  analyze:
    name: CodeQL Analysis
    runs-on: ubuntu-latest
    permissions:
      security-events: write # Required to post results to the Security tab

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    # 1. Initialize CodeQL for Python and JavaScript
    - name: Initialize CodeQL
      uses: github/codeql-action/init@v3
      with:
        languages: 'javascript, python'

    # 2. Perform CodeQL Analysis (Scans for SQLi, XSS, etc.)
    - name: Perform Analysis
      uses: github/codeql-action/analyze@v3

  dependency-check:
    name: Dependency Vulnerability Scan
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    # 3. Scan Python Requirements for known vulnerabilities
    - name: Check Python Dependencies
      run: |
        pip install safety
        safety check -r backend/requirements.txt
      continue-on-error: true # Warning only, change to false to block builds

    # 4. Scan Node.js Dependencies (npm audit)
    - name: Check Frontend Dependencies
      working-directory: ./frontend
      run: npm audit --audit-level=high

```

---

## 🔍 What this Pipeline Protects

### 1. Static Analysis (SAST) with CodeQL

CodeQL treats code as data. It doesn't just look for patterns; it tracks the **flow of data** from a "source" (like a URL parameter) to a "sink" (like a database query). If it detects data moving from an untrusted source to a database query without being sanitized, it flags a **SQL Injection** vulnerability.

### 2. Dependency Auditing (SCA)

Modern apps are 80% third-party libraries. This pipeline checks your `requirements.txt` and `package.json` against databases of known CVEs (Common Vulnerabilities and Exposures).

* **Safety:** Specifically targets Python packages (e.g., detecting an old, vulnerable version of Django).
* **NPM Audit:** Scans for "Prototype Pollution" or malicious packages in your React tree.

---

## 🚦 How to Read Results

Once active, you can find the detailed findings in your GitHub repository:

1. Go to the **Security** tab.
2. Click **Code scanning alerts**.
3. GitHub will show you the exact line of code, the risk level, and a recommendation on how to fix it.

---

### 🎓 Final Security Posture

With this workflow, you have implemented a **"Shift Left"** strategy—identifying security flaws during development rather than after deployment. Your architecture is now protected by:

* **Infrastructure Security** (Nginx + SSL)
* **Application Security** (JWT + CSRF + Throttling)
* **Automated Security** (CodeQL CI/CD)

