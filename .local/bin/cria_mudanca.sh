#!/bin/bash

[ -z "$1" ] || [ -e "$1" ] || echo "Arquivo $1 não encontrado. Forneça o nome do arquivo yaml." && exit 1

[ -e .env ] || echo "Ambiente não configurado." && exit 2

source .env

[ -z "$rundeck_dir" ] || [ -d "$rundeck_dir" ] || echo "Variável rundeck_dir não configurada." && exit 3

[ -z "$rundeck_token" ] && echo "Variável rundeck_token não configurada." && exit 4

[ -z "$rundeck_job_cria_mudanca" ] && echo "Variável rundeck_job_cria_mudança não configurada." && exit 5

nome_arquivo="$(basename "$1")"

cp "$1" "$rundeck_dir/$nome_arquivo"

BODY="{\"argString\":\"-nome_arquivo $nome_arquivo\",}"
curl -s -X POST --data "$BODY" \
  -H "Content-Type:application/json" \
  -H "X-Rundeck-Auth-Token:$rundeck_token" \
  "$rundeck_job_cria_mudanca"
