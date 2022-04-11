param (
    [string]$RunwayEmail,
    [string]$RunwayPassword
)
Write-Host 'Importing PsRunway module...'
#Import-Module PsRunway

Write-Host 'Authenticating to the Runway API...'
Connect-Runway -Email $RunwayEmail -Password (ConvertTo-SecureString $RunwayPassword -AsPlainText -Force)

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
        $existingJob = Import-RwJob -JobId $newJob.JobId
    } else {
        Write-Host "- The job already exists, updating existing..."
        $existingJob = Import-RwJob -JobId ($existingJobs | Where-Object {$_.Name -eq $job.Name}).Id
    }
    # Assign Endpoints
    foreach ($runner in $job.RunnerNames) {
        $existingRunner = $existingRunners | Where-Object {$_.AssetName -eq $runner}
        if ($null -ne $existingRunner) {
            Write-Host "- Assigning runner '$runner' to the job..."
            Add-RwSetToSet -TargetSetId $existingJob.EndpointSetId -ObjectIds $existingRunner.AssetId
        } else {
            Write-Host "# Unable to find runner with name: '$runner'"
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
                    Write-Host "# Unable to find connection with name: '$($action.ConnectionName)'"
                }
            } else {
                [Runway.PowerShell.Models.IActionSettingRequest]@{
                    RepositoryActionId = ($existingActions | Where-Object {$_.Name -eq $action.Name}).Id
                }
            }
        } else {
            Write-Host "# Unable to find action with name: '$($action.Name)'"
        }
    }
    Write-Host "- Applying the new action chain..."
    Set-RwJobAction -JobId $existingJob.Id -OutFile .\jobAction.txt -Request @(
        $actions
    )

    # Assign Schedule
    # There is a bug in PsRunway that requires this weird usage of Set-RwJobSchedule
    # Will be fixed in 0.2.0
    Write-Host "- Assigning the new schedule"
    $schedule = [Runway.PowerShell.Models.IJobSchedule]@{
        ScheduleType = $job.Schedule.Type
        RepeatMinutes = $job.Schedule.RepeatMinutes
        Weekdays = $job.Schedule.Weekdays
        Schedule = $job.Schedule.Time
    }
    $scheduleSplat = @{
        JobId = $existingJob.Id
        OutFile = '\jobSchedule.txt'
        Schedule = $schedule
        RepeatMinutes = $job.Schedule.RepeatMinutes
        ScheduleType = $job.Schedule.Type
        Weekdays = $job.Schedule.Weekdays
    }
    Set-RwJobSchedule @scheduleSplat
}