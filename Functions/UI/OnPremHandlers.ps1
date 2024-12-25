# OnPrem tab initialization and event handlers
function Initialize-OnPremTab {
    param (
        [System.Windows.Window]$Window,
        [System.Management.Automation.PSCredential]$Credential
    )
    
    # Get control references
    $script:chkOnPrem1 = $Window.FindName("chkOnPrem1")
    $script:chkOnPrem2 = $Window.FindName("chkOnPrem2")
    $script:chkOnPrem3 = $Window.FindName("chkOnPrem3")
    $script:btnRunOnPrem = $Window.FindName("btnRunOnPrem")
    $script:txtOnPremResults = $Window.FindName("txtOnPremResults")

    # Configure checkboxes with task descriptions
    $chkOnPrem1.Content = "Disable AD Account"
    $chkOnPrem2.Content = "Remove Group Memberships"
    $chkOnPrem3.Content = "Move to Disabled OU"

    # Add tooltip descriptions
    $chkOnPrem1.ToolTip = "Disables the user's Active Directory account"
    $chkOnPrem2.ToolTip = "Removes user from all AD groups except Domain Users"
    $chkOnPrem3.ToolTip = "Moves the user account to the Disabled Users OU"

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
    $userEmail = if ($script:UseADModule) {
        $script:SelectedUser.mail
    } else {
        $script:SelectedUser.Properties["mail"][0]
    }

    $userPrincipalName = if ($script:UseADModule) {
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
    if ($script:chkOnPrem1.IsChecked) {
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
    if ($script:chkOnPrem2.IsChecked) {
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
    if ($script:chkOnPrem3.IsChecked) {
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

    if ($script:UseADModule) {
        # Commented out actual action
        #Disable-ADAccount -Identity $UserPrincipalName -Credential $Credential
        return "[SIMULATION] Would disable account using AD Module: Account would be disabled"
    }
    else {
        $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
        $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
        $user = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
        
        if ($user) {
            # Commented out actual action
            #$userEntry = $user.GetDirectoryEntry()
            #$userEntry.InvokeSet("userAccountControl", 514)  # Disabled account flag
            #$userEntry.CommitChanges()
            return "[SIMULATION] Would disable account using LDAP: Account would be set to disabled state"
        }
        throw "User not found"
    }
}

function Remove-UserGroups {
    param (
        [string]$UserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Host "SIMULATION: Would remove group memberships for: $UserPrincipalName"

    if ($script:UseADModule) {
        $user = Get-ADUser -Identity $UserPrincipalName -Properties MemberOf -Credential $Credential
        $groups = $user.MemberOf | Where-Object { $_ -notmatch "Domain Users" }
        
        # Commented out actual action
        #foreach ($group in $groups) {
        #    Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false -Credential $Credential
        #}
        return "[SIMULATION] Would remove membership from $($groups.Count) groups using AD Module"
    }
    else {
        $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
        $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
        $user = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
        
        if ($user) {
            $userEntry = $user.GetDirectoryEntry()
            $groups = $userEntry.memberOf | Where-Object { $_ -notmatch "Domain Users" }
            
            # Commented out actual action
            #foreach ($group in $groups) {
            #    $groupEntry = [ADSI]"LDAP://$group"
            #    $groupEntry.Remove("member", $userEntry.distinguishedName[0])
            #    $groupEntry.CommitChanges()
            #}
            return "[SIMULATION] Would remove membership from $($groups.Count) groups using LDAP"
        }
        throw "User not found"
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

    if ($script:UseADModule) {
        $user = Get-ADUser -Identity $UserPrincipalName -Credential $Credential
        # Commented out actual action
        #Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledOU -Credential $Credential
        return "[SIMULATION] Would move user to $disabledOU using AD Module"
    }
    else {
        $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
        $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
        $user = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
        
        if ($user) {
            # Commented out actual action
            #$userEntry = $user.GetDirectoryEntry()
            #$userEntry.psbase.MoveTo([ADSI]"LDAP://$disabledOU")
            return "[SIMULATION] Would move user to $disabledOU using LDAP"
        }
        throw "User not found"
    }
}