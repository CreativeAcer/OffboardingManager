function Get-TaskSettings {
    try {
        $settings = @{}
        foreach($child in $script:pnlTaskSettings.Children) {
            if ($child -is [System.Windows.Controls.TextBox]) {
                $name = $child.Name
                $value = $child.Text
                if ($name -and $value) {
                    $settings[$name] = $value
                }
            }
        }
        return $settings
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Get-TaskSettings"
        throw
    }
}