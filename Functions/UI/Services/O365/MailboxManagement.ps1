# Individual functions for each mailbox operation
function Convert-ToSharedMailbox {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $false)]
        [bool]$DemoMode = (Get-AppSetting -SettingName "DemoMode")
    )

    try {
        if ($DemoMode) {
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Convert to Shared Mailbox" -Result "Demo Mode" -Platform "O365"
            return "[DEMO] Would convert mailbox to shared for: $UserPrincipalName"
        }
        else {
            # Comment out actual command for now
            # Import the required Microsoft Graph module
            # Import-Module Microsoft.Graph.Users

            # # Connect to Microsoft Graph if not already connected
            # if (!(Get-MgContext)) {
            #     Connect-MgGraph -Scopes "User.ReadWrite.All"
            # }

            # # Parameters for converting the mailbox to shared
            # $params = @{
            #     AccountEnabled = $false
            #     MailboxSettings = @{
            #         MessagePayloadRestricted = $true
            #     }
            # }

            # # Convert user mailbox to shared
            # try {
            #     Update-MgUser -UserId $UserPrincipalName -BodyParameter $params
            #     Write-Host "Successfully converted mailbox to shared for user: $UserPrincipalName"
            # }
            # catch {
            #     Write-Error "Failed to convert mailbox to shared: $_"
            # }
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Convert to Shared Mailbox" -Result "Simulation" -Platform "O365"
            return "[SIMULATION] Would convert mailbox to shared"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-ConvertToSharedMailbox"
        throw "Error converting mailbox to shared: $($_.Exception.Message)"
    }
}

function Set-MailboxForwarding {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $true)]
        [string]$ForwardingEmail,
        [Parameter(Mandatory = $false)]
        [bool]$DemoMode = (Get-AppSetting -SettingName "DemoMode")
    )

    try {
        if (-not $ForwardingEmail) {
            throw "Please provide an email address to forward to"
        }

        if ($DemoMode) {
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Mail Forwarding" -Result "Demo Mode - Forward to: $ForwardingEmail" -Platform "O365"
            return "[DEMO] Would set mail forwarding to: $ForwardingEmail"
        }
        else {
            # Comment out actual command for now
            # Import the required Microsoft Graph module
            # Import-Module Microsoft.Graph.Users

            # # Connect to Microsoft Graph if not already connected
            # if (!(Get-MgContext)) {
            #     Connect-MgGraph -Scopes "User.ReadWrite.All"
            # }

            # # Parameters for setting up email forwarding
            # $params = @{
            #     MailboxSettings = @{
            #         AutomaticRepliesSetting = @{
            #             ExternalReplyMessage = ""
            #             InternalReplyMessage = ""
            #         }
            #         ForwardingSettings = @{
            #             ForwardingSmtpAddress = $ForwardingEmail
            #             ForwardingEnabled = $true
            #             KeepCopy = $true  # This is equivalent to DeliverToMailboxAndForward
            #         }
            #     }
            # }

            # # Set up email forwarding
            # try {
            #     Update-MgUser -UserId $UserPrincipalName -BodyParameter $params
            #     Write-Host "Successfully set up email forwarding for user: $UserPrincipalName to: $ForwardingEmail"
            # }
            # catch {
            #     Write-Error "Failed to set up email forwarding: $_"
            # }
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Mail Forwarding" -Result "Simulation - Forward to: $ForwardingEmail" -Platform "O365"
            return "[SIMULATION] Would set forwarding to: $ForwardingEmail"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-SetMailboxForwarding"
        throw "Error setting mailbox forwarding: $($_.Exception.Message)"
    }
}

function Set-MailboxAutoReply {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $true)]
        [string]$AutoReplyMessage,
        [Parameter(Mandatory = $false)]
        [bool]$DemoMode = (Get-AppSetting -SettingName "DemoMode")
    )

    try {
        if (-not $AutoReplyMessage) {
            throw "Please provide an auto-reply message"
        }

        if ($DemoMode) {
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Auto-Reply" -Result "Demo Mode" -Platform "O365"
            return "[DEMO] Would set auto-reply message to: $AutoReplyMessage"
        }
        else {
            # Comment out actual command for now
            # Import the required Microsoft Graph module
            # Import-Module Microsoft.Graph.Users

            # # Connect to Microsoft Graph if not already connected
            # if (!(Get-MgContext)) {
            #     Connect-MgGraph -Scopes "User.ReadWrite.All"
            # }

            # # Parameters for setting up auto-reply
            # $params = @{
            #     MailboxSettings = @{
            #         AutomaticRepliesSetting = @{
            #             Status = "AlwaysEnabled"  # Equivalent to AutoReplyState Enabled
            #             ExternalReplyMessage = $AutoReplyMessage
            #             InternalReplyMessage = $AutoReplyMessage
            #             ScheduledStartDateTime = $null
            #             ScheduledEndDateTime = $null
            #             ExternalAudience = "All"  # Replies to all external senders
            #         }
            #     }
            # }

            # # Set up auto-reply
            # try {
            #     Update-MgUser -UserId $UserPrincipalName -BodyParameter $params
            #     Write-Host "Successfully configured auto-reply for user: $UserPrincipalName"
            # }
            # catch {
            #     Write-Error "Failed to configure auto-reply: $_"
            # }
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Auto-Reply" -Result "Simulation" -Platform "O365"
            return "[SIMULATION] Would set auto-reply message to: $AutoReplyMessage"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-SetMailboxAutoReply"
        throw "Error setting mailbox auto-reply: $($_.Exception.Message)"
    }
}

# Main orchestrator function
function Set-O365MailboxManagement {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $false)]
        [bool]$ConvertToShared,
        [Parameter(Mandatory = $false)]
        [bool]$SetForwarding,
        [Parameter(Mandatory = $false)]
        [string]$ForwardingEmail,
        [Parameter(Mandatory = $false)]
        [bool]$SetAutoReply,
        [Parameter(Mandatory = $false)]
        [string]$AutoReplyMessage
    )

    try {
        $DemoMode = Get-AppSetting -SettingName "DemoMode"
        $results = @()

        # Handle Convert to Shared
        if ($ConvertToShared) {
            $results += Convert-ToSharedMailbox -UserPrincipalName $UserPrincipalName -DemoMode $DemoMode
        }

        # Handle Forwarding
        if ($SetForwarding) {
            $results += Set-MailboxForwarding -UserPrincipalName $UserPrincipalName -ForwardingEmail $ForwardingEmail -DemoMode $DemoMode
        }

        # Handle Auto-Reply
        if ($SetAutoReply) {
            $results += Set-MailboxAutoReply -UserPrincipalName $UserPrincipalName -AutoReplyMessage $AutoReplyMessage -DemoMode $DemoMode
        }

        return $results -join "`n"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-MailboxManagement"
        return "Error managing mailbox: $($_.Exception.Message)"
    }
}

# Example usage:
# Individual function calls:
# Convert-ToSharedMailbox -UserPrincipalName "user@domain.com"
# Set-MailboxForwarding -UserPrincipalName "user@domain.com" -ForwardingEmail "forward@domain.com"
# Set-MailboxAutoReply -UserPrincipalName "user@domain.com" -AutoReplyMessage "I am out of office"

# Main function call:
# Set-O365MailboxManagement -UserPrincipalName "user@domain.com" -ConvertToShared $true -SetForwarding $true -ForwardingEmail "forward@domain.com" -SetAutoReply $true -AutoReplyMessage "Out of office"