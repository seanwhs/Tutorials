### **✅ Bonus Resource: Ready-to-Use Prompt & Workflow Templates**

Here’s a curated collection of **plug-and-play templates** based on the entire AI Fluency series. Copy, adapt, and use them directly with any LLM (ChatGPT, Grok, Gemini, Claude, Llama, etc.).

---

### **1. Meta-Prompting Templates** (Part 2)

**Prompt Architect**
```
You are an expert Prompt Engineer. My goal is: [clearly describe your goal]

I need a high-performance prompt that maximizes accuracy, minimizes hallucinations, and produces consistent, high-quality output.

Create:
1. A strong System Instruction
2. The full User Prompt with clear structure
3. Suggested few-shot examples (if helpful)
4. Output format specifications
5. Follow-up questions I should ask afterward

Make it suitable for [model type, e.g., reasoning model / fast model / local model].
```

---

### **2. Engineering & Architecture Templates**

**Documentation Auditor / Design Reviewer**
```
Act as a Principal Systems Architect with 15+ years of experience in large-scale distributed systems.

Here is the document/blueprint: [paste full text or upload file]

Perform a rigorous review and deliver:

1. **Strengths** – What works well and why
2. **Risks & Gaps** – Logical inconsistencies, scalability issues, integration bottlenecks
3. **Security, Compliance & Operational Concerns**
4. **Prioritized Recommendations** (High/Medium/Low)
5. **Devil’s Advocate Questions** (6–8 sharp questions to stress-test the design)
6. **Overall Assessment** (Score 1–10 + one-paragraph summary)

Be constructive but brutally honest. Flag anything vague or hand-wavy.
```

**Code Review & Improvement**
```
You are a senior software engineer and security expert. Review this code/module:

[paste code]

Provide:
- Overall quality assessment
- Bugs, edge cases, and security vulnerabilities
- Performance and scalability concerns
- Refactoring suggestions with improved code examples
- Test cases that should be added
- Documentation improvements
```

---

### **3. Research & Analysis Templates**

**Comprehensive Research Brief**
```
Conduct thorough research on: [topic]

Context/Goals: [your specific needs or angle]

Deliver a structured brief with:
- Executive Summary (2–3 sentences)
- Key Findings (bullet points with sources)
- Different Perspectives / Debates
- Implications for [your domain/role]
- Recommended Next Actions
- Open Questions or Areas Needing Further Research

Use only reliable information. Note uncertainty where it exists.
```

**Context-Aware Analysis**
```
Use the attached context documents as primary reference.

Task: [your task]

First, summarize the most relevant information from the provided context.
Then, complete the requested analysis while staying grounded in the documents.
```

---

### **4. Writing & Content Templates**

**Professional Writing with Voice**
```
You are helping me write in my professional voice. 

Style guidelines: [describe tone, e.g., concise, authoritative, collaborative, technical but accessible]

Audience: [who will read this]

Task: [what to write]

Here are examples of my writing style: [paste 1–2 examples]

Now write: [specific request]
```

---

### **5. Agentic / Multi-Step Workflow Templates**

**CrewAI-Style Multi-Agent Workflow (Conceptual Prompt)**
```
You are coordinating a team of AI specialists. Roles:
- Researcher: Gather and verify information
- Analyst: Identify insights and risks
- Critic: Find flaws and edge cases
- Writer: Produce polished final output

Goal: [your goal]

Available context: [paste or reference]

Execute step by step and show your work. At the end, produce a final consolidated deliverable.
```

**Iterative Refinement Loop**
```
First Draft: [your initial request]

Now review your previous output and improve it based on this feedback:
[your specific feedback]

Focus especially on [areas to improve]. Maintain [style requirements].
```

---

### **6. Evaluation & Discernment Templates**

**Output Evaluation**
```
Evaluate the following output against these criteria:
- Accuracy
- Completeness
- Clarity
- Usefulness for my goal: [goal]

Output to evaluate: [paste AI response]

Provide scores (1–10) for each criterion with specific explanations and suggested improvements.
```

**Personal Reflection Prompt** (End of Project)
```
We just completed [task] using AI. 

Help me reflect:
- What worked well in our prompting/workflow?
- What could be improved?
- Key lessons for next time
- Suggested refinements to my prompt library
```

---

### **7. Privacy-First Local Model Starter**
When using local models (Ollama, etc.), prefix with:
```
You are running locally with no data retention. All information is private. 
[then your normal prompt]
```

