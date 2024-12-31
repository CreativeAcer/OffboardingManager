function Set-MailboxTasks {
    param (
        [string]$UserEmail,
        [ref]$StateRef,
        [System.Windows.Window]$LoadingWindow
    )
    
    try {
        Update-LoadingMessage -LoadingWindow $LoadingWindow -Message "Updating O365 Mailbox..."
        
        $mailboxResult = Set-O365MailboxManagement `
            -UserPrincipalName $UserEmail `
            -ConvertToShared $StateRef.Value.UIState.CheckboxStates.ConvertShared `
            -SetForwarding $StateRef.Value.UIState.CheckboxStates.SetForwarding `
            -ForwardingEmail $StateRef.Value.UIState.ForwardingEmail `
            -SetAutoReply $StateRef.Value.UIState.CheckboxStates.AutoReply `
            -AutoReplyMessage $StateRef.Value.UIState.AutoReplyMessage
        
        return $mailboxResult
    }
    catch {
        return "Error executing mailbox tasks: $($_.Exception.Message)"
    }
}