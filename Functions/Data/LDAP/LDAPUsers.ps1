function Get-LDAPUsers {
    param (
        [Parameter(Mandatory=$true)]
        $Directory,
        [string]$SearchFilter = "(objectClass=user)"
    )
    
    try {
        if ($Directory.IsLDAPS) {
            Write-Host "Using System.DirectoryServices.Protocols for LDAPS..."
            
            # Extract server name from path
            $serverName = $Directory.Connection.Path -replace 'LDAPS://', ''
            Write-Host "Server name: $serverName"

            # Get credentials from directory entry
            $username = $Directory.Connection.Username
            $password = $Directory.Connection.Password
            Write-Host "Using credentials for: $username"

            # Create LDAP identifier
            $identifier = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier($serverName, 636)
            
            # Create network credential
            $networkCred = New-Object System.Net.NetworkCredential($username, $password)
            
            # Create and configure LDAP connection
            $ldapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection($identifier)
            $ldapConnection.Credential = $networkCred
            $ldapConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Negotiate
            $ldapConnection.SessionOptions.ProtocolVersion = 3
            $ldapConnection.SessionOptions.SecureSocketLayer = $true
            
            Write-Host "Created LDAPS connection, attempting search..."

            # Create the search request
            $searchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest
            $searchRequest.DistinguishedName = ""  # Root
            $searchRequest.Filter = $SearchFilter
            $searchRequest.Scope = [System.DirectoryServices.Protocols.SearchScope]::Subtree
            
            # Add attributes to retrieve
            @(
                "userPrincipalName", "displayName", "mail", "department",
                "title", "manager", "telephoneNumber", "mobile",
                "whenCreated", "whenChanged", "memberOf", "userAccountControl"
            ) | ForEach-Object {
                $searchRequest.Attributes.Add($_) | Out-Null
            }
            
            Write-Host "Executing LDAPS search..."
            $timeSpan = New-Object System.TimeSpan(0, 0, 30)  # 30 seconds timeout
            $response = $ldapConnection.SendRequest($searchRequest, $timeSpan)
            Write-Host "Search completed successfully"
            
            return $response.Entries
        }
        else {
            Write-Host "Using DirectorySearcher for standard LDAP..."
            $searcher = New-Object System.DirectoryServices.DirectorySearcher($Directory.Connection)
            $searcher.Filter = $SearchFilter
            $searcher.PropertiesToLoad.AddRange(@(
                "userPrincipalName", "displayName", "mail", "department",
                "title", "manager", "telephoneNumber", "mobile",
                "whenCreated", "whenChanged", "memberOf", "userAccountControl"
            ))
            
            return $searcher.FindAll()
        }
    }
    catch {
        Write-Host "Error in Get-LDAPUsers: $($_.Exception.Message)"
        Write-Host "Stack trace: $($_.ScriptStackTrace)"
        throw
    }
}