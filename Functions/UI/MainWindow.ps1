function Show-MainWindow {
    param (
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        Write-Host "Loading XAML..."
        $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\MainWindow.xaml"
        Write-Host "XAML Path: $xamlPath"
        $MainXAML = [xml](Get-ProcessedXaml -XamlPath $xamlPath)
        
        $Reader = New-Object System.Xml.XmlNodeReader $MainXAML
        $MainWindow = [Windows.Markup.XamlReader]::Load($Reader)
        
        Write-Host "Getting main UI elements..."
        # Get existing elements
        $txtSearch = $MainWindow.FindName("txtSearch")
        $lstUsers = $MainWindow.FindName("lstUsers")
        $txtUserInfo = $MainWindow.FindName("txtUserInfo")

        #Write-Host "Getting Easter Egg elements..."
        #$easterEggCanvas = $MainWindow.FindName("EasterEggCanvas")
        #Write-Host "EasterEggCanvas found: $($null -ne $easterEggCanvas)"
        
        #$matrixColumns = $MainWindow.FindName("MatrixColumns")
        #Write-Host "MatrixColumns found: $($null -ne $matrixColumns)"

        # if ($null -eq $easterEggCanvas) {
        #     Write-Warning "EasterEggCanvas not found in XAML"
        # }
        # if ($null -eq $matrixColumns) {
        #     Write-Warning "MatrixColumns not found in XAML"
        # }

        Write-Host "Initializing OnPrem tab..."
        Initialize-OnPremTab -Window $MainWindow -Credential $Credential

        Write-Host "Initializing O365 tab..."
        Initialize-O365Tab -Window $MainWindow -Credential $Credential

        # Write-Host "Attempting to initialize Easter Egg..."
        # if ($easterEggCanvas -and $matrixColumns) {
        #     try {
        #         Write-Host "Creating new MatrixEasterEgg instance..."
        #         $easterEgg = [MatrixEasterEgg]::new($easterEggCanvas, $matrixColumns, $MainWindow)
        #         Write-Host "Easter Egg initialized successfully"
        #     }
        #     catch {
        #         Write-Error "Failed to initialize Easter Egg: $_"
        #         Write-Host "Exception details: $($_.Exception.GetType().FullName)"
        #     }
        # }
        # else {
        #     Write-Warning "Skipping Easter Egg initialization due to missing elements"
        # }

        Write-Host "Setting up event handlers..."
        # Event handlers for main window functionality
        $txtSearch.Add_TextChanged({
            Update-UserList -SearchText $txtSearch.Text -ListBox $lstUsers -Credential $Credential
        })
        
        $lstUsers.Add_SelectionChanged({
            if ($lstUsers.SelectedItem) {
                Update-SelectedUser -UserPrincipalName $lstUsers.SelectedItem -Credential $Credential
                Show-UserDetails -UserPrincipalName $lstUsers.SelectedItem -TextBlock $txtUserInfo -Credential $Credential
            }
        })
        
        Write-Host "Populating initial user list..."
        Update-UserList -ListBox $lstUsers -Credential $Credential
        
        $MainWindow.WindowStyle = 'SingleBorderWindow'
        $MainWindow.Focusable = $true
        $MainWindow.Focus()

        Write-Host "Showing main window..."
        $MainWindow.ShowDialog()
    }
    catch {
        Write-Error "Error in MainWindow: $_"
        Write-Host "Full exception details:"
        Write-Host $_.Exception.GetType().FullName
        Write-Host $_.Exception.Message
        Write-Host $_.ScriptStackTrace
    }
}
# function Show-MainWindow {
#     param (
#         [System.Management.Automation.PSCredential]$Credential
#     )
    
#     try {
#         Write-Host "Loading XAML..."
#         $xamlPath = Join-Path -Path $script:BasePath -ChildPath "XAML\MainWindow.xaml"
#         Write-Host "XAML Path: $xamlPath"
#         $MainXAML = [xml](Get-ProcessedXaml -XamlPath $xamlPath)
        
#         $Reader = New-Object System.Xml.XmlNodeReader $MainXAML
#         $MainWindow = [Windows.Markup.XamlReader]::Load($Reader)
        
#         Write-Host "Getting main UI elements..."
#         # Get existing elements
#         $txtSearch = $MainWindow.FindName("txtSearch")
#         $lstUsers = $MainWindow.FindName("lstUsers")
#         $txtUserInfo = $MainWindow.FindName("txtUserInfo")

#         Write-Host "Getting Easter Egg elements..."
#         $easterEggCanvas = $MainWindow.FindName("EasterEggCanvas")
#         Write-Host "EasterEggCanvas found: $($null -ne $easterEggCanvas)"
        
#         $matrixColumns = $MainWindow.FindName("MatrixColumns")
#         Write-Host "MatrixColumns found: $($null -ne $matrixColumns)"

#         Write-Host "Initializing OnPrem tab..."
#         Initialize-OnPremTab -Window $MainWindow -Credential $Credential

#         Write-Host "Initializing O365 tab..."
#         Initialize-O365Tab -Window $MainWindow -Credential $Credential

#         # Set up Easter Egg
#         $keySequence = ""
#         $matrixChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@#$%&*".ToCharArray()
#         $activeColumns = @()
#         $timer = $null
#         $isActive = $false

#         $MainWindow.Add_PreviewKeyDown({
#             param($sender, $e)
            
#             $key = $e.Key.ToString()
#             Write-Host "Key pressed: $key"
            
#             $script:keySequence += $key
#             Write-Host "Current sequence: $script:keySequence"
            
#             # Check for Konami code
#             if ($script:keySequence -match "UpUpDownDownLeftRightLeftRightBA") {
#                 Write-Host "KONAMI CODE DETECTED!"
#                 $script:keySequence = ""
                
#                 if (-not $script:isActive) {
#                     $script:isActive = $true
#                     $easterEggCanvas.Visibility = "Visible"
                    
#                     # Create matrix columns
#                     $columnCount = [Math]::Floor($MainWindow.ActualWidth / 20)
#                     for ($i = 0; $i -lt $columnCount; $i++) {
#                         $column = New-Object System.Windows.Controls.StackPanel
#                         $column.Orientation = "Vertical"
#                         [System.Windows.Controls.Canvas]::SetLeft($column, $i * 20)
#                         [System.Windows.Controls.Canvas]::SetTop($column, (Get-Random -Minimum -500 -Maximum 0))
                        
#                         $script:activeColumns += $column
#                         $matrixColumns.Items.Add($column)
                        
#                         $charCount = Get-Random -Minimum 5 -Maximum 15
#                         for ($j = 0; $j -lt $charCount; $j++) {
#                             $textBlock = New-Object System.Windows.Controls.TextBlock
#                             $textBlock.Text = $matrixChars[(Get-Random -Maximum $matrixChars.Length)]
#                             $textBlock.Foreground = "Lime"
#                             $textBlock.FontFamily = "Consolas"
#                             $textBlock.FontSize = 16
#                             $textBlock.Opacity = [Math]::Max(0.1, 1 - ($j / $charCount))
#                             $column.Children.Add($textBlock)
#                         }
#                     }
                    
#                     # Animation timer
#                     $script:timer = New-Object System.Windows.Threading.DispatcherTimer
#                     $script:timer.Interval = [TimeSpan]::FromMilliseconds(50)
#                     $script:timer.Add_Tick({
#                         foreach ($column in $script:activeColumns) {
#                             $top = [System.Windows.Controls.Canvas]::GetTop($column)
#                             $top += 5
                            
#                             if ($top -gt $MainWindow.ActualHeight) {
#                                 $top = -500
#                             }
                            
#                             [System.Windows.Controls.Canvas]::SetTop($column, $top)
                            
#                             foreach ($textBlock in $column.Children) {
#                                 if ((Get-Random -Maximum 100) -lt 10) {
#                                     $textBlock.Text = $matrixChars[(Get-Random -Maximum $matrixChars.Length)]
#                                 }
#                             }
#                         }
#                     })
                    
#                     $script:timer.Start()
                    
#                     # Stop after 10 seconds
#                     $stopTimer = New-Object System.Windows.Threading.DispatcherTimer
#                     $stopTimer.Interval = [TimeSpan]::FromSeconds(10)
#                     $stopTimer.Add_Tick({
#                         if ($script:timer) {
#                             $script:timer.Stop()
#                         }
#                         $matrixColumns.Items.Clear()
#                         $script:activeColumns = @()
#                         $easterEggCanvas.Visibility = "Collapsed"
#                         $script:isActive = $false
#                         $stopTimer.Stop()
#                     })
#                     $stopTimer.Start()
#                 }
#             }
            
#             # Keep sequence from getting too long
#             if ($script:keySequence.Length > 20) {
#                 $script:keySequence = $script:keySequence.Substring($script:keySequence.Length - 20)
#             }
#         })

#         Write-Host "Setting up event handlers..."
#         # Event handlers for main window functionality
#         $txtSearch.Add_TextChanged({
#             Update-UserList -SearchText $txtSearch.Text -ListBox $lstUsers -Credential $Credential
#         })
        
#         $lstUsers.Add_SelectionChanged({
#             if ($lstUsers.SelectedItem) {
#                 Update-SelectedUser -UserPrincipalName $lstUsers.SelectedItem -Credential $Credential
#                 Show-UserDetails -UserPrincipalName $lstUsers.SelectedItem -TextBlock $txtUserInfo -Credential $Credential
#             }
#         })
        
#         Write-Host "Populating initial user list..."
#         Update-UserList -ListBox $lstUsers -Credential $Credential
        
#         # Focus handling
#         $MainWindow.WindowStyle = 'SingleBorderWindow'
#         $MainWindow.Focusable = $true
#         $MainWindow.Focus()
        
#         Write-Host "Showing main window..."
#         $MainWindow.ShowDialog()
#     }
#     catch {
#         Write-Error "Error in MainWindow: $_"
#         Write-Host "Full exception details:"
#         Write-Host $_.Exception.GetType().FullName
#         Write-Host $_.Exception.Message
#         Write-Host $_.ScriptStackTrace
#     }
# }

function Update-UserList {
    param (
        [System.Windows.Controls.ListBox]$ListBox,
        [System.Management.Automation.PSCredential]$Credential,
        [string]$SearchText = ""
    )
    
    $ListBox.Items.Clear()
    
    if ($script:UseADModule) {
        $Filter = "Enabled -eq '$true' -and LockedOut -eq '$false' -and Mail -like '*'"
        
        if ($SearchText) {
            $Filter = "Enabled -eq '$true' -and LockedOut -eq '$false' -and Mail -like '*' -and UserPrincipalName -like '*$SearchText*'"
        }

        Write-Host "Using AD Module filter: $Filter"
        
        $Users = Get-ADUser -Credential $Credential -Filter $Filter -Properties UserPrincipalName |
                Sort-Object UserPrincipalName
        
        foreach ($User in $Users) {
            $ListBox.Items.Add($User.UserPrincipalName)
        }
    }
    else {
        $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
        $filter = "(&(objectClass=user)(!userAccountControl:1.2.840.113556.1.4.803:=2)(!(userAccountControl:1.2.840.113556.1.4.803:=16))(mail=*))"

        if ($SearchText) {
            $filter = "(&(objectClass=user)(!userAccountControl:1.2.840.113556.1.4.803:=2)(!(userAccountControl:1.2.840.113556.1.4.803:=16))(mail=*)(userPrincipalName=*$SearchText*))"
        }

        Write-Host "Using LDAP filter: $filter"
        
        $Users = Get-LDAPUsers -Directory $directory -SearchFilter $filter
        
        foreach ($User in $Users) {
            if ($User.Properties["userPrincipalName"]) {
                $ListBox.Items.Add($User.Properties["userPrincipalName"][0])
            }
        }
    }
}

function Update-SelectedUser {
    param (
        [string]$UserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential
    )

    if ($script:UseADModule) {
        $script:SelectedUser = Get-ADUser -Credential $Credential -Filter "UserPrincipalName -eq '$UserPrincipalName'" -Properties *
    }
    else {
        $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
        $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
        $script:SelectedUser = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
    }
}

function Show-UserDetails {
    param (
        [string]$UserPrincipalName,
        [System.Windows.Controls.TextBlock]$TextBlock,
        [System.Management.Automation.PSCredential]$Credential
    )
    
    if ($script:UseADModule) {
        $User = Get-ADUser -Credential $Credential -Filter {UserPrincipalName -eq $UserPrincipalName} -Properties *
        
        $Details = @"
Name: $($User.Name)
User Principal Name: $($User.UserPrincipalName)
Distinguished Name: $($User.DistinguishedName)
Enabled: $($User.Enabled)
Last Logon: $($User.LastLogonDate)
Created: $($User.Created)
Modified: $($User.Modified)
Email: $($User.EmailAddress)
Department: $($User.Department)
Title: $($User.Title)
Manager: $($User.Manager)
Office: $($User.Office)
Phone: $($User.OfficePhone)
Mobile: $($User.MobilePhone)
Account Expires: $($User.AccountExpirationDate)
Password Last Set: $($User.PasswordLastSet)
Password Never Expires: $($User.PasswordNeverExpires)
Account Locked Out: $($User.LockedOut)
Member Of:
$($User.MemberOf | ForEach-Object { "- $_" } | Out-String)
"@
    }
    else {
        $directory = Get-LDAPConnection -DomainController $script:DomainController -Credential $Credential
        $filter = "(&(objectClass=user)(userPrincipalName=$UserPrincipalName))"
        $User = Get-LDAPUsers -Directory $directory -SearchFilter $filter | Select-Object -First 1
        
        # Convert UAC to enabled status
        $enabled = $true
        if ($User.Properties["userAccountControl"]) {
            $uac = $User.Properties["userAccountControl"][0]
            $enabled = -not [bool]($uac -band 0x2)
        }
        
        $Details = @"
Name: $($User.Properties["displayName"][0])
User Principal Name: $($User.Properties["userPrincipalName"][0])
Distinguished Name: $($User.Properties["distinguishedName"][0])
Enabled: $enabled
Created: $($User.Properties["whenCreated"][0])
Modified: $($User.Properties["whenChanged"][0])
Email: $($User.Properties["mail"][0])
Department: $($User.Properties["department"][0])
Title: $($User.Properties["title"][0])
Manager: $($User.Properties["manager"][0])
Phone: $($User.Properties["telephoneNumber"][0])
Mobile: $($User.Properties["mobile"][0])
Member Of:
$($User.Properties["memberOf"] | ForEach-Object { "- $_" } | Out-String)
"@
    }
    
    $TextBlock.Text = $Details
}