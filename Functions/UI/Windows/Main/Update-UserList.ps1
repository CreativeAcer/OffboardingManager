function Update-UserList {
    param (
        [System.Windows.Controls.ListBox]$ListBox,
        [System.Management.Automation.PSCredential]$Credential,
        [string]$SearchText = ""
    )
    $loadingWindow = $null
    
    try {
        # Show loading window for initial load only (when SearchText is empty)
        if ([string]::IsNullOrEmpty($SearchText)) {
            $loadingWindow = Show-LoadingScreen -Message "Loading users..."
            $loadingWindow.Show()
            [System.Windows.Forms.Application]::DoEvents()
        }

        $script:mainWindow.Dispatcher.Invoke([Action]{
            try {
                # Show loading indicator in the listbox
                $ListBox.Items.Clear()
                $ListBox.Items.Add("Loading users...")
                $ListBox.IsEnabled = $false

                if (Get-AppSetting -SettingName "DemoMode") {
                    Write-Host "Demo mode: Loading mock users..."
                    $script:Users = Get-MockUsers
                    if ($SearchText) {
                        $script:Users = $script:Users | Where-Object { 
                            $_.UserPrincipalName -like "*$SearchText*" -or 
                            $_.DisplayName -like "*$SearchText*" 
                        }
                    }
                    
                    $ListBox.Items.Clear()
                    foreach ($User in $script:Users) {
                        $ListBox.Items.Add($User.UserPrincipalName)
                    }
                }
                else {
                    if (Get-AppSetting -SettingName "UseADModule") {
                        Write-Host "Using AD Module for user lookup..."
                        try {
                            $searchFilter = "*"
                            if ($SearchText) {
                                $searchFilter = "*$SearchText*"
                            }

                            $script:Users = Get-ADModuleUsers -Credential $Credential -SearchFilter $searchFilter -DomainController $script:DomainController

                            $ListBox.Items.Clear()
                            foreach ($User in $script:Users) {
                                $ListBox.Items.Add($User.UserPrincipalName)
                            }
                        }
                        catch {
                            Write-Host "Failed to update user list using AD Module: $_"
                            throw
                        }
                    }
                    else {
                        try {
                            Write-Host "Using LDAP/LDAPS for user lookup..."
                            $useLDAPS = Get-AppSetting -SettingName "UseLDAPS"
                            $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential -UseLDAPS $useLDAPS
                            
                            # Build the LDAP filter
                            $filter = "(&(objectClass=user)(!userAccountControl:1.2.840.113556.1.4.803:=2)(!(userAccountControl:1.2.840.113556.1.4.803:=16))(mail=*))"
                            
                            if ($SearchText) {
                                $filter = "(&(objectClass=user)(!userAccountControl:1.2.840.113556.1.4.803:=2)(!(userAccountControl:1.2.840.113556.1.4.803:=16))(mail=*)(userPrincipalName=*$SearchText*))"
                            }
                        
                            Write-Host "Using filter: $filter"
                            Write-Host "Connection type: $(if ($useLDAPS) { 'LDAPS' } else { 'LDAP' })"
                            
                            # Get raw users from LDAP/LDAPS
                            $rawUsers = Get-LDAPUsers -Directory $directory -SearchFilter $filter
                            Write-Host "Retrieved $(if ($rawUsers) { $rawUsers.Count } else { '0' }) users"
                            
                            # Convert users to a consistent format
                            $script:Users = @()
                            foreach ($user in $rawUsers) {
                                if ($directory.IsLDAPS) {
                                    # Handle System.DirectoryServices.Protocols response
                                    if ($user.Attributes["userPrincipalName"]) {
                                        $convertedUser = @{
                                            UserPrincipalName = $user.Attributes["userPrincipalName"][0]
                                            DisplayName = if ($user.Attributes["displayName"]) { $user.Attributes["displayName"][0] } else { "" }
                                            Email = if ($user.Attributes["mail"]) { $user.Attributes["mail"][0] } else { "" }
                                            Department = if ($user.Attributes["department"]) { $user.Attributes["department"][0] } else { "" }
                                            Title = if ($user.Attributes["title"]) { $user.Attributes["title"][0] } else { "" }
                                            Attributes = $user.Attributes
                                            IsLDAPS = $true
                                        }
                                        $script:Users += $convertedUser
                                    }
                                }
                                else {
                                    # Handle standard DirectorySearcher response
                                    if ($user.Properties["userPrincipalName"]) {
                                        $convertedUser = @{
                                            UserPrincipalName = $user.Properties["userPrincipalName"][0]
                                            DisplayName = if ($user.Properties["displayName"]) { $user.Properties["displayName"][0] } else { "" }
                                            Email = if ($user.Properties["mail"]) { $user.Properties["mail"][0] } else { "" }
                                            Department = if ($user.Properties["department"]) { $user.Properties["department"][0] } else { "" }
                                            Title = if ($user.Properties["title"]) { $user.Properties["title"][0] } else { "" }
                                            Properties = $user.Properties
                                            IsLDAPS = $false
                                        }
                                        $script:Users += $convertedUser
                                    }
                                }
                            }
                            
                            Write-Host "Converted $(if ($script:Users) { $script:Users.Count } else { '0' }) users to normalized format"
                            
                            # Update ListBox with normalized user data
                            $ListBox.Items.Clear()
                            foreach ($user in $script:Users) {
                                $ListBox.Items.Add($user.UserPrincipalName)
                            }
                        }
                        catch {
                            Write-Host "Failed to update user list: $($_.Exception.Message)"
                            throw
                        }
                        finally {
                            if ($directory -and $directory.Connection) {
                                try {
                                    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($directory.Connection)
                                }
                                catch {
                                    Write-Host "Warning: Connection cleanup error: $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                }

                # Update O365 dropdowns if necessary
                if ($script:Users -and $script:txtO365Results) {
                    Write-Host "Updating O365 dropdowns with $(if ($script:Users) { $script:Users.Count } else { '0' }) users"
                    Update-O365Dropdowns
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
        })
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-UserList"
    }
    finally {
        if ($loadingWindow) {
            $script:mainWindow.Dispatcher.Invoke([Action]{
                $loadingWindow.Close()
            })
        }
    }    
}