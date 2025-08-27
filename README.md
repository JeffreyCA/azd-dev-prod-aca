## Example workflows

### Just deploy

1. `azd provision`
2. `azd deploy svc`
    - This does a package (build), pushes to ACR, then creates an ACA revision
    - The image is `dev-prod-aca/svc` (defined in azure.yaml)
    - The tag is `latest` (defined in azure.yaml)

### Separate package, publish, deploy

1. `azd provision`
2. `azd package svc` - Should print out "Target Image: dev-prod-aca/svc:latest"
3. `azd publish svc --from-package dev-prod-aca/svc:latest`
    - This pushes the previously built image to ACR (from Step 2)
4. `azd deploy svc --from-package dev-prod-aca/svc:latest`
    - `azd deploy svc --from-package <acr-name>.azurecr.io/dev-prod-aca/svc:latest` also works
    - Does not push to ACR again
    - Only creates a new ACA revision using previously pushed image (from Step 3)

### Separate publish, deploy

1. `azd provision`
2. `azd publish svc --from-package dev-prod-aca/svc:latest`
    - This does a package (build) and pushes to ACR.
    - The image is `dev-prod-aca/svc` (defined in azure.yaml)
    - The tag is `latest` (defined in azure.yaml)
3. `azd deploy svc --from-package dev-prod-aca/svc:latest`
    - `azd deploy svc --from-package <acr-name>.azurecr.io/dev-prod-aca/svc:latest` also works
    - Does not push to ACR again
    - Only creates a new ACA revision using previously pushed image (from Step 3)

### Separate publish (custom image tag), deploy

1. `azd provision`
2. `azd publish svc --tag dev`
    - This does a package (build) and pushes to ACR.
    - The image is `dev-prod-aca/svc` (defined in azure.yaml)
    - The tag is `dev` (overrides value in azure.yaml)
  - Should print the full image name: `<acr-name>.azurecr.io/dev-prod-aca/svc:dev`
3. `azd deploy svc --from-package dev-prod-aca/svc:dev`
    - `azd deploy svc --from-package <acr-name>.azurecr.io/dev-prod-aca/svc:dev` also works
    - Does not push to ACR again
    - Only creates a new ACA revision using previously pushed image (from Step 3)

### Separate publish (custom image name), deploy

1. `azd provision`
2. `azd publish svc --image dev-prod-aca/svc-2`
    - This does a package (build) and pushes to ACR.
    - The image is `dev-prod-aca/svc-2` (overrides value in azure.yaml)
    - The tag is `latest` (defined in azure.yaml)
    - Should print the full image name: `<acr-name>.azurecr.io/dev-prod-aca/svc-2:latest`
3. `azd deploy svc --from-package dev-prod-aca/svc-2:latest`
    - `azd deploy svc --from-package <acr-name>.azurecr.io/dev-prod-aca/svc-2:latest` also works
    - Does not push to ACR again
    - Only creates a new ACA revision using previously pushed image (from Step 3)
