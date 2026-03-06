---
name: commit-message
description: Draft git commit messages. Use when asked to create, draft, or prepare a commit message. Analyzes staged/unstaged changes and recent history to match project style.
allowed-tools: Bash, Read
user-invocable: true
---

# Commit Message Drafting

Generate commit messages following conventional commit format and project style. Do NOT commit afterwards; user will commit, or ask to commit!

## Process

1. **Gather context** (run in parallel):
   ```bash
   git status --short
   git diff --stat
   git log -5 --oneline
   ```

2. **Analyze changes** by category:
   - Features added (feat)
   - Bug fixes (fix)
   - Refactoring (refactor)
   - Documentation (docs)
   - Build/tooling (build, chore)
   - Style/formatting (style)

3. **Draft message** using conventional commits:
   ```
   type(scope): short description

   - Bullet point details
   - Another change

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
   ```

## Commit Types

| Type | When to use |
|------|-------------|
| feat | New feature or capability |
| fix | Bug fix |
| refactor | Code restructuring without behavior change |
| docs | Documentation only |
| style | Formatting, whitespace (no code change) |
| build | Build system, dependencies |
| chore | Maintenance tasks |
| perf | Performance improvement |
| test | Adding or fixing tests |

## Rules

- First line: type(scope): description (max 72 chars)
- Scope is optional, use component/area name
- Use imperative mood ("Add" not "Added")
- Body explains "what" and "why", not "how"
- Reference related issues if applicable
- For large changesets, consider suggesting multiple smaller commits

## Examples

Single change:
```
fix(auth): Prevent session timeout on form submission
```

Multiple changes (same area):
```
feat(page-parts): Add usage tracking and link resolution

- Add get_link() for post:123/term:123/archive:type formats
- Show meta box with pages embedding each page part
- Add AJAX endpoint for usage checking
```

Major refactoring:
```
refactor: Remove vendored Bootstrap in favor of npm

- Delete 80K+ lines of Bootstrap 5.3.3 source files
- Add gitignore rules for compiled CSS and source maps
- Bootstrap now managed via package.json dependencies
```
