# Get the current script's directory path
$rootFolder = $PSScriptRoot
$reportFile = "$rootFolder\folderstructurereport.txt"

# Helper function to display the folder structure
function Show-FolderStructure {
    param (
        [string]$folderPath,  # Path of the folder to display
        [int]$indentLevel = 0,  # Indentation level for display
        [string]$outputFile     # File to output the folder structure
    )
    
    # Get all subdirectories and files within the folder
    $directories = Get-ChildItem -Path $folderPath -Directory
    $files = Get-ChildItem -Path $folderPath -File

    # Build the lines to show
    $prefix = '│   ' * $indentLevel  # Vertical line with spaces for indentation
    $lastItemPrefix = '    ' * $indentLevel  # Space for last item (no vertical line)

    # Display files first
    $itemCount = $directories.Count + $files.Count
    $currentItem = 0

    foreach ($file in $files) {
        $currentItem++
        if ($currentItem -eq $itemCount) {
            "$prefix└── $($file.Name)" | Out-File -FilePath $outputFile -Append
        } else {
            "$prefix├── $($file.Name)" | Out-File -FilePath $outputFile -Append
        }
    }

    # Display directories, maintaining the structure
    $currentItem = 0
    foreach ($directory in $directories) {
        $currentItem++
        if ($currentItem -eq $itemCount) {
            "$prefix└── $($directory.Name)/" | Out-File -FilePath $outputFile -Append
        } else {
            "$prefix├── $($directory.Name)/" | Out-File -FilePath $outputFile -Append
        }

        # Recursively display subdirectories
        Show-FolderStructure -folderPath $directory.FullName -indentLevel ($indentLevel + 1) -outputFile $outputFile
    }
}

# Initialize or clear the report file
Clear-Content -Path $reportFile -ErrorAction SilentlyContinue

# Output the folder structure
Write-Host "Generating folder structure for: $rootFolder"
"Folder structure for: $rootFolder" | Out-File -FilePath $reportFile -Append
Show-FolderStructure -folderPath $rootFolder -indentLevel 0 -outputFile $reportFile

Write-Host "Folder structure report generated at: $reportFile"
