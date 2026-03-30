# Gamification Engine — shared functions for XP, streaks, achievements, domain health
# Source this from other hooks: . "$PSScriptRoot\gamification.ps1"

$GaiaRoot = if ($env:GAIA_ROOT) { $env:GAIA_ROOT } else { "C:\GitHub\Gaia" }
$GamFile  = Join-Path $GaiaRoot "temporal\gamification.json"

# --- XP Level Thresholds ---
$Levels = @(
    @{ Level = 1;  Name = "Novice";       MinXP = 0 }
    @{ Level = 2;  Name = "Apprentice";    MinXP = 100 }
    @{ Level = 3;  Name = "Journeyman";    MinXP = 300 }
    @{ Level = 4;  Name = "Adept";         MinXP = 600 }
    @{ Level = 5;  Name = "Expert";        MinXP = 1000 }
    @{ Level = 6;  Name = "Master";        MinXP = 1500 }
    @{ Level = 7;  Name = "Grandmaster";   MinXP = 2500 }
    @{ Level = 8;  Name = "Legend";         MinXP = 4000 }
)

function Get-GamState {
    if (Test-Path $GamFile) {
        return Get-Content $GamFile -Raw | ConvertFrom-Json
    }
    return $null
}

function Save-GamState($state) {
    $state | ConvertTo-Json -Depth 5 | Set-Content $GamFile -Encoding UTF8
}

function Get-LevelForXP($xp) {
    $result = $Levels[0]
    foreach ($l in $Levels) {
        if ($xp -ge $l.MinXP) { $result = $l }
    }
    return $result
}

function Get-XPToNextLevel($xp) {
    for ($i = 0; $i -lt $Levels.Count; $i++) {
        if ($xp -lt $Levels[$i].MinXP) {
            return $Levels[$i].MinXP - $xp
        }
    }
    return 0  # max level
}

function Add-XP($state, [int]$amount, [string]$reason) {
    $state.xp += $amount
    $newLevel = Get-LevelForXP $state.xp
    $leveledUp = $newLevel.Level -gt $state.level
    $state.level = $newLevel.Level
    $state.level_name = $newLevel.Name

    # Keep last 50 XP log entries
    $entry = @{
        date   = (Get-Date -Format "yyyy-MM-dd HH:mm")
        amount = $amount
        reason = $reason
    }
    $log = @($state.xp_log) + @($entry)
    if ($log.Count -gt 50) { $log = $log[-50..-1] }
    $state.xp_log = $log

    return $leveledUp
}

function Update-Streak($state) {
    $today = Get-Date -Format "yyyy-MM-dd"
    $yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")

    if ($state.last_active_date -eq $today) {
        # Already active today, no change
        return
    }
    elseif ($state.last_active_date -eq $yesterday) {
        # Consecutive day
        $state.current_streak += 1
    }
    else {
        # Streak broken (or first activity)
        $state.current_streak = 1
    }

    $state.last_active_date = $today
    if ($state.current_streak -gt $state.longest_streak) {
        $state.longest_streak = $state.current_streak
    }
}

function Update-WeeklyDomains($state, [string]$domain) {
    $today = Get-Date -Format "yyyy-MM-dd"
    $weekStart = (Get-Date).AddDays(-([int](Get-Date).DayOfWeek)).ToString("yyyy-MM-dd")

    # Reset weekly tracking if new week
    if ($state.weekly_reset_date -ne $weekStart) {
        $state.weekly_domains_touched = @()
        $state.weekly_reset_date = $weekStart
    }

    if ($domain -and ($state.weekly_domains_touched -notcontains $domain)) {
        $state.weekly_domains_touched = @($state.weekly_domains_touched) + @($domain)
    }
}

function Get-DomainHealthScore([string]$domain) {
    $domainFile = Join-Path $GaiaRoot "domains\$domain.md"
    if (-not (Test-Path $domainFile)) { return 0 }

    $raw = Get-Content $domainFile -Raw
    $score = 0
    $today = Get-Date

    # Recency (0-40): when was the domain last updated?
    if ($raw -match '(?m)^updated:\s*(.+)$') {
        $updated = $Matches[1].Trim()
        try {
            $updatedDate = [DateTime]::Parse($updated.Split('T')[0])
            $daysAgo = ($today - $updatedDate).Days
            if ($daysAgo -eq 0) { $score += 40 }
            elseif ($daysAgo -eq 1) { $score += 35 }
            elseif ($daysAgo -le 7) { $score += 25 }
            elseif ($daysAgo -le 30) { $score += 15 }
        } catch {}
    }

    # Review status (0-20)
    if ($raw -match '(?m)^next_review:\s*(.+)$') {
        $reviewDate = $Matches[1].Trim()
        try {
            $nextReview = [DateTime]::Parse($reviewDate)
            $daysUntil = ($nextReview - $today).Days
            if ($daysUntil -ge 0) { $score += 20 }
            elseif ($daysUntil -ge -7) { $score += 10 }
        } catch {}
    }

    # Activity count in last 30 days (0-20)
    $activityCount = 0
    $cutoff = $today.AddDays(-30).ToString("yyyy-MM-dd")
    $activityMatches = [regex]::Matches($raw, '\*\*\[(\d{4}-\d{2}-\d{2})\]\*\*')
    foreach ($m in $activityMatches) {
        if ($m.Groups[1].Value -ge $cutoff) { $activityCount++ }
    }
    if ($activityCount -ge 10) { $score += 20 }
    elseif ($activityCount -ge 5) { $score += 15 }
    elseif ($activityCount -ge 2) { $score += 10 }
    elseif ($activityCount -ge 1) { $score += 5 }

    # Has active goals (0-20)
    if ($raw -match '## Active Goals\s*\n([\s\S]*?)(?=\n## )') {
        $goalsSection = $Matches[1].Trim()
        if ($goalsSection.Length -gt 20) { $score += 20 }
        elseif ($goalsSection.Length -gt 0) { $score += 10 }
    }

    return $score
}

function Check-Achievements($state) {
    $newAchievements = @()
    $achieved = @($state.achievements)

    # First Blood — first domain activity
    if ($state.total_sessions -ge 1 -and $achieved -notcontains "first_blood") {
        $achieved += "first_blood"
        $newAchievements += "First Blood: First domain activity captured"
    }

    # Streak achievements
    if ($state.current_streak -ge 3 -and $achieved -notcontains "on_fire") {
        $achieved += "on_fire"
        $newAchievements += "On Fire: 3-day activity streak"
    }
    if ($state.current_streak -ge 7 -and $achieved -notcontains "unstoppable") {
        $achieved += "unstoppable"
        $newAchievements += "Unstoppable: 7-day activity streak"
    }
    if ($state.current_streak -ge 30 -and $achieved -notcontains "marathon") {
        $achieved += "marathon"
        $newAchievements += "Marathon: 30-day activity streak"
    }

    # Well-Rounded — all 11 domains in one week
    if (@($state.weekly_domains_touched).Count -ge 11 -and $achieved -notcontains "well_rounded") {
        $achieved += "well_rounded"
        $newAchievements += "Well-Rounded: All 11 domains touched in one week"
    }

    # Level achievements
    if ($state.level -ge 3 -and $achieved -notcontains "journeyman") {
        $achieved += "journeyman"
        $newAchievements += "Journeyman: Reached level 3"
    }
    if ($state.level -ge 5 -and $achieved -notcontains "expert") {
        $achieved += "expert"
        $newAchievements += "Expert: Reached level 5"
    }

    $state.achievements = $achieved
    return $newAchievements
}

function Get-StatsLine($state) {
    $toNext = Get-XPToNextLevel $state.xp
    $streak = if ($state.current_streak -gt 0) { " | Streak: $($state.current_streak)d" } else { "" }
    $nextStr = if ($toNext -gt 0) { " ($toNext to next)" } else { " (MAX)" }
    return "Lv$($state.level) $($state.level_name) | XP: $($state.xp)$nextStr$streak | Domains: $(@($state.weekly_domains_touched).Count)/11 this week"
}

function Record-DomainActivity([string]$domain, [string]$reason) {
    $state = Get-GamState
    if (-not $state) { return }

    $state.total_sessions += 1
    $state.total_domains_touched += 1

    # Check if domain was dormant (7+ days since last update)
    $isDormantRevival = $false
    $domainFile = Join-Path $GaiaRoot "domains\$domain.md"
    if (Test-Path $domainFile) {
        $raw = Get-Content $domainFile -Raw
        if ($raw -match '(?m)^updated:\s*(.+)$') {
            try {
                $lastUpdate = [DateTime]::Parse($Matches[1].Trim().Split('T')[0])
                $daysSince = ((Get-Date) - $lastUpdate).Days
                if ($daysSince -ge 7) { $isDormantRevival = $true }
            } catch {}
        }
    }

    Update-Streak $state
    Update-WeeklyDomains $state $domain

    # Award XP
    $leveledUp = Add-XP $state 10 "Session: $reason"
    if ($isDormantRevival) {
        Add-XP $state 30 "Revival: $domain (dormant $daysSince days)" | Out-Null
    }

    # Streak XP
    if ($state.current_streak -gt 1) {
        Add-XP $state 5 "Streak: day $($state.current_streak)" | Out-Null
    }

    # Update domain health
    $health = @{}
    Get-ChildItem (Join-Path $GaiaRoot "domains\*.md") -ErrorAction SilentlyContinue | ForEach-Object {
        $name = $_.BaseName
        $health[$name] = Get-DomainHealthScore $name
    }
    $state.domain_health = $health

    $newAch = Check-Achievements $state
    Save-GamState $state

    return @{
        LeveledUp       = $leveledUp
        NewAchievements = $newAch
        Stats           = Get-StatsLine $state
    }
}
