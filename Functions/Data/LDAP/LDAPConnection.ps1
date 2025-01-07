function Get-LDAPConnection {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DomainController,
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory=$false)]
        [bool]$UseLDAPS = $false
    )
    
    try {
        Write-Host "Connecting with DC: $($DomainController)"
        $networkCred = $Credential.GetNetworkCredential()
        
        if ($UseLDAPS) {
            $ldapPath = "LDAPS://$DomainController"
            $authType = [System.DirectoryServices.AuthenticationTypes]::Secure -bor 
                        [System.DirectoryServices.AuthenticationTypes]::Sealing -bor 
                        [System.DirectoryServices.AuthenticationTypes]::Signing -bor
                        [System.DirectoryServices.AuthenticationTypes]::SecureSocketsLayer

            Write-Host "Attempting secure LDAPS connection..."

            # Create callback to ignore certificate validation
            $callback = [System.Net.Security.RemoteCertificateValidationCallback]{
                param([object]$sender, [Security.Cryptography.X509Certificates.X509Certificate]$certificate,
                      [Security.Cryptography.X509Certificates.X509Chain]$chain, 
                      [Net.Security.SslPolicyErrors]$sslPolicyErrors)
                return $true
            }

            # Set the callback
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $callback

            $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry(
                $ldapPath, 
                "$($networkCred.Domain)\$($networkCred.Username)",
                $Credential.GetNetworkCredential().Password,
                $authType
            )
            $null = $directoryEntry.NativeObject
            Write-Host "LDAPS connection successful"
            return @{
                Connection = $directoryEntry
                IsLDAPS = $true
                Credentials = $Credential
            }
        }
        else {
            # Standard LDAP connection code remains the same
            $ldapPath = "LDAP://$DomainController"
            $authType = [System.DirectoryServices.AuthenticationTypes]::Secure -bor 
                        [System.DirectoryServices.AuthenticationTypes]::Sealing -bor 
                        [System.DirectoryServices.AuthenticationTypes]::Signing 

            $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry(
                $ldapPath, 
                "$($networkCred.Domain)\$($networkCred.Username)",
                $Credential.GetNetworkCredential().Password,
                $authType
            )
            $null = $directoryEntry.NativeObject
            Write-Host "LDAP connection successful"
            return @{
                Connection = $directoryEntry
                IsLDAPS = $false
                Credentials = $Credential
            }
        }
    }
    catch {
        Write-Host "LDAP connection error: $($_.Exception.Message)"
        throw
    }
}