check_running_services()
{
services=("httpd" "apache2" "nginx" "mysql" "mysqld" "mariadb" "varnish" "postfix" "sendmail" "vstfpd" "pcsd")
echo "Detected Services:"
for i in "${services[@]}"; do
        if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active $i >/dev/null 2>&1; then
                        echo "$i is running"
                fi
        elif service $i status >/dev/null 2>&1; then
                echo "$i is running"
        fi
done
}
check_running_services
