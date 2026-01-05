# Guide: Friction Removal & Technical Debt Management

Architecture should never be the reason a team is slow. We manage friction as a primary KPI.

## Identifying Friction
Friction occurs when the **Golden Path** no longer serves the developer. 
* **Signals:** High number of "Request for Standard" issues, project teams bypassing CI/CD, or "Snowflake" services appearing in "Aggressive" initiatives.

## Managing Architecture Debt
1. **Estimation:** During the "Initiation" phase, estimate the debt the new solution will incur.
2. **Documentation:** Record all accepted debt in an **ADR** with a clear "Payback" (Refactor) date.
3. **Refactoring:** Use the **Audit & Modernization** process to fund "Defensive" initiatives specifically aimed at removing high-friction debt.

## Goal
The goal of EA is to provide the **Trunk of the Tree** (Common infrastructure and patterns) so developers can focus on the **Leaves** (Business Logic).
