# Initialize script-scope settings variable
$script:AppSettings = $null

$settingsTemplate = @{
    DemoMode = $false
    UseADModule = $true
    UseLDAPS = $false
    DefaultDomain = $env:USERDNSDOMAIN
    AutoReplyTemplate = "I am currently unavailable..."
    LoggingEnabled = $true
    LogPath = "Logs/error_log.txt"
    LicenseTemplates = @(
        @{
            Name = "Standard User"
            Products = @(
                "Office 365 E3",
                "Exchange Online"
            )
        },
        @{
            Name = "Power User"
            Products = @(
                "Office 365 E5",
                "Power BI Pro"
            )
        }
    )
    WorkflowConfigurations = @{
        LastUsed = "Default"
        Configurations = @{
            "Default" = @{
                Name = "Default"
                Description = "Standard offboarding workflow"
                EnabledTasks = @()  # Will be populated when tasks are selected
                TaskSettings = @{
                    SetExpiration = @{
                        DaysAfterOffboarding = 30
                    }
                    SetForwarding = @{
                        KeepForwardingDays = 90
                    }
                    SetAutoReply = @{
                        Message = "I am currently unavailable..."
                    }
                }
                LastModified = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }
        }
    }
}

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
            
            # Initialize workflow configurations if they don't exist
            if (-not $script:AppSettings.WorkflowConfigurations) {
                Write-Host "Initializing default workflow configurations"
                $script:AppSettings | Add-Member -NotePropertyName "WorkflowConfigurations" -NotePropertyValue $settingsTemplate.WorkflowConfigurations
            }
        }
        else {
            # Use template for new settings file
            $script:AppSettings = $settingsTemplate
            
            # Save default settings
            $script:AppSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
        }

        # Set global script variables based on settings
        $script:DemoMode = $script:AppSettings.DemoMode
        $script:UseADModule = $script:AppSettings.UseADModule
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

    if ($SettingName) {
        return $script:AppSettings.$SettingName
    }
    return $script:AppSettings
}

function Update-AppSettings {
    param (
        [Parameter(Mandatory=$true)]
        $NewSettings
    )
    
    try {
        # If the $NewSettings is a PSCustomObject, convert it to a hashtable
        if ($NewSettings -is [PSCustomObject]) {
            $NewSettings = @{}  # Start with an empty hashtable
            foreach ($property in $NewSettings.PSObject.Properties) {
                $NewSettings[$property.Name] = $property.Value
            }
        }

        # Validate if $NewSettings is now a hashtable
        if ($NewSettings -isnot [hashtable]) {
            Write-ErrorLog -ErrorMessage "NewSettings must be either a Hashtable or a PSCustomObject." -Location "Update-AppSettings"
            throw
        }

        $settingsPath = Join-Path -Path $script:BasePath -ChildPath "Config\Settings.json"
        
        # Update AppSettings object with new values
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