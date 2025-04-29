#!/bin/bash

[ -z "$1" ] || [ -e "$1" ] || (echo "Arquivo $1 não encontrado. Forneça o nome do arquivo yaml." && exit 1)

[ -e .env ] || (echo "Ambiente não configurado." && exit 2)

source .env

[ -z "$rundeck_dir" ] || [ -d "$rundeck_dir" ] || (echo "Variável rundeck_dir não configurada." && exit 3)

[ -z "$rundeck_token" ] && (echo "Variável rundeck_token não configurada." && exit 4)

[ -z "$rundeck_job_cria_mudanca" ] && (echo "Variável rundeck_job_cria_mudança não configurada." && exit 5)

nome_arquivo="$(basename "$1")"

echo "Enviando $nome_arquivo para $rundeck_dir"

cp "$1" "$rundeck_dir/$nome_arquivo"

echo "Chamando $rundeck_job_cria_mudanca"

BODY="{\"argString\":\"-nome_arquivo $nome_arquivo\",}"
executionId=$(curl -s -X POST --data "$BODY" \
  -H "Content-Type:application/json" \
  -H "Accept:application/json" \
  -H "X-Rundeck-Auth-Token:$rundeck_token" \
  "$rundeck_url/api/14/job/$rundeck_cria_mudanca_job_id/run" | jq '.executionId')

completed=false
start_time=$(date +%s)
elapsed_time=0
timeout_seconds=360
until [ "$completed" = "true" ] || [ "$elapsed_time" -gt "$timeout_seconds" ]
do
  completed=$(curl -s "$rundeck_url/api/14/execution/$executionId/state" | jq '.completed')
  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))
done
echo "Processamento concluído"

executionState=$(curl -s "$rundeck_url/api/14/execution/$executionId/state" | jq '.executionState')
[ "$executionState" = "SUCCEEDED" ] || (echo "Execução falhou com status $executionState." && exit 6)
echo "Mudança processada com sucesso."

curl -s "$rundeck_url/api/14/execution/$executionId/output" | grep "ID da mudança criada = "

# TODO Testar recuperação do código da mudança criada:
# 1. pegar execution.id
# 2. Aguardar GET /api/14/execution/[execution.id]/state retornar SUCCEEDED (ou falhar e sair)
# curl -s "$rundeck_url/api/14/execution/$executionId/state" | jq '.completed'
# curl -s "$rundeck_url/api/14/execution/$executionId/state" | jq '.executionState'
# 3. chamar GET /api/14/execution/[execution.id]/output
# curl -s "$rundeck_url/api/14/execution/$executionId/output" | grep "ID da mudança criada = "
# 4. buscar por "ID da mudança criada = CRQ..."
