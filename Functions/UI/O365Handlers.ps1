function Initialize-O365Tab {
    param (
        [System.Windows.Window]$Window,
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        Write-Host "Initializing O365 Tab controls"
        
        # Get control references
        $script:btnConnectO365 = $Window.FindName("btnConnectO365")
        $script:btnRunO365 = $Window.FindName("btnRunO365")
        $script:chkO365Status = $Window.FindName("chkO365Status")
        $script:txtO365Results = $Window.FindName("txtO365Results")
        #Mailboxmanagement
        $script:chkConvertShared = $Window.FindName("chkConvertShared")
        $script:chkSetForwarding = $Window.FindName("chkSetForwarding")
        $script:chkAutoReply = $Window.FindName("chkAutoReply")
        $script:cmbForwardingUser = $Window.FindName("cmbForwardingUser")
        $script:txtAutoReplyMessage = $Window.FindName("txtAutoReplyMessage")
        #Teams & SharePoint
        $script:chkRemoveTeams = $Window.FindName("chkRemoveTeams")
        $script:chkTransferTeams = $Window.FindName("chkTransferTeams")
        $script:cmbTeamsOwner = $Window.FindName("cmbTeamsOwner")
        $script:chkRemoveSharePoint = $Window.FindName("chkRemoveSharePoint")
        #Licensemanagement
        $script:chkReassignLicense = $Window.FindName("chkReassignLicense")
        $script:cmbLicenseTarget = $Window.FindName("cmbLicenseTarget")
        $script:chkDisableProducts = $Window.FindName("chkDisableProducts")
        $script:lstProducts = $Window.FindName("lstProducts")
        $script:mainWindow = $Window

        # Initially disable execution controls until connected
        $script:btnRunO365.IsEnabled = $false
        $script:chkO365Status.IsEnabled = $false

        if ($null -eq $script:btnConnectO365) {
            throw "Failed to find btnConnectO365 control"
        }
        if ($null -eq $script:btnRunO365) {
            throw "Failed to find btnRunO365 control"
        }
        if ($null -eq $script:chkO365Status) {
            throw "Failed to find chkO365Status control"
        }
        if ($null -eq $script:txtO365Results) {
            throw "Failed to find txtO365Results control"
        }

        # Configure checkbox tooltips
        $script:chkO365Status.ToolTip = "Retrieves the current O365 status for the selected user"

        Write-Host "Adding click handlers for O365 buttons"

        # Configure UI based on demo mode
        if ($script:DemoMode) {
            $script:btnConnectO365.Content = "Connect to O365 (Demo)"
            $script:O365Connected = $false
        }
        # Add AD users to forwarding dropdown
        Update-ForwardingUserList
        # Add AD users to teamsowner dropdown
        Update-TeamsOwnerList
        # Initialize license target combobox
        Update-LicenseTargetList

        # Initialize products listbox
        $products = Get-O365Products
        foreach ($product in $products) {
            $script:lstProducts.Items.Add($product)
        }

        # Add click handler for connect button
        $script:btnConnectO365.Add_Click({
            if ($script:DemoMode) {
                $script:O365Connected = $true
                $script:btnConnectO365.IsEnabled = $false
                $script:chkO365Status.IsEnabled = $true
                $script:btnRunO365.IsEnabled = $true
                $script:chkConvertShared.IsEnabled = $true
                $script:chkSetForwarding.IsEnabled = $true
                $script:chkAutoReply.IsEnabled = $true
                $script:chkRemoveTeams.IsEnabled = $true
                $script:chkTransferTeams.IsEnabled = $true
                $script:cmbTeamsOwner.IsEnabled = $true
                $script:chkRemoveSharePoint.IsEnabled = $true
                $script:chkReassignLicense.IsEnabled = $true
                $script:chkDisableProducts.IsEnabled = $true
                $script:txtO365Results.Text = "Connected to O365 (Demo Mode)"
                return
            }
            try {
                $script:txtO365Results.Text = "Checking Microsoft Graph module..."

                # Check if Microsoft.Graph module is installed
                if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
                    $script:txtO365Results.Text = "Installing Microsoft Graph module..."
                    Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
                }

                # Import the module
                $script:txtO365Results.Text = "Importing Microsoft Graph module..."
                Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

                $script:txtO365Results.Text = "Connecting to Microsoft Graph...`nPlease watch for a popup browser window for authentication."
                
                # Connect using interactive login
                Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All" -ErrorAction Stop

                $script:txtO365Results.Text = "Successfully connected to Microsoft Graph!`nReady to perform O365 operations."
                
                # Enable execution controls after successful connection
                $script:btnRunO365.IsEnabled = $true
                $script:chkO365Status.IsEnabled = $true
                $script:btnConnectO365.IsEnabled = $false
                $script:chkConvertShared.IsEnabled = $true
                $script:chkSetForwarding.IsEnabled = $true
                $script:chkAutoReply.IsEnabled = $true
                $script:chkRemoveTeams.IsEnabled = $true
                $script:chkTransferTeams.IsEnabled = $true
                $script:cmbTeamsOwner.IsEnabled = $true
                $script:chkRemoveSharePoint.IsEnabled = $true
                $script:chkReassignLicense.IsEnabled = $true
                $script:chkDisableProducts.IsEnabled = $true
                $script:O365Connected = $true
            }
            catch {
                $script:txtO365Results.Text = "Error connecting to Microsoft Graph: $($_.Exception.Message)"
                Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-Connection"
                
                # Ensure controls remain disabled on error
                $script:btnRunO365.IsEnabled = $false
                $script:chkO365Status.IsEnabled = $false
                $script:chkConvertShared.IsEnabled = $false
                $script:chkSetForwarding.IsEnabled = $false
                $script:chkAutoReply.IsEnabled = $false
                $script:txtForwardingEmail.IsEnabled = $false
                $script:chkRemoveTeams.IsEnabled = $false
                $script:chkTransferTeams.IsEnabled = $false
                $script:cmbTeamsOwner.IsEnabled = $false
                $script:chkRemoveSharePoint.IsEnabled = $false
                $script:chkReassignLicense.IsEnabled = $false
                $script:chkDisableProducts.IsEnabled = $false
                $script:O365Connected = $false
            }
        })

        # Add click handler for execute button
        $script:btnRunO365.Add_Click({
            Start-O365Tasks -Credential $Credential
        })

        Write-Host "O365 Tab initialization completed"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-TabInit"
        throw
    }
}

function Update-ForwardingUserList {
    $script:cmbForwardingUser.Items.Clear()
    
    if ($script:DemoMode) {
        # Add mock users from our demo data
        $mockUsers = Get-MockUsers
        foreach($user in $mockUsers) {
            $script:cmbForwardingUser.Items.Add($user.UserPrincipalName)
        }
    }
    else {
        # Add users from the main list
        if ($script:UseADModule) {
            foreach($item in $script:Users) {
                $script:cmbForwardingUser.Items.Add($item.UserPrincipalName)
            }
        } else {
            foreach($item in $script:Users) {
                if ($item.Properties["userPrincipalName"]) {
                    $script:cmbForwardingUser.Items.Add($item.Properties["userPrincipalName"][0])
                }
                
            }
        }
        
        
    }
}

function Update-TeamsOwnerList {
    $script:cmbTeamsOwner.Items.Clear()
    
    if ($script:DemoMode) {
        $mockUsers = Get-MockUsers
        foreach($user in $mockUsers) {
            $script:cmbTeamsOwner.Items.Add($user.UserPrincipalName)
        }
    }
    else {
        # Add users from the main list
        if ($script:UseADModule) {
            foreach($item in $script:Users) {
                $script:cmbTeamsOwner.Items.Add($item.UserPrincipalName)
            }
        } else {
            foreach($item in $script:Users) {
                if ($item.Properties["userPrincipalName"]) {
                    $script:cmbTeamsOwner.Items.Add($item.Properties["userPrincipalName"][0])
                }
                
            }
        }
    }
}

function Update-LicenseTargetList {
    $script:cmbLicenseTarget.Items.Clear()
    
    if ($script:DemoMode) {
        $mockUsers = Get-MockUsers
        foreach($user in $mockUsers) {
            $script:cmbLicenseTarget.Items.Add($user.UserPrincipalName)
        }
    }
    else {
        foreach($item in $script:lstUsers.Items) {
            $script:cmbLicenseTarget.Items.Add($item)
        }
    }
}

function Start-O365Tasks {
    param (
        [System.Management.Automation.PSCredential]$Credential
    )

    try {
        # Validate user selection
        if (-not $script:SelectedUser) {
            $script:txtO365Results.Text = "Please select a user first."
            return
        }

        if (-not ($script:DemoMode -or $script:O365Connected)) {
            $script:txtO365Results.Text = "Please connect to O365 first."
            return
        }

        # Get user details
        $userEmail = if ($script:DemoMode) {
            $script:SelectedUser.EmailAddress
        }
        else {
            if ($script:UseADModule) {
                $script:SelectedUser.mail
            } else {
                $script:SelectedUser.Properties["mail"][0]
            }
        }

        if (-not $userEmail) {
            $script:txtO365Results.Text = "Selected user does not have an email address."
            return
        }

        $results = @()

        # Execute selected tasks
        if ($script:chkO365Status.IsChecked) {
            if ($script:DemoMode) {
                $o365User = Get-MockO365User -UserPrincipalName $userEmail
                $results += "O365 Status for $($o365User.DisplayName) (Demo):`n"
                $results += "- User Principal Name: $($o365User.UserPrincipalName)`n"
                $results += "- Email: $($o365User.Mail)`n"
                $results += "- Account Enabled: $($o365User.AccountEnabled)`n"
                $results += "- Licenses: Office 365 E5`n"
            }
            else {
                try {
                    $o365User = Get-MgUser -Filter "mail eq '$userEmail'" -Property displayName, userPrincipalName, accountEnabled, mail
                    $results += "O365 Status for $($o365User.DisplayName):`n"
                    $results += "- User Principal Name: $($o365User.UserPrincipalName)`n"
                    $results += "- Email: $($o365User.Mail)`n"
                    $results += "- Account Enabled: $($o365User.AccountEnabled)`n"
                }
                catch {
                    $results += "Error retrieving O365 status: $($_.Exception.Message)`n"
                }
            }
            
        }

        if ($script:chkConvertShared.IsChecked -or $script:chkSetForwarding.IsChecked -or $script:chkAutoReply.IsChecked) {
            $mailboxResult = Set-O365MailboxManagement `
                -UserPrincipalName $userEmail `
                -ConvertToShared $script:chkConvertShared.IsChecked `
                -SetForwarding $script:chkSetForwarding.IsChecked `
                -ForwardingEmail $script:txtForwardingEmail.Text `
                -SetAutoReply $script:chkAutoReply.IsChecked `
                -AutoReplyMessage $script:txtAutoReplyMessage.Text
        
            $results += $mailboxResult + "`n"
        }

        if ($script:chkRemoveTeams.IsChecked -or $script:chkTransferTeams.IsChecked -or $script:chkRemoveSharePoint.IsChecked) {
            $teamsResult = Set-TeamsManagement `
                -UserPrincipalName $userEmail `
                -RemoveFromTeams $script:chkRemoveTeams.IsChecked `
                -TransferOwnership $script:chkTransferTeams.IsChecked `
                -NewOwner $script:cmbTeamsOwner.SelectedItem `
                -RemoveSharePoint $script:chkRemoveSharePoint.IsChecked
        
            $results += $teamsResult + "`n"
        }

        if ($script:chkReassignLicense.IsChecked -or $script:chkDisableProducts.IsChecked) {
            $licenseResult = Set-LicenseManagement `
                -UserPrincipalName $userEmail `
                -ReassignLicenses $script:chkReassignLicense.IsChecked `
                -TargetUser $script:cmbLicenseTarget.SelectedItem `
                -DisableProducts $script:chkDisableProducts.IsChecked `
                -ProductsToDisable ($script:lstProducts.SelectedItems | ForEach-Object { $_ })

            $results += $licenseResult + "`n"
        }

        if ($results.Count -eq 0) {
            $script:txtO365Results.Text = "Please select at least one task to run for user $userEmail"
        } else {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $resultText = @"
Execution Time: $timestamp
User: $userEmail

Task Results:
$($results -join "`n")
"@
            $script:txtO365Results.Text = $resultText
        }
    }
    catch {
        $script:txtO365Results.Text = "Error executing O365 tasks: $($_.Exception.Message)"
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-Tasks"
    }
}