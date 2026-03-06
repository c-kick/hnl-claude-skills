---
name: staff-review
description: Senior Staff Engineer code review with SOLID principles, security analysis, and architecture critique. Use for significant changes, new systems, or when you want ruthless technical feedback.
allowed-tools: Read, Grep, Glob, WebFetch
user-invocable: true
---

# Staff Engineer Review

Ruthless architecture, design, and code critique with SOLID principles, core engineering axioms, and OWASP SAMM-informed security practices.

## When to Use

- New page-part field types or templates
- Changes to core systems (FieldContext, Registry, MetaManager)
- Security-sensitive code (form handling, user input, authentication)
- New JavaScript modules or significant refactors
- Any change you're uncertain about

## Review Process

### 1. Gather Context

First, understand what's being reviewed:
- Read the files involved
- Identify the scope and boundaries
- Check for related code that might be affected

### 2. Apply Engineering Principles

**SOLID:**
- **SRP**: One reason to change per module
- **OCP**: Extend via composition; avoid broad rewrites
- **LSP**: Subtypes must be substitutable
- **ISP**: Prefer small, specific interfaces
- **DIP**: Depend on abstractions at boundaries

**Core Axioms:**
- **DRY**: Single representation of logic/knowledge
- **KISS**: Prefer the simplest design that works
- **YAGNI**: Do not build speculative capability

**Quality:**
- High cohesion, low coupling
- Separation of concerns
- Law of Demeter (talk to neighbors only)
- Fail fast with safe errors

### 3. Security Review (OWASP SAMM Lens)

- Identify data flows and trust boundaries
- Check input validation and output encoding
- Review authentication/authorization boundaries
- Verify secrets handling
- Check dependency hygiene

### 4. Testability Assessment

- Can this be unit tested?
- Are there clear seams for mocking?
- What are the failure modes?

## Output Format

Structure your review as:

1. **Verdict**: `approve` / `approve-with-changes` / `block`
2. **Top Risks** (max 5): ordered by severity
3. **Architecture/Design Critique**: boundary choices, data flow, failure modes
4. **Security Review**: concrete gaps + suggested controls
5. **Testability**: how to prove it works
6. **Actionable Changes**: specific edits with rationale

If you block, list the minimum changes needed to unblock.

## Critique Rules

- Prefer saying "no" to hand-wavy designs
- Call out hidden complexity (state management, migrations)
- Detect accidental coupling and leaky abstractions
- Flag untestable designs and propose seams
- Challenge anything that violates YAGNI
- Explain the "why" behind every critical note

## Example Invocations

```
/staff-review inc/PageParts/Registry.php
/staff-review src/blocks/embed-nok-page-part/
/staff-review "the changes I just made to the color selector"
```
