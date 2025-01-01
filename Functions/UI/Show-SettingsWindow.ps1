function Show-SettingsWindow {
    param(
        [System.Windows.Window]$LoginWindow
    )
    try {
        # Get the XAML
        $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\SettingsWindow.xaml"
        $SettingsXAML = [xml](Get-ProcessedXaml -XamlPath $xamlPath)
        
        # Create window
        $reader = New-Object System.Xml.XmlNodeReader $SettingsXAML
        $settingsWindow = [Windows.Markup.XamlReader]::Load($reader)

        # Get controls
        $chkDemoMode = $settingsWindow.FindName("chkDemoMode")
        $chkUseADModule = $settingsWindow.FindName("chkUseADModule")
        $txtDefaultDomain = $settingsWindow.FindName("txtDefaultDomain")
        $txtAutoReplyTemplate = $settingsWindow.FindName("txtAutoReplyTemplate")
        $btnSaveSettings = $settingsWindow.FindName("btnSaveSettings")
        $btnClose = $settingsWindow.FindName("btnClose")
        $txtSettingsStatus = $settingsWindow.FindName("txtSettingsStatus")

        # Load current settings
        $settings = Get-StoredSettings
        
        # Apply settings to UI
        $chkDemoMode.IsChecked = $settings.DemoMode
        $chkUseADModule.IsChecked = $settings.UseADModule
        $txtDefaultDomain.Text = $settings.DefaultDomain
        $txtAutoReplyTemplate.Text = $settings.AutoReplyTemplate

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