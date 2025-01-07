function Test-LDAPSConnection {
    param(
        [string]$DomainController,
        [int]$Port = 636
    )
    
    try {
        Write-Host "Testing LDAPS prerequisites..."
        
        # Test if port 636 is open
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connectionResult = $tcpClient.BeginConnect($DomainController, $Port, $null, $null)
        $waited = $connectionResult.AsyncWaitHandle.WaitOne(1000, $false)
        
        if (-not $waited) {
            Write-Host "Port $Port is not accessible on $DomainController"
            return $false
        }
        
        Write-Host "Port $Port is open on $DomainController"
        
        # Test SSL certificate
        $cert = $null
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient($DomainController, $Port)
            $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream())
            $sslStream.AuthenticateAsClient($DomainController)
            $cert = $sslStream.RemoteCertificate
            
            Write-Host "SSL Certificate Details:"
            Write-Host "Subject: $($cert.Subject)"
            Write-Host "Issuer: $($cert.Issuer)"
            Write-Host "Valid From: $($cert.NotBefore)"
            Write-Host "Valid To: $($cert.NotAfter)"
            Write-Host "Thumbprint: $($cert.Thumbprint)"
        }
        catch {
            Write-Host "SSL Certificate error: $($_.Exception.Message)"
            return $false
        }
        finally {
            if ($sslStream) { $sslStream.Dispose() }
            if ($tcpClient) { $tcpClient.Dispose() }
        }
        
        return $true
    }
    catch {
        Write-Host "LDAPS test error: $($_.Exception.Message)"
        return $false
    }
}

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
        
        # Convert domain to DC format
        $dcPath = "DC=" + ($networkCred.Domain.Split('.') -join ',DC=')
        
        # If LDAPS is requested, try it first
        if ($UseLDAPS) {
            try {
                Write-Host "LDAPS connection requested"
                
                # Test LDAPS prerequisites
                if (-not (Test-LDAPSConnection -DomainController $DomainController)) {
                    Write-Host "LDAPS prerequisites not met, falling back to LDAP"
                    throw "LDAPS prerequisites not met"
                }

                $ldapPath = "LDAPS://$DomainController/$dcPath"
                Write-Host "Attempting LDAPS connection to: $ldapPath"
                
                $authType = [System.DirectoryServices.AuthenticationTypes]::Secure -bor 
                            [System.DirectoryServices.AuthenticationTypes]::Sealing -bor 
                            [System.DirectoryServices.AuthenticationTypes]::Signing -bor
                            [System.DirectoryServices.AuthenticationTypes]::SecureSocketsLayer

                # Create callback to ignore certificate validation
                $callback = [System.Net.Security.RemoteCertificateValidationCallback]{
                    param($sender, $certificate, $chain, $sslPolicyErrors)
                    return $true
                }
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $callback

                $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry(
                    $ldapPath, 
                    "$($networkCred.Domain)\$($networkCred.Username)",
                    $Credential.GetNetworkCredential().Password,
                    $authType
                )
                
                # Test the connection
                $null = $directoryEntry.NativeObject
                Write-Host "LDAPS connection successful"
                
                return @{
                    Connection = $directoryEntry
                    IsLDAPS = $true
                    Credentials = $Credential
                }
            }
            catch {
                Write-Host "LDAPS connection failed: $($_.Exception.Message)"
                Write-Host "Falling back to standard LDAP..."
            }
        }

        # Standard LDAP connection (fallback or primary if LDAPS not requested)
        Write-Host "Attempting standard LDAP connection..."
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
        
        # Test the connection
        $null = $directoryEntry.NativeObject
        Write-Host "LDAP connection successful"
        
        return @{
            Connection = $directoryEntry
            IsLDAPS = $false
            Credentials = $Credential
        }
    }
    catch {
        Write-Host "All connection attempts failed: $($_.Exception.Message)"
        throw
    }
}