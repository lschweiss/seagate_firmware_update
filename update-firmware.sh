#! /bin/bash

disks=`cat disk-list`

firmware='MegalodonES3-SAS-STD-E007.LOD'

sg_buffer_write="/opt/ozmt/bin/SunOS/sg_write_buffer"

mkdir -p /tmp/firmware

rm -f /tmp/firmware/success-disks
rm -f /tmp/firmware/failed-disks

set -x
for disk in $disks;do
    
    echo -n "Updating: $disk "
    
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
            echo "success"
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
        echo "FAILED"
    fi

done
    
    
