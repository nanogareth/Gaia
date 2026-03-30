# SessionStart: Inject Gaia context — priorities, gamification stats, domain health.

# Consume stdin (hook protocol sends JSON on stdin)
try { [Console]::In.ReadToEnd() | Out-Null } catch {}

$gaiaRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$context = @()

# --- Gamification stats ---
$gamFile = Join-Path $gaiaRoot "temporal\gamification.json"
if (Test-Path $gamFile) {
    try {
        $gam = Get-Content $gamFile -Raw | ConvertFrom-Json
        $toNext = 0
        $thresholds = @(0, 100, 300, 600, 1000, 1500, 2500, 4000)
        for ($i = 0; $i -lt $thresholds.Count; $i++) {
            if ($gam.xp -lt $thresholds[$i]) { $toNext = $thresholds[$i] - $gam.xp; break }
        }
        $streak = if ($gam.current_streak -gt 0) { " | Streak: $($gam.current_streak)d" } else { " | No active streak" }
        $domains = @($gam.weekly_domains_touched).Count
        $nextStr = if ($toNext -gt 0) { " ($toNext to Lv$($gam.level + 1))" } else { "" }

        $context += "=== Gaia Status ==="
        $context += "Lv$($gam.level) $($gam.level_name) | XP: $($gam.xp)$nextStr$streak | Domains: $domains/11 this week"

        # Show domain health scores if available
        if ($gam.domain_health) {
            $healthLine = ""
            $gam.domain_health.PSObject.Properties | Sort-Object Value | ForEach-Object {
                $bar = if ($_.Value -ge 60) { "OK" } elseif ($_.Value -ge 30) { "!!" } else { "XX" }
                $healthLine += " $($_.Name):$($_.Value)[$bar]"
            }
            if ($healthLine) { $context += "Health:$healthLine" }
        }
        $context += ""
    } catch {}
}

# --- Today's top priority (extracted prominently) ---
$todayFile = Join-Path $gaiaRoot "temporal\today.md"
if (Test-Path $todayFile) {
    $todayContent = Get-Content $todayFile -ErrorAction SilentlyContinue
    $priorities = @()
    $inPriorities = $false
    foreach ($line in $todayContent) {
        if ($line -match '^## Priorities') { $inPriorities = $true; continue }
        if ($inPriorities -and $line -match '^## ') { break }
        if ($inPriorities -and $line -match '^\d+\.') { $priorities += $line }
    }

    if ($priorities.Count -gt 0) {
        $context += ">>> TODAY'S #1 PRIORITY: $($priorities[0] -replace '^\d+\.\s*', '') <<<"
        $context += ""
    }

    # Plan summary (first 15 lines after frontmatter)
    $context += "=== Today's Plan ==="
    $planLines = @()
    $pastFrontmatter = $false
    foreach ($line in $todayContent) {
        if ($pastFrontmatter) { $planLines += $line }
        if ($line -match '^---$' -and $planLines.Count -eq 0) { $pastFrontmatter = $true }
        if ($planLines.Count -ge 15) { break }
    }
    if ($planLines) { $context += $planLines }
    $context += ""
}

# --- Domain snapshot with overdue flags ---
$context += "=== Domain Status ==="
$todayDate = Get-Date -Format "yyyy-MM-dd"
$overdue = @()

Get-ChildItem (Join-Path $gaiaRoot "domains\*.md") -ErrorAction SilentlyContinue | ForEach-Object {
    $raw = Get-Content $_.FullName -Raw
    if ($raw -match '(?s)^---\s*\n(.*?)\n---') {
        $fm = $Matches[1]
        $domain     = if ($fm -match '(?m)^domain:\s*(.+)$')      { $Matches[1].Trim() } else { "?" }
        $status     = if ($fm -match '(?m)^status:\s*(.+)$')      { $Matches[1].Trim() } else { "?" }
        $updated    = if ($fm -match '(?m)^updated:\s*(.+)$')     { $Matches[1].Trim().Split('T')[0] } else { "?" }
        $nextReview = if ($fm -match '(?m)^next_review:\s*(.+)$') { $Matches[1].Trim() } else { "" }

        $context += "- ${domain}: status=$status, updated=$updated, next_review=$nextReview"

        if ($nextReview -and ($nextReview -lt $todayDate)) {
            $overdue += "  OVERDUE: $domain (was due $nextReview)"
        }
    }
}

if ($overdue.Count -gt 0) {
    $context += ""
    $context += $overdue
}

# --- Output JSON ---
$contextStr = ($context | Out-String).Trim()
if ($contextStr) {
    $output = @{
        hookSpecificOutput = @{
            hookEventName    = "SessionStart"
            additionalContext = $contextStr
        }
    }
    $output | ConvertTo-Json -Depth 3 -Compress
}

exit 0
