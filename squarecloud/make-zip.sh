#!/bin/sh
# Genera n8n-squarecloud.zip con los 3 archivos que pide Square Cloud.
# Antes: copiar .env.example a .env y completar CAMBIAR.
set -e
cd "$(dirname "$0")"
[ -f .env ] || { echo "Falta .env (copia .env.example y completa los valores)"; exit 1; }
grep -q CAMBIAR .env && { echo "Aun hay valores CAMBIAR en .env"; exit 1; }
rm -f n8n-squarecloud.zip
if command -v zip >/dev/null; then zip -q n8n-squarecloud.zip package.json squarecloud.app .env
else powershell -NoProfile -Command "Compress-Archive -Path package.json,squarecloud.app,.env -DestinationPath n8n-squarecloud.zip -Force"; fi
echo "Listo: n8n-squarecloud.zip"
