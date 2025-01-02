function Update-LicenseTargetList {
    try {
        $script:cmbLicenseTarget.Items.Clear()
        
        if (Get-AppSettings -SettingName "DemoMode") {
            $mockUsers = Get-MockUsers
            foreach($user in $mockUsers) {
                $script:cmbLicenseTarget.Items.Add($user.UserPrincipalName)
            }
        }
        else {
            foreach($item in $script:lstUsers.Items) {
                $script:cmbLicenseTarget.Items.Add($item)
            }
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-LicenseList"
    }
}

function Initialize-ProductsList {
    try {
        # Clear existing items
        $script:lstProducts.Items.Clear()
        
        # Get and add products
        $products = Get-O365Products
        foreach ($product in $products) {
            $script:lstProducts.Items.Add($product)
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Initialize-ProductsList"
    }
}