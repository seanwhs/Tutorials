# Primer 6: Public-Key Cryptography & Signing — Trust Without Secrets

**Feeds into:** Phase 4 (Cosign image signing, keyless OIDC signing, the deploy-time verification gate) and Phase 5 (why audit logs and provenance are "non-repudiable").
**You'll be ready when:** you can explain why an attacker who can *read* a signature still can't *forge* one — and why "keyless" signing is safer than guarding a private key.

**Prerequisite primers:** Primer 3 (Containers) helps — signing acts on the *image* and its *digest*. Primer 2 (Auth) built intuition for hashing, which we reuse here.

---

## Why this matters

Phase 4 asks you to *cryptographically sign* your container image and then *verify* that signature before deploying. For most people this is the single most mysterious part of the whole series — it sounds like the kind of deep cryptography that requires a math degree.

It doesn't. The core ideas are elegant and, once you see the mechanism, genuinely intuitive. And they matter enormously for security, because signing defends a threat nothing else can touch: the **supply-chain / integrity** threat. Everything up to Phase 4 checks that your artifact is *good*. Signing proves it's *authentic* — that the exact thing you're about to run is the exact thing your trusted pipeline produced, and not a malicious look-alike an attacker swapped into the registry.

This is the last big conceptual mountain. Let's climb it in stages.

---

## Part A: The problem — how do you trust something you didn't watch being made?

Imagine your deployment system is about to pull an image from the registry (Primer 3's "library shelf") and run it in production. It faces a question it *cannot* answer just by looking:

> "Is this image *really* the one our secure pipeline built and vetted? Or did an attacker who got access to the registry quietly replace it with a poisoned version that looks identical?"

This is a real, devastating attack. Registries get compromised. Images get swapped. Man-in-the-middle attackers substitute artifacts in transit. A malicious build looks *exactly* like a good one from the outside — same name, same tag. **You cannot tell them apart by inspection.**

We need a way to prove two things about an artifact:
1. **Authenticity** — it really came from who it claims to (our pipeline).
2. **Integrity** — it hasn't been altered by even a single byte since.

The tool for this is a **digital signature**, built on **public-key cryptography.** Let's build up to it.

---

## Part B: The core idea — a lock with two different keys

Ordinary locks use *one* key: the same key locks and unlocks. That's called **symmetric** cryptography, and it has a fatal flaw for our problem — to let someone verify your work, you'd have to give them the key, and now *they* can forge your work too.

Public-key crypto uses something stranger and more powerful: a lock with **two different, mathematically-linked keys**, where each can only undo what the *other* did.

> **Definition — Key pair:** Two keys generated together as a mathematical pair — a **private key** (kept absolutely secret by the owner) and a **public key** (given out freely to anyone). They're linked so that what one key does, only the *other* can reverse.

> **The magic-wax-seal analogy:** Picture a signet ring (the **private key**) that presses a unique, impossibly-intricate seal into wax. Only *you* have the ring — nobody can reproduce your seal. But everyone in the kingdom has a *reference card* showing exactly what your genuine seal looks like (the **public key**). Anyone can hold a letter up to their card and confirm "yes, that's the king's real seal, and the wax is unbroken" — but *nobody* can forge the seal, because nobody else has the ring.
>
> The asymmetry is the whole trick: **making** a seal requires the secret ring; **checking** a seal requires only the public card. Reading and verifying is open to all; creating is exclusive to the owner.

That asymmetry — private key *creates*, public key *verifies*, and you can't derive one from the other — is what makes everything else possible.

---

## Part C: How a digital signature actually works

Now we combine the key pair with **hashing** (which you met in Primer 2 — the one-way "shredder"). A digital signature is a beautiful two-ingredient recipe.

### Signing (done by the creator, with the *private* key):
1. **Hash the artifact.** Run the entire image through a hash function to produce a small, unique fingerprint (Primer 2: change one byte → totally different fingerprint).
2. **Encrypt that fingerprint with the private key.** The result is the **signature** — a small blob attached to the artifact.

That's it. The signature is "the artifact's fingerprint, sealed with the private key."

### Verifying (done by anyone, with the *public* key):
1. **Hash the artifact yourself.** Compute the fingerprint of the image you received.
2. **Decrypt the signature with the public key** to reveal the fingerprint the *signer* computed.
3. **Compare the two fingerprints.** If they match → verified. If not → rejected.

Why this simultaneously proves *both* things we needed:

- **Authenticity:** the signature could *only* have been created by whoever holds the private key. If it decrypts correctly with the matching public key, it genuinely came from that owner. (Nobody else has the ring.)
- **Integrity:** if even one byte of the image changed, *your* recomputed fingerprint won't match the one inside the signature — and verification fails. (The wax seal is visibly broken.)

> **The security fact that trips people up:** a signature is *not secret*. It's published right alongside the artifact, in plain view — anyone can read it. That feels wrong at first ("isn't security about hiding things?"). But read Part B again: **reading/verifying a signature is public by design; only *creating* one is exclusive.** An attacker can see your signature all day and still can't forge it, because forging requires the private key they don't have. Publicity of the signature is not a weakness — it's the entire point.

This directly answers Phase 4's threat: an attacker who swaps the image in the registry *can't* produce a valid signature for their malicious version (no private key). When our deploy step verifies, the swapped image fails — the broken seal gives it away.

---

## Part D: The hard part of signing isn't the math — it's the key

Here's the twist that leads to the clever thing in Phase 4.

The cryptography above is bulletproof *as long as the private key stays private.* But that "as long as" is the whole ballgame. In traditional signing, you generate a private key and then you have to... *keep it somewhere.* And a private key is the ultimate high-value secret:

- If it leaks, an attacker can sign *anything* as you — every guarantee collapses.
- It has to live somewhere your CI pipeline can reach it to sign — which means it's exposed to exactly the automated environment attackers love to target.
- You have to store it, protect it, rotate it, and hope no one ever `cat`s it into a log (recall Phase 1/Phase 5's obsession with not leaking secrets — a signing key is the worst possible thing to leak).

> **The paradox:** we invented signing to *avoid trusting things blindly* — but traditional signing forces us to guard one incredibly dangerous long-lived secret, reintroducing exactly the "secret that could leak" problem we've been fighting since Phase 1.

The modern solution — and what Phase 4 uses — is to *get rid of the long-lived key entirely.* This is **keyless signing**, and understanding it is the final piece.

---

## Part E: Keyless signing — trust based on *identity*, not a stored key

This is the conceptual leap. Instead of "prove it's you because you hold this secret key forever," keyless signing says: **"prove who you are *right now*, and we'll issue you a signing certificate that's valid for just a few minutes, then expires."**

Let's assemble the pieces. Two new definitions:

> **Definition — OIDC (OpenID Connect):** A standard way for a system to *prove its identity* to another system, using short-lived, cryptographically-verifiable tokens. GitHub Actions can use OIDC to prove "I am the release.yml workflow running in this specific repo."
>
> **Definition — Sigstore / Cosign:** An open-source system (Cosign is the tool) that enables *keyless* signing. Instead of a stored private key, it uses your OIDC identity to obtain a *momentary* signing certificate, signs with it, and records the whole event in a public log.

Here's the keyless flow Phase 4 actually runs, step by step:

```
1. CI job needs to sign the image.
2. GitHub Actions proves its IDENTITY via OIDC:
   "I am the workflow release.yml in repo yourname/securenotes."
   (This token is short-lived and can't be faked — GitHub vouches for it.)
3. Sigstore's certificate authority (Fulcio) checks that identity and issues
   a SIGNING CERTIFICATE valid for only ~10 minutes.
4. Cosign signs the image's digest with that momentary key.
5. The signing event is recorded in a PUBLIC, append-only transparency log
   (Rekor) — a permanent, tamper-evident receipt.
6. The momentary key EXPIRES and is thrown away. Nothing to store. Nothing to leak.
```

> **The notary analogy:** Traditional key-based signing is like owning a personal rubber stamp you must lock in a safe forever — if it's stolen, disaster. Keyless signing is like going to a **notary**: you show your ID (OIDC identity), the notary confirms it's really you and stamps your document with a stamp that's only valid for this visit, and they write the event in their **public logbook** (Rekor) that anyone can inspect later. You never own a stamp to protect. Your *identity* is what's trusted, verified fresh each time — not a secret you're forced to hoard.

Why this is strictly better for a CI pipeline:

- **No long-lived key exists to steal.** The most dangerous secret simply isn't there. (This is the same philosophy as Primer 2's "hash, don't store passwords" and Phase 3's secret manager — *eliminate the dangerous secret rather than guard it*.)
- **The signature is bound to *who* signed** — a specific workflow in a specific repo, not an anonymous key. This is more meaningful: you're not trusting "whoever had the key," you're trusting "our exact release pipeline."
- **Everything is publicly auditable** in the Rekor transparency log — a permanent, tamper-evident record. (This is the "non-repudiation" payoff mentioned in Phase 5: nobody can later deny a signing happened.)

---

## Part F: Reading Phase 4's actual commands

You now have every concept to read Phase 4's signing and verification as plain English.

### Signing (in the `sign` job):
```bash
cosign sign --yes "${REGISTRY}/${IMAGE_NAME}@${DIGEST}"
```
Read it: *"Cosign, sign the image identified by this exact **digest** (Primer 3: the immutable `sha256:...` fingerprint, so we sign the precise bytes we scanned). Use my current OIDC identity to get a momentary certificate; record it in Rekor. `--yes` = don't prompt me, this is automation."* No key is mentioned anywhere — because there is no stored key. That's keyless signing in one line.

> **Why sign the *digest*, not the *tag*?** (Primer 3 pre-loaded this.) A tag like `:latest` is mutable — it can point to different bytes later. A digest is the *immutable fingerprint* of exact content. Signing the digest means the seal is on *these precise bytes* — the very ones we scanned in the previous job. Nobody can slip different content under our signature.

### Verifying (in the `deploy-staging` gate):
```bash
cosign verify \
  --certificate-identity-regexp "https://github.com/${GITHUB_REPOSITORY}/.github/workflows/release.yml@.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  "${REGISTRY}/${IMAGE_NAME}@${DIGEST}"
```
Read each line as a demand the image must satisfy:
- **`--certificate-identity-regexp ...release.yml@...`** → *"The signature MUST have been made by our exact release workflow — and nobody else."* (This pins *who* is allowed to have signed. Recall Part E: keyless signing binds the signature to an identity, so we can demand a *specific* one.)
- **`--certificate-oidc-issuer ...githubusercontent.com`** → *"...and that identity must have been vouched for by GitHub's OIDC provider."* (Pins *which authority* we trust to confirm identities.)
- The **digest** → *"...for this exact image."*

If all three hold, verification passes and deployment proceeds. If an attacker swapped the image, or signed it with a *different* identity, or tampered with a byte — verification returns non-zero, and (Primer 4: exit codes are the gate mechanism) the deploy step fails. **The seal is checked before the door opens.**

This is why Phase 4's verification is the gate that "makes signing meaningful." A signature nobody checks is decoration; the verification step is what converts the cryptography into an actual, enforced security control at the deployment boundary — closing the "CI pipeline → registry → production" trust boundary from our very first threat model.

---

## Part G: Zooming out — the trust chain

Step back and see the full chain of trust Phase 4 builds. Each link vouches for the next:

```
GitHub's OIDC provider
   │  vouches for →
The identity of our release.yml workflow
   │  which obtains →
A momentary signing certificate (from Fulcio)
   │  used to create →
A signature on the image's exact digest
   │  recorded in →
Rekor (public, tamper-evident transparency log)
   │  later checked by →
The deploy gate (cosign verify)
   │  which permits →
Deployment of ONLY the exact, authentic, unaltered image
```

Notice there is **no long-lived secret anywhere in this chain.** Trust flows from *verifiable identity* and *public transparency*, not from a hoarded key. That's the modern supply-chain security philosophy in miniature, and it's the same instinct as the rest of the series: *eliminate the dangerous secret, prefer verifiable proof, and check — never assume.*

---

## The six things to carry into Phase 4

1. **Public-key crypto uses a linked pair:** a *private* key (secret, creates signatures) and a *public* key (shared, verifies them). You can't derive one from the other.
2. **A digital signature = the artifact's hash, sealed with the private key.** It proves both *authenticity* (who made it) and *integrity* (not one byte changed).
3. **Signatures are public and that's fine** — reading/verifying is open to all; only *creating* requires the secret key. An attacker can see your signature and still can't forge it.
4. **The hardest part of signing is guarding the private key** — so keyless signing eliminates the long-lived key entirely.
5. **Keyless signing (Cosign/Sigstore + OIDC) trusts *identity*, not a stored secret:** prove who you are, get a momentary certificate, sign, log it publicly (Rekor), let the key expire. Nothing to steal.
6. **Verification is what makes signing real.** Phase 4's deploy gate demands the signature came from *our exact workflow* for *this exact digest* — and blocks deployment if not. Sign the *digest* (immutable), never the *tag* (mutable).

---

## ✅ Self-check

1. An attacker can *read* your image's signature in the public registry. Why can't they use it to forge a signature for their own malicious image?
2. What two distinct things does a valid digital signature prove about an artifact?
3. Why is it *safe* — even desirable — for a signature to be public, when so much of security is about keeping things secret?
4. In one sentence, what is the core advantage of *keyless* signing over traditional key-based signing?
5. Phase 4 signs the image's *digest* (`sha256:...`) rather than its *tag* (`:latest`). Why does that distinction matter for security?
6. The deploy step runs `cosign verify` with `--certificate-identity-regexp` pinned to our `release.yml`. An attacker uploads a malicious image and signs it with *their own* valid Sigstore identity. Does it pass our gate? Why or why not?
