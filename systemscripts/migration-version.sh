#!/bin/bash
application_version()
{
test -f /usr/sbin/httpd         && httpd -v 2> /dev/null | awk '{if (NR==1) printf ("Installed Apache Version: \n%s\n",$3)}'
test -f /usr/sbin/apache2ctl    && apache2ctl -v 2> /dev/null | awk '{if (NR==1) printf ("Installed Apache Version: \n%s\n",$3)}'
test -f /usr/bin/mysql          && echo "Installed Database Version:";mysql -V | awk -F "for|," '{print $1}'
test -f /usr/sbin/varnishd      && echo "Installed Varnish Version:";varnishd -V 2>&1 | sed -n 's/varnishd (\(varnish-.*\) rev.*/\1/p'
test -f /usr/sbin/nginx         && nginx -v 2>&1 | awk '{printf ("Installed Nginx Version: \n%s\n",$3)}'
test -f /usr/bin/redis-server   && redis-server --version | awk '{printf ("Installed Redis Version \n%s\n", $3)}'
test -f /usr/sbin/php-fpm       && /usr/sbin/php-fpm -v | awk '/^PHP/ {printf ("Installed PHP-FPM Version \n%s\n", $2)}'
}
