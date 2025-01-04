function Get-WorkflowTasks {
    param (
        [string]$WorkflowName
    )
    try {
        $settings = Get-AppSetting
        $configurations = $settings.WorkflowConfigurations.Configurations

        if ($configurations -is [PSCustomObject]) {
            $workflow = $configurations.PSObject.Properties | 
                Where-Object { $_.Name -eq $WorkflowName } |
                Select-Object -ExpandProperty Value
        } else {
            $workflow = $configurations[$WorkflowName]
        }

        return $workflow.EnabledTasks
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Get-WorkflowTasks"
        throw
    }
}