#!/bin/bash

echo "=== Probando configuración de Docker ==="

# Probar instalación de Docker
echo "1. Verificando Docker..."
docker --version

# Probar servicio Docker
echo "2. Verificando servicio Docker..."
systemctl is-active docker

# Probar red de Docker
echo "3. Verificando red de Docker..."
docker network ls | grep app_net

# Probar aplicación web
echo "4. Verificando aplicación web..."
ls -la /app/

# Probar contenedores corriendo
echo "5. Verificando contenedores corriendo..."
docker ps

echo "=== Prueba completada ===" 