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

    # Pump messages so the OS delivers the balloon tip event
    for ($i = 0; $i -lt 30; $i++) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }
    $notify.Dispose()
} catch {
    Write-Host "Toast notification failed: $_"
}
