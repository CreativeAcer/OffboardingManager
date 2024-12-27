function Update-SelectedUser {
    param (
        [string]$UserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential
    )
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