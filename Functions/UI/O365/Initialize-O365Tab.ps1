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

        $settings = Get-AppSettings
        #Check if autoreply was set in Settings page
        if ($settings.AutoReplyTemplate) {
            $script:txtAutoReplyMessage.Text = $settings.AutoReplyTemplate
        }

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
        if (Get-AppSettings -SettingName "DemoMode") {
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
            if (Get-AppSettings -SettingName "DemoMode") {
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