function Connect-O365 {
    try {
        if (Get-AppSetting -SettingName "DemoMode") {
            Enable-O365Controls
            $script:O365Connected = $true
            $script:txtO365Results.Text = "Connected to O365 (Demo Mode)"
            return
        }

        $script:txtO365Results.Text = "Checking Microsoft Graph module..."
        $script:O365Connected = $false

        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
            $script:btnConnectO365.IsEnabled = $false
            $script:txtO365Results.Text = "Installing Microsoft Graph module... This may take a few minutes.`nPlease wait..."

            # Create counters in script scope
            $script:elapsedSeconds = 0
            
            # Create runspace pool
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 1)
            $runspacePool.Open()

            # Create PowerShell instance for async work
            $powershell = [powershell]::Create().AddScript({
                Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
                return "Installation completed"
            })
            $powershell.RunspacePool = $runspacePool

            # Create timer for UI updates
            $timer = New-Object System.Windows.Threading.DispatcherTimer
            $timer.Interval = [TimeSpan]::FromSeconds(1)
            
            $timer.Add_Tick({
                $script:elapsedSeconds++
                $script:txtO365Results.Dispatcher.Invoke({
                    $script:txtO365Results.Text = "Installing Microsoft Graph module...`nThis may take a few minutes.`nTime elapsed: $script:elapsedSeconds seconds"
                })
            })
            $timer.Start()

            # Start async operation
            $asyncResult = $powershell.BeginInvoke()

            # Create a checker timer
            $checkerTimer = New-Object System.Windows.Threading.DispatcherTimer
            $checkerTimer.Interval = [TimeSpan]::FromSeconds(1)
            
            $checkerTimer.Add_Tick({
                if ($asyncResult.IsCompleted) {
                    $checkerTimer.Stop()
                    $timer.Stop()
                    
                    try {
                        $result = $powershell.EndInvoke($asyncResult)
                        
                        $script:txtO365Results.Dispatcher.Invoke({
                            $script:txtO365Results.Text = "Microsoft Graph module installed successfully."
                        })
                        
                        # Continue with module import and connection
                        $script:txtO365Results.Dispatcher.Invoke({
                            $script:txtO365Results.Text = "Importing Microsoft Graph module..."
                        })
                        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

                        $script:txtO365Results.Dispatcher.Invoke({
                            $script:txtO365Results.Text = "Connecting to Microsoft Graph...`nPlease watch for a popup browser window for authentication."
                        })
                        Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All" -ErrorAction Stop

                        $script:txtO365Results.Dispatcher.Invoke({
                            $script:txtO365Results.Text = "Successfully connected to Microsoft Graph!`nReady to perform O365 operations."
                        })
                        $script:O365Connected = $true
                        Enable-O365Controls
                    }
                    catch {
                        $script:O365Connected = $false
                        Disable-O365Controls
                        $script:btnConnectO365.IsEnabled = $true
                        $script:txtO365Results.Dispatcher.Invoke({
                            $script:txtO365Results.Text = "Error: $($_.Exception.Message)"
                        })
                        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-Connection"
                    }
                    finally {
                        $powershell.Dispose()
                        $runspacePool.Close()
                        $runspacePool.Dispose()
                    }
                }
            })
            $checkerTimer.Start()
        }
        else {
            # If module exists, proceed with connection
            $script:txtO365Results.Text = "Importing Microsoft Graph module..."
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

            $script:txtO365Results.Text = "Connecting to Microsoft Graph...`nPlease watch for a popup browser window for authentication."
            Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All" -ErrorAction Stop

            $script:txtO365Results.Text = "Successfully connected to Microsoft Graph!`nReady to perform O365 operations."
            $script:O365Connected = $true
            Enable-O365Controls
        }
    }
    catch {
        $script:O365Connected = $false
        Disable-O365Controls
        $script:btnConnectO365.IsEnabled = $true
        $script:txtO365Results.Text = "Error connecting to Microsoft Graph: $($_.Exception.Message) - Please install the module manually"
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