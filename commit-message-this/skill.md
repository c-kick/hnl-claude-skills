---
name: commit-message-this
description: Draft a commit message strictly for the work done in THIS session, identifying exactly which files belong in the commit. Ignores pre-existing dirty files.
allowed-tools: Bash, Read, Grep, Glob
user-invocable: true
---

# Commit Message for Current Session

Draft a commit message **strictly for the work done in this conversation session**, and list the exact files that should be staged.

**Key principle:** The working tree often has pre-existing uncommitted changes from other work. This skill ONLY covers changes made during the current session. It determines this from the conversation history — the Edit, Write, and Bash tool calls show exactly which files were touched.

## Process

1. **Review the conversation history** to build the authoritative list of changes:
   - Every file modified via Edit or Write tools → source file
   - Every `npm run build` or similar → identify which build artifacts correspond to those source files
   - The initial git status snapshot (at conversation start) shows what was already dirty — **exclude those unless this session edited them further**

2. **Gather current git state** (run in parallel):
   ```bash
   git status --short
   git diff --name-only
   git log -5 --oneline
   ```

3. **Cross-reference**: only include files that appear in both the conversation history (step 1) AND the current diff (step 2). This catches:
   - Source files you edited
   - Build artifacts regenerated from those source files
   - But NOT unrelated dirty files from before or outside the session

4. **Output** two things:

   **a. File list** — grouped by role:
   ```
   Source:
   - path/to/source-file.js
   - path/to/other-file.php

   Build artifacts:
   - path/to/compiled.js
   - path/to/compiled.asset.php
   ```

   **b. Commit message** — conventional commit format:
   ```
   type(scope): short description

   - Bullet point details
   - Another change

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   ```

## Rules

- The conversation history is the source of truth for what belongs in this commit — not `git diff`
- First line: type(scope): description (max 72 chars)
- Scope is optional, use component/area name
- Use imperative mood ("Add" not "Added")
- Body explains "what" and "why", not "how"
- For multi-topic sessions, consider suggesting separate commits per logical change
- Do NOT commit — only draft the message and list the files
- When unsure if a build artifact changed due to this session's work, check its diff content

## Identifying Build Artifacts

Common patterns in this project:
- `src/**/*.js` → `assets/js/*.js` + `assets/js/*.asset.php` (webpack)
- `src/blocks/**/*.js` → `blocks/**/index.js` + `blocks/**/index.asset.php` (webpack)
- `src/components/*.js` → compiled into all consumers' bundles (button-extension, design-selector, embed block)
- SCSS changes → may need `assets/css/*.css` if recompiled
