function Get-LDAPConnection {
    param (
        [string]$DomainController,
        [System.Management.Automation.PSCredential]$Credential
    )
    
    $ldapPath = "LDAP://$DomainController"
    $directory = New-Object System.DirectoryServices.DirectoryEntry($ldapPath, 
        $Credential.UserName, 
        $Credential.GetNetworkCredential().Password)
    
    return $directory
}