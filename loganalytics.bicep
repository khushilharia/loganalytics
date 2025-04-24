@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Location for the workspace')
param location string = resourceGroup().location

@description('Name of the virtual network')
param vnetName string

@description('Name of the subnet to use for the Private Endpoint')
param subnetName string

@description('Name of the resource group that contains the VNet')
param vnetResourceGroup string = resourceGroup().name

// Reference the existing VNet and subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: subnetName
  parent: vnet
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
  }
}

// Private Endpoint for Log Analytics
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: '${workspaceName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'loganalyticsConnection'
        properties: {
          privateLinkServiceId: logAnalytics.id
          groupIds: [ 'workspaces' ]
        }
      }
    ]
  }
}
