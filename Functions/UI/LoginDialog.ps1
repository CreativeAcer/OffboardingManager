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
    
    $txtDomain.Text = $env:USERDNSDOMAIN
    $txtDC.Text = $env:LOGONSERVER -replace '\\',''
    
    $script:loginSuccess = $false
    
    $btnLogin.Add_Click({
        $script:Domain = $txtDomain.Text
        $script:DomainController = $txtDC.Text
        $script:Username = $txtUsername.Text
        $script:Password = $txtPassword.SecurePassword
        $script:DemoMode = $chkDemoMode.IsChecked
        
        # Skip validation if in demo mode
        if ($script:DemoMode) {
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
    
    $LoginWindow.ShowDialog()
    return $script:loginSuccess
}