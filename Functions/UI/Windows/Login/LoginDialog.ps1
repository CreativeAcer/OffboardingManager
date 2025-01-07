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
            # Normal credential creation
            # Format username correctly for AD authentication
            $formattedUsername = if ($script:Username.Contains('\') -or $script:Username.Contains('@')) {
                $script:Username
            } else {
                "$script:Domain\$script:Username"
            }
            
            $Credential = New-Object System.Management.Automation.PSCredential ($formattedUsername, $script:Password)
            # # Construct full username with domain
            # $fullUsername = "$($script:Domain)\$($script:Username)"
            Write-Host "Attempting login with username: $formattedUsername"
            
            # # Create credential object
            # $Credential = New-Object System.Management.Automation.PSCredential($fullUsername, $script:Password)

            $loadingWindow = Show-LoadingScreen -Message "Validating credentials..."
            $loadingWindow.Owner = $LoginWindow
            $loadingWindow.WindowStartupLocation = "CenterOwner"
            $loadingWindow.Show()

            Write-Host "Using UseADModule: $(Get-AppSetting -SettingName "UseADModule")"
            if(Get-AppSetting -SettingName "UseADModule"){
                try {
                    # Use Get-ADAuthentication for authentication
                    $directory = Get-ADAuthentication -DomainController $script:DomainController -Credential $Credential
                    
                    Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Connection successful..."
                    Start-Sleep -Milliseconds 500

                    $script:loginSuccess = $true
                    $loadingWindow.Close()
                    $LoginWindow.Close()
                }
                catch {
                    Write-Host "Authentication error: $($_.Exception.Message)"
                    $loadingWindow.Close()
                    [System.Windows.MessageBox]::Show(
                        "Login failed: $($_.Exception.Message)`nPlease check your credentials and domain controller.", 
                        "Authentication Error", 
                        [System.Windows.MessageBoxButton]::OK, 
                        [System.Windows.MessageBoxImage]::Error)
                }
            } else {
                try {
                    # Use Get-LDAPConnection for authentication
                    $useLDAPS = Get-AppSetting -SettingName "UseLDAPS"
                    $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential -UseLDAPS $useLDAPS
                    
                    Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Connection successful..."
                    Start-Sleep -Milliseconds 500

                    $script:loginSuccess = $true
                    $loadingWindow.Close()
                    $LoginWindow.Close()
                }
                catch {
                    Write-Host "Authentication error: $($_.Exception.Message)"
                    $loadingWindow.Close()
                    [System.Windows.MessageBox]::Show(
                        "Login failed: $($_.Exception.Message)`nPlease check your credentials and domain controller.", 
                        "Authentication Error", 
                        [System.Windows.MessageBoxButton]::OK, 
                        [System.Windows.MessageBoxImage]::Error)
                }
            }
            
        }
        catch {
            Write-Host "Login error: $_"
            if ($null -ne $loadingWindow) {
                $loadingWindow.Close()
            }
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