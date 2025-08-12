targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Environment type - determines networking configuration (dev/test/prod)')
@allowed(['dev', 'test', 'prod'])
param envType string = 'dev'

@description('Flag to indicate if the container app already exists')
param devProdAcaExists bool = false

@description('Custom domain name for the container app')
param customDomain string

@description('Resource ID of the managed certificate')
param managedCertId string?

// The principal parameters are available for role assignments if needed in the future
// Currently, the application uses managed identity for secure access

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
  'environment-type': envType
}

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

var abbrs = loadJsonContent('../abbreviations.json')
var resourceToken = uniqueString(subscription().id, rg.id, location)

// Deploy network infrastructure only for production environments
module network '../resources/network.bicep' = if (envType == 'prod') {
  scope: rg
  name: 'networkDeployment'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    resourceToken: resourceToken
  }
}

// Monitor application with Azure Monitor
module monitoring '../resources/monitoring.bicep' = {
  scope: rg
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
  scope: rg
  name: 'appidentity'
  params: {
    name: '${abbrs.managedIdentityUserAssignedIdentities}app-${resourceToken}'
    location: location
  }
}

// Shared services including storage account with environment-specific connectivity
module shared '../resources/shared.bicep' = {
  scope: rg
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
module app '../resources/app.bicep' = {
  scope: rg
  name: 'appDeployment'
  params: {
    location: location
    tags: tags
    abbrs: abbrs
    resourceToken: resourceToken
    envType: envType
    containerAppSubnetId: envType == 'prod' ? network.outputs.containerAppSubnetId : ''
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    appIdentityResourceId: appIdentity.outputs.resourceId
    appIdentityClientId: appIdentity.outputs.clientId
    appIdentityPrincipalId: appIdentity.outputs.principalId
    storageAccountName: shared.outputs.storageAccountName
    storageAccountBlobEndpoint: shared.outputs.storageAccountBlobEndpoint
    devProdAcaExists: devProdAcaExists
    customDomain: customDomain
    managedCertId: managedCertId
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = app.outputs.containerRegistryEndpoint
output CONTAINER_APP_ENVIRONMENT_ID string = app.outputs.containerAppsEnvironmentResourceId
output CONTAINER_APP_HOSTNAME string = app.outputs.containerAppHostname

output CUSTOM_DOMAIN_VERIFICATION_ID string = app.outputs.customDomainVerificationId
output CUSTOM_DOMAIN string = customDomain
output CUSTOM_DOMAIN_CONFIGURED bool = devProdAcaExists
