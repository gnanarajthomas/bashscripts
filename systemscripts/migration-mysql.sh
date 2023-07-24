#!/bin/bash

check_running_services()
{
services=("httpd" "apache2" "nginx" "varnish" "php-fpm" "mysql" "mysqld" "mariadb" "redis*" "commvault" "nfs" "nfsd" "dovecot" "postfix" "sendmail" "vstfpd" "pcsd")
#print_hash_line
echo "Detected Services:"
for i in "${services[@]}"; do
        if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active $i >/dev/null 2>&1; then
                        echo "$i is running"
                        active_services[$i]=$i
                fi
        elif service $i status >/dev/null 2>&1; then
                echo "$i is running"
                active_services[$i]=$i
        fi
done
#e_e
}

###########
mysql_check()
{
MY_PWD_FILE="/root/.my.cnf"
        sql_queries()
        {
        echo "Data Directory:"
        mysql -Ne 'show variables like "%datadir%"'
        echo "Mysql Databases:"
        mysql -Ne 'show databases'
        echo "Mysql Users:"
        mysql -Ne "SELECT User, Host FROM mysql.user;"
        }
        if [ -f "$MY_PWD_FILE" ]; then
#               if ${active_services[mysql]} || ${active_services[mysqld]} || ${active_service[mariadb]}; then
                if [[ "${active_services[@]}" =~ mysql|mysqld|mariadb ]]; then
                        SLAVE_YES=$(mysql -e 'show slave status \G' | grep -c "Slave_IO_State")
                        SLAVE_WC=$(mysql -e 'show slave status' | wc -l)
                        MASTER_WC=$(mysql -NBe 'show master status' | wc -l)
                        if [[ $SLAVE_YES -ge 1 ]]; then
                                echo "MySQL is configured as SLAVE:"
                                mysql -e 'show slave status \G' | grep -E 'Master_Host|Master_Port|Slave_IO_Running|Slave_SQL_Running|Last_IO_Error'
                                sql_queries
                        elif [[ $SLAVE_WC -eq 0 ]] && [[ $MASTER_WC -ge 1 ]]; then
                                echo "Mysql is configured as MASTER"
                                mysql -Ne 'show master status'
                                sql_queries
                        else
                                echo "Mysql is configured as Standalone"
                                sql_queries
                        fi
                fi
        else
                echo -e "File $MY_PWD_FILE not found"
        fi
}
check_running_services
mysql_check

