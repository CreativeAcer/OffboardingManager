function Get-WorkflowConfigurations {
    try {
        $settings = Get-AppSetting
        Write-Host "Getting workflow configurations..."
        Write-Host ($settings | ConvertTo-Json -Depth 5)
        Write-Host ($settings.WorkflowConfigurations | ConvertTo-Json -Depth 5)
        return $settings.WorkflowConfigurations.Configurations
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Get-WorkflowConfigurations"
        throw
    }
}

function Get-CurrentWorkflowConfiguration {
    try {
        $settings = Get-AppSetting
        $lastUsed = $settings.WorkflowConfigurations.LastUsed
        
        if ([string]::IsNullOrEmpty($lastUsed)) {
            # Return first available configuration if no last used
            $config = $settings.WorkflowConfigurations.Configurations.Values | Select-Object -First 1
            if ($config) {
                return $config
            }
            # Return default template if no configurations exist
            return @{
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
                LastModified = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }
        }
        
        return $settings.WorkflowConfigurations.Configurations[$lastUsed]
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Get-CurrentWorkflowConfiguration"
        throw
    }
}