# Base image
FROM debian:latest

# Install dependencies
RUN apt-get update && \
    apt-get install -y nginx php-fpm php-cli php-mysql gettext

# Remove the default site configuration
RUN rm /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Copy the new site configuration template
COPY cmacc.template.conf /etc/nginx/cmacc.template.conf

# Copy the service start script
COPY start-services.sh /usr/local/bin/start-services.sh

# Ensure the script is executable
RUN chmod +x /usr/local/bin/start-services.sh

# Set document root and copy necessary directories
RUN rm -rf /var/www/html && mkdir -p /var/www/html
COPY vendor /var/www/html/vendor
COPY Doc /var/www/html/Doc
COPY File /var/www/html/File
COPY image /var/www/html/image
COPY png /var/www/html/png

# Set permissions
RUN chown -R www-data:www-data /var/www/html

# Copy PHP files
COPY index.php /var/www/html/index.php
COPY i.php /var/www/html/i.php

# debugging utilities
RUN apt-get install -y iproute2 lsof netcat-openbsd socat

# Expose port
EXPOSE 80

# Start PHP-FPM and Nginx using the script
CMD ["/usr/local/bin/start-services.sh"]
