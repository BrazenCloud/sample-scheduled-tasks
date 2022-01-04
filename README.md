# Runway Sample Scheduled Task Repository

This repository exists to demonstrate how to configure a Runway scheduled Job using a configuration stored in Git and the [Runway PowerShell SDK](https://github.com/runway-software/runway-powershell).

## Components

There are several items to be aware of:

- [Actions](actions): These are all of the actions that this scheduled job is dependent on. They do not need to be in this repository, they could be stored in a separate repository. However, they are here for demonstration purposes.
- [Jobs](jobs): This is where the jobs are each defined in `JSON` with a script to deploy them.
  - [Job deployment script](jobs/script.ps1): This script has all of the PsRunway magic. It will load the job definitions in the [Job definitions JSON file](jobs/definitions.json) and make sure that that job with the specified schedule exists in Runway.
- [Helper scripts](repoScripts): These are used during the [Github Action Workflow](.github/workflows/cicd.yaml)
  - [publish.ps1](repoScripts/publish.ps1): Publishes Actions
  - [replaceExecutables.ps1](repoScripts/replaceExecutables.ps1): Sourced from our [Actions Repository](https://github.com/Runway-Software/Actions/blob/main/replaceExecutables.ps1), this allows us to avoid storing executables in Git by downloading them during deployment.

## Authentication

For this to work in your environment, be sure to add your Runway email address and password as repository secrets:

- RUNWAY_EMAIL
- RUNWAY_PASSWORD