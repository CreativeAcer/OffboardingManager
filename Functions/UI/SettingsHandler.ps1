function Initialize-SettingsTab {
    param (
        [System.Windows.Window]$Window
    )
    
    try {
        # Get control references
        $script:chkDemoMode = $Window.FindName("chkDemoMode")
        $script:chkUseADModule = $Window.FindName("chkUseADModule")
        $script:txtDefaultDomain = $Window.FindName("txtDefaultDomain")
        $script:txtAutoReplyTemplate = $Window.FindName("txtAutoReplyTemplate")
        $script:btnSaveSettings = $Window.FindName("btnSaveSettings")
        $script:txtSettingsStatus = $Window.FindName("txtSettingsStatus")

        # Load current settings
        $settings = Get-StoredSettings
        
        # Apply settings to UI
        $script:chkDemoMode.IsChecked = $settings.DemoMode
        $script:chkUseADModule.IsChecked = $settings.UseADModule
        $script:txtDefaultDomain.Text = $settings.DefaultDomain
        $script:txtAutoReplyTemplate.Text = $settings.AutoReplyTemplate

        # Add save handler
        $script:btnSaveSettings.Add_Click({
            Save-Settings -Window $Window
        })
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Settings-TabInit"
    }
}

function Get-StoredSettings {
    $settingsPath = Join-Path -Path $script:BasePath -ChildPath "Config\Settings.json"
    
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath | ConvertFrom-Json
        # If domain is empty in settings, use auto-populated value
        if ([string]::IsNullOrEmpty($settings.DefaultDomain)) {
            $settings.DefaultDomain = $env:USERDNSDOMAIN
        }
    }
    else {
        # Default settings
        $settings = @{
            DemoMode = $false
            UseADModule = $true
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
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
    }
    
    return $settings
}

function Save-Settings {
    param (
        [System.Windows.Window]$Window
    )

    try {
        $settingsPath = Join-Path -Path $script:BasePath -ChildPath "Config\Settings.json"
        
        # Match the exact names from your XAML
        $chkDemoMode = $Window.FindName("chkDemoMode")
        $chkUseADModule = $Window.FindName("chkUseADModule")
        $txtDefaultDomain = $Window.FindName("txtDefaultDomain")
        $txtAutoReplyTemplate = $Window.FindName("txtAutoReplyTemplate")  
        $txtSettingsStatus = $Window.FindName("txtSettingsStatus")

        # If domain is empty, use auto-populated value
        $domainValue = if ([string]::IsNullOrWhiteSpace($txtDefaultDomain.Text)) {
            $env:USERDNSDOMAIN
        } else {
            $txtDefaultDomain.Text
        }

        $settings = @{
            DemoMode = $chkDemoMode.IsChecked
            UseADModule = $chkUseADModule.IsChecked
            DefaultDomain = $domainValue
            AutoReplyTemplate = $txtAutoReplyTemplate.Text
            LoggingEnabled = $true
            LogPath = "Logs/activity_log.txt"
            LicenseTemplates = (Get-StoredSettings).LicenseTemplates
        }
        
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
        
        $txtSettingsStatus.Text = "Settings saved successfully at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        # Update application settings
        $script:DemoMode = $settings.DemoMode
        $script:UseADModule = $settings.UseADModule
    }
    catch {
        $script:txtSettingsStatus.Text = "Error saving settings: $($_.Exception.Message)"
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Save-Settings"
    }
}