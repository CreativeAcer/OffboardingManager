# Functions/Workflow/WorkflowTasks.ps1
$script:WorkflowTasks = @{
    OnPrem = @(
        @{
            Id = "DisableAccount"
            DisplayName = "Disable Account"
            Description = "Disables the user's AD account"
            FunctionName = "Disable-ADAccount"  # Direct function reference
            Platform = "OnPrem"
            RequiredParams = @("UserPrincipalName", "Credential")
            OptionalParams = @()
        }
        @{
            Id = "RemoveGroups"
            DisplayName = "Remove Group Memberships"
            Description = "Removes user from all AD groups"
            FunctionName = "Remove-UserGroups"
            Platform = "OnPrem"
            RequiredParams = @("UserPrincipalName", "Credential")
            OptionalParams = @()
        }
        @{
            Id = "MoveToDisabledOU"
            DisplayName = "Move to Disabled OU"
            Description = "Moves user account to disabled users OU"
            FunctionName = "Move-UserToDisabledOU"
            Platform = "OnPrem"
            RequiredParams = @("UserPrincipalName", "Credential")
            OptionalParams = @()
        }
        @{
            Id = "SetExpiration"
            DisplayName = "Set Account Expiration"
            Description = "Sets an expiration date for the account"
            FunctionName = "Set-AccountExpiration"
            Platform = "OnPrem"
            RequiredParams = @("UserPrincipalName", "Credential", "ExpirationDate")
            OptionalParams = @()
        }
    )
    O365 = @(
        @{
            Id = "ConvertMailbox"
            DisplayName = "Convert to Shared Mailbox"
            Description = "Converts user mailbox to shared mailbox"
            FunctionName = "Convert-ToSharedMailbox"
            Platform = "O365"
            RequiredParams = @("UserPrincipalName")
            OptionalParams = @()
        }
        @{
            Id = "SetForwarding"
            DisplayName = "Set Mail Forwarding"
            Description = "Sets up email forwarding"
            FunctionName = "Set-MailForwarding"
            Platform = "O365"
            RequiredParams = @("UserPrincipalName", "ForwardingAddress")
            OptionalParams = @()
        }
        @{
            Id = "SetAutoReply"
            DisplayName = "Set Auto-Reply"
            Description = "Configures automatic reply message"
            FunctionName = "Set-AutoReplyMessage"
            Platform = "O365"
            RequiredParams = @("UserPrincipalName", "Message")
            OptionalParams = @()
        }
    )
}