function Write-ErrorLog {
    param(
        [string]$ErrorMessage,
        [string]$Location
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] ERROR in $Location`: $ErrorMessage"
    
    # Ensure log directory exists
    $logDir = Join-Path $script:BasePath "Logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }
    
    # Write to log file
    $logFile = Join-Path $logDir "error_log.txt"
    $logMessage | Out-File -FilePath $logFile -Append
    
    # Also write to console
    Write-Host $logMessage -ForegroundColor Red
}