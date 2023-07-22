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
print_hash_line
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
                fi
        elif service $i status >/dev/null 2>&1; then
                echo "$i is running"
        fi
done
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



os_type
hw_details
check_running_services
server_resources
sar_report
