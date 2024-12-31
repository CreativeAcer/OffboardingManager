function Set-TeamsTasks {
    param (
        [string]$UserEmail,
        [ref]$StateRef,
        [System.Windows.Window]$LoadingWindow
    )
    
    try {
        Update-LoadingMessage -LoadingWindow $LoadingWindow -Message "Updating O365 Teams..."
        
        $teamsResult = Set-TeamsManagement `
            -UserPrincipalName $UserEmail `
            -RemoveFromTeams $StateRef.Value.UIState.CheckboxStates.RemoveTeams `
            -TransferOwnership $StateRef.Value.UIState.CheckboxStates.TransferTeams `
            -NewOwner $StateRef.Value.UIState.TeamsOwner `
            -RemoveSharePoint $StateRef.Value.UIState.CheckboxStates.RemoveSharePoint
        
        return $teamsResult
    }
    catch {
        return "Error executing Teams tasks: $($_.Exception.Message)"
    }
}