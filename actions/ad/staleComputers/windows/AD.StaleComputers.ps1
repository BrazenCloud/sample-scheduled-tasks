# Functions
Function Get-ADStaleComputers {
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
        -and (Created -lt $CreatedBefore)
    }
    if ($PSBoundParameters.Keys -contains 'Properties') {
        [string[]]$Properties += 'LastLogonDate','Created'
    } else {
        $Properties = 'LastLogonDate','Created'
    }
    Get-ADComputer -Filter $filter -Properties $Properties
}

# Load Settings
$settings = Get-Content .\settings.json | ConvertFrom-Json
$settings

# Get stale computers
$staleComps = Get-ADStaleComputers -NoLogonSince $settings.'Last Logon' -CreatedBefore $settings.'Created Before'

Write-Host "Found: $($staleComps.count)"

# Clean them up
foreach ($comp in $staleComps) {
    Set-AdComputer -Enabled $false
    Move-ADObject $comp.DistinguishedName -Target $settings.'Disabled OU'
}

# Log the copmuters
$dateStr = Get-date -Format yyyy-MM-dd_hh-mm-ss
$staleComps | Select-Object Name,DistinguishedName,LastLogonDate,Created | Export-Csv ".\results\StaleComputers_$dateStr.csv" -NoTypeInformation

# Grab std out
Copy-Item .\std.out -Destination .\results