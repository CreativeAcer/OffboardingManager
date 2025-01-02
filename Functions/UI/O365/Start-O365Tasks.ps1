function Start-O365Tasks {
    param (
        [System.Management.Automation.PSCredential]$Credential
    )
    $loadingWindow = $null
    try {
        # Capture values before dispatcher invoke
        $localSelectedUser = $script:SelectedUser
        $localDemoMode = Get-AppSettings -SettingName "DemoMode"
        $localO365Connected = $script:O365Connected
        $localUseADModule = Get-AppSettings -SettingName "UseADModule"
        $results = @()

        # Get user email first
        $userEmail = if ($localDemoMode) {
            $localSelectedUser.EmailAddress
        } else {
            if ($localUseADModule) {
                $localSelectedUser.mail
            } else {
                $localSelectedUser.Properties["mail"][0]
            }
        }

        # Show loading screen
        $loadingWindow = Show-LoadingScreen -Message "Starting O365 tasks..."
        $loadingWindow.Show()

        # Force UI update
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100

        # Create a reference type to store the state
        $stateRef = [ref]@{
            HasSelectedTasks = $false
            UIState = $null
        }

        # Get UI state and validate selections
        Get-O365UIState -StateRef $stateRef
        
        if (-not $stateRef.Value.HasSelectedTasks) {
            $script:txtO365Results.Text = "Please select at least one task to run for user $userEmail"
            if ($loadingWindow) { $loadingWindow.Close() }
            return
        }

        # Execute Tasks
        if ($stateRef.Value.UIState.CheckboxStates.O365Status) {
            $results += Get-O365Status -UserEmail $userEmail -DemoMode $localDemoMode
        }

        if ($stateRef.Value.UIState.CheckboxStates.ConvertShared -or 
            $stateRef.Value.UIState.CheckboxStates.SetForwarding -or 
            $stateRef.Value.UIState.CheckboxStates.AutoReply) {
            
            $results += Set-MailboxTasks -UserEmail $userEmail -StateRef $stateRef -LoadingWindow $loadingWindow
        }

        if ($stateRef.Value.UIState.CheckboxStates.RemoveTeams -or 
            $stateRef.Value.UIState.CheckboxStates.TransferTeams -or 
            $stateRef.Value.UIState.CheckboxStates.RemoveSharePoint) {
            
            $results += Set-TeamsTasks -UserEmail $userEmail -StateRef $stateRef -LoadingWindow $loadingWindow
        }

        if ($stateRef.Value.UIState.CheckboxStates.ReassignLicense -or 
            $stateRef.Value.UIState.CheckboxStates.DisableProducts) {
            
            $results += Set-LicenseTasks -UserEmail $userEmail -StateRef $stateRef -LoadingWindow $loadingWindow
        }

        # Update Results
        Update-O365Results -Results $results -UserEmail $userEmail -LoadingWindow $loadingWindow
    }
    catch {
        if ($loadingWindow) { $loadingWindow.Close() }
        $script:txtO365Results.Text = "Error executing O365 tasks: $($_.Exception.Message)"
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "O365-Tasks"
    }
}

function Get-O365UIState {
    param (
        [ref]$StateRef
    )

    $script:mainWindow.Dispatcher.Invoke([Action]{

        $StateRef.Value.HasSelectedTasks = $false
        if ($script:chkO365Status.IsChecked -or 
            $script:chkConvertShared.IsChecked -or 
            $script:chkSetForwarding.IsChecked -or 
            $script:chkAutoReply.IsChecked -or 
            $script:chkRemoveTeams.IsChecked -or 
            $script:chkTransferTeams.IsChecked -or 
            $script:chkRemoveSharePoint.IsChecked -or 
            $script:chkReassignLicense.IsChecked -or 
            $script:chkDisableProducts.IsChecked) {
            $StateRef.Value.HasSelectedTasks = $true
        }

        Write-Host "Has selected tasks: $($StateRef.Value.HasSelectedTasks)"

        $StateRef.Value.UIState = @{
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
}

function Update-O365Results {
    param (
        [array]$Results,
        [string]$UserEmail,
        [System.Windows.Window]$LoadingWindow
    )

    $script:mainWindow.Dispatcher.Invoke([Action]{
        if ($Results.Count -eq 0) {
            $script:txtO365Results.Text = "Please select at least one task to run for user $UserEmail"
        } else {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $resultText = @"
Execution Time: $timestamp
User: $UserEmail

Task Results:
$($Results -join "`n")
"@
            $script:txtO365Results.Text = $resultText
        }
        # Close loading window inside dispatcher
        if ($LoadingWindow) {
            $LoadingWindow.Close()
        }
    })
}