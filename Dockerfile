# The immutable index pins PHP, Apache, Perl, curl, CA certificates, and OS libraries.
# No package repositories or downloads are used by this build.
FROM php:8.4.25-apache-bookworm@sha256:0629e7852d88a0939841973910d94157de7cd68e48acefac44546f8534b45d31

WORKDIR /var/www/html

COPY i.php index.php .htaccess README.md LICENSE.md ./
COPY Doc/ ./Doc/
COPY File/ ./File/
COPY image/ ./image/
COPY png/ ./png/
COPY vendor/ ./vendor/
COPY infra/container/apache.conf /etc/apache2/sites-available/000-default.conf
COPY infra/container/php.ini /usr/local/etc/php/conf.d/cmacc.ini

RUN set -eu; \
    printf 'Listen 8080\n' > /etc/apache2/ports.conf; \
    mkdir -p /usr/local/share/cmacc; \
    find . -type f -print0 | sort -z | xargs -0 sha256sum > /usr/local/share/cmacc/source.sha256; \
    dpkg-query -W -f='${Package}\t${Version}\t${Architecture}\n' > /usr/local/share/cmacc/packages.tsv; \
    php --version > /usr/local/share/cmacc/php-version.txt; \
    chown -R www-data:www-data Doc

# Runtime state stays in the container. The host checkout is never mounted.
ENV APACHE_RUN_DIR=/tmp/cmacc-apache \
    APACHE_PID_FILE=/tmp/cmacc-apache/apache2.pid \
    APACHE_LOCK_DIR=/tmp/cmacc-apache-lock \
    APACHE_LOG_DIR=/tmp/cmacc-apache-log

USER 33:33
EXPOSE 8080
CMD ["apache2-foreground"]
