# OnPrem tab initialization and event handlers
function Initialize-OnPremTab {
    param (
        [System.Windows.Window]$Window,
        [System.Management.Automation.PSCredential]$Credential
    )
    
    # Get control references
    $script:chkDisableAcc = $Window.FindName("chkDisableAcc")
    $script:chkRemMemberShips = $Window.FindName("chkRemMemberShips")
    $script:chkMoveToDisabledOu = $Window.FindName("chkMoveToDisabledOu")
    $script:chkScheduleDisable = $Window.FindName("chkScheduleDisable")
    $script:dpDisableDate = $Window.FindName("dpDisableDate")
    $script:btnRunOnPrem = $Window.FindName("btnRunOnPrem")
    $script:txtOnPremResults = $Window.FindName("txtOnPremResults")

    # Configure checkboxes with task descriptions
    # $chkDisableAcc.Content = "Disable AD Account"
    # $chkRemMemberShips.Content = "Remove Group Memberships"
    # $chkMoveToDisabledOu.Content = "Move to Disabled OU"

    # Add tooltip descriptions
    $chkDisableAcc.ToolTip = "Disables the user's Active Directory account"
    $chkRemMemberShips.ToolTip = "Removes user from all AD groups except Domain Users"
    $chkMoveToDisabledOu.ToolTip = "Moves the user account to the Disabled Users OU"

    # Add click handler for the run button
    $script:btnRunOnPrem.Add_Click({
        Start-OnPremTasks -Credential $Credential
    })
}

function Start-OnPremTasks {
    param (
        [System.Management.Automation.PSCredential]$Credential
    )

    # Validate user selection
    if (-not $script:SelectedUser) {
        $script:txtOnPremResults.Text = "Please select a user first."
        return
    }

    # Get user details based on the connection method
    $userEmail = if (Get-AppSetting -SettingName "DemoMode") {
        $script:SelectedUser.EmailAddress
    }
    elseif ($script:UseADModule) {
        $script:SelectedUser.mail
    } else {
        $script:SelectedUser.Properties["mail"][0]
    }

    $userPrincipalName = if (Get-AppSetting -SettingName "DemoMode") {
        $script:SelectedUser.UserPrincipalName
    }
    elseif ($script:UseADModule) {
        $script:SelectedUser.UserPrincipalName
    } else {
        $script:SelectedUser.Properties["userPrincipalName"][0]
    }

    if (-not $userEmail) {
        $script:txtOnPremResults.Text = "Selected user does not have an email address."
        return
    }

    # Initialize results collection
    $results = @()
    $errorOccurred = $false

    # Task 1: Disable AD Account
    if ($script:chkDisableAcc.IsChecked) {
        try {
            $result = Disable-UserAccount -UserPrincipalName $userPrincipalName -Credential $Credential
            Write-ActivityLog -UserEmail $userEmail -Action "Disable AD Account" -Result $result -Platform "OnPrem"
            $results += "Account Disable Task: $result"
        }
        catch {
            $errorMessage = "Account Disable Task Failed: $($_.Exception.Message)"
            Write-ActivityLog -UserEmail $userEmail -Action "Disable AD Account" -Result $errorMessage -Platform "OnPrem"
            $results += $errorMessage
            $errorOccurred = $true
        }
    }

    # Task 2: Remove Group Memberships
    if ($script:chkRemMemberShips.IsChecked) {
        try {
            $result = Remove-UserGroups -UserPrincipalName $userPrincipalName -Credential $Credential
            Write-ActivityLog -UserEmail $userEmail -Action "Remove Group Memberships" -Result $result -Platform "OnPrem"
            $results += "Group Removal Task: $result"
        }
        catch {
            $errorMessage = "Group Removal Task Failed: $($_.Exception.Message)"
            Write-ActivityLog -UserEmail $userEmail -Action "Remove Group Memberships" -Result $errorMessage -Platform "OnPrem"
            $results += $errorMessage
            $errorOccurred = $true
        }
    }

    # Task 3: Move to Disabled OU
    if ($script:chkMoveToDisabledOu.IsChecked) {
        try {
            $result = Move-UserToDisabledOU -UserPrincipalName $userPrincipalName -Credential $Credential
            Write-ActivityLog -UserEmail $userEmail -Action "Move to Disabled OU" -Result $result -Platform "OnPrem"
            $results += "OU Move Task: $result"
        }
        catch {
            $errorMessage = "OU Move Task Failed: $($_.Exception.Message)"
            Write-ActivityLog -UserEmail $userEmail -Action "Move to Disabled OU" -Result $errorMessage -Platform "OnPrem"
            $results += $errorMessage
            $errorOccurred = $true
        }
    }
    # Task 4: Set Disabled date
    if ($script:chkScheduleDisable.IsChecked) {
        try {
            $disableDate = $script:dpDisableDate.SelectedDate
            if (-not $disableDate) {
                throw "No disable date selected"
            }

            $result = Set-AccountExpiration -UserPrincipalName $userPrincipalName -ExpirationDate $disableDate -Credential $Credential
            Write-ActivityLog -UserEmail $userEmail -Action "Schedule Account Disable" -Result $result -Platform "OnPrem"
            $results += "Account Expiration Task: $result"
        }
        catch {
            $errorMessage = "Account Expiration Task Failed: $($_.Exception.Message)"
            Write-ActivityLog -UserEmail $userEmail -Action "Schedule Account Disable" -Result $errorMessage -Platform "OnPrem"
            $results += $errorMessage
            $errorOccurred = $true
        }
    }

    # Display results
    if ($results.Count -eq 0) {
        $script:txtOnPremResults.Text = "Please select at least one task to run for user $userEmail"
    } else {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $status = if ($errorOccurred) { "Completed with errors" } else { "Completed successfully" }
        
        $resultText = @"
Execution Time: $timestamp
User: $userEmail
Status: $status

Task Results:
$($results | ForEach-Object { "- $_" } | Out-String)
"@
        $script:txtOnPremResults.Text = $resultText
    }
}

function Disable-UserAccount {
    param (
        [string]$UserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential
    )
 
    Write-Host "SIMULATION: Would disable account for: $UserPrincipalName"
    if (Get-AppSetting -SettingName "DemoMode") {
        try {
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Account Disable" -Result "Starting account disable process (Demo)" -Platform "OnPrem"
            return "[SIMULATION] Would disable account for demo user: $UserPrincipalName"
        }
        catch {
            throw "Demo account disable simulation failed: $($_.Exception.Message)"
        }
    }
    elseif ($script:UseADModule) {
        try {
            $user = Get-ADUser -Identity $UserPrincipalName -Properties DisplayName -Credential $Credential
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Account Disable" -Result "Starting account disable process" -Platform "OnPrem"
            
            # Commented out actual action
            #Disable-ADAccount -Identity $UserPrincipalName -Credential $Credential
            #Write-ActivityLog -UserEmail $UserPrincipalName -Action "Account Disable" -Result "Account successfully disabled" -Platform "OnPrem"
            
            return "[SIMULATION] Would disable account using AD Module: Account would be disabled"
        }
        catch {
            throw "Account disable simulation failed: $($_.Exception.Message)"
        }
    }
    else {
        try {
            $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
            $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
            $user = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
            
            if ($user) {
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Account Disable" -Result "Starting account disable process" -Platform "OnPrem"
                
                # Commented out actual action
                #$userEntry = $user.GetDirectoryEntry()
                #$userEntry.InvokeSet("userAccountControl", 514)  # Disabled account flag
                #$userEntry.CommitChanges()
                #Write-ActivityLog -UserEmail $UserPrincipalName -Action "Account Disable" -Result "Account successfully disabled" -Platform "OnPrem"
                
                return "[SIMULATION] Would disable account using LDAP: Account would be set to disabled state"
            }
            throw "User not found"
        }
        catch {
            throw "Account disable simulation failed (LDAP): $($_.Exception.Message)"
        }
    }
 }

function Remove-UserGroups {
    param (
        [string]$UserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential
    )
 
    Write-Host "[SIMULATION]: Would remove group memberships for: $UserPrincipalName"
    if (Get-AppSetting -SettingName "DemoMode") {
        try {
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Group Membership Backup" -Result "Groups to remove: $($groups -join '; ')" -Platform "OnPrem"
            return "[SIMULATION]: Would remove group memberships for: $UserPrincipalName"
        }
        catch {
            throw "Demo account disable simulation failed: $($_.Exception.Message)"
        }
    }
    elseif ($script:UseADModule) {
        try {
            $user = Get-ADUser -Identity $UserPrincipalName -Properties MemberOf, DisplayName -Credential $Credential
            $groups = $user.MemberOf | Where-Object { $_ -notmatch "Domain Users" }
            
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Group Membership Backup" -Result "Groups to remove: $($groups -join '; ')" -Platform "OnPrem"
            
            # Commented out actual action
            #foreach ($group in $groups) {
            #    Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false -Credential $Credential
            #    Write-ActivityLog -UserEmail $UserPrincipalName -Action "Group Removal" -Result "Removed from: $group" -Platform "OnPrem"
            #}
            return "[SIMULATION] Would remove membership from $($groups.Count) groups using AD Module"
        }
        catch {
            throw "Group removal simulation failed: $($_.Exception.Message)"
        }
    }
    else {
        try {
            $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
            $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
            $user = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
            
            if ($user) {
                $userEntry = $user.GetDirectoryEntry()
                $groups = $userEntry.memberOf | Where-Object { $_ -notmatch "Domain Users" }
                
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Group Membership Backup" -Result "Groups to remove: $($groups -join '; ')" -Platform "OnPrem"
                
                # Commented out actual action
                #foreach ($group in $groups) {
                #    $groupEntry = [ADSI]"LDAP://$group"
                #    $groupEntry.Remove("member", $userEntry.distinguishedName[0])
                #    $groupEntry.CommitChanges()
                #    Write-ActivityLog -UserEmail $UserPrincipalName -Action "Group Removal" -Result "Removed from: $group" -Platform "OnPrem"
                #}
                return "[SIMULATION] Would remove membership from $($groups.Count) groups using LDAP"
            }
            throw "User not found"
        }
        catch {
            throw "Group removal simulation failed (LDAP): $($_.Exception.Message)"
        }
    }
 }

function Move-UserToDisabledOU {
    param (
        [string]$UserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential
    )
 
    Write-Host "SIMULATION: Would move user to Disabled OU: $UserPrincipalName"
 
    # You should customize this OU path for your environment
    $disabledOU = "OU=Disabled Users,DC=yourdomain,DC=com"
 
    if (Get-AppSetting -SettingName "DemoMode") {
        try {
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Move to Disabled OU" -Result "Starting OU move process" -Platform "OnPrem"
            return "SIMULATION: Would move user to Disabled OU: $UserPrincipalName"
        }
        catch {
            throw "Demo account disable simulation failed: $($_.Exception.Message)"
        }
    }
    elseif ($script:UseADModule) {
        try {
            $user = Get-ADUser -Identity $UserPrincipalName -Properties DisplayName -Credential $Credential
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Move to Disabled OU" -Result "Starting OU move process" -Platform "OnPrem"
            
            # Commented out actual action
            #Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledOU -Credential $Credential
            #Write-ActivityLog -UserEmail $UserPrincipalName -Action "Move to Disabled OU" -Result "Successfully moved to $disabledOU" -Platform "OnPrem"
            
            return "[SIMULATION] Would move user to $disabledOU using AD Module"
        }
        catch {
            throw "OU move simulation failed: $($_.Exception.Message)"
        }
    }
    else {
        try {
            $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
            $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
            $user = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
            
            if ($user) {
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Move to Disabled OU" -Result "Starting OU move process" -Platform "OnPrem"
                
                # Commented out actual action
                #$userEntry = $user.GetDirectoryEntry()
                #$userEntry.psbase.MoveTo([ADSI]"LDAP://$disabledOU")
                #Write-ActivityLog -UserEmail $UserPrincipalName -Action "Move to Disabled OU" -Result "Successfully moved to $disabledOU" -Platform "OnPrem"
                
                return "[SIMULATION] Would move user to $disabledOU using LDAP"
            }
            throw "User not found"
        }
        catch {
            throw "OU move simulation failed (LDAP): $($_.Exception.Message)"
        }
    }
}

function Set-AccountExpiration {
    param (
        [string]$UserPrincipalName,
        [DateTime]$ExpirationDate,
        [System.Management.Automation.PSCredential]$Credential
       
    )
 
    Write-Host "[SIMULATION]: Would set account expiration for: $UserPrincipalName to $($ExpirationDate.ToString('yyyy-MM-dd'))"
    if (Get-AppSetting -SettingName "DemoMode") {
        try {
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Account Expiration" -Result "Demo mode - Would set expiration date to $($ExpirationDate.ToString('yyyy-MM-dd'))" -Platform "OnPrem"
            return "[SIMULATION]: Would set account expiration for: $UserPrincipalName to $($ExpirationDate.ToString('yyyy-MM-dd'))"
        }
        catch {
            throw "Demo account expiration simulation failed: $($_.Exception.Message)"
        }
    }
    elseif ($script:UseADModule) {
        try {
            $user = Get-ADUser -Identity $UserPrincipalName -Properties AccountExpirationDate -Credential $Credential
            
            Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Account Expiration" -Result "Current expiration date: $($user.AccountExpirationDate)" -Platform "OnPrem"
            
            # Commented out actual action
            #Set-ADUser -Identity $UserPrincipalName -AccountExpirationDate $ExpirationDate -Credential $Credential
            #Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Account Expiration" -Result "New expiration date: $($ExpirationDate.ToString('yyyy-MM-dd'))" -Platform "OnPrem"
            
            return "[SIMULATION] Would set account expiration date to $($ExpirationDate.ToString('yyyy-MM-dd')) using AD Module"
        }
        catch {
            throw "Account expiration simulation failed: $($_.Exception.Message)"
        }
    }
    else {
        try {
            $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
            $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
            $user = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
            
            if ($user) {
                $userEntry = $user.GetDirectoryEntry()
                $currentExpiry = $userEntry.Properties["accountExpires"].Value
                
                Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Account Expiration" -Result "Current expiration: $currentExpiry" -Platform "OnPrem"
                
                # Commented out actual action
                #$userEntry.Properties["accountExpires"].Value = $ExpirationDate.ToFileTime()
                #$userEntry.CommitChanges()
                #Write-ActivityLog -UserEmail $UserPrincipalName -Action "Set Account Expiration" -Result "New expiration date: $($ExpirationDate.ToString('yyyy-MM-dd'))" -Platform "OnPrem"
                
                return "[SIMULATION] Would set account expiration date to $($ExpirationDate.ToString('yyyy-MM-dd')) using LDAP"
            }
            throw "User not found"
        }
        catch {
            throw "Account expiration simulation failed (LDAP): $($_.Exception.Message)"
        }
    }
}
