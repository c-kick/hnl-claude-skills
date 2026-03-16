---
name: bug-hunter
description: >
  Proactive bug-hunting methodology — autonomous codebase reconnaissance to find
  latent bugs, hidden failure modes, and ticking time bombs BEFORE they detonate
  in production. Use this skill whenever the user asks to "find bugs", "hunt for
  issues", "audit this codebase", "what could go wrong", "find what's broken",
  "stress-test this project", "find landmines", "what will bite me later", or
  any variation of proactive defect discovery. Also trigger when the user says
  "scan for problems", "pre-flight check", "what am I missing across the
  codebase", "find the weak spots", or asks for a proactive quality sweep before
  a release, merge, or deployment. This is NOT for debugging known errors (use
  systematic-debugging) or reviewing specific code you're handed (use
  hostile-review). This is for when there are no known errors yet and you need
  to go FIND them.
---

# Bug Hunter

## Mission Profile

You are a forward reconnaissance unit dropped into unfamiliar terrain. Your job
is not to respond to explosions — that's EOD (systematic-debugging). Your job is
not to interrogate a captured prisoner — that's intel (hostile-review). Your job
is to map the minefield before the infantry walks through it.

**Operational doctrine:** Systematic sweep → threat model → targeted hunt →
proof of kill → debrief.

You report what you find. You verify it's real. You don't guess.

---

## Phase 0: Mission Briefing

Before entering the codebase, establish scope and rules of engagement:

1. **Define the AO (Area of Operations)**
   - Full codebase, specific module, recent changes only, or pre-deploy delta?
   - What's the tech stack? (Language, framework, DB, infra)
   - What's the deployment target? (serverless, containers, bare metal, edge)

2. **Identify high-value targets**
   - What would hurt most if it broke? (auth, payments, data integrity, uptime)
   - What changed recently? (recent commits are higher-probability minefields)
   - What has no tests? (undefended territory)

3. **Set severity threshold**
   - Hunt everything, or only P0/P1 potential?
   - Include code quality / maintainability debt, or strictly runtime defects?

If the user doesn't specify, default to: full codebase, all severities, runtime
defects + data integrity issues prioritized.

---

## Phase 1: Terrain Mapping (Reconnaissance)

Systematically map the codebase topology before hunting. You can't find what's
wrong if you don't know what's there.

### 1.1 Structure Scan

```
1. Map directory structure and module boundaries
2. Identify entry points (HTTP routes, CLI commands, event handlers, cron jobs)
3. Identify exit points (DB writes, API calls, file I/O, message publishing)
4. Map dependency graph (internal module deps + external packages)
5. Locate configuration surfaces (env vars, config files, feature flags)
```

### 1.2 Data Flow Mapping

```
1. Trace primary data paths: input → processing → storage → output
2. Identify trust boundaries (user input, external API responses, DB reads)
3. Map state mutation points (where does shared state get modified?)
4. Identify serialization/deserialization boundaries (JSON parse, DB ORM, API contracts)
5. Note any implicit contracts between modules (undocumented assumptions)
```

### 1.3 Test Coverage Recon

```
1. Check test coverage metrics if available
2. Identify modules with zero or minimal test coverage
3. Note what KIND of tests exist (unit only? integration? e2e?)
4. Flag any tests that are skipped, flaky, or test implementation not behavior
5. Mark untested code paths as HIGH PRIORITY hunt zones
```

**Output:** A mental (or written) map of the codebase with annotated risk zones.
Untested code near trust boundaries = highest priority.

---

## Phase 2: Threat Modeling

For each identified zone, systematically enumerate what CAN go wrong. This is
not guessing — it's applying known failure categories to the specific code.

### The Failure Taxonomy

Apply each category to every relevant component. Not all apply everywhere — skip
what doesn't fit, but don't skip categories out of laziness.

#### 2.1 Input & Validation Failures
- Unvalidated user input reaching business logic or DB queries
- Type coercion surprises (string "0" vs number 0, empty string vs null)
- Missing bounds checks (negative numbers, zero, MAX_INT, empty arrays)
- Encoding mismatches (UTF-8 assumptions, URL encoding, HTML entities)
- Malformed payloads accepted silently (partial JSON, truncated data)

#### 2.2 State & Concurrency Failures
- Race conditions on shared mutable state
- Time-of-check-to-time-of-use (TOCTOU) gaps
- Missing atomicity (multi-step operations that can partially complete)
- Stale reads (cache invalidation failures, read-your-writes violations)
- Session/request state bleed (shared objects across requests)

#### 2.3 Error Handling Failures
- Silent swallowing (catch-and-ignore, empty catch blocks)
- Error type confusion (catching broad Exception, masking specific errors)
- Missing error propagation (error logged but caller not informed)
- Inconsistent error responses (different error formats from same API)
- Resource leaks on error paths (connections, file handles, locks not released)

#### 2.4 Boundary & Integration Failures
- External service timeout/failure not handled (no circuit breaker)
- API contract assumptions not validated (trusting external response shape)
- DB schema drift (code assumes columns/types that may change)
- Version skew between services (deploy order dependencies)
- Missing idempotency on retry-able operations

#### 2.5 Data Integrity Failures
- Silent data loss (overwrite without check, truncation without warning)
- Partial writes visible to readers (no transaction boundaries)
- Orphaned records (parent deleted, children remain)
- Precision loss (float arithmetic on currency, integer overflow)
- Timezone confusion (mixing UTC and local, DST edge cases)

#### 2.6 Resource & Capacity Failures
- Unbounded growth (collections that grow without limit, log files, queues)
- N+1 query patterns (loop-driven DB queries)
- Missing pagination (loading all records into memory)
- Connection pool exhaustion under load
- Memory leaks (event listeners not removed, closures capturing scope)

#### 2.7 Security Failures
- Auth checks missing or in wrong order (check after expensive work)
- Privilege escalation paths (horizontal: user A sees user B's data)
- Secrets in code, logs, or error messages
- Injection vectors (SQL, command, template, path traversal)
- Missing rate limiting on sensitive endpoints

#### 2.8 Temporal & Ordering Failures
- Assumption that operations complete in a specific order
- Missing retry/backoff on transient failures
- Cron job overlap (next execution starts before previous finishes)
- Clock skew sensitivity (distributed systems relying on wall clock)
- Daylight saving time transitions breaking scheduled operations

---

## Phase 3: The Hunt

Now execute targeted searches based on Phase 2 threat model. For each risk zone
identified, apply the appropriate hunt patterns.

### Hunt Methodology

```
For each high-risk zone from Phase 1+2:
  1. SELECT applicable failure categories from Phase 2
  2. SEARCH for concrete instances in the code
  3. TRACE the data/control flow to confirm exploitability
  4. CLASSIFY: confirmed bug, latent risk, or false positive
  5. MOVE to next zone
```

### Hunt Patterns (Quick-Reference Kill Chain)

These are the specific code patterns to grep/search for. Use as a checklist
during the hunt.

**Silent killers (often zero symptoms until catastrophe):**
- `catch` blocks that don't re-throw or return error state
- `.then()` chains without `.catch()` (unhandled promise rejections)
- Writes without transactions where atomicity matters
- `DELETE` operations without cascading or cleanup
- Floating point used for money or precision-critical values

**Ticking time bombs (work now, explode under load or at scale):**
- Array/list operations inside database query loops
- No pagination on queries that return growing datasets
- In-memory caches without eviction policy or TTL
- String concatenation in hot paths (vs. builder/buffer)
- Synchronous I/O on async code paths

**Trust violations (assumes the world is kind):**
- External API response used without schema validation
- User-supplied values in file paths, SQL, shell commands, or template strings
- JWT/token validation that only checks signature, not claims/expiry
- CORS/CSP policies that are overly permissive or missing
- Deserialization of untrusted data without type checking

**State corruption (the Heisenbug factory):**
- Mutable default arguments (Python: `def f(x=[])`)
- Shared object references across request contexts
- Global/module-level state modified at runtime
- Event listeners registered but never removed
- Async operations modifying shared state without locks

**The "works on my machine" special:**
- Hardcoded paths, ports, or hostnames
- Locale-dependent string operations (date parsing, number formatting)
- OS-specific behavior (path separators, line endings, case sensitivity)
- Timezone assumptions (server vs. user vs. database)
- Missing environment variable fallbacks or validation at startup

---

## Phase 4: Verification (Proof of Kill)

A suspected bug is not a confirmed bug until you can demonstrate it. Do NOT
report unverified suspicions as findings.

### Verification Methods (in order of preference)

1. **Write a failing test** — The gold standard. If you can write a test that
   fails because of the bug, it's confirmed and you've started the fix.

2. **Construct a trigger scenario** — Describe the exact sequence of
   inputs/events/timing that would trigger the bug. Be specific enough that
   someone could reproduce it.

3. **Static proof** — For logic errors, show the code path that leads to the
   invalid state. Trace it step by step with concrete values.

4. **Analogous evidence** — If the exact trigger is hard to construct (race
   conditions, distributed timing), cite the pattern and demonstrate it's
   present in the code with specific line references.

### Verification Checklist

For each finding:
- [ ] Can I show the EXACT code path that fails?
- [ ] Can I describe SPECIFIC inputs or conditions that trigger it?
- [ ] Is this a real production risk, or only theoretical under absurd conditions?
- [ ] Have I ruled out that existing code elsewhere doesn't already handle this?

**Kill threshold:** If you can't satisfy at least items 1 and 2, downgrade from
"confirmed bug" to "risk / needs investigation".

---

## Phase 5: Debrief (Report)

### Report Format

```markdown
# 🎯 Bug Hunt Report: [Target / Scope]

**AO:** [what was scanned]
**Hunt duration:** [time/effort]
**Terrain:** [tech stack summary]

## Executive Summary
[2-3 sentences: how many findings, worst severity, overall health assessment]

## Findings

### [SEVERITY] [BH-001]: Title
**Location:** `path/to/file.ext:line`
**Category:** [from Phase 2 taxonomy, e.g., "State & Concurrency > Race Condition"]
**Status:** Confirmed Bug | Latent Risk | Needs Investigation

**The problem:**
[What's wrong, in one paragraph. Be precise.]

**Trigger scenario:**
[How this actually breaks. Specific inputs, timing, conditions.]

**Evidence:**
[Code snippet showing the vulnerable path]

**Impact:**
[What happens when this fires. Data loss? Auth bypass? Silent corruption?]

**Recommended fix:**
[Concrete fix — code preferred, description acceptable for architectural issues]

---
[repeat for each finding]

## Risk Map
[Optional: visual or tabular summary of where risk concentrates]

| Zone | Findings | Worst Severity | Coverage |
|------|----------|---------------|----------|
| auth/ | 3 | CRITICAL | 12% |
| api/handlers/ | 5 | HIGH | 45% |
| utils/ | 1 | LOW | 80% |

## Hunt Coverage
[What was scanned, what was skipped, and why. Intellectual honesty about blind spots.]
```

### Severity Definitions

| Level | Meaning | Example |
|-------|---------|---------|
| **CRITICAL** | Data loss, security breach, or total service failure possible | Auth bypass, silent data corruption |
| **HIGH** | Significant functionality broken under realistic conditions | Race condition on concurrent writes, unbounded query |
| **MEDIUM** | Incorrect behavior in edge cases, degraded performance | Missing null check on optional field, N+1 query |
| **LOW** | Code quality issue that increases future bug probability | Implicit type coercion, missing error context |
| **INFO** | Not a bug, but worth knowing | Undocumented behavior, unusual pattern |

---

## Operational Rules

1. **Sweep systematically.** Don't random-walk through the code hoping to spot
   something. Follow the phases. Map first, model second, hunt third.

2. **Verify before reporting.** Unverified suspicions waste everyone's time. If
   you can't verify it, say so explicitly and classify as "Needs Investigation".

3. **Don't fix during the hunt.** Your job is reconnaissance, not repair. Mixing
   the two means you'll stop hunting once you start fixing. Report everything
   first, fix later (or hand off to systematic-debugging for confirmed issues).

4. **Track your coverage.** Know what you've scanned and what you haven't. A
   hunt that covers 30% of the codebase should say so, not pretend to be
   comprehensive.

5. **Prioritize by blast radius.** Hunt high-value targets first: auth,
   payments, data writes, external integrations. The logging utility can wait.

6. **Fresh eyes principle.** Don't assume anything works correctly because it
   hasn't failed yet. Absence of errors is not evidence of correctness —
   especially in code with no tests.

---

## Integration with Other Skills

- **hostile-review**: For deep-dive on specific suspicious code found during hunt
- **systematic-debugging**: Hand off confirmed bugs for proper root-cause fix cycle
- **staff-review**: Escalate architectural concerns found during terrain mapping
