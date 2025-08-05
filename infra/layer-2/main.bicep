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

param containerAppsEnvironmentResourceId string

@description('Custom domain name for the container app')
param customDomain string

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

// Application hosting infrastructure
module cert '../resources/cert.bicep' = {
  scope: rg
  name: 'managedCert'
  params: {
    location: location
    tags: tags
    containerAppsEnvironmentResourceId: containerAppsEnvironmentResourceId
    customDomain: customDomain
  }
}

// Outputs from cert module
output LAYER_2_MANAGED_CERTIFICATE_ID string = cert.outputs.managedCertificateId
output LAYER_2_MANAGED_CERTIFICATE_NAME string = cert.outputs.managedCertificateName
output LAYER_2_CUSTOM_DOMAIN_NAME string = cert.outputs.customDomainName
output LAYER_2_CERTIFICATE_CREATED bool = cert.outputs.certificateCreated
output LAYER_2_DOMAIN_VALIDATION_INSTRUCTIONS string = cert.outputs.domainValidationInstructions
