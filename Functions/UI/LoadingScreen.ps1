function Show-LoadingScreen {
    param (
        [string]$Message = "Initializing..."
    )

    try {
        # Get the XAML
        $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\LoadingWindow.xaml"
        $LoadingXAML = [xml](Get-ProcessedXaml -XamlPath $xamlPath)
        
        # Create window
        $reader = New-Object System.Xml.XmlNodeReader $LoadingXAML
        $loadingWindow = [Windows.Markup.XamlReader]::Load($reader)

        # Get controls
        $loadingTextBlock = $loadingWindow.FindName("LoadingText")
        $progressBar = $loadingWindow.FindName("LoadingProgress")
        
        # Set initial message
        if ($loadingTextBlock) {
            $loadingTextBlock.Text = $Message
        } else {
            Write-Host "Warning: LoadingText control not found"
        }

        if (-not $progressBar) {
            Write-Host "Warning: LoadingProgress control not found"
        }

        # Ensure window is on top and visible
        $loadingWindow.Topmost = $true
        $loadingWindow.ShowInTaskbar = $false
        
        return $loadingWindow
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Show-LoadingScreen"
        throw
    }
}

function Update-LoadingMessage {
    param (
        [System.Windows.Window]$LoadingWindow,
        [string]$Message
    )
    
    if ($null -ne $LoadingWindow) {
        $LoadingWindow.Dispatcher.Invoke({
            $loadingText = $LoadingWindow.FindName("LoadingText")
            if ($null -ne $loadingText) {
                $loadingText.Text = $Message
            }
        })
    }
}