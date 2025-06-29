#!/usr/bin/env bash
set -e

USER=vagrant
HOME_DIR=/home/$USER
KEY_DIR=$HOME_DIR/.ssh
PUBS_DIR=/vagrant/.pubkeys

mkdir -p "$KEY_DIR" "$PUBS_DIR"
chown -R $USER:$USER "$KEY_DIR"

if [ ! -f "$KEY_DIR/id_rsa" ]; then
  sudo -u $USER ssh-keygen -t rsa -N "" -f "$KEY_DIR/id_rsa"
fi

cp "$KEY_DIR/id_rsa.pub" "$PUBS_DIR/$(hostname).pub"

sleep 3
cat $PUBS_DIR/*.pub >"$KEY_DIR/authorized_keys"
chmod 600 "$KEY_DIR/authorized_keys"
chown $USER:$USER "$KEY_DIR/authorized_keys"

echo "[+] Claves SSH cruzadas"
