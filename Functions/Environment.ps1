function Test-Environment {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
    
    if ($arch -eq [System.Runtime.InteropServices.Architecture]::X86 -or 
        $arch -eq [System.Runtime.InteropServices.Architecture]::X64) {
        try {
            Import-Module ActiveDirectory -ErrorAction Stop
            $script:UseADModule = $true
            Write-Host "Using Active Directory module"
            return $true
        }
        catch {
            Write-Host "AD module not available, falling back to LDAP"
        }
    }
    
    Write-Host "Using LDAP for directory access"
    return $true
}