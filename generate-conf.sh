#!/bin/sh

# Paths and templates
VHOSTS_FILE="/etc/nginx/conf-template/vhosts.json"
HTTP_TEMPLATE="/etc/nginx/conf-template/http.template"
HTTPS_TEMPLATE="/etc/nginx/conf-template/https.template"
HTTP_OUT_CONF="/etc/nginx/sites-available/http"
HTTPS_OUT_CONF="/etc/nginx/sites-available/https"
SITES_ENABLED_PATH="/etc/nginx/sites-enabled"

i=0
DOMAINS_COUNT=$(jq length "$VHOSTS_FILE")

while [ $i -lt "$DOMAINS_COUNT" ]; do
    DOMAIN=$(jq -r ".[$i].domain" "$VHOSTS_FILE")
    HOST=$(jq -r ".[$i].host"   "$VHOSTS_FILE")
    PORT=$(jq -r ".[$i].port"   "$VHOSTS_FILE")

    echo "> Generating http/https configs for $DOMAIN ($HOST:$PORT)"

    # Generate HTTP config
    sed -e "s|\${DOMAIN}|$DOMAIN|g" \
        -e "s|\${HOST}|$HOST|g" \
        -e "s|\${PORT}|$PORT|g" \
        "$HTTP_TEMPLATE"  > "$HTTP_OUT_CONF/$DOMAIN.conf"

    # Generate HTTPS config
    sed -e "s|\${DOMAIN}|$DOMAIN|g" \
        -e "s|\${HOST}|$HOST|g" \
        -e "s|\${PORT}|$PORT|g" \
        "$HTTPS_TEMPLATE" > "$HTTPS_OUT_CONF/$DOMAIN.conf"

    # Create a symlink if it doesn't exist yes to enable the website
    if [ ! -f "$SITE_ENABLED_PATH/$DOMAIN.conf" ]; then
        ln -s "$HTTP_OUT_CONF/$DOMAIN.conf" "$SITES_ENABLED_PATH/$DOMAIN.conf"
    fi

    i=$((i + 1))
done
