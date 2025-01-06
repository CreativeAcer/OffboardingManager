function Show-LoginDialog {
    # Use the global base path
    $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\Windows\LoginWindow.xaml"
    $LoginXAML = [xml](Get-ProcessedXaml -XamlPath $xamlPath)
    
    $Reader = New-Object System.Xml.XmlNodeReader $LoginXAML
    $LoginWindow = [Windows.Markup.XamlReader]::Load($Reader)
    
    $txtDomain = $LoginWindow.FindName("txtDomain")
    $txtDC = $LoginWindow.FindName("txtDC")
    $txtUsername = $LoginWindow.FindName("txtUsername")
    $txtPassword = $LoginWindow.FindName("txtPassword")
    $chkDemoMode = $LoginWindow.FindName("chkDemoMode")
    $btnLogin = $LoginWindow.FindName("btnLogin")

    $btnSettings = $loginWindow.FindName("btnSettings")
    $btnSettings.Add_Click({
        Show-SettingsWindow -LoginWindow $loginWindow
    })
    
    $txtDomain.Text = $env:USERDNSDOMAIN
    $txtDC.Text = $env:LOGONSERVER -replace '\\',''
    
    $script:loginSuccess = $false

    $settings = Get-AppSetting
    if ($settings) {
        $script:DemoMode = $settings.DemoMode
        $chkDemoMode.IsChecked = $settings.DemoMode
        if ($settings.DefaultDomain) {
            $txtDomain.Text = $settings.DefaultDomain
        }
    }

    $LoginWindow.Add_Closing({
        param($sender, $e)
        if (-not $script:loginSuccess) {
            $script:loginSuccess = $false
        }
    })
    
    $btnLogin.Add_Click({
        try {
            # Get values from form
            $script:Domain = $txtDomain.Text.Trim()
            $script:DomainController = $txtDC.Text.Trim()
            $script:Username = $txtUsername.Text.Trim()
            $script:Password = $txtPassword.SecurePassword
            $script:DemoMode = $chkDemoMode.IsChecked

            if (Get-AppSetting -SettingName "DemoMode") {
                $script:loginSuccess = $true 
                $LoginWindow.Close()
                return
            }
            # Validate input fields
            if ([string]::IsNullOrWhiteSpace($script:Username) -or 
                [string]::IsNullOrWhiteSpace($script:DomainController) -or 
                [string]::IsNullOrWhiteSpace($script:Domain)) {
                throw "Please fill in all required fields"
            }

            # Construct full username with domain
            $fullUsername = "$($script:Domain)\$($script:Username)"
            Write-Host "Attempting login with username: $fullUsername"
            
            # Create credential object
            $Credential = New-Object System.Management.Automation.PSCredential($fullUsername, $script:Password)
            
            $loadingWindow = Show-LoadingScreen -Message "Validating credentials..."
            $loadingWindow.Owner = $LoginWindow
            $loadingWindow.WindowStartupLocation = "CenterOwner"
            $loadingWindow.Show()

            # Create authentication block
            $authBlock = {
                try {
                    Write-Host "Using LDAP for authentication..."
                    Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Establishing LDAP connection..."
                    
                    $networkCred = $Credential.GetNetworkCredential()
                    $ldapPath = "LDAP://$($script:DomainController)"
                    
                    Write-Host "Creating directory entry with path: $ldapPath"
                    Write-Host "Username: $($networkCred.UserName)"
                    Write-Host "Domain: $($networkCred.Domain)"
                    
                    $authType = [System.DirectoryServices.AuthenticationTypes]::Secure -bor 
                               [System.DirectoryServices.AuthenticationTypes]::Sealing -bor 
                               [System.DirectoryServices.AuthenticationTypes]::Signing
                    
                    $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry(
                        $ldapPath,
                        $networkCred.UserName,
                        $networkCred.Password,
                        $authType
                    )
                    
                    Write-Host "Directory entry created, testing connection..."
                    if ($null -eq $directoryEntry) {
                        throw "Failed to create directory entry"
                    }
                    
                    # Test connection
                    $null = $directoryEntry.RefreshCache()
                    
                    Write-Host "Creating directory searcher..."
                    $searcher = New-Object System.DirectoryServices.DirectorySearcher
                    $searcher.SearchRoot = $directoryEntry
                    $searcher.Filter = "(sAMAccountName=$($script:Username))"
                    
                    Write-Host "Performing search..."
                    $result = $searcher.FindOne()
                    
                    if ($null -eq $result) {
                        throw "User not found in directory"
                    }

                    Write-Host "Authentication successful"
                    Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Connection successful..."
                    Start-Sleep -Milliseconds 500

                    $script:loginSuccess = $true
                    
                    $loadingWindow.Dispatcher.Invoke({ $loadingWindow.Close() })
                    $LoginWindow.Dispatcher.Invoke({ $LoginWindow.Close() })
                }
                catch {
                    Write-Host "Authentication error details: $($_.Exception.Message)"
                    Write-Host "Stack trace: $($_.ScriptStackTrace)"
                    
                    $loadingWindow.Dispatcher.Invoke({ 
                        $loadingWindow.Close()
                        [System.Windows.MessageBox]::Show(
                            "Login failed: $($_.Exception.Message)`nPlease check your credentials and domain controller.", 
                            "Authentication Error", 
                            [System.Windows.MessageBoxButton]::OK, 
                            [System.Windows.MessageBoxImage]::Error)
                    })
                }
            }

            # Execute authentication on dispatcher
            $LoginWindow.Dispatcher.Invoke($authBlock, [System.Windows.Threading.DispatcherPriority]::Normal)
        }
        catch {
            Write-Host "Login error: $_"
            [System.Windows.MessageBox]::Show(
                "Login failed: $($_.Exception.Message)", 
                "Error", 
                [System.Windows.MessageBoxButton]::OK, 
                [System.Windows.MessageBoxImage]::Error)
        }
    })
    
    $LoginWindow.ShowDialog() | Out-Null
    return $script:loginSuccess
}