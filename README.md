# ACA Custom Domains with Layers

1. `azd up` - when prompted, set `customDomain` to your custom domain.

> [!NOTE] 
> You'll be prompted to configure 2 DNS records on your domain. The first is a TXT record (`asuid.<your-custom-domain.com>`) pointing to the domain verification ID (long string of numbers and letters). The second is a CNAME/A record pointing to the container app hostname.
