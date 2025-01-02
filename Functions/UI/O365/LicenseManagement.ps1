function Set-LicenseManagement {
    param (
        [string]$UserPrincipalName,
        [bool]$ReassignLicenses,
        [string]$TargetUser,
        [bool]$DisableProducts,
        [string[]]$ProductsToDisable
    )

    try {
        if (Get-AppSettings -SettingName "DemoMode") {
            $results = @()
            
            if ($ReassignLicenses) {
                $results += "[DEMO] Would reassign licenses from $UserPrincipalName to $TargetUser"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "License Reassignment" -Result "Demo Mode - Target: $TargetUser" -Platform "O365"
            }

            if ($DisableProducts) {
                $results += "[DEMO] Would disable products: $($ProductsToDisable -join ', ')"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Product Disable" -Result "Demo Mode - Products: $($ProductsToDisable -join ', ')" -Platform "O365"
            }

            return $results -join "`n"
        }
        else {
            $results = @()
            
            if ($ReassignLicenses) {
                # Get user's current licenses
                $userLicenses = Get-MgUserLicenseDetail -UserId $UserPrincipalName
                
                foreach ($license in $userLicenses) {
                    # Comment out actual commands
                    #Set-MgUserLicense -UserId $TargetUser -AddLicenses @{SkuId = $license.SkuId} -RemoveLicenses @()
                    #Set-MgUserLicense -UserId $UserPrincipalName -AddLicenses @() -RemoveLicenses @($license.SkuId)
                    $results += "[SIMULATION] Would transfer license $($license.SkuPartNumber) to $TargetUser"
                }
                
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "License Reassignment" -Result "Simulation - Target: $TargetUser" -Platform "O365"
            }

            if ($DisableProducts) {
                # Get current license assignments
                $userLicenses = Get-MgUserLicenseDetail -UserId $UserPrincipalName
                
                foreach ($product in $ProductsToDisable) {
                    # Comment out actual commands
                    #$license = $userLicenses | Where-Object { $_.SkuPartNumber -eq $product }
                    #if ($license) {
                    #    $disabledPlans = $license.ServicePlans | ForEach-Object { $_.ServicePlanId }
                    #    Set-MgUserLicense -UserId $UserPrincipalName -AddLicenses @{
                    #        SkuId = $license.SkuId
                    #        DisabledPlans = $disabledPlans
                    #    } -RemoveLicenses @()
                    #}
                    $results += "[SIMULATION] Would disable product: $product"
                }
                
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Product Disable" -Result "Simulation" -Platform "O365"
            }

            return $results -join "`n"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-LicenseManagement"
        return "Error managing licenses: $($_.Exception.Message)"
    }
}

function Get-O365Products {
    try {
        if (Get-AppSettings -SettingName "DemoMode") {
            return @(
                "ENTERPRISEPACK",           # Office 365 E3
                "ENTERPRISEPREMIUM",        # Office 365 E5
                "EXCHANGESTANDARD",         # Exchange Online Plan 1
                "EXCHANGEENTERPRISE",       # Exchange Online Plan 2
                "SHAREPOINTSTANDARD",       # SharePoint Online Plan 1
                "SHAREPOINTENTERPRISE",     # SharePoint Online Plan 2
                "TEAMS1",                   # Microsoft Teams
                "PROJECTPREMIUM",           # Project Online Premium
                "VISIOONLINE_PLAN1"         # Visio Online Plan 1
            )
        }
        else {
            $skus = Get-MgSubscribedSku
            return $skus | Select-Object -ExpandProperty SkuPartNumber
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-GetProducts"
        return @()
    }
}