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
            #Set-Mailbox -Identity $UserPrincipalName -Type Shared
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
            #Set-Mailbox -Identity $UserPrincipalName -ForwardingAddress $ForwardingEmail -DeliverToMailboxAndForward $true
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
            #Set-MailboxAutoReplyConfiguration -Identity $UserPrincipalName -AutoReplyState Enabled -InternalMessage $AutoReplyMessage -ExternalMessage $AutoReplyMessage
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