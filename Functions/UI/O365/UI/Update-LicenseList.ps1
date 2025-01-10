function Update-LicenseTargetList {
    try {
        Write-Host "Starting Update-LicenseTargetList..."
        Write-Host "Users count: $(if ($script:Users) { $script:Users.Count } else { 'null' })"
        
        $script:cmbLicenseTarget.Items.Clear()
        
        if (Get-AppSetting -SettingName "DemoMode") {
            Write-Host "Demo mode detected"
            $mockUsers = Get-MockUsers
            foreach($user in $mockUsers) {
                $script:cmbLicenseTarget.Items.Add($user.UserPrincipalName)
            }
        }
        else {
            Write-Host "Live mode detected"
            if (Get-AppSetting -SettingName "UseADModule") {
                Write-Host "Using AD Module"
                foreach($user in $script:Users) {
                    $script:cmbLicenseTarget.Items.Add($user.UserPrincipalName)
                }
            } else {
                Write-Host "Using LDAP/LDAPS"
                
                if ($null -eq $script:Users) {
                    throw "Users array is null"
                }

                foreach($user in $script:Users) {
                    if ($user.UserPrincipalName) {
                        #Write-Host "Adding UPN: $($user.UserPrincipalName)"
                        $script:cmbLicenseTarget.Items.Add($user.UserPrincipalName)
                    }
                }
            }
        }
        Write-Host "Update-LicenseTargetList completed successfully"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-LicenseList"
        Write-Host "Error details: $($_.Exception.Message)"
        Write-Host "Stack trace: $($_.ScriptStackTrace)"
    }
}