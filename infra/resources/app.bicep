// Application infrastructure module for Azure Container Apps hosting
// This module creates the application hosting infrastructure:
// 1. Container Registry for storing container images
// 2. Container Apps Environment with conditional VNet integration
// 3. Container App with managed identity integration
//
// Security Features:
// - VNet integration for secure backend communication (prod only)
// - Managed identity for passwordless authentication
// - Private container registry access
// - Comprehensive logging and monitoring integration

@description('The location used for all deployed resources')
param location string

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Abbreviations for Azure resource naming')
param abbrs object

@description('Unique token for resource naming')
param resourceToken string

@description('Environment type - determines networking configuration')
@allowed(['dev', 'test', 'prod'])
param envType string = 'dev'

@description('Container App subnet ID for VNet integration (empty for non-prod environments)')
param containerAppSubnetId string

@description('Application Insights connection string for monitoring')
param applicationInsightsConnectionString string

@description('Managed identity resource ID for the application')
param appIdentityResourceId string

@description('Managed identity client ID for the application')
param appIdentityClientId string

@description('Managed identity principal ID for the application')
param appIdentityPrincipalId string

@description('Storage account name for application configuration')
param storageAccountName string

@description('Storage account blob endpoint for application configuration')
param storageAccountBlobEndpoint string

@description('Flag to indicate if the container app already exists')
param devProdPcAcaExists bool

@description('Custom domain name for the container app')
param customDomain string

@description('Resource ID of the managed certificate')
param managedCertId string?

// Container registry for storing container images
module containerRegistry 'br/public:avm/res/container-registry/registry:0.1.1' = {
  name: 'registry'
  params: {
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
    publicNetworkAccess: 'Enabled'
    roleAssignments:[
      {
        principalId: appIdentityPrincipalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
      }
    ]
  }
}

// Container apps environment with conditional VNet integration
module containerAppsEnvironment 'br/public:avm/res/app/managed-environment:0.4.5' = {
  name: 'container-apps-environment'
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    name: '${abbrs.appManagedEnvironments}${resourceToken}'
    location: location
    zoneRedundant: false
    // VNet integration for production environments
    infrastructureSubnetId: envType == 'prod' && !empty(containerAppSubnetId) ? containerAppSubnetId : null
    internal: envType == 'prod'
  }
}

// Fetch existing container image if app already exists
module devProdPcAcaFetchLatestImage './modules/fetch-container-image.bicep' = {
  name: 'devProdPcAca-fetch-image'
  params: {
    exists: devProdPcAcaExists
    name: 'dev-prod-aca'
  }
}

// Container app with managed identity integration
module devProdPcAca 'br/public:avm/res/app/container-app:0.18.1' = {
  name: 'devProdPcAca'
  params: {
    name: 'dev-prod-aca'
    ingressTargetPort: 5000
    scaleSettings: {
      minReplicas: 1
      maxReplicas: 10
    }
    containers: [
      {
        image: devProdPcAcaFetchLatestImage.outputs.?containers[?0].?image ?? 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        name: 'main'
        resources: {
          cpu: json('0.5')
          memory: '1.0Gi'
        }
        env: [
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: applicationInsightsConnectionString
          }
          {
            name: 'AZURE_CLIENT_ID'
            value: appIdentityClientId
          }
          {
            name: 'AZURE_STORAGE_ACCOUNT_NAME'
            value: storageAccountName
          }
          {
            name: 'AZURE_STORAGE_BLOB_ENDPOINT'
            value: storageAccountBlobEndpoint
          }
          {
            name: 'PORT'
            value: '5000'
          }
        ]
      }
    ]
    customDomains: [
      {
        name: customDomain
        certificateId: managedCertId
        bindingType: managedCertId == null ? 'Disabled' : 'SniEnabled'
      }
    ]
    managedIdentities:{
      systemAssigned: false
      userAssignedResourceIds: [appIdentityResourceId]
    }
    registries:[
      {
        server: containerRegistry.outputs.loginServer
        identity: appIdentityResourceId
      }
    ]
    environmentResourceId: containerAppsEnvironment.outputs.resourceId
    location: location
    tags: union(tags, { 'azd-service-name': 'dev-prod-aca' })
  }
}

// Additional parameter needed for the log analytics workspace
@description('Log Analytics workspace resource ID for monitoring')
param logAnalyticsWorkspaceResourceId string

// Outputs for use by other modules
@description('Container App resource ID')
output containerAppResourceId string = devProdPcAca.outputs.resourceId

@description('Container Registry endpoint')
output containerRegistryEndpoint string = containerRegistry.outputs.loginServer

@description('Container Apps Environment resource ID')
output containerAppsEnvironmentResourceId string = containerAppsEnvironment.outputs.resourceId

@description('Container App name')
output containerAppName string = devProdPcAca.outputs.name

@description('Container App hostname')
output containerAppHostname string = devProdPcAca.outputs.fqdn
