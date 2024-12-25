function Initialize-ReportsTab {
    param (
        [System.Windows.Window]$Window,
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        Write-Host "Initializing Reports Tab controls"
        
        # Get control references
        $script:chkOffboardingReport = $Window.FindName("chkOffboardingReport")
        $script:chkLicenseReport = $Window.FindName("chkLicenseReport")
        $script:cmbReportFormat = $Window.FindName("cmbReportFormat")
        $script:dpStartDate = $Window.FindName("dpStartDate")
        $script:dpEndDate = $Window.FindName("dpEndDate")
        $script:btnGenerateReport = $Window.FindName("btnGenerateReport")
        $script:txtReportResults = $Window.FindName("txtReportResults")

        # Set default dates
        $script:dpStartDate.SelectedDate = (Get-Date).AddDays(-30)
        $script:dpEndDate.SelectedDate = Get-Date

        # Add click handler for generate button
        $script:btnGenerateReport.Add_Click({
            Generate-Reports -Credential $Credential
        })

        Write-Host "Reports Tab initialization completed"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Reports-TabInit"
        throw
    }
}

# function Get-BasePath {
#     try {
#         # Dynamically determine the base path
#         $BasePath = $PSScriptRoot
#         if (-not $BasePath) {
#             $BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
#         }
#         return $BasePath
#     } catch {
#         throw "Unable to determine the base path: $($_.Exception.Message)"
#     }
# }

function Generate-Reports {
    param (
        [System.Management.Automation.PSCredential]$Credential
    )

    try {
        # Ensure at least one report is selected
        if (-not ($script:chkOffboardingReport.IsChecked -or $script:chkLicenseReport.IsChecked)) {
            $script:txtReportResults.Text = "Please select at least one report to generate."
            return
        }

        # Get user-selected parameters and normalize date ranges
        $startDate = [datetime]::ParseExact($script:dpStartDate.SelectedDate.ToString("yyyy-MM-dd 00:00:00"), "yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $endDate = [datetime]::ParseExact($script:dpEndDate.SelectedDate.ToString("yyyy-MM-dd 23:59:59"), "yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $format = $script:cmbReportFormat.SelectedItem.Content
        $results = @()

        $BasePath = Get-BasePath
        $BasePath = Split-Path -Parent (Split-Path -Parent $BasePath)  # Move two folders higher
        Write-Output "BasePath resolved to: $BasePath"

        # Ensure the reports directory exists
        $reportsPath = Join-Path -Path $BasePath -ChildPath "Reports"
        if (-not (Test-Path $reportsPath)) {
            New-Item -ItemType Directory -Path $reportsPath -Force | Out-Null
            Write-Output "Created reports directory: $reportsPath"
        }

        # Generate a timestamp for report files
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

        # Retrieve log files and process them
        $logFilesPath = Join-Path -Path $BasePath -ChildPath "Logs"
        $logFiles = Get-ChildItem -Path $logFilesPath -Filter "*.log"

        foreach ($file in $logFiles) {
            Write-Output "Processing file: $($file.FullName)"
            foreach ($line in (Get-Content -Path $file.FullName -Encoding UTF8)) {
                Write-Output "Processing line: $line"
                # Add your line processing logic here
            }
        }

        # Generate reports based on user selection
        if ($script:chkOffboardingReport.IsChecked) {
            $results += Generate-OffboardingReport -StartDate $startDate -EndDate $endDate -Format $format -Timestamp $timestamp
        }

        if ($script:chkLicenseReport.IsChecked) {
            $results += Generate-LicenseReport -Format $format -Timestamp $timestamp
        }

        # Display the results in the UI
        $script:txtReportResults.Text = $results -join "`n`n"
    } catch {
        # Handle errors gracefully
        $script:txtReportResults.Text = "Error generating reports: $($_.Exception.Message)"
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Reports-Generation"
    }
}



function Generate-OffboardingReport {
    param (
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [string]$Format,
        [string]$Timestamp
    )

    try {
        # Dynamically determine base path
        $BasePath = Get-BasePath
        $BasePath = Split-Path -Parent (Split-Path -Parent $BasePath)  # Move two folders higher
        Write-Output "BasePath resolved to: $BasePath"

        # Define paths for logs and reports
        $reportPath = Join-Path -Path $BasePath -ChildPath "Reports\OffboardingReport_$Timestamp.$($Format.ToLower())"
        $logPath = Join-Path -Path $BasePath -ChildPath "Logs\OffboardingActivities"

        # Ensure directories exist
        if (-not (Test-Path $logPath)) {
            throw "Log directory not found: $logPath"
        }
        if (-not (Test-Path (Split-Path -Parent $reportPath))) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $reportPath) -Force | Out-Null
        }

        $activities = @()

        # Get log files matching the date range
        $logFiles = Get-ChildItem -Path $logPath -Filter "*.log" |
            Where-Object {
                $_.BaseName -match "^\d{8}$" -and (
                    $logDate = [DateTime]::ParseExact($_.BaseName, "yyyyMMdd", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None) -ne $null
                ) -and ($logDate -ge $StartDate -and $logDate -le $EndDate)
            }

        if ($logFiles.Count -eq 0) {
            Write-Output "No log files found in the specified date range ($StartDate to $EndDate)."
            return "No log files found in the specified date range."
        }

        Write-Output "Log files to process: $($logFiles.FullName)"

        foreach ($file in $logFiles) {
            Write-Output "Processing file: $($file.FullName)"
    
            foreach ($line in (Get-Content -Path $file.FullName -Encoding UTF8)) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
    
                try {
                    if ($line -match "\|") {
                        # Parse pipe-delimited format
                        $parts = $line -split "\|"
                        $activity = [PSCustomObject]@{
                            Timestamp = $parts[0].Trim()
                            UserEmail = $parts[1]
                            Action = $parts[2]
                            Result = $parts[3]
                            Platform = $parts[4]
                        }
    
                        # Debug parsed activity
                        Write-Output "Parsed activity: $($activity | Out-String)"
    
                        # Convert and filter by date
                        $activityDate = [DateTime]::ParseExact($activity.Timestamp, "yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
                        if ($activityDate -ge $startDate -and $activityDate -le $endDate) {
                            Write-Output "Activity matches date range: $($activity | Out-String)"
                            $activities += $activity
                        } else {
                            Write-Output "Activity outside date range: $activityDate"
                        }
                    } else {
                        Write-Output "Skipping line (not pipe-delimited): $line"
                    }
                } catch {
                    Write-Output "Error processing line: $_"
                }
            }
        }

        if ($activities.Count -gt 0) {
            $activities | Select-Object Timestamp, UserEmail, Action, Result, Platform |
            Export-Csv -Path $reportPath -NoTypeInformation
            return "Report generated with $($activities.Count) entries at $reportPath"
        }
        return "No activities found in date range"
    } catch {
        Write-Output "Error: $($_.Exception.Message)"
        return "Error generating report: $($_.Exception.Message)"
    }
}


function Generate-LicenseReport {
    param (
        [string]$Format,
        [string]$Timestamp
    )

    try {
        # Dynamically determine base path
        $BasePath = Get-BasePath
        $BasePath = Split-Path -Parent (Split-Path -Parent $BasePath)  # Move two folders higher
        Write-Output "BasePath resolved to: $BasePath"

        # Define the report path
        $reportDirectory = Join-Path $BasePath "Reports"
        $reportPath = Join-Path $reportDirectory "LicenseReport_$Timestamp.$($Format.ToLower())"

        # Ensure the report directory exists
        if (-not (Test-Path $reportDirectory)) {
            New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
            Write-Output "Created report directory: $reportDirectory"
        }

        # Placeholder for license information retrieval and report generation logic
        Write-Output "Generating license report..."

        # Example: Create a dummy report for demonstration purposes
        $licenseData = @(
            [PSCustomObject]@{ Name = "User1"; License = "E5"; Status = "Active" },
            [PSCustomObject]@{ Name = "User2"; License = "E3"; Status = "Inactive" }
        )

        # Export data to the chosen format
        if ($Format.ToLower() -eq "csv") {
            $licenseData | Export-Csv -Path $reportPath -NoTypeInformation
        } elseif ($Format.ToLower() -eq "json") {
            $licenseData | ConvertTo-Json -Depth 2 | Out-File -FilePath $reportPath -Encoding UTF8
        } else {
            throw "Unsupported format: $Format. Please use 'csv' or 'json'."
        }

        Write-Output "Report generated successfully at: $reportPath"
        return "Generated License Report: $reportPath"
    } catch {
        Write-Output "Error: $($_.Exception.Message)"
        return "Error generating License Report: $($_.Exception.Message)"
    }
}