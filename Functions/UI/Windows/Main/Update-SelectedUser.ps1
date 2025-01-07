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
        if (Get-AppSetting -SettingName "DemoMode") {
            $script:SelectedUser = Get-MockUser -UserPrincipalName $UserPrincipalName
        }
        else {
            if (Get-AppSetting -SettingName "UseADModule") {
                $script:SelectedUser = Get-ADUser -Credential $Credential -Filter "UserPrincipalName -eq '$UserPrincipalName'" -Properties *
            }
            else {
                $useLDAPS = Get-AppSetting -SettingName "UseLDAPS"
                $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential -UseLDAPS $useLDAPS
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