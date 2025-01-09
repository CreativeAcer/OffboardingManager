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
            $script:txtO365Results.Text = "Installing Microsoft Graph module... This may take a few minutes."

            # Create counters in script scope
            $script:elapsedSeconds = 0
            $script:currentStatus = "Starting installation process..."
            
            # Create runspace pool
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 1)
            $runspacePool.Open()

            # Create PowerShell instance for async work
            $powershell = [powershell]::Create().AddScript({
                # Enable verbose output
                $VerbosePreference = 'Continue'
                $messages = @()

                try {
                    # Check and install NuGet provider if needed
                    $messages += "Checking NuGet provider..."
                    $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
                    if (-not $nugetProvider -or $nugetProvider.Version -lt [version]"2.8.5.201") {
                        $messages += "Installing NuGet provider..."
                        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
                        $messages += "NuGet provider installed successfully"
                    } else {
                        $messages += "NuGet provider already installed"
                    }

                    $messages += "Beginning Microsoft Graph module installation..."
                    Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser -SkipPublisherCheck -ErrorAction Stop -Verbose 4>&1 | 
                        ForEach-Object { $messages += $_.Message }
                    
                    $messages += "Installation completed successfully"
                    return $messages
                }
                catch {
                    $messages += "Error: $($_.Exception.Message)"
                    throw
                }
            })
            $powershell.RunspacePool = $runspacePool

            # Start async operation
            $asyncResult = $powershell.BeginInvoke()

            # Create timer for UI updates
            $timer = New-Object System.Windows.Threading.DispatcherTimer
            $timer.Interval = [TimeSpan]::FromSeconds(1)
            
            $timer.Add_Tick({
                $script:elapsedSeconds++
                
                # Check if the operation is completed
                if ($asyncResult.IsCompleted) {
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
                    }
                    finally {
                        $powershell.Dispose()
                        $runspacePool.Close()
                        $runspacePool.Dispose()
                    }
                    return
                }

                # Get the latest messages
                try {
                    $messages = $powershell.Streams.Verbose.ReadAll()
                    if ($messages) {
                        $latestMessages = $messages | Select-Object -Last 3
                        $script:txtO365Results.Dispatcher.Invoke({
                            $script:txtO365Results.Text = "Installing Microsoft Graph module...`nTime elapsed: $script:elapsedSeconds seconds`n`nLatest status:`n$($latestMessages -join "`n")"
                        })
                    } else {
                        $script:txtO365Results.Dispatcher.Invoke({
                            $script:txtO365Results.Text = "Installing Microsoft Graph module...`nTime elapsed: $script:elapsedSeconds seconds"
                        })
                    }
                } catch {
                    $script:txtO365Results.Dispatcher.Invoke({
                        $script:txtO365Results.Text = "Installing Microsoft Graph module...`nTime elapsed: $script:elapsedSeconds seconds"
                    })
                }

                # Add timeout check
                if ($script:elapsedSeconds -gt 600) { # 10 minutes timeout
                    $timer.Stop()
                    $powershell.Stop()
                    
                    $script:txtO365Results.Dispatcher.Invoke({
                        $script:txtO365Results.Text = "Installation timed out after 10 minutes.`nPlease try installing manually using:`n`nInstall-Module Microsoft.Graph -Force -Verbose"
                    })
                    
                    $script:btnConnectO365.IsEnabled = $true
                    
                    # Cleanup
                    $powershell.Dispose()
                    $runspacePool.Close()
                    $runspacePool.Dispose()
                }
            })

            # Start the timer
            $timer.Start()
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