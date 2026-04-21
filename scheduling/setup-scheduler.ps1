# Gaia Scheduling Layer v2 — Windows Task Scheduler Setup
#
# Registers automated Gaia tasks as Windows Scheduled Tasks.
# Run from PowerShell (Admin not required for current-user tasks):
#   .\scheduling\setup-scheduler.ps1
#
# To remove all tasks:  .\scheduling\setup-scheduler.ps1 -Remove
# To list task status:  .\scheduling\setup-scheduler.ps1 -Status

param(
    [switch]$Remove,
    [switch]$Status
)

$ErrorActionPreference = "Stop"

$GaiaDir  = "C:\GitHub\Gaia"
$BashExe  = "C:\Program Files\Git\bin\bash.exe"
$Runner   = "$GaiaDir\scheduling\run-task.sh"

# Task definitions: Name, TaskName (schedule label), Model, Budget, Trigger
# Type: "claude" (default) runs via run-task.sh + claude -p
#        "script" runs a PowerShell script directly (no API cost)
$Tasks = @(
    @{
        Name        = "morning-plan"
        TaskName    = "Gaia - Morning Plan"
        Description = "Generate today's plan with usage-aware work queue"
        Model       = "sonnet"
        Budget      = "2.00"
        Trigger     = New-ScheduledTaskTrigger -Daily -At 07:00
    },
    @{
        Name        = "evening-reflect"
        TaskName    = "Gaia - Evening Reflect"
        Description = "Compare today's plan vs actual, flag carry-forwards, update journal"
        Model       = "sonnet"
        Budget      = "2.00"
        Trigger     = New-ScheduledTaskTrigger -Daily -At 21:00
    },
    @{
        Name        = "weekly-review"
        TaskName    = "Gaia - Weekly Review"
        Description = "Compile the week's activity into a weekly review"
        Model       = "opus"
        Budget      = "5.00"
        Trigger     = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 10:00
    },
    @{
        Name        = "gap-tracker"
        TaskName    = "Gaia - Gap Tracker"
        Description = "Track progress against Anthropic application gaps"
        Model       = "sonnet"
        Budget      = "3.00"
        Trigger     = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 08:30
    },
    @{
        Name        = "micro-commit"
        TaskName    = "Gaia - Micro-Commitment"
        Description = "Break #1 priority into a 5-minute starter task"
        Model       = "haiku"
        Budget      = "0.50"
        Trigger     = New-ScheduledTaskTrigger -Daily -At 07:15
    },
    @{
        Name        = "noon-check"
        TaskName    = "Gaia - Noon Check"
        Description = "Accountability check - has the top priority been touched?"
        Model       = "haiku"
        Budget      = "0.50"
        Trigger     = New-ScheduledTaskTrigger -Daily -At 12:00
    },
    @{
        Name        = "git-scraper-morning"
        TaskName    = "Gaia - Git Scraper (Morning)"
        Description = "Scan manifest repos for new commits, update domain activity"
        Type        = "script"
        Script      = "$GaiaDir\scheduling\scripts\git-scraper.ps1"
        Trigger     = New-ScheduledTaskTrigger -Daily -At 08:30
    },
    @{
        Name        = "git-scraper-evening"
        TaskName    = "Gaia - Git Scraper (Evening)"
        Description = "Scan manifest repos for new commits, update domain activity"
        Type        = "script"
        Script      = "$GaiaDir\scheduling\scripts\git-scraper.ps1"
        Trigger     = New-ScheduledTaskTrigger -Daily -At 20:30
    }
)

# --- Status mode ---
if ($Status) {
    Write-Host "`nGaia Scheduled Tasks Status:" -ForegroundColor Cyan
    Write-Host ("=" * 60)
    foreach ($task in $Tasks) {
        $existing = Get-ScheduledTask -TaskName $task.TaskName -ErrorAction SilentlyContinue
        if ($existing) {
            $info = Get-ScheduledTaskInfo -TaskName $task.TaskName
            Write-Host "`n  $($task.TaskName)" -ForegroundColor Green
            Write-Host "    State:    $($existing.State)"
            Write-Host "    Last Run: $($info.LastRunTime)"
            Write-Host "    Result:   $($info.LastTaskResult)"
            Write-Host "    Next Run: $($info.NextRunTime)"
        } else {
            Write-Host "`n  $($task.TaskName)" -ForegroundColor Yellow
            Write-Host "    NOT REGISTERED"
        }
    }
    Write-Host ""
    exit 0
}

# --- Remove mode ---
if ($Remove) {
    Write-Host "`nRemoving Gaia Scheduled Tasks..." -ForegroundColor Yellow
    foreach ($task in $Tasks) {
        $existing = Get-ScheduledTask -TaskName $task.TaskName -ErrorAction SilentlyContinue
        if ($existing) {
            Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
            Write-Host "  Removed: $($task.TaskName)" -ForegroundColor Red
        } else {
            Write-Host "  Not found: $($task.TaskName)" -ForegroundColor DarkGray
        }
    }
    Write-Host "Done.`n"
    exit 0
}

# --- Register mode (default) ---
Write-Host "`nRegistering Gaia Scheduled Tasks..." -ForegroundColor Cyan
Write-Host "  Bash:   $BashExe"
Write-Host "  Runner: $Runner"
Write-Host ""

# Verify prerequisites
if (-not (Test-Path $BashExe)) {
    Write-Error "Git Bash not found at $BashExe. Install Git for Windows or update the path."
}
if (-not (Test-Path $Runner)) {
    Write-Error "Task runner not found at $Runner. Ensure the Gaia repo is set up."
}

$Settings = New-ScheduledTaskSettingsSet `
    -WakeToRun `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 15) `
    -Hidden

# Use wscript to run bash hidden (no visible console window)
$VBSWrapper = "$GaiaDir\scheduling\run-hidden.vbs"

foreach ($task in $Tasks) {
    $taskType = if ($task.Type) { $task.Type } else { "claude" }

    if ($taskType -eq "script") {
        # Script tasks run PowerShell directly (no Claude API cost)
        $action = New-ScheduledTaskAction `
            -Execute "powershell.exe" `
            -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$($task.Script)`"" `
            -WorkingDirectory $GaiaDir
    } else {
        # Claude tasks run via bash + run-task.sh + claude -p
        $bashArgs = "-l `"$Runner`" $($task.Name) $($task.Model) $($task.Budget)"
        $action = New-ScheduledTaskAction `
            -Execute "wscript.exe" `
            -Argument "`"$VBSWrapper`" `"$BashExe`" $bashArgs" `
            -WorkingDirectory $GaiaDir
    }

    # Remove existing task if present (idempotent)
    $existing = Get-ScheduledTask -TaskName $task.TaskName -ErrorAction SilentlyContinue
    if ($existing) {
        Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
    }

    Register-ScheduledTask `
        -TaskName $task.TaskName `
        -Action $action `
        -Trigger $task.Trigger `
        -Settings $Settings `
        -Description $task.Description

    Write-Host "  Registered: $($task.TaskName)" -ForegroundColor Green
    if ($taskType -eq "script") {
        Write-Host "    Command: powershell -File `"$($task.Script)`""
    } else {
        Write-Host "    Command: bash -l `"$Runner`" $($task.Name) $($task.Model) $($task.Budget)"
    }
    Write-Host "    Trigger: $($task.Trigger.ToString())"
    Write-Host ""
}

Write-Host "All tasks registered. Run with -Status to verify." -ForegroundColor Cyan
Write-Host "Logs will be written to: $GaiaDir\scheduling\logs\" -ForegroundColor DarkGray
Write-Host ""
