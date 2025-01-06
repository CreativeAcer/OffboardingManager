function Get-LDAPConnection {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DomainController,
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        Write-Host "Connecting with DC: $($DomainController)"
        $networkCred = $Credential.GetNetworkCredential()
        
        # Try LDAPS first (SSL)
        $ldapPath = "LDAPS://$DomainController"
        $authType = [System.DirectoryServices.AuthenticationTypes]::SecureSocketsLayer

        # Write-Host "Attempting secure LDAPS connection..."
        # try {
        #     $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry(
        #         $ldapPath, 
        #         $Credential.UserName,
        #         $networkCred.Password,
        #         $authType
        #     )
            
        #     # Test connection
        #     $null = $directoryEntry.NativeObject
        #     Write-Host "LDAPS connection successful"
            
        #     return $directoryEntry
        # }
        # catch {
        #     Write-Host "LDAPS connection failed, trying standard LDAP..."
        Write-Host "LDAPS connection failed, currently unsupported..."
            # If LDAPS fails, try regular LDAP
            $ldapPath = "LDAP://$DomainController"
            $authType = [System.DirectoryServices.AuthenticationTypes]::Secure -bor 
                        [System.DirectoryServices.AuthenticationTypes]::Sealing -bor 
                        [System.DirectoryServices.AuthenticationTypes]::Signing 

            $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry(
                $ldapPath, 
                "$($networkCred.Domain)\$($networkCred.Username)",
                $networkCred.Password,
                $authType
            )
            # Test connection using NativeObject
            $null = $directoryEntry.NativeObject
            $script:searchBase = Set-RootSearchBase -DomainController $DomainController
            Write-Host "LDAP connection successful"
            return $directoryEntry
        # }
    }
    catch {
        Write-Host "LDAP connection error: $($_.Exception.Message)"
        throw
    }
}

function Set-RootSearchBase {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DomainController
    )
    try {
        # Retrieve the default search base
        $rootDSE = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$DomainController/RootDSE")
        Write-Host "Default search base: $searchBase"
        return $rootDSE.Properties["defaultNamingContext"][0]
    }
    catch {
        Write-Host "Retrieving seachbase failed: $($_.Exception.Message)"
        throw
    }
    
}