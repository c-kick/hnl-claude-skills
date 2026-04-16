# hnl-claude-skills
### A centralized, local skill repository.

This repository contains my custom Claude Code skills, along with a small management layer that maintains them in a single source and distributes them across projects via symlinks (macOS/Linux) or junctions (Windows).

You can add a specific skill to a project, or install a predefined bundle of skills. This doesn't replace the standard Claude Code skills workflow — you can still drop a `SKILL.md` anywhere manually as you normally would. This just adds a central home for skills you want to reuse across projects.

### Example
In your project root, run `skill-add reflect`. This installs the `reflect` skill in `.claude/skills` as a symlink/junction pointing to the local repository at `~/.config/hnl-claude-skills`. No matter how many projects use the skill, it lives in one place — update it in the repository, and every project picks up the change immediately.

#### Bundles
You can also define bundles - predefined collections of skills. Example: `skill-bundle-add web_development` installs all skills in that bundle at once, each as a symlink/junction to the repository — the same as adding them individually. Bundles also support inheritance: `web_development` can extend `code_development`, which in turn extends `general`, so installing `web_development` pulls in the full chain automatically.

---

## Installation

**Windows (PowerShell):**

1. Clone the repository
```powershell
git clone --recurse-submodules https://github.com/c-kick/hnl-claude-skills.git "$HOME/.config/hnl-claude-skills"
```

> **Note:** PowerShell does not expand `~` for external programs like `git`. Always use `$HOME` instead.

The default location is `~/.config/hnl-claude-skills`. To use a different path, clone there instead and set `CLAUDE_SKILLS` in your environment before sourcing the script — both scripts will pick it up.

2. Add to PowerShell profile (Run `notepad $PROFILE` in PowerShell*):
```powershell
# Optional: set a custom location
# $env:CLAUDE_SKILLS = "D:\path\to\hnl-claude-skills"
. "$HOME\.config\hnl-claude-skills\hnl-claude-skills.ps1"
```
> If you get an error running `notepad $PROFILE`, this means you don't have a PowerShell profile yet. You can create one with `New-Item -Path $PROFILE -ItemType File -Force`

**macOS/Linux**

1. Clone the repository
```bash
git clone --recurse-submodules https://github.com/c-kick/hnl-claude-skills.git ~/.config/hnl-claude-skills
```

2. Add to `~/.bashrc` or `~/.zshrc`:
```bash
# Optional: set a custom location
# export CLAUDE_SKILLS="/path/to/hnl-claude-skills"
. "$HOME/.config/hnl-claude-skills/hnl-claude-skills.sh"
```

Reload your shell (in Windows PowerShell, just run `. $PROFILE`), done.

---

## Commands

All commands are run from any **project root** you want to use the skills in.

| Command | Description |
|---|---|
| `skill-ls` | List all skills in the registry |
| `skill-ls-bundles [bundle]` | List all bundles and their resolved skill chains; optionally filter to one bundle |
| `skill-ls-installed` | Show skills installed in the current project, with status |
| `skill-add <skill> [...]` | Link one or more skills into the current project |
| `skill-add-all` | Link all skills into the current project |
| `skill-remove <skill> [...]` | Remove one or more skills from the current project |
| `skill-bundle-add <bundle>` | Install a full bundle (resolves inheritance chain) |
| `skill-bundle-remove <bundle>` | Remove a full bundle (exact mirror of add) |
| `skill-update` | Pull latest changes for the registry and all submodules |

### `skill-ls-installed` status codes

| Status | Meaning |
|---|---|
| `LINKED` | Junction/symlink pointing into this registry — managed |
| `EXTERNAL` | Real directory or foreign junction — not managed, will not be touched |

### `skill-add` status codes

| Status | Meaning |
|---|---|
| `OK` | Fresh junction/symlink created |
| `ALREADY_INSTALLED` | Already linked to this registry, skipped |
| `EXISTS` | Real directory or foreign junction, skipped |


### Updating skills

To update the skills from this repository, just use:
```bash
skill-update
```

Works from any directory, runs `git pull` and `git submodule update --remote` in the registry. All projects with linked skills pick up changes immediately — no action needed in individual projects.

---

## Bundles

Bundles are defined in `bundles.conf`. Format:

```ini
[bundle-name]
extends=other-bundle,another-bundle   # optional, comma-separated
skill-one
skill-two
```

- `extends` resolves recursively and deduplicates — installing `web_development` also installs everything in `code_development` and `general`.
- Circular extends are detected and hard-error.
- Multiple parents are supported: `extends=general,code_development`.

---

## Adding your own skills

You don't have to rely on the skills that this repository gives you - you can add your own to the local repository!

Create a skill and just copy its folder to `~/.config/hnl-claude-skills/` (or whichever `CLAUDE_SKILLS` path you're using). Once added, `skill-add my-skill` works in any project just like any other skill.

---

## Adding an external skill repo

For skills that live in their own repository, add them as a submodule:

```bash
cd ~/.config/hnl-claude-skills   # on Windows PowerShell, use: cd "$HOME/.config/hnl-claude-skills"
git submodule add https://github.com/you/skill-repo.git skill-name
git commit -m "add: skill-name as submodule"
git push
```

To update a submodule to its latest version:

```bash
cd ~/.config/hnl-claude-skills   # on Windows PowerShell, use: cd "$HOME/.config/hnl-claude-skills"
git submodule update --remote skill-name
git commit -m "update: skill-name to latest"
git push
```

Or just run `skill-update` to pull everything at once.

---

## Known limitations

**`skill-bundle-remove` removes the full resolved chain.** If you manually added a skill via `skill-add` *before* running `skill-bundle-add`, and that skill is part of the bundle's resolved chain, `skill-bundle-remove` will remove it. This is by design — remove mirrors add exactly. If you want to keep a skill after removing a bundle, re-add it manually with `skill-add`.
