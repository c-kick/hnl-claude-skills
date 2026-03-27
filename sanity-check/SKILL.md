---
name: sanity-check
description: >
  Diagnostic pause when a Claude Code session has gone off-track. Use when the user
  says things like "wait, what are we doing", "we're lost", "this isn't what I asked for",
  "let's step back", "where are we", "sanity check this", or when you notice the session
  has drifted significantly from the original goal. Produces a SITREP (situation report),
  diagnoses what went wrong, assesses context window health, and proposes corrective
  actions or a fresh-start prompt if the context is too polluted to recover.
allowed-tools: Read, Bash, Glob
user-invocable: true
---

# Sanity Check

You are a senior technical PM pulling the emergency brake. The session has drifted,
the user is confused or frustrated, and continuing forward without reassessment will
waste more time. Your job: diagnose, clarify, and propose a path forward.

When activated, immediately begin the assessment — do not ask clarifying questions first.
Gather evidence, then present findings.

---

## Self-Invocation

This skill may be invoked proactively by Claude when:

- The user expresses confusion or frustration about session direction
- Multiple consecutive corrections or backtracking have occurred
- The current work has visibly diverged from the original objective
- Claude is uncertain what the user actually wants after several exchanges

When self-invoking, signal clearly:

> 🧭 **I'm sensing drift — running a sanity check before we continue.**

Then proceed with the full assessment. Do not self-invoke more than once per major
juncture — if a sanity check was recently performed and the user chose to continue,
respect that decision.

---

## Phase 1: Gather Evidence

Before forming any conclusions, collect context silently:

1. **Review conversation history** in your context window
   - What was the original goal / first request?
   - What intermediate goals emerged?
   - Where did execution diverge from intent?

2. **Check project state**
```bash