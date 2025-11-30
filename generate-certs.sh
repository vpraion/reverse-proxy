#!/bin/sh

# Paths and templates
VHOSTS_FILE="/etc/nginx/conf-template/vhosts.json"
HTTP_TEMPLATE="/etc/nginx/conf-template/http.template"
HTTPS_TEMPLATE="/etc/nginx/conf-template/https.template"
HTTP_OUT_CONF="/etc/nginx/sites-available/http"
HTTPS_OUT_CONF="/etc/nginx/sites-available/https"
SITES_ENABLED_PATH="/etc/nginx/sites-enabled"


# Base path where certificates are stored
CERT_BASE="/etc/letsencrypt/live"

# Helper: enable a site by creating a symbolic link
enable_site() {
    # $1 source, $2 destination
    ln -nsf $1 $2
}

# Count how many domains to process
DOMAINS_COUNT=$(jq length "$VHOSTS_FILE")
i=0

while [ $i -lt "$DOMAINS_COUNT" ]; do
    DOMAIN=$(jq -r ".[$i].domain" "$VHOSTS_FILE")
    HOST=$(jq -r ".[$i].host"   "$VHOSTS_FILE")
    PORT=$(jq -r ".[$i].port"   "$VHOSTS_FILE")
    MAIL=$(jq -r ".[$i].mail"   "$VHOSTS_FILE")

    echo ">>> Checking certificate for $DOMAIN"

    CERT_PATH="$CERT_BASE/$DOMAIN/fullchain.pem"

    if [ -f "$CERT_PATH" ]; then
        # Certificate already exist
        ISSUER=$(openssl x509 -in "$CERT_PATH" -noout -issuer | sed 's/^issuer=//')
        SUBJECT=$(openssl x509 -in "$CERT_PATH" -noout -subject | sed 's/^subject=//')


        if [ "$ISSUER" = "$SUBJECT" ]; then
            echo "⚠️  $DOMAIN → Self-signed certificate detected"
            if [ "$DEV_ENV" != "1" ]; then
                certbote delete --cert-name $DOMAIN
                certbot certonly \
                    --webroot \
                    -w /var/www/certbot \
                    -d "$DOMAIN" \
                    --email "$MAIL" \
                    --agree-tos \
                    --no-eff-email \
                    --rsa-key-size 4096 \
                    --non-interactive
            fi
        else
            echo "✅ $DOMAIN → Valid ACME certificate"
            if [ "$DEV_ENV" != "1" ]; then
                echo "🔎 Renewing if close to expiration $DOMAIN"
                certbot renew --cert-name "$DOMAIN" \
                    --webroot -w /var/www/certbot \
                    --quiet
            fi
        fi
    else
        echo "❗ No certificate found for $DOMAIN"

        if [ "$DEV_ENV" = "1" ]; then
            echo "🔧 Dev mode → Generatif self-signed certificate for $DOMAIN"

            mkdir -p "$CERT_BASE/$DOMAIN"

            openssl req -x509 -nodes -newkey rsa:4096 \
                -days 30 \
                -keyout "$CERT_BASE/$DOMAIN/privkey.pem" \
                -out    "$CERT_BASE/$DOMAIN/fullchain.pem" \
                -subj "/CN=$DOMAIN"

            echo "✅ Self-signed certificate created for $DOMAIN (valid 30 days)"
        else
            echo "🌍 Prod mode → Requesting Let’s Encrypt certificate for $DOMAIN"

            certbot certonly \
                --webroot \
                -w /var/www/certbot \
                -d "$DOMAIN" \
                --email "$MAIL" \
                --agree-tos \
                --no-eff-email \
                --rsa-key-size 4096 \
                --non-interactive

            echo "✅ Let's encrypt certificate obtained $DOMAIN"
        fi
    fi

    enable_site "$HTTPS_OUT_CONF/$DOMAIN.conf" "$SITES_ENABLED_PATH/$DOMAIN.conf"

    i=$((i + 1))
done
