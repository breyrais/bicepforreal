# bicepforreal

Following this [series](https://bicepforreal.com) to learn more about Bicep and Microsoft Azure.

## Commands
`az deployment group create -g bicepforreal --template-file core.bicep`

`az deployment group what-if -g bicepforreal --template-file core.bicep`

with parameter file

`az deployment group create -g bicepforreal --template-file core.bicep --parameters ..\configs\dev.json`