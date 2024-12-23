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
        
        # Add click handler for connect button
        $script:btnConnectO365.Add_Click({
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
            }
            catch {
                $script:txtO365Results.Text = "Error connecting to Microsoft Graph: $($_.Exception.Message)"
                Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-Connection"
                
                # Ensure controls remain disabled on error
                $script:btnRunO365.IsEnabled = $false
                $script:chkO365Status.IsEnabled = $false
                $script:btnConnectO365.IsEnabled = $true
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

        # Get user details
        $userEmail = if ($script:UseADModule) {
            $script:SelectedUser.mail
        } else {
            $script:SelectedUser.Properties["mail"][0]
        }

        if (-not $userEmail) {
            $script:txtO365Results.Text = "Selected user does not have an email address."
            return
        }

        $results = @()

        # Execute selected tasks
        if ($script:chkO365Status.IsChecked) {
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