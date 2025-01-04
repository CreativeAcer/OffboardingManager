function Show-LoginDialog {
    # Use the global base path
    $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\LoginWindow.xaml"
    $LoginXAML = [xml](Get-ProcessedXaml -XamlPath $xamlPath)
    
    $Reader = New-Object System.Xml.XmlNodeReader $LoginXAML
    $LoginWindow = [Windows.Markup.XamlReader]::Load($Reader)
    
    $txtDomain = $LoginWindow.FindName("txtDomain")
    $txtDC = $LoginWindow.FindName("txtDC")
    $txtUsername = $LoginWindow.FindName("txtUsername")
    $txtPassword = $LoginWindow.FindName("txtPassword")
    $chkDemoMode = $LoginWindow.FindName("chkDemoMode")
    $btnLogin = $LoginWindow.FindName("btnLogin")

    # Get settings button and add click handler
    $btnSettings = $loginWindow.FindName("btnSettings")
    $btnSettings.Add_Click({
        Show-SettingsWindow -LoginWindow $loginWindow
    })
    
    $txtDomain.Text = $env:USERDNSDOMAIN
    $txtDC.Text = $env:LOGONSERVER -replace '\\',''
    
    $script:loginSuccess = $false

    # Load current settings and apply them
    #$settings = Get-StoredSettings
    $settings = Get-AppSetting
    if ($settings) {
        $script:DemoMode = $settings.DemoMode
        $chkDemoMode.IsChecked = $settings.DemoMode
        if ($settings.DefaultDomain) {
            $txtDomain.Text = $settings.DefaultDomain
        }
    }

    # Window closing handler ('X' pressed)
    $LoginWindow.Add_Closing({
        param($sender, $e)
        if ($LoginWindow.DialogResult -ne $true) {
            $script:loginSuccess = $false
            $LoginWindow.DialogResult = $false
        }
    })
    
    $btnLogin.Add_Click({
        $script:Domain = $txtDomain.Text
        $script:DomainController = $txtDC.Text
        $script:Username = $txtUsername.Text
        $script:Password = $txtPassword.SecurePassword
        $script:DemoMode = $chkDemoMode.IsChecked
        
        # Skip validation if in demo mode
        if ($script:DemoMode) {
            $script:loginSuccess = $true 
            $LoginWindow.DialogResult = $true
            $LoginWindow.Close()
            return
        }
        
        try {
            $Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)
            
            # Create and show loading window first
            $loadingWindow = Show-LoadingScreen -Message "Validating credentials..."
            $loadingWindow.Owner = $LoginWindow
            $loadingWindow.WindowStartupLocation = "CenterOwner"
            $loadingWindow.Show()
            
            # Now hide the login window
            $LoginWindow.Hide()
            
            # Use dispatcher to allow UI to update
            $LoginWindow.Dispatcher.Invoke([Action]{
                try {
                    if ($script:UseADModule) {
                        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Connecting to Active Directory..."
                        Get-ADUser -Credential $Credential -Filter * -ResultSetSize 1 | Out-Null
                    }
                    else {
                        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Establishing LDAP connection..."
                        $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
                        if ($directory.Name -eq $null) {
                            throw "Failed to connect to LDAP"
                        }
                    }

                    Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Connection successful..."
                    Start-Sleep -Milliseconds 500

                    $script:loginSuccess = $true
                    $LoginWindow.DialogResult = $true
                    
                    # Clean up windows
                    if ($loadingWindow.IsVisible) {
                        $loadingWindow.Close()
                    }
                    $LoginWindow.Close()
                }
                catch {
                    Write-Host "Connection error: $_"
                    if ($loadingWindow.IsVisible) {
                        $loadingWindow.Close()
                    }
                    $LoginWindow.Show()
                    [System.Windows.MessageBox]::Show(
                        "Login failed. Please check your credentials and domain controller.", 
                        "Error", 
                        [System.Windows.MessageBoxButton]::OK, 
                        [System.Windows.MessageBoxImage]::Error)
                }
            }, [System.Windows.Threading.DispatcherPriority]::Background)
        }
        catch {
            Write-Host "Login error: $_"
            [System.Windows.MessageBox]::Show(
                "Login failed. Please check your credentials and domain controller.", 
                "Error", 
                [System.Windows.MessageBoxButton]::OK, 
                [System.Windows.MessageBoxImage]::Error)
        }
    })
    
    $result = $LoginWindow.ShowDialog()
    return ($result -eq $true -and $script:loginSuccess)
}