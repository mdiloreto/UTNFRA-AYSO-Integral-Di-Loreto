#!/bin/bash
# clear

###############################
#
# Parametros:
#  - Lista Dominios y URL
#
#  Tareas:
#  - Se debera generar la estructura de directorio pedida con 1 solo comando con las tecnicas enseñadas en clases
#  - Generar los archivos de logs requeridos.
#
###############################
LISTA=$1

ANT_IFS=$IFS
IFS=$'\n'

for LINEA in `cat $LISTA | grep -v ^#`
do
  DOM=$(echo "$LINEA" | awk -F ',' '{print $1}')
  URL=$(echo $LINEA | awk -F ',' '{print $2}')

  if [ -z $URL ] > /dev/null; then
    continue
  fi

  # ---- Dentro del bucle ----#
  # Obtener el código de estado HTTP
  STATUS_CODE=$(curl -LI -o /dev/null -w '%{http_code}\n' -s "$URL")

  # Fecha y hora actual en formato yyyymmdd_hhmmss
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

  if [[ $STATUS_CODE =~ ^4 ]]; then 
    LOG_PATH="$PWD/tmp/head-check/error/cliente/$DOM-$TIMESTAMP.log"
  elif [[ $STATUS_CODE =~ ^5 ]]; then
    LOG_PATH="$PWD/tmp/head-check/error/server/$DOM-$TIMESTAMP.log"
  elif [[ $STATUS_CODE =~ ^2 ]]; then
    LOG_PATH="$PWD/tmp/head-check/ok/$DOM-$TIMESTAMP.log"
  else
    LOG_PATH="$PWD/tmp/head-check/$DOM-$TIMESTAMP.log"
  fi
  
  mkdir -p "$(dirname "$LOG_PATH")"
 # Registrar en el archivo /var/log/status_url.log
  echo "$TIMESTAMP - Code:$STATUS_CODE - URL:$URL" |sudo tee -a  "$LOG_PATH"

#-------------------------#
done 
IFS=$ANT_IFS
