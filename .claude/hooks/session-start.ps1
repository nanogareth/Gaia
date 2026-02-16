# SessionStart: Inject Gaia domain context and today's plan summary.

# Consume stdin (hook protocol sends JSON on stdin)
try { [Console]::In.ReadToEnd() | Out-Null } catch {}

$gaiaRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$context = @()

# --- Today's plan summary (first 20 lines) ---
$todayFile = Join-Path $gaiaRoot "temporal/today.md"
if (Test-Path $todayFile) {
    $context += "=== Today's Plan ==="
    $plan = Get-Content $todayFile -TotalCount 20 -ErrorAction SilentlyContinue
    if ($plan) { $context += $plan }
    $context += ""
}

# --- Domain snapshot ---
$context += "=== Domain Status ==="
$todayDate = Get-Date -Format "yyyy-MM-dd"
$overdue = @()

Get-ChildItem (Join-Path $gaiaRoot "domains/*.md") -ErrorAction SilentlyContinue | ForEach-Object {
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
