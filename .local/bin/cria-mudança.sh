#!/bin/bash

[ -z "$1" ] || [ -e "$1" ] || (echo "Arquivo $1 não encontrado. Forneça o nome do arquivo yaml." && exit 1)

#[ -e .env ] || (echo "Ambiente não configurado." && exit 2)

source .env

[ -z "$rundeck_dir" ] || [ -d "$rundeck_dir" ] || (echo "Variável rundeck_dir não configurada." && exit 3)

[ -z "$rundeck_token" ] && (echo "Variável rundeck_token não configurada." && exit 4)

[ -z "$rundeck_cria_mudanca_job_id" ] && (echo "Variável rundeck_job_cria_mudança não configurada." && exit 5)

nome_arquivo="$(basename "$1")"

echo "Enviando $nome_arquivo para $rundeck_dir"

cp "$1" "$rundeck_dir/$nome_arquivo"

echo "Chamando job $rundeck_cria_mudanca_job_id"

BODY="{\"argString\":\"-nome_arquivo $nome_arquivo\",}"
executionId=$(curl -s -X POST --data "$BODY" \
  -H "Content-Type:application/json" \
  -H "Accept:application/json" \
  -H "X-Rundeck-Auth-Token:$rundeck_token" \
  "$rundeck_url/api/14/job/$rundeck_cria_mudanca_job_id/run" | jq '.executionId')

sleep 60
echo "Processamento concluído"

echo "Chamando $rundeck_url/api/14/execution/$executionId/state"
executionState=$(curl -s "$rundeck_url/api/14/execution/$executionId/state" | jq '.executionState')
[ "$executionState" = "SUCCEEDED" ] || (echo "Execução falhou com status $executionState." && exit 6)
echo "Mudança processada com sucesso."

curl -s "$rundeck_url/api/14/execution/$executionId/output" | grep "ID da mudança criada = "
