// Step #1 plan the interface i.e. parameters
param location string = resourceGroup().location
param prefix string
// vnet specific
param vnetSettings object = {
  addressPrefixes: [
    '10.0.0.0/20'
  ]
  subnets: [
    {
      name: 'subnet1'
      addressPrefix: '10.0.0.0/22'
    }
  ]
}


// network security groups to be used at the subnet level
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${prefix}-default-nsg'
  location: location
  properties: {
    securityRules: [] // only take the default nsg rules - deny all
  }
}


// vnet resource
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: '${prefix}-vnet-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetSettings.addressPrefixes
    }
    subnets: [ for subnet in vnetSettings.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: {
          id: networkSecurityGroup.id
        }
      }
    }]
  }
}
