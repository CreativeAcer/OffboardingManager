function Update-ForwardingUserList {
    try {
        $script:cmbForwardingUser.Items.Clear()
        
        if (Get-AppSetting -SettingName "DemoMode") {
            # Add mock users from demo data
            $mockUsers = Get-MockUsers
            foreach($user in $mockUsers) {
                $script:cmbForwardingUser.Items.Add($user.UserPrincipalName)
            }
        }
        else {
            # Add users from the main list
            if (Get-AppSetting -SettingName "UseADModule") {
                foreach($item in $script:Users) {
                    $script:cmbForwardingUser.Items.Add($item.UserPrincipalName)
                }
            } else {
                foreach($item in $script:Users) {
                    if ($item.Properties["userPrincipalName"]) {
                        $script:cmbForwardingUser.Items.Add($item.Properties["userPrincipalName"][0])
                    }
                }
            }
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-ForwardingList"
    }
}