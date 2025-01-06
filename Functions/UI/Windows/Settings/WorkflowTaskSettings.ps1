function Update-TaskSettingsPanel {
    param (
        [Parameter(Mandatory = $false)]
        [bool]$ReadOnly = $false,
        [Parameter(Mandatory = $false)]
        [System.Windows.Controls.ListBox]$TasksList = $null
    )

    Write-Host "=== Update Task Settingspanel Initialization ==="
    $script:pnlTaskSettings.Children.Clear()
    
    # Get current settings
    $settings = Get-AppSetting
    $workflowName = if ($ReadOnly) {
        $script:cmbWorkflows.SelectedItem
    } else {
        $script:cmbWorkflowList.SelectedItem
    }

    # Get task settings for the current workflow
    $taskSettings = $null
    if ($workflowName) {
        $workflow = $settings.WorkflowConfigurations.Configurations.$workflowName
        if ($workflow) {
            $taskSettings = $workflow.TaskSettings
        }
    }
    
    # Use provided TasksList or default to lstSelectedTasks
    $taskSource = if ($TasksList) { $TasksList } else { $script:lstSelectedTasks }
    
    foreach($task in $taskSource.Items) {
        # Add settings controls for each task
        $header = New-Object System.Windows.Controls.TextBlock
        $header.Text = $task.DisplayName
        $header.FontWeight = "SemiBold"
        $header.Margin = "0,10,0,5"
        $script:pnlTaskSettings.Children.Add($header)
        
        # Add specific settings based on task type
        switch($task.Id) {
            "SetForwarding" {
                $savedSettings = if ($taskSettings.SetForwarding) { $taskSettings.SetForwarding } else { @{ KeepForwardingDays = 90 } }
                Add-ForwardingSettings -Task $task -ReadOnly:$ReadOnly -Settings $savedSettings
            }
            "SetAutoReply" {
                $savedSettings = if ($taskSettings.SetAutoReply) { $taskSettings.SetAutoReply } else { @{ Message = (Get-AppSetting -SettingName "AutoReplyTemplate") } }
                Add-AutoReplySettings -Task $task -ReadOnly:$ReadOnly -Settings $savedSettings
            }
            "SetExpiration" {
                $savedSettings = if ($taskSettings.SetExpiration) { $taskSettings.SetExpiration } else { @{ DaysAfterOffboarding = 30 } }
                Add-ExpirationSettings -Task $task -ReadOnly:$ReadOnly -Settings $savedSettings
            }
        }
    }
    Write-Host "=== Update Task Settingspanel Initialization Complete ==="
}

function Add-ForwardingSettings {
    param(
        $Task,
        [bool]$ReadOnly = $false,
        $Settings
    )
    
    # Add forwarding email setting
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Forwarding Duration (days):"
    $label.Margin = "20,5,0,5"
    $script:pnlTaskSettings.Children.Add($label)

    $input = New-Object System.Windows.Controls.TextBox
    $input.Text = $Settings.KeepForwardingDays  # Use saved value
    $input.Margin = "20,0,0,10"
    $input.IsReadOnly = $ReadOnly
    $script:pnlTaskSettings.Children.Add($input)
}

function Add-AutoReplySettings {
    param(
        $Task,
        [bool]$ReadOnly = $false,
        $Settings
    )
    
    # Add auto-reply message setting
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Auto-Reply Message:"
    $label.Margin = "20,5,0,5"
    $script:pnlTaskSettings.Children.Add($label)

    $input = New-Object System.Windows.Controls.TextBox
    $input.Text = $Settings.Message  # Use saved value
    $input.TextWrapping = "Wrap"
    $input.AcceptsReturn = $true
    $input.Height = 60
    $input.Margin = "20,0,0,10"
    $input.IsReadOnly = $ReadOnly
    $script:pnlTaskSettings.Children.Add($input)
}

function Add-ExpirationSettings {
    param(
        $Task,
        [bool]$ReadOnly = $false,
        $Settings
    )
    
    # Add expiration days setting
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Days until expiration:"
    $label.Margin = "20,5,0,5"
    $script:pnlTaskSettings.Children.Add($label)

    $input = New-Object System.Windows.Controls.TextBox
    $input.Text = $Settings.DaysAfterOffboarding  # Use saved value
    $input.Margin = "20,0,0,10"
    $input.IsReadOnly = $ReadOnly
    $script:pnlTaskSettings.Children.Add($input)
}