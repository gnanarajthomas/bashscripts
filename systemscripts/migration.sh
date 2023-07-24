#!/bin/bash

PHY_DELL=$(dmidecode -s system-manufacturer | grep -i dell)
PHY_HP=$(dmidecode -s system-manufacturer | grep -i hp)
VM_ENV=$(dmidecode -s system-manufacturer | grep -iE 'xen|vmware|kvm')
SRV_MODEL=$(dmidecode -s system-product-name)
CPU_COUNT=$(lscpu | awk -F ":" '{gsub(/ /,""); if ($1~/^CPU\(/) print $2}')
PLESK_BINARY="/usr/local/psa/admin/sbin/plesk"
WEBMIN_BINARY1="/usr/share/webmin/"
WEBMIN_BINARY2="/opt/webmin/"
CPANEL_BINARY="/usr/local/cpanel/cpanel"


print_hash_line()
{
  for ((i=1; i<=50; i++)); do
    echo -n "#"
  done
  echo
}

e_e()
{
echo ""
}

###################
#OS Classification#
###################

os_type()
{
e_e
        if [ -f "/etc/os-release" ]; then
                OS_DISTRO=$(sed -n 's/^PRETTY_NAME=\"\(.*\)\"/\1/p' /etc/os-release)
                echo "Detected OS: $OS_DISTRO"
        elif [ -f "/etc/lsb-release" ]; then
                OS_DISTRO=$(sed -n 's/^DISTRIB_DESCRIPTION=\"\(.*\)\"/\1/p' /etc/lsb-release)
                echo "Detected OS: $OS_DISTRO"
        elif [ -f "/etc/debian_version"]; then
                OS_DISTRO=$(cat /etc/debian_version)
                echo "Detected OS: $OS_DISTRO"
        fi

        if [[ ! -z "$PHY_DELL" ]]; then
                SRV_ENV="Dell"
                echo "Detected Hardware: $PHY_DELL"
        elif [[ ! -z "$PHY_HP" ]]; then
                SRV_ENV="HP"
                echo "Detected Hardware: $PHY_HP"
        elif [[ ! -z $VM_ENV ]]; then
                SRV_ENV="VM"
                echo "Detected VM Platform: $VM_ENV"
        fi

        if [ -f "$PLESK_BINARY" ]; then
                echo "Datected Panel: Plesk"
        elif [ -f "$WEBMIN_BINARY1" ] || [ -f "$$WEBMIN_BINARY2" ]; then
                echo "Detected Panel: Webmin"
        elif [ -f "$CPANEL_BINARY" ]; then
                echo "Detected Panel: Cpanel"
        else
                echo "No Control Panel Detected"
        fi
}


##################
#Hardware Details#
##################


hw_details()
{
print_hash_line
echo "Server Make: $SRV_ENV"
echo "Server Model: $SRV_MODEL"
test -f /opt/dell/srvadmin/bin/omreport && omreport system version | awk NF && e_e && omreport storage vdisk | awk '/^ID/;/^Layout/;/^Size/'
if [ -f /sbin/ssacli ]; then
	ssacli controller all show | awk '{if (NR==2) print $6}' | while read line; 
		do ssacli controller slot=$line logicaldrive all show; 
	done
fi
e_e
}

###################
#Detected Services#
###################

check_running_services()
{
services=("httpd" "apache2" "nginx" "varnish" "php-fpm" "mysql" "mysqld" "mariadb" "redis*" "commvault" "nfs" "nfsd" "dovecot" "postfix" "sendmail" "vstfpd" "pcsd")
print_hash_line
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
e_e
}

#####################################
#Check Installed Application Version#
#####################################

application_version()
{
print_hash_line
test -f /usr/sbin/httpd         && httpd -v 2> /dev/null | awk '{if (NR==1) printf ("Installed Apache Version: \n%s\n",$3)}'
test -f /usr/sbin/apache2ctl    && apache2ctl -v 2> /dev/null | awk '{if (NR==1) printf ("Installed Apache Version: \n%s\n",$3)}'
test -f /usr/bin/mysql          && echo "Installed Database Version:";mysql -V | awk -F "for|," '{print $1}'
test -f /usr/sbin/varnishd      && echo "Installed Varnish Version:";varnishd -V 2>&1 | sed -n 's/varnishd (\(varnish-.*\) rev.*/\1/p'
test -f /usr/sbin/nginx         && nginx -v 2>&1 | awk '{printf ("Installed Nginx Version: \n%s\n",$3)}'
test -f /usr/bin/redis-server   && redis-server --version | awk '{printf ("Installed Redis Version \n%s\n", $3)}'
test -f /usr/sbin/php-fpm       && /usr/sbin/php-fpm -v | awk '/^PHP/ {printf ("Installed PHP-FPM Version \n%s\n", $2)}'
e_e
}

php_apache_modules()
{
print_hash_line
test -f /usr/sbin/php-fpm 	&& echo "Installed PHP-FPM Modules:" 	&& /usr/sbin/php-fpm -m
test -f /usr/sbin/php 		&& echo "Installed PHP Modules:" 	&& /usr/sbin/php -m
test -f /usr/sbin/httpd 	&& echo "Loaded Apache Modules:" 	&& /usr/sbin/httpd -M
test -f /usr/sbin/apache2ctl 	&& echo "Loaded Apache Modules:" 	&& /usr/sbin/apache2ctl -M
e_e
}


##################
#Server Resources#
##################

server_resources()
{
print_hash_line
echo "Number of CPU(s): $CPU_COUNT"
e_e

print_hash_line
echo "Memory Details:"
free -h
e_e

print_hash_line
echo "Disk Layout"
lsblk
e_e

print_hash_line
echo "Mount point and FS"
df -Th
e_e
OFS=$IFS
IFS=
print_hash_line
echo "LVM List"
LV_LIST=$(lvscan 2> /dev/null)
        if [ -n "$LV_LIST" ]; then
                echo "$LV_LIST";
        else
                echo "NO LVs Found"
        fi
e_e

print_hash_line
echo "VG List"
VG_LIST=$(vgscan 2> /dev/null)
        if [ -n "$VG_LIST" ]; then
                echo "$VG_LIST";
        else
                echo "NO VGs Found"
        fi
e_e

print_hash_line
echo "PV List"
PV_LIST=$(pvscan 2> /dev/null)
        if [ -n "$PV_LIST" ]; then
                echo "$PV_LIST";
        else
                echo "NO PVs Found"
        fi
e_e

print_hash_line
echo "Fstab Entries"
cat /etc/fstab
e_e
echo ""
IFS=$OFS
}

########
#Day -2#
########

#################################
#Historical Resource Utilization#
#################################

sar_cpu_fn()
{
                if [[ $SAR_DAYS -ge 1 ]]; then
                        echo "HIGH CPU Utilization for last $SAR_DAYS days:"
                        echo "SAR file          %CPU"
                        ls $SAR_LOG | while read line; do
                                CPU_IDLE=$(sar -u -f $line | grep '^[0-9]' | sed -e 's/AM\|PM//g' -e '/RESTART\|idle/d' | sort -s -n -k8,8 | awk '{ if (NR==1) print $8 }')
                                CPU_PERCENT=$(echo "100.00 - $CPU_IDLE" | bc)
                                echo "$line: $CPU_PERCENT%";
                        done
                else
                        echo "No SAR files found"
                fi
}

sar_mem_deb_fn()
{
                if [[ $SAR_DAYS -ge 1 ]]; then
                        echo "HIGH Memory Percentage & Commit Utilization for last $SAR_DAYS days:"
                        echo "SAR file          %memused %commit"
                        ls $SAR_LOG | while read line; do
                                MEMORY_PERCENT=$(sar -r -f $line | grep '^[0-9]' | sed -e 's/AM\|PM//g' -e '/RESTART\|commit/d' | sort -s -n -k5,5 | awk 'END {print $5}')
                                MEMORY_COMMIT=$(sar -r -f $line | grep '^[0-9]' | sed -e 's/AM\|PM//g' -e '/RESTART\|commit/d' | sort -s -n -k9,9 | awk 'END {print $9}')
                                echo "$line:    $MEMORY_PERCENT $MEMORY_COMMIT";
                        done
                else
                        echo "No SAR files found"
                fi

}

sar_mem_cent_fn()
{
                if [[ $SAR_DAYS -ge 1 ]]; then
                        echo "HIGH Memory Percentage & Commit Utilization for last $SAR_DAYS days:"
                        echo "SAR file          %memused %commit"
                        ls $SAR_LOG | while read line; do
                                MEMORY_PERCENT=$(sar -r -f $line | grep '^[0-9]' | sed -e 's/AM\|PM//g' -e '/RESTART\|commit/d' | sort -s -n -k5,5 | awk 'END {print $4}')
                                MEMORY_COMMIT=$(sar -r -f $line | grep '^[0-9]' | sed -e 's/AM\|PM//g' -e '/RESTART\|commit/d' | sort -s -n -k8,8 | awk 'END {print $8}')
                                echo "$line:    $MEMORY_PERCENT $MEMORY_COMMIT";
                        done
                else
                        echo "No SAR files found"
                fi

}


sar_report()
{
        if [[ $OS_DISTRO =~ Cent|Red|Alma|Rocky ]]; then
                SAR_LOG="/var/log/sa/sa[0-3][0-9]"
                SAR_DAYS=$(ls $SAR_LOG 2> /dev/null | wc -l)
                print_hash_line
                sar_cpu_fn
                print_hash_line
                sar_mem_cent_fn
                print_hash_line
        elif [[ $OS_DISTRO =~ Ubuntu|Debian ]]; then
                SAR_LOG="/var/log/sysstat/sa[0-3][0-9]"
                SAR_DAYS=$(ls $SAR_LOG 2> /dev/null | wc -l)
                print_hash_line
                sar_cpu_fn
                print_hash_line
                sar_mem_deb_fn
                print_hash_line
        else
                echo "No SAR Found"
        fi
}

nw_details()
{
print_hash_line
echo "Network interfaceas and IPs:"
ip -br a | grep UP
BOND_COUNT=$(ip -br a | awk /^bond/ | wc -l)
if [ $BOND_COUNT -ge 1 ]; then
        ip -br a | awk /^bond/ | while read BOND; do echo "$BOND details:"; echo "Slaves: $(cat /sys/class/net/$BOND/bonding/slaves)"; grep "Bonding Mode"  /proc/net/bonding/bond0;
done
fi
e_e
}

users_info()
{
print_hash_line
echo "Users above UID 1000 and having any login shell:"
MIN_UID=$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)
ALL_UID=$(awk -v minid=$MIN_UID -F ":" '{if ($3 >= minid && $7 ~/sh$/) print $1}' /etc/passwd)
echo "$ALL_UID"
echo "Users above UID 1000 having false and nologin shell:"
awk -v minid=$MIN_UID -F ":" '{if ($3 >= minid && $7 ~/false$|nologin$/) print $1}' /etc/passwd
echo "Sudo Users:"
echo "$ALL_UID" | while read uid;
        do
                sudo -l -U $uid | grep "may run" | awk '{print $2}';
        done
e_e
}


pcs_details()
{
if [ -f /usr/sbin/pcs ] && systemctl is-active pcsd 2>&1 > /dev/null; then
print_hash_line
echo "PCS Version:"
pcs --version
pcs status nodes config
echo "PCS Resource groups and resources:"
pcs resource show --groups
fi
e_e
}


###############
#MySQL Details#
###############

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


os_type
hw_details
nw_details
users_info
pcs_details
check_running_services
application_version
php_apache_modules
server_resources
sar_report
mysql_check


