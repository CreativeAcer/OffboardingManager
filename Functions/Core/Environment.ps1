function Test-Environment {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
    
    if ($arch -eq [System.Runtime.InteropServices.Architecture]::X86 -or 
        $arch -eq [System.Runtime.InteropServices.Architecture]::X64) {
        try {
            # Check Windows PowerShell for AD module
            if (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
                Write-Host "AD module not available. Please ask your administrator to install RSAT tools."
                Write-Host "Falling back to LDAP"
                $script:UseADModule = $false
                return $true
            }
            
            Import-Module ActiveDirectory -ErrorAction Stop
            $script:UseADModule = $true
            Write-Host "Using Active Directory module"
            return $true
        }
        catch {
            Write-Host "Failed to import AD module: $($_.Exception.Message)"
            Write-Host "Falling back to LDAP"
            $script:UseADModule = $false
        }
    }
    
    Write-Host "Using LDAP(S) for directory access"
    return $true
}