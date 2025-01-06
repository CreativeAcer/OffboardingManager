function Get-ADModuleUsers {
   param (
       [Parameter(Mandatory=$true)]
       [System.Management.Automation.PSCredential]$Credential,
       [string]$SearchFilter = "*",
       [string]$DomainController  # Add this if you need to specify a DC
   )
   
   try {
       $adParams = @{
           'Credential' = $Credential
           'Properties' = @(
               "userPrincipalName", "displayName", "mail", "department",
               "title", "manager", "telephoneNumber", "mobile",
               "whenCreated", "whenChanged", "memberOf", "Enabled",
               "LockedOut"
           )
           'Filter' = "Enabled -eq 'True' -and UserPrincipalName -like '$SearchFilter'"
       }

       # Add server parameter if domain controller is specified
       if ($DomainController) {
           $adParams['Server'] = $DomainController
       }

       # Get AD users with specified properties
       $users = Get-ADUser @adParams | 
               Where-Object { -not $_.LockedOut -and $_.mail -like "*" } |
               Sort-Object UserPrincipalName

       return $users
   }
   catch {
       Write-Host "Error retrieving AD users: $($_.Exception.Message)"
       throw
   }
}