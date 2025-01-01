function Update-SelectedUser {
    param (
        [string]$UserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential
    )
    $loadingWindow = $null
    try {
        $loadingWindow = Show-LoadingScreen -Message "Loading user details..."
        $loadingWindow.Show()
        [System.Windows.Forms.Application]::DoEvents()
        if ($script:DemoMode) {
            $script:SelectedUser = Get-MockUser -UserPrincipalName $UserPrincipalName
        }
        else {
            if ($script:UseADModule) {
                $script:SelectedUser = Get-ADUser -Credential $Credential -Filter "UserPrincipalName -eq '$UserPrincipalName'" -Properties *
            }
            else {
                $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
                $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
                $script:SelectedUser = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
            }
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-SelectedUser"
    }
    finally {
        if ($loadingWindow) {
            $script:mainWindow.Dispatcher.Invoke([Action]{
                $loadingWindow.Close()
            })
        }
    }
    
}