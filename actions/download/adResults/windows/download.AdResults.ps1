# Load Settings
$settings = Get-Content .\settings.json | ConvertFrom-Json
$settings

# Download results
$outFolder = '.\out'
if (-not (Test-Path $outFolder)) {
    New-Item $outFolder -ItemType Directory
}
& .\windows\runway.exe -N -S $settings.host download --directory $outFolder

# Organize
foreach ($zip in (Get-ChildItem $outFolder -Filter *.zip)) {
    Expand-Archive $zip.FullName -DestinationPath $settings.Path
}