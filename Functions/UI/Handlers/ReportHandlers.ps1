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
        # Ensure at least one report is selected
        if (-not ($script:chkOffboardingReport.IsChecked -or $script:chkLicenseReport.IsChecked)) {
            $script:txtReportResults.Text = "Please select at least one report to generate."
            return
        }

        if ($script:chkLicenseReport.IsChecked -and -not (Get-AppSetting -SettingName "DemoMode" -or $script:O365Connected)) {
            $script:txtReportResults.Text = "Please connect to O365 first before generating license reports."
            return
        }

        # Get user-selected parameters and normalize date ranges
        $startDate = [datetime]::ParseExact($script:dpStartDate.SelectedDate.ToString("yyyy-MM-dd 00:00:00"), "yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $endDate = [datetime]::ParseExact($script:dpEndDate.SelectedDate.ToString("yyyy-MM-dd 23:59:59"), "yyyy-MM-dd HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)
        $format = $script:cmbReportFormat.SelectedItem.Content
        $results = @()

        # Dynamically determine the base path and move two folders higher
        $BasePath = $PSScriptRoot
        if (-not $BasePath) {
            $BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
        }
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
            $offboardingReport = Generate-OffboardingReport -StartDate $startDate -EndDate $endDate -Format $format -Timestamp $timestamp
            $results += $offboardingReport.DisplayText + "`n`n"

            # Store Offboarding Report Data for Export
            $script:currentOffboardingReport = $offboardingReport
        }


        if ($script:chkLicenseReport.IsChecked) {
            # Get user details
            $selectedUserUPN = if (Get-AppSetting -SettingName "DemoMode") {
                $script:SelectedUser.UserPrincipalName  
            } elseif ($script:UseADModule) {
                $script:SelectedUser.mail
            } else {
                $script:SelectedUser.Properties["mail"][0]
            }

            if (-not $selectedUserUPN) {
                $script:txtReportResults.Text = "Selected user does not have a valid UserPrincipalName."
                return
            }

            $licenseReport = Generate-LicenseReport -Format $format -Timestamp $timestamp -UserPrincipalName $selectedUserUPN
            $results += $licenseReport.DisplayText + "`n`n"

             # Store License Report Data for Export
             $script:currentLicenseReport = $licenseReport
        }

        # Display the results in the UI
        $script:txtReportResults.Text = $results

        # Enable the export button if results are generated
        if ($results -ne "") {
            $script:btnExportReport.IsEnabled = $true
            $script:currentReportData = @{
                DisplayText = $results
                Data = @()  # You can populate this with the actual data if needed
            }
        }
    } catch {
        # Handle errors gracefully
        $script:txtReportResults.Text = "Error generating reports: $($_.Exception.Message)"
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Reports-Generation"
    }
}

function Generate-LicenseReport {
    param (
        [string]$Format,
        [string]$Timestamp,
        [string]$UserPrincipalName
    )

    if (Get-AppSetting -SettingName "DemoMode") {
        try {
            Write-Host "Retrieving mock license information..."
            $licenseData = @()
            
            $mockUsers = Get-MockO365Users
            $mockLicenses = Get-MockO365Licenses
            
            foreach ($user in $mockUsers) {
                foreach ($license in $user.AssignedLicenses) {
                    $sku = $mockLicenses.Skus | Where-Object { $_.SkuId -eq $license.SkuId }
                    $licenseData += [PSCustomObject]@{
                        DisplayName = $user.DisplayName
                        UserPrincipalName = $user.UserPrincipalName
                        LicenseName = $sku.DisplayName
                        Status = "Active"
                    }
                }
            }

            # Format the display output
            $displayText = @"
License Report (Demo Mode)
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
            Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "License-Report-Demo"
            return "Error generating License Report (Demo): $($_.Exception.Message)"
        }
    }
    else {

    try {
        Write-Host "Retrieving license information for user: $UserPrincipalName"
        $licenseData = @()

        # Get all SKUs
        $skus = Get-MgSubscribedSku -All
        $skuLookup = @{ }
        foreach ($sku in $skus) {
            $skuLookup[$sku.SkuId] = $sku.SkuPartNumber
        }

        # Get the selected user's licenses
        $user = Get-MgUser -UserId $UserPrincipalName -Property Id, DisplayName, UserPrincipalName, AssignedLicenses -ErrorAction Stop
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

        # Format the display output
        $displayText = @"
License Report for $UserPrincipalName
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Total Licenses: $($licenseData.Count)

License Details:
$($licenseData | ForEach-Object {
    "  License: $($_.LicenseName)
  Status: $($_.Status)"
})
"@

        return @{
            DisplayText = $displayText
            Data = $licenseData
            Type = "License"
        }
    } catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "License-Report"
        return "Error generating License Report: $($_.Exception.Message)"
    }
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
        $logPath = Join-Path $BasePath "Logs/OffboardingActivities"
        Write-Host $logPath
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
        # Dynamically determine the base path and move two folders higher
        $BasePath = $PSScriptRoot
        if (-not $BasePath) {
            $BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
        }
        $BasePath = Split-Path -Parent (Split-Path -Parent $BasePath)  # Move two folders higher
        $reportDirectory = Join-Path $BasePath "Reports"

        if (-not (Test-Path $reportDirectory)) {
            New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $format = $script:cmbReportFormat.SelectedItem

        # Export Offboarding Report if available
        if ($script:currentOffboardingReport) {
            $offboardingReportPath = Join-Path $reportDirectory "OffboardingReport_$timestamp.$($format.ToLower())"
            $script:currentOffboardingReport.Data | Export-Csv -Path $offboardingReportPath -NoTypeInformation
            $script:txtReportResults.Text += "`nOffboarding report exported to: $offboardingReportPath"
        }

        # Export License Report if available
        if ($script:currentLicenseReport) {
            $licenseReportPath = Join-Path $reportDirectory "LicenseReport_$timestamp.$($format.ToLower())"
            $script:currentLicenseReport.Data | Export-Csv -Path $licenseReportPath -NoTypeInformation
            $script:txtReportResults.Text += "`nLicense report exported to: $licenseReportPath"
        }

    } catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Location "Report-Export"
        $script:txtReportResults.Text += "`nError exporting reports: $($_.Exception.Message)"
    }
}
