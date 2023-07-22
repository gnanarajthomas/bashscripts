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
}

sar_cpu_fn()
{
                SAR_DAYS=$(ls $SAR_LOG | wc -l)
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
                SAR_DAYS=$(ls $SAR_LOG | wc -l)
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
                SAR_DAYS=$(ls $SAR_LOG | wc -l)
                if [[ $SAR_DAYS -ge 1 ]]; then
                        echo "HIGH Memory Percentage & Commit Utilization for last $SAR_DAYS days:"
                        echo "SAR file          %memused %commit"
                        ls $SAR_LOG | while read line; do
                                MEMORY_PERCENT=$(sar -r -f $line | grep '^[0-9]' | sed -e 's/AM\|PM//g' -e '/RESTART\|commit/d' | sort -s -n -k5,5 | awk 'END {print $4}')
                                MEMORY_COMMIT=$(sar -r -f $line | grep '^[0-9]' | sed -e 's/AM\|PM//g' -e '/RESTART\|commit/d' | sort -s -n -k9,9 | awk 'END {print $8}')
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
                print_hash_line
                sar_cpu_fn
                print_hash_line
                sar_mem_cent_fn
                print_hash_line
        elif [[ $OS_DISTRO =~ Ubuntu|Debian ]]; then
                SAR_LOG="/var/log/sysstat/sa[0-3][0-9]"
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
sar_report
