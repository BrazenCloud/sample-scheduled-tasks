param (
    [string]$BrazenCloudEmail,
    [string]$BrazenCloudPassword,
    [string]$BrazenCloudDomain = 'portal.brazencloud.com'
)
Write-Host 'Authenticating to the BrazenCloud API...'
Connect-BrazenCloud -Email $BrazenCloudEmail -Password (ConvertTo-SecureString $BrazenCloudPassword -AsPlainText -Force) -Domain $BrazenCloudDomain

Sync-BcResourceYaml -PathToYaml .\jobs\definitions.yaml -Verbose