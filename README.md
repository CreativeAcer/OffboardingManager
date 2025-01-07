# AD User Offboarding Tool
[![CodeFactor](https://www.codefactor.io/repository/github/creativeacer/offboardingmanager/badge)](https://www.codefactor.io/repository/github/creativeacer/offboardingmanager)
![License](https://img.shields.io/github/license/creativeacer/offboardingmanager)
![Version](https://img.shields.io/github/v/release/creativeacer/offboardingmanager)
![PowerShell](https://img.shields.io/badge/powershell-%3E%3D%205.1-blue)

![Platform Support](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)
![Architecture](https://img.shields.io/badge/architecture-x86%20%7C%20x64%20%7C%20ARM-yellow)

<div align="center">
    <img src="./Docs/Images/MainWindow.png" alt="AD User Offboarding Tool" width="800"/>
</div>

## Table of Contents
- [Architecture Support](#architecture-support)
- [Features](#features)
- [Demo Mode](#demo-mode)
- [Screenshots](#screenshots)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Development Status](#development-status)
- [Backlog](#backlog)
- [Contributing](#contributing)
- [Usage](#usage)
- [Reporting System](#reporting-system)
- [Project Structure](#project-structure)
- [Acknowledgments](#acknowledgments)

## About
A PowerShell-based GUI tool for managing user offboarding in both Active Directory and Office 365 environments. Designed to work across multiple Windows architectures including x86, x64, and ARM. Features a demo mode for testing and training purposes.

This script is actively being developed, with frequent updates and new features.
And offcourse - sometimes some features might not be fully tested yet, if you find something don't hesitate to create an issue.

## Architecture Support
The tool automatically adapts to your system architecture:
- ✅ **x64 (64-bit)**: Full AD PowerShell module support
- ✅ **x86 (32-bit)**: Full AD PowerShell module support
- ✅ **ARM64**: LDAP-based access (Windows 11 ARM)

Use of LDAPS can be set in settings

## Features
- 🖥️ Modern WPF interface with sleek styling
- 🔒 Secure authentication for both AD and O365
- 🔄 Automatic architecture detection and adaptation
- 📊 Comprehensive reporting system with CSV export
- ⚡ Support for both AD Module and LDAP approaches
- 🎯 Demo mode for testing and training
- 📝 Activity logging and audit trails
- 🔄 Real-time task execution feedback
- ⚙️ Settings Page: easy configuration

### On-Premises Features
- Disable AD accounts
- Remove group memberships
- Move to disabled OU
- Set Expiration date
- Automatic logging of all actions

### O365 Features
- Microsoft Graph integration
- Mailbox Management
  - Convert to shared mailbox
  - Mail forwarding
  - Configure auto reply
- License management reporting
- User status verification
- Secure connection handling

### Reporting Capabilities
- Offboarding activity reports
- License usage reports
- Date range filtering
- Export to CSV
- Detailed user activity tracking

## Demo Mode
Test the application's functionality without affecting your AD environment:
- Simulated AD operations
- Mock user data
- Safe testing environment
- Training purposes
- No actual AD modifications

## Screenshots

Screenshots may be outdated due to continuous development!

<div align="center">
    <img src="./Docs/Images/Login.png" alt="Login Screen" width="400"/>
    <p><em>Login Screen</em></p>
</div>

<div align="center">
    <img src="./Docs/Images/OnPrem.png" alt="onprem Screen" width="400"/>
    <p><em>On Premise options</em></p>
</div>

<div align="center">
    <img src="./Docs/Images/O365.png" alt="O365 Screen" width="400"/>
    <p><em>O365 Options</em></p>
</div>

<div align="center">
    <img src="./Docs/Images/reporting.png" alt="Report Screen" width="400"/>
    <p><em>Reporting</em></p>
</div>

<div align="center">
    <img src="./Docs/Images/Settings.png" alt="Settings Screen" width="400"/>
    <p><em>Settings</em></p>
</div>

<div align="center">
    <img src="./Docs/Images/Settings-Workflow.png" alt="Settings Workflow Screen" width="400"/>
    <p><em>Settings Workflow crud</em></p>
</div>

## Prerequisites
- Windows PowerShell 5.1 or later
- One of the following:
  - Windows 10/11 (x64/x86) with AD PowerShell module
  - Windows 11 ARM with RSAT tools
- Microsoft Graph PowerShell module (auto-installed if needed)
- Appropriate AD and O365 permissions
- Internet connection for O365 features

## Installation

```powershell
# Clone the repository
git clone https://github.com/CreativeAcer/OffboardingManager.git

# Navigate to the directory
cd OffboardingManager

# Optional: Create desktop shortcut
.\Create-Shortcut.bat
# This will automatically create a shortcut on your desktop for you
```

## Development Status
- [x] Basic UI Implementation
- [x] AD Integration
- [x] O365 Basic Integration
- [x] Cross-Architecture Support
- [x] Demo Mode Implementation
- [x] Reporting System
- [x] Activity Logging
- [ ] Advanced O365 Features (In Development)
- [ ] Bulk Operations (Planned)
- [ ] Enhanced Reporting Features (Comming Soon)

## Backlog
These items might change the scope of this project
### General functionality
- [ ] (bulk)Creation of user
- [x] Settings page

### Teams & SharePoint
- [x] Remove from Teams groups
- [x] Transfer Teams ownership
- [ ] Archive Teams channels
- [x] Remove SharePoint permissions
- [ ] Transfer OneDrive ownership
- [ ] Back up OneDrive content

### License Management
- [x] License reassignment
- [ ] License cost analysis
- [ ] License usage optimization
- [x] Product-specific disabling
- [ ] Bulk license management

### Security & Compliance
- [x] Set Expiration date
- [ ] Revoke app permissions
- [ ] Remove MFA devices
- [ ] Clear mobile device list
- [ ] Export mailbox audit logs
- [ ] Set litigation hold
- [ ] Generate security reports

### Device Management
- [ ] Remove from Intune
- [ ] Wipe enrolled devices
- [ ] Revoke certificates
- [ ] Remove Azure AD devices
- [ ] Clear cached credentials
- [ ] Device compliance report

### Automation Features
- [ ] Scheduled offboarding
- [ ] Conditional task execution
- [x] Custom workflow builder
- [ ] Email notifications
- [ ] Manager approvals
- [ ] Integration with ticketing systems

## Contributing
Feel free to submit issues, fork the repository and create pull requests for any improvements.

## Usage
1. Launch the application using Start-Offboarding.ps1 or the desktop shortcut
2. Login with AD credentials or select Demo Mode
3. Select a user from the list
4. Choose operations from available tabs:
  - **On-Premises Tasks**
    - Disable AD account
    - Remove group memberships
    - Move to disabled OU
    - Set expiration date
  - **O365 Management**
    - Connect to Microsoft Graph
    - Mailbox Management
    - Teams and SharePoint Management
    - License Management
    - View license status
  - **Report Generation**
    - Generate activity reports
    - Export license reports
5. Execute selected tasks
6. Review real-time feedback
7. Export reports as needed

## Reporting System
### Available Reports
- **Offboarding Activity Report**
 - Track all offboarding actions
 - Filter by date range
 - View success/failure status
 - Export to CSV

- **License Usage Report**
 - Current license assignments
 - License distribution overview
 - User license details
 - Export capabilities

### Report Features
- Date range filtering
- Multiple export formats
- Detailed audit trails
- Real-time generation
- Searchable results
- Error tracking
- Activity summaries

### Export Options
- CSV format support
- Structured data output
- Timestamp inclusion
- Detailed metadata
- Audit compatibility

## Project Structure
```plaintext
/ADUserOffboarding/
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── Create-FolderstructureReport.ps1
├── Create-OffboardingShortcut.ps1
├── Create-Shortcut.bat
├── FolderStructure.txt
├── Launch-Offboarding.ps1
├── LICENSE
├── README.md
├── Start-Offboarding.ps1
├── Config/
│   ├── Colors.ps1
│   ├── Fonts.ps1
│   ├── Settings.json
│   └── Settings.ps1
├── Docs/
│   └── Images/
│   │   ├── Login.png
│   │   ├── MainWindow.png
│   │   ├── O365.png
│   │   ├── OnPrem.png
│   │   ├── reporting.png
│   │   ├── Settings-Workflow.png
│   │   └── Settings.png
├── Functions/
│   ├── Core/
│   │   ├── Environment.ps1
│   │   ├── Dependencies/
│   │   │   └── DotNetVersionCheck.ps1
│   │   ├── Logging/
│   │   │   └── Write-ActivityLog.ps1
│   ├── Data/
│   │   ├── ADModule/
│   │   │   ├── ADConnection.ps1
│   │   │   └── ADUsers.ps1
│   │   ├── LDAP/
│   │   │   ├── LDAPConnection.ps1
│   │   │   └── LDAPUsers.ps1
│   │   ├── Mock/
│   │   │   └── MockData.ps1
│   │   └── O365/
│   │   │   └── Connect-O365.ps1
│   ├── Reports/
│   ├── UI/
│   │   ├── EasterEgg.ps1
│   │   ├── Handlers/
│   │   │   ├── O365Handlers.ps1
│   │   │   ├── OnPremHandlers.ps1
│   │   │   └── ReportHandlers.ps1
│   │   ├── O365/
│   │   │   ├── Initialize-O365Tab.ps1
│   │   │   ├── Start-O365Tasks.ps1
│   │   │   ├── Tasks/
│   │   │   │   ├── Get-O365Status.ps1
│   │   │   │   ├── Set-LicenseTasks.ps1
│   │   │   │   ├── Set-MailboxTasks.ps1
│   │   │   │   └── Set-TeamsTasks.ps1
│   │   │   ├── UI/
│   │   │   │   ├── Update-ForwardingList.ps1
│   │   │   │   ├── Update-LicenseList.ps1
│   │   │   │   └── Update-TeamsOwnerList.ps1
│   │   ├── Services/
│   │   │   └── O365/
│   │   │   │   ├── Connect-O365.ps1
│   │   │   │   ├── LicenseManagement.ps1
│   │   │   │   ├── MailboxManagement.ps1
│   │   │   │   └── TeamsManagement.ps1
│   │   ├── Shared/
│   │   │   ├── LoadingScreen.ps1
│   │   │   ├── XamlHelper.ps1
│   │   │   ├── Controls/
│   │   │   │   └── Update-WorkflowDropdowns.ps1
│   │   ├── Windows/
│   │   │   ├── Login/
│   │   │   │   └── LoginDialog.ps1
│   │   │   ├── Main/
│   │   │   │   ├── Initialize-MainWindow.ps1
│   │   │   │   ├── MainWindow.ps1
│   │   │   │   ├── Show-UserDetails.ps1
│   │   │   │   ├── Update-SelectedUser.ps1
│   │   │   │   └── Update-UserList.ps1
│   │   │   └── Settings/
│   │   │   │   ├── Initialize-WorkflowSettingsTab.ps1
│   │   │   │   ├── SettingsHandler.ps1
│   │   │   │   ├── Show-SettingsWindow.ps1
│   │   │   │   └── WorkflowTaskSettings.ps1
│   │   ├── Workflow/
│   │   │   └── Initialize-WorkflowTab.ps1
│   ├── Utilities/
│   │   ├── Converters.ps1
│   │   └── PathUtils.ps1
│   └── Workflow/
│   │   ├── Start-OffboardingWorkflow.ps1
│   │   ├── WorkflowTasks.ps1
│   │   ├── Configuration/
│   │   │   ├── Get-TaskSettings.ps1
│   │   │   ├── Get-WorkflowConfiguration.ps1
│   │   │   ├── Import-WorkflowConfiguration.ps1
│   │   │   ├── Remove-WorkflowConfiguration.ps1
│   │   │   └── Save-WorkflowConfiguration.ps1
│   │   ├── Tasks/
│   │   │   └── Get-WorkflowTasks.ps1
├── Logs/
│   ├── error_log.txt
│   ├── OffboardingActivities/
│   │   ├── 20241227.log
│   │   └── 20241231.log
├── Reports/
└── XAML/
    ├── Components/
    │   └── LoadingWindow.xaml
    └── Windows/
        ├── LoginWindow.xaml
        ├── MainWindow.xaml
        └── SettingsWindow.xaml

```
## Acknowledgments
- PowerShell Community for inspiration and examples
- Microsoft Graph API Documentation
- Active Directory PowerShell Module Documentation
- Contributors and testers providing valuable feedback
