function Save-WorkflowConfiguration {
    param(
        [string]$Name,
        [string]$Description,
        [array]$EnabledTasks,
        [hashtable]$TaskSettings,
        [bool]$SetAsDefault = $false
    )
    
    try {
        # Get current settings
        $settings = Get-AppSetting
        
        # Initialize WorkflowConfigurations if it doesn't exist
        if (-not $settings.WorkflowConfigurations) {
            $settings.WorkflowConfigurations = @{
                LastUsed = ""
                Configurations = @{}
            }
        }

        # Create new configuration
        $newConfig = @{
            Name = $Name
            Description = $Description
            EnabledTasks = $EnabledTasks
            TaskSettings = $TaskSettings
            LastModified = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
        #TESTING THIS
        # Add or update configuration
        if ($settings.WorkflowConfigurations.Configurations -is [PSCustomObject]) {
            # If it's a PSCustomObject, check if the configuration exists
            if ($settings.WorkflowConfigurations.Configurations.PSObject.Properties.Match($Name)) {
                # Remove the old configuration if it exists
                $settings.WorkflowConfigurations.Configurations.PSObject.Properties.Remove($Name)
            }

            # Add the new configuration
            $settings.WorkflowConfigurations.Configurations | Add-Member -MemberType NoteProperty -Name $Name -Value $newConfig
        } else {
            # If it's a hashtable, directly add or update the configuration
            $settings.WorkflowConfigurations.Configurations[$Name] = $newConfig
        }

        
        # Add or update configuration
        #$settings.WorkflowConfigurations.Configurations[$Name] = $newConfig
        
        # Set as last used if requested or if it's the only configuration
        if ($SetAsDefault -or $settings.WorkflowConfigurations.Configurations.Count -eq 1) {
            $settings.WorkflowConfigurations.LastUsed = $Name
        }
        # Save settings
        Update-AppSettings -NewSettings $settings

        # Save settings
        #Update-AppSettings -NewSettings $settings
        
        return "Workflow configuration '$Name' saved successfully"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Save-WorkflowConfiguration"
        throw
    }
}