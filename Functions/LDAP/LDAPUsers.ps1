function Get-LDAPUsers {
    param (
        [System.DirectoryServices.DirectoryEntry]$Directory,
        [string]$SearchFilter = "(objectClass=user)"
    )
    
    $searcher = New-Object System.DirectoryServices.DirectorySearcher($Directory)
    $searcher.Filter = $SearchFilter
    $searcher.PropertiesToLoad.AddRange(@(
        "userPrincipalName", "displayName", "mail", "department",
        "title", "manager", "telephoneNumber", "mobile",
        "whenCreated", "whenChanged", "memberOf", "userAccountControl"
    ))
    
    return $searcher.FindAll()
}