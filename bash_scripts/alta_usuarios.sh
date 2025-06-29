LISTA=$1

ANT_IFS=$IFS
IFS=$'\n'
for LINEA in `cat $LISTA |  grep -v ^#`
do
	USUARIO=$(echo  $LINEA |awk -F ',' '{print $1}')
	GRUPO=$(echo  $LINEA |awk -F ',' '{print $2}')
    DIRECTORIO=$(echo "$LINEA" | awk -F ',' '{print $3}')

	if ! getent group "$GRUPO" > /dev/null; then
		sudo groupadd "$GRUPO"
	fi

	sudo useradd -m -d $DIRECTORIO -s /bin/bash -g $GRUPO $USUARIO
done
IFS=$ANT_IFS