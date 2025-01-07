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
                        Write-Host "Using AD Module filter: $baseFilter"
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
                            Write-Host "Failed to update user list: $_"
                            throw
                        }
                    }
                    else {
                        try {
                            $useLDAPS = Get-AppSetting -SettingName "UseLDAPS"
                            $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential -UseLDAPS $useLDAPS
                            
                            $filter = "(&(objectClass=user)(!userAccountControl:1.2.840.113556.1.4.803:=2)(!(userAccountControl:1.2.840.113556.1.4.803:=16))(mail=*))"
                            
                            if ($SearchText) {
                                $filter = "(&(objectClass=user)(!userAccountControl:1.2.840.113556.1.4.803:=2)(!(userAccountControl:1.2.840.113556.1.4.803:=16))(mail=*)(userPrincipalName=*$SearchText*))"
                            }
                        
                            Write-Host "Using LDAPS filter: $filter"
                            
                            $script:Users = Get-LDAPUsers -Directory $directory -SearchFilter $filter
                            
                            $ListBox.Items.Clear()
                            foreach ($User in $script:Users) {
                                if ($directory.IsLDAPS) {
                                    # Handle System.DirectoryServices.Protocols response
                                    $attributes = $User.Attributes
                                    if ($attributes["userPrincipalName"]) {
                                        $ListBox.Items.Add($attributes["userPrincipalName"][0])
                                    }
                                }
                                else {
                                    # Handle standard DirectorySearcher response
                                    if ($User.Properties["userPrincipalName"]) {
                                        $ListBox.Items.Add($User.Properties["userPrincipalName"][0])
                                    }
                                }
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
                if ($script:txtO365Results) {  # Check if O365 tab is initialized
                    Write-Host "Updating O365 dropdowns after user list update..."
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