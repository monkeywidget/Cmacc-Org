#!/bin/sh

# Ensure the /run/php directory exists and is owned by www-data
mkdir -p /run/php
chown -R www-data:www-data /run/php

# Find the installed PHP-FPM service
PHP_FPM_SERVICE=$(ls /etc/init.d/ | grep php | grep -E 'fpm$')
PHP_FPM_VERSION=$(echo $PHP_FPM_SERVICE | sed 's/php//g' | sed 's/-fpm//g')

echo "Detected PHP-FPM service: $PHP_FPM_SERVICE"
echo "PHP-FPM version: $PHP_FPM_VERSION"

# Substitute the PHP-FPM version in the Nginx config template
export PHP_FPM_VERSION
envsubst '${PHP_FPM_VERSION}' < /etc/nginx/cmacc.template.conf > /etc/nginx/sites-available/cmacc.conf
ln -s /etc/nginx/sites-available/cmacc.conf /etc/nginx/sites-enabled/cmacc.conf

# Start PHP-FPM service
if [ -n "$PHP_FPM_SERVICE" ]; then
    service $PHP_FPM_SERVICE start
else
    echo "PHP-FPM service not found"
    exit 1
fi

# add a test file
echo "<?php phpinfo(); ?>" > /var/www/html/test.php

# Start Nginx
nginx -g 'daemon off;'
