# n8n-instance-deploy

Template de Railway: **n8n + Postgres + Redis** ajustados para bajo consumo de RAM
(~400-450 MB en total en reposo, frente a ~1 GB con los templates por defecto).

```
n8n/Dockerfile        n8n con heap limitado, pruning y sin telemetria
postgres/Dockerfile   Postgres 17 con buffers minimos
redis/Dockerfile      Redis 7 con maxmemory 32 MB y AOF
```

Toda la optimizacion vive en los Dockerfile. Cualquier `ENV` se puede sobrescribir
creando una variable con el mismo nombre en el servicio de Railway.

## 0. Probar en local (opcional)

```bash
docker compose -f docker-compose.test.yml up -d --build
docker stats --no-stream
docker compose -f docker-compose.test.yml down -v
```

Editor en http://localhost:5678. Medido en reposo con n8n 2.39.10:
n8n ~325 MiB, Postgres ~45-55 MiB, Redis ~4 MiB.

## 1. Subir a GitHub

Repo **publico** (Railway lo exige para templates; aqui no hay ningun secreto).

```bash
git init -b main
git add .
git commit -m "n8n + postgres + redis lite para Railway"
git remote add origin https://github.com/ariannosanchez/n8n-instance-deploy.git
git push -u origin main
```

## 2. Crear el template en Railway

Workspace Settings -> **Templates** -> **New Template**. Agregar 3 servicios, los tres
con Source = este repo de GitHub, cambiando solo el **Root Directory**.

### Servicio `Postgres` — Root Directory `/postgres`
- Volumen: `/var/lib/postgresql/data`
- Variables:
  ```
  POSTGRES_USER=n8n
  POSTGRES_DB=n8n
  POSTGRES_PASSWORD=${{secret(24)}}
  ```

### Servicio `Redis` — Root Directory `/redis`
- Volumen: `/data`
- Variables:
  ```
  REDIS_PASSWORD=${{secret(24)}}
  ```

### Servicio `n8n` — Root Directory `/n8n`
- Volumen: `/home/node/.n8n`
- Public Networking: dominio HTTP -> puerto `5678`
- Healthcheck Path: `/healthz`
- Variables:
  ```
  N8N_ENCRYPTION_KEY=${{secret(32)}}
  DB_POSTGRESDB_HOST=${{Postgres.RAILWAY_PRIVATE_DOMAIN}}
  DB_POSTGRESDB_PORT=5432
  DB_POSTGRESDB_DATABASE=${{Postgres.POSTGRES_DB}}
  DB_POSTGRESDB_USER=${{Postgres.POSTGRES_USER}}
  DB_POSTGRESDB_PASSWORD=${{Postgres.POSTGRES_PASSWORD}}
  N8N_HOST=${{RAILWAY_PUBLIC_DOMAIN}}
  WEBHOOK_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}/
  N8N_EDITOR_BASE_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}
  N8N_VERSION=2.39.10
  PORT=5678
  ```
  `PORT=5678` es obligatorio: Railway hace el healthcheck contra `PORT`, y n8n escucha en
  `N8N_PORT` (5678). Sin esto el deploy falla con "replicas never became healthy".

  `N8N_VERSION` fija la version de n8n (si no existe la variable, el Dockerfile usa 2.39.10,
  la version probada). Para actualizar n8n: cambias la variable y redeploy. Nunca uses `stable`/`latest`
  en produccion: un redeploy te actualizaria n8n sin querer y las migraciones de base no tienen vuelta atras.

Ajustes recomendados por servicio (Settings): **Watch Paths** `/n8n/**`, `/postgres/**`, `/redis/**`
(un cambio en una carpeta no redespliega los otros servicios) y Restart Policy `On Failure`.
Postgres y Redis **sin** dominio publico ni TCP proxy: solo red privada.

Guardar -> **Deploy** para probarlo en un proyecto nuevo. Publicarlo en el marketplace es opcional.

## 3. Credenciales dentro de n8n

| Credencial | Host | Puerto | Password |
|---|---|---|---|
| Redis | `redis.railway.internal` | 6379 | `REDIS_PASSWORD` |

(El host interno es el nombre del servicio en minusculas + `.railway.internal`.)

El Postgres de este template es **solo la base interna de n8n** (workflows, credenciales,
ejecuciones). Los datos del negocio y la memoria de chat (`n8n_chat_histories`) viven en
Supabase, asi que esas credenciales no cambian al migrar.

## 4. Migrar un n8n existente a este template

1. Copia **la misma `N8N_ENCRYPTION_KEY`** del proyecto viejo al nuevo (en vez de `secret(32)`).
   Sin esto todas las credenciales guardadas quedan ilegibles.
2. Con el n8n nuevo detenido, pasa la base:
   ```bash
   pg_dump --no-owner --no-acl "<DATABASE_PUBLIC_URL viejo>" | psql "<URL publica del Postgres nuevo>"
   ```
   (activa temporalmente un TCP Proxy en el Postgres nuevo para tener URL publica, y quitalo despues).
3. Arranca n8n, revisa credenciales y workflows, y recien entonces apunta el webhook de YCloud
   al dominio nuevo (o mueve el dominio custom).
4. Redis no se migra: solo tiene estado efimero (buffers, locks, pausas de 24 h).

## Ajustes

| Sintoma | Cambio |
|---|---|
| `JavaScript heap out of memory` | `NODE_OPTIONS=--max-old-space-size=512` |
| Quieres ver ejecuciones exitosas de un workflow | Settings del workflow -> Save successful executions = Yes |
| Postgres: `too many connections` | subir `max_connections` en `postgres/Dockerfile` |
| Historial de ejecuciones mas largo | `EXECUTIONS_DATA_MAX_AGE` (horas) |
