function Start-OffboardingWorkflow {
    param(
        [string]$UserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential
    )

    try {
        $loadingWindow = Show-LoadingScreen -Message "Starting offboarding workflow..."
        $loadingWindow.Show()
        [System.Windows.Forms.Application]::DoEvents()

        $results = @()
        $errorOccurred = $false
        
        # Get current workflow configuration
        $workflow = Get-CurrentWorkflowConfiguration
        if (-not $workflow) {
            throw "No workflow configuration found"
        }

        # Get user email for logging
        $userEmail = if ($script:DemoMode) {
            $UserPrincipalName
        }
        else {
            if ($script:UseADModule) {
                (Get-ADUser -Identity $UserPrincipalName -Properties mail).mail
            } else {
                $script:SelectedUser.Properties["mail"][0]
            }
        }

        Write-ActivityLog -UserEmail $userEmail -Action "Workflow Started" -Result "Starting workflow: $($workflow.Name)" -Platform "Workflow"

        foreach($taskId in $workflow.EnabledTasks) {
            # Find task definition
            $task = $script:WorkflowTasks.OnPrem + $script:WorkflowTasks.O365 |
                   Where-Object { $_.Id -eq $taskId } |
                   Select-Object -First 1

            if($task) {
                Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Executing task: $($task.DisplayName)..."
                
                try {
                    # Get task-specific settings
                    $taskSettings = $workflow.TaskSettings[$taskId]
                    
                    # Build parameters
                    $params = @{
                        UserPrincipalName = $UserPrincipalName
                    }

                    # Add Credential for non-O365 tasks
                    if ($task.Platform -ne "O365") {
                        $params["Credential"] = $Credential
                    }
                    
                    # Add task-specific parameters from settings
                    if($taskSettings) {
                        foreach($key in $taskSettings.Keys) {
                            $params[$key] = $taskSettings[$key]
                        }
                    }

                    # Execute task
                    $taskResult = & $task.FunctionName @params
                    $results += "$($task.DisplayName): $taskResult"
                    
                    Write-ActivityLog -UserEmail $userEmail `
                                    -Action "Workflow Task: $($task.DisplayName)" `
                                    -Result $taskResult `
                                    -Platform $task.Platform
                }
                catch {
                    $errorMessage = "$($task.DisplayName) failed: $($_.Exception.Message)"
                    $results += $errorMessage
                    Write-ActivityLog -UserEmail $userEmail `
                                    -Action "Workflow Task: $($task.DisplayName)" `
                                    -Result $errorMessage `
                                    -Platform $task.Platform
                    $errorOccurred = $true
                }
            }
            else {
                $errorMessage = "Task '$taskId' not found in workflow task registry"
                $results += $errorMessage
                Write-ActivityLog -UserEmail $userEmail `
                                -Action "Workflow Error" `
                                -Result $errorMessage `
                                -Platform "Workflow"
                $errorOccurred = $true
            }
        }

        # Log workflow completion
        $completionStatus = if ($errorOccurred) { "Completed with errors" } else { "Completed successfully" }
        Write-ActivityLog -UserEmail $userEmail -Action "Workflow Completed" -Result $completionStatus -Platform "Workflow"

        return $results
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Start-OffboardingWorkflow"
        throw
    }
    finally {
        if($loadingWindow) {
            $loadingWindow.Close()
        }
    }
}