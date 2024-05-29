#!/bin/sh

# Find the installed PHP-FPM service
PHP_FPM_SERVICE=$(ls /etc/init.d/ | grep php | grep -E 'fpm$')
PHP_FPM_VERSION=$(echo $PHP_FPM_SERVICE | sed 's/php//g' | sed 's/-fpm//g')

echo "Detected PHP-FPM service: $PHP_FPM_SERVICE"
echo "PHP-FPM version: $PHP_FPM_VERSION"

# Substitute the PHP-FPM version in the Nginx config template
export PHP_FPM_VERSION
envsubst '${PHP_FPM_VERSION}' < /etc/nginx/sites-available/cmacc.template.conf > /etc/nginx/sites-available/cmacc.conf
ln -s /etc/nginx/sites-available/cmacc.conf /etc/nginx/sites-enabled/cmacc.conf

# Start PHP-FPM service
if [ -n "$PHP_FPM_SERVICE" ]; then
    service $PHP_FPM_SERVICE start
else
    echo "PHP-FPM service not found"
    exit 1
fi

# Start Nginx
nginx -g 'daemon off;'
