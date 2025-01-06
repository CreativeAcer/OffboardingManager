function Initialize-WorkflowSettingsTab {
    param (
        [Parameter(Mandatory = $true)]
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

        # Store window reference
        $script:settingsWindow = $Window
        
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
            Write-Host "Loading initial workflow settings..."
            Load-SelectedWorkflow -Window $Window `
                     -WorkflowDropdownName "cmbWorkflowList" `
                     -TaskListName "lstSelectedTasks" `
                     -AdditionalControls @{
                         "txtWorkflowName" = "Name"
                         "txtWorkflowDescription" = "Description"
                     }
        }

        Write-Host "Setting up event handlers..."
        # Add event handlers
        $script:cmbWorkflowList.Add_SelectionChanged({
            Write-Host "Workflow selection changed to: $($script:cmbWorkflowList.SelectedItem)"
            Load-SelectedWorkflow -Window $script:settingsWindow `
                     -WorkflowDropdownName "cmbWorkflowList" `
                     -TaskListName "lstSelectedTasks" `
                     -AdditionalControls @{
                         "txtWorkflowName" = "Name"
                         "txtWorkflowDescription" = "Description"
                     }
        })

        $script:btnNewWorkflow.Add_Click({
            New-Workflow
        })

        $script:btnDeleteWorkflow.Add_Click({
            try {
                Remove-CurrentWorkflow -Window $script:settingsWindow
            }
            catch {
                [System.Windows.MessageBox]::Show(
                    "Failed to remove workflow: $($_.Exception.Message)",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                )
            }
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
            try {
                Save-CurrentWorkflow -Window $script:settingsWindow
            }
            catch {
                [System.Windows.MessageBox]::Show(
                    "Failed to save workflow: $($_.Exception.Message)",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                )
            }
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

function Load-SelectedWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Window]$Window,
        [string]$WorkflowDropdownName,
        [string]$TaskListName,
        [hashtable]$AdditionalControls = @{}  # For optional controls like description, name textboxes etc.
    )
    try {
        # Get the dropdown and task list controls
        $workflowDropdown = $Window.FindName($WorkflowDropdownName)
        $taskList = $Window.FindName($TaskListName)

        if ($workflowDropdown.SelectedItem) {
            $settings = Get-AppSetting
            $workflowName = $workflowDropdown.SelectedItem.ToString()
            
            # Get workflow configuration
            $configurations = $settings.WorkflowConfigurations.Configurations
            $workflow = $null

            if ($configurations -is [PSCustomObject]) {
                $workflow = $configurations.PSObject.Properties |
                    Where-Object { $_.Name -eq $workflowName } |
                    Select-Object -ExpandProperty Value
            } else {
                $workflow = $configurations[$workflowName]
            }

            if ($workflow) {
                # Handle additional controls if provided
                foreach ($controlName in $AdditionalControls.Keys) {
                    $control = $Window.FindName($controlName)
                    if ($control) {
                        $propertyName = $AdditionalControls[$controlName]
                        $control.Text = $workflow.$propertyName
                    }
                }

                # Clear and reload tasks
                $taskList.Items.Clear()

                # Convert EnabledTasks to ArrayList if needed
                $enabledTasks = [System.Collections.ArrayList]@($workflow.EnabledTasks)

                foreach($taskId in $enabledTasks) {
                    $task = $script:WorkflowTasks.OnPrem + $script:WorkflowTasks.O365 |
                        Where-Object { $_.Id -eq $taskId } |
                        Select-Object -First 1

                    if ($task) {
                        # Create proper PSObject for the task
                        $taskObject = New-Object PSObject -Property @{
                            Id = $task.Id
                            DisplayName = $task.DisplayName
                            Description = $task.Description
                            FunctionName = $task.FunctionName
                            Platform = $task.Platform
                            RequiredParams = $task.RequiredParams
                            OptionalParams = $task.OptionalParams
                        }
                        $taskList.Items.Add($taskObject)
                    }
                }
                Update-TaskSettingsPanel -ReadOnly $false
            }
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Load-SelectedWorkflow"
    }
}

function New-Workflow {
    try {
        # Clear all fields
        $script:txtWorkflowName.Text = "New Workflow"
        $script:txtWorkflowDescription.Text = ""
        $script:lstSelectedTasks.Items.Clear()
        $script:pnlTaskSettings.Children.Clear()

        # Select the name text box for immediate editing
        $script:txtWorkflowName.Focus()
        $script:txtWorkflowName.SelectAll()
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "New-Workflow"
    }
}

function Remove-CurrentWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Window]$Window
    )
    try {
        if ($script:cmbWorkflowList.SelectedItem) {
            $workflowName = $script:cmbWorkflowList.SelectedItem.ToString()
            
            $result = [System.Windows.MessageBox]::Show(
                "Are you sure you want to delete the workflow '$workflowName'?",
                "Confirm Delete",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            
            if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                $settings = Get-AppSetting

                # Create new configurations hashtable
                $newConfigurations = @{}
                
                # Copy all workflows except the one being deleted
                if ($settings.WorkflowConfigurations.Configurations -is [PSCustomObject]) {
                    foreach($prop in $settings.WorkflowConfigurations.Configurations.PSObject.Properties) {
                        if ($prop.Name -ne $workflowName) {
                            $newConfigurations[$prop.Name] = $prop.Value
                        }
                    }
                } else {
                    foreach($key in $settings.WorkflowConfigurations.Configurations.Keys) {
                        if ($key -ne $workflowName) {
                            $newConfigurations[$key] = $settings.WorkflowConfigurations.Configurations[$key]
                        }
                    }
                }

                # Set LastUsed to first available workflow if current is being deleted
                $newLastUsed = $settings.WorkflowConfigurations.LastUsed
                if ($newLastUsed -eq $workflowName -and $newConfigurations.Count -gt 0) {
                    $newLastUsed = $newConfigurations.Keys | Select-Object -First 1
                }
                elseif ($newConfigurations.Count -eq 0) {
                    $newLastUsed = ""
                }

                # Create complete new settings
                $newSettings = @{
                    DemoMode = $settings.DemoMode
                    UseADModule = $settings.UseADModule
                    DefaultDomain = $settings.DefaultDomain
                    AutoReplyTemplate = $settings.AutoReplyTemplate
                    LoggingEnabled = $settings.LoggingEnabled
                    LogPath = $settings.LogPath
                    LicenseTemplates = $settings.LicenseTemplates
                    WorkflowConfigurations = @{
                        LastUsed = $newLastUsed
                        Configurations = $newConfigurations
                    }
                }

                # Update settings
                Update-AppSettings -NewSettings $newSettings

                # Refresh workflow list
                Update-WorkflowDropdowns -Window $Window -DropdownNames @("cmbWorkflowList")
            }
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Remove-CurrentWorkflow"
        throw
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
        Update-TaskSettingsPanel -ReadOnly $false
    }
}

function Remove-SelectedTask {
    if ($script:lstSelectedTasks.SelectedItem) {
        $script:lstSelectedTasks.Items.Remove($script:lstSelectedTasks.SelectedItem)
        Update-TaskSettingsPanel -ReadOnly $false
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
        Update-TaskSettingsPanel -ReadOnly $false
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
        Update-TaskSettingsPanel -ReadOnly $false
    }
}

function Save-CurrentWorkflow {
    param (
        [System.Windows.Window]$Window
    )
    try {
        $settings = Get-AppSetting
        Write-Host "Starting save workflow..."

        # Get enabled tasks
        $enabledTasks = [System.Collections.ArrayList]@()
        foreach($task in $script:lstSelectedTasks.Items) {
            Write-Host "Adding task to enabled tasks: $($task.Id)"
            $enabledTasks.Add($task.Id) | Out-Null
        }

        # Capture task settings from the panel
        $taskSettings = @{}

        # Loop through selected tasks to ensure we capture settings for each enabled task
        foreach($task in $script:lstSelectedTasks.Items) {
            Write-Host "Processing task: $($task.Id) - $($task.DisplayName)"
            
            # Find the TextBox for this task
            $taskHeader = $script:pnlTaskSettings.Children | 
                Where-Object { $_ -is [System.Windows.Controls.TextBlock] -and $_.Text -eq $task.DisplayName }

            if ($taskHeader) {
                Write-Host "Found header for task: $($taskHeader.Text)"
                
                # Get all controls after this header until the next header or end
                $controls = $script:pnlTaskSettings.Children | 
                    Where-Object { $script:pnlTaskSettings.Children.IndexOf($_) -gt $script:pnlTaskSettings.Children.IndexOf($taskHeader) }

                foreach ($control in $controls) {
                    if ($control -is [System.Windows.Controls.TextBox]) {
                        Write-Host "Found TextBox with value: $($control.Text) for task: $($task.Id)"
                        
                        switch ($task.Id) {
                            "SetForwarding" {
                                $taskSettings[$task.Id] = @{
                                    KeepForwardingDays = [int]$control.Text
                                }
                                Write-Host "Saved forwarding days: $($control.Text)"
                            }
                            "SetAutoReply" {
                                $taskSettings[$task.Id] = @{
                                    Message = $control.Text
                                }
                                Write-Host "Saved auto-reply message"
                            }
                            "SetExpiration" {
                                $taskSettings[$task.Id] = @{
                                    DaysAfterOffboarding = [int]$control.Text
                                }
                                Write-Host "Saved expiration days: $($control.Text)"
                            }
                        }
                        break  # Only process the first TextBox after the header
                    }
                }
            }
        }

        Write-Host "Final task settings:"
        Write-Host ($taskSettings | ConvertTo-Json -Depth 5)

        # Create new workflow configuration
        $newWorkflow = @{
            Name = $script:txtWorkflowName.Text
            Description = $script:txtWorkflowDescription.Text
            EnabledTasks = $enabledTasks.ToArray()
            TaskSettings = $taskSettings
            LastModified = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }

        # Create new configurations hashtable
        $newConfigurations = @{}
        
        # Handle PSCustomObject configurations
        $configurations = $settings.WorkflowConfigurations.Configurations
        if ($configurations -is [PSCustomObject]) {
            foreach($prop in $configurations.PSObject.Properties) {
                if ($prop.Name -ne $newWorkflow.Name) {
                    $newConfigurations[$prop.Name] = $prop.Value
                }
            }
        } else {
            foreach($key in $configurations.Keys) {
                if ($key -ne $newWorkflow.Name) {
                    $newConfigurations[$key] = $configurations[$key]
                }
            }
        }

        # Add the new workflow
        $newConfigurations[$newWorkflow.Name] = $newWorkflow

        # Create new settings object
        $newSettings = @{
            DemoMode = $settings.DemoMode
            UseADModule = $settings.UseADModule
            DefaultDomain = $settings.DefaultDomain
            AutoReplyTemplate = $settings.AutoReplyTemplate
            LoggingEnabled = $settings.LoggingEnabled
            LogPath = $settings.LogPath
            LicenseTemplates = $settings.LicenseTemplates
            WorkflowConfigurations = @{
                LastUsed = $newWorkflow.Name
                Configurations = $newConfigurations
            }
        }

        # Update settings
        Update-AppSettings -NewSettings $newSettings

        # Refresh workflow list
        Update-WorkflowDropdowns -Window $Window -DropdownNames @("cmbWorkflowList")
        
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
            "Failed to save workflow: $($_.Exception.Message)",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
    }
}
