#!/bin/sh

# ASSUMPTIONS and ENVIRONMENT:
#
# I am asked for a filesystem that will product the output "hello world".  Assuming that
# this means that I am creating a small embedded Linux for a device with limited capabilities.
# Ideally, I'd custom configure a Linux kernel to match the device hardware in this instance,
# but I will compromise in this case and take a prebuilt kernel.  To save space, I will create
# an initrd from cpio which Linux will use to populate a ram disk.  In that ram disk, I will
# have only an init application that has been statically linked.  Depending on extended
# requirements, I could have built busybox to populate the ram disk with a more complete
# set of Linux commands.  Also, I could also create another filesystem image in a file that
# could be persistent.  However, the stated requirements didn't seem to need a persistent
# filesystem.  Thus I limited the solution to the ram filesystem.
#
# I've built and tested this script on a newly installed Ubuntu 22.04.3 system.  The script
# does require the user to provide the root password for installing the needed packages
# that aren't installed initially when Ubuntu 22.04.3 is installed fresh.  Other than that,
# no user input is required.  Personally, I used Virtual Box to create a new virtual machine,
# and I installed Ubuntu 22.04.3 which I downloaded from Canonical.  This virtual machine
# was then used to verify the script.
#
# Enhancements could include skipping the apt install step if run on a system that already
# has the needed packages installed.  Also, the Linux kernel could either be custom built
# or the kernel could be cached locally to avoid needing to download the full distribution
# simply to extract the kernel.  Other enhancements were discussed in the first paragraph.

cd $HOME
mkdir problem1
cd problem1

###############################################################
echo "Install needed packages"
sudo apt install -y curl qemu-system build-essential

###############################################################
echo "Download Alpine Linux and extract kernel"
curl https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/alpine-standard-3.18.3-x86_64.iso --output alpine-standard-3.18.3-x86_64.iso

isoinfo -i alpine-standard-3.18.3-x86_64.iso -R -x /boot/vmlinuz-lts > vmlinuz-lts

###############################################################
echo "Create init and put it in an initrd to create the RAM filesystem that Linux will use"
cat <<EOF > init.c
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

int main()
{
	sleep(1);
	printf("\n\n\nhello world!\n");
	sleep(-1);
	return 0;
}
EOF

gcc -static -o init init.c
touch 'TRAILER!!!'
echo init | cpio -ovH newc > initrd.img
echo 'TRAILER!!!' | cpio -ovH newc >> initrd.img
gzip initrd.img

###############################################################
echo "Run QEMU"
qemu-system-x86_64 -kernel vmlinuz-lts -initrd initrd.img.gz -m 512
