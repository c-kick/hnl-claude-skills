# hnl-claude-skills
if (-not $env:CLAUDE_SKILLS) {
    $env:CLAUDE_SKILLS = "$HOME\.config\hnl-claude-skills"
}

function skill-ls {
    Get-ChildItem $env:CLAUDE_SKILLS -Directory | Select-Object -ExpandProperty Name
}

function skill-add {
    New-Item -ItemType Directory -Force -Path ".claude\skills" | Out-Null
    foreach ($s in $args) {
        $src = "$env:CLAUDE_SKILLS\$s"
        $dst = ".claude\skills\$s"
        if (Test-Path $dst) {
			$item = Get-Item $dst
			$isOurJunction = ($item.LinkType -eq "Junction") -and ($item.Target -like "*hnl-claude-skills*")
			if ($isOurJunction) {
				Write-Host "ALREADY_INSTALLED: $s"
				continue
			} else {
				Write-Host "EXISTS: $s (not managed by hnl-claude-skills, skipping)"
				continue
			}
		}
		New-Item -ItemType Junction -Path $dst -Target $src | Out-Null
		Write-Host "OK: $s"
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
    $bundleFile = "$env:CLAUDE_SKILLS\bundles.conf"
    if (-not (Test-Path $bundleFile)) {
        Write-Host "ERROR: bundles.conf not found in $env:CLAUDE_SKILLS"
        exit 1
    }
    $bundles = @{}
    $current = $null
    foreach ($line in Get-Content $bundleFile) {
        $line = $line.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { continue }
        if ($line -match '^\[(.+)\]$') {
            $current = $Matches[1]
            $bundles[$current] = [PSCustomObject]@{ skills = @(); extends = @() }
            continue
        }
        if ($null -eq $current) { continue }
        if ($line -match '^extends=(.+)$') {
            $bundles[$current].extends = $Matches[1] -split ',' | ForEach-Object { $_.Trim() }
            continue
        }
        $bundles[$current].skills += $line
    }
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
    foreach ($skill in $resolved) { skill-add $skill }
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
    foreach ($skill in $resolved) { skill-remove $skill }
}


function skill-ls-installed {
    $skillsDir = ".claude\skills"
    if (-not (Test-Path $skillsDir)) {
        Write-Host "No skills directory found in current project."
        return
    }
    $items = Get-ChildItem $skillsDir
    if (-not $items) {
        Write-Host "No skills installed in current project."
        return
    }
    foreach ($item in $items) {
        $isJunction = $item.Attributes -band [IO.FileAttributes]::ReparsePoint
        if ($isJunction) {
            $target = (Get-Item $item.FullName).Target
            if ($target -like "*hnl-claude-skills*") {
                Write-Host "LINKED:   $($item.Name) -> $target"
            } else {
                Write-Host "EXTERNAL: $($item.Name) -> $target"
            }
        } else {
            Write-Host "EXTERNAL: $($item.Name) (local directory)"
        }
    }
}

function skill-update {
    Write-Host "Updating hnl-claude-skills..."
    Push-Location $env:CLAUDE_SKILLS
    git pull
    git submodule update --remote
    Pop-Location
}