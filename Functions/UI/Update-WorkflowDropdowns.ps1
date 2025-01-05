function Update-WorkflowDropdowns {
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Window]$Window,
        [string[]]$DropdownNames
    )
    try {
        $settings = Get-AppSetting
        
        $Window.Dispatcher.Invoke([Action]{
            foreach($dropdownName in $DropdownNames) {
                $dropdown = $Window.FindName($dropdownName)
                if ($null -ne $dropdown) {
                    # Store current selection
                    $currentSelection = $dropdown.SelectedItem
                    
                    # Clear and refill items
                    $dropdown.Items.Clear()
        
                    if ($settings.WorkflowConfigurations -and 
                        $settings.WorkflowConfigurations.Configurations) {
                        
                        # Convert to hashtable if it's a PSCustomObject
                        $configurations = $settings.WorkflowConfigurations.Configurations
                        if ($configurations -is [PSCustomObject]) {
                            $names = @($configurations.PSObject.Properties) | 
                                ForEach-Object { $_.Value.Name }
                        } else {
                            $names = @($configurations.Values) | 
                                ForEach-Object { $_.Name }
                        }

                        foreach($name in $names) {
                            Write-Host "Adding workflow: $name"
                            $dropdown.Items.Add($name)
                        }

                        # Try to restore previous selection, otherwise use LastUsed or first item
                        if ($dropdown.Items.Contains($currentSelection)) {
                            $dropdown.SelectedItem = $currentSelection
                        }
                        elseif ($settings.WorkflowConfigurations.LastUsed -and 
                               $dropdown.Items.Contains($settings.WorkflowConfigurations.LastUsed)) {
                            $dropdown.SelectedItem = $settings.WorkflowConfigurations.LastUsed
                        }
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