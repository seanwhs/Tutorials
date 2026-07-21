# Primer 2: How Auth Works — Sessions, JWTs, Hashing & bcrypt

**Feeds into:** Phase 2 (registration, login, JWT middleware, bcrypt) and every protected route thereafter.
**You'll be ready when:** you can explain, in one breath, what happens between typing a password and receiving a token — and why each step is built the way it is.

**Prerequisite:** Primer 1 (especially the idea that HTTP is *stateless*). If "stateless" doesn't ring a bell, read that first — it's the reason JWTs exist.

---

## Why this matters most

Authentication is the front door of your application. Get the locks on every other door perfect, and it won't matter if the front door opens for anyone. Two of the six STRIDE threats from our very first threat model live right here:

- **Spoofing** — an attacker pretending to be someone else.
- **Elevation of privilege** — a normal user gaining powers they shouldn't have.

And the failures are catastrophic *and common*: plaintext password leaks, forgeable tokens, credentials in logs. The good news is that the *correct* patterns are well-established and not hard — you just have to understand *why* they're correct, or you'll accidentally undo them.

Let's untangle two ideas that beginners constantly confuse, then build up to how our app actually works.

---

## Part A: The two questions — authentication vs authorization

These sound alike and get mixed up endlessly. They are completely different jobs.

> **Definition — Authentication (authN):** *Who are you?* Proving identity. (Showing your passport at the airport.)
> **Definition — Authorization (authZ):** *What are you allowed to do?* Proving permission. (Your boarding pass says you can board flight 302, seat 14C — but not the cockpit.)

The airport analogy makes it stick:

- **Check-in / passport control = authentication.** They confirm *you are who you say you are*.
- **Your boarding pass = authorization.** It grants access to *specific* things (this flight, this seat), and *nothing else*.

You need **both**, in that order. First we confirm identity (login), *then* on every request we check permission (can this user touch this note?).

In `securenotes`:
- **Authentication** = the `/auth/login` route (Phase 2): prove you're `alice@example.com`.
- **Authorization** = the ownership checks in the note store (Phase 2/3): even though we know you're Alice, you can only touch *Alice's* notes.

> **The classic breach happens when apps do authN but forget authZ.** They confirm you're logged in, then let you read *anyone's* data by changing an ID in the URL (`/notes/123` → `/notes/124`). This is called **IDOR (Insecure Direct Object Reference)**, and it's one of the most common real-world vulnerabilities. Our defense — every query is scoped to the authenticated user's ID (golden rule #4) — exists *specifically* to kill IDOR. Authentication alone would not save us.

Hold onto this: **login proves who you are; ownership checks prove what you can touch.** Now let's build each half correctly.

---

## Part B: Storing passwords — hashing, not encryption

Before anyone can log in, they register, and we must store *something* to check future logins against. What we store — and how — is where the biggest disasters happen.

### The three ways to store a password (two are wrong)

**❌ Way 1: Plaintext.** Store `"secret12345"` as-is. If the database leaks, *every* password is instantly exposed — and since people reuse passwords, you've also compromised their email, bank, and everything else. This is negligence, full stop. Never do it.

**❌ Way 2: Encryption.** Scramble the password with a reversible cipher. Sounds better — but *reversible* is the fatal flaw. Encryption implies a key that turns the scramble *back* into the password. If an attacker gets the database, they usually get the key too (it's often right there in the config), and now they can reverse everything. Encryption is for data you need to *read back later*. A password is not that.

**✅ Way 3: Hashing.** This is the right answer, and it's worth understanding deeply.

> **Definition — Hashing:** A *one-way* mathematical function. It turns any input into a fixed-size fingerprint (the "hash"), and — crucially — **there is no reverse function.** You can turn `"secret12345"` into a hash, but you can *never* turn the hash back into `"secret12345"`.

> **The paper-shredder analogy:** Hashing is a shredder. You can shred a document into confetti (hash the password), but you can never reassemble the confetti into the original document. So how do we check a login? We take the password the user *just typed*, shred it the same way, and compare the two piles of confetti. **Same document always shreds to the same confetti** — so if the piles match, the password was correct. We verified the password *without ever storing or being able to recover it.*

This is the magic: even if our entire database leaks (a `SELECT * FROM users`), the attacker gets only *hashes*, not passwords. There's no key to steal, because there's no reversal at all.

### But plain hashing isn't enough — enter bcrypt

Here's the catch that trips up intermediate developers. A basic fast hash (like SHA-256) is one-way, yes — but it's *fast*. And "fast" is bad for passwords. An attacker with a stolen hash database can't reverse the hashes, so instead they **guess**: they hash billions of common passwords per second and look for matching confetti. Modern GPUs can try *tens of billions* of guesses per second against a fast hash. Your users' weak passwords fall in seconds.

The fix is a hash function that's **deliberately slow**, and that's what **bcrypt** is.

> **Definition — bcrypt:** A password-hashing algorithm designed to be *intentionally slow* and *tunable*. It has a "work factor" (also called cost or rounds) that controls how much computation each hash takes.

In Phase 2 you'll see:
```typescript
const passwordHash = await bcrypt.hash(password, 12);  // the 12 is the work factor
```

That `12` means 2¹² = 4,096 rounds of internal hashing, taking roughly ~100 milliseconds per hash. Why deliberately waste 100ms?

> **The bank-vault-timer analogy:** Imagine a vault whose dial takes exactly 100ms to turn one notch. For a legitimate user logging in *once*, 100ms is imperceptible. But for an attacker trying to brute-force *billions* of guesses, 100ms *each* is devastating — it drops them from ~10 billion guesses/second to maybe *ten* guesses/second. What took seconds now takes millennia. The slowness is a *feature*, tuned to be trivial for one honest login and catastrophic for mass guessing.

And it's **adaptive**: as computers get faster, you bump the work factor from 12 to 13 to 14, keeping honest-login cost around 100ms while re-crippling attackers. That's why bcrypt has aged well for decades.

bcrypt also automatically handles **salting** — mixing in random data so two users with the *same* password get *different* hashes. This defeats "rainbow tables" (giant precomputed guess-to-hash lookup tables) because the attacker can't precompute against random salts. You get this for free; you don't have to manage it.

**The takeaway for the code you'll write:** we `bcrypt.hash()` on registration to store the shredded password, and `bcrypt.compare()` on login to shred-and-check. We never store, log, or transmit the raw password. (Recall Primer 1: the password arrives in the request *body* — attacker-controllable input — validated by Zod, then immediately hashed and forgotten.)

---

## Part C: Staying logged in — the stateless problem

You've logged in. bcrypt confirmed your password. Now what? You want to make 50 more requests without re-typing your password each time. But remember Primer 1's hard truth:

> **The server is stateless. It forgets you the instant it answers.** Your next request arrives as a total stranger.

So how do you "stay logged in" to a server that has amnesia? There are two classic approaches. Understanding *both* is the key to understanding why we chose one.

### Approach 1: Sessions (the coat-check ticket)

> **The coat-check analogy:** You hand your coat to the attendant. They store it on a numbered hook and give you a *ticket* with just the number. The coat (your identity data) stays *with them*; you carry only the tiny ticket. Each time you return, you show the ticket, they look up hook #47, and retrieve your coat.

In session-based auth:
- On login, the **server stores** your identity in its own memory/database and gives you a random **session ID** (the ticket number).
- On each request, you send back the session ID; the server **looks it up** to remember who you are.

**Trade-off:** The server has to *store and look up* every active session. That's *stateful* — it works, but it means every server instance needs access to the same session store (a shared database or Redis), which adds infrastructure. To log someone out, the server just deletes the ticket — instant and clean.

### Approach 2: Tokens / JWTs (the tamper-proof wristband)

> **The festival-wristband analogy:** Instead of a coat check, a festival gives you a **wristband** that has your info printed *right on it* ("VIP, valid until 11pm") — and it's stamped with a *special hologram only the festival can make*. Now the gate staff don't need to look anything up. They read the wristband, check the hologram is genuine, and let you in. The staff store *nothing*; the wristband carries everything, and the hologram proves it's authentic and unaltered.

This is a **JWT**, and it fits statelessness perfectly:

> **Definition — JWT (JSON Web Token):** A self-contained token that carries its own data (called "claims," e.g. your user ID) *and* a cryptographic signature proving it was issued by the server and hasn't been tampered with.

Because the token carries its own identity data and its own proof, the **server stores nothing** — it just verifies the signature on each request. This matches HTTP's stateless nature and scales beautifully (any server instance can verify any token, no shared database needed). That's why `securenotes` uses JWTs.

**The trade-off (be honest about it):** because the server stores nothing, it can't easily "un-issue" a wristband. To limit this, we make tokens **short-lived** (Phase 2 sets `expiresIn: "1h"`) — a stolen wristband stops working within an hour. This is a real, deliberate security decision, not an accident.

---

## Part D: Inside a JWT — the three parts

A JWT looks like intimidating gibberish:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJhYmMtMTIzIiwiZW1haWwiOiJhQHguY29tIn0.dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk
```

But look closely — there are **two dots** splitting it into **three parts**. Decode them and it's simple:

```
HEADER . PAYLOAD . SIGNATURE
```

### Part 1: Header — *how it's signed*
```json
{ "alg": "HS256", "typ": "JWT" }
```
Metadata: the signing algorithm (`HS256`) and token type. This is just base64-encoded (a reversible *encoding*, **not** encryption).

### Part 2: Payload — *the claims (who you are)*
```json
{ "userId": "abc-123", "email": "a@x.com", "exp": 1712345678 }
```
The actual data — in our app, your `userId` and `email`, plus an `exp` (expiry timestamp). These are the "VIP, valid until 11pm" details printed on the wristband.

> **🚨 The most important security fact about JWTs, and the one beginners get wrong:** the payload is only **base64-encoded, NOT encrypted.** *Anyone* who has the token can read the payload — paste it into [jwt.io](https://jwt.io) and see everything inside. Therefore: **never put secrets in a JWT payload.** No passwords, no credit-card numbers, no private data. Put only non-sensitive identity claims (a user ID is fine). The token proves *who you are*; it is not a secure vault.

### Part 3: Signature — *the tamper-proof hologram*
This is the security. The signature is created by taking the header + payload and running them through a cryptographic function *with our secret key* (`JWT_SECRET` — remember Phase 1 forced it to be at least 32 characters, and Phase 3 moved it into a secret manager?).

Here's why this is unforgeable:

- An attacker *can* read the payload and *can* try to change it (e.g., swap `"userId": "abc-123"` to someone else's ID — a Spoofing attempt).
- But to make the change *valid*, they'd have to **re-sign** the modified token — and signing requires `JWT_SECRET`, which only the server knows.
- Without the secret, any tampered token fails signature verification and is rejected (`401`).

> **This is exactly why `JWT_SECRET` is the crown jewel of the whole app** — recall the threat model listed "JWT signing secret" as a top asset, because *"Leak = attacker can forge ANY user's identity."* If the secret leaks, an attacker can mint valid wristbands for anyone. That's why we validate its length (Phase 1), never hardcode it, and vault it (Phase 3). The security of every login rests on that one secret staying secret.

---

## Part E: The full login → request flow, end to end

Now let's assemble everything into the exact journey `securenotes` implements. Follow the wristband:

```
┌─────────────────────────── REGISTRATION (once) ──────────────────────────────┐
│  1. Client → POST /auth/register  { email, password }   (body = untrusted)   │
│  2. Server validates body with Zod            (Primer 1: validate the edge)   │
│  3. Server bcrypt.hash(password, 12)          (shred it; store only the hash) │
│  4. Server stores { email, passwordHash } in the users table                  │
│  5. Server signs a JWT and returns it         (you're now logged in)          │
└───────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────── LOGIN (later) ─────────────────────────────────┐
│  1. Client → POST /auth/login  { email, password }                            │
│  2. Server looks up the user by email                                         │
│  3. Server bcrypt.compare(typed password, stored hash)  (shred & compare)     │
│     ✗ no match → 401 "Invalid credentials"   (generic — don't reveal which!)  │
│     ✓ match → sign a fresh JWT, return it                                     │
└───────────────────────────────────────────────────────────────────────────────┘

┌───────────────────── EVERY PROTECTED REQUEST AFTER ────────────────────────────┐
│  1. Client → GET /notes                                                        │
│              Authorization: Bearer <the JWT>    (show the wristband)          │
│  2. requireAuth middleware verifies the signature with JWT_SECRET             │
│     ✗ missing/invalid/expired → 401             (rejected at the door)        │
│     ✓ valid → attaches req.user = { userId, email }                           │
│  3. Route runs, scoping the query to req.user.userId  (authZ / golden rule #4)│
│     → you get ONLY your own notes, never anyone else's                        │
└───────────────────────────────────────────────────────────────────────────────┘
```

Trace it and you'll see every earlier idea in action:
- **Statelessness** (Primer 1) → why we need the token at all.
- **Body is untrusted** (Primer 1) → Zod validates it before bcrypt touches it.
- **Hashing** → the password is shredded, never stored.
- **JWT signature** → the wristband can't be forged (Spoofing defeated).
- **Ownership scoping** → authN (who) *plus* authZ (what), killing IDOR (Elevation of privilege / Tampering defeated).

That flow *is* Phase 2. When you read the code there, this diagram is the map.

---

## Part F: The subtle security details (why the code looks the way it does)

A few things in Phase 2's code look small but are deliberate defenses. Now you'll know why:

1. **Generic error messages.** Login failure always says `"Invalid credentials"` — never `"no such email"` or `"wrong password"`. Telling an attacker *which* part was wrong lets them **enumerate** valid emails (a form of Information Disclosure). Same reason register returns a generic `"Could not register"` instead of `"email already exists"`.

2. **Short token lifetime (`1h`).** Because stateless tokens can't be easily revoked, we cap the damage of a stolen one by expiring it quickly.

3. **`Authorization: Bearer` is verified, never trusted.** The header is *attacker-controlled input* (Primer 1). `requireAuth` runs `jwt.verify()` — checking both the signature *and* the expiry — before believing a single claim inside.

4. **Passwords are redacted from logs (Phase 5).** Even with perfect hashing, if you accidentally log the raw request body you leak the plaintext password before it's ever hashed. Phase 5's log redaction closes that gap — auth security spans the whole lifecycle, not just the login route.

5. **Brute-force lockout (Phase 5).** bcrypt makes *offline* guessing (against a stolen hash DB) slow. The Phase 5 brute-force guard makes *online* guessing (hammering the live login endpoint) fail too, by locking out an IP after repeated failures. Two different attacks, two different defenses — defense in depth.

---

## The five things to carry into Phase 2

1. **AuthN ≠ AuthZ.** *Who are you* (login) vs *what can you touch* (ownership checks). You need both; forgetting the second causes IDOR.
2. **Hash passwords, never encrypt or store them.** Hashing is one-way (the shredder); there's no key to steal.
3. **Use bcrypt, because slow is safe.** Its deliberate, tunable slowness cripples mass guessing while being invisible to honest logins.
4. **A JWT is a signed, self-readable wristband.** The payload is *readable by anyone* (never put secrets in it); the *signature* is what makes it unforgeable.
5. **`JWT_SECRET` is the crown jewel.** Its secrecy is the foundation of every login — hence the length rules, no hardcoding, and the vault.

---

## ✅ Self-check

1. Your database of user records leaks. If you used bcrypt correctly, how bad is it — and why *isn't* it as bad as it could be?
2. Why can't you "decrypt" a bcrypt hash to recover the password?
3. An attacker copies a user's JWT and edits the payload to change `userId` to someone else's. Why does this fail?
4. Why is it safe to store a `userId` in a JWT payload, but *not* a password?
5. You've confirmed a request has a valid JWT for user Alice. Are you done with security checks before returning a note? Why or why not?
