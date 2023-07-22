#!/bin/bash
php_apache_modules()
{
test -f /usr/sbin/php-fpm && echo "Installed PHP-FPM Modules:" && /usr/sbin/php-fpm -m
test -f /usr/sbin/php && echo "Installed PHP Modules:" && /usr/sbin/php -m
test -f /usr/sbin/httpd && echo "Loaded Apache Modules:" && /usr/sbin/httpd -M
test -f /usr/sbin/apache2ctl && echo "Loaded Apache Modules:" && /usr/sbin/apache2ctl -M
}

