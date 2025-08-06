#!/bin/sh

if [ -n "$CUSTOM_DOMAIN_VERIFICATION_ID" ] && [ -n "$CUSTOM_DOMAIN" ] && [ "$CUSTOM_DOMAIN_CONFIGURED" = "false" ]; then
  echo ""
  echo "Configure TXT record on 'asuid.$CUSTOM_DOMAIN' with value: $CUSTOM_DOMAIN_VERIFICATION_ID"
  echo "Press enter once completed..."
  read dummy
  exit 0
fi

if [ -n "$CONTAINER_APP_HOSTNAME" ] && [ -z "$MANAGED_CERTIFICATE_ID" ]; then
  echo ""
  echo "Configure CNAME or A record on '$CUSTOM_DOMAIN' to: '$CONTAINER_APP_HOSTNAME'"
  echo "Press enter once completed..."
  read dummy
  exit 0
fi
