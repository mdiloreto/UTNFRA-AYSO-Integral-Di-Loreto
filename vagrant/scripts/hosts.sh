#!/usr/bin/env bash
set -e

grep -q "vm1-grupo-Diloreto" /etc/hosts || cat >>/etc/hosts <<EOF
192.168.56.11 vm1-grupo-Diloreto
192.168.56.12 vm2-grupo-Diloreto
EOF
echo "[+] /etc/hosts actualizado"