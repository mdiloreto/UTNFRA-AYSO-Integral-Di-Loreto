#!/usr/bin/env bash
set -e

echo "[+] Instalando paquetes básicos…"           
if command -v apt-get &>/dev/null; then
  apt-get update -y
  apt-get install -y git curl tree vim
else
  dnf -y install git curl tree vim
fi

echo "[+] Activando sudo sin password para vagrant…"
echo "%vagrant ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/99-vagrant-nopass
chmod 440 /etc/sudoers.d/99-vagrant-nopass