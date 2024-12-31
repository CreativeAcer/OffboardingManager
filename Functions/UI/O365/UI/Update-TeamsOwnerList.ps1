function Update-TeamsOwnerList {
    try {
        $script:cmbTeamsOwner.Items.Clear()
        
        if ($script:DemoMode) {
            $mockUsers = Get-MockUsers
            foreach($user in $mockUsers) {
                $script:cmbTeamsOwner.Items.Add($user.UserPrincipalName)
            }
        }
        else {
            if ($script:UseADModule) {
                foreach($item in $script:Users) {
                    $script:cmbTeamsOwner.Items.Add($item.UserPrincipalName)
                }
            } else {
                foreach($item in $script:Users) {
                    if ($item.Properties["userPrincipalName"]) {
                        $script:cmbTeamsOwner.Items.Add($item.Properties["userPrincipalName"][0])
                    }
                }
            }
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-TeamsOwnerList"
    }
}