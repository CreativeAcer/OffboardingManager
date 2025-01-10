function Initialize-MainWindow {
    param (
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        # Show initial loading screen
        $loadingWindow = Show-LoadingScreen -Message "Initializing application..."
        $loadingWindow.Show()

        try {
            Write-Host "Loading XAML..."
            Update-LoadingMessage -LoadingWindow $loadingWindow -Message "Loading interface components..."
            
            $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\Windows\MainWindow.xaml"
            $MainXAML = [xml](Get-ProcessedXaml -XamlPath $xamlPath)
            
            $Reader = New-Object System.Xml.XmlNodeReader $MainXAML
            $MainWindow = [Windows.Markup.XamlReader]::Load($Reader)
            
            Initialize-MainWindowControls -Window $MainWindow -Credential $Credential -LoadingWindow $loadingWindow
            
            return $MainWindow
        }
        finally {
            if ($loadingWindow) {
                $loadingWindow.Close()
            }
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Initialize-MainWindow"
        throw
    }
}

function Initialize-MainWindowControls {
    param (
        [System.Windows.Window]$Window,
        [System.Management.Automation.PSCredential]$Credential,
        $LoadingWindow
    )

    if (Get-AppSetting -SettingName "DemoMode") {
        $Window.Title += " (DEMO MODE)"
    }
    
    Write-Host "Getting main UI elements..."
    Update-LoadingMessage -LoadingWindow $LoadingWindow -Message "Setting up controls..."
    
    # Store controls in script scope for access across functions
    $script:txtSearch = $Window.FindName("txtSearch")
    $script:lstUsers = $Window.FindName("lstUsers")
    $script:txtUserInfo = $Window.FindName("txtUserInfo")

    # Initialize tabs
    Initialize-Tabs -Window $Window -Credential $Credential -LoadingWindow $LoadingWindow

    # Set up event handlers
    $script:txtSearch.Add_TextChanged({
        Filter-UserList -SearchText $script:txtSearch.Text -ListBox $script:lstUsers
    })
    
    $script:lstUsers.Add_SelectionChanged({
        if ($script:lstUsers.SelectedItem) {
            Update-SelectedUser -UserPrincipalName $script:lstUsers.SelectedItem -Credential $Credential
            Show-UserDetails -UserPrincipalName $script:lstUsers.SelectedItem -TextBlock $script:txtUserInfo -Credential $Credential
        }
    })

    
    # Initial data load
    Write-Host "Populating initial user list..."
    Update-LoadingMessage -LoadingWindow $LoadingWindow -Message "Loading user list..."
    Update-UserList -ListBox $script:lstUsers -Credential $Credential
    
    $Window.WindowStyle = 'SingleBorderWindow'
    $Window.Focusable = $true
}

function Initialize-Tabs {
    param (
        [System.Windows.Window]$Window,
        [System.Management.Automation.PSCredential]$Credential,
        $LoadingWindow
    )
    
    Write-Host "Initializing OnPrem tab..."
    Update-LoadingMessage -LoadingWindow $LoadingWindow -Message "Initializing On-Premises components..."
    Initialize-OnPremTab -Window $Window -Credential $Credential

    Write-Host "Initializing O365 tab..."
    Update-LoadingMessage -LoadingWindow $LoadingWindow -Message "Initializing Office 365 components..."
    Initialize-O365Tab -Window $Window -Credential $Credential

    Write-Host "Initializing Workflow tab..."
    Update-LoadingMessage -LoadingWindow $LoadingWindow -Message "Initializing Workflow components..."
    Initialize-WorkflowTab -Window $Window -Credential $Credential

    Write-Host "Initializing Reports tab..."
    Update-LoadingMessage -LoadingWindow $LoadingWindow -Message "Initializing Reports components..."
    Initialize-ReportsTab -Window $Window -Credential $Credential
}