function Update-ForwardingUserList {
    try {
        Write-Host "Starting Update-ForwardingUserList..."
        Write-Host "Users count: $(if ($script:Users) { $script:Users.Count } else { 'null' })"
        
        $script:cmbForwardingUser.Items.Clear()
        
        if (Get-AppSetting -SettingName "DemoMode") {
            Write-Host "Demo mode detected"
            $mockUsers = Get-MockUsers
            foreach($user in $mockUsers) {
                $script:cmbForwardingUser.Items.Add($user.UserPrincipalName)
            }
        }
        else {
            Write-Host "Live mode detected"
            if (Get-AppSetting -SettingName "UseADModule") {
                Write-Host "Using AD Module"
                foreach($user in $script:Users) {
                    $script:cmbForwardingUser.Items.Add($user.UserPrincipalName)
                }
            } else {
                Write-Host "Using LDAP/LDAPS"
                
                if ($null -eq $script:Users) {
                    throw "Users array is null"
                }

                foreach($user in $script:Users) {
                    if ($user.UserPrincipalName) {
                        Write-Host "Adding UPN: $($user.UserPrincipalName)"
                        $script:cmbForwardingUser.Items.Add($user.UserPrincipalName)
                    }
                }
            }
        }
        Write-Host "Update-ForwardingUserList completed successfully"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-ForwardingList"
        Write-Host "Error details: $($_.Exception.Message)"
        Write-Host "Stack trace: $($_.ScriptStackTrace)"
    }
}