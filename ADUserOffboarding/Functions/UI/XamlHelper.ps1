function Get-ProcessedXaml {
    param (
        [string]$XamlPath
    )
    
    try {
        # Verify file exists
        if (-not (Test-Path $XamlPath)) {
            throw "XAML file not found: $XamlPath"
        }

        # Read the XAML content
        $xamlContent = Get-Content -Path $XamlPath -Raw

        # Replace color variables
        $processedXaml = $ExecutionContext.InvokeCommand.ExpandString($xamlContent)

        return $processedXaml
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "XAML Processing"
        throw
    }
}