param(
    [string]$Title = "Gaia",
    [string]$Body  = ""
)

# Windows balloon tip — Windows 11 renders these as modern toasts.
# Works with PowerShell 5.1 (no WinRT dependency).
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Application
    $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $notify.BalloonTipTitle = $Title
    $notify.BalloonTipText = $Body
    $notify.Visible = $true
    $notify.ShowBalloonTip(10000)

    # Must keep process alive long enough for the toast to render
    Start-Sleep -Seconds 3
    $notify.Dispose()
} catch {
    Write-Host "Toast notification failed: $_"
}
