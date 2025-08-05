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
param devProdPcAcaExists bool = false

@description('Custom domain name for the container app')
param customDomain string

@description('Resource ID of the managed certificate')
param managedCertId string

@description('Container App subnet ID for VNet integration (from networking layer)')
param containerAppSubnetId string = ''

@description('Log Analytics workspace resource ID (from monitoring layer)')
param logAnalyticsWorkspaceResourceId string

@description('Application Insights connection string (from monitoring layer)')
param applicationInsightsConnectionString string

@description('Application identity resource ID (from identity layer)')
param appIdentityResourceId string

@description('Application identity client ID (from identity layer)')
param appIdentityClientId string

@description('Application identity principal ID (from identity layer)')
param appIdentityPrincipalId string

@description('Storage account name (from storage layer)')
param storageAccountName string

@description('Storage account blob endpoint (from storage layer)')
param storageAccountBlobEndpoint string

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
    containerAppSubnetId: containerAppSubnetId
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    applicationInsightsConnectionString: applicationInsightsConnectionString
    appIdentityResourceId: appIdentityResourceId
    appIdentityClientId: appIdentityClientId
    appIdentityPrincipalId: appIdentityPrincipalId
    storageAccountName: storageAccountName
    storageAccountBlobEndpoint: storageAccountBlobEndpoint
    devProdPcAcaExists: devProdPcAcaExists
    customDomain: customDomain
    managedCertId: managedCertId
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = app.outputs.containerRegistryEndpoint
output AZURE_RESOURCE_DEV_PROD_PC_ACA_ID string = app.outputs.containerAppResourceId
