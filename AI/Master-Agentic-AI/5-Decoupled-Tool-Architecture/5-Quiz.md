# Quiz: Phase 5 — Decoupled Tool Architectures & Protocol Interfaces

---

**Q1.** A new tool is added to the registry, but the developer forgets to give it a `description` field. Walk through exactly what happens, starting from `defineTool()`, and explain why this fails the way it does rather than silently producing a tool with a blank description.



---

**Q2.** Explain specifically why `ToolRegistry.execute()` validates a tool's input against its Zod schema *before* calling the handler function, rather than letting each handler validate its own input internally.



---

**Q3.** The course actually swapped `lookupOrderStatus`'s backing data source from a JSON file to a simulated async database client. Name the exact two files that needed to change, and explain why the registry, the system prompt builder, and the ReAct loop required zero changes as a result.



---

**Q4.** Why does the course gate the `cancelOrder` write-action tool at *registration time* (skipping `registry.register(cancelOrderTool)` entirely when disabled) rather than registering it normally but adding an "if disabled, refuse" check inside its handler function?



---

**Q5.** Why does `middleware.js` explicitly check whether `process.env.AGENT_API_KEY` itself is missing on the server, and return a `500` in that case, rather than just comparing `providedKey !== expectedKey` directly and letting an `undefined` expected key naturally fail that comparison?



---

**Q6.** Middleware runs in Next.js's Edge Runtime by default. Explain, using a concrete example from this course, why this constrains what kind of authentication logic you could put directly inside `middleware.js` for a real multi-tenant, database-backed API key system.
