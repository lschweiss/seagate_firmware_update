#! /bin/bash

die () {
    echo $1
    exit 1
}

# show function usage
show_usage() {
    echo
    echo "Usage: $0 -f {firmware_file} -d {disk_list} [-j {concurrent_jobs} ]"
}

while getopts f:d:j: opt; do
    case $opt in
        f) # Firmware
            firmware="$OPTARG"
            ;;
        d) # Disk
            disk_list="$OPTARG"
            ;;
        j) # Concurrent jobs
            jobs="-j $OPTARG"
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

which sg_write_buffer 1>/dev/null 2>/dev/null || die "sg_write_buffer is not in execution search PATH"

which parallel 1>/dev/null 2>/dev/null || die "gnu parallel is not in execution search PATH"

[ -f $firmware ] || die "Could not locate firmware file at: $firmware" 

[ -f $disk_list ] || die "Disk list not found: ${disk_list}"

mkdir -p /tmp/firmware

rm -f /tmp/firmware/success-disks
rm -f /tmp/firmware/failed-disks

cat $disk_list | parallel ${jobs} --eta ./update-seagate-firmware.sh -f ${firmware} -d {} 

