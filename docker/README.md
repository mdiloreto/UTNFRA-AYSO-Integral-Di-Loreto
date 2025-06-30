# docker

Esta carpeta contiene los archivos necesarios para levantar servicios y aplicaciones usando Docker y Docker Compose.

## ¿Qué vas a encontrar?
- `docker-compose.yml`: Definición de los servicios, volúmenes y redes.
- `web/`: Archivos estáticos y scripts para el contenedor web.
- Dockerfiles para distintos modos de ejecución.

## Ejemplo de uso
```bash
cd docker
docker compose up -d
```

> Tip: Podés modificar los archivos según tus necesidades para agregar o quitar servicios. 