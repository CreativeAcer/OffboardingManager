function Show-MainWindow {
    param (
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        # Show initial loading screen
        $loadingWindow = Show-LoadingScreen -Message "Initializing application..."
        $loadingWindow.Show()

        Write-Host "Loading XAML..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Loading interface components..."
        
        $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\MainWindow.xaml"
        $MainXAML = [xml](Get-ProcessedXaml -XamlPath $xamlPath)
        
        $Reader = New-Object System.Xml.XmlNodeReader $MainXAML
        $MainWindow = [Windows.Markup.XamlReader]::Load($Reader)
        
        Write-Host "Getting main UI elements..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Setting up controls..."
        
        # Get existing elements
        $txtSearch = $MainWindow.FindName("txtSearch")
        $lstUsers = $MainWindow.FindName("lstUsers")
        $txtUserInfo = $MainWindow.FindName("txtUserInfo")

        Write-Host "Initializing OnPrem tab..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Initializing On-Premises components..."
        Initialize-OnPremTab -Window $MainWindow -Credential $Credential

        Write-Host "Initializing O365 tab..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Initializing Office 365 components..."
        Initialize-O365Tab -Window $MainWindow -Credential $Credential

        Write-Host "Setting up event handlers..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Configuring event handlers..."
        
        # Event handlers for main window functionality
        $txtSearch.Add_TextChanged({
            Update-UserList -SearchText $txtSearch.Text -ListBox $lstUsers -Credential $Credential
        })
        
        $lstUsers.Add_SelectionChanged({
            if ($lstUsers.SelectedItem) {
                Update-SelectedUser -UserPrincipalName $lstUsers.SelectedItem -Credential $Credential
                Show-UserDetails -UserPrincipalName $lstUsers.SelectedItem -TextBlock $txtUserInfo -Credential $Credential
            }
        })
        
        Write-Host "Populating initial user list..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Loading user list..."
        Update-UserList -ListBox $lstUsers -Credential $Credential
        
        $MainWindow.WindowStyle = 'SingleBorderWindow'
        $MainWindow.Focusable = $true

        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Ready!"
        Start-Sleep -Milliseconds 500  # Brief pause to show ready message
        
        # Close loading window and show main window
        $loadingWindow.Close()
        
        Write-Host "Showing main window..."
        $MainWindow.Focus()
        $MainWindow.ShowDialog()
    }
    catch {
        if ($loadingWindow) {
            $loadingWindow.Close()
        }
        Write-Error "Error in MainWindow: $_"
        Write-Host "Full exception details:"
        Write-Host $_.Exception.GetType().FullName
        Write-Host $_.Exception.Message
        Write-Host $_.ScriptStackTrace
        
        [System.Windows.MessageBox]::Show(
            "Failed to initialize application: $($_.Exception.Message)", 
            "Error", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Error)
    }
}

function Update-UserList {
    param (
        [System.Windows.Controls.ListBox]$ListBox,
        [System.Management.Automation.PSCredential]$Credential,
        [string]$SearchText = ""
    )
    
    # Show loading indicator in the listbox
    $ListBox.Items.Clear()
    $ListBox.Items.Add("Loading users...")
    $ListBox.IsEnabled = $false
    
    try {
        if ($script:UseADModule) {
            $Filter = "Enabled -eq '$true' -and LockedOut -eq '$false' -and Mail -like '*'"
            
            if ($SearchText) {
                $Filter = "Enabled -eq '$true' -and LockedOut -eq '$false' -and Mail -like '*' -and UserPrincipalName -like '*$SearchText*'"
            }

            Write-Host "Using AD Module filter: $Filter"
            
            $Users = Get-ADUser -Credential $Credential -Filter $Filter -Properties UserPrincipalName |
                    Sort-Object UserPrincipalName
            
            $ListBox.Items.Clear()
            foreach ($User in $Users) {
                $ListBox.Items.Add($User.UserPrincipalName)
            }
        }
        else {
            $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
            $filter = "(&(objectClass=user)(!userAccountControl:1.2.840.113556.1.4.803:=2)(!(userAccountControl:1.2.840.113556.1.4.803:=16))(mail=*))"

            if ($SearchText) {
                $filter = "(&(objectClass=user)(!userAccountControl:1.2.840.113556.1.4.803:=2)(!(userAccountControl:1.2.840.113556.1.4.803:=16))(mail=*)(userPrincipalName=*$SearchText*))"
            }

            Write-Host "Using LDAP filter: $filter"
            
            $Users = Get-LDAPUsers -Directory $directory -SearchFilter $filter
            
            $ListBox.Items.Clear()
            foreach ($User in $Users) {
                if ($User.Properties["userPrincipalName"]) {
                    $ListBox.Items.Add($User.Properties["userPrincipalName"][0])
                }
            }
        }
    }
    catch {
        Write-Error "Failed to update user list: $_"
        $ListBox.Items.Clear()
        $ListBox.Items.Add("Error loading users")
    }
    finally {
        $ListBox.IsEnabled = $true
    }
}

function Update-SelectedUser {
    param (
        [string]$UserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential
    )

    if ($script:UseADModule) {
        $script:SelectedUser = Get-ADUser -Credential $Credential -Filter "UserPrincipalName -eq '$UserPrincipalName'" -Properties *
    }
    else {
        $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
        $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
        $script:SelectedUser = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
    }
}

function Show-UserDetails {
    param (
        [string]$UserPrincipalName,
        [System.Windows.Controls.TextBlock]$TextBlock,
        [System.Management.Automation.PSCredential]$Credential
    )
    
    if ($script:UseADModule) {
        $User = Get-ADUser -Credential $Credential -Filter {UserPrincipalName -eq $UserPrincipalName} -Properties *
        
        $Details = @"
Name: $($User.Name)
User Principal Name: $($User.UserPrincipalName)
Distinguished Name: $($User.DistinguishedName)
Enabled: $($User.Enabled)
Last Logon: $($User.LastLogonDate)
Created: $($User.Created)
Modified: $($User.Modified)
Email: $($User.EmailAddress)
Department: $($User.Department)
Title: $($User.Title)
Manager: $($User.Manager)
Office: $($User.Office)
Phone: $($User.OfficePhone)
Mobile: $($User.MobilePhone)
Account Expires: $($User.AccountExpirationDate)
Password Last Set: $($User.PasswordLastSet)
Password Never Expires: $($User.PasswordNeverExpires)
Account Locked Out: $($User.LockedOut)
Member Of:
$($User.MemberOf | ForEach-Object { "- $_" } | Out-String)
"@
    }
    else {
        $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
        $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
        $User = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
        
        # Convert UAC to enabled status
        $enabled = $true
        if ($User.Properties["userAccountControl"]) {
            $uac = $User.Properties["userAccountControl"][0]
            $enabled = -not [bool]($uac -band 0x2)
        }
        
        $Details = @"
Name: $($User.Properties["displayName"][0])
User Principal Name: $($User.Properties["userPrincipalName"][0])
Distinguished Name: $($User.Properties["distinguishedName"][0])
Enabled: $enabled
Created: $($User.Properties["whenCreated"][0])
Modified: $($User.Properties["whenChanged"][0])
Email: $($User.Properties["mail"][0])
Department: $($User.Properties["department"][0])
Title: $($User.Properties["title"][0])
Manager: $($User.Properties["manager"][0])
Phone: $($User.Properties["telephoneNumber"][0])
Mobile: $($User.Properties["mobile"][0])
Member Of:
$($User.Properties["memberOf"] | ForEach-Object { "- $_" } | Out-String)
"@
    }
    
    $TextBlock.Text = $Details
}