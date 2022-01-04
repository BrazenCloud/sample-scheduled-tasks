param (
    [string]$RunwayEmail,
    [string]$RunwayPassword
)
Write-Host 'Installing PsRunway module...'
Install-Module PsRunway -Repository PSGallery -Force

Write-Host 'Authenticating to the Runway API...'
$s = Invoke-RwAuthentication -Email $RunwayEmail -Password $RunwayPassword -Remember
$env:RunwaySessionToken = $s.Session

Write-Host 'Loading existing resources from the Runway API...'
$existingActions = (Get-RwRepository).Items
$existingRunners = (Get-RwRunner).Items
$existingJobs = (Get-RwJob).Items
$existingConnections = (Get-RwConnection).Items

Write-Host 'Loading the job definitions file...'
$jobDef = Get-Content ./jobs/definitions.json | ConvertFrom-Json

foreach ($job in $jobDef) {
    Write-Host "Starting on job: $($job.Name)"
    if ($existingJobs.Name -notcontains $job.Name) {
        # Create Job
        Write-Host "- The job does not exist, creating..."
        $newJob = New-RwJob -Name $job.Name -IsEnabled:$true -IsHidden:$false
        $existingJob = Import-RwJob -Id $newJob.JobId
    } else {
        Write-Host "- The job already exists, updating existing..."
        $existingJob = Import-RwJob -Id ($existingJobs | Where-Object {$_.Name -eq $job.Name}).Id
    }
    # Assign Endpoints
    foreach ($runner in $job.RunnerNames) {
        $existingRunner = $existingRunners | Where-Object {$_.Name -eq $runner}
        if ($null -ne $existingRunner) {
            Write-Host "- Assigning runner '$runner' to the job..."
            Add-RwSetToSet -TargetSetId $existingJob.EndpointSetId -ObjectIds $existingRunner.Id
        } else {
            Write-Host "Unable to find runner with name: '$runner'"
        }
    }

    # Assign Actions
    $actions = foreach ($action in $job.Actions) {
        Write-Host "- Adding action '$($action.Name)'..."
        $existingAction = $existingActions | Where-Object {$_.Name -eq $action.Name}
        if ($null -ne $existingAction) {
            if ($null -ne $action.ConnectionName) {
                # Action must be a connection
                $existingConnection = ($existingConnections) | Where-Object {$_.Name -eq $action.ConnectionName}
                if ($null -ne $existingConnection) {
                    [Runway.PowerShell.Models.IActionSettingRequest]@{
                        RepositoryActionId = ($existingActions | Where-Object {$_.Name -eq $action.Name}).Id
                        ConnectionId = $existingConnection.Id
                    }    
                } else {
                    Write-Host "Unable to find connection with name: '$($action.ConnectionName)'"
                }
            } else {
                [Runway.PowerShell.Models.IActionSettingRequest]@{
                    RepositoryActionId = ($existingActions | Where-Object {$_.Name -eq $action.Name}).Id
                }
            }
        } else {
            Write-Host "Unable to find action with name: '$($action.Name)'"
        }
    }
    Write-Host "- Applying the new action chain..."
    Set-RwJobAction -JobId $existingJob.Id -Request @(
        $actions
    )

    # Assign Schedule
    Write-Host "- Assigning the new schedule"
    Set-RwJobSchedule -JobId $existingJob.Id -Schedule [Runway.PowerShell.Models.IJobSchedule]@{
        ScheduleType = $job.Schedule.Type
        RepeatMinutes = $job.Schedule.RepeateMinutes
        Weekdays = $job.Schedule.Weekdays
        Schedule = $job.Schedule.Time
    }
}