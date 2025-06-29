#!/usr/bin/env bash
set -e

grep -q "vm1-grupo-diloreto" /etc/hosts || cat >>/etc/hosts <<EOF
192.168.56.11 vm1-grupo-diloreto
192.168.56.12 vm2-grupo-diloreto
EOF
echo "[+] /etc/hosts actualizado"