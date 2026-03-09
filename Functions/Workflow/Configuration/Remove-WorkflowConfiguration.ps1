function Remove-WorkflowConfiguration {
    param(
        [string]$Name
    )
    
    try {
        $settings = Get-AppSetting
        $configs = $settings.WorkflowConfigurations.Configurations

        # Normalise to hashtable so all operations are uniform
        if ($configs -is [PSCustomObject]) {
            $configHash = @{}
            foreach ($prop in $configs.PSObject.Properties) {
                $configHash[$prop.Name] = $prop.Value
            }
            $configs = $configHash
        }

        # Validate configuration exists
        if (-not $configs.ContainsKey($Name)) {
            throw "Configuration '$Name' not found"
        }

        # Prevent removing last configuration
        if ($configs.Count -eq 1) {
            throw "Cannot remove the last configuration"
        }

        # Remove configuration
        $configs.Remove($Name)

        # Write the normalised hashtable back into settings
        $settings.WorkflowConfigurations.Configurations = $configs

        # Update last used if needed
        if ($settings.WorkflowConfigurations.LastUsed -eq $Name) {
            $settings.WorkflowConfigurations.LastUsed = $configs.Keys | Select-Object -First 1
        }
        
        # Save settings
        Update-AppSettings -NewSettings $settings
        
        return "Workflow configuration '$Name' removed successfully"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Remove-WorkflowConfiguration"
        throw
    }
}

function Set-CurrentWorkflowConfiguration {
    param(
        [string]$Name
    )
    
    try {
        $settings = Get-AppSetting
        $configs = $settings.WorkflowConfigurations.Configurations

        # Normalise to hashtable so ContainsKey is available
        if ($configs -is [PSCustomObject]) {
            $configHash = @{}
            foreach ($prop in $configs.PSObject.Properties) {
                $configHash[$prop.Name] = $prop.Value
            }
            $configs = $configHash
        }

        if ($configs.ContainsKey($Name)) {
            $settings.WorkflowConfigurations.LastUsed = $Name
            Update-AppSettings -NewSettings $settings
            return "Current workflow set to '$Name'"
        }

        throw "Configuration '$Name' not found"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Set-CurrentWorkflowConfiguration"
        throw
    }
}