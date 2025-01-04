function Initialize-WorkflowSettingsTab {
    param (
        [System.Windows.Window]$Window
    )

    try {
        Write-Host "=== Workflow Settings Tab Initialization ==="

        # Get control references
        Write-Host "Getting control references..."
        $script:cmbWorkflowList = $Window.FindName("cmbWorkflowList")
        if (-not $script:cmbWorkflowList) {
            Write-Host "ERROR: cmbWorkflowList not found!"
        }
        
        Write-Host "Initializing Workflow Settings Tab controls"
        # Get control references
        $script:btnNewWorkflow = $Window.FindName("btnNewWorkflow")
        $script:btnDeleteWorkflow = $Window.FindName("btnDeleteWorkflow")
        $script:lstAvailableTasks = $Window.FindName("lstAvailableTasks")
        $script:lstSelectedTasks = $Window.FindName("lstSelectedTasks")
        $script:btnAddTask = $Window.FindName("btnAddTask")
        $script:btnRemoveTask = $Window.FindName("btnRemoveTask")
        $script:btnMoveUp = $Window.FindName("btnMoveUp")
        $script:btnMoveDown = $Window.FindName("btnMoveDown")
        $script:txtWorkflowName = $Window.FindName("txtWorkflowName")
        $script:txtWorkflowDescription = $Window.FindName("txtWorkflowDescription")
        $script:pnlTaskSettings = $Window.FindName("pnlTaskSettings")
        $script:btnSaveWorkflow = $Window.FindName("btnSaveWorkflow")

        Write-Host "Loading available tasks..."
        Load-AvailableTasks

        Write-Host "Loading settings..."
        $settings = Get-AppSetting
        Write-Host "Current workflow configurations:"
        Write-Host ($settings.WorkflowConfigurations | ConvertTo-Json -Depth 5)

        if (-not $settings.WorkflowConfigurations) {
            Write-Host "Creating default workflow configuration..."
            $defaultWorkflow = @{
                LastUsed = "Default"
                Configurations = @{
                    "Default" = @{
                        Name = "Default"
                        Description = "Standard offboarding workflow"
                        EnabledTasks = @()
                        TaskSettings = @{
                            SetExpiration = @{
                                DaysAfterOffboarding = 30
                            }
                            SetForwarding = @{
                                KeepForwardingDays = 90
                            }
                        }
                    }
                }
            }

            $settings | Add-Member -NotePropertyName "WorkflowConfigurations" -NotePropertyValue $defaultWorkflow -Force
            Update-AppSettings -NewSettings $settings
        }

        Write-Host "Updating workflow list..."
        $script:cmbWorkflowList.Items.Clear()
        
        # Handle PSCustomObject or Hashtable configurations
        $configurations = $settings.WorkflowConfigurations.Configurations
        if ($configurations -is [PSCustomObject]) {
            $configProperties = $configurations.PSObject.Properties
            foreach($config in $configProperties) {
                Write-Host "Adding workflow: $($config.Value.Name)"
                $script:cmbWorkflowList.Items.Add($config.Value.Name)
            }
        } else {
            foreach($workflow in $configurations.GetEnumerator()) {
                Write-Host "Adding workflow: $($workflow.Value.Name)"
                $script:cmbWorkflowList.Items.Add($workflow.Value.Name)
            }
        }

        if ($settings.WorkflowConfigurations.LastUsed) {
            Write-Host "Setting selected workflow to: $($settings.WorkflowConfigurations.LastUsed)"
            $script:cmbWorkflowList.SelectedItem = $settings.WorkflowConfigurations.LastUsed
        }

        Write-Host "Setting up event handlers..."
        # Add event handlers
        $script:cmbWorkflowList.Add_SelectionChanged({
            Write-Host "Workflow selection changed to: $($script:cmbWorkflowList.SelectedItem)"
            Load-SelectedWorkflow
        })

        $script:btnNewWorkflow.Add_Click({
            New-Workflow
        })

        $script:btnDeleteWorkflow.Add_Click({
            Remove-CurrentWorkflow
        })

        $script:btnAddTask.Add_Click({
            Add-SelectedTask
        })

        $script:btnRemoveTask.Add_Click({
            Remove-SelectedTask
        })

        $script:btnMoveUp.Add_Click({
            Move-TaskUp
        })

        $script:btnMoveDown.Add_Click({
            Move-TaskDown
        })

        $script:btnSaveWorkflow.Add_Click({
            Save-CurrentWorkflow
        })

        Write-Host "=== Workflow Settings Tab Initialization Complete ==="
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "WorkflowSettings-TabInit"
        throw
    }
}

function Load-AvailableTasks {
    $script:lstAvailableTasks.Items.Clear()

    Write-Host "Loading OnPrem tasks:"
    foreach ($task in $script:WorkflowTasks.OnPrem) {
        $taskObject = New-Object PSObject -property @{
            Id = $task.Id
            DisplayName = $task.DisplayName
            Description = $task.Description
            FunctionName = $task.FunctionName
            Platform = $task.Platform
            RequiredParams = $task.RequiredParams
            OptionalParams = $task.OptionalParams
        }

        # Add the taskObject to the ListBox
        $script:lstAvailableTasks.Items.Add($taskObject)
    }

    Write-Host "Loading O365 tasks:"
    foreach ($task in $script:WorkflowTasks.O365) {
        $taskObject = New-Object PSObject -property @{
            Id = $task.Id
            DisplayName = $task.DisplayName
            Description = $task.Description
            FunctionName = $task.FunctionName
            Platform = $task.Platform
            RequiredParams = $task.RequiredParams
            OptionalParams = $task.OptionalParams
        }

        # Add the taskObject to the ListBox
        $script:lstAvailableTasks.Items.Add($taskObject)
    }
}

function Update-WorkflowList {
    try {
        $script:cmbWorkflowList.Items.Clear()
        
        $settings = Get-AppSetting
        Write-Host "Current workflow configurations:"
        Write-Host ($settings.WorkflowConfigurations | ConvertTo-Json -Depth 5)

        if ($settings.WorkflowConfigurations -and 
            $settings.WorkflowConfigurations.Configurations) {
            
            # Convert to hashtable if it's a PSCustomObject
            $configurations = $settings.WorkflowConfigurations.Configurations
            if ($configurations -is [PSCustomObject]) {
                $configurations = @($configurations.PSObject.Properties) | 
                    ForEach-Object { $_.Value }
            }

            foreach($workflow in $configurations) {
                Write-Host "Adding workflow: $($workflow.Name)"
                $script:cmbWorkflowList.Items.Add($workflow.Name)
            }
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-WorkflowList"
        throw
    }
}

function Load-SelectedWorkflow {
    try {
        if ($script:cmbWorkflowList.SelectedItem) {
            $settings = Get-AppSetting
            $workflowName = $script:cmbWorkflowList.SelectedItem.ToString()
            
            # Convert to hashtable if it's a PSCustomObject
            $configurations = $settings.WorkflowConfigurations.Configurations
            if ($configurations -is [PSCustomObject]) {
                $workflow = $configurations.PSObject.Properties |
                    Where-Object { $_.Name -eq $workflowName } |
                    Select-Object -ExpandProperty Value
            } else {
                $workflow = $configurations[$workflowName]
            }

            if ($workflow) {
                $script:txtWorkflowName.Text = $workflow.Name
                $script:txtWorkflowDescription.Text = $workflow.Description

                # Clear and reload selected tasks
                $script:lstSelectedTasks.Items.Clear()
                foreach($taskId in $workflow.EnabledTasks) {
                    $task = $script:WorkflowTasks.OnPrem + $script:WorkflowTasks.O365 |
                        Where-Object { $_.Id -eq $taskId } |
                        Select-Object -First 1

                    if ($task) {
                        # Create PSObject for the task
                        $taskObject = New-Object PSObject -Property @{
                            Id = $task.Id
                            DisplayName = $task.DisplayName
                            Description = $task.Description
                            FunctionName = $task.FunctionName
                            Platform = $task.Platform
                            RequiredParams = $task.RequiredParams
                            OptionalParams = $task.OptionalParams
                        }
                        $script:lstSelectedTasks.Items.Add($taskObject)
                    }
                }
            }
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Load-SelectedWorkflow"
    }
}

function New-Workflow {
    $script:txtWorkflowName.Text = "New Workflow"
    $script:txtWorkflowDescription.Text = ""
    $script:lstSelectedTasks.Items.Clear()
    $script:pnlTaskSettings.Children.Clear()
}

function Remove-CurrentWorkflow {
    if ($script:cmbWorkflowList.SelectedItem) {
        $result = [System.Windows.MessageBox]::Show(
            "Are you sure you want to delete this workflow?",
            "Confirm Delete",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )

        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            Remove-WorkflowConfiguration -Name $script:cmbWorkflowList.SelectedItem
            Update-WorkflowList
        }
    }
}

function Add-SelectedTask {
    if ($script:lstAvailableTasks.SelectedItem) {
        $selectedTask = $script:lstAvailableTasks.SelectedItem

        # Create new PSObject for selected tasks list
        $taskObject = New-Object PSObject -Property @{
            Id = $selectedTask.Id
            DisplayName = $selectedTask.DisplayName
            Description = $selectedTask.Description
            FunctionName = $selectedTask.FunctionName
            Platform = $selectedTask.Platform
            RequiredParams = $selectedTask.RequiredParams
            OptionalParams = $selectedTask.OptionalParams
        }

        $script:lstSelectedTasks.Items.Add($taskObject)
        Update-TaskSettingsPanel
    }
}

function Remove-SelectedTask {
    if ($script:lstSelectedTasks.SelectedItem) {
        $script:lstSelectedTasks.Items.Remove($script:lstSelectedTasks.SelectedItem)
        Update-TaskSettingsPanel
    }
}

function Move-TaskUp {
    if ($script:lstSelectedTasks.SelectedIndex -gt 0) {
        $currentIndex = $script:lstSelectedTasks.SelectedIndex
        $task = $script:lstSelectedTasks.SelectedItem

        # Create new list of items to preserve order
        $items = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
        
        # Copy all items to the new list, swapping the selected item with the one above it
        for ($i = 0; $i -lt $script:lstSelectedTasks.Items.Count; $i++) {
            if ($i -eq $currentIndex - 1) {
                $items.Add($task)
            }
            elseif ($i -eq $currentIndex) {
                $items.Add($script:lstSelectedTasks.Items[$currentIndex - 1])
            }
            else {
                $items.Add($script:lstSelectedTasks.Items[$i])
            }
        }

        # Clear and repopulate the listbox
        $script:lstSelectedTasks.Items.Clear()
        foreach ($item in $items) {
            $script:lstSelectedTasks.Items.Add($item)
        }

        $script:lstSelectedTasks.SelectedIndex = $currentIndex - 1
        Update-TaskSettingsPanel
    }
}

function Move-TaskDown {
    if ($script:lstSelectedTasks.SelectedIndex -lt $script:lstSelectedTasks.Items.Count - 1) {
        $currentIndex = $script:lstSelectedTasks.SelectedIndex
        $task = $script:lstSelectedTasks.SelectedItem

        # Create new list of items to preserve order
        $items = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
        
        # Copy all items to the new list, swapping the selected item with the one below it
        for ($i = 0; $i -lt $script:lstSelectedTasks.Items.Count; $i++) {
            if ($i -eq $currentIndex) {
                $items.Add($script:lstSelectedTasks.Items[$currentIndex + 1])
            }
            elseif ($i -eq $currentIndex + 1) {
                $items.Add($task)
            }
            else {
                $items.Add($script:lstSelectedTasks.Items[$i])
            }
        }

        # Clear and repopulate the listbox
        $script:lstSelectedTasks.Items.Clear()
        foreach ($item in $items) {
            $script:lstSelectedTasks.Items.Add($item)
        }

        $script:lstSelectedTasks.SelectedIndex = $currentIndex + 1
        Update-TaskSettingsPanel
    }
}

function Save-CurrentWorkflow {
    try {
        $enabledTasks = @()
        foreach($task in $script:lstSelectedTasks.Items) {
            $enabledTasks += $task.Id
        }

        # Gather task settings from UI
        $taskSettings = @{}
        # Add code here to gather settings from pnlTaskSettings controls

        Save-WorkflowConfiguration `
            -Name $script:txtWorkflowName.Text `
            -Description $script:txtWorkflowDescription.Text `
            -EnabledTasks $enabledTasks `
            -TaskSettings $taskSettings

        Update-WorkflowList
        [System.Windows.MessageBox]::Show(
            "Workflow saved successfully",
            "Success",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        )
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Save-CurrentWorkflow"
        [System.Windows.MessageBox]::Show(
            $_.Exception.Message,
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
    }
}

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
            "SetExpiration" {
                Add-ExpirationSettings $task
            }
            "SetForwarding" {
                Add-ForwardingSettings $task
            }
            # Add more task-specific settings as needed
        }
    }
}