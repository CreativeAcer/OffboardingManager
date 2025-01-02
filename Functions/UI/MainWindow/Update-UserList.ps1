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
                if (Get-AppSettings -SettingName "DemoMode") {
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
                    if (Get-AppSettings -SettingName "UseADModule") {
                        $Filter = "Enabled -eq '$true' -and LockedOut -eq '$false' -and Mail -like '*'"
                        
                        if ($SearchText) {
                            $Filter = "Enabled -eq '$true' -and LockedOut -eq '$false' -and Mail -like '*' -and UserPrincipalName -like '*$SearchText*'"
                        }
            
                        Write-Host "Using AD Module filter: $Filter"
                        
                        $script:Users = Get-ADUser -Credential $Credential -Filter $Filter -Properties UserPrincipalName |
                                Sort-Object UserPrincipalName
                        
                        $ListBox.Items.Clear()
                        foreach ($User in $script:Users) {
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
                        
                        $script:Users = Get-LDAPUsers -Directory $directory -SearchFilter $filter
                        
                        $ListBox.Items.Clear()
                        foreach ($User in $script:Users) {
                            if ($User.Properties["userPrincipalName"]) {
                                $ListBox.Items.Add($User.Properties["userPrincipalName"][0])
                            }
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