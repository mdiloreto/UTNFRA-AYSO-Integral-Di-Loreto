#!/usr/bin/env bash
set -eu 

echo "[+] Formateando y montando discos…"
for dev in /dev/sdb /dev/sdc; do
  blkid $dev || mkfs.ext4 -F $dev
done

mkdir -p /mnt/disk10 /mnt/disk2
grep -q '/mnt/disk10' /etc/fstab || echo '/dev/sdb /mnt/disk10 ext4 defaults 0 2' >> /etc/fstab
grep -q '/mnt/disk2'  /etc/fstab || echo '/dev/sdc /mnt/disk2  ext4 defaults 0 2' >> /etc/fstab
mount -a
