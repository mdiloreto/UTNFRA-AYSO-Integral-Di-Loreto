set -e   # salir si algo falla

pvcreate /dev/sdb /dev/sdc /dev/sdd

vgcreate vg_datos /dev/sdb /dev/sdc /dev/sdd

lvcreate -L 10M  -n lv_docker vg_datos
lvcreate -L 2.5G -n lv_work   vg_datos

# sistema de archivos ext4
mkfs.ext4 /dev/vg_datos/lv_docker            
mkfs.ext4 /dev/vg_datos/lv_work

mkdir -p /var/lib/docker /work
mount  /dev/vg_datos/lv_docker /var/lib/docker
mount  /dev/vg_datos/lv_work   /work

# /etc/fstab para que se monten al arrancar
echo "/dev/vg_datos/lv_docker /var/lib/docker ext4 defaults 0 2" >> /etc/fstab
echo "/dev/vg_datos/lv_work   /work            ext4 defaults 0 2" >> /etc/fstab

# Config la swap
mkswap /dev/sdd
swapon  /dev/sdd
echo "/dev/sdd none swap sw 0 0" >> /etc/fstab
