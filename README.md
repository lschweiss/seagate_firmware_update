## Seagate Disk Firmware Update

Simple script to do bulk firmware updates to Seagate SAS disks in a JBOD on Illumos/Solaris.

**Background:**
Seagate disks will only accept a firmware image that is sent on the primary SAS channel.  When in a JBOD with multiple SAS paths, Illumos will round robin all communication down all paths.   This will not work.   This script disables all but one path before sending the firmware.  If it fails it tries another path until it succeeds or has tried all paths.

**Requires:**
sg_buffer_write from sg3_utils - http://sg.danny.cz/sg/sg3_utils.html
'sg_buffer_write' must be in the execution search path

**Optional:**
GNU Parallel 
https://www.gnu.org/software/parallel/
'parallel' must be in the execution search path 

**Update a single disk example:**

    update-seagate-firmware.sh -d c0t5000C500629AD01Fd0 -f MakaraPlusEntCapSAS-STD-5xxE-E004.LOD

**Update multiple disks utilizing GNU Parallel:**
Create a file listing all the names of the disks to be updated with one disk per line.  Such as:

    c0t5000C500629AD01Fd0    
    c0t5000C500629A4FFBd0    
    c0t5000C500629A516Fd0    
    c0t5000C500629A5947d0

Execute:

    parallel-update.sh -d {disk_list_file} -f {firmware}

The successes and failures are listed in /tmp/firmware/success-disks and /tmp/firmware/failed-disk along with output from each SAS path tried.

