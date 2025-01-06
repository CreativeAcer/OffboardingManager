function Update-TaskSettingsPanel {
    param (
        [Parameter(Mandatory = $false)]
        [bool]$ReadOnly = $false,  # Add parameter to control if settings are editable
        [Parameter(Mandatory = $false)]
        [System.Windows.Controls.ListBox]$TasksList = $null  # Allow passing in different list box
    )

    Write-Host "=== Update Task Settingspanel Initialization ==="
    $script:pnlTaskSettings.Children.Clear()
    
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
                Add-ForwardingSettings -Task $task -ReadOnly:$ReadOnly
            }
            "SetAutoReply" {
                Add-AutoReplySettings -Task $task -ReadOnly:$ReadOnly
            }
            "SetExpiration" {
                Add-ExpirationSettings -Task $task -ReadOnly:$ReadOnly
            }
            # Add more task-specific settings as needed
        }
    }
    Write-Host "=== Update Task Settingspanel Initialization Complete ==="
}

function Add-ForwardingSettings {
    param(
        $Task,
        [bool]$ReadOnly = $false
    )
    
    # Add forwarding email setting
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Forwarding Duration (days):"
    $label.Margin = "20,5,0,5"
    $script:pnlTaskSettings.Children.Add($label)

    $input = New-Object System.Windows.Controls.TextBox
    $input.Text = "90"  # Default value
    $input.Margin = "20,0,0,10"
    $input.IsReadOnly = $ReadOnly
    $script:pnlTaskSettings.Children.Add($input)
}

function Add-AutoReplySettings {
    param(
        $Task,
        [bool]$ReadOnly = $false
    )
    
    # Add auto-reply message setting
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Auto-Reply Message:"
    $label.Margin = "20,5,0,5"
    $script:pnlTaskSettings.Children.Add($label)

    $input = New-Object System.Windows.Controls.TextBox
    $input.Text = Get-AppSetting -SettingName "AutoReplyTemplate"
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
        [bool]$ReadOnly = $false
    )
    
    # Add expiration days setting
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Days until expiration:"
    $label.Margin = "20,5,0,5"
    $script:pnlTaskSettings.Children.Add($label)

    $input = New-Object System.Windows.Controls.TextBox
    $input.Text = "30"  # Default value
    $input.Margin = "20,0,0,10"
    $input.IsReadOnly = $ReadOnly
    $script:pnlTaskSettings.Children.Add($input)
}