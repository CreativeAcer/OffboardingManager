#Requires -Version 5.1
<#
.SYNOPSIS
    Active Directory User Offboarding Tool
.DESCRIPTION
    GUI tool for managing user offboarding tasks in Active Directory
.NOTES
    Version:        1.0
    Author:         Marco Moris
    Creation Date:  2024-03-20
    Purpose/Change: Initial script development
#>

# Import required assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.DirectoryServices
Add-Type -AssemblyName System.DirectoryServices.AccountManagement

# Script root path determination
# $script:BasePath = $PSScriptRoot
# if (-not $script:BasePath) {
#     $script:BasePath = Split-Path $MyInvocation.MyCommand.Path
# }

# Import utilities
. "$PSScriptRoot\Functions\Utilities\PathUtils.ps1"

$currentPath = Get-BasePath
$script:BasePath = Split-Path -Parent (Split-Path -Parent $currentPath)  # Move two folders higher
        

# Import configurations
. "$script:BasePath\Config\Colors.ps1"
. "$script:BasePath\Config\Fonts.ps1"
. "$script:BasePath\Config\Settings.ps1"

# Import functions
. "$script:BasePath\Functions\Environment.ps1"
. "$script:BasePath\Functions\LDAP\LDAPConnection.ps1"
. "$script:BasePath\Functions\LDAP\LDAPUsers.ps1"
. "$script:BasePath\Functions\UI\XamlHelper.ps1"
. "$script:BasePath\Functions\UI\LoadingScreen.ps1"
. "$script:BasePath\Functions\UI\LoginDialog.ps1"
. "$script:BasePath\Functions\UI\MainWindow.ps1"
. "$script:BasePath\Functions\UI\OnPremHandlers.ps1"
. "$script:BasePath\Functions\UI\O365Handlers.ps1"
. "$script:BasePath\Functions\UI\ReportHandlers.ps1"
. "$script:BasePath\Functions\Logging\Write-ActivityLog.ps1"
#. "$script:BasePath\Functions\UI\EasterEgg.ps1"

# Error handling function
function Write-ErrorLog {
    param(
        [string]$ErrorMessage,
        [string]$Location
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] ERROR in $Location`: $ErrorMessage"
    
    # Ensure log directory exists
    $logDir = Join-Path $script:BasePath "Logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }
    
    # Write to log file
    $logFile = Join-Path $logDir "error_log.txt"
    $logMessage | Out-File -FilePath $logFile -Append
    
    # Also write to console
    Write-Host $logMessage -ForegroundColor Red
}

# Version check
$minVersion = [Version]"5.1"
$currentVersion = $PSVersionTable.PSVersion

if ($currentVersion -lt $minVersion) {
    $message = "This script requires PowerShell version $minVersion or higher. Current version is $currentVersion"
    [System.Windows.MessageBox]::Show($message, "Version Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    exit
}

# Main script execution
try {
    Write-Host "Initializing AD User Offboarding Tool..."
    
    # Test environment and module availability
    if (Test-Environment) {
        Write-Host "Environment check passed."
        
        # Show loading screen for initial setup
        $loadingWindow = Show-LoadingScreen -Message "Initializing environment..."
        $loadingWindow.Show()
        
        try {
            # Show login dialog
            Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Preparing login..."
            Start-Sleep -Milliseconds 500  # Brief pause for smooth transition
            $loadingWindow.Close()
            
            if (Show-LoginDialog) {
                Write-Host "Login successful."
                
                # Create credential object
                $Credential = New-Object System.Management.Automation.PSCredential($script:Username, $script:Password)
                
                try {
                    # Show main window
                    Show-MainWindow -Credential $Credential
                }
                catch {
                    Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "MainWindow"
                    [System.Windows.MessageBox]::Show(
                        "An error occurred while running the main application: $($_.Exception.Message)", 
                        "Error", 
                        [System.Windows.MessageBoxButton]::OK, 
                        [System.Windows.MessageBoxImage]::Error)
                }
            }
            else {
                Write-Host "Login cancelled or failed."
            }
        }
        catch {
            if ($loadingWindow) {
                $loadingWindow.Close()
            }
            throw
        }
    }
    else {
        throw "Environment initialization failed."
    }
}
catch {
    Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Main"
    [System.Windows.MessageBox]::Show(
        "Failed to initialize the application. Please check if you have necessary permissions and try again.`n`nError: $($_.Exception.Message)", 
        "Critical Error", 
        [System.Windows.MessageBoxButton]::OK, 
        [System.Windows.MessageBoxImage]::Error)
}
finally {
    # Cleanup
    Write-Host "Cleaning up..."
    if ($script:Password) {
        $script:Password.Dispose()
    }
    [System.GC]::Collect()
}

Write-Host "Script execution completed."