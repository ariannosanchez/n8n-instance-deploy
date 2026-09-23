# Prueba de n8n en Square Cloud

Misma configuracion que el template de Railway, adaptada a Square Cloud (no usa Docker:
n8n se instala por npm con la version fijada en `package.json`).

## Pasos
1. Plan **Standard** (4 GB) activo en https://squarecloud.app.
2. Dashboard > **Databases** > Create Database > PostgreSQL 17 de **1 GB** (es el minimo que permiten para Postgres). Anotar host, puerto,
   usuario, password y nombre de base.
3. (Opcional, solo si el workflow usa nodos Redis) crear un Redis 7 de 512 MB (minimo para cache); sus datos
   van en la credencial Redis dentro de n8n, no en `.env`.
4. `cp .env.example .env` y completar los `CAMBIAR` (DB + encryption key). El SUBDOMAIN
   de `squarecloud.app` debe coincidir con las URLs de `.env`.
5. `sh make-zip.sh` -> sube `n8n-squarecloud.zip` en Dashboard > New Application.
6. Esperar el build (instala n8n por npm, 2-5 min) y abrir `https://<subdomain>.squareweb.app`.

## Que medir durante el mes
- RAM real en el panel (objetivo: < 700 MB; si se queda corta, subir MEMORY a 1536).
- Redeploy y restart: workflows y credenciales siguen (la base esta en su Postgres).
- Webhooks de YCloud: sin fallos ni duplicados; latencia del primer mensaje.
- Tiempo de cada deploy y cobro real en la tarjeta.

## Si el build rechaza MEMORY=1024
Su tutorial de n8n usa 3072 "por razones de plataforma". Probar 1024; si lo rechaza, subir
hasta el minimo que acepte y anotarlo: ese numero define cuantos clientes caben por plan.
