# Git Scraper -- Scan manifest repos for new commits, update domain activity.
# Runs as a standalone scheduled task (no Claude API needed).
#
# Usage: powershell.exe -ExecutionPolicy Bypass -NoProfile -File git-scraper.ps1
#
# What it does:
#   1. Reads manifest.yaml for repo list + paths
#   2. For each repo, runs git log to find commits since last scan
#   3. Appends new commits to the relevant domain's Recent Activity
#   4. Updates frontmatter timestamps
#   5. Awards gamification XP
#   6. Commits and pushes Gaia changes

$ErrorActionPreference = "Continue"

$GaiaRoot   = if ($env:GAIA_ROOT) { $env:GAIA_ROOT } else { "C:\GitHub\Gaia" }
$Manifest   = Join-Path $GaiaRoot "manifest.yaml"
$StateFile  = Join-Path $GaiaRoot "scheduling\state\scraper-state.json"
$LogDir     = Join-Path $GaiaRoot "scheduling\logs"
$LogFile    = Join-Path $LogDir "git-scraper-$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"
$DefaultRoot = "C:\GitHub"

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$ts] $msg"
    try { Add-Content -Path $LogFile -Value $entry -ErrorAction SilentlyContinue } catch {}
}

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
Log "=== Git Scraper started ==="

# --- Pull latest Gaia state ---
$pullResult = git -C $GaiaRoot pull --rebase 2>&1
if ($LASTEXITCODE -ne 0) {
    Log "WARNING: git pull failed: $pullResult"
}

# --- Parse manifest.yaml ---
if (-not (Test-Path $Manifest)) {
    Log "FAIL: manifest.yaml not found at $Manifest"
    exit 1
}

$entries = @()
$current = @{ name = ""; github = ""; domain = ""; path = ""; status = "" }
$inUncloned = $false

foreach ($line in (Get-Content $Manifest)) {
    # Stop parsing when we hit the uncloned section
    if ($line -match '^\s*uncloned:') {
        if ($current.name -and $current.domain) {
            $entries += [PSCustomObject]$current
        }
        $inUncloned = $true
        continue
    }
    if ($inUncloned) { continue }

    if ($line -match '^\s*-\s*name:\s*(.+)') {
        if ($current.name -and $current.domain) {
            $entries += [PSCustomObject]$current
        }
        $current = @{ name = $Matches[1].Trim(); github = ""; domain = ""; path = ""; status = "" }
    }
    elseif ($line -match '^\s*github:\s*(.+)')      { $current.github = $Matches[1].Trim() }
    elseif ($line -match '^\s*domain:\s*(.+)')       { $current.domain = $Matches[1].Trim() }
    elseif ($line -match '^\s*path:\s*(.+)$') { $current.path = $Matches[1].Trim().Trim("'`"") }
    elseif ($line -match '^\s*status:\s*(.+)')       { $current.status = $Matches[1].Trim() }
}
if (-not $inUncloned -and $current.name -and $current.domain) {
    $entries += [PSCustomObject]$current
}

Log "Manifest: $($entries.Count) active repos"

# --- Load scraper state ---
$state = @{ repos = @{} }
if (Test-Path $StateFile) {
    try {
        $state = Get-Content $StateFile -Raw | ConvertFrom-Json
        # Ensure repos is a hashtable-like object
        if (-not $state.repos) { $state.repos = @{} }
    } catch {
        Log "WARNING: Could not parse state file, starting fresh"
        $state = @{ repos = @{} }
    }
}

# --- Load gamification engine ---
$gamScript = Join-Path $GaiaRoot ".claude\hooks\gamification.ps1"
$hasGamification = Test-Path $gamScript
if ($hasGamification) {
    try { . $gamScript } catch { $hasGamification = $false; Log "WARNING: gamification load failed: $_" }
}

# --- Scan each repo ---
$anyChanges = $false
$date = Get-Date -Format "yyyy-MM-dd"
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

foreach ($repo in $entries) {
    if ($repo.status -and $repo.status -ne "active") {
        Log "SKIP: $($repo.name) (status: $($repo.status))"
        continue
    }

    # Resolve path
    $repoPath = if ($repo.path) { $repo.path } else { Join-Path $DefaultRoot $repo.name }

    if (-not (Test-Path $repoPath)) {
        Log "SKIP: $($repo.name) -- path not found: $repoPath"
        continue
    }

    # Check for .git directory
    $gitDir = Join-Path $repoPath ".git"
    if (-not (Test-Path $gitDir)) {
        Log "SKIP: $($repo.name) -- no .git at $repoPath"
        continue
    }

    # Get last known commit for this repo
    $lastCommit = $null
    if ($state.repos.PSObject -and $state.repos.PSObject.Properties[$repo.name]) {
        $lastCommit = $state.repos.($repo.name).last_commit
    } elseif ($state.repos -is [hashtable] -and $state.repos.ContainsKey($repo.name)) {
        $lastCommit = $state.repos[$repo.name].last_commit
    }

    # Fetch new commits
    try {
        if ($lastCommit) {
            # Check if the last known commit still exists (handles force-pushes)
            $commitExists = git -C $repoPath cat-file -t $lastCommit 2>$null
            if ($LASTEXITCODE -ne 0) {
                Log "WARNING: $($repo.name) -- last commit $lastCommit no longer exists, scanning last 7 days"
                $since = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
                $newCommits = git -C $repoPath log --oneline --since=$since --reverse 2>$null
            } else {
                $newCommits = git -C $repoPath log --oneline "$lastCommit..HEAD" --reverse 2>$null
            }
        } else {
            # First scan -- take last 7 days of commits
            $since = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
            $newCommits = git -C $repoPath log --oneline --since=$since --reverse 2>$null
        }
    } catch {
        Log "ERROR: $($repo.name) -- git log failed: $_"
        continue
    }

    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: $($repo.name) -- git log returned exit code $LASTEXITCODE"
        continue
    }

    # Parse commits
    $commits = @()
    if ($newCommits) {
        $commits = @($newCommits -split "`n" | Where-Object { $_.Trim() })
    }

    if ($commits.Count -eq 0) {
        Log "OK: $($repo.name) -- no new commits"
        # Still update current HEAD in state
        try {
            $currentHead = (git -C $repoPath rev-parse --short HEAD 2>$null).Trim()
            if ($currentHead) {
                if ($state.repos -is [hashtable]) {
                    $state.repos[$repo.name] = @{ last_commit = $currentHead }
                } else {
                    $state.repos | Add-Member -NotePropertyName $repo.name -NotePropertyValue @{ last_commit = $currentHead } -Force
                }
            }
        } catch {}
        continue
    }

    Log "FOUND: $($repo.name) -- $($commits.Count) new commit(s)"

    # --- Append to domain file ---
    $domainFile = Join-Path $GaiaRoot "domains\$($repo.domain).md"
    if (-not (Test-Path $domainFile)) {
        Log "WARNING: domain file not found: $domainFile"
        continue
    }

    $lines = Get-Content $domainFile
    $newLines = @()
    $inActivity = $false
    $inserted = $false

    # Build activity entries (collapse to latest commit message to avoid spam)
    # If many commits, summarize; if few, list individually
    $activityEntries = @()
    if ($commits.Count -le 3) {
        foreach ($c in $commits) {
            $msg = ($c -replace '^\w+\s+', '').Trim()
            $activityEntries += "- **[$date]** $($repo.name): $msg"
        }
    } else {
        $latestMsg = ($commits[-1] -replace '^\w+\s+', '').Trim()
        $activityEntries += "- **[$date]** $($repo.name): $latestMsg (+$($commits.Count - 1) more commits)"
    }

    foreach ($line in $lines) {
        if ($line -match '^## Recent Activity') {
            $inActivity = $true
            $newLines += $line
            continue
        }
        if ($inActivity -and ($line -match '^## ') -and ($line -notmatch '^## Recent Activity')) {
            foreach ($entry in $activityEntries) { $newLines += $entry }
            $newLines += ""
            $inActivity = $false
            $inserted = $true
        }
        $newLines += $line
    }
    if ($inActivity -and -not $inserted) {
        foreach ($entry in $activityEntries) { $newLines += $entry }
        $newLines += ""
    }

    $newLines | Set-Content $domainFile -Encoding UTF8

    # Update frontmatter
    $content = Get-Content $domainFile -Raw
    $content = $content -replace '(?m)^updated: .+', "updated: $timestamp"
    $content = $content -replace '(?m)^updated_by: .+', "updated_by: git-scraper"
    [System.IO.File]::WriteAllText($domainFile, $content)

    Log "Updated: $domainFile"
    $anyChanges = $true

    # Update state with current HEAD
    try {
        $currentHead = (git -C $repoPath rev-parse --short HEAD 2>$null).Trim()
        if ($currentHead) {
            if ($state.repos -is [hashtable]) {
                $state.repos[$repo.name] = @{ last_commit = $currentHead }
            } else {
                $state.repos | Add-Member -NotePropertyName $repo.name -NotePropertyValue @{ last_commit = $currentHead } -Force
            }
        }
    } catch {
        Log "WARNING: could not get HEAD for $($repo.name)"
    }

    # Gamification
    if ($hasGamification) {
        try {
            $latestMsg = ($commits[-1] -replace '^\w+\s+', '').Trim()
            $result = Record-DomainActivity $repo.domain "$($repo.name): $latestMsg"
            if ($result) {
                Log "Gamification: $($result.Stats)"
                if ($result.LeveledUp) { Log "LEVEL UP!" }
                foreach ($ach in $result.NewAchievements) { Log "Achievement: $ach" }
            }
        } catch {
            Log "WARNING: gamification failed for $($repo.name): $_"
        }
    }
}

# --- Save state ---
$state | Add-Member -NotePropertyName "last_run" -NotePropertyValue $timestamp -Force
$state | ConvertTo-Json -Depth 3 | Set-Content $StateFile -Encoding UTF8
Log "State saved to $StateFile"

# --- Commit and push ---
if ($anyChanges) {
    git -C $GaiaRoot add domains/ temporal/gamification.json scheduling/state/scraper-state.json 2>$null
    $commitOutput = git -C $GaiaRoot commit -m "sync: git-scraper activity update" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Log "Committed changes"
        $pushOutput = git -C $GaiaRoot push 2>&1
        if ($LASTEXITCODE -ne 0) {
            Log "FAIL: push failed: $pushOutput"
            $pendingDir = Join-Path $GaiaRoot ".pending"
            New-Item -ItemType Directory -Path $pendingDir -Force | Out-Null
            $pendingFile = Join-Path $pendingDir "scraper-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
            "# Pending: git-scraper push failed at $timestamp" | Set-Content $pendingFile
            "Commit succeeded locally. Retry with: git push" | Add-Content $pendingFile
        } else {
            Log "Pushed successfully"
        }
    } else {
        Log "No changes to commit (or commit failed): $commitOutput"
    }
} else {
    # Still save state file
    git -C $GaiaRoot add scheduling/state/scraper-state.json 2>$null
    git -C $GaiaRoot commit -m "sync: git-scraper state update (no activity)" 2>&1 | Out-Null
    git -C $GaiaRoot push 2>&1 | Out-Null
    Log "No domain changes -- state file updated"
}

# Prune old logs
Get-ChildItem "$LogDir\git-scraper-*.log" -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -Force -ErrorAction SilentlyContinue

Log "=== Git Scraper complete ==="
exit 0
