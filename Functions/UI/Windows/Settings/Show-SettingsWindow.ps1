function Show-SettingsWindow {
    param(
        [System.Windows.Window]$LoginWindow
    )
    try {
        Write-Host "=== Opening Settings Window ==="
        
        # Store window reference at script level
        $script:settingsWindow = $null
        
        # Get the XAML
        $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\Windows\SettingsWindow.xaml"
        Write-Host "XAML Path: $xamlPath"
        
        $settingsXAML = [xml](Get-ProcessedXaml -XamlPath $xamlPath)
        Write-Host "XAML loaded successfully"
        
        # Create window
        $reader = New-Object System.Xml.XmlNodeReader $settingsXAML
        $script:settingsWindow = [Windows.Markup.XamlReader]::Load($reader)
        $reader.Close()
        
        if ($null -eq $script:settingsWindow) {
            throw "Failed to create settings window - window is null after loading"
        }
        Write-Host "Settings window created successfully"

        # Set window properties
        $script:settingsWindow.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
        if ($LoginWindow) {
            $script:settingsWindow.Owner = $LoginWindow
        }

        Write-Host "settingsWindow type: $($script:settingsWindow.GetType().FullName)"
        # Initialize settings tab
        Initialize-SettingsTab -Window $script:settingsWindow -LoginWindow $LoginWindow
        Write-Host "Settings tab initialized"

        # Verify critical controls exist
        $controlList = @(
            "chkDemoMode", "chkUseADModule", "txtDefaultDomain", 
            "txtAutoReplyTemplate", "btnSaveSettings", "chkUseLDAPS",
            "btnClose", "txtSettingsStatus"
        )

        foreach ($controlName in $controlList) {
            $control = $script:settingsWindow.FindName($controlName)
            Write-Host "Control '$controlName' exists: $($null -ne $control)"
            if ($null -eq $control) {
                throw "Required control '$controlName' not found in XAML"
            }
        }

        Write-Host "=== Settings Window Ready for Display ==="
        
        # Show the window
        if ($script:settingsWindow) {
            $script:settingsWindow.ShowDialog()
        }
        else {
            throw "Settings window is null before showing dialog"
        }
    }
    catch {
        $errorMessage = "Error in Show-SettingsWindow: $($_.Exception.Message)"
        Write-Host $errorMessage
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Show-SettingsWindow"
        [System.Windows.MessageBox]::Show(
            "Failed to open settings: $($_.Exception.Message)", 
            "Error", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Error)
    }
    finally {
        # Cleanup
        if ($script:settingsWindow) {
            $script:settingsWindow = $null
        }
    }
}