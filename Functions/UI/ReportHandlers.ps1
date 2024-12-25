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
        $script:btnExportReport = $Window.FindName("btnExportReport")
        $script:txtReportResults = $Window.FindName("txtReportResults")

        # Initialize format combo box
        $script:cmbReportFormat.Items.Clear()
        $script:cmbReportFormat.Items.Add("CSV")
        $script:cmbReportFormat.SelectedIndex = 0

        # Set default dates
        $script:dpStartDate.SelectedDate = (Get-Date).AddDays(-30)
        $script:dpEndDate.SelectedDate = Get-Date

        # Store current report data for export
        $script:currentReportData = $null

        # Add click handler for generate button
        $script:btnGenerateReport.Add_Click({
            $script:btnExportReport.IsEnabled = $false
            $script:txtReportResults.Text = "Generating report, please wait..."
            Generate-Reports -Credential $Credential
        })

        # Add click handler for export button
        $script:btnExportReport.Add_Click({
            if ($script:currentReportData) {
                Export-ReportData
            }
        })

        Write-Host "Reports Tab initialization completed"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Reports-TabInit"
        throw
    }
}

function Generate-Reports {
    param (
        [System.Management.Automation.PSCredential]$Credential
    )

    try {
        if (-not ($script:chkOffboardingReport.IsChecked -or $script:chkLicenseReport.IsChecked)) {
            $script:txtReportResults.Text = "Please select at least one report to generate."
            return
        }

        # Check Graph connection if License Report is selected
        if ($script:chkLicenseReport.IsChecked) {
            try {
                $context = Get-MgContext -ErrorAction Stop
                if (-not $context) {
                    $script:txtReportResults.Text = "Please connect to Office 365 in the O365 tab first before generating license reports."
                    return
                }
            }
            catch {
                $script:txtReportResults.Text = "Please connect to Office 365 in the O365 tab first before generating license reports."
                return
            }
        }

        $results = @()
        
        if ($script:chkLicenseReport.IsChecked) {
            $licenseReport = Generate-LicenseReport
            $results += $licenseReport
            $script:currentReportData = $licenseReport
        }

        if ($script:chkOffboardingReport.IsChecked) {
            $startDate = [datetime]::ParseExact($script:dpStartDate.SelectedDate.ToString("yyyy-MM-dd 00:00:00"), "yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
            $endDate = [datetime]::ParseExact($script:dpEndDate.SelectedDate.ToString("yyyy-MM-dd 23:59:59"), "yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
            
            $offboardingReport = Generate-OffboardingReport -StartDate $startDate -EndDate $endDate
            $results += $offboardingReport
            $script:currentReportData = $offboardingReport
        }

        # Enable export button if we have data
        $script:btnExportReport.IsEnabled = $true
        
        # Display results
        $script:txtReportResults.Text = $results -join "`n`n"
    }
    catch {
        $script:txtReportResults.Text = "Error generating reports: $($_.Exception.Message)"
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Reports-Generation"
    }
}

function Generate-LicenseReport {
    try {
        Write-Host "Retrieving license information..."
        $licenseData = @()

        # Get all SKUs first
        $skus = Get-MgSubscribedSku -All
        $skuLookup = @{}
        foreach ($sku in $skus) {
            $skuLookup[$sku.SkuId] = $sku.SkuPartNumber
        }

        # Get all licensed users
        $users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, AssignedLicenses
        
        foreach ($user in $users) {
            if ($user.AssignedLicenses) {
                foreach ($license in $user.AssignedLicenses) {
                    $licenseName = $skuLookup[$license.SkuId]
                    if (-not $licenseName) {
                        $licenseName = "Unknown License ($($license.SkuId))"
                    }
                    
                    $licenseData += [PSCustomObject]@{
                        DisplayName = $user.DisplayName
                        UserPrincipalName = $user.UserPrincipalName
                        LicenseName = $licenseName
                        Status = "Active"
                    }
                }
            }
        }

        # Format the display output
        $displayText = @"
License Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Total Licensed Users: $($licenseData.Count)

License Distribution:
$($licenseData | Group-Object LicenseName | ForEach-Object {
    "  $($_.Name): $($_.Count) users"
})

Detailed User List:
$($licenseData | ForEach-Object {
    "User: $($_.DisplayName)
    Email: $($_.UserPrincipalName)
    License: $($_.LicenseName)
    Status: $($_.Status)
    " + "-" * 50
})
"@

        return @{
            DisplayText = $displayText
            Data = $licenseData
            Type = "License"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "License-Report"
        return "Error generating License Report: $($_.Exception.Message)"
    }
}

function Generate-OffboardingReport {
    param (
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )

    try {
        Write-Host "Generating offboarding report..."
        
        $BasePath = Get-BasePath
        $BasePath = Split-Path -Parent (Split-Path -Parent $BasePath) # Move two folders higher
        $logPath = Join-Path $BasePath "Logs"
        $activities = @()

        $logFiles = Get-ChildItem -Path $logPath -Filter "*.log"
        
        foreach ($file in $logFiles) {
            foreach ($line in (Get-Content $file.FullName)) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }

                try {
                    if ($line -match "\|") {
                        $parts = $line -split "\|"
                        if ($parts.Count -ge 5) {
                            $activity = [PSCustomObject]@{
                                Timestamp = $parts[0].Trim()
                                UserEmail = $parts[1]
                                Action = $parts[2]
                                Result = $parts[3]
                                Platform = $parts[4]
                            }

                            $activityDate = [DateTime]::ParseExact($activity.Timestamp, "yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
                            if ($activityDate -ge $StartDate -and $activityDate -le $EndDate) {
                                $activities += $activity
                            }
                        }
                    }
                }
                catch {
                    Write-Host "Error processing log line: $_"
                    continue
                }
            }
        }

        # Format the display output
        $displayText = @"
Offboarding Activity Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Date Range: $($StartDate.ToString("yyyy-MM-dd")) to $($EndDate.ToString("yyyy-MM-dd"))

Total Activities: $($activities.Count)

Activity Summary:
$($activities | Group-Object Action | ForEach-Object {
    "  $($_.Name): $($_.Count) actions"
})

Detailed Activity List:
$($activities | ForEach-Object {
    "Timestamp: $($_.Timestamp)
    User: $($_.UserEmail)
    Action: $($_.Action)
    Result: $($_.Result)
    Platform: $($_.Platform)
    " + "-" * 50
})
"@

        return @{
            DisplayText = $displayText
            Data = $activities
            Type = "Offboarding"
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Offboarding-Report"
        return "Error generating Offboarding Report: $($_.Exception.Message)"
    }
}

function Export-ReportData {
    try {
        $BasePath = Get-BasePath
        $BasePath = Split-Path -Parent (Split-Path -Parent $BasePath) # Move two folders higher
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportDirectory = Join-Path $BasePath "Reports"
        
        if (-not (Test-Path $reportDirectory)) {
            New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
        }

        $format = $script:cmbReportFormat.SelectedItem
        $reportPath = Join-Path $reportDirectory "$($script:currentReportData.Type)Report_$timestamp.$($format.ToLower())"

        $script:currentReportData.Data | Export-Csv -Path $reportPath -NoTypeInformation
        $script:txtReportResults.Text += "`n`nReport exported to: $reportPath"
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Report-Export"
        $script:txtReportResults.Text += "`n`nError exporting report: $($_.Exception.Message)"
    }
}