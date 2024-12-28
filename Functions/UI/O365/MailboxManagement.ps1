function Set-O365MailboxManagement {
    param (
        [string]$UserPrincipalName,
        [bool]$ConvertToShared,
        [bool]$SetForwarding,
        [string]$ForwardingEmail,
        [bool]$SetAutoReply,
        [string]$AutoReplyMessage
    )

    try {
        if ($script:DemoMode) {
            $results = @()
            
            if ($ConvertToShared) {
                $results += "[DEMO] Would convert mailbox to shared for: $UserPrincipalName"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Convert to Shared Mailbox" -Result "Demo Mode" -Platform "O365"
            }

            if ($SetForwarding) {
                $forwardingUser = $script:cmbForwardingUser.SelectedItem
                if (-not $forwardingUser) {
                    throw "Please select a user to forward emails to"
                }
                $results += "[DEMO] Would set mail forwarding to: $forwardingUser"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Mail Forwarding" -Result "Demo Mode - Forward to: $ForwardingEmail" -Platform "O365" 
            }

            if ($SetAutoReply) {
                $results += "[DEMO] Would set auto-reply message to: $AutoReplyMessage"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Auto-Reply" -Result "Demo Mode" -Platform "O365"
            }

            return $results -join "`n"
        }
        else {
            $results = @()
            
            # Convert to Shared Mailbox
            if ($ConvertToShared) {
                # Comment out actual command for now
                #Set-Mailbox -Identity $UserPrincipalName -Type Shared
                $results += "[SIMULATION] Would convert mailbox to shared"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Convert to Shared Mailbox" -Result "Simulation" -Platform "O365"
            }

            # Set Mail Forwarding
            if ($SetForwarding) {
                # Comment out actual command for now
                #Set-Mailbox -Identity $UserPrincipalName -ForwardingAddress $ForwardingEmail -DeliverToMailboxAndForward $true
                $forwardingUser = $script:cmbForwardingUser.SelectedItem
                if (-not $forwardingUser) {
                    throw "Please select a user to forward emails to"
                }
                else {
                    $results += "[SIMULATION] Would set forwarding to: $forwardingUser"
                    Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Mail Forwarding" -Result "Simulation - Forward to: $ForwardingEmail" -Platform "O365"
                }
            }

            # Set Auto-Reply
            if ($SetAutoReply) {
                # Comment out actual command for now
                #Set-MailboxAutoReplyConfiguration -Identity $UserPrincipalName -AutoReplyState Enabled -InternalMessage $AutoReplyMessage -ExternalMessage $AutoReplyMessage
                $results += "[SIMULATION] Would set auto-reply message to: $AutoReplyMessage"
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Auto-Reply" -Result "Simulation" -Platform "O365"
            }

            return $results -join "`n"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-MailboxManagement"
        return "Error managing mailbox: $($_.Exception.Message)"
    }
}