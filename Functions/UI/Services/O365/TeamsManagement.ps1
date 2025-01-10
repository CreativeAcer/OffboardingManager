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
            # Import the required Microsoft Graph modules
            # Import-Module Microsoft.Graph.Teams
            # Import-Module Microsoft.Graph.Groups

            # # Connect to Microsoft Graph if not already connected
            # if (!(Get-MgContext)) {
            #     Connect-MgGraph -Scopes "Team.ReadWrite.All", "User.Read.All", "Group.ReadWrite.All"
            # }

            # # Get all teams the user is a member of
            # $teams = Get-MgUserJoinedTeam -UserId $UserPrincipalName

            # # Remove user from each team
            # foreach ($team in $teams) {
            #     try {
            #         # Get the user's membership ID
            #         $membershipId = (Get-MgTeamMember -TeamId $team.Id | 
            #             Where-Object { $_.UserId -eq $UserPrincipalName }).Id
                    
            #         if ($membershipId) {
            #             # Remove the user from the team
            #             Remove-MgTeamMember -TeamId $team.Id -ConversationMemberId $membershipId
            #             Write-Host "Removed user from team: $($team.DisplayName)"
            #         }
            #     }
            #     catch {
            #         Write-Warning "Failed to remove user from team $($team.DisplayName): $_"
            #     }
            # }
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
            # Import the required Microsoft Graph modules
            # Import-Module Microsoft.Graph.Teams
            # Import-Module Microsoft.Graph.Groups

            # # Connect to Microsoft Graph if not already connected
            # if (!(Get-MgContext)) {
            #     Connect-MgGraph -Scopes "Team.ReadWrite.All", "User.Read.All", "Group.ReadWrite.All"
            # }

            # # Get teams owned by the user
            # $ownedTeams = Get-MgUserJoinedTeam -UserId $UserPrincipalName | Where-Object {
            #     (Get-MgTeamMember -TeamId $_.Id | Where-Object Role -eq 'owner').UserId -contains $UserPrincipalName
            # }

            # # Transfer ownership for each team
            # foreach ($team in $ownedTeams) {
            #     # Add new owner
            #     $params = @{
            #         "@odata.type" = "#microsoft.graph.aadUserConversationMember"
            #         Roles = @("owner")
            #         UserId = $NewOwner
            #     }
            #     New-MgTeamMember -TeamId $team.Id -BodyParameter $params

            #     # Remove old owner
            #     $oldOwnerMemberId = (Get-MgTeamMember -TeamId $team.Id | 
            #         Where-Object { $_.UserId -eq $UserPrincipalName }).Id
            #     Remove-MgTeamMember -TeamId $team.Id -ConversationMemberId $oldOwnerMemberId
            # }
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
            # # Import the required Microsoft Graph module
            # Import-Module Microsoft.Graph.Sites
            # # Connect to Microsoft Graph if not already connected
            # if (!(Get-MgContext)) {
            #     Connect-MgGraph -Scopes "Sites.FullControl.All", "Directory.Read.All"
            # }

            # # Get all SharePoint sites
            # $sites = Get-MgSite -All

            # # Remove user from each site
            # foreach ($site in $sites) {
            #     try {
            #         # Get the user's site permissions
            #         $siteUsers = Get-MgSitePermission -SiteId $site.Id
                    
            #         # Find the user's permission ID
            #         $userPermission = $siteUsers | Where-Object { 
            #             $_.Roles.AdditionalProperties.value.userPrincipalName -eq $UserPrincipalName 
            #         }
                    
            #         if ($userPermission) {
            #             # Remove the user's permission
            #             Remove-MgSitePermission -SiteId $site.Id -PermissionId $userPermission.Id
            #             Write-Host "Removed user from site: $($site.WebUrl)"
            #         }
            #     }
            #     catch {
            #         Write-Warning "Failed to process site $($site.WebUrl): $_"
            #     }
            # }
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