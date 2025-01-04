function Get-WorkflowConfigurations {
    try {
        $settings = Get-AppSetting
        if ($settings.WorkflowConfigurations -and 
            $settings.WorkflowConfigurations.Configurations) {
            
            # Convert to hashtable if it's a PSCustomObject
            $configurations = $settings.WorkflowConfigurations.Configurations
            if ($configurations -is [PSCustomObject]) {
                $configHash = @{}
                foreach($prop in $configurations.PSObject.Properties) {
                    $configHash[$prop.Name] = $prop.Value
                }
                return $configHash
            }
            return $configurations
        }
        return @{}
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