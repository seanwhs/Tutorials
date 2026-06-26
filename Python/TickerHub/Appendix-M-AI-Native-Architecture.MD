# APPENDIX M — AI-NATIVE ARCHITECTURE & AGENTIC SYSTEMS

# TickerHub Intelligence Layer Reference

> *"AI is not another feature. AI is another actor in the distributed system."*

---

# Purpose

This appendix defines the AI-native architecture of TickerHub.

The goals are to:

* integrate LLMs into enterprise systems
* define AI service boundaries
* establish agent architectures
* define Retrieval-Augmented Generation (RAG)
* establish AI governance
* define human-in-the-loop workflows
* treat AI as a distributed subsystem

---

# AI Philosophy

TickerHub treats AI as:

```text id="ai001"
Probabilistic Software
```

not:

```text id="ai002"
Deterministic Software
```

This means:

```text id="ai003"
AI outputs are suggestions.

AI outputs are never truth.
```

---

# AI Architecture Principles

TickerHub AI follows:

```text id="ai004"
Retrieval First

Verification First

Human Approval First

Audit Everything
```

---

# AI Architecture

```text id="ai005"
                      USER
                        |
                        |
                   AI Gateway
                        |
         ----------------------------------
         |               |                |
         V               V                V

    RAG Engine      AI Agents       Guardrails

         |               |                |

         ----------------------------------

                        |

                  Knowledge Layer
                        |
        ----------------------------------
        |                |               |
        V                V               V

     Research       Market Data      Events
```

---

# AI Layers

```text id="ai006"
Foundation Models

↓

Retrieval Layer

↓

Agent Layer

↓

Business Layer

↓

Human Layer
```

---

# AI Services

TickerHub AI is split into bounded contexts.

```text id="ai007"
Research AI

Trading AI

Risk AI

Portfolio AI

Operations AI
```

---

# Research AI

Purpose:

```text id="ai008"
Answer questions
```

Example:

```text id="ai009"
"What happened to DBS earnings?"
```

---

Inputs:

```text id="ai010"
Research reports

News

Market events

SEC filings
```

---

Outputs:

```text id="ai011"
Summary

Citations

Confidence
```

---

# Trading AI

Purpose:

```text id="ai012"
Generate hypotheses
```

Example:

```text id="ai013"
"Identify unusual price action."
```

---

Allowed:

```text id="ai014"
Recommendations
```

Forbidden:

```text id="ai015"
Trade execution
```

---

# Risk AI

Purpose:

```text id="ai016"
Explain risk
```

Example:

```text id="ai017"
"Why did VaR increase?"
```

---

Outputs:

```text id="ai018"
Human explanation
```

---

# Portfolio AI

Purpose:

```text id="ai019"
Portfolio analytics
```

Example:

```text id="ai020"
"What sectors drive performance?"
```

---

# Operations AI

Purpose:

```text id="ai021"
Infrastructure diagnosis
```

Example:

```text id="ai022"
"Why is Kafka lagging?"
```

---

# Retrieval-Augmented Generation

---

## Architecture

```text id="ai023"
Question

   |

Embedding

   |

Vector Search

   |

Retrieved Documents

   |

Prompt Assembly

   |

LLM

   |

Answer
```

---

# Why RAG?

Without RAG:

```text id="ai024"
Hallucinations
```

With RAG:

```text id="ai025"
Grounded answers
```

---

# Vector Database

Stores:

```text id="ai026"
Research

News

Reports

Documentation

Events
```

---

# Embedding Pipeline

```text id="ai027"
Document

   |

Chunking

   |

Embedding

   |

Vector Store
```

---

# Chunking Strategy

Example:

```text id="ai028"
Document

↓

500 tokens

↓

50 token overlap
```

---

# Agent Architecture

---

## Agent Loop

```text id="ai029"
Goal

↓

Plan

↓

Act

↓

Observe

↓

Reflect

↓

Repeat
```

---

# Agent Components

```text id="ai030"
Planner

Executor

Memory

Tools

Guardrails
```

---

# Research Agent

---

Input:

```text id="ai031"
Explain DBS earnings.
```

---

Process:

```text id="ai032"
Search

↓

Retrieve

↓

Summarize

↓

Verify

↓

Present
```

---

# Risk Agent

---

Input:

```text id="ai033"
Explain today's losses.
```

---

Process:

```text id="ai034"
Retrieve trades

↓

Calculate attribution

↓

Generate explanation
```

---

# Operations Agent

---

Input:

```text id="ai035"
Why is latency high?
```

---

Process:

```text id="ai036"
Metrics

↓

Logs

↓

Traces

↓

Root cause
```

---

# Tool Calling

Agents may use:

```text id="ai037"
SQL

Kafka

Redis

Prometheus

Vector DB

Search
```

---

# Tool Contract

Example:

```json id="ai038"
{
  "tool":"search",
  "arguments":{
    "query":"DBS earnings"
  }
}
```

---

# Agent Memory

---

## Short-Term Memory

```text id="ai039"
Current conversation
```

---

## Long-Term Memory

```text id="ai040"
Historical interactions
```

---

## Episodic Memory

```text id="ai041"
Previous tasks
```

---

# Multi-Agent Systems

---

Example:

```text id="ai042"
Research Agent

↓

Risk Agent

↓

Portfolio Agent

↓

Coordinator
```

---

# Agent Communication

Uses:

```text id="ai043"
Kafka events
```

---

Example:

```text id="ai044"
ResearchCompleted

↓

RiskAnalysisRequested

↓

PortfolioAnalysisCompleted
```

---

# Human In The Loop

---

Required for:

```text id="ai045"
Trading

Risk overrides

Portfolio changes

Administration
```

---

Workflow:

```text id="ai046"
AI

↓

Recommendation

↓

Human approval

↓

Execution
```

---

# AI Guardrails

---

## Input Validation

Blocks:

```text id="ai047"
Prompt injection

Jailbreaks

Secrets
```

---

## Output Validation

Checks:

```text id="ai048"
Facts

Format

Policy
```

---

## Tool Validation

Restricts:

```text id="ai049"
Allowed actions
```

---

# Confidence Scores

Every AI response contains:

```json id="ai050"
{
  "answer":"...",
  "confidence":0.82,
  "sources":[]
}
```

---

# AI Audit Trail

Store:

```text id="ai051"
Prompt

Context

Retrieved docs

Model

Parameters

Response
```

---

# AI Metrics

Measure:

```text id="ai052"
Latency

Cost

Hallucinations

Accuracy

Tool usage
```

---

# AI Security

Threats:

```text id="ai053"
Prompt injection

Data exfiltration

Tool abuse

Hallucination
```

---

Controls:

```text id="ai054"
Sandboxing

RAG isolation

Human approval

Auditing
```

---

# AI Cost Model

Track:

```text id="ai055"
Input tokens

Output tokens

Embedding costs

Storage costs
```

---

# AI Reliability

Use:

```text id="ai056"
Retries

Fallback models

Caching

Circuit breakers
```

---

# AI Fallback Strategy

```text id="ai057"
GPT

↓

Claude

↓

Gemini

↓

Rule engine
```

---

# AI Event Model

Examples:

```text id="ai058"
PromptSubmitted

RetrievalCompleted

AgentStarted

AgentCompleted

RecommendationGenerated
```

---

# AI Governance

Rules:

```text id="ai059"
No autonomous trading.

No autonomous risk approval.

No autonomous administration.

No autonomous secrets access.
```

---

# AI Maturity Levels

| Level | Capability              |
| ----- | ----------------------- |
| L0    | No AI                   |
| L1    | Search                  |
| L2    | RAG                     |
| L3    | Agent                   |
| L4    | Multi-agent             |
| L5    | Autonomous organization |

---

# TickerHub Target

```text id="ai060"
L3-L4
```

Meaning:

```text id="ai061"
AI assists humans.

AI does not replace humans.
```

---

# AI Principles

TickerHub AI follows:

```text id="ai062"
Retrieve

Verify

Explain

Audit

Approve
```

---

# Final Principle

```text id="ai063"
Traditional software
executes instructions.

AI systems
generate possibilities.
```

And therefore:

```text id="ai064"
The job of engineering
is not to trust AI.

The job of engineering
is to build systems
that remain correct
even when AI is wrong.
```
