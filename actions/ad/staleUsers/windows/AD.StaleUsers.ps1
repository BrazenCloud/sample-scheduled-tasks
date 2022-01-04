# Functions
Function Get-ADStaleUsers {
    [cmdletbinding()]
    Param (
        [ValidateNotNullOrEmpty()]
        [datetime]$NoLogonSince = (Get-Date).AddDays(-90),
        [ValidateNotNullOrEmpty()]
        [datetime]$CreatedBefore = (Get-Date).AddDays(-14),
        [string[]]$Properties
    )
    $NoLogonString = $NoLogonSince.ToFileTime()
    $filter = {
        ((LastLogonTimeStamp -lt $NoLogonString) -or (LastLogonTimeStamp -notlike "*"))
        -and (Created -lt $createdBefore)
    }
    if ($PSBoundParameters.Keys -contains 'Properties') {
        [string[]]$Properties += 'LastLogonDate','Created'
    } else {
        $Properties = 'LastLogonDate','Created'
    }
    Get-ADUser -Filter $filter -Properties $Properties
}

# Load Settings
$settings = Get-Content .\settings.json | ConvertFrom-Json
$settings

# Get stale computers
$staleUsers = Get-ADStaleUsers -NoLogonSince $settings.'Last Logon' -CreatedBefore $settings.'Created Before'

Write-Host "Found: $($staleUsers.count)"

# Clean them up
foreach ($user in $staleUsers) {
    Set-AdComputer -Enabled $false
    Move-ADObject $comp.DistinguishedName -Target $settings.'Disabled OU'
}

# Log the users
$dateStr = Get-date -Format yyyy-MM-dd_hh-mm-ss
$staleUsers | Select-Object Name,DistinguishedName,LastLogonDate,Created | Export-Csv ".\results\StaleUsers_$dateStr.csv" -NoTypeInformation

# Grab std out
Copy-Item .\std.out -Destination .\results