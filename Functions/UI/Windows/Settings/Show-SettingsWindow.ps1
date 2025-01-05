function Show-SettingsWindow {
    param(
        [System.Windows.Window]$LoginWindow
    )
    try {
        Write-Host "=== Opening Settings Window ==="
        # Get the XAML
        $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\Windows\SettingsWindow.xaml"
        $SettingsXAML = [xml](Get-ProcessedXaml -XamlPath $xamlPath)
        
        # Create window
        $reader = New-Object System.Xml.XmlNodeReader $SettingsXAML
        $settingsWindow = [Windows.Markup.XamlReader]::Load($reader)

        Write-Host "Initializing settings tab..."
        Initialize-SettingsTab -Window $settingsWindow

        # Get controls
        $chkDemoMode = $settingsWindow.FindName("chkDemoMode")
        $chkUseADModule = $settingsWindow.FindName("chkUseADModule")
        $txtDefaultDomain = $settingsWindow.FindName("txtDefaultDomain")
        $txtAutoReplyTemplate = $settingsWindow.FindName("txtAutoReplyTemplate")
        $btnSaveSettings = $settingsWindow.FindName("btnSaveSettings")
        $btnClose = $settingsWindow.FindName("btnClose")
        $txtSettingsStatus = $settingsWindow.FindName("txtSettingsStatus")

        # Load current settings
        #$settings = Get-StoredSettings
        $settings = Get-AppSetting
        
        # Apply settings to UI
        $chkDemoMode.IsChecked = $settings.DemoMode
        $chkUseADModule.IsChecked = $settings.UseADModule

        # Only populate text fields if they have values in settings
        if (![string]::IsNullOrWhiteSpace($settings.DefaultDomain)) {
            $txtDefaultDomain.Text = $settings.DefaultDomain
        }
        
        if (![string]::IsNullOrWhiteSpace($settings.AutoReplyTemplate)) {
            $txtAutoReplyTemplate.Text = $settings.AutoReplyTemplate
        }
        else {
            # Add placeholder text or watermark
            $txtAutoReplyTemplate.Tag = "Enter auto-reply message here..."
        }

        # Add save handler
        $btnSaveSettings.Add_Click({
            try {
                Save-Settings -Window $settingsWindow
                $txtSettingsStatus.Text = "Settings saved successfully!"

                # Update login window controls
                if ($LoginWindow) {
                    $chkLoginDemoMode = $LoginWindow.FindName("chkDemoMode")
                    if ($chkLoginDemoMode) {
                        $chkLoginDemoMode.IsChecked = $chkDemoMode.IsChecked
                    }
                }
            }
            catch {
                $txtSettingsStatus.Text = "Error saving settings: $($_.Exception.Message)"
                Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Settings-Save"
            }
        })

        # Add close handler
        $btnClose.Add_Click({
            $settingsWindow.Close()
        })

        # Show window
        Write-Host "=== Settings Window Initialized ==="
        $settingsWindow.ShowDialog()
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Show-SettingsWindow"
        [System.Windows.MessageBox]::Show(
            "Failed to open settings: $($_.Exception.Message)", 
            "Error", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Error)
    }
}