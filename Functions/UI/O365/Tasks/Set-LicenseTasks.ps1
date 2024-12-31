function Set-LicenseTasks {
    param (
        [string]$UserEmail,
        [ref]$StateRef,
        [System.Windows.Window]$LoadingWindow
    )
    
    try {
        Update-LoadingMessage -LoadingWindow $LoadingWindow -Message "Updating O365 Licensing..."
        
        $licenseResult = Set-LicenseManagement `
            -UserPrincipalName $UserEmail `
            -ReassignLicenses $StateRef.Value.UIState.CheckboxStates.ReassignLicense `
            -TargetUser $StateRef.Value.UIState.LicenseTarget `
            -DisableProducts $StateRef.Value.UIState.CheckboxStates.DisableProducts `
            -ProductsToDisable $StateRef.Value.UIState.SelectedProducts

        return $licenseResult
    }
    catch {
        return "Error executing license tasks: $($_.Exception.Message)"
    }
}