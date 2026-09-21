# n8n optimizado para bajo consumo de RAM en Railway.
# Fija la version creando la variable N8N_VERSION en el servicio de Railway
# (Railway la pasa como build arg). Si no existe, se usa la version probada de abajo.
ARG N8N_VERSION=2.39.10
FROM n8nio/n8n:${N8N_VERSION}

# Los volumenes de Railway se montan como root: corremos como root y fijamos
# la carpeta de datos para que siga siendo /home/node/.n8n (ahi va el volumen).
USER root
ENV N8N_USER_FOLDER=/home/node

# --- Memoria ---
# Limita el heap de Node: sin esto crece y casi nunca devuelve RAM al sistema.
# Subir a 512 si aparecen errores "heap out of memory".
ENV NODE_OPTIONS=--max-old-space-size=384
# Los binarios (audios de WhatsApp, imagenes) van a disco, no al heap.
ENV N8N_DEFAULT_BINARY_DATA_MODE=filesystem
ENV DB_POSTGRESDB_POOL_SIZE=2
ENV EXECUTIONS_MODE=regular

# --- Ejecuciones: guardar poco y limpiar rapido (controla el tamano de Postgres) ---
# Para depurar un workflow concreto: Settings del workflow -> Save successful executions = Yes
ENV EXECUTIONS_DATA_SAVE_ON_SUCCESS=none
ENV EXECUTIONS_DATA_SAVE_ON_ERROR=all
ENV EXECUTIONS_DATA_SAVE_ON_PROGRESS=false
ENV EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=false
ENV EXECUTIONS_DATA_PRUNE=true
ENV EXECUTIONS_DATA_MAX_AGE=72
ENV EXECUTIONS_DATA_PRUNE_MAX_COUNT=2000

# --- Sin telemetria ni llamadas de fondo ---
ENV N8N_DIAGNOSTICS_ENABLED=false
ENV N8N_VERSION_NOTIFICATIONS_ENABLED=false
ENV N8N_TEMPLATES_ENABLED=false
ENV N8N_PERSONALIZATION_ENABLED=false

# --- Base ---
ENV DB_TYPE=postgresdb
ENV N8N_PORT=5678
ENV N8N_PROTOCOL=https
ENV N8N_PROXY_HOPS=1
ENV GENERIC_TIMEZONE=America/Lima
ENV TZ=America/Lima

EXPOSE 5678
