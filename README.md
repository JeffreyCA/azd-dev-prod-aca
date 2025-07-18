# ACA with custom domains (single deployment)

This deploys an ACA app with custom domains set up from the beginning, with some manual required steps for domain verification. 

1. Create the `asuid` TXT record with the value set to the custom domain verification ID. This ID can be determined ahead of time (see [here](https://github.com/microsoft/azure-container-apps/issues/1395#issuecomment-3100424115)). If don't do this, then you'll get an `InvalidCustomHostNameValidation` error when deploying the Container App.
2. `azd up`
    When prompted, enter the custom domain or subdomain to use.
3. The Bicep deployment should remain in progress indefinitely, waiting for managed cert to finish creating.
4. In a separate process, use Az PowerShell to retrieve the validation token:

	```
	$ Get-AzContainerAppManagedCert -EnvName <cae-name> -ResourceGroupName <rg-name> -Name <managed-cert-name> | Select-Object ValidationToken
	
	ValidationToken
	---------------
	_md2kkxf7fg7lm4hp84nehz5ddojmxxv
	```

5. On your domain's DNS provider, set the TXT record for your domain to the validation token. E.g. if your managed cert is for `sub.example.com`, then you'd set the TXT record for `sub.example.com` to `_md2kkxf7fg7lm4hp84nehz5ddojmxxv`.

6. After a few minutes, the managed cert should reach a Succeeded state and the Bicep deployment should complete shortly after as well. At this point, remove the TXT record and update it to the appropriate A/CNAME record pointing to the container app endpoint.
