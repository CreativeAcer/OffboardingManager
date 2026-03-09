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
        # Normalise Configurations to a hashtable so add/update is uniform.
        # PSCustomObject (from JSON) does not support direct key assignment.
        if ($settings.WorkflowConfigurations.Configurations -is [PSCustomObject]) {
            $configHash = @{}
            foreach ($prop in $settings.WorkflowConfigurations.Configurations.PSObject.Properties) {
                $configHash[$prop.Name] = $prop.Value
            }
            $settings.WorkflowConfigurations.Configurations = $configHash
        }

        # Add or update configuration
        $settings.WorkflowConfigurations.Configurations[$Name] = $newConfig

        # Set as last used if requested or if it's the only configuration
        if ($SetAsDefault -or $settings.WorkflowConfigurations.Configurations.Count -eq 1) {
            $settings.WorkflowConfigurations.LastUsed = $Name
        }

        # Save settings
        Update-AppSettings -NewSettings $settings
        
        return "Workflow configuration '$Name' saved successfully"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Save-WorkflowConfiguration"
        throw
    }
}