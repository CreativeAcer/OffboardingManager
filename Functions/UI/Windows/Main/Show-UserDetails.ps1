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
        
        if (Get-AppSetting -SettingName "DemoMode") {
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
            if (Get-AppSetting -SettingName "UseADModule") {
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
                Write-Host "Looking up user details for: $UserPrincipalName"
                $useLDAPS = Get-AppSetting -SettingName "UseLDAPS"
                $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential -UseLDAPS $useLDAPS
                $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
                $rawUser = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1

                if ($null -eq $rawUser) {
                    throw "User not found: $UserPrincipalName"
                }

                # Create a normalized user object
                $User = @{}
                
                if ($directory.IsLDAPS) {
                    Write-Host "Processing LDAPS user details"
                    $User = @{
                        DisplayName = if ($rawUser.Attributes["displayName"]) { $rawUser.Attributes["displayName"][0] } else { "" }
                        UserPrincipalName = if ($rawUser.Attributes["userPrincipalName"]) { $rawUser.Attributes["userPrincipalName"][0] } else { "" }
                        DistinguishedName = if ($rawUser.Attributes["distinguishedName"]) { $rawUser.Attributes["distinguishedName"][0] } else { "" }
                        Email = if ($rawUser.Attributes["mail"]) { $rawUser.Attributes["mail"][0] } else { "" }
                        Department = if ($rawUser.Attributes["department"]) { $rawUser.Attributes["department"][0] } else { "" }
                        Title = if ($rawUser.Attributes["title"]) { $rawUser.Attributes["title"][0] } else { "" }
                        Manager = if ($rawUser.Attributes["manager"]) { $rawUser.Attributes["manager"][0] } else { "" }
                        Phone = if ($rawUser.Attributes["telephoneNumber"]) { $rawUser.Attributes["telephoneNumber"][0] } else { "" }
                        Mobile = if ($rawUser.Attributes["mobile"]) { $rawUser.Attributes["mobile"][0] } else { "" }
                        Created = if ($rawUser.Attributes["whenCreated"]) { $rawUser.Attributes["whenCreated"][0] } else { "" }
                        Modified = if ($rawUser.Attributes["whenChanged"]) { $rawUser.Attributes["whenChanged"][0] } else { "" }
                        MemberOf = if ($rawUser.Attributes["memberOf"]) { 
                            # Convert each memberOf entry to its string representation
                            @($rawUser.Attributes["memberOf"] | ForEach-Object { 
                                if ($_ -is [byte[]]) {
                                    [System.Text.Encoding]::UTF8.GetString($_)
                                } else {
                                    $_
                                }
                            })
                        } else { @() }
                    }

                    # Handle enabled status
                    if ($rawUser.Attributes["userAccountControl"]) {
                        $uac = $rawUser.Attributes["userAccountControl"][0]
                        $User.Enabled = -not [bool]($uac -band 0x2)
                    }
                    else {
                        $User.Enabled = $true
                    }
                }
                else {
                    Write-Host "Processing standard LDAP user details"
                    $User = @{
                        DisplayName = if ($rawUser.Properties["displayName"]) { $rawUser.Properties["displayName"][0] } else { "" }
                        UserPrincipalName = if ($rawUser.Properties["userPrincipalName"]) { $rawUser.Properties["userPrincipalName"][0] } else { "" }
                        DistinguishedName = if ($rawUser.Properties["distinguishedName"]) { $rawUser.Properties["distinguishedName"][0] } else { "" }
                        Email = if ($rawUser.Properties["mail"]) { $rawUser.Properties["mail"][0] } else { "" }
                        Department = if ($rawUser.Properties["department"]) { $rawUser.Properties["department"][0] } else { "" }
                        Title = if ($rawUser.Properties["title"]) { $rawUser.Properties["title"][0] } else { "" }
                        Manager = if ($rawUser.Properties["manager"]) { $rawUser.Properties["manager"][0] } else { "" }
                        Phone = if ($rawUser.Properties["telephoneNumber"]) { $rawUser.Properties["telephoneNumber"][0] } else { "" }
                        Mobile = if ($rawUser.Properties["mobile"]) { $rawUser.Properties["mobile"][0] } else { "" }
                        Created = if ($rawUser.Properties["whenCreated"]) { $rawUser.Properties["whenCreated"][0] } else { "" }
                        Modified = if ($rawUser.Properties["whenChanged"]) { $rawUser.Properties["whenChanged"][0] } else { "" }
                        MemberOf = if ($rawUser.Properties["memberOf"]) { 
                            @($rawUser.Properties["memberOf"]) 
                        } else { 
                            @() 
                        }
                    }

                    # Handle enabled status
                    if ($rawUser.Properties["userAccountControl"]) {
                        $uac = $rawUser.Properties["userAccountControl"][0]
                        $User.Enabled = -not [bool]($uac -band 0x2)
                    }
                    else {
                        $User.Enabled = $true
                    }
                }

                $Details = @"
Name: $($User.DisplayName)
User Principal Name: $($User.UserPrincipalName)
Distinguished Name: $($User.DistinguishedName)
Enabled: $($User.Enabled)
Created: $($User.Created)
Modified: $($User.Modified)
Email: $($User.Email)
Department: $($User.Department)
Title: $($User.Title)
Manager: $($User.Manager)
Phone: $($User.Phone)
Mobile: $($User.Mobile)
Member Of:
$($User.MemberOf | ForEach-Object { "- $_" } | Out-String)
"@
            }
        }
        
        $TextBlock.Text = $Details
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Show-UserDetails"
        Write-Host "Error details: $($_.Exception.Message)"
        Write-Host "Stack trace: $($_.ScriptStackTrace)"
        $TextBlock.Text = "Error loading user details: $($_.Exception.Message)"
    }
    finally {
        if ($loadingWindow) {
            $script:mainWindow.Dispatcher.Invoke([Action]{
                $loadingWindow.Close()
            })
        }
    }
}