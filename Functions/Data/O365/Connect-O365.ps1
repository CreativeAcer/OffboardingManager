# Custom object for UI management
function New-UIManager {
    param(
        $ResultsBox,
        $ConnectButton,
        $Controls
    )

    $uiManager = [PSCustomObject]@{
        ResultsBox = $ResultsBox
        ConnectButton = $ConnectButton
        Controls = $Controls
        Dispatcher = $ResultsBox.Dispatcher
        IsConnected = $false
    }

    # Add methods using Add-Member
    Add-Member -InputObject $uiManager -MemberType ScriptMethod -Name "UpdateStatus" -Value {
        param($Message)
        if ($null -ne $this.Dispatcher) {
            $this.Dispatcher.Invoke(
                [Action]{
                    $this.ResultsBox.Text = $Message
                }, 
                [System.Windows.Threading.DispatcherPriority]::Normal
            )
        }
    }

    Add-Member -InputObject $uiManager -MemberType ScriptMethod -Name "EnableControls" -Value {
        $this.IsConnected = $true
        if ($null -ne $this.Dispatcher) {
            $this.Dispatcher.Invoke([Action]{
                $this.ConnectButton.IsEnabled = $false
                foreach ($control in $this.Controls.Values) {
                    $control.IsEnabled = $true
                }
            }, [System.Windows.Threading.DispatcherPriority]::Normal)
        }
    }

    Add-Member -InputObject $uiManager -MemberType ScriptMethod -Name "DisableControls" -Value {
        $this.IsConnected = $false
        if ($null -ne $this.Dispatcher) {
            $this.Dispatcher.Invoke([Action]{
                $this.ConnectButton.IsEnabled = $true
                foreach ($control in $this.Controls.Values) {
                    $control.IsEnabled = $false
                }
            }, [System.Windows.Threading.DispatcherPriority]::Normal)
        }
    }

    return $uiManager
}

# Module installation function
function Install-O365Module {
    param(
        $UI,
        $InstallLogPath
    )

    # Create synchronized hashtable for cross-thread communication
    $sync = [hashtable]::Synchronized(@{
        Messages = [System.Collections.ArrayList]::new()
        IsComplete = $false
        Error = $null
    })

    # Create runspace pool
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 1)
    $runspacePool.Open()

    # Create PowerShell instance
    $powershell = [powershell]::Create().AddScript({
        param($LogPath, $SyncHash)

        try {
            function Write-Progress {
                param($Message)
                $SyncHash.Messages.Add($Message) | Out-Null
            }

            # Check and install NuGet
            Write-Progress "Checking NuGet provider..."
            $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
            if (-not $nugetProvider -or $nugetProvider.Version -lt [version]"2.8.5.201") {
                Write-Progress "Installing NuGet provider..."
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
                Write-Progress "NuGet provider installed successfully"
            }

            # Install Microsoft.Graph
            Write-Progress "Starting Microsoft.Graph module installation..."
            $verboseOutput = Install-Module Microsoft.Graph -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser -Verbose 4>&1 *>&1

            foreach($line in $verboseOutput) {
                $message = if ($line -is [System.Management.Automation.VerboseRecord]) {
                    $line.Message
                } elseif ($line -is [string]) {
                    $line
                } else {
                    $line | Out-String
                }
                if ($message) {
                    Write-Progress $message.Trim()
                }
            }

            # Verify installation
            Write-Progress "Verifying installation..."
            if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
                throw "Module installation verification failed"
            }

            Write-Progress "Installation completed successfully"
            $SyncHash.IsComplete = $true
        }
        catch {
            $SyncHash.Error = $_.Exception.Message
            throw
        }
    }).AddArgument($InstallLogPath).AddArgument($sync)

    $powershell.RunspacePool = $runspacePool

    # Start async operation
    $asyncResult = $powershell.BeginInvoke()

    # Create timer for UI updates
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)

    # Track elapsed time
    $startTime = Get-Date

    $timer.Add_Tick({
        if ($sync.Messages.Count -gt 0) {
            $messages = $sync.Messages.ToArray()
            $elapsedTime = [Math]::Round(((Get-Date) - $startTime).TotalSeconds)
            $statusMessage = "Installing Microsoft Graph module...`nTime elapsed: $elapsedTime seconds`n`nLatest status:`n$($messages[-[Math]::Min(5, $messages.Count)..-1] -join "`n")"
            $UI.UpdateStatus($statusMessage)
        }

        if ($asyncResult.IsCompleted) {
            $timer.Stop()
            try {
                $null = $powershell.EndInvoke($asyncResult)
                
                if ($sync.Error) {
                    throw $sync.Error
                }

                return $true
            }
            catch {
                throw
            }
            finally {
                $powershell.Dispose()
                $runspacePool.Close()
                $runspacePool.Dispose()
            }
        }
    })

    $timer.Start()
    return $timer
}

# Main connection function
function Connect-O365 {
    try {
        Write-Host "Starting Connect-O365 function..."
        if (Get-AppSetting -SettingName "DemoMode") {
            Enable-O365Controls
            $script:O365Connected = $true
            $script:txtO365Results.Text = "Connected to O365 (Demo Mode)"
            return
        }
        # Validate UI controls
        if ($null -eq $script:txtO365Results -or 
            $null -eq $script:btnConnectO365) {
            throw "UI controls not properly initialized"
        }

        # Check if already connected
        try {
            $context = Get-MgContext
            if ($null -ne $context) {
                Write-Host "Already connected to Microsoft Graph"
                $script:txtO365Results.Text = "Successfully connected to Microsoft Graph!`nReady to perform O365 operations."
                $script:O365Connected = $true
                Enable-O365Controls
                return
            }
        }
        catch {
            Write-Host "Not connected to Microsoft Graph, proceeding with connection..."
        }

        # Create controls hashtable
        $controls = @{
            'O365Status' = $script:chkO365Status
            'RunO365' = $script:btnRunO365
            'ConvertShared' = $script:chkConvertShared
            'SetForwarding' = $script:chkSetForwarding
            'AutoReply' = $script:chkAutoReply
            'RemoveTeams' = $script:chkRemoveTeams
            'TransferTeams' = $script:chkTransferTeams
            'TeamsOwner' = $script:cmbTeamsOwner
            'RemoveSharePoint' = $script:chkRemoveSharePoint
            'ReassignLicense' = $script:chkReassignLicense
            'DisableProducts' = $script:chkDisableProducts
        }

        # Create UI manager
        $ui = New-UIManager -ResultsBox $script:txtO365Results -ConnectButton $script:btnConnectO365 -Controls $controls

        Write-Host "Checking if Microsoft Graph module is available..."
        $ui.UpdateStatus("Checking Microsoft Graph module...")

        if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
            Write-Host "Module not found, starting installation..."
            $ui.DisableControls()
            
            try {
                # Start installation
                $timer = Install-O365Module -UI $ui -InstallLogPath (Join-Path $env:TEMP "MGInstall.log")
                
                # Wait for completion
                $timeout = New-TimeSpan -Minutes 10
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                while ($timer.IsEnabled -and $sw.Elapsed -lt $timeout) {
                    [System.Windows.Forms.Application]::DoEvents()
                    Start-Sleep -Milliseconds 100
                }
                
                if ($timer.IsEnabled) {
                    $timer.Stop()
                    throw "Installation timed out after 10 minutes"
                }
            }
            finally {
                $installLogPath = Join-Path $env:TEMP "MGInstall.log"
                if (Test-Path $installLogPath) {
                    Remove-Item $installLogPath -Force -ErrorAction SilentlyContinue
                }
            }
        }

        # Import module and connect
        $ui.UpdateStatus("Importing Microsoft Graph module...")
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

        $ui.UpdateStatus("Connecting to Microsoft Graph...`nPlease watch for a popup browser window for authentication.")
        $authResult = Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All", "Team.ReadWrite.All", "Group.ReadWrite.All", "Sites.FullControl.All" -ErrorAction Stop

        $script:O365Connected = $true
        $ui.UpdateStatus("Successfully connected to Microsoft Graph!`nReady to perform O365 operations.")
        $ui.EnableControls()
    }
    catch {
        Write-Host "Error in Connect-O365: $($_.Exception.Message)"
        $script:O365Connected = $false
        if ($null -ne $ui) {
            $ui.DisableControls()
            $ui.UpdateStatus("Error: $($_.Exception.Message)")
        }
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-Connection"
    }
}