# Import sub-components
. "$PSScriptRoot\MainWindow\Initialize-MainWindow.ps1"
. "$PSScriptRoot\MainWindow\Update-UserList.ps1"
. "$PSScriptRoot\MainWindow\Update-SelectedUser.ps1"
. "$PSScriptRoot\MainWindow\Show-UserDetails.ps1"

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
        
        $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\MainWindow.xaml"
        $MainXAML = [xml](Get-ProcessedXaml -XamlPath $xamlPath)
        
        $Reader = New-Object System.Xml.XmlNodeReader $MainXAML
        $MainWindow = [Windows.Markup.XamlReader]::Load($Reader)
        
        Write-Host "Getting main UI elements..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Setting up controls..."
        
        Initialize-MainWindowControls -Window $MainWindow -Credential $Credential -LoadingWindow $loadingWindow

        # Get existing elements
        $txtSearch = $MainWindow.FindName("txtSearch")
        $lstUsers = $MainWindow.FindName("lstUsers")
        $txtUserInfo = $MainWindow.FindName("txtUserInfo")

        Write-Host "Initializing OnPrem tab..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Initializing On-Premises components..."
        Initialize-OnPremTab -Window $MainWindow -Credential $Credential

        Write-Host "Initializing O365 tab..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Initializing Office 365 components..."
        Initialize-O365Tab -Window $MainWindow -Credential $Credential

        Write-Host "Setting up event handlers..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Configuring event handlers..."
        
        # Event handlers for main window functionality
        $txtSearch.Add_TextChanged({
            Update-UserList -SearchText $txtSearch.Text -ListBox $lstUsers -Credential $Credential
        })
        
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Ready!"
        Start-Sleep -Milliseconds 500
        $loadingWindow.Close()
        
        Write-Host "Populating initial user list..."
        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Loading user list..."
        Update-UserList -ListBox $lstUsers -Credential $Credential
        
        $MainWindow.WindowStyle = 'SingleBorderWindow'
        $MainWindow.Focusable = $true

        Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Ready!"
        Start-Sleep -Milliseconds 500  # Brief pause to show ready message
        
        # Close loading window and show main window
        $loadingWindow.Close()
        
        Write-Host "Showing main window..."
        $MainWindow.Focus()
        $MainWindow.ShowDialog()
    }
    catch {
        if ($loadingWindow) {
            $loadingWindow.Close()
        }
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "MainWindow"
        Write-Error "Error in MainWindow: $_"
        Write-Host "Full exception details:"
        Write-Host $_.Exception.GetType().FullName
        Write-Host $_.Exception.Message
        Write-Host $_.ScriptStackTrace
        
        [System.Windows.MessageBox]::Show(
            "Failed to initialize application: $($_.Exception.Message)", 
            "Error", 
            [System.Windows.MessageBoxButton]::OK, 
            [System.Windows.MessageBoxImage]::Error)
    }
}