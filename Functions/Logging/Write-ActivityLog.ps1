function Write-ActivityLog {
    param (
        [string]$UserEmail,
        [string]$Action,
        [string]$Result,
        [string]$Platform
    )
    
    try {
        $logPath = Join-Path $script:BasePath "Logs\OffboardingActivities"
        if (-not (Test-Path $logPath)) {
            New-Item -ItemType Directory -Path $logPath | Out-Null
        }
 
        $dateStamp = Get-Date -Format "yyyyMMdd"
        $logFile = Join-Path $logPath "$dateStamp.log"
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logLine = "$timestamp|$UserEmail|$Action|$($Result -replace '\|','/')|$Platform"
        
        Add-Content -Path $logFile -Value $logLine -Encoding UTF8
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Activity-Logging"
    }
 }