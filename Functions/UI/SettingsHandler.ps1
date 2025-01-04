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
            Save-Settings -Window $Window
        })
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Settings-TabInit"
    }
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

        # Load current settings
        #$settings = Get-StoredSettings
        $settings = Get-AppSetting
        $settings = @{
            DemoMode = $chkDemoMode.IsChecked
            UseADModule = $chkUseADModule.IsChecked

            # For domain: use input if provided, else keep current, else use system
            DefaultDomain = if (![string]::IsNullOrWhiteSpace($txtDefaultDomain.Text)) {
                $txtDefaultDomain.Text
            } elseif (![string]::IsNullOrWhiteSpace($settings.DefaultDomain)) {
                $settings.DefaultDomain
            } else {
                $env:USERDNSDOMAIN
            }
            
            # For auto reply: use input if provided, else keep current, else use default
            AutoReplyTemplate = if (![string]::IsNullOrWhiteSpace($txtAutoReplyTemplate.Text)) {
                $txtAutoReplyTemplate.Text
            } elseif (![string]::IsNullOrWhiteSpace($settings.AutoReplyTemplate)) {
                $settings.AutoReplyTemplate
            } else {
                "I am currently unavailable..."
            }

            LoggingEnabled = $true
            LogPath = "Logs/error_log.txt"
            LicenseTemplates = Get-AppSetting -SettingName "LicenseTemplates"
        }
        
        # Update settings through Settings.ps1
        Update-AppSettings -NewSettings $settings
        
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