function Show-UserDetails {
    param (
        [string]$UserPrincipalName,
        [System.Windows.Controls.TextBlock]$TextBlock,
        [System.Management.Automation.PSCredential]$Credential
    )
    $loadingWindow = $null
    try {
        $loadingWindow = Show-LoadingScreen -Message "Loading user information..."
        $loadingWindow.Show()
        [System.Windows.Forms.Application]::DoEvents()
        if ($script:DemoMode) {
            $User = Get-MockUser -UserPrincipalName $UserPrincipalName
        
        $Details = @"
Name: $($User.DisplayName)
User Principal Name: $($User.UserPrincipalName)
Enabled: $($User.Enabled)
Last Logon: $($User.LastLogonDate)
Created: $($User.Created)
Modified: $($User.Modified)
Email: $($User.EmailAddress)
Department: $($User.Department)
Title: $($User.Title)
Manager: $($User.Manager)
Office: $($User.Office)
Phone: $($User.OfficePhone)
Mobile: $($User.MobilePhone)
Account Expires: $($User.AccountExpirationDate)
Password Last Set: $($User.PasswordLastSet)
Password Never Expires: $($User.PasswordNeverExpires)
Account Locked Out: $($User.LockedOut)
Member Of:
$($User.MemberOf | ForEach-Object { "- $_" } | Out-String)
"@
    }
    else {
        if ($script:UseADModule) {
            $User = Get-ADUser -Credential $Credential -Filter {UserPrincipalName -eq $UserPrincipalName} -Properties *
            
            $Details = @"
Name: $($User.Name)
User Principal Name: $($User.UserPrincipalName)
Distinguished Name: $($User.DistinguishedName)
Enabled: $($User.Enabled)
Last Logon: $($User.LastLogonDate)
Created: $($User.Created)
Modified: $($User.Modified)
Email: $($User.EmailAddress)
Department: $($User.Department)
Title: $($User.Title)
Manager: $($User.Manager)
Office: $($User.Office)
Phone: $($User.OfficePhone)
Mobile: $($User.MobilePhone)
Account Expires: $($User.AccountExpirationDate)
Password Last Set: $($User.PasswordLastSet)
Password Never Expires: $($User.PasswordNeverExpires)
Account Locked Out: $($User.LockedOut)
Member Of:
$($User.MemberOf | ForEach-Object { "- $_" } | Out-String)
"@
    }
    else {
        $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
        $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
        $User = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
        
        # Convert UAC to enabled status
        $enabled = $true
        if ($User.Properties["userAccountControl"]) {
            $uac = $User.Properties["userAccountControl"][0]
            $enabled = -not [bool]($uac -band 0x2)
        }
        
        $Details = @"
Name: $($User.Properties["displayName"][0])
User Principal Name: $($User.Properties["userPrincipalName"][0])
Distinguished Name: $($User.Properties["distinguishedName"][0])
Enabled: $enabled
Created: $($User.Properties["whenCreated"][0])
Modified: $($User.Properties["whenChanged"][0])
Email: $($User.Properties["mail"][0])
Department: $($User.Properties["department"][0])
Title: $($User.Properties["title"][0])
Manager: $($User.Properties["manager"][0])
Phone: $($User.Properties["telephoneNumber"][0])
Mobile: $($User.Properties["mobile"][0])
Member Of:
$($User.Properties["memberOf"] | ForEach-Object { "- $_" } | Out-String)
"@
    }
}
    
    $TextBlock.Text = $Details
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Show-UserDetails"
    }
    finally {
        if ($loadingWindow) {
            $script:mainWindow.Dispatcher.Invoke([Action]{
                $loadingWindow.Close()
            })
        }
    }

}