function Get-ADAuthentication {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DomainController,
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        Write-Host "Attempting AD authentication..."
        Write-Host "Using username: $($Credential.UserName)"
        
        # Get the username without domain
        $username = $Credential.UserName.Split('\')[-1]
        
        # Try to get the user with the provided credentials
        $adUser = Get-ADUser -Server $DomainController -Credential $Credential -Identity $username
        
        if ($null -eq $adUser) {
            throw "User not found in Active Directory"
        }

        Write-Host "AD authentication successful"
        return $adUser
    }
    catch {
        Write-Host "AD authentication error: $($_.Exception.Message)"
        throw
    }
}