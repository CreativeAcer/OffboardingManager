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