function Set-TeamsManagement {
    param (
        [string]$UserPrincipalName,
        [bool]$RemoveFromTeams,
        [bool]$TransferOwnership,
        [string]$NewOwner,
        [bool]$RemoveSharePoint
    )

    try {
        if (Get-AppSetting -SettingName "DemoMode") {
            $results = @()
            
            if ($RemoveFromTeams) {
                $results += "[DEMO] Would remove $UserPrincipalName from all Teams groups"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Teams Removal" -Result "Demo Mode" -Platform "O365"
            }

            if ($TransferOwnership) {
                $results += "[DEMO] Would transfer Teams ownership to: $NewOwner"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Teams Ownership Transfer" -Result "Demo Mode - Transfer to: $NewOwner" -Platform "O365"
            }

            if ($RemoveSharePoint) {
                $results += "[DEMO] Would remove SharePoint permissions"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "SharePoint Permissions Removal" -Result "Demo Mode" -Platform "O365"
            }

            return $results -join "`n"
        }
        else {
            $results = @()
            
            # Remove from Teams groups
            if ($RemoveFromTeams) {
                # Get user's Teams memberships
                #$teams = Get-Team -User $UserPrincipalName
                #foreach ($team in $teams) {
                #    Remove-TeamUser -GroupId $team.GroupId -User $UserPrincipalName
                #}
                $results += "[SIMULATION] Would remove user from all Teams groups"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Teams Removal" -Result "Simulation" -Platform "O365"
            }

            # Transfer Teams ownership
            if ($TransferOwnership) {
                # Get teams where user is owner
                #$ownedTeams = Get-Team -User $UserPrincipalName | Where-Object { 
                #    (Get-TeamUser -GroupId $_.GroupId -Role Owner).User -contains $UserPrincipalName 
                #}
                #foreach ($team in $ownedTeams) {
                #    Add-TeamUser -GroupId $team.GroupId -User $NewOwner -Role Owner
                #    Remove-TeamUser -GroupId $team.GroupId -User $UserPrincipalName
                #}
                $results += "[SIMULATION] Would transfer Teams ownership to: $NewOwner"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Teams Ownership Transfer" -Result "Simulation" -Platform "O365"
            }

            # Remove SharePoint permissions
            if ($RemoveSharePoint) {
                # Get SharePoint sites
                #$sites = Get-SPOSite
                #foreach ($site in $sites) {
                #    Remove-SPOUser -Site $site.Url -LoginName $UserPrincipalName
                #}
                $results += "[SIMULATION] Would remove SharePoint permissions"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "SharePoint Permissions Removal" -Result "Simulation" -Platform "O365"
            }

            return $results -join "`n"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-TeamsManagement"
        return "Error managing Teams/SharePoint: $($_.Exception.Message)"
    }
}