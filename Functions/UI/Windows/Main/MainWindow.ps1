# Import sub-components
. "$PSScriptRoot\Initialize-MainWindow.ps1"
. "$PSScriptRoot\Update-UserList.ps1"
. "$PSScriptRoot\Update-SelectedUser.ps1"
. "$PSScriptRoot\Show-UserDetails.ps1"

function Show-MainWindow {
    param (
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        # Show initial loading screen
        $loadingWindow = Show-LoadingScreen -Message "Initializing application..."
        $loadingWindow.Show()

        Write-Host "Loading XAML..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Loading interface components..."
        
        $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\Windows\MainWindow.xaml"
        $MainXAML = [xml](Get-ProcessedXaml -XamlPath $xamlPath)
        
        $Reader = New-Object System.Xml.XmlNodeReader $MainXAML
        $MainWindow = [Windows.Markup.XamlReader]::Load($Reader)
        
        Write-Host "Getting main UI elements..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Setting up controls..."
        
        Initialize-MainWindowControls -Window $MainWindow -Credential $Credential -LoadingWindow $loadingWindow
        
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Ready!"
        Start-Sleep -Milliseconds 500
        $loadingWindow.Close()
        
        $MainWindow.ShowDialog()
    }
    catch {
        if ($loadingWindow) {
            $loadingWindow.Close()
        }
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "MainWindow"
        [System.Windows.MessageBox]::Show(
            "Failed to initialize application: $($_.Exception.Message)", 
            "Error", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Error)
    }
}