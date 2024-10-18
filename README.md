# bicepforreal

Following this [series](https://bicepforreal.com) to learn more about Bicep and Microsoft Azure.

## Commands
`az group create --name bicep-dev --location eastus2`

`az deployment group create -g bicep-dev --template-file core.bicep`

`az deployment group what-if -g bicep-dev --template-file core.bicep`

with parameter file

`az deployment group create -g bicep-dev --template-file core.bicep --parameters ..\configs\dev.json`