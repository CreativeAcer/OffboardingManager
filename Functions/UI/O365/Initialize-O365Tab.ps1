function Update-O365Dropdowns {
    Write-Host "Refreshing O365 dropdowns..."
    # Add AD users to forwarding dropdown
    Update-ForwardingUserList
    # Add AD users to teamsowner dropdown
    Update-TeamsOwnerList
    # Initialize license target combobox
    Update-LicenseTargetList
}
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

        $settings = Get-AppSetting
        #Check if autoreply was set in Settings page
        if ($settings.AutoReplyTemplate) {
            $script:txtAutoReplyMessage.Text = $settings.AutoReplyTemplate
        }

        # Initially disable execution controls until connected
        $script:btnRunO365.IsEnabled = $false
        $script:chkO365Status.IsEnabled = $false
        $script:chkConvertShared.IsEnabled = $false
        $script:chkSetForwarding.IsEnabled = $false
        $script:chkAutoReply.IsEnabled = $false
        $script:chkRemoveTeams.IsEnabled = $false
        $script:chkTransferTeams.IsEnabled = $false
        $script:chkRemoveSharePoint.IsEnabled = $false
        $script:chkReassignLicense.IsEnabled = $false
        $script:chkDisableProducts.IsEnabled = $false

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
        if (Get-AppSetting -SettingName "DemoMode") {
            $script:btnConnectO365.Content = "Connect to O365 (Demo)"
            $script:O365Connected = $false

            # Add demo products
            $products = Get-O365Products
            foreach ($product in $products) {
                $script:lstProducts.Items.Add($product)
            }
        }
        else {
            $script:btnConnectO365.Content = "Connect to O365"
            $script:O365Connected = $false
            $script:lstProducts.Items.Clear()
            $script:lstProducts.Items.Add("Please connect to O365 first...")
        }
        Update-O365Dropdowns

        # Add click handler for connect button
        $script:btnConnectO365.Add_Click({
            try {
                # Call Connect-O365 function for initial connection
                Connect-O365

                # Only update products list if connection was successful
                if ($script:O365Connected) {
                    $script:lstProducts.Items.Clear()
                    $products = Get-O365Products
                    foreach ($product in $products) {
                        $script:lstProducts.Items.Add($product)
                    }
                }
            }
            catch {
                Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-ButtonClick"
                DisableO365Controls
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

# Helper function to enable controls
function EnableO365Controls {
    $script:O365Connected = $true
    $script:btnConnectO365.IsEnabled = $false
    $script:btnRunO365.IsEnabled = $true
    $script:chkO365Status.IsEnabled = $true
    $script:chkConvertShared.IsEnabled = $true
    $script:chkSetForwarding.IsEnabled = $true
    $script:chkAutoReply.IsEnabled = $true
    $script:chkRemoveTeams.IsEnabled = $true
    $script:chkTransferTeams.IsEnabled = $true
    $script:chkRemoveSharePoint.IsEnabled = $true
    $script:chkReassignLicense.IsEnabled = $true
    $script:chkDisableProducts.IsEnabled = $true
}

# Helper function to disable controls
function DisableO365Controls {
    $script:O365Connected = $false
    $script:btnConnectO365.IsEnabled = $true
    $script:btnRunO365.IsEnabled = $false
    $script:chkO365Status.IsEnabled = $false
    $script:chkConvertShared.IsEnabled = $false
    $script:chkSetForwarding.IsEnabled = $false
    $script:chkAutoReply.IsEnabled = $false
    $script:chkRemoveTeams.IsEnabled = $false
    $script:chkTransferTeams.IsEnabled = $false
    $script:chkRemoveSharePoint.IsEnabled = $false
    $script:chkReassignLicense.IsEnabled = $false
    $script:chkDisableProducts.IsEnabled = $false
}