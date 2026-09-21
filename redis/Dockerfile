# Redis minimo para buffer / locks / pausas / rate-limit del bot (~10-15 MB de RAM).
FROM redis:7-alpine

# Volumen montado en /data. AOF activo para que las claves pause:* (24 h)
# sobrevivan a un reinicio; sin snapshots RDB.
# REDIS_PASSWORD se define como variable del servicio en Railway.
CMD ["sh", "-c", "exec redis-server --maxmemory 32mb --maxmemory-policy allkeys-lru --save '' --appendonly yes --appendfsync everysec --dir /data --requirepass \"$REDIS_PASSWORD\""]
