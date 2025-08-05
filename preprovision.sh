#!/bin/sh

echo "Preprovision script started..."
echo "Subscription: $AZURE_SUBSCRIPTION_ID"

if [ -n "$CONTAINER_APP_HOSTNAME" ] && [ -z "$MANAGED_CERTIFICATE_ID" ]; then
  echo "Configure CNAME or A record on '$CUSTOM_DOMAIN' to: '$CONTAINER_APP_HOSTNAME'"
  echo "Press enter once completed..."
  read dummy
fi

# if [ -z "$CONTAINER_APP_HOSTNAME" ] && [ -z "$MANAGED_CERTIFICATE_ID" ]; then
#   unique_id="${AZURE_SUBSCRIPTION_ID}282EF"
#   hashed=$(echo -n "$unique_id" | sha256sum | cut -d' ' -f1)
#   hashed_upper=$(echo "$hashed" | tr '[:lower:]' '[:upper:]')
#   echo "Configure TXT record on 'asuid.your-custom-domain.com' with value: $hashed_upper"
#   echo "Press enter once completed..."
#   read dummy
# fi
