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

#Check if a previous proces is running
try {
    if (Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq "AD User Offboarding" -or $_.MainWindowTitle -eq "AD User Offboarding (DEMO MODE)"}) {
        Stop-Process -Name "powershell" -Force
    }
} catch {
    Write-Host "No previous instance found"
}

# Import utilities
. "$PSScriptRoot\Functions\Utilities\PathUtils.ps1"
$currentPath = Get-BasePath
$script:BasePath = Split-Path -Parent (Split-Path -Parent $currentPath)  # Move two folders higher

# Import Core functions
. "$script:BasePath\Functions\Core\Environment.ps1"
. "$script:BasePath\Functions\Core\Logging\Write-ActivityLog.ps1"
. "$script:BasePath\Functions\Core\Logging\Write-ErrorLog.ps1"
. "$script:BasePath\Functions\Core\Dependencies\DotNetVersionCheck.ps1"
 
# Import Data functions
. "$script:BasePath\Functions\Data\Mock\MockData.ps1"
. "$script:BasePath\Functions\Data\ADModule\ADConnection.ps1"
. "$script:BasePath\Functions\Data\ADModule\ADUsers.ps1"  
. "$script:BasePath\Functions\Data\LDAP\LDAPConnection.ps1"
. "$script:BasePath\Functions\Data\LDAP\LDAPUsers.ps1"  

# Import configurations
. "$script:BasePath\Config\Colors.ps1"
. "$script:BasePath\Config\Fonts.ps1"
. "$script:BasePath\Config\Settings.ps1"

# Initialize settings
Initialize-AppSettings

# Import workflow functionality
. "$script:BasePath\Functions\Workflow\WorkflowTasks.ps1"
. "$script:BasePath\Functions\Workflow\Start-OffboardingWorkflow.ps1"
. "$script:BasePath\Functions\Workflow\Configuration\Get-WorkflowConfiguration.ps1"
. "$script:BasePath\Functions\Workflow\Configuration\Save-WorkflowConfiguration.ps1"
. "$script:BasePath\Functions\Workflow\Configuration\Import-WorkflowConfiguration.ps1"
. "$script:BasePath\Functions\Workflow\Configuration\Remove-WorkflowConfiguration.ps1"
. "$script:BasePath\Functions\Workflow\Configuration\Get-TaskSettings.ps1"
. "$script:BasePath\Functions\Workflow\Tasks\Get-WorkflowTasks.ps1"

# Import workflow UI
. "$script:BasePath\Functions\UI\Workflow\Initialize-WorkflowTab.ps1"

# Import Shared functions
. "$script:BasePath\Functions\UI\Shared\XamlHelper.ps1"
. "$script:BasePath\Functions\UI\Shared\LoadingScreen.ps1"
. "$script:BasePath\Functions\UI\Shared\Controls\Update-WorkflowDropdowns.ps1"

# Import Windows functions
. "$script:BasePath\Functions\UI\Windows\Login\LoginDialog.ps1"
. "$script:BasePath\Functions\UI\Windows\Main\MainWindow.ps1"
. "$script:BasePath\Functions\UI\Windows\Settings\Initialize-WorkflowSettingsTab.ps1"
. "$script:BasePath\Functions\UI\Windows\Settings\Show-SettingsWindow.ps1"
. "$script:BasePath\Functions\UI\Windows\Settings\WorkflowTaskSettings.ps1"
. "$script:BasePath\Functions\UI\Windows\Reports\Initialize-ReportsTab.ps1"

# Import functions
. "$script:BasePath\Functions\UI\Services\O365\MailboxManagement.ps1"
. "$script:BasePath\Functions\UI\Services\O365\TeamsManagement.ps1"
. "$script:BasePath\Functions\UI\Handlers\SettingsHandler.ps1"
. "$script:BasePath\Functions\UI\Handlers\OnPremHandlers.ps1"
. "$script:BasePath\Functions\UI\Handlers\O365Handlers.ps1"
. "$script:BasePath\Functions\UI\Handlers\ReportHandlers.ps1"


#. "$script:BasePath\Functions\UI\EasterEgg.ps1"

# Version check
$minVersion = [Version]"5.1"
$currentVersion = $PSVersionTable.PSVersion

if ($currentVersion -lt $minVersion) {
    $message = "This script requires PowerShell version $minVersion or higher. Current version is $currentVersion"
    [System.Windows.MessageBox]::Show($message, "Version Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    exit
}

try {
    $psEnvironment = Check-PowerShellVersion
    Write-Host "Running on PowerShell $psEnvironment"
    $script:UseProtocolsForLDAPS = Initialize-LDAPAssemblies
    Write-Host "Environment validated. Proceeding with script execution..." -ForegroundColor Green
} catch {
    Write-Error $_.Exception.Message
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
                if (Get-AppSetting -SettingName "DemoMode") {
                    # Create a dummy credential for demo mode
                    $securePassword = ConvertTo-SecureString "DemoPassword" -AsPlainText -Force
                    $Credential = New-Object System.Management.Automation.PSCredential("DemoUser", $securePassword)
                }
                else {
                    # Normal credential creation
                    # Format username correctly for AD authentication
                    $formattedUsername = if ($Username.Contains('\') -or $Username.Contains('@')) {
                        $Username
                    } else {
                        "$Domain\$Username"
                    }
                    
                    $Credential = New-Object System.Management.Automation.PSCredential ($formattedUsername, $Password)
                }
                
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