function Update-LicenseTargetList {
    try {
        $script:cmbLicenseTarget.Items.Clear()
        
        if (Get-AppSetting -SettingName "DemoMode") {
            $mockUsers = Get-MockUsers
            foreach($user in $mockUsers) {
                $script:cmbLicenseTarget.Items.Add($user.UserPrincipalName)
            }
        }
        else {
            foreach($item in $script:Users) {
                if ($item.Properties["userPrincipalName"]) {
                    $script:cmbLicenseTarget.Items.Add($item.Properties["userPrincipalName"][0])
                }
            }
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-LicenseList"
    }
}