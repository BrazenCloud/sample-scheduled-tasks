# BrazenCloud Sample Scheduled Task Repository

This repository exists to demonstrate how to configure a BrazenCloud scheduled Job using a configuration stored in Git, the [BrazenCloud PowerShell module](https://github.com/brazencloud/powershell), and the [BrazenCloud YAML module](https://github.com/brazencloud/yaml).

## Components

There are several items to be aware of:

- [Actions](actions): These are all of the actions that this scheduled job is dependent on. They do not need to be in this repository, they could be stored in a separate repository. However, they are here for demonstration purposes.
- [Jobs](jobs): This is where the jobs are each defined in `JSON` with a script to deploy them.
  - [Job deployment script](jobs/script.ps1): This script has all of the BrazenCloud magic. It will connect to the BrazenCloud API and leverage our YAML module to ensure that all of the jobs defined in the [definitions.yaml](jobs/definitions.yaml) file exist.
- [Helper scripts](repoScripts): These are used during the [Github Action Workflow](.github/workflows/cicd.yaml)
  - [publish.ps1](repoScripts/publish.ps1): Publishes Actions

## Authentication

For this to work in your environment, be sure to add your Runway email address and password as repository secrets:

- BRAZENCLOUD_EMAIL
- BRAZENCLOUD_PASSWORD