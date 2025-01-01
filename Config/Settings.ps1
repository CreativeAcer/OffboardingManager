# Global variables
#$script:UseADModule = $false
#$script:Domain = $null
#$script:DomainController = $null

# Initialize script-scope settings variable
$script:AppSettings = $null

function Initialize-AppSettings {
    try {
        # Load settings from JSON
        $settingsPath = Join-Path -Path $script:BasePath -ChildPath "Config\Settings.json"
        if (Test-Path $settingsPath) {
            $script:AppSettings = Get-Content $settingsPath | ConvertFrom-Json
            
            # If domain is empty in settings, use auto-populated value
            if ([string]::IsNullOrEmpty($script:AppSettings.DefaultDomain)) {
                $script:AppSettings.DefaultDomain = $env:USERDNSDOMAIN
            }
        }
        else {
            # Default settings
            $script:AppSettings = @{
                DemoMode = $false
                UseADModule = $false
                Domain = $null
                DomainController = $null
                DefaultDomain = $env:USERDNSDOMAIN
                AutoReplyTemplate = "I am currently unavailable..."
                LoggingEnabled = $true
                LogPath = "Logs/error_log.txt"
                LicenseTemplates = @(
                    @{
                        Name = "Standard User"
                        Products = @("Office 365 E3", "Exchange Online")
                    }
                )
            }
            
            # Save default settings
            $script:AppSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
        }

        # Set global script variables based on settings
        $script:DemoMode = $script:AppSettings.DemoMode
        $script:UseADModule = $script:AppSettings.UseADModule
        $script:Domain = $script:AppSettings.Domain
        $script:DomainController = $script:AppSettings.DomainController
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Initialize-AppSettings"
        throw
    }
}

function Get-AppSetting {
    param (
        [string]$SettingName
    )
    
    if ($null -eq $script:AppSettings) {
        Initialize-AppSettings
    }

    return $script:AppSettings.$SettingName
}

function Update-AppSettings {
    param (
        [hashtable]$NewSettings
    )
    
    try {
        $settingsPath = Join-Path -Path $script:BasePath -ChildPath "Config\Settings.json"
        
        # Update AppSettings object
        foreach ($key in $NewSettings.Keys) {
            $script:AppSettings.$key = $NewSettings[$key]
        }

        # Save to file
        $script:AppSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath

        # Update global script variables
        $script:DemoMode = $script:AppSettings.DemoMode
        $script:UseADModule = $script:AppSettings.UseADModule
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-AppSettings"
        throw
    }
}