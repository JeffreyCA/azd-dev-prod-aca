// Certificate infrastructure module for Azure Container Apps managed certificates
// This module creates managed certificates for custom domains in Container Apps
//
// Features:
// - Managed certificate creation for custom domains
// - Automatic certificate management and renewal
// - Integration with Container Apps environments

@description('The location used for all deployed resources')
param location string

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Container Apps Environment resource ID where the certificate will be created')
param containerAppsEnvironmentResourceId string

@description('Custom domain name for the certificate (e.g., app.contoso.com)')
param customDomain string

var createManagedCert bool = !empty(customDomain)

// Extract the environment name from the resource ID for proper naming
var environmentName = last(split(containerAppsEnvironmentResourceId, '/'))

// Reference to the existing Container Apps Environment
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: environmentName
}

// Managed certificate for custom domain
resource managedCertificate 'Microsoft.App/managedEnvironments/managedCertificates@2024-03-01' = if (createManagedCert) {
  name: '${replace(customDomain, '.', '-')}-cert'
  parent: containerAppsEnvironment
  location: location
  tags: tags
  properties: {
    subjectName: customDomain
    domainControlValidation: 'CNAME'
  }
}

// Outputs for use by other modules
@description('Managed certificate resource ID')
output managedCertificateId string = createManagedCert ? managedCertificate.id : ''

@description('Managed certificate name')
output managedCertificateName string = createManagedCert ? managedCertificate.name : ''
