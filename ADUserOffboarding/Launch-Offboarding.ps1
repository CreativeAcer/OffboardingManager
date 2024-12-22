Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Get script paths
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainScript = Join-Path $scriptPath "Start-Offboarding.ps1"

# Launch the main script
Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$mainScript`"" -WindowStyle Hidden

# Exit the launcher
[System.Windows.Forms.Application]::Exit()
