# using namespace System.Windows
# using namespace System.Windows.Controls
# using namespace System.Windows.Media
# using namespace System.Windows.Threading

# Add required assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase


class MatrixEasterEgg {
    hidden [string]$keySequence = ""
    hidden [char[]]$matrixChars
    hidden [array]$activeColumns = @()
    hidden [System.Windows.Threading.DispatcherTimer]$timer
    hidden [System.Windows.Controls.Canvas]$easterEggCanvas
    hidden [System.Windows.Controls.ItemsControl]$matrixColumns
    hidden [System.Windows.Window]$window
    hidden [scriptblock]$keyHandler

    MatrixEasterEgg([System.Windows.Controls.Canvas]$canvas, [System.Windows.Controls.ItemsControl]$columns, [System.Windows.Window]$mainWindow) {
        Write-Host "Starting MatrixEasterEgg initialization..."
        
        # Validate inputs
        if ($null -eq $canvas) { throw "Canvas is null" }
        if ($null -eq $columns) { throw "Columns is null" }
        if ($null -eq $mainWindow) { throw "MainWindow is null" }
        
        $this.easterEggCanvas = $canvas
        $this.matrixColumns = $columns
        $this.window = $mainWindow
        $this.matrixChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@#$%&*".ToCharArray()
        
        # Create key handler
        $this.keyHandler = {
            param($sender, $e)
            
            $key = $e.Key.ToString()
            Write-Host "Key pressed in Easter Egg: $key"
            
            # Add key to sequence
            $this.keySequence += $key
            Write-Host "Current sequence: $($this.keySequence)"
            
            # Check for Konami code
            if ($this.keySequence -match "UpUpDownDownLeftRightLeftRightBA") {
                Write-Host "KONAMI CODE DETECTED!"
                $this.keySequence = ""  # Reset sequence
                $this.StartEffect()
            }
            
            # Keep sequence from getting too long
            if ($this.keySequence.Length > 20) {
                $this.keySequence = $this.keySequence.Substring($this.keySequence.Length - 20)
            }
        }
        
        # Add the event handler
        $mainWindow.AddHandler(
            [System.Windows.UIElement]::KeyDownEvent,
            [System.Windows.Input.KeyEventHandler]$this.keyHandler
        )
        
        Write-Host "MatrixEasterEgg initialized successfully"
    }

    [void]StartEffect() {
        Write-Host "Starting Matrix effect..."
        $this.easterEggCanvas.Dispatcher.Invoke({
            $this.easterEggCanvas.Visibility = [System.Windows.Visibility]::Visible
        })
        
        try {
            # Create matrix columns
            $columnCount = [Math]::Floor($this.window.ActualWidth / 20)
            Write-Host "Creating $columnCount columns..."
            
            $this.window.Dispatcher.Invoke({
                for ($i = 0; $i -lt $columnCount; $i++) {
                    $column = New-Object System.Windows.Controls.StackPanel
                    $column.Orientation = "Vertical"
                    [System.Windows.Controls.Canvas]::SetLeft($column, $i * 20)
                    [System.Windows.Controls.Canvas]::SetTop($column, (Get-Random -Minimum -500 -Maximum 0))
                    
                    $this.activeColumns += $column
                    $this.matrixColumns.Items.Add($column)
                    
                    $charCount = Get-Random -Minimum 5 -Maximum 15
                    for ($j = 0; $j -lt $charCount; $j++) {
                        $textBlock = New-Object System.Windows.Controls.TextBlock
                        $textBlock.Text = $this.matrixChars[(Get-Random -Maximum $this.matrixChars.Length)]
                        $textBlock.Foreground = "Lime"
                        $textBlock.FontFamily = "Consolas"
                        $textBlock.FontSize = 16
                        $textBlock.Opacity = [Math]::Max(0.1, 1 - ($j / $charCount))
                        $column.Children.Add($textBlock)
                    }
                }
            })
            
            # Animation timer
            $this.timer = New-Object System.Windows.Threading.DispatcherTimer
            $this.timer.Interval = [TimeSpan]::FromMilliseconds(50)
            $this.timer.Add_Tick({
                $this.window.Dispatcher.Invoke({
                    foreach ($column in $this.activeColumns) {
                        $top = [System.Windows.Controls.Canvas]::GetTop($column)
                        $top += 5
                        
                        if ($top -gt $this.window.ActualHeight) {
                            $top = -500
                        }
                        
                        [System.Windows.Controls.Canvas]::SetTop($column, $top)
                        
                        foreach ($textBlock in $column.Children) {
                            if ((Get-Random -Maximum 100) -lt 10) {
                                $textBlock.Text = $this.matrixChars[(Get-Random -Maximum $this.matrixChars.Length)]
                            }
                        }
                    }
                })
            })
            
            $this.timer.Start()
            Write-Host "Animation started"
            
            # Stop after 10 seconds
            $stopTimer = New-Object System.Windows.Threading.DispatcherTimer
            $stopTimer.Interval = [TimeSpan]::FromSeconds(10)
            $stopTimer.Add_Tick({
                $this.StopEffect()
                $stopTimer.Stop()
            })
            $stopTimer.Start()
        }
        catch {
            Write-Host "Error in StartEffect: $_"
            $this.StopEffect()
        }
    }

    [void]StopEffect() {
        Write-Host "Stopping effect..."
        if ($this.timer) {
            $this.timer.Stop()
        }
        $this.window.Dispatcher.Invoke({
            $this.matrixColumns.Items.Clear()
            $this.activeColumns = @()
            $this.easterEggCanvas.Visibility = [System.Windows.Visibility]::Collapsed
        })
        Write-Host "Effect stopped"
    }
}