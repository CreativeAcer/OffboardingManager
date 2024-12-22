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
    $btnLogin = $LoginWindow.FindName("btnLogin")
    
    $txtDomain.Text = $env:USERDNSDOMAIN
    $txtDC.Text = $env:LOGONSERVER -replace '\\',''
    
    $btnLogin.Add_Click({
        $script:Domain = $txtDomain.Text
        $script:DomainController = $txtDC.Text
        $script:Username = $txtUsername.Text
        $script:Password = $txtPassword.SecurePassword
        
        try {
            $Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)
            
            if ($script:UseADModule) {
                # Test connection using AD module
                Get-ADUser -Credential $Credential -Filter * -ResultSetSize 1 | Out-Null
            }
            else {
                # Test connection using LDAP
                $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
                if ($directory.Name -eq $null) {
                    throw "Failed to connect to LDAP"
                }
            }
            
            $LoginWindow.DialogResult = $true
            $LoginWindow.Close()
        }
        catch {
            [System.Windows.MessageBox]::Show(
                "Login failed. Please check your credentials and domain controller.", 
                "Error", 
                [System.Windows.MessageBoxButton]::OK, 
                [System.Windows.MessageBoxImage]::Error)
        }
    })
    
    $LoginWindow.ShowDialog()
}