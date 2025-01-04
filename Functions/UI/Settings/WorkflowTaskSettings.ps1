function Update-TaskSettingsPanel {
    $script:pnlTaskSettings.Children.Clear()
    
    foreach($task in $script:lstSelectedTasks.Items) {
        # Add settings controls for each task
        $header = New-Object System.Windows.Controls.TextBlock
        $header.Text = $task.DisplayName
        $header.FontWeight = "SemiBold"
        $header.Margin = "0,10,0,5"
        $script:pnlTaskSettings.Children.Add($header)
        
        # Add specific settings based on task type
        switch($task.Id) {
            "SetForwarding" {
                Add-ForwardingSettings -Task $task
            }
            "SetAutoReply" {
                Add-AutoReplySettings -Task $task
            }
            "SetExpiration" {
                Add-ExpirationSettings -Task $task
            }
        }
    }
}

function Add-ForwardingSettings {
    param($Task)
    
    # Add forwarding email setting
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Forwarding Duration (days):"
    $label.Margin = "20,5,0,5"
    $script:pnlTaskSettings.Children.Add($label)

    $input = New-Object System.Windows.Controls.TextBox
    $input.Text = "90"  # Default value
    $input.Margin = "20,0,0,10"
    $script:pnlTaskSettings.Children.Add($input)
}

function Add-AutoReplySettings {
    param($Task)
    
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
    $script:pnlTaskSettings.Children.Add($input)
}

function Add-ExpirationSettings {
    param($Task)
    
    # Add expiration days setting
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Days until expiration:"
    $label.Margin = "20,5,0,5"
    $script:pnlTaskSettings.Children.Add($label)

    $input = New-Object System.Windows.Controls.TextBox
    $input.Text = "30"  # Default value
    $input.Margin = "20,0,0,10"
    $script:pnlTaskSettings.Children.Add($input)
}