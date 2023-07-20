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
	echo "Server Make: $SRV_ENV"
	echo "Server Model: $SRV_MODEL"
}

##################
#Server Resources#
##################

server_resources()
{
echo "Number of CPU(s): $CPU_COUNT"
echo ""

echo "Memory Details:"
print_hash_line
free -h
print_hash_line
echo ""

echo "Disk Layout"
print_hash_line
lsblk
print_hash_line
echo ""

echo "Mount point and FS"
df -Th
print_hash_line
echo ""
print_hash_line
OFS=$IFS
IFS=
print_hash_line
echo "LVM List"
LV_LIST=$(lvscan)
	if [ -n "$LV_LIST" ]; then 
		echo "$LV_LIST";
	else
		echo "NO LVs Found"
	fi
print_hash_line
echo ""

print_hash_line
echo "VG List"
VG_LIST=$(vgscan)
	if [ -n "$VG_LIST" ]; then 
		echo "$VG_LIST";
	else
		echo "NO VGs Found"
	fi
print_hash_line
echo ""

print_hash_line
echo "PV List"
PV_LIST=$(pvscan)
	if [ -n "$PV_LIST" ]; then 
		echo "$PV_LIST";
	else
		echo "NO PVs Found"
	fi
print_hash_line
echo ""

print_hash_line
echo "Fstab Entries"
cat /etc/fstab
print_hash_line
echo ""
IFS=$OFS
}

os_type
hw_details
server_resources
