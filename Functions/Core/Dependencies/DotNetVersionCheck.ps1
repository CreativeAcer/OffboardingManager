# Function to check the current PowerShell version and runtime
function Check-PowerShellVersion {
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 7) {
        return "Core"
    } elseif ($psVersion.Major -eq 5 -and $PSVersionTable.PSEdition -eq "Desktop") {
        return "Desktop"
    } else {
        throw "Unsupported PowerShell version: $($psVersion.ToString())"
    }
}

# Function to load System.DirectoryServices.Protocols
function Load-LdapLibrary {
    param (
        [string]$Environment
    )
    
    if ($Environment -eq "Desktop") {
        # PowerShell 5.1 (Windows PowerShell)
        try {
            Add-Type -AssemblyName System.DirectoryServices.Protocols
            Write-Host "Successfully loaded System.DirectoryServices.Protocols for PowerShell 5.1." -ForegroundColor Green
        } catch {
            Write-Error "Failed to load System.DirectoryServices.Protocols on PowerShell 5.1. Ensure .NET Framework 2.0 or later is installed."
            exit
        }
    } elseif ($Environment -eq "Core") {
        # PowerShell 7.x (or 6.x)
        try {
            $assemblyPath = "$PSScriptRoot\System.DirectoryServices.Protocols.dll"
            if (-Not (Test-Path $assemblyPath)) {
                Write-Host "Downloading System.DirectoryServices.Protocols.dll..." -ForegroundColor Yellow
                Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/System.DirectoryServices.Protocols" -OutFile "$PSScriptRoot\System.DirectoryServices.Protocols.nupkg"
                Expand-Archive -Path "$PSScriptRoot\System.DirectoryServices.Protocols.nupkg" -DestinationPath "$PSScriptRoot\NugetPackage" -Force
                Copy-Item "$PSScriptRoot\NugetPackage\lib\netstandard2.0\System.DirectoryServices.Protocols.dll" -Destination $assemblyPath
            }
            Add-Type -Path $assemblyPath
            Write-Host "Successfully loaded System.DirectoryServices.Protocols for PowerShell 7.x." -ForegroundColor Green
        } catch {
            Write-Error "Failed to load System.DirectoryServices.Protocols on PowerShell 7.x. Ensure .NET Core 3.1 or later is installed."
            exit
        }
    } else {
        throw "Unsupported environment: $Environment"
    }
}
