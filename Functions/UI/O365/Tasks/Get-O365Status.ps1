function Get-O365Status {
    param (
        [string]$UserEmail,
        [bool]$DemoMode,
        [System.Windows.Window]$LoadingWindow
    )
    
    try {
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Checking O365 status..."
        
        if ($DemoMode) {
            $o365User = Get-MockO365User -UserPrincipalName $UserEmail
            $statusResults = @(
                "O365 Status for $($o365User.DisplayName) (Demo):",
                "- User Principal Name: $($o365User.UserPrincipalName)",
                "- Email: $($o365User.Mail)",
                "- Account Enabled: $($o365User.AccountEnabled)",
                "- Licenses: Office 365 E5"
            )
        } else {
            $o365User = Get-MgUser -Filter "userPrincipalName eq '$UserEmail'" -Property displayName, userPrincipalName, accountEnabled, mail
            $statusResults = @(
                "O365 Status for $($o365User.DisplayName):",
                "- User Principal Name: $($o365User.UserPrincipalName)",
                "- Email: $($o365User.Mail)",
                "- Account Enabled: $($o365User.AccountEnabled)"
            )
        }
        
        return $statusResults -join "`n"
    }
    catch {
        return "Error retrieving O365 status: $($_.Exception.Message)"
    }
}