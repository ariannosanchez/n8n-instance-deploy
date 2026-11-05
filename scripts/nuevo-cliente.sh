#!/usr/bin/env bash
# Crea un proyecto en Railway desde el template n8n-lite-v2 y le aplica los limites de RAM/CPU.
#
#   Uso:  bash scripts/nuevo-cliente.sh "NOMBRE DEL CLIENTE" [CODIGO_TEMPLATE]
#
# Requiere: railway CLI con sesion iniciada (railway login) en la cuenta donde vive el template,
#           node (para leer JSON). Se puede ejecutar desde cualquier carpeta. Tarda ~4 min.
set -euo pipefail

NAME="${1:?Falta el nombre del proyecto}"
CODE="${2:-Xz0V7U}"            # codigo del template n8n-lite-v2 (ver: railway templates list)
MEM_N8N=0.75;  CPU_N8N=2       # GB / vCPU
MEM_PG=0.25;   CPU_PG=1
MEM_REDIS=0.125; CPU_REDIS=0.5

j() { node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const j=JSON.parse(s);$1})"; }

echo "1/4  Leyendo template $CODE..."
TPL=$(railway api "query { template(code:\"$CODE\") { id serializedConfig } }")
TPL_ID=$(echo "$TPL" | j 'console.log(j.data.template.id)')
TPL_CFG=$(echo "$TPL" | j 'process.stdout.write(JSON.stringify(j.data.template.serializedConfig))')

echo "2/4  Creando proyecto \"$NAME\"..."
WORK=$(mktemp -d); pushd "$WORK" >/dev/null
PROJ=$(railway init --name "$NAME" --json | j 'console.log(j.id)')
ENV=$(railway status --json | j 'console.log(j.environments.edges[0].node.id)')
popd >/dev/null; rm -rf "$WORK"
echo "     proyecto=$PROJ  entorno=$ENV"

echo "3/4  Desplegando template..."
VARS=$(TPL_CFG="$TPL_CFG" TPL_ID="$TPL_ID" PROJ="$PROJ" ENV="$ENV" node -e "const e=process.env;console.log(JSON.stringify({i:{templateId:e.TPL_ID,projectId:e.PROJ,environmentId:e.ENV,serializedConfig:JSON.parse(e.TPL_CFG)}}))")
railway api 'mutation($i:TemplateDeployV2Input!){ templateDeployV2(input:$i) { projectId workflowId } }' --variables "$VARS" | j 'if(j.errors){console.error(JSON.stringify(j.errors));process.exit(1)}console.log("     ok")'

echo "4/4  Esperando el primer deploy (los limites puestos antes de que termine se pierden)..."
for i in $(seq 1 60); do
  ST=$(railway api "query { project(id:\"$PROJ\") { services { edges { node { name serviceInstances { edges { node { latestDeployment { status } } } } } } } } }" | j 'console.log(j.data.project.services.edges.map(e=>e.node.name+"="+(e.node.serviceInstances.edges[0]?.node.latestDeployment?.status||"PENDING")).join(" "))')
  echo "     $ST"
  if [ "$(echo "$ST" | wc -w)" -ge 3 ] && ! echo "$ST" | grep -qE "PENDING|BUILDING|DEPLOYING|INITIALIZING|QUEUED|WAITING"; then break; fi
  sleep 10
done

echo "     Aplicando limites de RAM/CPU..."
SVCS=$(railway api "query { project(id:\"$PROJ\") { services { edges { node { id name } } } } }" | j 'console.log(j.data.project.services.edges.map(e=>e.node.name+"="+e.node.id).join(" "))')
for pair in $SVCS; do
  n="${pair%%=*}"; id="${pair##*=}"
  case "$n" in
    n8n)      mem=$MEM_N8N;   cpu=$CPU_N8N ;;
    Postgres) mem=$MEM_PG;    cpu=$CPU_PG ;;
    Redis)    mem=$MEM_REDIS; cpu=$CPU_REDIS ;;
    *) continue ;;
  esac
  for t in $(seq 1 10); do
    if railway api "mutation { serviceInstanceLimitsUpdate(input:{serviceId:\"$id\", environmentId:\"$ENV\", memoryGB:$mem, vCPUs:$cpu}) }" 2>/dev/null | grep -q '"serviceInstanceLimitsUpdate": *true'; then
      echo "     $n -> ${mem} GB / ${cpu} vCPU"; break
    fi
    sleep 5
  done
done

echo
DOM=$(railway api "query { project(id:\"$PROJ\") { services { edges { node { name serviceInstances { edges { node { domains { serviceDomains { domain } } } } } } } } } }" | j 'const svc=j.data.project.services.edges.find(e=>e.node.name==="n8n");const d=svc&&svc.node.serviceInstances.edges[0]?.node.domains.serviceDomains[0]?.domain;console.log(d||"")')
echo "Listo."
[ -n "$DOM" ] && echo "  n8n:      https://$DOM"
echo "  proyecto: https://railway.com/project/$PROJ"
