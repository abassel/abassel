
# Umount Rootfs by pivoting(chroot) to a ramfs and encrypt the underlying disk



### Goal:
- Add encrypted LVM with swap
- Unlock disk via SSH-dropbear
- Upgrade from Debian 10 (Buster) to Debian 11 (Bullseye)

### Assumptions:
- You have no access to console, usb or cdrom
- You only have access to ssh(root)
- You have limited ram(1GB)

-------------------------------------------------------------

### Youtube screencast for this guide:

[![Watch the video](https://img.youtube.com/vi/DuUAc5CGyZU/0.jpg)](https://youtu.be/DuUAc5CGyZU)


### BACKUP BACKUP BACKUP
**I take no responsibility if you lose any data**

## Steps:

0 - Update and reboot

```bash
apt update; apt upgrade -y

uname -r
# 4.19.0-10-cloud-amd64

ls /usr/lib/modules/
# 4.19.0-10-cloud-amd64  4.19.0-13-cloud-amd64
```

**Reboot if the running kernel does not match the highest
version in your modules directory(above)** Otherwise you will have a hard time loading kernel modules!

-------------------------------------------------------------

1 - Install required tools

```bash
apt install -y debootstrap lsof psmisc git

```

2 - Keep track of `/etc` changes:

```bash
cd /etc

git config --global user.email "a@b.com"

git config --global user.name "None"

git init

git add --all

git commit -m 'initial commit'
```

3 - Unmount all that you can and stop some services

```bash
umount -a
# umount: /run/user/0: target is busy.
# umount: /sys/fs/cgroup/unified: target is busy.
# umount: /sys/fs/cgroup: target is busy.
# umount: /: target is busy.
# umount: /run: target is busy.
# umount: /dev: target is busy.


running=`systemctl list-units | grep '.service' | grep running | awk '{print $1}' | grep -v -e ssh -e networking -e udev -e user`

echo $running
# cron.service dbus.service getty@tty1.service ntp.service
# rsyslog.service serial-getty@ttyS0.service 
# systemd-journald.service systemd-logind.service unscd.service

for SERVICE in $running; do systemctl stop $SERVICE; done

telinit 2
```

4 - Create a ramfs mount

```bash
ROOT_MOUNT=/mnt/tmpfs

mkdir -p ${ROOT_MOUNT}

mount -t tmpfs -o size=512m tmpfs ${ROOT_MOUNT}

mount | grep /tmpfs
# tmpfs on /mnt/tmpfs type tmpfs (rw,relatime,size=524288k)

df -h
# Filesystem      Size  Used Avail Use% Mounted on
# udev            487M     0  487M   0% /dev
# tmpfs            99M  2.8M   97M   3% /run
# /dev/vda1        25G  1.2G   23G   5% /
# tmpfs           495M     0  495M   0% /sys/fs/cgroup
# tmpfs            99M     0   99M   0% /run/user/0
# tmpfs           512M     0  512M   0% /mnt/tmpfs  <-- here
```

5 - Bootstrap Debain and copy some configuration

I recommend you not use `--variant=minbase` so the pivot goes smooth (because you will be pivoting to a systemd)

```bash
debootstrap  --arch amd64 --include=openssh-server,psmisc,parted,debootstrap,lsof,net-tools,lvm2,cryptsetup,linux-image-cloud-amd64 buster ${ROOT_MOUNT} http://cdn-fastly.deb.debian.org/debian

# for verification purposes
touch ${ROOT_MOUNT}/ramfs_root

# Move etc git repo to new partition
cp -R /etc/.git ${ROOT_MOUNT}/etc/

# Copy config to allow login/ssh
cp -R /root ${ROOT_MOUNT}
cp -R /etc/ssh ${ROOT_MOUNT}/etc

```

6 - Pivot (chroot)

```bash
mkdir -p ${ROOT_MOUNT}/old_root

# Do not create new mounts, instead move them
mount --make-rprivate /
mount --move /sys ${ROOT_MOUNT}/sys
mount --move /proc ${ROOT_MOUNT}/proc
mount --move /dev ${ROOT_MOUNT}/dev
mount --move /run ${ROOT_MOUNT}/run

# pivot
mount --make-private /
pivot_root ${ROOT_MOUNT} ${ROOT_MOUNT}/old_root

ls /
#  ...files.... ramfs_root  ...files.....

df -h
# Filesystem      Size  Used Avail Use% Mounted on
# udev            487M     0  487M   0% /dev
# tmpfs            99M  2.8M   97M   3% /run
# /dev/vda1        25G  1.2G   23G   5% /old_root
# tmpfs           495M     0  495M   0% /sys/fs/cgroup
# tmpfs            99M     0   99M   0% /run/user/0
# tmpfs           512M  410M  103M  80% /

systemctl --failed
# 0 loaded units listed. Pass --all to see loaded but inactive units, too.
# To show all installed unit files use 'systemctl list-unit-files'.

```
7 - Unmount(umount) old root

```bash
systemctl restart sshd

# Expect this to fail
umount /old_root
# umount: /old_root: target is busy.

fuser -vm /dev/vda1
#                      USER        PID ACCESS COMMAND
# /dev/vda1:           root     kernel mount /old_root
#                      root          1 ...e. systemd
#                      root        234 frce. systemd-udevd
#                      root       5259 ...e. sshd
#                      root       5265 ...e. systemd
#                      root       5266 ...e. (sd-pam
#                      root       5281 ..ce. bash
#                      root       5630 F..e. rsyslogd
#                      sshd       5647 ...e. dbus-daemon
#                      root       5649 ..ce. cron
#                      root       5650 ...e. systemd-logind
#                      root       5651 ...e. systemd-journal
#                      root       5652 ...e. agetty
#                      (unknown)   5657 ...e. nscd
#                      root       5660 ...e. agetty
#                      (unknown)   5663 .rce. ntpd

# MAKE SURE YOU CAN SSH BEFORE 
# RUNNING THE COMMAND BELOW

fuser -mk /dev/vda1
# /dev/vda1:    1e   234rce  5259e  5265e  5266e  5281ce  5630e  5647e  5649ce  5650e  5651e  5652e  5657e  5660e  5663rce
# Connection to <IP> closed by remote host.
# Connection to <IP> closed.

# >>>> reconnect <<<<

# Run `fuser -mk /dev/vda1` multiple times until
# until you end with the contents bellow
fuser -mk /dev/vda1
# /dev/vda1:               1e

systemctl daemon-reload

kill 1

umount /old_root

# at this point some system process will fail
systemctl --failed
# ● dbus.service           not-found failed failed dbus.service
# ● ntp.service            not-found failed failed ntp.service
# ● systemd-logind.service loaded    failed failed Login Service
# ● unscd.service          not-found failed failed unscd.service

```

8 - Check that your root file system is, in fact, FREE


```bash
ln -s /proc/self/mounts /etc/mtab

rm -rf /old_root

e2fsck /dev/vda1
# e2fsck 1.44.5 (15-Dec-2018)
# /dev/vda1: clean, 38925/1638400 files, 419895/6552827 blocks
```

9 - Remove old partition and create new ones with encrypted lvm

### **POINT OF NO RETURN**

```bash

# Make sure you can load crypt module before removing partitions
modprobe dm-crypt
modprobe dm-mod

# Remove partitions

parted /dev/vda rm 1
# Information: You may need to update /etc/fstab.

parted /dev/vda rm 2
# Information: You may need to update /etc/fstab.

# Create new ones
parted --script --align optimal /dev/vda \
            mktable msdos \
            mkpart primary ext4 1MiB 200MiB \
            mkpart primary 200MiB 100% \
            set 1 boot on \
            set 2 lvm on

parted /dev/vda align-check optimal 1
# 1 aligned

fdisk -l /dev/vda
# Disk /dev/vda: 25 GiB, 26843545600 bytes, 52428800 sectors
# Units: sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 512 bytes
# I/O size (minimum/optimal): 512 bytes / 512 bytes
# Disklabel type: dos
# Disk identifier: 0xc0990542
#
# Device     Boot  Start      End  Sectors  Size Id Type
# /dev/vda1  *      2048   409599   407552  199M 83 Linux
# /dev/vda2       409600 52428799 52019200 24.8G 8e Linux LVM

# Format boot partition
mkfs.ext4 /dev/vda1
# mke2fs 1.44.5 (15-Dec-2018)
# Creating filesystem with 203776 1k blocks and 51000 inodes
# Filesystem UUID: bf2f2d87-dd38-4ad8-8a1d-80126881ef65
# Superblock backups stored on blocks:
# 	8193, 24577, 40961, 57345, 73729

# Encrypt

cryptsetup  -y -v luksFormat /dev/vda2
# WARNING!
# ========
# This will overwrite data on /dev/vda2 irrevocably.
#
# Are you sure? (Type uppercase yes): YES
# Enter passphrase for /dev/vda2:
# Verify passphrase:
# Key slot 0 created.
# Command successful.

cryptsetup open /dev/vda2 vda2_crypt
# Enter passphrase for /dev/vda2:

pvcreate --dataalignmentoffset 512 /dev/mapper/vda2_crypt
#   Physical volume "/dev/mapper/vda2_crypt" successfully created.

vgcreate vg0 /dev/mapper/vda2_crypt
#   Volume group "vg0" successfully created

lvcreate -L 3g -n swapLV vg0
# Logical volume "swapLV" created.

lvcreate -L 5g -n rootLV vg0
# Logical volume "rootLV" created.

lvcreate -l 100%FREE -n dataLV vg0
# Logical volume "dataLV" created

mkfs.ext4 /dev/vg0/rootLV
mkfs.ext4 /dev/vg0/dataLV
mkswap /dev/vg0/swapLV && swapon /dev/vg0/swapLV
```

10 - Mount new partitions

```bash
NEW_ROOT=/new_root

mkdir -p ${NEW_ROOT}; mount /dev/vg0/rootLV ${NEW_ROOT}
mkdir -p ${NEW_ROOT}/data && mount /dev/vg0/dataLV ${NEW_ROOT}/data
mkdir -p ${NEW_ROOT}/boot && mount /dev/vda1 ${NEW_ROOT}/boot

```

11 - Bootstrap upgraded Debian system and copy configurations

```bash
debootstrap  --arch amd64 --include=openssh-server,psmisc,arch-install-scripts,net-tools,lsof,linux-image-amd64,linux-headers-amd64,grub2,cryptsetup,git,vim,lvm2 bullseye ${NEW_ROOT} http://deb.debian.org/debian

# for verifications purposes
touch ${NEW_ROOT}/new_root_02

# Move git history to new partition
cp -R /etc/.git* ${NEW_ROOT}/etc/

# otherwise you cannot login
cp -R /root ${NEW_ROOT}
cp -R /etc/ssh ${NEW_ROOT}/etc

mkdir -p ${NEW_ROOT}/old_root
```

12 - Move system mounts and pivot

```bash
mount --make-rprivate /
mount --move /sys ${NEW_ROOT}/sys
mount --move /proc ${NEW_ROOT}/proc
mount --move /dev ${NEW_ROOT}/dev
mount --move /run ${NEW_ROOT}/run

mount --make-private /
pivot_root ${NEW_ROOT} ${NEW_ROOT}/old_root
```

13 - Umount old root

```bash
systemctl daemon-reload
systemctl restart sshd

fuser -vm /old_root

# Run this multiple time until you end with nothing
fuser -km /old_root

killall -9 systemd
systemctl daemon-reload
kill 1
umount /old_root

ln -s /proc/self/mounts /etc/mtab

rm -rf /old_root

```

14 - Configure fstab and crypttab

```bash
genfstab -U / > /etc/fstab

cat /etc/fstab

uuid="$(blkid -o value -s UUID /dev/vda2)"

echo "vda2_crypt UUID=$uuid none luks" | tee -a /etc/crypttab

cat /etc/crypttab
## <target name>	<source device>		<key file>	<options>
# vda2_crypt UUID=<YOUR_DISK_UUID> none luks
```

15 - Install Grub2 and ssh-dropbear

```
apt install -y cryptsetup-initramfs dropbear-initramfs

# https://www.arminpech.de/2019/12/23/debian-unlock-luks-root-partition-remotely-by-ssh-using-dropbear/
echo 'DROPBEAR_OPTIONS="-RFEsjk -p 48236 -c /bin/cryptroot-unlock"' > /etc/dropbear-initramfs/config

cp ~/.ssh/authorized_keys /etc/dropbear-initramfs/authorized_keys

cd /etc

# Restore some network configurations - adapt acordigly
git status | grep net
git checkout udev/rules.d/70-persistent-net.rules
git diff network/interfaces
git checkout network/interfaces

cat /etc/network/interfaces

client_ip=167.172.236.53
gw_ip=167.172.224.1
netmask=255.255.240.0
net_interface=eth0

echo ip=${client_ip}:${server_ip}:${gw_ip}:${netmask}:${hostname_fqdn}:${net_interface}:${autoconf}:${dns0_ip}:${dns1_ip}
# ip=167.172.236.53::167.172.224.1:255.255.240.0::eth0:::

vi /etc/default/grub #
GRUB_CMDLINE_LINUX_DEFAULT=""

grub-install /dev/vda

update-grub /dev/vda

update-initramfs -u

reboot now

uname -a
# Linux debian-s-1vcpu-1gb-nyc3-01 5.9.0-4-amd64 #1 SMP Debian 5.9.11-1 (2020-11-27) x86_64 GNU/Linux

lsblk
# NAME             MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
# vda              254:0    0   25G  0 disk
# ├─vda1           254:1    0  199M  0 part  /boot
# └─vda2           254:2    0 24.8G  0 part
#   └─vda2_crypt   253:0    0 24.8G  0 crypt
#     ├─vg0-swapLV 253:1    0    3G  0 lvm   [SWAP]
#     ├─vg0-rootLV 253:2    0    5G  0 lvm   /
#     └─vg0-dataLV 253:3    0 16.8G  0 lvm   /data
# vdb              254:16   0  458K  1 disk
```

16 - Fix locale

```bash
apt install console-common locales

echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen

locale-gen

exit
```

## References

- Configure remote unlock:
[https://debuntu-tools.readthedocs.io/en/latest/unlock-remote-system.html](https://debuntu-tools.readthedocs.io/en/latest/unlock-remote-system.html)

- Kernel command line parameters for network configuration:
[https://www.kernel.org/doc/Documentation/filesystems/nfs/nfsroot.txt](https://www.kernel.org/doc/Documentation/filesystems/nfs/nfsroot.txt)
