#!/usr/bin/env bash
# hnl-claude-skills — bash port
# Source this file from ~/.bashrc or ~/.zshrc:
#   . "$HOME/.config/hnl-claude-skills/hnl-claude-skills.sh"

CLAUDE_SKILLS="${CLAUDE_SKILLS:-$HOME/.config/hnl-claude-skills}"

skill-ls() {
    for d in "$CLAUDE_SKILLS"/*/; do
        [ -d "$d" ] && basename "$d"
    done
}

skill-add() {
    if [ $# -eq 0 ]; then
        echo "Usage: skill-add <skill> [skill...]"
        return 1
    fi
    mkdir -p .claude/skills
    for s in "$@"; do
        local src="$CLAUDE_SKILLS/$s"
        local dst=".claude/skills/$s"
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            if [ -L "$dst" ]; then
                local target
                target=$(readlink "$dst")
                case "$target" in
                    *hnl-claude-skills*)
                        echo "ALREADY_INSTALLED: $s"
                        continue
                        ;;
                    *)
                        echo "EXISTS: $s (not managed by hnl-claude-skills, skipping)"
                        continue
                        ;;
                esac
            else
                echo "EXISTS: $s (not managed by hnl-claude-skills, skipping)"
                continue
            fi
        fi
        ln -sfn "$src" "$dst"
        echo "OK: $s"
    done
}

skill-add-all() {
    for d in "$CLAUDE_SKILLS"/*/; do
        skill-add "$(basename "$d")"
    done
}

skill-remove() {
    if [ $# -eq 0 ]; then
        echo "Usage: skill-remove <skill> [skill...]"
        return 1
    fi
    for s in "$@"; do
        local dst=".claude/skills/$s"
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            rm -f "$dst"
            echo "REMOVED: $s"
        else
            echo "NOT FOUND: $s"
        fi
    done
}

_load_bundles() {
    local conf="$CLAUDE_SKILLS/bundles.conf"
    if [ ! -f "$conf" ]; then
        echo "ERROR: bundles.conf not found in $CLAUDE_SKILLS" >&2
        return 1
    fi

    _BUNDLE_NAMES=()

    local current=""
    while IFS= read -r line || [ -n "$line" ]; do
        # strip carriage return
        line="${line%$'\r'}"
        # skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        # section header
        if [[ "$line" =~ ^\[([^]]+)\]$ ]]; then
            current="${BASH_REMATCH[1]}"
            _BUNDLE_NAMES+=("$current")
            eval "_BUNDLE_SKILLS_${current}=''"
            eval "_BUNDLE_EXTENDS_${current}=''"
            continue
        fi

        [ -z "$current" ] && continue

        # extends directive
        if [[ "$line" =~ ^extends=(.+)$ ]]; then
            eval "_BUNDLE_EXTENDS_${current}='${BASH_REMATCH[1]}'"
            continue
        fi

        # skill name — append with newline separator
        local current_skills
        eval "current_skills=\"\$_BUNDLE_SKILLS_${current}\""
        if [ -n "$current_skills" ]; then
            eval "_BUNDLE_SKILLS_${current}=\"\${current_skills}
${line}\""
        else
            eval "_BUNDLE_SKILLS_${current}=\"${line}\""
        fi
    done < "$conf"
}

_resolve_bundle() {
    local name="$1"
    shift
    # remaining args are the visiting stack
    local visiting=("$@")

    # circular dependency check
    for v in "${visiting[@]}"; do
        if [ "$v" = "$name" ]; then
            echo "ERROR: Circular extends detected at bundle '$name'" >&2
            return 1
        fi
    done

    # existence check
    local found=0
    for b in "${_BUNDLE_NAMES[@]}"; do
        if [ "$b" = "$name" ]; then
            found=1
            break
        fi
    done
    if [ "$found" -eq 0 ]; then
        echo "ERROR: Bundle '$name' not found" >&2
        return 1
    fi

    visiting+=("$name")

    # resolve parents
    local extends_val
    eval "extends_val=\"\$_BUNDLE_EXTENDS_${name}\""
    if [ -n "$extends_val" ]; then
        IFS=',' read -ra parents <<< "$extends_val"
        for parent in "${parents[@]}"; do
            parent="${parent// /}"
            _resolve_bundle "$parent" "${visiting[@]}" || return 1
        done
    fi

    # add own skills (deduplicated)
    local skills_val
    eval "skills_val=\"\$_BUNDLE_SKILLS_${name}\""
    if [ -n "$skills_val" ]; then
        while IFS= read -r skill; do
            skill="${skill// /}"
            [ -z "$skill" ] && continue
            # deduplicate
            local dup=0
            for existing in "${_RESOLVED_SKILLS[@]}"; do
                if [ "$existing" = "$skill" ]; then
                    dup=1
                    break
                fi
            done
            if [ "$dup" -eq 0 ]; then
                _RESOLVED_SKILLS+=("$skill")
            fi
        done <<< "$skills_val"
    fi
}

skill-ls-bundles() {
    local filter="${1:-}"
    _load_bundles || return 1

    local names=()
    if [ -n "$filter" ]; then
        local found=0
        for b in "${_BUNDLE_NAMES[@]}"; do
            if [ "$b" = "$filter" ]; then
                found=1
                break
            fi
        done
        if [ "$found" -eq 0 ]; then
            echo "ERROR: Bundle '$filter' not found"
            return 1
        fi
        names=("$filter")
    else
        names=("${_BUNDLE_NAMES[@]}")
    fi

    for name in "${names[@]}"; do
        _RESOLVED_SKILLS=()
        _resolve_bundle "$name" || return 1
        echo ""
        echo "[$name]"
        for skill in "${_RESOLVED_SKILLS[@]}"; do
            echo "  $skill"
        done
    done
}

skill-bundle-add() {
    local bundle="${1:-}"
    if [ -z "$bundle" ]; then
        echo "Usage: skill-bundle-add <bundle>"
        echo "Run 'skill-ls-bundles' to see available bundles"
        return 1
    fi
    _load_bundles || return 1
    _RESOLVED_SKILLS=()
    _resolve_bundle "$bundle" || return 1
    echo "Installing bundle '$bundle' (${#_RESOLVED_SKILLS[@]} skills):"
    for skill in "${_RESOLVED_SKILLS[@]}"; do
        skill-add "$skill"
    done
}

skill-bundle-remove() {
    local bundle="${1:-}"
    if [ -z "$bundle" ]; then
        echo "Usage: skill-bundle-remove <bundle>"
        echo "Run 'skill-ls-bundles' to see available bundles"
        return 1
    fi
    _load_bundles || return 1
    _RESOLVED_SKILLS=()
    _resolve_bundle "$bundle" || return 1
    echo "Removing bundle '$bundle' (${#_RESOLVED_SKILLS[@]} skills):"
    for skill in "${_RESOLVED_SKILLS[@]}"; do
        skill-remove "$skill"
    done
}

skill-ls-installed() {
    local skills_dir=".claude/skills"
    if [ ! -d "$skills_dir" ]; then
        echo "No skills directory found in current project."
        return
    fi
    local count=0
    for item in "$skills_dir"/*/; do
        [ -d "$item" ] || continue
        count=1
        local name
        name=$(basename "$item")
        if [ -L "$item" ] || [ -L "${item%/}" ]; then
            local target
            target=$(readlink "${item%/}")
            case "$target" in
                *hnl-claude-skills*)
                    echo "LINKED:   $name -> $target"
                    ;;
                *)
                    echo "EXTERNAL: $name -> $target"
                    ;;
            esac
        else
            echo "EXTERNAL: $name (local directory)"
        fi
    done
    if [ "$count" -eq 0 ]; then
        echo "No skills installed in current project."
    fi
}

skill-update() {
    echo "Updating hnl-claude-skills..."
    (cd "$CLAUDE_SKILLS" && git pull && git submodule update --remote)
}
