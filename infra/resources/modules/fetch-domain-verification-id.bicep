param name string

resource existingApp 'Microsoft.App/containerApps@2023-05-02-preview' existing = {
  name: name
}

output domainVerificationId string = existingApp.properties.customDomainVerificationId
