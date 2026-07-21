# Primer 3: Containers & Docker from Zero

**Feeds into:** Phase 3 (the multi-stage Dockerfile, docker-compose for PostgreSQL) and Phase 4 (image scanning & signing).
**You'll be ready when:** you can read our `Dockerfile` line by line and explain what each instruction adds, why it runs as a non-root user, and why we scan the *image* separately from the code.

**No prerequisite primers** — but Primer 1's request/response model helps when we talk about ports.

---

## Why this matters

For an application developer, containers are usually the biggest conceptual leap in the whole DevSecOps journey. Up to now everything lived in files you could open. Suddenly there's an "image," a "container," "layers," a "registry," and a `Dockerfile` full of unfamiliar keywords — and Phase 4 asks you to *scan* and *cryptographically sign* these mysterious things.

Here's the reassuring part: containers are far simpler than they look, and once the core metaphor clicks, the rest falls into place fast. And it matters for *security* specifically, because the container is the actual thing that runs in production. Two of our threat-model concerns live here:

- **Supply chain** — the image bundles *someone else's* operating system and libraries; a vulnerability in any of them becomes *your* vulnerability (Phase 4 image scanning).
- **Elevation of privilege** — if an attacker breaks into a container running as root, they have admin *inside* it (which is why our Dockerfile drops to a non-root user).

Let's build the mental model from the ground up.

---

## Part A: The problem containers solve — "works on my machine"

Every developer has lived this nightmare. The app runs perfectly on your laptop. You send it to a teammate — it crashes. You deploy it to a server — it crashes differently. Why?

Because software doesn't run in a vacuum. It depends on a hundred invisible things: the exact Node.js version, specific system libraries, environment variables, file paths, the operating system itself. Your laptop has one particular combination of all these; the server has another. The app that "works on my machine" was silently relying on *your machine's* specific setup.

> **The moving-house analogy:** Imagine moving to a new home by carrying your furniture over loose, one piece at a time. The couch arrives, but the screws are missing. The table comes, but not its legs. Something always gets lost or doesn't fit the new space. Now imagine instead you pack *everything* — furniture, screws, instructions, even a chunk of the old floor it sat on — into a **standardized shipping container**. You seal it, ship it, and when it arrives *anywhere in the world*, you open it and everything is exactly as you left it. It just works, because you shipped the *whole environment*, not just the contents.

That's the entire idea of software containers, and it's literally where the name comes from. Instead of shipping just your code and *hoping* the destination has the right environment, you package your code **together with its entire environment** — the right Node version, the right libraries, the right OS files — into one sealed, portable unit that runs identically everywhere.

> **Definition — Docker:** The most popular tool for building and running containers. "Docker" is to containers what "Kleenex" is to tissues — technically a brand, colloquially the whole concept.

---

## Part B: The two words you must not confuse — image vs container

Beginners mix these up constantly, and Phase 4 makes no sense until you separate them. They have a precise relationship:

> **Definition — Image:** The *blueprint* / the *sealed, packed shipping container sitting in the warehouse*. It's a static, read-only package containing your app + its environment. It isn't running — it's a template, waiting.
>
> **Definition — Container:** A *running instance* of an image. It's what you get when you *open* the shipping container and start using what's inside.

> **The clearest analogy — class vs object, or recipe vs meal:**
> - An **image** is a **recipe** (or a cookie cutter). Written once, stored, unchanging.
> - A **container** is the **actual cooked meal** (or the actual cookie). You can make *many* meals from one recipe, all identical.
>
> One image → many containers. You build the image *once*, then run it as containers *many times* (three copies of your API behind a load balancer = one image, three containers).

Why the distinction is a *security* distinction: in Phase 4 we scan and sign the **image** (the recipe), because that's the immutable artifact we can inspect and vouch for once and trust everywhere it runs. You don't scan each running container individually; you scan the one blueprint they all come from. Nail this and Phase 4's "scan the image, sign the image, verify the image before deploy" reads naturally.

---

## Part C: How an image is built — layers

Now the part that explains *why our Dockerfile is structured so carefully*. Images aren't built as one solid block. They're built in **layers**, stacked on top of each other.

> **Definition — Layer:** Each instruction in a Dockerfile creates a new, read-only layer on top of the previous ones. The final image is all those layers stacked together.

> **The transparent-sheets analogy:** Picture an old-school overhead projector. You start with a base sheet (the operating system). On top you lay another transparent sheet (install Node). On top of that, another (copy in your dependencies). Then another (copy in your code). Stack them all and shine the light through — you see the complete picture. Each sheet is a *layer*; the stack is the *image*.

Two enormous benefits come from this, and both show up in our code:

### Benefit 1: Caching = fast rebuilds
Docker **caches** each layer. If you change only your app's code (the top sheet), Docker reuses the cached lower sheets (OS, Node, dependencies) and only rebuilds the top one. That's why our Phase 3 Dockerfile does this:

```dockerfile
COPY package.json package-lock.json ./   # copy ONLY dependency manifests first
RUN npm ci                                # install deps → this becomes a cached layer
COPY src ./src                            # copy source code LAST
```

We copy the dependency list *before* the source code **on purpose.** Your dependencies change rarely, but your code changes constantly. By putting the slow `npm ci` step in its own early layer, Docker caches it — so editing a line of code doesn't force a full re-install every build. It's a deliberate ordering for speed. (This ordering is one of the most common "why is my Docker build so slow?" fixes.)

### Benefit 2: Layers are why image scanning exists
Remember from Phase 4: a vulnerability can hide in *any* layer. That outdated OpenSSL library isn't in *your* code layer — it's baked into the *base OS* layer you inherited from `node:20-alpine`. Source scanning (Phase 2) only ever sees your top layer. **Image scanning (Phase 4) shines the light through *all* the sheets**, checking every layer's contents against the CVE database. That's precisely why "my code is clean" ≠ "my image is clean."

---

## Part D: The base image — you're standing on someone else's shoulders

Every Dockerfile starts with `FROM`:

```dockerfile
FROM node:20-alpine
```

> **Definition — Base image:** The starting layer(s) you build *on top of* — a pre-made image someone else published, usually containing an OS and a runtime.

`node:20-alpine` means "start from an image that already has Node.js 20 installed, on top of Alpine Linux." You inherit all of it instantly instead of installing an OS and Node from scratch.

This is a huge convenience — and a huge **supply-chain responsibility**. You are trusting whoever built that base image. Everything in it becomes part of *your* image and *your* attack surface.

Two security decisions in our Dockerfile flow directly from this:

1. **We chose `alpine`.** Alpine Linux is a *minimal* base — a few megabytes with very few packages. Compare it to a full Ubuntu base (hundreds of packages). **Fewer packages = fewer potential vulnerabilities = a smaller attack surface = a quieter Phase 4 scan.** Minimalism is a security strategy. (This is why Phase 4's image scan comes back clean where a bloated base would light up red.)

2. **We pin a version (`20`, not `latest`).** `latest` is a moving target — it can silently change under you, breaking builds and defeating reproducibility. Pinning a version means you build the *same* thing every time, which is essential for the "sign it once, trust it everywhere" model in Phase 4.

---

## Part E: Reading our actual Dockerfile — the multi-stage build

Now you have every concept needed to read Phase 3's `Dockerfile` and understand *why* it's a **multi-stage build**. Here's the core idea:

> **The messy-kitchen / clean-plate analogy:** To cook a great meal you need a messy kitchen full of tools — mixers, knives, flour everywhere, the compiler, dev dependencies. But you don't *serve* the customer the whole messy kitchen. You plate the finished dish on a clean plate and send *only that* out. A multi-stage build cooks in a messy "build stage," then copies *only the finished food* onto a fresh, clean "runtime stage."

Watch it happen in two `FROM` statements:

```dockerfile
# ── STAGE 1: Build (the messy kitchen) ──────────────
FROM node:20-alpine AS build          # a full build environment
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci                            # installs ALL deps, including dev tools
COPY src ./src
RUN npm run build                     # compiles TypeScript → dist/
RUN npm ci --omit=dev                 # then strips dev deps

# ── STAGE 2: Runtime (the clean plate) ──────────────
FROM node:20-alpine AS runtime        # a FRESH, empty base — nothing carried over
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules   # copy ONLY the finished food:
COPY --from=build /app/dist ./dist                   #   compiled code + prod deps
USER node                             # drop to non-root user (security!)
CMD ["node", "dist/server.js"]
```

The payoff, all security-relevant:
- The final image contains **no TypeScript compiler, no dev dependencies, no source `.ts` files** — just the compiled output and production dependencies. Fewer things = smaller attack surface.
- It's dramatically **smaller** (~180 MB vs ~1.1 GB). Smaller images pull faster *and* give the Phase 4 scanner less to flag.
- `COPY --from=build` is the "plating" step — reaching back into the messy kitchen to grab *only* the finished dish.

### The `USER node` line — the single most important security instruction
```dockerfile
USER node   # stop running as root; run as an unprivileged user
```

By default, a container runs as **root** — the all-powerful admin user. That's dangerous: if an attacker exploits your app and breaks into the container, they inherit root's powers *inside* it, making further attacks (installing tools, escaping the container) much easier.

> **The hotel-guest analogy:** Giving your app root inside the container is like handing every hotel guest the master key to *every* room and the manager's office. `USER node` gives them a key to *only their own room*. If a guest turns out to be a burglar, the damage is contained to one room instead of the whole hotel.

This is **least privilege** — the principle of giving software only the minimum power it needs — and it directly defends the "Elevation of privilege" threat from our model. It's why Phase 4's image scan and Dockerfile audit both check "does this run as non-root?"

---

## Part F: Ports and networking — how you talk to a container

A container is *isolated* by design — it's a sealed box. So how does an HTTP request (Primer 1!) get *into* it? Through **ports**.

> **Definition — Port:** A numbered "door" on a machine through which network traffic flows. Our app listens on port 3000 *inside* its container.

But the container's port 3000 is inside the sealed box — the outside world can't reach it yet. You have to **publish** (map) it to a port on the host machine:

```bash
docker run -p 3001:3000 securenotes:local
#             │    │
#             │    └─ port INSIDE the container (where the app listens)
#             └────── port on YOUR machine (what you connect to)
```

> **The apartment-building analogy:** The container's internal port 3000 is an apartment's front door *inside* the building. `-p 3001:3000` is the building's public street-facing entrance (3001) with a sign pointing to that apartment. Visitors (requests) arrive at the street entrance; the building routes them to the right apartment. Without publishing a port, the apartment exists but has no public entrance — nobody outside can reach it.

That's why Phase 3's verification uses `curl http://localhost:3001/health` — you're knocking on the *host* port 3001, which forwards into the container's port 3000 where the app is listening. (Note the security implication: only ports you *explicitly* publish are reachable. Everything else stays sealed inside — isolation by default is a security feature.)

---

## Part G: docker-compose — orchestrating more than one container

Real apps aren't one container. `securenotes` needs *two* things running: the app **and** a PostgreSQL database. Starting each by hand with long `docker run` commands is tedious and error-prone. That's what **docker-compose** solves.

> **Definition — Docker Compose:** A tool that lets you define multiple containers (and how they connect) in one YAML file, then start them all with a single command (`docker compose up`).

> **The stage-manager analogy:** Running containers one by one is like an actor setting up their own lights, props, and sound before a play. `docker-compose.yml` is the *stage manager's script* — one document listing every element and cue, so a single "places, everyone!" (`docker compose up`) launches the whole production in coordination.

Our Phase 3 `docker-compose.yml` defines the PostgreSQL service so you get a real database with one command — no manual database install required. It also wires in the schema file and a persistent volume so data survives restarts. This is why Phase 3's verification is just `docker compose up -d` and the database is *there*, correctly configured, every time.

---

## Part H: The registry — shipping the image

Finally: you've built an image locally. How does it get to production, or to the Phase 4 CI pipeline that scans and signs it? You push it to a **registry**.

> **Definition — Container Registry:** A warehouse for storing and sharing images — like npm for containers, or GitHub for code. We use **GHCR** (GitHub Container Registry) in Phase 4.

> **The library analogy:** You write a book (build an image) and donate it to a public library (push to a registry). Now anyone with a card can borrow it (pull the image) — including your production servers and your CI pipeline. The registry is the shared shelf everyone reads from.

This closes the Phase 4 loop and explains its whole shape:
1. CI **builds** the image.
2. CI **pushes** it to the registry (GHCR) — identified by an immutable **digest** (`sha256:...`).
3. CI **scans** that exact image in the registry (Phase 4).
4. CI **signs** it (Phase 4) — a tamper-proof seal on the library book.
5. Deploy **pulls** it from the registry, but only after **verifying the signature**.

The registry is the central shelf that build, scan, sign, and deploy all point at — which is why we always refer to the image by its unchangeable *digest*, not a mutable tag: so the book you scanned and signed is *exactly* the book that gets borrowed and run.

---

## The six things to carry into Phases 3 & 4

1. **A container ships the whole environment**, not just code — killing "works on my machine."
2. **Image = blueprint (recipe); Container = running instance (meal).** One image, many containers. We scan and sign the *image*.
3. **Images are built in layers**, and Docker caches them — which is why we copy `package.json` before source code (speed).
4. **You inherit the base image's contents and risks** — so we pick minimal `alpine`, pin the version, and scan every layer in Phase 4.
5. **Multi-stage builds + `USER node`** give a small image and least privilege — smaller attack surface, contained damage (defends Elevation of privilege).
6. **Registry + digest** are the shared shelf and the immutable ID that make "build → scan → sign → verify → deploy" trustworthy end to end.

---

## ✅ Self-check

1. Your app runs fine locally but crashes on a teammate's laptop. In one sentence, how does containerizing it fix this?
2. What's the difference between an image and a container? Which one do we scan and sign, and why that one?
3. Why does our Dockerfile `COPY package.json` and run `npm ci` *before* copying the source code?
4. Phase 2's source scan came back clean, but Phase 4's image scan finds a HIGH-severity CVE. How is that possible?
5. Why does our Dockerfile end with `USER node`, and which STRIDE threat does that address?
6. You run `docker run -p 8080:3000 securenotes`. Which port do you point `curl` at, and why?
