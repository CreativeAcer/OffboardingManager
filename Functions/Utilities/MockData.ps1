function Get-MockUsers {
    return @(
        [PSCustomObject]@{
            UserPrincipalName = "john.doe@company.com"
            DisplayName = "John Doe"
            EmailAddress = "john.doe@company.com"
            Department = "IT"
            Title = "System Administrator"
            Manager = "CN=Jane Manager,OU=Users,DC=company,DC=com"
            Office = "Main Office"
            OfficePhone = "+31 123 456 789"
            MobilePhone = "+31 612 345 678"
            Enabled = $true
            LastLogonDate = (Get-Date).AddDays(-1)
            Created = (Get-Date).AddYears(-2)
            Modified = (Get-Date).AddDays(-10)
            AccountExpirationDate = $null
            PasswordLastSet = (Get-Date).AddMonths(-2)
            PasswordNeverExpires = $false
            LockedOut = $false
            MemberOf = @(
                "CN=IT Department,OU=Groups,DC=company,DC=com",
                "CN=VPN Users,OU=Groups,DC=company,DC=com",
                "CN=Office 365 Users,OU=Groups,DC=company,DC=com"
            )
        },
        [PSCustomObject]@{
            UserPrincipalName = "jane.smith@company.com"
            DisplayName = "Jane Smith"
            EmailAddress = "jane.smith@company.com"
            Department = "HR"
            Title = "HR Manager"
            Manager = "CN=John Director,OU=Users,DC=company,DC=com"
            Office = "Branch Office"
            OfficePhone = "+31 123 456 790"
            MobilePhone = "+31 612 345 679"
            Enabled = $true
            LastLogonDate = (Get-Date).AddHours(-2)
            Created = (Get-Date).AddYears(-3)
            Modified = (Get-Date).AddDays(-5)
            AccountExpirationDate = $null
            PasswordLastSet = (Get-Date).AddMonths(-1)
            PasswordNeverExpires = $false
            LockedOut = $false
            MemberOf = @(
                "CN=HR Department,OU=Groups,DC=company,DC=com",
                "CN=Management,OU=Groups,DC=company,DC=com",
                "CN=Office 365 Users,OU=Groups,DC=company,DC=com"
            )
        },
        [PSCustomObject]@{
            UserPrincipalName = "bob.wilson@company.com"
            DisplayName = "Bob Wilson"
            EmailAddress = "bob.wilson@company.com"
            Department = "Finance"
            Title = "Financial Analyst"
            Manager = "CN=Jane Smith,OU=Users,DC=company,DC=com"
            Office = "Main Office"
            OfficePhone = "+31 123 456 791"
            MobilePhone = "+31 612 345 680"
            Enabled = $true
            LastLogonDate = (Get-Date).AddDays(-1)
            Created = (Get-Date).AddYears(-1)
            Modified = (Get-Date).AddDays(-15)
            AccountExpirationDate = $null
            PasswordLastSet = (Get-Date).AddMonths(-3)
            PasswordNeverExpires = $false
            LockedOut = $false
            MemberOf = @(
                "CN=Finance Department,OU=Groups,DC=company,DC=com",
                "CN=Office 365 Users,OU=Groups,DC=company,DC=com"
            )
        }
    )
}

function Get-MockUser {
    param (
        [string]$UserPrincipalName
    )
    
    return (Get-MockUsers | Where-Object { $_.UserPrincipalName -eq $UserPrincipalName })
}



# 0365 Mock data
# Add these functions to your existing MockData.ps1

function Get-MockO365Licenses {
    return @{
        Skus = @(
            [PSCustomObject]@{
                SkuId = "c7df2760-2c81-4ef7-b578-5b5392b571df"
                SkuPartNumber = "ENTERPRISEPREMIUM"
                DisplayName = "Office 365 E5"
            },
            [PSCustomObject]@{
                SkuId = "6fd2c87f-b296-42f0-b197-1e91e994b900"
                SkuPartNumber = "ENTERPRISESTANDARD"
                DisplayName = "Office 365 E3"
            }
        )
    }
}

function Get-MockO365Users {
    $users = Get-MockUsers
    $licenses = Get-MockO365Licenses

    return $users | ForEach-Object {
        [PSCustomObject]@{
            DisplayName = $_.DisplayName
            UserPrincipalName = $_.UserPrincipalName
            Mail = $_.EmailAddress
            AccountEnabled = $_.Enabled
            AssignedLicenses = @(
                @{
                    SkuId = $licenses.Skus[0].SkuId  # E5 License
                }
            )
        }
    }
}

function Get-MockO365User {
    param (
        [string]$UserPrincipalName
    )
    
    return (Get-MockO365Users | Where-Object { $_.UserPrincipalName -eq $UserPrincipalName })
}