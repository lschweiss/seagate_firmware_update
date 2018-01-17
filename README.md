Simple script to do bulk firmware updates to Seagate SAS disks in a JBOD on Illumos/Solaris.

Seagate disks will only accept a firmware image that is sent on the primary SAS channel.  When in a JBOD with multiple SAS paths, Illumos will round robin all communication down all paths.   This will not work.   This script disables all but one path before sending the firmware.  If it fails it tries another path until it succeeds or has tried all paths.

Requires:
sg3_utils - http://sg.danny.cz/sg/sg3_utils.html

Modify the variables at the top of the script to point to a firmware image and the path to sg_buffer_write.

Create a 'disk-list' file with the names of the disks to be updated with one disk per line.  Such as:

c0t5000C500629AD01Fd0

c0t5000C500629A4FFBd0

c0t5000C500629A516Fd0

c0t5000C500629A5947d0

Run the script.

The successes and failures are listed in /tmp/firmware/success-disks and /tmp/firmware/failed-disk along with output from each SAS path tried.

