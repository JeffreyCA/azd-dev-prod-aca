// Network infrastructure module for secure VNet integration and private networking
// This module creates:
// 1. Virtual Network with single subnet for Container Apps environment and private endpoints
// 2. Private DNS Zone for blob storage resolution within the VNet
// 3. VNet link to enable DNS resolution for private endpoints
//
// Security Benefits:
// - Isolates network traffic to private network
// - Enables secure communication between services
// - Provides DNS resolution for private endpoints
// - Simplified networking compared to App Service (single subnet vs dual subnet)

@description('The location used for all deployed resources')
param location string

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Abbreviations for Azure resource naming')
param abbrs object

@description('Unique token for resource naming')
param resourceToken string

// Virtual Network for secure networking
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: '${abbrs.networkVirtualNetworks}${resourceToken}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'container-app-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: [
            {
              name: 'container-apps-delegation'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// Private DNS Zone for storage account
resource privateDnsZoneStorage 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

// VNet link for private DNS zone
resource privateDnsZoneStorageVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: 'storage-vnet-link'
  parent: privateDnsZoneStorage
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false
  }
}

// Outputs for use by other modules
@description('Virtual Network resource ID')
output virtualNetworkId string = virtualNetwork.id

@description('Container App subnet ID (also used for private endpoints)')
output containerAppSubnetId string = '${virtualNetwork.id}/subnets/container-app-subnet'

@description('Private DNS Zone ID for storage account')
output privateDnsZoneStorageId string = privateDnsZoneStorage.id

@description('Virtual Network name')
output virtualNetworkName string = virtualNetwork.name
