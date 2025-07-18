# Azure Container Apps + Storage: Dev→Prod

To set up custom domains manually after provisioning:

1. `azd up` - when prompted, leave `customDomain` and `managedCertId` empty.
2. Navigate to the Azure Portal.
3. Go to the Container App resource.
4. Under "Settings", select "Custom domains".
5. Click on "Add custom domain" and follow the prompts to configure your domain.
    See [Azure documentation](https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-managed-certificates?pivots=azure-portal) for more details.
6. `azd env set CUSTOM_DOMAIN_NAME <your_custom_domain_name>` - set the custom domain name in your environment.
7. `azd env set MANAGED_CERT_ID <your_managed_certificate_id>` (`/subscriptions/.../resourceGroups/.../providers/Microsoft.App/managedEnvironments/.../managedCertificates/<cert-name>`) - set the managed certificate resource ID in your environment.
8. This is needed to prevent the custom domain configuration from getting cleared on future provisions.
