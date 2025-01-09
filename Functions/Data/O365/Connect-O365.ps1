function Connect-O365 {
    try {
        if (Get-AppSetting -SettingName "DemoMode") {
            Enable-O365Controls
            $script:O365Connected = $true
            $script:txtO365Results.Text = "Connected to O365 (Demo Mode)"
            return
        }
        # If Microsoft Graph module is not installed
        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
            $script:btnConnectO365.IsEnabled = $false
            $script:txtO365Results.Text = "Installing Microsoft Graph module... This may take a few minutes.`nPlease wait..."

            # Check if async operation is in progress
            if ($script:asyncOperationInProgress) {
                $script:txtO365Results.Text = "Please wait for the current operation to complete."
                return
            }

            # Create counters in script scope
            $script:elapsedSeconds = 0

            # Set flag for async operation in progress
            $script:asyncOperationInProgress = $true

            # Create runspace pool
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 1)
            $runspacePool.Open()

            # Create PowerShell instance for async work
            $powershell = [powershell]::Create().AddScript({
                # Enable verbose output
                $VerbosePreference = 'Continue'
                
                # Create a temporary log file
                $logFile = Join-Path $env:TEMP "MGInstallLog.txt"
                
                # Clear existing log file if it exists
                if (Test-Path $logFile) {
                    Remove-Item $logFile -Force
                }
                
                # Log the start of the process
                "Starting installation process at $(Get-Date)" | Out-File $logFile
                
                # Check and install NuGet provider if needed
                "Checking NuGet provider..." | Out-File $logFile -Append
                try {
                    $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
                    if (-not $nugetProvider -or $nugetProvider.Version -lt [version]"2.8.5.201") {
                        "Installing NuGet provider..." | Out-File $logFile -Append
                        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
                        "NuGet provider installed successfully" | Out-File $logFile -Append
                    } else {
                        "NuGet provider already installed" | Out-File $logFile -Append
                    }
                }
                catch {
                    "Error installing NuGet provider: $($_.Exception.Message)" | Out-File $logFile -Append
                    throw
                }
                
                "Beginning Microsoft Graph module installation..." | Out-File $logFile -Append
                
                # Capture the installation process with verbose output
                try {
                    $result = Install-Module Microsoft.Graph -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop -Verbose 4>&1 | 
                        ForEach-Object {
                            $_.Message | Out-File -Append $logFile
                            $_.Message
                        }
                    "Installation completed successfully" | Out-File $logFile -Append
                }
                catch {
                    "Installation failed: $($_.Exception.Message)" | Out-File $logFile -Append
                    throw
                }
                
                return @{
                    Status = "Installation completed"
                    Log = Get-Content $logFile
                }
            })
            $powershell.RunspacePool = $runspacePool

            # Start async operation
            $asyncResult = $powershell.BeginInvoke()

            # Timer for UI updates
            $timer = New-Object System.Windows.Threading.DispatcherTimer
            $timer.Interval = [TimeSpan]::FromSeconds(1)
            
            $timer.Add_Tick({
                $script:elapsedSeconds++
                try {
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
                            $script:txtO365Results.Dispatcher.Invoke({
                                $script:txtO365Results.Text = "Error: $($_.Exception.Message)"
                            })
                        }
                        finally {
                            # Set flag to false when done
                            $script:asyncOperationInProgress = $false
                            # Cleanup
                            $powershell.Dispose()
                            $runspacePool.Close()
                            $runspacePool.Dispose()
                        }
                        return
                    }

                    # If not completed, update the status
                    $logFile = Join-Path $env:TEMP "MGInstallLog.txt"
                    if (Test-Path $logFile) {
                        $lastLines = Get-Content $logFile -Tail 5
                        $script:txtO365Results.Dispatcher.Invoke({
                            $script:txtO365Results.Text = "Installing Microsoft Graph module...`nThis may take a few minutes.`nTime elapsed: $script:elapsedSeconds seconds`n`nLatest status:`n$($lastLines -join "`n")"
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
                } catch {
                    # If we can't read the log, just show the timer
                    $script:txtO365Results.Dispatcher.Invoke({
                        $script:txtO365Results.Text = "Installing Microsoft Graph module...`nThis may take a few minutes.`nTime elapsed: $script:elapsedSeconds seconds"
                    })
                }
            })
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
        $script:txtO365Results.Text = "Error connecting to Microsoft Graph: $($_.Exception.Message) - Please install the module manually"
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-Connection"
    }
}
#Dispatchers to perform update on main thread again
function Enable-O365Controls {
    $script:O365Connected = $true
    $script:btnConnectO365.Dispatcher.Invoke({
        $script:btnConnectO365.IsEnabled = $false
    })
    $script:chkO365Status.Dispatcher.Invoke({
        $script:chkO365Status.IsEnabled = $true
    })
    $script:btnRunO365.Dispatcher.Invoke({
        $script:btnRunO365.IsEnabled = $true
    })
    $script:chkConvertShared.Dispatcher.Invoke({
        $script:chkConvertShared.IsEnabled = $true
    })
    $script:chkSetForwarding.Dispatcher.Invoke({
        $script:chkSetForwarding.IsEnabled = $true
    })
    $script:chkAutoReply.Dispatcher.Invoke({
        $script:chkAutoReply.IsEnabled = $true
    })
    $script:chkRemoveTeams.Dispatcher.Invoke({
        $script:chkRemoveTeams.IsEnabled = $true
    })
    $script:chkTransferTeams.Dispatcher.Invoke({
        $script:chkTransferTeams.IsEnabled = $true
    })
    $script:cmbTeamsOwner.Dispatcher.Invoke({
        $script:cmbTeamsOwner.IsEnabled = $true
    })
    $script:chkRemoveSharePoint.Dispatcher.Invoke({
        $script:chkRemoveSharePoint.IsEnabled = $true
    })
    $script:chkReassignLicense.Dispatcher.Invoke({
        $script:chkReassignLicense.IsEnabled = $true
    })
    $script:chkDisableProducts.Dispatcher.Invoke({
        $script:chkDisableProducts.IsEnabled = $true
    })
}

function Disable-O365Controls {
    $script:O365Connected = $false
    $script:btnRunO365.Dispatcher.Invoke({
        $script:btnRunO365.IsEnabled = $false
    })
    $script:chkO365Status.Dispatcher.Invoke({
        $script:chkO365Status.IsEnabled = $false
    })
    $script:chkConvertShared.Dispatcher.Invoke({
        $script:chkConvertShared.IsEnabled = $false
    })
    $script:chkSetForwarding.Dispatcher.Invoke({
        $script:chkSetForwarding.IsEnabled = $false
    })
    $script:chkAutoReply.Dispatcher.Invoke({
        $script:chkAutoReply.IsEnabled = $false
    })
    $script:chkRemoveTeams.Dispatcher.Invoke({
        $script:chkRemoveTeams.IsEnabled = $false
    })
    $script:chkTransferTeams.Dispatcher.Invoke({
        $script:chkTransferTeams.IsEnabled = $false
    })
    $script:cmbTeamsOwner.Dispatcher.Invoke({
        $script:cmbTeamsOwner.IsEnabled = $false
    })
    $script:chkRemoveSharePoint.Dispatcher.Invoke({
        $script:chkRemoveSharePoint.IsEnabled = $false
    })
    $script:chkReassignLicense.Dispatcher.Invoke({
        $script:chkReassignLicense.IsEnabled = $false
    })
    $script:chkDisableProducts.Dispatcher.Invoke({
        $script:chkDisableProducts.IsEnabled = $false
    })
}

