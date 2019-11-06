set -e
# in this script, you should type 5 times
#  * type "YES" to begin the script
#  * type "YES" to confirm that you want to encrypt the disk
#  * type your password twice to set it
#  * type your password again to open the encrypted disk
# lat last, unplug and replug your disk, input the password, and you will get it!

# HOW TO MOUNT (the encrypted disk), after you run this script?
# cryptsetup luksOpen /dev/sd? a_random_name_for_this_device

# then the device name of this (unencrypted) disk should be
#     /dev/${LVM_GROUP_NAME}/${LVM_NAME}
# or
#     /dev/mapper/${LVM_GROUP_NAME}-${LVM_NAME}

# this is the device that you want to format and encrypt, be careful to use the right one!
# use `lsblk` to view all devices, get the right device ID use `ls -al /dev/disk/by-id`, copy it below
export DISK_ID_NAME=

# choose which filesystem to use. Recommend zfs (only if you have installed it!)
export fstype=zfs # should be zfs or lvm
export LUKS_DEVICE_NAME=backup_luks
export MOUNT_POINT=/LaCie-Backup-5T

# lvm related names when you use lvm and ext4
export LVM_GROUP_NAME=backup_VG
export LVM_NAME=backup_DATA
# zfs related names when you use zfs
export ZPOOL_NAME=LaCie-Backup-5T

export DISK_DEV=/dev/disk/by-id/${DISK_ID_NAME}
export DISK=${DISK_DEV}-part1

if [[ ! -h ${DISK_DEV} ]]; then
	echo "$DISK_DEV not found!"
	exit 1
else
	lsblk ${DISK_DEV}
	read -p "type UPPER YES to continue" result
	if [[ $result != "YES" ]]; then
		echo "exit"
		exit 1
	fi
fi

export doParted=True
export doLuks=True
export doFormat=True

if [[ "${doParted}" == "True" ]]; then
# 1. parted the disk
# parted
	cat <<-EOF > ./expect.sh
	#!/usr/bin/expect -f
	set timeout 5
	spawn parted -a optimal $DISK_DEV
	expect "*(parted) " { send "mklabel gpt\r" }
	expect {
		"Warning:*Do you want to continue?*Yes/No?" { send "Yes\r" }
		timeout { }
	}
	expect {
		"Warning:*will be destroyed and all data on this disk will be lost. Do you want to continue?*Yes/No?" { send "Yes\r" }
		timeout { }
	}
	expect "(parted) " { send "unit MiB\r" }
	expect "(parted) " { send "mkpart primary 1 -1\r" }
	expect "(parted) " { send "name 1 superbloch-data\r" }
	expect "(parted) " { send "set 1 lvm on\r" }
	expect "(parted) " { send "p\r" }
	expect "(parted) " { send "q\r" }
	EOF
	expect -f expect.sh

sleep 3
if [[ ! -h ${DISK} ]]; then
	echo "$DISK not generated!"
	exit 1
fi
fi # end of doParted

# 2. encrypt the disk
if [[ "${doLuks}" == "True" ]]; then
# encrypt lvm, you need to input YES, and a password
cryptsetup -v -y -c aes-xts-plain64 -s 512 -h sha512 -i 5000 --use-random luksFormat $DISK
# show header info
cryptsetup luksDump $DISK
# open crypt disk
cryptsetup luksOpen $DISK $LUKS_DEVICE_NAME
fi # end of doLuks

# 3.1 create lvm and use ext4
if [[ "${doFormat}" == "True" ]]; then
## create physical volume
mkdir -p ${MOUNT_POINT}
if [[ "${fstype}" == "lvm" ]]; then
	pvcreate /dev/mapper/$LUKS_DEVICE_NAME
	pvdisplay
	vgcreate $LVM_GROUP_NAME	/dev/mapper/${LUKS_DEVICE_NAME}
	vgdisplay
	lvcreate -l "+100%FREE" -n ${LVM_NAME} ${LVM_GROUP_NAME}
	lvdisplay
	vgscan
	vgchange -ay
	mkfs.ext4 -b 2048 -i 1024 /dev/${LVM_GROUP_NAME}/${LVM_NAME} # this will make a disk good to store small config file
	mount /dev/${LVM_GROUP_NAME}/${LVM_NAME} ${MOUNT_POINT}
elif [[ "${fstype}" == 'zfs' ]]; then
	zpool create -f -m none -o ashift=10 -O atime=off -O compression=lz4 -O xattr=sa ${ZPOOL_NAME} /dev/mapper/${LUKS_DEVICE_NAME}
	zfs set mountpoint=${MOUNT_POINT} ${ZPOOL_NAME}
fi
echo "disk mounted on ${MOUNT_POINT}"
fi # end of doFormat
