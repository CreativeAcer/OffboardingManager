function Update-WorkflowDropdowns {
    param (
        [System.Windows.Window]$Window,
        [string[]]$DropdownNames  # Array of dropdown names to update
    )
    try {
        $settings = Get-AppSetting
        Write-Host "Current workflow configurations:"
        Write-Host ($settings.WorkflowConfigurations | ConvertTo-Json -Depth 5)

        $Window.Dispatcher.Invoke([Action]{
            foreach($dropdownName in $DropdownNames) {
                $dropdown = $Window.FindName($dropdownName)
                if ($null -ne $dropdown) {
                    $dropdown.Items.Clear()
            
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
                            $dropdown.Items.Add($workflow.Name)
                        }

                        # Set selected item to LastUsed if available
                        if ($settings.WorkflowConfigurations.LastUsed) {
                            $dropdown.SelectedItem = $settings.WorkflowConfigurations.LastUsed
                        }
                        # If no LastUsed, but items exist, select the first one
                        elseif ($dropdown.Items.Count -gt 0) {
                            $dropdown.SelectedIndex = 0
                        }
                    }
                }
            }
        })
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Update-WorkflowDropdowns"
        throw
    }
}