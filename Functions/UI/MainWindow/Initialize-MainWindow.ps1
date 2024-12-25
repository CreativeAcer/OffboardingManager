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
            
            $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\MainWindow.xaml"
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
    
    Write-Host "Getting main UI elements..."
    Update-LoadingMessage -LoadingWindow $LoadingWindow -Message "Setting up controls..."
    
    # Get existing elements
    $txtSearch = $Window.FindName("txtSearch")
    $lstUsers = $Window.FindName("lstUsers")
    $txtUserInfo = $Window.FindName("txtUserInfo")

    # Initialize tabs
    Initialize-Tabs -Window $Window -Credential $Credential -LoadingWindow $LoadingWindow

    # Set up event handlers
    Set-MainWindowEventHandlers -Window $Window -Controls @{
        Search = $txtSearch
        UserList = $lstUsers
        UserInfo = $txtUserInfo
    } -Credential $Credential
    
    # Initial data load
    Write-Host "Populating initial user list..."
    Update-LoadingMessage -LoadingWindow $LoadingWindow -Message "Loading user list..."
    Update-UserList -ListBox $lstUsers -Credential $Credential
    
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

    Write-Host "Initializing Reports tab..."
    Update-LoadingMessage -LoadingWindow $LoadingWindow -Message "Initializing Reports components..."
    Initialize-ReportsTab -Window $Window -Credential $Credential
}

function Set-MainWindowEventHandlers {
    param (
        [System.Windows.Window]$Window,
        [hashtable]$Controls,
        [System.Management.Automation.PSCredential]$Credential
    )
    
    Write-Host "Setting up event handlers..."
    
    $Controls.Search.Add_TextChanged({
        Update-UserList -SearchText $Controls.Search.Text -ListBox $Controls.UserList -Credential $Credential
    })
    
    $Controls.UserList.Add_SelectionChanged({
        if ($Controls.UserList.SelectedItem) {
            Update-SelectedUser -UserPrincipalName $Controls.UserList.SelectedItem -Credential $Credential
            Show-UserDetails -UserPrincipalName $Controls.UserList.SelectedItem -TextBlock $Controls.UserInfo -Credential $Credential
        }
    })
}