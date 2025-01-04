function Remove-WorkflowConfiguration {
    param(
        [string]$Name
    )
    
    try {
        $settings = Get-AppSetting
        
        # Validate configuration exists
        if (-not $settings.WorkflowConfigurations.Configurations.ContainsKey($Name)) {
            throw "Configuration '$Name' not found"
        }

        # Prevent removing last configuration
        if ($settings.WorkflowConfigurations.Configurations.Count -eq 1) {
            throw "Cannot remove the last configuration"
        }
        
        # Remove configuration
        $settings.WorkflowConfigurations.Configurations.Remove($Name)
        
        # Update last used if needed
        if ($settings.WorkflowConfigurations.LastUsed -eq $Name) {
            $settings.WorkflowConfigurations.LastUsed = $settings.WorkflowConfigurations.Configurations.Keys | 
                                                      Select-Object -First 1
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
        
        if ($settings.WorkflowConfigurations.Configurations.ContainsKey($Name)) {
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