param location string = resourceGroup().location
@minLength(3)
param prefix string
param vNetName string
param containerRegistryName string
param containerRegistryUsername string
@secure()
param containerRegistryPassword string
param containerVersion string
param cosmosAccountName string
param cosmosDbName string
param cosmosContainerName string

// log analytics workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: '${prefix}-la-workspace'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}


resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-03-15' existing = {
  name: cosmosAccountName
}

var cosmosDbKey = cosmosDbAccount.listKeys().primaryMasterKey

resource env 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${prefix}-container-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', '${vNetName}', 'acaControlPlaneSubnet')
    }
  }
  resource daprStateStore 'daprComponents@2023-05-01' = {
    name: 'statestore'
    properties:{
      componentType: 'state.azure.cosmosdb'
      version: 'v1'
      scopes: [
        'lambdaapi'
      ]
      metadata: [
        {
          name: 'url'
          value: 'https://${cosmosAccountName}.documents.azure.com:443/'
        }
        {
          name: 'database'
          value: cosmosDbName
        }
        {
          name: 'collection'
          value: cosmosContainerName
        }
        {
          name: 'masterKey'
          value: cosmosDbKey
        }
      ]
    }
  }
}

resource apiApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: '${prefix}-api-container'
  location: location 
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      secrets: [
        {
          name: 'container-registry-password'
          value: containerRegistryPassword // this should be pulled from keyvault directly, that requires managed identity
        }
      ]
      registries: [
        {
          server: '${containerRegistryName}.azurecr.io'
          username: containerRegistryUsername // this should be pulled from keyvault as well
          passwordSecretRef: 'container-registry-password'
        }
      ]
      ingress: {
        external: true
        targetPort: 80
      }
      dapr: {
        enabled: true
        appPort: 3000
        appId: 'lambdaapi'
      }
    }
    template: {
      containers: [
        {
          image: '${containerRegistryName}.azurecr.io/hello-k8s-node:${containerVersion}'
          name: 'lambdaapi'
          resources: {
            cpu: '0.5'
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
      }
    }
  }
}
