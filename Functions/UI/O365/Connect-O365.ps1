function Connect-O365 {
    try {
        if (Get-AppSetting -SettingName "DemoMode") {
            Enable-O365Controls
            $script:txtO365Results.Text = "Connected to O365 (Demo Mode)"
            return
        }

        $script:txtO365Results.Text = "Checking Microsoft Graph module..."

        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
            $script:txtO365Results.Text = "Installing Microsoft Graph module..."
            Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
        }

        $script:txtO365Results.Text = "Importing Microsoft Graph module..."
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

        $script:txtO365Results.Text = "Connecting to Microsoft Graph...`nPlease watch for a popup browser window for authentication."
        
        Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All" -ErrorAction Stop

        $script:txtO365Results.Text = "Successfully connected to Microsoft Graph!`nReady to perform O365 operations."
        
        Enable-O365Controls
    }
    catch {
        Disable-O365Controls
        $script:txtO365Results.Text = "Error connecting to Microsoft Graph: $($_.Exception.Message)"
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-Connection"
    }
}

function Enable-O365Controls {
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
}

function Disable-O365Controls {
    $script:O365Connected = $false
    $script:btnRunO365.IsEnabled = $false
    $script:chkO365Status.IsEnabled = $false
    $script:chkConvertShared.IsEnabled = $false
    $script:chkSetForwarding.IsEnabled = $false
    $script:chkAutoReply.IsEnabled = $false
    $script:chkRemoveTeams.IsEnabled = $false
    $script:chkTransferTeams.IsEnabled = $false
    $script:cmbTeamsOwner.IsEnabled = $false
    $script:chkRemoveSharePoint.IsEnabled = $false
    $script:chkReassignLicense.IsEnabled = $false
    $script:chkDisableProducts.IsEnabled = $false
}