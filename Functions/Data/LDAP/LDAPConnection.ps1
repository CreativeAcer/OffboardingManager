function Get-LDAPConnection {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DomainController,
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        Write-Host "Attempting LDAP connection to: LDAP://$DomainController"
        Write-Host "Using username: $($Credential.UserName)"
        
        $ldapPath = "LDAP://$DomainController"
        
        # Create the directory entry with basic authentication type
        $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry(
            $ldapPath,
            $Credential.UserName,
            $Credential.GetNetworkCredential().Password,
            [System.DirectoryServices.AuthenticationTypes]::Secure
        )
        
        # Test the connection
        $null = $directoryEntry.NativeObject
        Write-Host "LDAP connection successful"
        
        return $directoryEntry
    }
    catch {
        Write-Host "LDAP connection error: $($_.Exception.Message)"
        throw
    }
}