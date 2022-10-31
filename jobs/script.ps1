param (
    [string]$BrazenCloudEmail,
    [string]$BrazenCloudPassword,
    [string]$BrazenCloudDomain = 'portal.brazencloud.com'
)
Write-Host 'Authenticating to the BrazenCloud API...'
Connect-BrazenCloud -Email $RunwayEmail -Password (ConvertTo-SecureString $RunwayPassword -AsPlainText -Force) -Domain $BrazenCloudDomain

Sync-BcResourceYaml -PathToYaml .\jobs\definition.yaml -Verbose