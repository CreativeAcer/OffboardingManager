function Initialize-WorkflowTab {
    param (
        [System.Windows.Window]$Window,
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        Write-Host "Initializing Workflow Tab controls"

        # Store window reference
        $script:mainWindow = $Window
        
        # Get control references
        $script:cmbWorkflows = $Window.FindName("cmbWorkflows")
        $script:lstWorkflowTasks = $Window.FindName("lstWorkflowTasks")
        $script:pnlTaskSettings = $Window.FindName("pnlTaskSettings")
        $script:btnRunWorkflow = $Window.FindName("btnRunWorkflow")
        $script:txtWorkflowResults = $Window.FindName("txtWorkflowResults")

        # Load available workflows
        Update-WorkflowDropdowns -Window $Window -DropdownNames @("cmbWorkflows")

        # Add event handlers
        $script:cmbWorkflows.Add_SelectionChanged({
            if ($script:cmbWorkflows.SelectedItem) {
                Load-SelectedWorkflow -Window $script:mainWindow `
                     -WorkflowDropdownName "cmbWorkflows" `
                     -TaskListName "lstWorkflowTasks"
                $script:btnRunWorkflow.IsEnabled = $true
            }
        })

        $script:btnRunWorkflow.Add_Click({
            Start-SelectedWorkflow -Credential $Credential
        })

        $script:btnRunWorkflow.IsEnabled = $false  # Enable only when workflow is selected
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Workflow-TabInit"
        throw
    }
}


function Update-WorkflowTasksList {
    try {
        if ($script:cmbWorkflows.SelectedItem) {
            $settings = Get-AppSetting
            $workflowName = $script:cmbWorkflows.SelectedItem.ToString()
            
            # Use the same function as settings window
            Load-SelectedWorkflow -Window $script:mainWindow `
                     -WorkflowDropdownName "cmbWorkflows" `
                     -TaskListName "lstWorkflowTasks"
            $script:btnRunWorkflow.IsEnabled = $true
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-WorkflowTasksList"
    }
}

function Update-TaskSettings {
    try {
        $script:pnlTaskSettings.Children.Clear()
        
        $selectedWorkflow = Get-WorkflowConfigurations[$script:cmbWorkflows.SelectedItem]
        if($selectedWorkflow -and $selectedWorkflow.TaskSettings) {
            foreach($taskId in $selectedWorkflow.TaskSettings.Keys) {
                $settings = $selectedWorkflow.TaskSettings[$taskId]
                $task = $script:WorkflowTasks.OnPrem + $script:WorkflowTasks.O365 |
                        Where-Object { $_.Id -eq $taskId } |
                        Select-Object -First 1
                
                if($task) {
                    # Add task settings header
                    $header = New-Object System.Windows.Controls.TextBlock
                    $header.Text = $task.DisplayName
                    $header.FontWeight = "SemiBold"
                    $header.Margin = "0,10,0,5"
                    $script:pnlTaskSettings.Children.Add($header)
                    
                    # Add settings controls
                    foreach($setting in $settings.GetEnumerator()) {
                        $label = New-Object System.Windows.Controls.TextBlock
                        $label.Text = $setting.Key
                        $label.Margin = "20,5,0,0"
                        $script:pnlTaskSettings.Children.Add($label)
                        
                        $value = New-Object System.Windows.Controls.TextBox
                        $value.Text = $setting.Value
                        $value.IsReadOnly = $true
                        $value.Margin = "20,0,0,5"
                        $script:pnlTaskSettings.Children.Add($value)
                    }
                }
            }
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-TaskSettings"
    }
}

function Start-SelectedWorkflow {
    param (
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        if (-not $script:SelectedUser) {
            [System.Windows.MessageBox]::Show(
                "Please select a user first.",
                "Warning",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            )
            return
        }

        $results = Start-OffboardingWorkflow -UserPrincipalName $script:SelectedUser.UserPrincipalName -Credential $Credential
        $script:txtWorkflowResults.Text = $results -join "`n"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Start-SelectedWorkflow"
        [System.Windows.MessageBox]::Show(
            $_.Exception.Message,
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
    }
}