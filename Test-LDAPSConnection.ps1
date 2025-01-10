function Get-DomainController {
    try {
        # Try method 1: Environment variable
        $dc = $env:LOGONSERVER -replace '\\',''
        if (-not [string]::IsNullOrEmpty($dc)) {
            Write-Host "Found DC from LOGONSERVER: $dc"
            return $dc
        }

        # Try method 2: Current domain
        $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        $dc = $domain.DomainControllers[0].Name
        if (-not [string]::IsNullOrEmpty($dc)) {
            Write-Host "Found DC from current domain: $dc"
            return $dc
        }

        # Try method 3: DNS query
        $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
        $dc = (nslookup -type=srv _ldap._tcp.dc._msdcs.$domain 2>$null | 
               Select-String -Pattern "svr hostname = (.+)$" | 
               ForEach-Object { $_.Matches.Groups[1].Value }) | Select-Object -First 1
        
        if (-not [string]::IsNullOrEmpty($dc)) {
            Write-Host "Found DC from DNS query: $dc"
            return $dc
        }

        throw "No Domain Controller found"
    }
    catch {
        Write-Host "Error finding Domain Controller: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Test-LDAPSConnection {
    param(
        [Parameter(Mandatory=$false)]
        [string]$DomainController = (Get-DomainController)
    )

    try {
        Write-Host "`n=== Testing LDAPS Configuration ==="
        
        # Validate DC name
        if ([string]::IsNullOrEmpty($DomainController)) {
            throw "No Domain Controller specified"
        }

        Write-Host "Testing connection to Domain Controller: $DomainController"
        $LDAPSPort = 636  # Define LDAPS port

        # Test 1: Basic port connectivity
        try {
            Write-Host "`nTesting LDAPS port connectivity..."
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $result = $tcpClient.BeginConnect($DomainController, $LDAPSPort, $null, $null)
            $waited = $result.AsyncWaitHandle.WaitOne(1000, $false)
            
            if ($waited) {
                Write-Host "✓ Port $LDAPSPort is open" -ForegroundColor Green
            } else {
                Write-Host "✗ Port $LDAPSPort is not accessible" -ForegroundColor Red
                return
            }
        }
        catch {
            Write-Host "✗ Port connectivity test failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        finally {
            if ($tcpClient) {
                $tcpClient.Close()
            }
        }

        # Test 2: LDAPS Binding
        try {
            Write-Host "`nTesting LDAPS binding..."
            $ldapPath = "LDAPS://$DomainController"
            $authType = [System.DirectoryServices.AuthenticationTypes]::Secure -bor 
                       [System.DirectoryServices.AuthenticationTypes]::SecureSocketsLayer

            $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry($ldapPath, $null, $null, $authType)
            
            # Try to access a property to verify connection
            $name = $directoryEntry.Name
            
            Write-Host "✓ LDAPS binding successful" -ForegroundColor Green
            Write-Host "`nLDAPS connection details:"
            Write-Host "  Server: $DomainController"
            Write-Host "  Path: $($directoryEntry.Path)"
            Write-Host "  Name: $name"

            # Test 3: SSL Certificate (only if binding successful)
            try {
                Write-Host "`nTesting SSL Certificate..."
                $tcpClient = New-Object System.Net.Sockets.TcpClient($DomainController, $LDAPSPort)
                $sslStream = New-Object System.Net.Security.SslStream(
                    $tcpClient.GetStream(),
                    $false,
                    { param($sender, $certificate, $chain, $errors) return $true }
                )

                $sslStream.AuthenticateAsClient($DomainController)
                $cert = $sslStream.RemoteCertificate

                if ($cert -ne $null) {
                    # Convert to X509Certificate2 for better property access
                    $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cert)
    
                    Write-Host "Certificate details:" -ForegroundColor Cyan
                    Write-Host "  Subject: $($cert2.Subject)"
                    Write-Host "  Issuer: $($cert2.Issuer)"
                    Write-Host "  Valid From: $($cert2.NotBefore.ToString('yyyy-MM-dd HH:mm:ss'))"
                    Write-Host "  Valid To: $($cert2.NotAfter.ToString('yyyy-MM-dd HH:mm:ss'))"
                    Write-Host "  Thumbprint: $($cert2.Thumbprint)"

                    if ($cert2.NotAfter -gt (Get-Date)) {
                        Write-Host "✓ Certificate is valid" -ForegroundColor Green
                    } else {
                        Write-Host "✗ Certificate has expired" -ForegroundColor Red
                    }
                } else {
                    Write-Host "✗ SSL Certificate is null or could not be retrieved" -ForegroundColor Red
                }
            } catch {
                Write-Host "✗ SSL Certificate validation failed: $($_.Exception.Message)" -ForegroundColor Red
}
            finally {
                if ($sslStream -ne $null) {
                    try { $sslStream.Dispose() } catch { Write-Host "Error disposing SslStream: $($_.Exception.Message)" }
                }
                if ($tcpClient -ne $null) {
                    try { $tcpClient.Dispose() } catch { Write-Host "Error disposing TcpClient: $($_.Exception.Message)" }
                }
            }

        }
        catch {
            Write-Host "✗ LDAPS binding failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        finally {
            if ($directoryEntry) {
                $directoryEntry.Dispose()
            }
        }
    }
    catch {
        Write-Host "`n✗ Test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Write-Host "`n=== Test Complete ===`n"
    }
}

# Call the function with the automatically detected DC
$dc = $env:LOGONSERVER -replace '\\',''
if ([string]::IsNullOrEmpty($dc)) {
    Write-Host "Could not detect Domain Controller from environment." -ForegroundColor Yellow
    Write-Host "Please provide a Domain Controller name." -ForegroundColor Yellow
} else {
    Write-Host "Testing LDAPS for Domain Controller: $dc"
    Test-LDAPSConnection -DomainController $dc
}