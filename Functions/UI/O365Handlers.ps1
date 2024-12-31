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
        # Capture values before dispatcher invoke (separate thread)
        $localSelectedUser = $script:SelectedUser
        $localDemoMode = $script:DemoMode
        $localO365Connected = $script:O365Connected
        $localUseADModule = $script:UseADModule
        $results = @()

        # Show loading screen
        $loadingWindow = Show-LoadingScreen -Message "Starting O365 tasks..."
        $loadingWindow.Show()

        # Force UI update
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100

        # Validate user selection
        if (-not $localSelectedUser) {
            $script:txtO365Results.Text = "Please select a user first."
            if ($loadingWindow) { $loadingWindow.Close() }
            return
        }

        if (-not ($localDemoMode -or $localO365Connected)) {
            $script:txtO365Results.Text = "Please connect to O365 first."
            if ($loadingWindow) { $loadingWindow.Close() }
            return
        }

        # Get user email
        $userEmail = if ($localDemoMode) {
            $localSelectedUser.EmailAddress
        } else {
            if ($localUseADModule) {
                $localSelectedUser.mail
            } else {
                $localSelectedUser.Properties["mail"][0]
            }
        }

        if (-not $userEmail) {
            $script:txtO365Results.Text = "Selected user does not have an email address."
            if ($loadingWindow) { $loadingWindow.Close() }
            return
        }

        # Debug logging
        Write-Host "Starting task checks..."

        # Check if any tasks are selected
        # Create a reference type to store the state
        $stateRef = [ref]@{
            HasSelectedTasks = $false
            UIState = $null
        }
        $script:mainWindow.Dispatcher.Invoke([System.Action]{
            # Debug logging for checkbox states
            Write-Host "O365Status: $($script:chkO365Status.IsChecked)"
            Write-Host "ConvertShared: $($script:chkConvertShared.IsChecked)"
            Write-Host "SetForwarding: $($script:chkSetForwarding.IsChecked)"
            Write-Host "AutoReply: $($script:chkAutoReply.IsChecked)"
            Write-Host "RemoveTeams: $($script:chkRemoveTeams.IsChecked)"
            Write-Host "TransferTeams: $($script:chkTransferTeams.IsChecked)"
            Write-Host "RemoveSharePoint: $($script:chkRemoveSharePoint.IsChecked)"
            Write-Host "ReassignLicense: $($script:chkReassignLicense.IsChecked)"
            Write-Host "DisableProducts: $($script:chkDisableProducts.IsChecked)"

            $stateRef.Value.HasSelectedTasks = $false
            if ($script:chkO365Status.IsChecked -or 
                $script:chkConvertShared.IsChecked -or 
                $script:chkSetForwarding.IsChecked -or 
                $script:chkAutoReply.IsChecked -or 
                $script:chkRemoveTeams.IsChecked -or 
                $script:chkTransferTeams.IsChecked -or 
                $script:chkRemoveSharePoint.IsChecked -or 
                $script:chkReassignLicense.IsChecked -or 
                $script:chkDisableProducts.IsChecked) {
                $stateRef.Value.HasSelectedTasks = $true
            }
            Write-Host "Has selected tasks: $($stateRef.Value.HasSelectedTasks)"
            # Store UI state
            $stateRef.Value.UIState = @{
                CheckboxStates = @{
                    O365Status = $script:chkO365Status.IsChecked
                    ConvertShared = $script:chkConvertShared.IsChecked
                    SetForwarding = $script:chkSetForwarding.IsChecked
                    AutoReply = $script:chkAutoReply.IsChecked
                    RemoveTeams = $script:chkRemoveTeams.IsChecked
                    TransferTeams = $script:chkTransferTeams.IsChecked
                    RemoveSharePoint = $script:chkRemoveSharePoint.IsChecked
                    ReassignLicense = $script:chkReassignLicense.IsChecked
                    DisableProducts = $script:chkDisableProducts.IsChecked
                }
                ForwardingEmail = $script:cmbForwardingUser.SelectedItem
                AutoReplyMessage = $script:txtAutoReplyMessage.Text
                TeamsOwner = $script:cmbTeamsOwner.SelectedItem
                LicenseTarget = $script:cmbLicenseTarget.SelectedItem
                SelectedProducts = @($script:lstProducts.SelectedItems)
            }
        })
        Write-Host "After dispatcher, hasSelectedTasks: $($stateRef.Value.HasSelectedTasks)"

        if (-not $stateRef.Value.HasSelectedTasks) {
            $script:txtO365Results.Text = "Please select at least one task to run for user $userEmail"
            if ($loadingWindow) { $loadingWindow.Close() }
            return
        }

        # Execute O365 Status Check
        if ($stateRef.Value.UIState.CheckboxStates.O365Status) {
            Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Checking O365 status..."
            if ($localDemoMode) {
                $o365User = Get-MockO365User -UserPrincipalName $userEmail
                $results += "O365 Status for $($o365User.DisplayName) (Demo):`n"
                $results += "- User Principal Name: $($o365User.UserPrincipalName)`n"
                $results += "- Email: $($o365User.Mail)`n"
                $results += "- Account Enabled: $($o365User.AccountEnabled)`n"
                $results += "- Licenses: Office 365 E5`n"
            } else {
                try {
                    $o365User = Get-MgUser -Filter "mail eq '$userEmail'" -Property displayName, userPrincipalName, accountEnabled, mail
                    $results += "O365 Status for $($o365User.DisplayName):`n"
                    $results += "- User Principal Name: $($o365User.UserPrincipalName)`n"
                    $results += "- Email: $($o365User.Mail)`n"
                    $results += "- Account Enabled: $($o365User.AccountEnabled)`n"
                } catch {
                    $results += "Error retrieving O365 status: $($_.Exception.Message)`n"
                }
            }
        }

        # Execute Mailbox Management Tasks
        if ($stateRef.Value.UIState.CheckboxStates.ConvertShared -or 
            $stateRef.Value.UIState.CheckboxStates.SetForwarding -or 
            $stateRef.Value.UIState.CheckboxStates.AutoReply) {
            
            Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Updating O365 Mailbox..."
            $mailboxResult = Set-O365MailboxManagement `
                -UserPrincipalName $userEmail `
                -ConvertToShared $stateRef.Value.UIState.CheckboxStates.ConvertShared `
                -SetForwarding $stateRef.Value.UIState.CheckboxStates.SetForwarding `
                -ForwardingEmail $stateRef.Value.UIState.ForwardingEmail `
                -SetAutoReply $stateRef.Value.UIState.CheckboxStates.AutoReply `
                -AutoReplyMessage $stateRef.Value.UIState.AutoReplyMessage
            
            $results += $mailboxResult + "`n"
        }

        # Execute Teams Management Tasks
        if ($stateRef.Value.UIState.CheckboxStates.RemoveTeams -or 
            $stateRef.Value.UIState.CheckboxStates.TransferTeams -or 
            $stateRef.Value.UIState.CheckboxStates.RemoveSharePoint) {
            
            Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Updating O365 Teams..."
            $teamsResult = Set-TeamsManagement `
                -UserPrincipalName $userEmail `
                -RemoveFromTeams $stateRef.Value.UIState.CheckboxStates.RemoveTeams `
                -TransferOwnership $stateRef.Value.UIState.CheckboxStates.TransferTeams `
                -NewOwner $stateRef.Value.UIState.TeamsOwner `
                -RemoveSharePoint $stateRef.Value.UIState.CheckboxStates.RemoveSharePoint
            
            $results += $teamsResult + "`n"
        }

        # Execute License Management Tasks
        if ($stateRef.Value.UIState.CheckboxStates.ReassignLicense -or 
            $stateRef.Value.UIState.CheckboxStates.DisableProducts) {
            
            Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Updating O365 Licensing..."
            $licenseResult = Set-LicenseManagement `
                -UserPrincipalName $userEmail `
                -ReassignLicenses $stateRef.Value.UIState.CheckboxStates.ReassignLicense `
                -TargetUser $stateRef.Value.UIState.LicenseTarget `
                -DisableProducts $stateRef.Value.UIState.CheckboxStates.DisableProducts `
                -ProductsToDisable $stateRef.Value.UIState.SelectedProducts

            $results += $licenseResult + "`n"
        }

        # Update UI with results
        $script:mainWindow.Dispatcher.Invoke([System.Action]{
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $resultText = @"
Execution Time: $timestamp
User: $userEmail

Task Results:
$($results -join "`n")
"@
            $script:txtO365Results.Text = $resultText
        })
    }
    catch {
        $script:txtO365Results.Text = "Error executing O365 tasks: $($_.Exception.Message)"
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-Tasks"
    }
    finally {
        if ($loadingWindow) {
            $loadingWindow.Close()
        }
    }
}