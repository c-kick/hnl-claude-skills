# hnl-claude-skills
$env:CLAUDE_SKILLS = "$HOME\.config\hnl-claude-skills"

function skill-ls {
    Get-ChildItem $env:CLAUDE_SKILLS -Directory | Select-Object -ExpandProperty Name
}

function skill-add {
    New-Item -ItemType Directory -Force -Path ".claude\skills" | Out-Null
    foreach ($s in $args) {
        $src = "$env:CLAUDE_SKILLS\$s"
        $dst = ".claude\skills\$s"
        if (Test-Path $src) {
            New-Item -ItemType Junction -Path $dst -Target $src -Force | Out-Null
            Write-Host "OK: $s"
        } else {
            Write-Host "NOT FOUND: $s (not in $env:CLAUDE_SKILLS)"
        }
    }
}

function skill-remove {
    foreach ($s in $args) {
        $dst = ".claude\skills\$s"
        if (Test-Path $dst) {
            cmd /c rmdir "$dst"
            Write-Host "REMOVED: $s"
        } else {
            Write-Host "NOT FOUND: $s"
        }
    }
}

function _load-bundles {
    $bundleFile = "$env:CLAUDE_SKILLS\bundles.json"
    if (-not (Test-Path $bundleFile)) {
        Write-Host "ERROR: bundles.json not found in $env:CLAUDE_SKILLS"
        exit 1
    }
    $raw = Get-Content $bundleFile | ConvertFrom-Json
    $bundles = @{}
    $raw.PSObject.Properties | ForEach-Object { $bundles[$_.Name] = $_.Value }
    return $bundles
}

function _resolve-bundle {
    param(
        [string]$name,
        [hashtable]$bundles,
        [System.Collections.Generic.List[string]]$resolved,
        [System.Collections.Generic.List[string]]$visiting
    )
    if ($visiting.Contains($name)) {
        Write-Host "ERROR: Circular extends detected at bundle '$name'"
        exit 1
    }
    if (-not $bundles.ContainsKey($name)) {
        Write-Host "ERROR: Bundle '$name' not found"
        exit 1
    }
    $visiting.Add($name) | Out-Null
    $bundle = $bundles[$name]
    if ($bundle.extends) {
        foreach ($parent in $bundle.extends) {
            _resolve-bundle -name $parent -bundles $bundles -resolved $resolved -visiting $visiting
        }
    }
    foreach ($skill in $bundle.skills) {
        if (-not $resolved.Contains($skill)) {
            $resolved.Add($skill) | Out-Null
        }
    }
    $visiting.Remove($name) | Out-Null
}

function skill-ls-bundles {
    param([string]$filter = "")
    $bundles = _load-bundles
    $names = if ($filter) {
        if (-not $bundles.ContainsKey($filter)) {
            Write-Host "ERROR: Bundle '$filter' not found"
            return
        }
        @($filter)
    } else {
        $bundles.Keys
    }
    foreach ($name in $names) {
        $resolved = [System.Collections.Generic.List[string]]::new()
        $visiting = [System.Collections.Generic.List[string]]::new()
        _resolve-bundle -name $name -bundles $bundles -resolved $resolved -visiting $visiting
        Write-Host ""
        Write-Host "[$name]"
        foreach ($skill in $resolved) { Write-Host "  $skill" }
    }
}

function skill-bundle-add {
    param([string]$bundle = "")
    if (-not $bundle) {
        Write-Host "Usage: skill-bundle-add <bundle>"
        Write-Host "Run 'skill-ls-bundles' to see available bundles"
        return
    }
    $bundles = _load-bundles
    $resolved = [System.Collections.Generic.List[string]]::new()
    $visiting = [System.Collections.Generic.List[string]]::new()
    _resolve-bundle -name $bundle -bundles $bundles -resolved $resolved -visiting $visiting
    Write-Host "Installing bundle '$bundle' ($($resolved.Count) skills):"
    skill-add @($resolved)
}

function skill-bundle-remove {
    param([string]$bundle = "")
    if (-not $bundle) {
        Write-Host "Usage: skill-bundle-remove <bundle>"
        Write-Host "Run 'skill-ls-bundles' to see available bundles"
        return
    }
    $bundles = _load-bundles
    $resolved = [System.Collections.Generic.List[string]]::new()
    $visiting = [System.Collections.Generic.List[string]]::new()
    _resolve-bundle -name $bundle -bundles $bundles -resolved $resolved -visiting $visiting
    Write-Host "Removing bundle '$bundle' ($($resolved.Count) skills):"
    skill-remove @($resolved)
}
