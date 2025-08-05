# ACA Custom Domains with Layers

1. `azd up` - when prompted, set `customDomain` to your custom domain.

> [!NOTE] 
> The first time running `azd up`, you may get a `InvalidCustomHostNameValidation` deployment error. If you encounter this, you'll need to configure a TXT record on your domain (`asuid.<your-custom-domain.com>`) pointing to the domain verification ID (long string of numbers and letters). After configuring the TXT record, re-run `azd up`.

2. There will be a step where you will be prompted to configure the CNAME or A record for your custom domain. Press `<enter>` only after you configured it, otherwise the managed certificate deployment may fail.
