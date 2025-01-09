# Individual functions for license management operations
function Set-LicenseReassignment {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $true)]
        [string]$TargetUser,
        [Parameter(Mandatory = $false)]
        [bool]$DemoMode = (Get-AppSetting -SettingName "DemoMode")
    )

    try {
        if (-not $TargetUser) {
            throw "Please provide a target user for license reassignment"
        }

        if ($DemoMode) {
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "License Reassignment" -Result "Demo Mode - Target: $TargetUser" -Platform "O365"
            return "[DEMO] Would reassign licenses from $UserPrincipalName to $TargetUser"
        }
        else {
            $results = @()
            # Get user's current licenses
            $userLicenses = Get-MgUserLicenseDetail -UserId $UserPrincipalName
            
            foreach ($license in $userLicenses) {
                # Comment out actual commands
                # Import the required Microsoft Graph modules
                # Import-Module Microsoft.Graph.Users
                # Import-Module Microsoft.Graph.Users.Actions
                # Import-Module Microsoft.Graph.Identity.DirectoryManagement

                # # Connect to Microsoft Graph if not already connected
                # if (!(Get-MgContext)) {
                #     Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
                # }

                # # Assign license to target user and remove from original user
                # try {
                #     # Add license to target user
                #     Set-MgUserLicense -UserId $TargetUser -AddLicenses @{SkuId = $license.SkuId} -RemoveLicenses @()
                #     Write-Host "Successfully assigned license to target user: $TargetUser"

                #     # Remove license from original user
                #     Set-MgUserLicense -UserId $UserPrincipalName -AddLicenses @() -RemoveLicenses @($license.SkuId)
                #     Write-Host "Successfully removed license from original user: $UserPrincipalName"
                # }
                # catch {
                #     Write-Error "Failed to process license transfer: $_"
                # }
                $results += "[SIMULATION] Would transfer license $($license.SkuPartNumber) to $TargetUser"
            }
            
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "License Reassignment" -Result "Simulation - Target: $TargetUser" -Platform "O365"
            return $results -join "`n"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-LicenseReassignment"
        throw "Error reassigning licenses: $($_.Exception.Message)"
    }
}

function Disable-UserProducts {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $true)]
        [string[]]$ProductsToDisable,
        [Parameter(Mandatory = $false)]
        [bool]$DemoMode = (Get-AppSetting -SettingName "DemoMode")
    )

    try {
        if (-not $ProductsToDisable -or $ProductsToDisable.Count -eq 0) {
            throw "Please provide products to disable"
        }

        if ($DemoMode) {
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Product Disable" -Result "Demo Mode - Products: $($ProductsToDisable -join ', ')" -Platform "O365"
            return "[DEMO] Would disable products: $($ProductsToDisable -join ', ')"
        }
        else {
            # Import the required Microsoft Graph modules
            # Import-Module Microsoft.Graph.Users
            # Import-Module Microsoft.Graph.Users.Actions
            # Import-Module Microsoft.Graph.Identity.DirectoryManagement

            # # Connect to Microsoft Graph if not already connected
            # if (!(Get-MgContext)) {
            #     Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
            # }

            # $results = @()

            # # Get current license assignments
            # $userLicenses = Get-MgUserLicenseDetail -UserId $UserPrincipalName
            
            # foreach ($product in $ProductsToDisable) {
            #     try {
            #         $license = $userLicenses | Where-Object { $_.SkuPartNumber -eq $product }
                    
            #         if ($license) {
            #             # Get all service plans to disable
            #             $disabledPlans = $license.ServicePlans | ForEach-Object { $_.ServicePlanId }
                        
            #             # Update license with all plans disabled
            #             Set-MgUserLicense -UserId $UserPrincipalName -AddLicenses @{
            #                 SkuId = $license.SkuId
            #                 DisabledPlans = $disabledPlans
            #             } -RemoveLicenses @()
                        
            #             $results += "Successfully disabled all services for product: $product"
            #             Write-Host "Disabled all services for product: $product"
            #         }
            #         else {
            #             $results += "Product not found in user's licenses: $product"
            #             Write-Warning "Product not found in user's licenses: $product"
            #         }
            #     }
            #     catch {
            #         $results += "Error processing product $product : $_"
            #         Write-Error "Failed to process product $product : $_"
            #     }
            # }
                     
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Product Disable" -Result "Simulation" -Platform "O365"
            return $results -join "`n"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-ProductDisable"
        throw "Error disabling products: $($_.Exception.Message)"
    }
}

# Main orchestrator function
function Set-LicenseManagement {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $false)]
        [bool]$ReassignLicenses,
        [Parameter(Mandatory = $false)]
        [string]$TargetUser,
        [Parameter(Mandatory = $false)]
        [bool]$DisableProducts,
        [Parameter(Mandatory = $false)]
        [string[]]$ProductsToDisable
    )

    try {
        $DemoMode = Get-AppSetting -SettingName "DemoMode"
        $results = @()

        # Handle License Reassignment
        if ($ReassignLicenses) {
            $results += Set-LicenseReassignment -UserPrincipalName $UserPrincipalName -TargetUser $TargetUser -DemoMode $DemoMode
        }

        # Handle Product Disable
        if ($DisableProducts) {
            $results += Disable-UserProducts -UserPrincipalName $UserPrincipalName -ProductsToDisable $ProductsToDisable -DemoMode $DemoMode
        }

        return $results -join "`n"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-LicenseManagement"
        return "Error managing licenses: $($_.Exception.Message)"
    }
}

# Example usage:
# Individual function calls:
# Set-LicenseReassignment -UserPrincipalName "user@domain.com" -TargetUser "newuser@domain.com"
# Disable-UserProducts -UserPrincipalName "user@domain.com" -ProductsToDisable @("Product1", "Product2")

# Main function call:
# Set-LicenseManagement -UserPrincipalName "user@domain.com" -ReassignLicenses $true -TargetUser "newuser@domain.com" -DisableProducts $true -ProductsToDisable @("Product1", "Product2")

function Get-O365Products {
    try {
        if (Get-AppSetting -SettingName "DemoMode") {
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
            if (-not $script:O365Connected) {
                return @("Please connect to O365 first...")
            }
            # Import the required Microsoft Graph module
            Import-Module Microsoft.Graph.Identity.DirectoryManagement

            # Connect to Microsoft Graph if not already connected
            if (!(Get-MgContext)) {
                Connect-MgGraph -Scopes "Directory.Read.All"
            }
            # Get all subscribed SKUs and return their part numbers
            $skus = Get-MgSubscribedSku
            return $skus | Select-Object -ExpandProperty SkuPartNumber
            
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-GetProducts"
        return @("Error retrieving products. Please check connection.")
    }
}