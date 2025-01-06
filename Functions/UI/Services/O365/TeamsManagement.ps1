# Individual functions for each Teams/SharePoint operation
function Remove-UserFromTeams {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $false)]
        [bool]$DemoMode = (Get-AppSetting -SettingName "DemoMode")
    )

    try {
        if ($DemoMode) {
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Teams Removal" -Result "Demo Mode" -Platform "O365"
            return "[DEMO] Would remove $UserPrincipalName from all Teams groups"
        }
        else {
            # Get user's Teams memberships
            #$teams = Get-Team -User $UserPrincipalName
            #foreach ($team in $teams) {
            #    Remove-TeamUser -GroupId $team.GroupId -User $UserPrincipalName
            #}
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Teams Removal" -Result "Simulation" -Platform "O365"
            return "[SIMULATION] Would remove user from all Teams groups"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-TeamsRemoval"
        throw "Error removing user from Teams: $($_.Exception.Message)"
    }
}

function Set-TeamsOwnershipTransfer {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $true)]
        [string]$NewOwner,
        [Parameter(Mandatory = $false)]
        [bool]$DemoMode = (Get-AppSetting -SettingName "DemoMode")
    )

    try {
        if (-not $NewOwner) {
            throw "Please provide a new owner for the Teams"
        }

        if ($DemoMode) {
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Teams Ownership Transfer" -Result "Demo Mode - Transfer to: $NewOwner" -Platform "O365"
            return "[DEMO] Would transfer Teams ownership to: $NewOwner"
        }
        else {
            # Get teams where user is owner
            #$ownedTeams = Get-Team -User $UserPrincipalName | Where-Object { 
            #    (Get-TeamUser -GroupId $_.GroupId -Role Owner).User -contains $UserPrincipalName 
            #}
            #foreach ($team in $ownedTeams) {
            #    Add-TeamUser -GroupId $team.GroupId -User $NewOwner -Role Owner
            #    Remove-TeamUser -GroupId $team.GroupId -User $UserPrincipalName
            #}
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Teams Ownership Transfer" -Result "Simulation" -Platform "O365"
            return "[SIMULATION] Would transfer Teams ownership to: $NewOwner"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-TeamsOwnershipTransfer"
        throw "Error transferring Teams ownership: $($_.Exception.Message)"
    }
}

function Remove-SharePointPermissions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $false)]
        [bool]$DemoMode = (Get-AppSetting -SettingName "DemoMode")
    )

    try {
        if ($DemoMode) {
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "SharePoint Permissions Removal" -Result "Demo Mode" -Platform "O365"
            return "[DEMO] Would remove SharePoint permissions"
        }
        else {
            # Get SharePoint sites
            #$sites = Get-SPOSite
            #foreach ($site in $sites) {
            #    Remove-SPOUser -Site $site.Url -LoginName $UserPrincipalName
            #}
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "SharePoint Permissions Removal" -Result "Simulation" -Platform "O365"
            return "[SIMULATION] Would remove SharePoint permissions"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-SharePointPermissionsRemoval"
        throw "Error removing SharePoint permissions: $($_.Exception.Message)"
    }
}

# Main orchestrator function
function Set-TeamsManagement {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $false)]
        [bool]$RemoveFromTeams,
        [Parameter(Mandatory = $false)]
        [bool]$TransferOwnership,
        [Parameter(Mandatory = $false)]
        [string]$NewOwner,
        [Parameter(Mandatory = $false)]
        [bool]$RemoveSharePoint
    )

    try {
        $DemoMode = Get-AppSetting -SettingName "DemoMode"
        $results = @()

        # Handle Teams Removal
        if ($RemoveFromTeams) {
            $results += Remove-UserFromTeams -UserPrincipalName $UserPrincipalName -DemoMode $DemoMode
        }

        # Handle Ownership Transfer
        if ($TransferOwnership) {
            $results += Set-TeamsOwnershipTransfer -UserPrincipalName $UserPrincipalName -NewOwner $NewOwner -DemoMode $DemoMode
        }

        # Handle SharePoint Permissions
        if ($RemoveSharePoint) {
            $results += Remove-SharePointPermissions -UserPrincipalName $UserPrincipalName -DemoMode $DemoMode
        }

        return $results -join "`n"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-TeamsManagement"
        return "Error managing Teams/SharePoint: $($_.Exception.Message)"
    }
}

# Example usage:
# Individual function calls:
# Remove-UserFromTeams -UserPrincipalName "user@domain.com"
# Set-TeamsOwnershipTransfer -UserPrincipalName "user@domain.com" -NewOwner "newowner@domain.com"
# Remove-SharePointPermissions -UserPrincipalName "user@domain.com"

# Main function call:
# Set-TeamsManagement -UserPrincipalName "user@domain.com" -RemoveFromTeams $true -TransferOwnership $true -NewOwner "newowner@domain.com" -RemoveSharePoint $true