# Postgres ajustado para una sola instancia pequena de n8n (~60-80 MB de RAM).
FROM postgres:17-alpine

# El volumen de Railway trae un lost+found en la raiz: los datos van en una subcarpeta.
# Volumen montado en /var/lib/postgresql/data
ENV PGDATA=/var/lib/postgresql/data/pgdata

CMD ["postgres", \
     "-c", "shared_buffers=32MB", \
     "-c", "effective_cache_size=128MB", \
     "-c", "work_mem=2MB", \
     "-c", "maintenance_work_mem=16MB", \
     "-c", "wal_buffers=1MB", \
     "-c", "max_wal_size=256MB", \
     "-c", "max_connections=20", \
     "-c", "max_worker_processes=2", \
     "-c", "max_parallel_workers=0", \
     "-c", "max_parallel_workers_per_gather=0", \
     "-c", "autovacuum_max_workers=1"]
