// Main resources module for Azure Container Apps infrastructure
// This configuration deploys different patterns based on environment type:
// 
// PRODUCTION (envType = 'prod'):
// 1. Virtual Network with Container Apps subnet
// 2. Private DNS Zone for storage account resolution within the VNet
// 3. Private endpoint for storage account (blocks public access)
// 4. Container Apps Environment with VNet integration enabled
// 5. Storage account with public access disabled (only accessible via private endpoint)
//
// DEVELOPMENT (envType != 'prod'):
// 1. No VNet integration - simplified connectivity
// 2. Storage account with public access enabled (with managed identity authentication)
// 3. Container Apps Environment without VNet integration
// 4. Managed identity still used for secure authentication
//
// Security Benefits (Production):
// - All traffic between Container Apps and Storage Account flows through the private network
// - Storage account is not accessible from the public internet
// - DNS resolution for storage account happens through private DNS zone
// - Container Apps can reach storage account using private IP addresses

@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Environment type - determines networking configuration')
@allowed(['dev', 'test', 'prod'])
param envType string = 'dev'

@description('Flag to indicate if the container app already exists')
param devProdPcAcaExists bool

@description('Custom domain or subdomain for the container app (leave blank to disable)')
param customDomain string

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location)

// Deploy network infrastructure only for production environments
module network './network.bicep' = if (envType == 'prod') {
  name: 'networkDeployment'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    resourceToken: resourceToken
  }
}

// Monitor application with Azure Monitor
module monitoring './monitoring.bicep' = {
  name: 'monitoringDeployment'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    resourceToken: resourceToken
  }
}

// Managed identity for the application
module appIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.1' = {
  name: 'appidentity'
  params: {
    name: '${abbrs.managedIdentityUserAssignedIdentities}app-${resourceToken}'
    location: location
  }
}

// Shared services including storage account with environment-specific connectivity
module shared './shared.bicep' = {
  name: 'sharedDeployment'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    resourceToken: resourceToken
    envType: envType
    privateEndpointSubnetId: envType == 'prod' ? network.outputs.containerAppSubnetId : ''
    privateDnsZoneStorageId: envType == 'prod' ? network.outputs.privateDnsZoneStorageId : ''
    appIdentityPrincipalId: appIdentity.outputs.principalId
  }
}

// Application hosting infrastructure
module app './app.bicep' = {
  name: 'appDeployment'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    resourceToken: resourceToken
    envType: envType
    customDomain: customDomain
    containerAppSubnetId: envType == 'prod' ? network.outputs.containerAppSubnetId : ''
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    appIdentityResourceId: appIdentity.outputs.resourceId
    appIdentityClientId: appIdentity.outputs.clientId
    appIdentityPrincipalId: appIdentity.outputs.principalId
    storageAccountName: shared.outputs.storageAccountName
    storageAccountBlobEndpoint: shared.outputs.storageAccountBlobEndpoint
    devProdPcAcaExists: devProdPcAcaExists
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = app.outputs.containerRegistryEndpoint
output AZURE_RESOURCE_DEV_PROD_PC_ACA_ID string = app.outputs.containerAppResourceId
