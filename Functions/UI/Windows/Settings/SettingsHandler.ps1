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

        # Initialize workflow settings
        Write-Host "Initializing workflow settings tab..."
        Initialize-WorkflowSettingsTab -Window $Window

        # Load current settings
        $settings = Get-AppSetting
        if ($settings) {
            $script:chkDemoMode.IsChecked = $settings.DemoMode
            $script:chkUseADModule.IsChecked = $settings.UseADModule
            $script:txtDefaultDomain.Text = $settings.DefaultDomain
            $script:txtAutoReplyTemplate.Text = $settings.AutoReplyTemplate
        }

        Write-Host "Settings Tab initialization completed"e

        # Add save handler
        $script:btnSaveSettings.Add_Click({
            Save-Settings -Window $Window -LoginWindow $LoginWindow
        })
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Settings-TabInit"
    }
}

function Save-Settings {
    param (
        [System.Windows.Window]$Window,
        [System.Windows.Window]$LoginWindow  # Add LoginWindow parameter
    )

    try {
        # Get controls and validate
        $chkDemoMode = $Window.FindName("chkDemoMode")
        $chkUseADModule = $Window.FindName("chkUseADModule")
        $txtDefaultDomain = $Window.FindName("txtDefaultDomain")
        $txtAutoReplyTemplate = $Window.FindName("txtAutoReplyTemplate")  
        $txtSettingsStatus = $Window.FindName("txtSettingsStatus")

        # Get current settings
        $currentSettings = Get-AppSetting

        # Build new settings
        $settings = @{
            DemoMode = $chkDemoMode.IsChecked
            UseADModule = $chkUseADModule.IsChecked
            DefaultDomain = if (![string]::IsNullOrWhiteSpace($txtDefaultDomain.Text)) {
                $txtDefaultDomain.Text
            } else {
                $env:USERDNSDOMAIN
            }
            AutoReplyTemplate = if (![string]::IsNullOrWhiteSpace($txtAutoReplyTemplate.Text)) {
                $txtAutoReplyTemplate.Text
            } elseif (![string]::IsNullOrWhiteSpace($currentSettings.AutoReplyTemplate)) {
                $currentSettings.AutoReplyTemplate
            } else {
                "I am currently unavailable..."
            }
            LoggingEnabled = $true
            LogPath = "Logs/error_log.txt"
            LicenseTemplates = $currentSettings.LicenseTemplates
            WorkflowConfigurations = $currentSettings.WorkflowConfigurations
        }
        
        # Update settings
        Update-AppSettings -NewSettings $settings

        # Update Login window if available
        if ($null -ne $LoginWindow) {
            $loginDomain = $LoginWindow.FindName("txtDomain")
            $loginDemoMode = $LoginWindow.FindName("chkDemoMode")
            if ($null -ne $loginDomain) {
                $loginDomain.Text = $settings.DefaultDomain
            }
            if ($null -ne $loginDemoMode) {
                $loginDemoMode.IsChecked = $settings.DemoMode
            }
        }
        
        if ($null -ne $txtSettingsStatus) {
            $txtSettingsStatus.Text = "Settings saved successfully at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        }
        
        # Update application settings
        $script:DemoMode = $settings.DemoMode
        $script:UseADModule = $settings.UseADModule
    }
    catch {
        if ($null -ne $txtSettingsStatus) {
            $txtSettingsStatus.Text = "Error saving settings: $($_.Exception.Message)"
        }
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Save-Settings"
    }
}