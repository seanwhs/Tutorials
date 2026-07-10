# Secure by Design — Part 6: Zero-Trust Network Design

## 1. Concept & Architecture Rationale

### "Never trust, always verify" — including your own network

Traditional network security models assume anything inside the corporate/VPC perimeter is trustworthy — a "castle and moat." Zero-Trust rejects this: every request, whether it originates from the public internet or from another service inside the same VPC, must independently prove its identity and be authorized, every time. This directly generalizes the Part 2 architectural rule ("every layer that can independently receive a request must independently verify authorization") from the application layer down to the network layer.

### Why this matters even for "internal-only" services

The most damaging breaches typically involve **lateral movement**: an attacker compromises one low-value service (a public marketing site, a forgotten internal tool) and then pivots freely because internal network traffic was implicitly trusted. Zero-Trust network design means that even if an attacker gains a foothold inside your network, every subsequent hop is still a locked door requiring its own key.

### The three pillars of Zero-Trust network design

- **Service identity**: each service has a cryptographic identity (a certificate), not just a network location (an IP address, which is spoofable and ephemeral in containerized/serverless environments).
- **Mutual authentication (mTLS)**: both sides of a connection verify each other's certificate — not just the client verifying the server (as in standard TLS for a browser visiting a website), but the server also verifying the client's identity before accepting the connection.
- **Egress filtering**: outbound connections are default-deny; a service may only reach the specific destinations it has an explicit, documented need to reach — directly mitigating the SSRF and data-exfiltration risks from Part 4.

## 2. Implementation

### Step 1 — Establish a private Certificate Authority (CA) for service identity, free and open-source

**step-ca** (from Smallstep, free and open-source) or **cert-manager** (free, open-source, the standard for Kubernetes) can issue and automatically rotate short-lived certificates to every service. Short-lived here mirrors Part 2's short-lived token philosophy exactly — a certificate valid for 24 hours or less means a leaked private key has a small, bounded window of usefulness, and rotation happens automatically without manual intervention.

### Step 2 — Implement mTLS between two internal services

Conceptually, for a Node.js service calling another internal service: the calling service's HTTPS client is configured with its own client certificate and private key (`cert`, `key` options) plus the CA certificate used to validate the server's certificate (`ca` option); the receiving service's HTTPS server is configured with `requestCert: true` and `rejectUnauthorized: true`, meaning it refuses any connection that doesn't present a valid client certificate signed by the trusted internal CA — the connection fails at the TLS handshake, before a single line of application code runs. This is a critical property: authentication happens at the transport layer, so even a completely unauthenticated application code path cannot be reached by an unverified caller.

### Step 3 — Service mesh as the practical implementation vehicle (for container/Kubernetes environments)

Hand-rolling mTLS certificate distribution and rotation across dozens of services doesn't scale. **Linkerd** (free, open-source, CNCF-graduated, notably lightweight) or **Istio** (free, open-source, more feature-rich but heavier operationally) inject a sidecar proxy alongside each service that transparently handles mTLS for all pod-to-pod traffic — your application code makes plain HTTP calls to `localhost`, and the sidecar proxies transparently upgrade every hop to mutually authenticated TLS. This is the pragmatic, production-grade path to Zero-Trust networking without rewriting every service's networking code.

### Step 4 — Service-to-service authentication above the transport layer (SPIFFE/SPIRE)

mTLS proves *which service* is calling, but you often also need to prove *which workload identity* — especially important for multi-tenant clusters or serverless. **SPIFFE** (Secure Production Identity Framework For Everyone) and its runtime implementation **SPIRE** (both free, open-source, CNCF projects) issue cryptographically verifiable workload identities (SVIDs) independent of network location, so a service's identity travels with it even across restarts, redeploys, and IP address changes — directly solving the "IP addresses are ephemeral and spoofable" problem named above.

### Step 5 — Egress filtering: default-deny outbound traffic

At the network policy layer (Kubernetes `NetworkPolicy` resources, or cloud provider security groups/NACLs), configure egress rules as default-deny, then explicitly allowlist only the destinations each service legitimately needs — e.g., your API service may egress to your database's specific internal address and your identity provider's specific external domain, and nothing else. Concretely, in Kubernetes, a `NetworkPolicy` resource with `policyTypes: [Egress]` and an empty default `egress: []` blocks all outbound traffic from pods matching its selector, with additional `egress` rule blocks added individually per allowed destination.

### Step 6 — DNS-aware egress filtering for SaaS dependencies

Pure IP-based egress allowlists break when your dependencies (Stripe, Clerk, third-party APIs) sit behind provider-managed, rotating IP ranges. Use a DNS-aware egress proxy/firewall (e.g., **Cilium**, free and open-source, with its `FQDN`-based `CiliumNetworkPolicy`) to allowlist by hostname rather than IP — the proxy resolves and enforces the policy dynamically, so `api.stripe.com` remains allowed even as its underlying IPs change, while everything else, including any SSRF attempt from Part 4 to reach an internal metadata endpoint or an attacker's exfiltration server, is blocked at the network layer as a second, independent control beyond the application-layer allowlist already implemented there.

### Step 7 — Extend Zero-Trust to the edge: verify at ingress too

Zero-Trust isn't only internal — apply the same "never trust, always verify" discipline to inbound edge traffic using a free, open-source Web Application Firewall (WAF) like **ModSecurity** (with the free OWASP Core Rule Set) or Cloudflare's free-tier WAF rules, positioned in front of your application. This is the concrete answer to the "WAF at the edge vs. application-layer sanitization" architectural question raised in Part 4: the WAF is a coarse, fast, network-adjacent filter catching known-bad request patterns (common SQLi/XSS payloads, malicious user agents, credential-stuffing patterns) at the edge, cheaply, before requests even reach your application; application-layer validation (Zod, parameterized queries) is the precise, context-aware defense that must exist regardless, because a WAF's pattern-matching can always be bypassed by a sufficiently novel payload — neither layer is optional, and each catches what the other misses.

## 3. Exercise Challenge

1. Diagram your current service-to-service traffic (even if it's just "app talks to database" and "app talks to two third-party APIs") and mark which hops currently rely on network location alone (an IP allowlist or "it's inside the VPC") rather than cryptographic identity.
2. If you run any containerized services, install Linkerd (its "auto mTLS" feature requires zero configuration on your part for most standard deployments) and verify mTLS is active between two of your own services using `linkerd viz edges`.
3. Write one Kubernetes `NetworkPolicy` (or cloud security group equivalent) that moves one service from default-allow egress to default-deny-plus-explicit-allowlist.
4. Stand up ModSecurity with the OWASP Core Rule Set in front of a test application and confirm it blocks a basic SQLi test payload in the request path.

## 4. Solution & Explanation

Applied to a multi-service backend (e.g., the QB Clone's main app plus an Inngest background-job worker plus a reporting service): Linkerd is installed into the cluster, automatically issuing short-lived certificates to every pod and upgrading all pod-to-pod traffic to mTLS with zero application code changes; a `NetworkPolicy` is added restricting the reporting service's egress to only the database's internal service address, denying it any path to the public internet at all (since a reporting service, by function, never needs outbound internet access — a violation of this policy is an immediate, high-confidence signal of compromise); and ModSecurity with OWASP CRS sits in front of the public-facing app, catching malformed and known-malicious requests before they reach the Zod-validated application boundary from Part 4.

Why this matters architecturally: notice the reporting service's egress-deny rule is not primarily about stopping a known attack — it's about **reducing the blast radius of an unknown one**. If that service is ever compromised (a vulnerable dependency, per Part 3/5), the attacker gains a foothold that literally cannot reach the internet to exfiltrate data or receive further instructions. This is Zero-Trust's core value proposition: security that holds even when a component you didn't know was vulnerable turns out to be vulnerable.

## 5. Key Takeaways

- Zero-Trust generalizes "verify at every layer" from the application layer (Part 2) to the network layer: no service should be trusted merely because of its network location.
- Short-lived, auto-rotated certificates (mirroring Part 2's short-lived tokens) bound the blast radius of key leakage.
- Service meshes (Linkerd/Istio) make mTLS operationally practical at scale without rewriting application networking code.
- Egress filtering — default-deny outbound, explicit allowlist only — turns "the internal network is compromised" from a catastrophe into a contained incident.
- Edge WAFs and application-layer validation are complementary, not redundant: a WAF's pattern-matching is fast and coarse; app-layer validation is precise and context-aware.

Next: Part 7 — Monitoring & Incident Response, where we design centralized logging, audit trails, and automated alerts for suspicious activity using open-source SIEM/SOAR principles.
