# Import all required O365 modules
# Base O365 functionality
. "$PSScriptRoot\..\O365\Initialize-O365Tab.ps1"
. "$PSScriptRoot\..\O365\Start-O365Tasks.ps1"
. "$PSScriptRoot\..\Services\O365\Connect-O365.ps1"
. "$PSScriptRoot\..\Services\O365\LicenseManagement.ps1"

# Task-specific modules
. "$PSScriptRoot\..\O365\Tasks\Get-O365Status.ps1"
. "$PSScriptRoot\..\O365\Tasks\Set-MailboxTasks.ps1"
. "$PSScriptRoot\..\O365\Tasks\Set-TeamsTasks.ps1"
. "$PSScriptRoot\..\O365\Tasks\Set-LicenseTasks.ps1"

# UI update modules
. "$PSScriptRoot\..\O365\UI\Update-ForwardingList.ps1"
. "$PSScriptRoot\..\O365\UI\Update-TeamsOwnerList.ps1"
. "$PSScriptRoot\..\O365\UI\Update-LicenseList.ps1"

# Script-level variables for O365 tab
$script:O365Connected = $false



