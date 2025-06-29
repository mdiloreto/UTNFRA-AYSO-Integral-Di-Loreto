#!/usr/bin/env bash
# ====================================================================
# check_tp.sh  –  Verificador del TP Integral AySO
# ────────────────────────────────────────────────────────────────────
# Requiere: Vagrant, ssh, awk, grep, tput
# Ejecutar desde la carpeta "vagrant/" del proyecto
# ====================================================================

VM=("VM1-Grupo-diloreto" "VM2-Grupo-diloreto")
EXPECTED_BOX=("ubuntu" "fedora")
EXTRA_DISKS=(sdb sdc sdd sde)        # sde = disco 1 GB libre
HOSTS_LINES=("192.168.56.11 vm1-grupo-diloreto"
             "192.168.56.12 vm2-grupo-diloreto")
VG_NAME="vg_datos"
VG_TEMP="vg_temp"
DOCKER_LV_SIZE="10M"
WORK_LV_SIZE="2.5G"
SWAP_DEV="/dev/sdd"

# ---- helpers -------------------------------------------------------
GREEN=$(tput setaf 2); RED=$(tput setaf 1); YEL=$(tput setaf 3); NC=$(tput sgr0)
pass() { echo -e " ${GREEN}✔${NC} $*"; }
fail() { echo -e " ${RED}✘${NC} $*"; exit 1; }
warn() { echo -e " ${YEL}⚠${NC} $*"; }

ssh_vm() { vagrant ssh "$1" -c "$2" 2>/dev/null; return $?; }

# ---- 1. VMs up & boxes --------------------------------------------
echo "🔍 1. Estado VMs / box:"
for i in "${!VM[@]}"; do
  vagrant status "${VM[$i]}" | grep -q running \
    && pass "${VM[$i]} encendida" \
    || fail  "${VM[$i]} no está corriendo"

  os=$(ssh_vm "${VM[$i]}" 'grep ^ID= /etc/os-release | cut -d= -f2')
  [[ $os == ${EXPECTED_BOX[$i]}* ]] \
    && pass "OS ${os} ok" \
    || fail "OS esperado ${EXPECTED_BOX[$i]}*, encontrado $os"
done

# ---- 2. Discos extra ----------------------------------------------
echo "🔍 2. Discos extra:"
for vm in "${VM[@]}"; do
  for d in "${EXTRA_DISKS[@]}"; do
    ssh_vm "$vm" "[ -b /dev/$d ]" \
      && pass "$vm: /dev/$d presente" \
      || fail "$vm: falta /dev/$d"
  done
done

# ---- 3. /etc/hosts -------------------------------------------------
echo "🔍 3. /etc/hosts:"
for vm in "${VM[@]}"; do
  for line in "${HOSTS_LINES[@]}"; do
    ssh_vm "$vm" "grep -qx '$line' /etc/hosts" \
      && pass "$vm hosts ok ($line)" \
      || fail "$vm sin línea $line"
  done
done

# ---- 4. sudo NOPASSWD & paquetes ----------------------------------
echo "🔍 4. sudo sin password + paquetes base:"
for vm in "${VM[@]}"; do
  ssh_vm "$vm" "sudo -n true" \
    && pass "$vm sudo NOPASSWD" \
    || fail "$vm requiere password para sudo"

  for pkg in git tree; do
    ssh_vm "$vm" "command -v $pkg" \
      && pass "$vm paquete $pkg" \
      || fail "$vm sin paquete $pkg"
  done
done

# ---- 5. SSH cruzado ------------------------------------------------
echo "🔍 5. SSH cruzado:"
ssh_vm "${VM[0]}" "ssh -o BatchMode=yes ${VM[1]%.*} hostname" \
  && pass "VM1 → VM2 OK" || warn "VM1 no puede ssh a VM2"
ssh_vm "${VM[1]}" "ssh -o BatchMode=yes ${VM[0]%.*} hostname" \
  && pass "VM2 → VM1 OK" || warn "VM2 no puede ssh a VM1"

# ---- 6. LVM --------------------------------------------------------
echo "🔍 6. LVM VG/LV/FS:"
check_lv () {
  local vm=$1 vg=$2 lv=$3 size=$4 mount=$5
  ssh_vm "$vm" "lvs --noheadings -o lv_size /dev/$vg/$lv" | grep -q "$size" \
    && pass "$vm $lv tamaño $size" || fail "$vm $lv tamaño incorrecto"
  [[ -n $mount ]] && ssh_vm "$vm" "mount | grep -q ' /dev/$vg/$lv on $mount '" \
    && pass "$vm $lv montado en $mount" || fail "$vm $lv no montado"
}
check_lv "${VM[0]}" "$VG_NAME"  lv_docker "$DOCKER_LV_SIZE" /var/lib/docker
check_lv "${VM[0]}" "$VG_NAME"  lv_work   "$WORK_LV_SIZE"   /work
ssh_vm "${VM[0]}" "vgs | grep -q $VG_TEMP" \
  && pass "VG temporal $VG_TEMP existe" || warn "falta VG temporal $VG_TEMP"

# ---- 7. Swap -------------------------------------------------------
echo "🔍 7. Swap:"
ssh_vm "${VM[0]}" "swapon --summary | grep -q '$SWAP_DEV'" \
  && pass "Swap activo en $SWAP_DEV" \
  || fail "Swap no activo en $SWAP_DEV"

echo -e "\n${GREEN}🏁  Validación COMPLETA – todo OK${NC}"
