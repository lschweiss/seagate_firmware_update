#! /bin/bash

die () {
    echo $1
    exit 1
fi

# show function usage
show_usage() {
    echo
    echo "Usage: $0 -f {firmware_file} -d {disk}"
}

while getopts f:d: opt; do
    case $opt in
        f) # Firmware
            firmware="$OPTARG"
            ;;
        d) # Disk
            disk="$OPTARG"
            ;;
        ?)  # Show program usage and exit
            show_usage
            exit 0
            ;;
        :)  # Mandatory arguments not specified
            die "${job_name}: Option -$OPTARG requires an argument."
            ;;
    esac
done

[ "$(uname)" == "SunOS" ] || die "This only runs on Illumos or Solaris"

which sg_buffer_write 1>/dev/null 2>/dev/null || die "sg_buffer_write is not in excution search PATH"

[ -f $firmware ] || die "Could not locate firmware file at: $firmware" 

[ -f /dev/rdsk/${disk}s2 ] || die "Disk not found: /dev/rdsk/${disk}s2"

mkdir -p /tmp/firmware

rm -f /tmp/firmware/success-disks
rm -f /tmp/firmware/failed-disks
    
# Collect paths
mpathadm show logical-unit /dev/rdsk/${disk}s2 |grep "Initiator Port Name:" | awk -F ":  " '{print $2}' > /tmp/firmware/${disk}.initports
readarray iport < /tmp/firmware/${disk}.initports

mpathadm show logical-unit /dev/rdsk/${disk}s2 |grep "Target Port Name:" | awk -F ":  " '{print $2}' > /tmp/firmware/${disk}.targetports
readarray tport < /tmp/firmware/${disk}.targetports

paths=`cat /tmp/firmware/${disk}.initports|wc -l`

# Disable all but one path and try until successfull

epath=1
success=0

while [ $epath -le $paths ]; do
    # Enable all paths
    path=1
    while [ $path -le $paths ]; do
        mpathadm enable path -i ${iport[$((path - 1))]} -t ${tport[$((path - 1))]} -l /dev/rdsk/${disk}s2
        path=$(( path + 1 ))
    done


    # Disable all but $epath
    path=1
    while [ $path -le $paths ]; do
        if [ $path -ne $epath ]; then
            # Disable path
            mpathadm disable path -i ${iport[$((path - 1))]} -t ${tport[$((path - 1))]} -l /dev/rdsk/${disk}s2
        fi
        path=$(( path + 1 ))
    done
    
    # Try to update firmware

    $sg_buffer_write -b 4k -v -m 7 -I ${firmware} /dev/rdsk/${disk}s2 \
        1>/tmp/firmware/${disk}.update_${epath}_out  2>/tmp/firmware/${disk}.update_${epath}_error
    if [ $? -eq 0 ]; then
        # Success.
        echo "${disk}: success"
        success=1
        echo $disk >> /tmp/firmware/success-disks
        # Break out of while loop
        break
    fi
    epath=$(( epath + 1 ))

done

# Enable paths 
path=1
while [ $path -le $paths ]; do
    mpathadm enable path -i ${iport[$((path - 1))]} -t ${tport[$((path - 1))]} -l /dev/rdsk/${disk}s2
    path=$(( path + 1 ))
done

if [ $success -eq 0 ]; then
    echo $disk >> /tmp/firmware/failed-disks
    echo "${disk}: FAILED"
fi

