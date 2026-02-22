# First create the icon
& "$PSScriptRoot\create-icon.ps1"

$icoPath = "$env:USERPROFILE\.claude-launcher-icon.ico"
$desktopPath = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktopPath "Claude SC.lnk"
$launcherScript = "\\wsl$\Ubuntu\home\hike-\.claude-launcher\claude-launcher.ps1"

# Remove old .bat if exists
$oldBat = Join-Path $desktopPath "Claude Code.bat"
if (Test-Path $oldBat) { Remove-Item $oldBat -Force }

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcherScript`""
$shortcut.IconLocation = $icoPath
$shortcut.Description = "Claude Code Project Launcher"
$shortcut.WorkingDirectory = "%USERPROFILE%"
$shortcut.WindowStyle = 7  # minimized (hides powershell window)
$shortcut.Save()

Write-Host "Shortcut created at: $shortcutPath"
Write-Host "Done!"
