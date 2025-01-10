function Filter-UserList {
    param (
        [System.Windows.Controls.ListBox]$ListBox,
        [string]$SearchText = ""
    )
    
    try {
        $script:mainWindow.Dispatcher.Invoke([Action]{
            try {
                # Show loading indicator
                $ListBox.Items.Clear()
                $ListBox.Items.Add("Filtering users...")
                $ListBox.IsEnabled = $false

                if ([string]::IsNullOrEmpty($SearchText)) {
                    # If search is cleared, show all users from $script:Users
                    $ListBox.Items.Clear()
                    foreach ($User in $script:Users) {
                        $ListBox.Items.Add($User.UserPrincipalName)
                    }
                }
                else {
                    # Filter existing users based on search text
                    $filteredUsers = $script:Users | Where-Object { 
                        $_.UserPrincipalName -like "*$SearchText*" -or 
                        $_.DisplayName -like "*$SearchText*" 
                    }
                    
                    $ListBox.Items.Clear()
                    foreach ($User in $filteredUsers) {
                        $ListBox.Items.Add($User.UserPrincipalName)
                    }
                }

                # Update O365 dropdowns if necessary
                if ($script:txtO365Results) {
                    Write-Host "Updating O365 dropdowns with filtered users"
                    Update-O365Dropdowns
                }
            }
            catch {
                Write-Error "Failed to filter user list: $_"
                $ListBox.Items.Clear()
                $ListBox.Items.Add("Error filtering users")
            }
            finally {
                $ListBox.IsEnabled = $true
            }
        })
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Filter-UserList"
    }
}